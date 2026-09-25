# -*- coding: utf-8 -*-
"""只更新 ScriptsData.json 中的 UtilsLuckyCrate payload（保持 .NET 转义风格）。
用法: python sync_utils_lucky_crate.py [--check-only]
"""
import json
import re
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import find_repo_root  # noqa: E402

REPO_ROOT = find_repo_root()
JSON_PATH = os.path.join(REPO_ROOT, 'ScriptsData.json')
# UtilsLuckyCrate 已拆分为 lua/GAME/PureDraw 下多个功能文件；payload 保持单文件 = 各文件按顺序拼接。
PURE_DRAW_DIR = os.path.join(REPO_ROOT, 'lua', 'GAME', 'PureDraw')
PURE_DRAW_PARTS = [
    '01_crate_event.lua',
    '02_data.lua',
    '03_quota.lua',
    '04_draw.lua',
    '05_crate_airdrop.lua',
    '06_init_mcv.lua',
]

NEEDLES = ['function NoCreatesInCenter', 'function PureLuckyCrateMode_Setting']


def strip_header_comment(body):
    """剥离文件头部的开发注释块（-- ==== 边框 或 -- PureDraw: 标题行开头的块），
    注释只给 lua 源码阅读用，JSON payload 只保留执行代码。
    正文中的普通 -- 注释（如 -- 启用箱子模式）保留。"""
    lines = body.split('\r\n')
    i = 0
    first = lines[0].strip() if lines else ''
    if first.startswith('-- ===') or first.startswith('-- PureDraw'):
        i = 1
        # 剥离连续的注释行（头部开发注释块）
        while i < len(lines):
            l = lines[i].strip()
            if l == '' or l.startswith('--'):
                i += 1
            else:
                break
        # 跳过块后的空行
        while i < len(lines) and lines[i].strip() == '':
            i += 1
        return '\r\n'.join(lines[i:])
    return body


def strip_lua_comments(body):
    """剥离 Lua -- 行注释（正确处理字符串内的 --），并去掉空行。
    JSON payload 只保留执行代码，注释只给 lua 源码阅读用。"""
    out_lines = []
    for line in body.split('\r\n'):
        out = []
        i = 0
        n = len(line)
        in_str = None
        while i < n:
            c = line[i]
            if in_str:
                out.append(c)
                if c == '\\' and i + 1 < n:
                    out.append(line[i + 1])
                    i += 2
                    continue
                if c == in_str:
                    in_str = None
                i += 1
                continue
            if c == '"' or c == "'":
                in_str = c
                out.append(c)
                i += 1
                continue
            if c == '-' and i + 1 < n and line[i + 1] == '-':
                break  # 行注释：截断
            out.append(c)
            i += 1
        # Lua 不依赖行首缩进。运行载荷去掉两侧空白，避免合并脚本超过
        # RA3LuaBridge 的约 64 KiB 字符串边界；分拆源码仍保留完整格式。
        line_out = ''.join(out).strip()
        if line_out.strip() != '':
            out_lines.append(line_out)
    return '\r\n'.join(out_lines)


def net_json_string(s):
    """模拟 .NET System.Text.Json 的字符串序列化风格：
    " -> \\u0022, \\ -> \\\\, \\r -> \\r, \\n -> \\n, 非 ASCII -> \\uXXXX(小写)。"""
    out = ['"']
    for ch in s:
        o = ord(ch)
        if ch == '"':
            out.append('\\u0022')
        elif ch == '\\':
            out.append('\\\\')
        elif ch == '\r':
            out.append('\\r')
        elif ch == '\n':
            out.append('\\n')
        elif ch == '\t':
            out.append('\\t')
        elif ch == '\b':
            out.append('\\b')
        elif ch == '\f':
            out.append('\\f')
        elif o < 0x20:
            out.append('\\u%04x' % o)
        elif o < 0x7F:
            out.append(ch)
        else:
            out.append('\\u%04x' % o)
    out.append('"')
    return ''.join(out)


def main():
    check_only = '--check-only' in sys.argv
    with open(JSON_PATH, 'r', encoding='utf-8', newline='') as f:
        raw = f.read()

    pattern = re.compile(r'"(?:\\.|[^"\\])*"')
    candidates = []
    for m in pattern.finditer(raw):
        if not m.group().startswith('"#!ra3luabridge'):
            continue
        try:
            decoded = json.loads(m.group())
        except json.JSONDecodeError:
            continue
        if all(n in decoded for n in NEEDLES):
            candidates.append(m)
    if len(candidates) != 1:
        print('ERROR: expected one UtilsLuckyCrate payload, found %d' % len(candidates))
        sys.exit(1)
    m = candidates[0]
    current_payload = json.loads(m.group())

    parts = []
    for part_name in PURE_DRAW_PARTS:
        part_path = os.path.join(PURE_DRAW_DIR, part_name)
        with open(part_path, 'r', encoding='utf-8', newline='') as f:
            part_body = f.read()
        part_body = re.sub(r'\r?\n', '\r\n', part_body)
        part_body = strip_header_comment(part_body)  # 剥离文件头开发注释块
        parts.append(part_body.rstrip('\r\n'))
    body = ('\r\n' * 2).join(parts)
    body = strip_lua_comments(body)  # 剥离所有 Lua 注释：JSON 只保留执行代码
    body = body.rstrip('\r\n')
    expected_payload = '#!ra3luabridge\r\n' + body
    encoded = net_json_string(expected_payload)

    if check_only:
        if current_payload != expected_payload:
            print('ERROR: UtilsLuckyCrate payload is out of sync (current=%d, expected=%d)'
                  % (len(current_payload), len(expected_payload)))
            sys.exit(1)
        print('check-only: UtilsLuckyCrate payload matches all %d PureDraw parts, length=%d'
              % (len(PURE_DRAW_PARTS), len(expected_payload)))
        return

    new_raw = raw[:m.start()] + encoded + raw[m.end():]

    # 验证整体 JSON 合法
    json.loads(new_raw)

    with open(JSON_PATH, 'w', encoding='utf-8', newline='') as f:
        f.write(new_raw)
    print('UtilsLuckyCrate payload updated in ScriptsData.json')


if __name__ == '__main__':
    main()
