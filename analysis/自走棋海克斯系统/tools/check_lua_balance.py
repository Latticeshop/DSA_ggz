# -*- coding: utf-8 -*-
"""基础 Lua 语法平衡校验（括号/引号/关键字）"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import find_repo_root  # noqa: E402

REPO_ROOT = find_repo_root()

files = [
    'lua/LUABOX/BUTTON/BtnChoiceDialogEventFunc.lua',
    'lua/text/Localization.lua',
    'lua/GAME/HextechRune/00_assets.lua',
    'lua/GAME/HextechRune/01_rune_pool.lua',
    'lua/GAME/HextechRune/02_event.lua',
    'lua/GAME/HextechRune/04_buff.lua',
    'lua/GAME/HextechRune/05_ultimate_creature.lua',
    'lua/GAME/HextechRune/06_ascension.lua',
]


def strip_comments_strings(text):
    # 移除长注释 --[[ ]]
    text = re.sub(r'--\[\[.*?\]\]', '', text, flags=re.S)
    # 移除行注释
    text = re.sub(r'--[^\n]*', '', text)
    # 替换长字符串 [[ ]]
    text = re.sub(r'\[\[.*?\]\]', '""', text, flags=re.S)
    # 移除字符串字面量（保留空串占位）
    text = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    text = re.sub(r"'(?:\\.|[^'\\])*'", "''", text)
    return text


def check_balance(text):
    text = strip_comments_strings(text)
    stack = []
    pairs = {')': '(', ']': '[', '}': '{'}
    for i, ch in enumerate(text):
        if ch in '([{':
            stack.append((ch, i))
        elif ch in ')]}':
            if not stack or stack[-1][0] != pairs[ch]:
                return False, 'mismatch at char %d: %s' % (i, ch)
            stack.pop()
    if stack:
        return False, 'unclosed: %s at %d' % (stack[-1][0], stack[-1][1])
    return True, 'ok'


def check_keywords(text):
    """检查 function/if/for/while/end 的平衡（粗略）"""
    text = strip_comments_strings(text)
    # 词法切分
    tokens = re.findall(r'\b(function|if|then|elseif|else|end|for|while|do|repeat|until|local)\b', text)
    # 简化：统计 end 与 function/if/for/while/repeat 的数量
    openers = sum(1 for t in tokens if t in ('function', 'if', 'for', 'while', 'repeat'))
    ends = sum(1 for t in tokens if t == 'end')
    # do/then/until 与 for/while/if/repeat 配对（粗略，仅提示）
    return openers, ends


def main():
    all_ok = True
    for f in files:
        try:
            with open(os.path.join(REPO_ROOT, f), 'r', encoding='utf-8-sig') as fh:
                content = fh.read()
            ok, msg = check_balance(content)
            openers, ends = check_keywords(content)
            kw_hint = ''
            if abs(openers - ends) > 3:
                kw_hint = ' (注意: openers=%d ends=%d，可能不平衡，需人工确认)' % (openers, ends)
            status = 'PASS' if ok else 'FAIL'
            if not ok:
                all_ok = False
            print('%s: %s (%s)%s' % (f, status, msg, kw_hint))
        except Exception as e:
            all_ok = False
            print('%s: ERROR %s' % (f, e))
    sys.exit(0 if all_ok else 1)


if __name__ == '__main__':
    main()
