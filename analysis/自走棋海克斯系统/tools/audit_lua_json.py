# -*- coding: utf-8 -*-
"""全树内容审计：确认 lua/ 里每个文件的逻辑都真的进了 ScriptsData.json。

用法:
    python "analysis/自走棋海克斯系统/tools/audit_lua_json.py"

不看「登记名单」：sync_scriptsdata.py 的 TARGETS 只列日常维护的 30 多个文件，其余上百个老脚本
没人改过、内容与 JSON 仍逐字相同，不需要登记。判定一律按内容：某个 lua 文件在 JSON 里找不到
对应 payload，才是真问题（要么忘了同步，要么 JSON 侧已经更新而 lua 是旧的）。

分类：
  OK          与某个 payload 逐字一致；或 JSON 侧是它的去注释版本（超过安全余量线时正常现象）。
  SPLIT       按 `--@节名` 分节的源文件（一个文件回填多个 payload），每节都要能对上。
  CONCAT      由 sync_utils_lucky_crate.py 以多分片拼接方式同步的 PureDraw/**。
  LEGACY      文件头部写明「旧版保留 / 历史参考 / 不生效」，本就不参与地图逻辑。
  COSMETIC    差异只在注释与空白，可执行代码逐行相同（不影响运行）。
  DRIFT       以上都不是 —— 必须确认以哪一侧为准。
"""
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from lua_payload import find_repo_root, normalize_crlf, split_sections, strip_lua_comments  # noqa: E402

ROOT = find_repo_root()
JSON_PATH = os.path.join(ROOT, "ScriptsData.json")
LUA_ROOT = os.path.join(ROOT, "lua")
PREFIX = "#!ra3luabridge"
CONCAT_DIRS = ("lua/GAME/PureDraw/",)
LEGACY_PATTERN = re.compile(u"旧版|历史参考|不生效|不再|已无实际逻辑|仅供")


def uncomment(text):
    # strip_lua_comments 返回 (新文本, 省下的字节数)，这里只要文本。
    return strip_lua_comments(text)[0]


def strip_prefix(text):
    text = normalize_crlf(text)
    stripped = text.lstrip()
    if stripped.startswith(PREFIX):
        text = stripped[len(PREFIX):]
    return text


def norm(text):
    text = strip_prefix(text)
    lines = [ln.rstrip() for ln in text.split("\n")]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    return "\n".join(lines)


def code_only(text):
    """只留可执行代码行，并压掉行内空白 —— 用于识别「差异仅为注释/空白」。"""
    text = strip_prefix(uncomment(text))
    out = []
    for line in text.split("\n"):
        s = line.strip()
        if not s or s.startswith("--"):
            continue
        out.append(re.sub(r"\s+", " ", s))
    return "\n".join(out)


def repo_rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def main():
    raw = io.open(JSON_PATH, encoding="utf-8", newline="").read()
    payloads = []
    for m in re.compile(r'"(?:\\.|[^"\\])*"').finditer(raw):
        if not m.group().startswith('"' + PREFIX):
            continue
        try:
            payloads.append(json.loads(m.group()))
        except ValueError:
            pass

    exact = set()
    code = set()
    for p in payloads:
        exact.add(norm(p))
        exact.add(norm(uncomment(p)))
        code.add(code_only(p))

    counts = {"OK": 0, "SPLIT": 0, "CONCAT": 0, "LEGACY": 0, "COSMETIC": 0, "DRIFT": 0}
    report = {"COSMETIC": [], "DRIFT": []}
    total = 0

    def code_match(text):
        return code_only(text) in code

    def exact_match(text):
        return norm(text) in exact or norm(uncomment(text)) in exact

    for dirpath, _dirs, names in sorted(os.walk(LUA_ROOT)):
        for fn in sorted(names):
            if not fn.endswith(".lua"):
                continue
            path = os.path.join(dirpath, fn)
            rel = repo_rel(path)
            text = io.open(path, encoding="utf-8-sig", errors="replace").read()
            total += 1
            # 分节文件：一个源文件按 --@节名 回填多个 payload，逐节校验。
            sections = split_sections(text)
            if sections is not None:
                missing = [name for name in sorted(sections)
                           if not (exact_match(sections[name]) or code_match(sections[name]))]
                if missing:
                    counts["DRIFT"] += 1
                    report["DRIFT"].append("%s（缺节：%s）" % (rel, ", ".join(missing)))
                else:
                    counts["SPLIT"] += 1
                continue
            if exact_match(text):
                counts["OK"] += 1
            elif rel.startswith(CONCAT_DIRS):
                counts["CONCAT"] += 1
            elif LEGACY_PATTERN.search(text[:800]):
                counts["LEGACY"] += 1
            elif code_match(text):
                counts["COSMETIC"] += 1
                report["COSMETIC"].append(rel)
            else:
                counts["DRIFT"] += 1
                report["DRIFT"].append(rel)

    print("ScriptsData.json 中的 lua payload = %d 个；lua/ 目录文件 = %d 个" % (
        len(payloads), total))
    print("OK 逐字/去注释一致        = %d" % counts["OK"])
    print("SPLIT --@节名 分节同步     = %d" % counts["SPLIT"])
    print("CONCAT 分片拼接同步        = %d  (PureDraw/**)" % counts["CONCAT"])
    print("LEGACY 标注旧版保留        = %d" % counts["LEGACY"])
    print("COSMETIC 仅注释/空白差异   = %d" % counts["COSMETIC"])
    for rel in report["COSMETIC"]:
        print("   ~ %s" % rel)
    print("DRIFT 真漂移               = %d" % counts["DRIFT"])
    for rel in report["DRIFT"]:
        print("   ! %s" % rel)
    print("")
    if counts["DRIFT"]:
        print("结论：以上文件在 ScriptsData.json 中找不到对应逻辑，需要确认以哪一侧为准。")
        return 1
    print("结论：lua/ 的全部逻辑都能在 ScriptsData.json 中找到（COSMETIC 不影响运行）。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
