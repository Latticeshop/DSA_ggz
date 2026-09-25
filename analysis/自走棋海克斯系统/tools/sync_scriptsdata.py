# -*- coding: utf-8 -*-
"""与 Sync-ScriptsData.ps1 等价的 Python 同步脚本。
将 lua 目录下的源文件内容回填到 ScriptsData.json 中对应的 #!ra3luabridge payload。
用法: python sync_scriptsdata.py [--check-only]

payload 体积受 WorldBuilder 脚本字符串约 64KB 上限限制：超过会被截断并在游戏内
报 `last token read: '<eof>'` 语法错误。因此本脚本复用 lua_payload.build_payload()：
放得下就与源文件逐字一致，放不下就自动去掉 Lua 注释（注释不执行，只占预算），
去注释后仍超限则中止同步。源文件始终保留完整注释。
"""
import json
import re
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lua_payload import (  # noqa: E402
    PAYLOAD_HARD_LIMIT, PAYLOAD_WARN_LIMIT, LuaPayloadError, build_payload,
    find_repo_root, normalize_crlf,
)

REPO_ROOT = find_repo_root()
JSON_PATH = os.path.join(REPO_ROOT, 'ScriptsData.json')

TARGETS = [
    ('lua/GAME/MIRRORTOWER/unlockT4Ship.lua', ['local enableT4Ship = {', 'Sea3ProtectShip8']),
    ('lua/GAME/MIRRORTOWER/unlockT4Ship22.lua', ['local enableT4Ship = {', 'Sea3ProtectShip7']),
    ('lua/GAME/ShrinkMode_Trigger.lua', ['if g_EnableShrinkMode == 1 then', 'ShrinkMode_Apply()']),
    ('lua/GAME/T71Unlock.lua', ['if g_GameMode ~= 4 then', 'Player_4/UNLOCK1__4', 'PlyrCreeps']),
    ('lua/GAME/T72Unlock.lua', ['if g_GameMode ~= 4 then', 'Player_4/UNLOCK2__4', 'PlyrCreeps']),
    ('lua/GAME/T73Unlock.lua', ['if g_GameMode ~= 4 then', 'Player_4/UNLOCK3__4']),
    ('lua/GAME/T81Unlock.lua', ['if g_GameMode ~= 4 then', 'Player_1/UNLOCK1__1', 'PlyrCivilian']),
    ('lua/GAME/T82Unlock.lua', ['if g_GameMode ~= 4 then', 'Player_1/UNLOCK2__1', 'PlyrCivilian']),
    ('lua/GAME/T83Unlock.lua', ['if g_GameMode ~= 4 then', 'Player_1/UNLOCK3__1']),
    ('lua/GAME/UnitCreate.lua', ['g_UnitCreateEventFunc = {}', 'function onUnitCreateEvent']),
    ('lua/GAME/UnitDie.lua', ['g_UnitDieEventFunc =', 'function onUnitDieEvent',
        'CelestialBatteryDie']),
    ('lua/GAME/RecycleUnit.lua', ['g_CurrentRecycleType = {', 'function RemoveRecycleUnitCount', 'g_RecycleBtnsMapByFaction']),
    ('lua/GAME/RescueBlockedProductions.lua', ['RescueBlockedProductions_UnitList = {', 'function RescueBlockedProductions_CheckUnitCanBuild']),
    ('lua/GAME/GiveFreeNavelYardAtBegin.lua', ['\nlocal freeNavalYard = {', 'freeNavelYard']),
    ('lua/GAME/GiveFreeStructure__2.lua', ['local freeAirField = {', 'freeAirField', 'TryEnableLuckyCrateIfAllowed()']),
    ('lua/GAME/ExtraCommand.lua', ['g_BanSeaFilter = CreateObjectFilter', 'function MsgCommand_BanInfantry', 'function onUserHotKeyEvent']),
    ('lua/LUABOX/BUTTON/devilASuper_0.lua', ['g_DevilChronosphereTransportIndex', 'devilChronosphereTransport']),
    ('lua/LUABOX/BUTTON/angelASuper_0.lua', ['g_AngelChronosphereTransportIndex', 'angelChronosphereTransport']),
    ('lua/LUABOX/BUTTON/CenterTopBtnFunc.lua', ['g_RecycleEconomicRate', 'function GetBaseRecycleRate', 'RequestDragonShip']),
    # ('lua/GAME/UtilsLuckyCrate.lua', ['-- 启用箱子模式', 'function NoCreatesInCenter']),  # 已拆分，改由 sync_utils_lucky_crate.py 拼接同步
    ('lua/LUABOX/BUTTON/BtnChoiceDialogEventFunc.lua', ['devil_max = 200', 'function BtnChoiceDialogEventFunc_ShowGameModeDialog']),
    ('lua/LUABOX/UNITCOUNTERINI_0.lua', ['FilterLIST = {}', 'function unitgetcountanddelet']),
    ('lua/LUABOX/moneysys/MONEYINI_3.lua', ['LIMITPOWERC = 4', 'function GetPlayerYaoguangCount', 'function LIMITYAOGUANG']),
    ('lua/cams/OpenMode.lua', ['if g_GameMode == 2 or g_EnableDeathModeEffect == 1 then', 'RecycleUnit_Setting()']),
    ('lua/text/Localization.lua', ['Localization = Localization or {}', 'Localization._text_sources']),
    # 海克斯符文系统：由 add_hextech_scripts.py 首次插入 LUABOX/BUTTON 节点，
    # 后续改动用这里的按需回填即可，避免整文件重排与转义噪声。
    ('lua/GAME/HextechRune/00_assets.lua', ['local HextechFrameGold = {', 'g_HextechFrameGoldId']),
    ('lua/GAME/HextechRune/01_rune_pool.lua', ['HextechRune.RunePool = {', 'PickBuyTwoGetOneTarget']),
    ('lua/GAME/HextechRune/02_event.lua', ['function HextechRune:ShowFormalEvent', 'function HextechRune:OnRoundBegin']),
    ('lua/GAME/HextechRune/04_buff.lua', ['HextechRune.BattleUnitEffectDelay', 'ApplyFiveTigerGenerals']),
    ('lua/GAME/HextechRune/05_ultimate_creature.lua', ['ApplyUltimateCreatures', 'UltimateCreatureScale']),
    ('lua/GAME/HextechRune/06_ascension.lua', ['AscensionRateOfFirePerUnit', 'CreateAscensionModifier']),
]


def find_json_strings(raw):
    """与 PowerShell [regex]::Matches($raw, '"(?:\\\\.|[^"\\\\])*"') 等价。"""
    pattern = re.compile(r'"(?:\\.|[^"\\])*"')
    return list(pattern.finditer(raw))


def main():
    check_only = '--check-only' in sys.argv
    with open(JSON_PATH, 'r', encoding='utf-8', newline='') as f:
        raw = f.read()

    string_matches = find_json_strings(raw)
    replacements = []
    sizes = []

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
        if len(candidates) != 1:
            print('ERROR: expected one ScriptsData payload for %s, found %d' % (target_path, len(candidates)))
            sys.exit(1)
        with open(os.path.join(REPO_ROOT, target_path), 'r', encoding='utf-8', newline='') as f:
            body = f.read()
        body = normalize_crlf(body)
        body = body.rstrip('\r\n')
        # 放得下就与源文件逐字一致；超过 64KB 上限时自动去掉注释（注释不执行却占预算）。
        try:
            payload, stripped, size = build_payload(body, target_path)
        except LuaPayloadError as error:
            print('ERROR: %s' % error)
            sys.exit(1)
        sizes.append((size, target_path, stripped))
        # 沿用该 payload 原有转义风格：海克斯符文节点由 add_hextech_scripts.py
        # 以 UTF-8 原文写入，其余节点是 \uXXXX 转义。
        # 统一成同一种写法会把整行 payload 全部改写，产生无意义的大 diff。
        was_escaped = all(ord(ch) < 128 for ch in candidates[0].group())
        encoded = json.dumps(payload, ensure_ascii=was_escaped)
        replacements.append((target_path, candidates[0].start(), candidates[0].end(), encoded))
        print('matched %-52s %6d B (余 %6d B)%s' % (
            target_path, size, PAYLOAD_HARD_LIMIT - size,
            '  已去注释' if stripped else ''))

    print()
    print('payload 体积最大的 5 个（上限 %d B）：' % PAYLOAD_HARD_LIMIT)
    for size, path, stripped in sorted(sizes, reverse=True)[:5]:
        flag = '   <== 贴近上限，注意不要再加内容' if size > PAYLOAD_WARN_LIMIT else ''
        print('  %6d B (余 %6d B)  %s%s%s' % (
            size, PAYLOAD_HARD_LIMIT - size, path, '（已去注释）' if stripped else '', flag))

    if check_only:
        print('check-only: %d targets matched' % len(replacements))
        return

    for target_path, start, end, encoded in sorted(replacements, key=lambda r: r[1], reverse=True):
        raw = raw[:start] + encoded + raw[end:]

    with open(JSON_PATH, 'w', encoding='utf-8', newline='') as f:
        f.write(raw)

    # 验证整个 JSON 仍然合法
    with open(JSON_PATH, 'r', encoding='utf-8', newline='') as f:
        json.load(f)
    print('ScriptsData.json updated and validated OK')


if __name__ == '__main__':
    main()
