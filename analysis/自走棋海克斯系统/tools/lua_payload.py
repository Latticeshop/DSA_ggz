# -*- coding: utf-8 -*-
"""WorldBuilder 脚本 payload（ScriptsData.json 里的 #!ra3luabridge 字符串）公共工具。

关键约束：单个 payload 约 64KB 上限。超过后游戏内该字符串被截断，表现为
`last token read: '<eof>'` 语法错误，并且同一段脚本里原本正常的功能一起失效
（已实测：HextechRuneEffects 67514 B 直接导致开图报错）。

因此向外发送 payload 时统一走 build_payload()：
  - 先按原样构造；放得下（≤ 硬上限）就原样发送，保持 payload 与源文件逐字一致；
  - 放不下才自动去掉 Lua 注释后再发。注释只给开发者看，在 payload 里不执行，
    却要占用这 64KB 预算；源文件（lua/ 下的 .lua）始终保留完整注释作为文档来源。
  - 去注释后仍超限则直接报错中止同步，避免把截断内容写进 ScriptsData.json。
"""
import os
import re

PAYLOAD_PREFIX = "#!ra3luabridge\r\n"
# 引擎侧上限：超过即被截断。
PAYLOAD_HARD_LIMIT = 65536
# 安全余量警告线：此后任何一次新增内容都可能越界。
PAYLOAD_WARN_LIMIT = 64512

_LONG_BRACKET = re.compile(r"\[(=*)\[")


class LuaPayloadError(Exception):
    pass


def find_repo_root(start_path=None):
    """从本文件（或指定路径）向上查找包含 ScriptsData.json 的仓库根目录。

    工具可放在任意子目录，路径不再写死本机绝对路径。
    """
    path = os.path.abspath(start_path or os.path.dirname(os.path.abspath(__file__)))
    while True:
        if os.path.exists(os.path.join(path, "ScriptsData.json")):
            return path
        parent = os.path.dirname(path)
        if parent == path:
            raise LuaPayloadError("向上查找未找到 ScriptsData.json，无法定位仓库根目录")
        path = parent


def normalize_crlf(value):
    return re.sub(r"\r?\n", "\r\n", value)


def payload_size(payload):
    return len(payload.encode("utf-8"))


def strip_lua_comments(text):
    """删除 Lua 行注释与 --[[ ]] 块注释，返回 (新文本, 省下字节数)。

    只删注释：字符串（含 [[ ]] 长字符串）原样保留，换行数量不变，
    因此每个函数/语句在文件中的行号与源文件保持一致，报错行号仍然对得上。
    """
    out = []
    index = 0
    length = len(text)
    while index < length:
        char = text[index]
        if char == "-" and index + 1 < length and text[index + 1] == "-":
            match = _LONG_BRACKET.match(text, index + 2)
            if match:
                closer = "]" + match.group(1) + "]"
                end = text.find(closer, match.end())
                if end < 0:
                    raise LuaPayloadError("存在未闭合的长注释（--[[ ... ]]）")
                end += len(closer)
                out.append("".join(c for c in text[index:end] if c in "\r\n"))
                index = end
            else:
                end = text.find("\n", index)
                if end < 0:
                    end = length
                # 行注释整段删除，但保留行尾的 \r，避免把 CRLF 变成 LF。
                if end > index and text[end - 1] == "\r":
                    out.append("\r")
                index = end
            continue
        if char == '"' or char == "'":
            end = index + 1
            while end < length:
                current = text[end]
                if current == "\\":
                    end += 2
                    continue
                if current == char:
                    end += 1
                    break
                if current == "\n":
                    line = text.count("\n", 0, index) + 1
                    raise LuaPayloadError("第 %d 行字符串跨行未闭合，去注释已中止" % line)
                end += 1
            out.append(text[index:end])
            index = end
            continue
        match = _LONG_BRACKET.match(text, index) if char == "[" else None
        if match:
            closer = "]" + match.group(1) + "]"
            end = text.find(closer, match.end())
            if end < 0:
                raise LuaPayloadError("存在未闭合的长字符串")
            end += len(closer)
            out.append(text[index:end])
            index = end
            continue
        out.append(char)
        index += 1
    stripped = "".join(out)
    return stripped, payload_size(text) - payload_size(stripped)


def validate_stripped(source, stripped):
    """去注释的安全校验：行数不变、每行只减不增、再扫一遍不再有注释、
    再剥一次结果不变（幂等）。任何一条不满足都抛错，宁可不发也不发坏包。"""
    source_lines = source.split("\n")
    stripped_lines = stripped.split("\n")
    if len(source_lines) != len(stripped_lines):
        raise LuaPayloadError("去注释后行数变化：%d -> %d"
                              % (len(source_lines), len(stripped_lines)))
    for number, (original, current) in enumerate(zip(source_lines, stripped_lines), start=1):
        if not original.rstrip("\r").startswith(current.rstrip("\r")):
            raise LuaPayloadError("第 %d 行去注释后不再是原行的前缀，已中止" % number)
    again, _ = strip_lua_comments(stripped)
    if again != stripped:
        raise LuaPayloadError("去注释结果不幂等，已中止")
    return True


def build_payload(body, target_path):
    """返回 (payload 文本, 是否去掉了注释, 字节数)。body 必须是 CRLF 且无尾换行。

    低于安全余量线时原样发送（payload 与源文件逐字一致，便于比对）；
    一旦越过安全余量线就自动去注释，把预算留给真正的代码。
    """
    full = PAYLOAD_PREFIX + body
    size = payload_size(full)
    if size <= PAYLOAD_WARN_LIMIT:
        return full, False, size
    stripped, saved = strip_lua_comments(body)
    validate_stripped(body, stripped)
    compact = PAYLOAD_PREFIX + stripped
    compact_size = payload_size(compact)
    if compact_size > PAYLOAD_HARD_LIMIT:
        raise LuaPayloadError(
            "%s 去注释后仍为 %d B，超过 %d B 上限（还超 %d B）；"
            "请把内容拆到新的 lua 文件/payload 节点"
            % (target_path, compact_size, PAYLOAD_HARD_LIMIT,
               compact_size - PAYLOAD_HARD_LIMIT))
    print("        %s payload %d B 已越过安全余量线，自动去注释 -> %d B（省 %d B）"
          % (target_path, size, compact_size, saved))
    return compact, True, compact_size
