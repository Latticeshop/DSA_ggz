# -*- coding: utf-8 -*-
"""与 Sync-ScriptsData.ps1 等价的 Python 同步脚本。
将 lua 目录下的源文件内容回填到 ScriptsData.json 中对应的 #!ra3luabridge payload。
用法: python sync_scriptsdata.py [--check-only]

TARGETS 每一项为 (lua 源文件, [定位用关键字])，可选第三项声明该段逻辑在 JSON 里重复几份
（默认 1 份），全部写成同一份源内容；可选第四项给出节名，表示源文件按 `--@节名`
切成多段、每段各回填一个 payload（用于逻辑只差参数的极短调用段，见 time_stop.lua）。

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
    find_repo_root, normalize_crlf, split_sections,
)

REPO_ROOT = find_repo_root()
JSON_PATH = os.path.join(REPO_ROOT, 'ScriptsData.json')

TARGETS = [  # fmt: skip
    ('lua/GAME/MIRRORTOWER/unlockT4Ship.lua', ['local enableT4Ship = {', 'Sea3ProtectShip8']),
    ('lua/GAME/MIRRORTOWER/unlockT4Ship22.lua', ['local enableT4Ship = {', 'Sea3ProtectShip7']),
    # lua/GAME/ShrinkMode_Trigger.lua 不在这张表里：它的 payload 末尾还合并了
    # PassengerLoadSpawn.lua（载具装填），必须两份源一起写，否则会互相覆盖。
    # 同步请用 analysis/merge_passenger_spawn_payload.py。
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
    ('lua/BUFF/T2tank_0.lua', ['T2tank=CreateObjectFilter', 'AlliedBattleFortress']),
    ('lua/BUFF/BUFF_1.lua', ['FilterJapanSentinelVehicle=CreateObjectFilter',
        'function JapanSentinelVehicleBUFF']),
    ('lua/GAME/RescueBlockedProductions.lua', ['RescueBlockedProductions_UnitList = {', 'function RescueBlockedProductions_CheckUnitCanBuild']),
    ('lua/GAME/GiveFreeNavelYardAtBegin.lua', ['\nlocal freeNavalYard = {', 'freeNavelYard']),
    ('lua/GAME/GiveFreeStructure__2.lua', ['local freeAirField = {', 'freeAirField', 'TryEnableLuckyCrateIfAllowed()']),
    ('lua/GAME/ExtraCommand.lua', ['g_BanSeaFilter = CreateObjectFilter', 'function MsgCommand_BanInfantry', 'function onUserHotKeyEvent']),
    ('lua/LUABOX/BUTTON/devilASuper_0.lua', ['g_DevilChronosphereTransportIndex', 'devilChronosphereTransport']),
    ('lua/LUABOX/BUTTON/angelASuper_0.lua', ['g_AngelChronosphereTransportIndex', 'angelChronosphereTransport']),
    ('lua/LUABOX/BUTTON/unit_button_0.lua', ['BOMBID', 'function onUnitTopBtnClickEvent']),
    ('lua/LUABOX/BUTTON/ButtonManager.lua', ['ButtonManager = {', 'function ButtonManager.SetButton',
        'function onCustomBtnClickEvent', '_multipleUseOnClick']),
    ('lua/LUABOX/BUTTON/time_stop.lua', ['T74, "units", true, 210'], 1, 'angel_cast'),
    ('lua/LUABOX/BUTTON/time_stop.lua', ['T74, "units", true, 60'], 1, 'angel_tick'),
    ('lua/LUABOX/BUTTON/time_stop.lua', ['T74, "units", false'], 1, 'angel_release'),
    ('lua/LUABOX/BUTTON/time_stop.lua', ['T84, "units2", true, 210'], 1, 'devil_cast'),
    ('lua/LUABOX/BUTTON/time_stop.lua', ['T84, "units2", true, 60'], 1, 'devil_tick'),
    ('lua/LUABOX/BUTTON/time_stop.lua', ['T84, "units2", false'], 1, 'devil_release'),
    ('lua/LUABOX/BUTTON/CenterTopBtnFunc.lua', ['g_RecycleEconomicRate', 'function GetBaseRecycleRate', 'RequestDragonShip']),
    # ('lua/GAME/UtilsLuckyCrate.lua', ['-- 启用箱子模式', 'function NoCreatesInCenter']),  # 已拆分，改由 sync_utils_lucky_crate.py 拼接同步
    ('lua/LUABOX/BUTTON/BtnChoiceDialogEventFunc.lua', ['devil_max = 200', 'function BtnChoiceDialogEventFunc_ShowGameModeDialog']),
    ('lua/LUABOX/UNITCOUNTERINI_0.lua', ['FilterLIST = {}', 'function unitgetcountanddelet']),
    ('lua/LUABOX/moneysys/MONEYINI_3.lua', ['LIMITPOWERC = 4', 'function GetPlayerYaoguangCount', 'function LIMITYAOGUANG']),
    # MONEYINI_1（自由贸易结算）原先同样漏登记：节点一直在 JSON 里、内容与源逐字一致，
    # 但改它不会被同步。2026-10-24 把「只认盟军电厂」改成「按持币人自己的全部电厂」时发现。
    ('lua/LUABOX/moneysys/MONEYINI_1.lua',
     ['function addmoneyAllied', 'NAMED_NOT_DESTROYED', 'UNIT_HAS_MODELCONDITION']),
    ('lua/cams/OpenMode.lua', ['if g_GameMode == 2 or g_EnableDeathModeEffect == 1 then', 'RecycleUnit_Setting()']),
    # 这两个模式脚本原先没登记：节点一直在 JSON 里、内容与 lua 源逐字一致，但改它们不会被同步
    # （2026-10-14 补「删守护神展示体前解除登记」时发现，顺手登记进来）。BasicVar1 同样漏登记。
    ('lua/GAME/BasicVar1.lua', ['g_TowerGuardianUnitIds = g_TowerGuardianUnitIds or {}',
        'SpawnTowerGuardian']),
    ('lua/GAME/PurchaseTechMode_Logic.lua', ['PurchaseTechMode_Setting', 'g_maxTechLevelDecreaseRate']),
    ('lua/cams/DeathMode.lua', ['GetObjectByScriptName("t533")', 'alliedAdditionalTech']),
    # 防冻结（2026-10-23）：没新开节点，直接复用地图里早就存在、一直停用的 `NO_freeze`
    # （条件 TRUE / EvaluationInterval = 1 / DeactivateUponSuccess = false），payload 换成
    # 模板扫描版的定期解冻。原因：只靠 TowerFreeOfFreeze.lua 挂的 IN_SHIELD_SPHERE 挡不住
    # 冷冻武器灌冷冻条（实测海塔仍被冻），真正管用的是这条负二次伤害的解冻循环。
    # 该节点是「停用」状态，启用后才会跑（节点开关在地图的脚本树里，导入 payload 不会改它）。
    ('lua/GAME/TowerUnfreeze.lua', ['g_TowerUnfreezeTypes', 'exObjectDealSecondaryDamage(ObjectGetId(tower)']),
    # 2026-10-27 清理旧解冻循环时补登记：TOWER 节点（lua/obj/TOWER_0.lua）此前不在表里，
    # 删掉 UNFROZEN() 只改源码不会回写 JSON，audit_lua_json 会报 DRIFT。
    # needles 取删改后仍存在的两行全局赋值（BUTTON_0.lua 用的是单引号，不会误命中）。
    ('lua/obj/TOWER_0.lua', ['T74= GetObjectByScriptName("T74")', 'T84= GetObjectByScriptName("T84")']),
    ('lua/text/Localization.lua', ['Localization = Localization or {}', 'Localization._text_sources']),
    ('lua/GAME/HextechRune/00_assets.lua', ['local HextechFrameGold = {', 'g_HextechFrameGoldId']),
    ('lua/GAME/HextechRune/03_text.lua', ['g_LocalizationExtraText = {', 'hextech.rune.shrink_ray.desc']),
    ('lua/GAME/HextechRune/01_rune_pool.lua', ['HextechRune.RunePool = {', 'PickBuyTwoGetOneTarget']),
    ('lua/GAME/HextechRune/02_event.lua', ['function HextechRune:ShowFormalEvent', 'function HextechRune:OnRoundBegin']),
    ('lua/GAME/HextechRune/04_buff.lua', ['HextechRune.BattleUnitEffectDelay', 'ApplyFiveTigerGenerals']),
    # 注意：回归基本功 / 等价交换的实现段曾经并入 01_rune_pool.lua 尾部（走 HextechRunePool 节点），
    # 因为当时地图脚本树（map.xml）不收录新节点。**现在 HextechRuneBasicsExchange 节点已经存在于
    # ScriptsData.json 里**（用户在地图里加好了），所以改回独立条目跟着同步；若哪天该节点又被移除，
    # 就把这段实现再并回 01_rune_pool.lua 尾部，并删掉下面这条。
    ('lua/GAME/HextechRune/18_basics_exchange.lua',
     ['HextechRune.TierWideRuneEffects', 'ApplyBasicsOrExchangeToUnit']),
    ('lua/GAME/HextechRune/05_ultimate_creature.lua',
     ['ApplyUltimateCreatureToUnit', 'UltimateCreatureScale']),
    ('lua/GAME/HextechRune/06_ascension.lua', ['AscensionConsumedUnitIds', 'CreateAscensionModifier']),
    ('lua/GAME/HextechRune/07_war_efficiency.lua', ['WarEfficiencyBonusPerDeath', 'ExpireWarEfficiencyBuffs']),
    ('lua/GAME/HextechRune/08_time_rift.lua', ['TimeRiftInterval', 'FreezeSideByTimeRift']),
    ('lua/GAME/HextechRune/09_shrink_ray.lua', ['ShrinkRayBaseInterval', 'RescanShrinkRay']),
    ('lua/GAME/HextechRune/10_recombobulator.lua', ['RecombobulatorRareChance', 'RollRecombobulatorTargetIndex']),
    # 注意：needles 必须同时出现在「JSON 中的现有 payload」与「新 lua 内容」里，
    # 否则定位不到待替换的 payload 会报 expected ... found 0。改名/重写时优先选
    # 两边都保留的函数名。
    ('lua/GAME/HextechRune/11_poach.lua',
     ['CollectPoachSourceUnitIndexes', 'ApplyPoachToPlayer']),
    ('lua/GAME/HextechRune/12_investment.lua', ['ApplyInvestment', 'InvestmentPayoutMultiplier']),
    ('lua/GAME/HextechRune/13_ten_pull.lua', ['TenPullGuaranteedTier', 'RollTenPullResults']),
    ('lua/GAME/HextechRune/14_lethal_tempo.lua',
     ['LethalTempoModifierName', 'ApplyAllLethalTempoBuffs']),
    ('lua/GAME/HextechRune/15_drain.lua',
     ['CollectDrainSourceEntries', 'ApplyDrainToPlayer']),
    ('lua/GAME/HextechRune/16_cryo_satellite.lua',
     ['PlayerTech_Allied_CryoSatellite_Rank3', 'SpecialPowerCryoSatelliteLvl3']),
    ('lua/GAME/HextechRune/17_death_triggers.lua',
     ['HuntRhythmHealRate', 'OnDeathRewardUnitDie']),
    # 第 6 组技能（九头蛇万岁 + 冰天雪地）的溢出节点，CenterTopBtnFunc.lua 已无预算。
    ('lua/LUABOX/BUTTON/CenterTopBtnFuncExtra.lua',
     ['function RequestHydra', 'g_GetEnemyBattlefieldContext']),
    # 空军元帅的 8 波苏霍伊各自是一个地编脚本里的 lua 动作（每波 2 架，脚本名见节点名）。
    # 这些节点此前没登记，改 lua 不会写回 ScriptsData.json，星级 buff 就静默丢失。
    ('lua/LUABOX/BUTTON/air_marshal/Devil_air/devil_air_0.lua',
     ['for i=1,2,1 do', 'GetObjectByScriptName("devil"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Devil_air/devil__1_0.lua',
     ['for i=3,4,1 do', 'GetObjectByScriptName("devil"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Devil_air/devil__2_0.lua',
     ['for i=5,6,1 do', 'GetObjectByScriptName("devil"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Devil_air/devil__3_0.lua',
     ['for i=7,8,1 do', 'GetObjectByScriptName("devil"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Angel_air/angel_air_0.lua',
     ['for i=1,2,1 do', 'GetObjectByScriptName("angel"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Angel_air/angel__1_0.lua',
     ['for i=3,4,1 do', 'GetObjectByScriptName("angel"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Angel_air/angel__2_0.lua',
     ['for i=5,6,1 do', 'GetObjectByScriptName("angel"..i)']),
    ('lua/LUABOX/BUTTON/air_marshal/Angel_air/angel__3_0.lua',
     ['for i=7,8,1 do', 'GetObjectByScriptName("angel"..i)']),
    ('lua/GAME/EnvKillAllUnit.lua', ['CallOnEveryRoundBegin',
        'env_kill_all_unit.execute'], 2),
    # 达摩剑目标池与两发落点脚本此前未登记；守护神判定改到抽取时后必须能回写。
    ('lua/BUFF/unit_all_0.lua', ['unitall = CreateObjectFilter',
        'JapanLightTransportVehicle']),
    ('lua/LUABOX/BUTTON/nemesis/devil_nemesis_0.lua',
     ['T84, nil', 'CelestialOrbitalStrikeTarget']),
    ('lua/LUABOX/BUTTON/nemesis/angel_nemesis_0.lua',
     ['T74, nil', 'CelestialOrbitalStrikeTarget']),
    ('lua/LUABOX/HIDEINI_0.lua', ['FilterJapanLightTransportVehicle=CreateObjectFilter',
        'function HIDEOBJ ()']),
    ('lua/LUABOX/MOCROCONTROL/MICROINI_0.lua', ['FilterPrioritySiegeVehicle=CreateObjectFilter',
        'function PrioritySiegeAttackMoveMICROCONTROL']),
    # TGMICRO 是调用段（周期脚本），内容只有函数名列表。两个 needle 都取「调用写法」：
    # MICROINI 里定义函数时写成 `function X ()`（带空格），不会误命中那 3 个调用式 needle。
    ('lua/LUABOX/MOCROCONTROL/TGMICRO_0.lua', ['JapanAntiNavyShipTech3MICROCONTROL()',
        'if BIGSHIPCONTROL then']),
    # AIRSPACT 此前没登记（JSON 里那份是 87 B 的单行调用），要给飞机批次补打击者VX，
    # 必须先登记，否则改了不会写回 ScriptsData.json。
    ('lua/LUABOX/AIRSPACT_0.lua', ['UNITSPAIRST (step3+1,step35,LIGHTVEHSP,AIRTEAM,AIRATTACK,LIGHTVEHSPCH)']),
    ('lua/LUABOX/LandArmySpawn.lua', ['function SpawnNoNavyAmphibiousLand_left',
        'function LandArmySpawn()']),
    ('lua/LUABOX/SPUNITINI_0.lua', ['function UNITSPST (unitmin,unitmax',
        'function UNITSPST_right']),
    ('lua/LUABOX/SPUNITINI_1.lua', ['function UNITSPAIRST (unitmin,unitmax',
        'function UNITSPAIRST_right']),
    ('lua/LUABOX/SPUNITINI_2.lua', ['function UNITSPSHIP (unitmin,unitmax',
        'function UNITSPSHIP_SIDE']),
    # 此前没登记，JSON 里那份是历史遗留、恰好与源码一致；禁空模式要在里面加守卫，
    # 必须先登记，否则改了不会写回 ScriptsData.json。
    ('lua/LUABOX/SpawnGigaFortress.lua', ['EnsureGigaFortressAirForm',
        'g_GigaFortressBigHeadSpawnChance']),
    # 更新日志（原先单独用 sync_update_log2.py，机制与本脚本完全一致，已并入）。
    ('lua/text/Update_0.lua', ['g_RuleText = Localization.get', 'g_UpdateBoxText']),
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

    for entry in TARGETS:
        target_path, needles = entry[0], entry[1]
        # 少数脚本节点里同一段逻辑存在多份重复 payload（例如 EnvKillAllUnit），
        # 这类目标显式声明份数，全部写入同一份源内容。
        expect = entry[2] if len(entry) > 2 else 1
        section = entry[3] if len(entry) > 3 else None
        label = target_path if section is None else '%s#%s' % (target_path, section)
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
        if len(candidates) != expect:
            print('ERROR: expected %d ScriptsData payload(s) for %s, found %d' % (
                expect, label, len(candidates)))
            sys.exit(1)
        with open(os.path.join(REPO_ROOT, target_path), 'r', encoding='utf-8', newline='') as f:
            body = f.read()
        if section is not None:
            sections = split_sections(body) or {}
            if section not in sections:
                print('ERROR: %s 里没有 --@%s 节' % (target_path, section))
                sys.exit(1)
            body = sections[section]
        body = normalize_crlf(body)
        body = body.rstrip('\r\n')
        # 放得下就与源文件逐字一致；超过 64KB 上限时自动去掉注释（注释不执行却占预算）。
        try:
            payload, stripped, size = build_payload(body, label)
        except LuaPayloadError as error:
            print('ERROR: %s' % error)
            sys.exit(1)
        sizes.append((size, label, stripped))
        for cand in candidates:
            # 沿用该 payload 原有转义风格：海克斯符文节点由 add_hextech_scripts.py
            # 以 UTF-8 原文写入，其余节点是 \uXXXX 转义。
            # 统一成同一种写法会把整行 payload 全部改写，产生无意义的大 diff。
            was_escaped = all(ord(ch) < 128 for ch in cand.group())
            encoded = json.dumps(payload, ensure_ascii=was_escaped)
            replacements.append((target_path, cand.start(), cand.end(), encoded))
            print('matched %-52s %6d B (余 %6d B)%s' % (
                label, size, PAYLOAD_HARD_LIMIT - size,
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
