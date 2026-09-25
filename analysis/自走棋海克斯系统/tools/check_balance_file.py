# -*- coding: utf-8 -*-
"""括号平衡检查器（参数化文件路径）：忽略字符串和注释，检查 Lua 代码的 () {} [] 平衡。
用法: python check_balance_file.py <lua路径>
"""
import re
import sys

path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    code = f.read()

lines = code.split('\n')
cleaned_lines = []
for line in lines:
    out = []
    in_str = None
    i = 0
    while i < len(line):
        c = line[i]
        if in_str:
            out.append(c)
            if c == '\\' and i + 1 < len(line):
                out.append(line[i+1])
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
        if c == '-' and i + 1 < len(line) and line[i+1] == '-':
            break
        out.append(c)
        i += 1
    cleaned_lines.append(''.join(out))

code2 = '\n'.join(cleaned_lines)
stack = []
pairs = {')': '(', ']': '[', '}': '{'}
opens = set('([{')
closes = set(')]}')
line_no = 1
in_str = None
i = 0
n = len(code2)
err = None
while i < n:
    c = code2[i]
    if c == '\n':
        line_no += 1
        i += 1
        continue
    if in_str:
        if c == '\\':
            i += 2
            continue
        if c == in_str:
            in_str = None
        i += 1
        continue
    if c == '"' or c == "'":
        in_str = c
        i += 1
        continue
    if c in opens:
        stack.append((c, line_no))
    elif c in closes:
        if not stack:
            err = '多余闭合 %s at line %d' % (c, line_no)
            break
        top, top_line = stack.pop()
        if top != pairs[c]:
            err = '不匹配: line %d 的 %s vs line %d 的 %s' % (top_line, top, line_no, c)
            break
    i += 1

if err:
    print('FAIL: %s' % err)
    sys.exit(1)
if in_str:
    print('FAIL: 字符串未闭合')
    sys.exit(1)
if stack:
    print('FAIL: 未闭合括号 %d 个，首个 %s at line %d' % (len(stack), stack[0][0], stack[0][1]))
    sys.exit(1)
print('OK: 括号完全平衡')
