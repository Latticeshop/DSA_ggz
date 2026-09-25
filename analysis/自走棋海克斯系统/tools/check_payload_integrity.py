# -*- coding: utf-8 -*-
"""提取 ScriptsData.json 的 UtilsLuckyCrate payload，检查完整性：
行数、末尾几行、首 35 行、end/then/do/function 结构配对。"""
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import find_repo_root  # noqa: E402

with open(os.path.join(find_repo_root(), 'ScriptsData.json'), encoding='utf-8') as f:
    raw = f.read()

pattern = re.compile(r'"(?:\\.|[^"\\])*"')
payload = None
for m in pattern.finditer(raw):
    if not m.group().startswith('"#!ra3luabridge'):
        continue
    try:
        s = json.loads(m.group())
    except json.JSONDecodeError:
        continue
    if 'function NoCreatesInCenter' not in s:
        continue
    payload = s
    break

if payload is None:
    print('未找到 UtilsLuckyCrate payload')
    raise SystemExit(1)

# 去掉前缀，按行拆分
body = payload[len('#!ra3luabridge\r\n'):]
lines = body.split('\r\n')
print('payload 总长度:', len(payload))
print('去掉前缀后行数:', len(lines))
print()
print('=== 首 35 行 ===')
for i, line in enumerate(lines[:35], 1):
    print('%4d| %s' % (i, line))
print()
print('=== 末尾 10 行 ===')
for i, line in enumerate(lines[-10:], len(lines) - 9):
    print('%4d| %s' % (i, line))

# 结构关键字配对统计（忽略注释和字符串粗略统计）
def strip_comments(code):
    out = []
    for line in code.split('\n'):
        # 去掉 -- 注释（简单处理，不含字符串内的 --）
        idx = line.find('--')
        if idx >= 0:
            line = line[:idx]
        out.append(line)
    return '\n'.join(out)

code = strip_comments(body)
words = re.findall(r'\b(end|then|do|function|if|for|while|repeat|until)\b', code)
counts = {}
for w in words:
    counts[w] = counts.get(w, 0) + 1
print()
print('=== 结构关键字统计 ===')
for k in ('if', 'then', 'for', 'do', 'while', 'function', 'end', 'repeat', 'until'):
    print('  %-8s: %d' % (k, counts.get(k, 0)))
print()
print('if 数量 == then 数量:', counts.get('if', 0) == counts.get('then', 0))
print('(for+while) 数量 == do 数量:', counts.get('for', 0) + counts.get('while', 0) == counts.get('do', 0))
print('(then+do+function) 数量 == end 数量:', counts.get('then', 0) + counts.get('do', 0) + counts.get('function', 0) == counts.get('end', 0))
