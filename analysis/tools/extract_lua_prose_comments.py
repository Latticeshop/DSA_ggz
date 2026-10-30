#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 lua 源码里的"文本讲解注释"搬进 analysis/地图注释说明文档.md 附录 A。

[需求] ：
  - **文本讲解**（讲机制、记实测依据、记失败历史、写注意事项）→ 从 lua 删掉、移到文档，
    这样它不会占 ScriptsData.json 里那约 64KB 的 payload 预算；
  - **代码注释**（跟在代码上方的字段说明、参数清单、行尾提示）→ 留在 lua 里。

所以判定不能只看长度：先看内容，再看位置。规则写在 classify() 里，一块一个结论，
dry-run 会把「移出 / 留下」两块清单都打出来，便于人工复核（漏判就改规则重跑）。
误判成「讲解」的块用 KEEP_BLOCKS / KEEP_MARKERS 逐个登记保留，不靠改 classify() 的全局规则：
KEEP_BLOCKS 按「块起始行号」登记（源码一改行号就失效），KEEP_MARKERS 按「块首行正文」登记，
两者取其一命中即保留 —— 新增登记请优先用 KEEP_MARKERS。

安全约束：
  - 只处理连续 >= --min-run 行的"整行注释"；行尾注释一律不碰；
  - `[[ ... ]]` 长字符串内部的 -- 行不算注释（00_assets.lua / CenterTopBtnFunc.lua /
    Localization.lua 里有 base64 长字符串，误判会直接损坏数据）；
  - `--@节名` 是 sync_scriptsdata.py 的分节标记，永远不动；
  - 保持每个文件原有的 BOM 与换行风格（CRLF/LF）；
  - 默认 dry-run，--apply 才写文件（先补附录再改源码，中途出错不会出现"注释没了文档没写"）。

用法：
  python analysis/tools/extract_lua_prose_comments.py                  # 看清单
  python analysis/tools/extract_lua_prose_comments.py --list-kept      # 连留在源码的长块一起看
  python analysis/tools/extract_lua_prose_comments.py --apply          # 真改
  python analysis/tools/extract_lua_prose_comments.py --apply --file lua/GAME/x.lua ...
                                                                      # 附录已存在时按文件续补
"""
import argparse
import os
import re
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import find_repo_root  # noqa: E402

BASE = find_repo_root(os.path.abspath(__file__))
LUA_DIR = os.path.join(BASE, "lua")
DOC = os.path.join(BASE, "analysis", "地图注释说明文档.md")

# 这两个文件已手工整理（文档 §1），不再自动处理
EXCLUDE = {
    "lua/GAME/PassengerLoadSpawn.lua",
    "lua/GAME/ShrinkMode_Trigger.lua",
}

# classify() 把「叙述标记」当最强信号，于是把两类其实该留在源码的块也判成了讲解，逐个登记保留：
#   - 「恢复步骤说明 + 注释掉的代码」存档块：整块存在的意义就是就地取消注释即可恢复，
#     搬进文档反而要两头对照（01_rune_pool.lua 的符文条目、04_buff.lua 的派发分支）；
#   - 紧跟表/常量上方的字段说明（键名 ↔ 中文名对照），按口径属于代码注释。
# 键是文件相对路径，值是 { 块起始行号（1 起）: 保留理由 }。dry-run 会把这几个块打上「人工保留」。
KEEP_BLOCKS = {
    "lua/GAME/HextechRune/01_rune_pool.lua": {
        144: "恢复步骤 + 注释掉的符文条目（取消注释即可恢复的存档）",
    },
    "lua/GAME/HextechRune/04_buff.lua": {
        1621: "恢复步骤 + 注释掉的派发分支（取消注释即可恢复的存档）",
    },
    "lua/LUABOX/BUTTON/BtnChoiceDialogEventFunc.lua": {
        102: "市场塔原价表的字段说明（键名 ↔ 塔名对照）",
    },
}

# 行号会随源码改动漂移，所以再给一份「按块首行正文」的登记（优先用这份维护）：
# 键是文件相对路径，值是 (块首行里出现的片段, 保留理由)。命中 KEEP_BLOCKS 或本表都算人工保留。
KEEP_MARKERS = {
    "lua/GAME/HextechRune/01_rune_pool.lua": [
        ("协议授予·金·冷冻卫星", "恢复步骤 + 注释掉的符文条目（取消注释即可恢复的存档）"),
        ("协议授予·金·现金奖励", "恢复步骤 + 注释掉的符文条目（取消注释即可恢复的存档）"),
    ],
    "lua/GAME/HextechRune/04_buff.lua": [
        ("协议授予·金·冷冻卫星", "恢复步骤 + 注释掉的派发分支（取消注释即可恢复的存档）"),
        ("恢复时取消下面两行注释", "恢复步骤 + 注释掉的派发分支（取消注释即可恢复的存档）"),
    ],
    "lua/LUABOX/BUTTON/BtnChoiceDialogEventFunc.lua": [
        ("市场塔原价", "市场塔原价表的字段说明（键名 ↔ 塔名对照）"),
    ],
    "lua/baselib/ScheduleModule.lua": [
        ("SchedulerModule.lua", "第三方库的 LuaDoc 文件头（文件名 / 作者 / 日期），不是讲解"),
    ],
    # 三个「旧版保留脚本」的文件头（说明本文件已不生效）：它们的 JSON 副本不在
    # sync_scriptsdata.py 的 TARGETS 里，改动源码会让 audit_lua_json.py 报 DRIFT
    # （2026-10-14 实测：搬走这三块 → DRIFT = 3），所以留在源码里。
    "lua/GAME/KillCelestialCore.lua": [
        ("旧版保留脚本", "旧版保留脚本的文件头；源码一改就会与 JSON 里的旧脚本不一致（DRIFT）"),
    ],
    "lua/GAME/SpawnShips.lua": [
        ("旧版保留脚本", "旧版保留脚本的文件头；源码一改就会与 JSON 里的旧脚本不一致（DRIFT）"),
    ],
    "lua/LUABOX/CelestialBomberAircraft_TriggierChangeMode.lua": [
        ("旧版保留脚本", "旧版保留脚本的文件头；源码一改就会与 JSON 里的旧脚本不一致（DRIFT）"),
    ],
}

POINTER_FMT = "-- 讲解见 analysis/地图注释说明文档.md 附录 A.%d"
POINTER_RE = re.compile(r"^-- 讲解见 analysis/地图注释说明文档\.md 附录 A\.[0-9A.、]+$")
APPENDIX_TITLE = "## 附录 A. 从 lua 源码移出的讲解注释"

# 叙述标记：命中任一即判定整块是"文本讲解"（本项目的依据写法是 [实测]/[先例]/教训…）
NARRATIVE = (
    "[实测]", "[需求]", "[先例]", "实测", "教训", "为什么", "结论", "已验证", "之所以",
    "背景", "原则", "做法", "方案", "早先", "别再", "一律不", "反而会", "否则会",
)

# 逐行分型用：lua 关键字/赋值开头的行是"注释掉的代码"，不是讲解
KEYWORD_RE = re.compile(r"^(if|for|while|function|return|end|local|else|elseif|then|do|and|or|not)\b")
ASSIGN_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_.\[]]*\s*=")
CODE_TOKENS = "=(){}[]"
CJK = lambda s: sum(1 for ch in s if u"\u4e00" <= ch <= u"\u9fff")
LONG_COMMENT = re.compile(r"^--+\[(=*)\[")


def read_text(path):
    with open(path, "rb") as f:
        data = f.read()
    bom = b"\xef\xbb\xbf" if data.startswith(b"\xef\xbb\xbf") else b""
    text = data[len(bom):].decode("utf-8", errors="replace")
    style = "crlf" if text.count("\r\n") else "lf"
    return text.replace("\r\n", "\n").replace("\r", "\n"), bom, style


def write_text(path, text, bom, style):
    if style == "crlf":
        text = text.replace("\n", "\r\n")
    with open(path, "wb") as f:
        f.write(bom)
        f.write(text.encode("utf-8"))


def comment_mask(lines):
    """每行是否"整行注释"。[[ ... ]] 长字符串内部一律 False。"""
    mask = []
    depth = 0
    for line in lines:
        in_long = depth > 0
        i = 0
        n = len(line)
        while i < n:
            if depth > 0:
                if line.startswith("]" + "=" * depth + "]", i):
                    depth = 0
                    i += 2 + depth
                    continue
                i += 1
                continue
            ch = line[i]
            if ch == "[":
                eq = 0
                while i + 1 + eq < n and line[i + 1 + eq] == "=":
                    eq += 1
                if line.startswith("[" + "=" * eq + "[", i):
                    closer = "]" + "=" * eq + "]"
                    end = line.find(closer, i + eq + 2)
                    if end < 0:
                        depth = eq
                        i = n
                    else:
                        i = end + len(closer)
                    continue
            if ch in "\"'":
                quote = ch
                i += 1
                while i < n and line[i] != quote:
                    i += 2 if line[i] == "\\" else 1
                i += 1
                continue
            if ch == "-" and line.startswith("--", i) and not LONG_COMMENT.match(line, i):
                break
            i += 1
        stripped = line.strip()
        if stripped.startswith("--@"):
            mask.append(False)
            continue
        mask.append(not in_long and stripped.startswith("--"))
    return mask


def find_blocks(lines, mask, min_run):
    blocks = []
    i = 0
    n = len(lines)
    while i < n:
        if mask[i]:
            j = i
            while j < n and mask[j]:
                j += 1
            if j - i >= min_run:
                blocks.append((i, j))
            i = j
        else:
            i += 1
    return blocks


def is_header_block(lines, start):
    """块前面全是空行/注释 = 它就是文件开头的整体说明块。"""
    for k in range(start):
        if lines[k].strip() and not lines[k].strip().startswith("--"):
            return False
    return True


def line_kind(comment_line):
    """单行整行注释的分型：code（注释掉的代码 / 字段清单）/ prose（中文讲解）/ other。"""
    body = comment_line.strip()
    while body.startswith("-"):
        body = body[1:].strip()
    if not body:
        return "blank"
    if body.startswith("@") or KEYWORD_RE.match(body) or ASSIGN_RE.match(body) \
            or body[0] in "{[":
        return "code"
    tokens = sum(body.count(ch) for ch in CODE_TOKENS)
    cjk = CJK(body)
    if cjk >= 4 and tokens <= 2:
        return "prose"
    if tokens >= 3 or (cjk <= 1 and "=" in body):
        return "code"
    return "other"


def classify(comment_lines, header):
    """返回 (是否移出, 理由)。comment_lines 是块内的原始行。"""
    kinds = [line_kind(l) for l in comment_lines]
    text = [k for k in kinds if k != "blank"]
    if not text:
        return False, "空块"
    prose = text.count("prose")
    code = text.count("code")
    hits = sum(1 for l in comment_lines if any(k in l for k in NARRATIVE))
    if hits:
        return True, "叙述标记 %d/%d 行" % (hits, len(text))
    if code >= max(2, int(len(text) * 0.5)):
        return False, "注释掉的代码/字段清单 %d/%d 行" % (code, len(text))
    if prose >= max(3, int(len(text) * 0.6)):
        return True, "中文讲解 %d/%d 行" % (prose, len(text))
    if header:
        return True, "文件头整体说明"
    return False, "就地代码注释 %d/%d 行" % (prose, len(text))


def collect(min_run, only_rels):
    targets = []
    for root, _dirs, files in os.walk(LUA_DIR):
        for fn in sorted(files):
            if not fn.endswith(".lua"):
                continue
            full = os.path.join(root, fn)
            rel = os.path.relpath(full, BASE).replace("\\", "/")
            if rel in EXCLUDE or (only_rels and rel not in only_rels):
                continue
            text, bom, style = read_text(full)
            lines = text.split("\n")
            mask = comment_mask(lines)
            blocks = find_blocks(lines, mask, min_run)
            if not blocks:
                continue
            verdicts = []
            for a, b in blocks:
                prose, why = classify(lines[a:b], is_header_block(lines, a))
                keep_reason = KEEP_BLOCKS.get(rel, {}).get(a + 1)
                if keep_reason is None:
                    for marker, reason in KEEP_MARKERS.get(rel, []):
                        if marker in lines[a]:
                            keep_reason = reason
                            break
                if prose and keep_reason:
                    prose, why = False, "人工保留：%s" % keep_reason
                verdicts.append({"a": a, "b": b, "prose": prose, "why": why,
                                 "bytes": len("\n".join(lines[a:b]).encode("utf-8"))})
            moved = sum(v["bytes"] for v in verdicts if v["prose"])
            targets.append({"rel": rel, "text": text, "lines": lines, "mask": mask,
                            "verdicts": verdicts, "moved": moved,
                            "kept": sum(v["bytes"] for v in verdicts if not v["prose"]),
                            "bom": bom, "style": style})
    targets.sort(key=lambda t: -t["moved"])
    return targets


def dedent(text_lines):
    strip = [l for l in text_lines if l.strip()]
    if not strip:
        return text_lines
    indent = min(len(l) - len(l.lstrip()) for l in strip)
    return [l[indent:] if l.strip() else "" for l in text_lines]


def follow_code(lines, mask, end):
    for k in range(end, min(end + 12, len(lines))):
        if not mask[k] and lines[k].strip():
            return lines[k].strip()[:70]
    return "(文件末尾)"


def doc_section(rel, target, section_no):
    entries = target["entries"]
    out = ["### A.%d `%s`（移出 %d 段 / %d 字节；另有 %d 字节代码注释留在源码）"
           % (section_no, rel, len(entries), target["moved"], target["kept"]), ""]
    for idx, e in enumerate(entries, 1):
        out.append("#### A.%d.%d 原第 %d-%d 行（%s），后接 `%s`" %
                   (section_no, idx, e["start"] + 1, e["end"], e["why"], e["follow"]))
        out.append("")
        out.append("```lua")
        out.extend(e["text"])
        out.append("```")
        out.append("")
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--min-run", type=int, default=3)
    ap.add_argument("--file", dest="only_rels", action="append", default=None,
                    help="只处理指定文件（可重复；用于给已有附录续补）")
    ap.add_argument("--start-section", type=int, default=0,
                    help="A.x 起始编号；默认接着现有附录的最大编号继续")
    ap.add_argument("--no-doc", action="store_true",
                    help="只改源码（配 --file/--start-section 用：该文件的讲解已在附录里）")
    ap.add_argument("--list-kept", action="store_true", help="连留在源码里的长注释块一起列")
    args = ap.parse_args()

    all_targets = collect(args.min_run, args.only_rels)
    targets = [t for t in all_targets if t["moved"]]
    print(">= %d 行的整行注释块：合计 %d B / %d 个文件；判为讲解 %d B / %d 个文件，"
          "判为代码注释留 %d B" % (args.min_run, sum(t["moved"] + t["kept"] for t in all_targets),
                                   len(all_targets), sum(t["moved"] for t in all_targets),
                                   len(targets), sum(t["kept"] for t in all_targets)))
    for t in all_targets:
        print("  移出 %6d B（留 %6d B）  %s" % (t["moved"], t["kept"], t["rel"]))
        if t["rel"] not in [x["rel"] for x in targets] and not args.list_kept:
            continue
        for v in t["verdicts"]:
            if v["prose"]:
                print("          移出 %3d-%-3d %6d B  %s" %
                      (v["a"] + 1, v["b"], v["bytes"], v["why"]))
            elif args.list_kept:
                print("          留下 %3d-%-3d %6d B  %s" %
                      (v["a"] + 1, v["b"], v["bytes"], v["why"]))
    if not args.apply:
        print("\n[dry-run] 未改动任何文件；确认后用 --apply")
        return 0

    doc_text, doc_bom, doc_style = read_text(DOC)
    head = doc_text.rstrip("\n")
    if APPENDIX_TITLE in head and not args.only_rels:
        print("[FAIL] 附录 A 已存在。重跑请先删掉附录 A，或用 --file 单独补一个文件")
        return 1
    if not args.only_rels:
        head += ("\n\n---\n\n" + APPENDIX_TITLE + "\n\n"
                 "由 `analysis/tools/extract_lua_prose_comments.py` 从 lua 源码整块搬来；"
                 "每段标了原行号与判定理由，便于回源码定位。\n"
                 "**留在源码里的只有代码注释**（字段清单、行尾提示、不足 %d 行的短注释），"
                 "它们跟着代码走、也一起进 payload。\n" % args.min_run)
    start_section = args.start_section
    if start_section <= 0:
        used = [int(m) for m in re.findall(r"^### A\.(\d+)", head, re.M)]
        start_section = (max(used) + 1) if used else 1
    for offset, t in enumerate(targets):
        section_no = start_section + offset
        t["section"] = section_no
        t["entries"] = [{"start": v["a"], "end": v["b"],
                         "follow": follow_code(t["lines"], t["mask"], v["b"]),
                         "why": v["why"], "text": dedent(t["lines"][v["a"]:v["b"]]),
                         "bytes": v["bytes"]}
                        for v in t["verdicts"] if v["prose"]]
        if not args.no_doc:
            # 每个新节统一和前一节隔两个空行（含接在旧文档末尾的第一节，否则会和上一节的
            # 代码围栏粘成一行）。
            head = head.rstrip("\n") + "\n\n"
            head += "\n" + "\n".join(doc_section(t["rel"], t, section_no)) + "\n"
    if args.no_doc:
        print("[--no-doc] 附录不动，只改源码：%d 个文件" % len(targets))
    else:
        write_text(DOC, head.rstrip("\n") + "\n", doc_bom, doc_style)
        print("已写入附录：%s" % DOC)

    for t in targets:
        lines = t["lines"]
        markers_before = [l.strip() for l in lines if l.strip().startswith("--@")]
        skip = set()
        for v in t["verdicts"]:
            if v["prose"]:
                skip.update(range(v["a"], v["b"]))
        out = [line for k, line in enumerate(lines) if k not in skip]
        while out and not out[0].strip():
            out.pop(0)
        # 已有指路行就往同一行追加编号（一个文件只留一行指路），否则在文件头插一行；
        # 指路行后补一个空行，免得它和下面的代码注释粘成一块被误判成头块。
        if out and POINTER_RE.match(out[0].strip()):
            out[0] = out[0].rstrip() + ("、A.%d" % t["section"])
        else:
            out[0:0] = [POINTER_FMT % t["section"], ""]
        markers_after = [l.strip() for l in out if l.strip().startswith("--@")]
        if markers_after != markers_before:
            print("[FAIL] %s 的分节标记 --@ 被改动（%s -> %s），已中止" %
                  (t["rel"], markers_before, markers_after))
            return 1
        write_text(os.path.join(BASE, t["rel"]), "\n".join(out), t["bom"], t["style"])
        print("已移出 %-52s %6d B / %d 段" % (t["rel"], t["moved"], len(t["entries"])))
    print("合计释放 %d 字节" % sum(t["moved"] for t in targets))
    return 0


if __name__ == "__main__":
    sys.exit(main())
