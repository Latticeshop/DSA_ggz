# -*- coding: utf-8 -*-
"""与 sync_scriptsdata.py 完全一致的机制，单独同步 lua/text/Update_0.lua。"""
import json
import re
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import find_repo_root  # noqa: E402

REPO_ROOT = find_repo_root()
JSON_PATH = os.path.join(REPO_ROOT, 'ScriptsData.json')

TARGETS = [
    ('lua/text/Update_0.lua', ['g_RuleText = Localization.get', 'g_UpdateBoxText']),
]


def normalize_crlf(value):
    return re.sub(r'\r?\n', '\r\n', value)


def find_json_strings(raw):
    pattern = re.compile(r'"(?:\\.|[^"\\])*"')
    return list(pattern.finditer(raw))


def main():
    with open(JSON_PATH, 'r', encoding='utf-8', newline='') as f:
        raw = f.read()

    string_matches = find_json_strings(raw)
    replacements = []

    for target_path, needles in TARGETS:
        candidates = []
        for m in string_matches:
            if not m.group().startswith('"#!ra3luabridge'):
                continue
            try:
                decoded = json.loads(m.group())
            except json.JSONDecodeError:
                continue
            if all(needle in decoded for needle in needles):
                candidates.append(m)
        print('匹配 payload 数:', len(candidates))
        if len(candidates) != 1:
            print('ERROR: expected one, found %d' % len(candidates))
            return 1
        with open(os.path.join(REPO_ROOT, target_path), 'r', encoding='utf-8', newline='') as f:
            body = f.read()
        body = normalize_crlf(body)
        body = body.rstrip('\r\n')
        encoded = json.dumps('#!ra3luabridge\r\n' + body, ensure_ascii=True)
        replacements.append((target_path, candidates[0].start(), candidates[0].end(), encoded))
        print('matched %s' % target_path)

    for target_path, start, end, encoded in sorted(replacements, key=lambda r: r[1], reverse=True):
        raw = raw[:start] + encoded + raw[end:]

    with open(JSON_PATH, 'w', encoding='utf-8', newline='') as f:
        f.write(raw)

    with open(JSON_PATH, 'r', encoding='utf-8', newline='') as f:
        json.load(f)
    print('ScriptsData.json updated and validated OK')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
