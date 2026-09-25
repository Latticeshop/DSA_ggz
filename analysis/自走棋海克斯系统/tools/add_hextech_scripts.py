# -*- coding: utf-8 -*-
"""向 ScriptsData.json 的 LUABOX/BUTTON 文件夹添加海克斯符文系统脚本节点。
执行顺序：资源 -> 符文池 -> 效果层 -> 究极生物 -> 事件/UI。
用法: python "analysis/自走棋海克斯系统/tools/add_hextech_scripts.py"
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import build_payload, find_repo_root  # noqa: E402

BASE = find_repo_root()
JSON_PATH = os.path.join(BASE, "ScriptsData.json")
LUA_DIR = os.path.join(BASE, "lua")


def make_script_node(name, payload):
    """构造 Script 节点：CONDITION_TRUE + DEBUG_MESSAGE_BOX(#!ra3luabridge 内容)"""
    return {
        "Type": "Script",
        "Name": name,
        "DeactivateUponSuccess": True,
        "EvaluationInterval": 0,
        "If": [
            [
                {
                    "Name": "CONDITION_TRUE",
                    "Name_EN_IGNORE": "[3] Scripting/True.",
                    "Name_ZH_IGNORE": "[3] 真实 真",
                    "ArgumentsDesc_IGNORE": " True.",
                    "ArgumentsType_IGNORE": [],
                }
            ]
        ],
        "Then": [
            {
                "Name": "DEBUG_MESSAGE_BOX",
                "Arguments": [payload],
                "Name_EN_IGNORE": "[0] Scripting/Debug/Display message and pause",
                "Name_ZH_IGNORE": "[0] 显示消息和暂停",
                "ArgumentsDesc_IGNORE": " Show debug string and pause: ",
                "ArgumentsType_IGNORE": ["String"],
            }
        ],
        "Else": [],
    }


def read_lua(rel_path):
    with open(os.path.join(LUA_DIR, rel_path), "r", encoding="utf-8-sig", errors="replace") as f:
        content = f.read()
    content = content.replace("\r\n", "\n").replace("\r", "\n")
    lines = [ln.rstrip() for ln in content.split("\n")]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    # 地图引擎（RA3LuaBridge）需要 CRLF 换行，统一转换为 \r\n
    return "\r\n".join(lines)


def find_folder(node, name):
    if isinstance(node, dict):
        if node.get("Type") == "Folder" and node.get("Name") == name:
            return node
        for child in node.get("Content", []) or []:
            r = find_folder(child, name)
            if r:
                return r
    elif isinstance(node, list):
        for item in node:
            r = find_folder(item, name)
            if r:
                return r
    return None


def main():
    with open(JSON_PATH, "r", encoding="utf-8-sig") as f:
        data = json.load(f)

    luabox = find_folder(data, "LUABOX")
    if luabox is None:
        print("ERROR: LUABOX folder not found")
        sys.exit(1)
    button = find_folder(luabox, "BUTTON")
    if button is None:
        print("ERROR: LUABOX/BUTTON folder not found")
        sys.exit(1)

    content = button.get("Content", [])
    specs = [
        ("HextechRuneAssets", "GAME/HextechRune/00_assets.lua"),
        ("HextechRunePool", "GAME/HextechRune/01_rune_pool.lua"),
        ("HextechRuneEffects", "GAME/HextechRune/04_buff.lua"),
        ("HextechRuneUltimateCreature", "GAME/HextechRune/05_ultimate_creature.lua"),
        ("HextechRuneEvent", "GAME/HextechRune/02_event.lua"),
        ("HextechRuneAscension", "GAME/HextechRune/06_ascension.lua"),
    ]
    hextech_names = set(name for name, _ in specs)
    existing = {}
    remaining = []
    for node in content:
        if isinstance(node, dict) and node.get("Type") == "Script" \
                and node.get("Name") in hextech_names:
            existing[node.get("Name")] = node
        else:
            remaining.append(node)

    ordered_nodes = []
    for name, rel_path in specs:
        body = read_lua(rel_path)
        # 超过 64KB 上限时自动去注释，避免 payload 被引擎截断（源文件保留注释）。
        payload, stripped, size = build_payload(body, "lua/" + rel_path)
        node = existing.get(name)
        if node is None:
            node = make_script_node(name, payload)
            print("added %-26s %6d B%s" % (name, size, "（已去注释）" if stripped else ""))
        else:
            node["Then"][0]["Arguments"][0] = payload
            print("updated %-26s %6d B%s" % (name, size, "（已去注释）" if stripped else ""))
        ordered_nodes.append(node)

    button["Content"] = remaining + ordered_nodes

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    # 验证 JSON 合法
    with open(JSON_PATH, "r", encoding="utf-8") as f:
        json.load(f)
    print("ScriptsData.json updated and validated OK")


if __name__ == "__main__":
    main()
