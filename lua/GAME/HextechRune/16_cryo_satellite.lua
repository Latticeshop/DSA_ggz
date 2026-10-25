-- 讲解见 analysis/地图注释说明文档.md 附录 A.33

HextechRune = HextechRune or {}

-- ============ 协议授予类符文（键名即符文 Effect，04_buff.lua 按这张表派发）============
-- 新增一张协议符文：这里加一行 + 01_rune_pool.lua 加条目 + 03_text.lua 加文案，派发无需改动。
-- 表里的 Faction 同时是抽卡过滤依据（不给本阵营协议），讲解见文档 8.1。
HextechRune.ProtocolGrants = {
    grant_cryo_satellite = {
        PlayerTech = "PlayerTech_Allied_CryoSatellite_Rank3",
        SpecialPower = "SpecialPowerCryoSatelliteLvl3",
        Faction = 1, YardType = "AlliedConstructionYard" },
    -- 银·神威：2026-10-14 由「时空裂缝3级」降为「时空裂缝2级」（原 gold_divine_might）；
    -- 科技名取地编选项去掉 Purchase_ 前缀，技能名按 ProtocolEnum 的 Lvl2 档对齐。
    grant_chrono_rift = {
        PlayerTech = "PlayerTech_Allied_ChronoRift_Rank2",
        SpecialPower = "SpecialPowerChronoRiftSelectLvl2",
        Faction = 1, YardType = "AlliedConstructionYard" },
    -- 金·现金奖励：苏联协议。苏联玩家自己的基地就够解锁、符文不再额外给基地；
    cash_reward = {
        PlayerTech = "PlayerTech_Soviet_ProductionKickbacks",
        SpecialPower = "SpecialPower_ProductionKickbacks",
        Faction = 2, YardType = "SovietConstructionYard" },
    -- 银·鸡汤来咯：苏联协议（毒质腐蚀）。与现金奖励同阵营，钥匙基地共用一栋、不重复生成。
    grant_irradiate = {
        PlayerTech = "PlayerTech_Soviet_IrradiateTarget",
        SpecialPower = "SpecialPower_IrradiateTarget",
        Faction = 2, YardType = "SovietConstructionYard" },
    -- 金·享辐（2026-10-19 由彩降金）：苏联三级投毒（撒毒）协议。技能名带 Level 后缀、不是 Lvl，按 ProtocolEnum 原样取。
    grant_desolator_bomb = {
        PlayerTech = "PlayerTech_Soviet_DesolatorBomb_Rank3",
        SpecialPower = "SpecialPower_DesolatorBomb_Level3",
        Faction = 2, YardType = "SovietConstructionYard" },
    -- 棱彩·万象天引：苏联磁力奇点，协议不分档、技能名没有 Rank 后缀。
    grant_magnetic_singularity = {
        PlayerTech = "PlayerTech_Soviet_MagneticSingularity",
        SpecialPower = "SpecialPowerMagneticSingularity",
        Faction = 2, YardType = "SovietConstructionYard" },
    -- 金·艾卡西亚的惊喜：盟军三级时空炸弹。苏联玩家靠地图外钥匙基地解锁，盟军玩家本机即通。
    grant_time_bomb = {
        PlayerTech = "PlayerTech_Allied_TimeBomb_Rank3",
        SpecialPower = "SpecialPowerTimeBombLvl3",
        Faction = 1, YardType = "AlliedConstructionYard" },
}

-- 钥匙基地的停泊点，实测确认在地图外。
HextechRune.ProtocolYardOffmapX = 3324.27
HextechRune.ProtocolYardOffmapY = 8979.87

-- 钥匙基地的名字按「阵营 + 持有者」：同一方的多张协议卡共用一把钥匙（盟军神威 / 冷冻卫星 /
-- 时空炸弹，苏联现金奖励 / 毒质腐蚀 / 投毒 / 磁力奇点），已经有就不再生成第二栋。
function GetHextechProtocolYardName(playerName, faction)
    return "HextechProtocolYard_" .. faction .. "_" .. playerName
end

-- 地图外没有航点，仍走已验证的航点生成通道保证归属与形态，落点再单独挪一次（与伏龙殿同一套做法）。
-- 禁用走 HELD 位而不是 UNPACKING：HELD 是本图开局永久禁用 NANO1/NANO2 用的同一位。
function HextechRune.DisableProtocolYard(yardName)
    ExecuteAction("NAMED_SET_DISABLED", yardName, "HELD", 1)
end

-- playerIndex 为 nil 表示场地中间的 AI 阵营（PlyrCivilian/PlyrCreeps）：这类侧没有自己的
-- Player_N_Start 航点，借 Player_1_Start 生成就行（归属只由 team 参数决定），同帧挪到图外。
function HextechRune:EnsureProtocolYard(playerName, grant, playerIndex, keepUsable)
    -- 本阵营的协议本来就不生成钥匙基地。抽卡侧已经过滤掉「自己阵营的协议符文」，
    -- 这里留着是第二道保险（例如别处直接调用 GrantProtocolToPlayer 时）。
    if playerIndex ~= nil and g_PlayerSide ~= nil
        and g_PlayerSide[playerIndex] == grant.Faction then
        return
    end
    local name = GetHextechProtocolYardName(playerName, grant.Faction)
    if GetObjectByScriptName(name) ~= nil then
        return
    end
    local waypoint = "Player_1_Start"
    if playerIndex ~= nil then
        waypoint = "Player_" .. playerIndex .. "_Start"
    end
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT_WITH_ORIENTATION", name,
        grant.YardType, playerName .. "/team" .. playerName,
        waypoint, 0)
    local yard = GetObjectByScriptName(name)
    if yard == nil then
        return
    end
    local x, y, z = ObjectGetPosition(yard)
    ObjectSetPosition(yard, self.ProtocolYardOffmapX, self.ProtocolYardOffmapY, z)
    if keepUsable then
        return
    end
    -- 同帧挂会被随后的展开流程改回去（实测就是那一小段展开空隙），等展开落定再挂：
    -- 建筑展开约 3.5 秒，取 53 帧（3.53 秒）略偏后。实测这样协议照常可用、基地造不出兵。
    SchedulerModule.delay_call(HextechRune.DisableProtocolYard, 53, { name })
end

-- 赋予手法与 04_buff.lua 的 GrantCashRewardProtocol 相同：先解掉科技显式锁，否则授予后图标仍置灰。
-- 授予对象既可以是玩家（Player_N），也可以是场地中间的 AI 阵营（PlyrCivilian/PlyrCreeps）。
function HextechRune:GrantProtocolToPlayer(playerName, grantKey, playerIndex, skipYard)
    local grant = self.ProtocolGrants[grantKey]
    if grant == nil then
        return
    end
    local previous = SetWorldBuilderThisPlayer(1)
    -- 继承时基地已经由引擎转交给新玩家，不再按新玩家名字生成第二栋。
    if not skipYard then
        self:EnsureProtocolYard(playerName, grant, playerIndex)
    end
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName, grant.PlayerTech, 0)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", grant.SpecialPower, playerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        grant.SpecialPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        grant.SpecialPower, 0)
    SetWorldBuilderThisPlayer(previous)
    -- 技能实例由 GRANT 延迟创建，同帧的 Available 可能只改到全局禁用记录，下一帧再解禁一次。
    SchedulerModule.delay_call(HextechRune.ReunlockProtocol, 1,
        {playerName, grant.PlayerTech, grant.SpecialPower})
end

function HextechRune:GrantProtocol(playerIndex, grantKey)
    self:GrantProtocolToPlayer("Player_" .. playerIndex, grantKey, playerIndex)
end

-- 退出继承：协议是逐玩家授予的，必须给继承者重新授予科技/技能；基地已自动转交，不再重建。
function HextechRune:IsInheritedProtocolRune(rune)
    if rune == nil then
        return false
    end
    if self.ProtocolGrants[rune.Effect] ~= nil then
        return true
    end
    return rune.Effect == "grant_free_trade"
        or rune.Effect == "grant_mass_production"
end

function HextechRune:ReregisterInheritedProtocol(playerIndex, rune)
    if rune == nil then
        return
    end
    local effect = rune.Effect
    if self.ProtocolGrants[effect] ~= nil then
        self:GrantProtocolToPlayer("Player_" .. playerIndex, effect, playerIndex, true)
    elseif effect == "grant_free_trade" then
        self:GrantFreeTrade(playerIndex)
    elseif effect == "grant_mass_production" then
        self:GrantMassProduction(playerIndex, true)
    end
end

-- 延迟解禁：只补解锁与可用性，不再重复 GRANT（重复授予会把冷却打回原形）。
function HextechRune.ReunlockProtocol(playerName, playerTech, specialPower)
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName, playerTech, 0)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName, specialPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName, specialPower, 0)
    SetWorldBuilderThisPlayer(previous)
end

-- 只解科技锁的延迟解禁（被动协议没有技能按钮，不能走 ReunlockProtocol 的技能那两步）。
function HextechRune.ReunlockPlayerTech(playerName, playerTech)
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName, playerTech, 0)
    SetWorldBuilderThisPlayer(previous)
end

-- 讲解见 analysis/地图注释说明文档.md 8.2（没有技能按钮；钥匙基地见下一行）
HextechRune.MassProductionPlayerTech = "PlayerTech_ProductionBonus_Soviet"
HextechRune.MassProductionYard = { Faction = 2, YardType = "SovietConstructionYard" }

function HextechRune:GrantMassProduction(playerIndex, skipYard)
    local playerName = "Player_" .. playerIndex
    local alreadyMarked = false
    if g_ProductionBonus_SovietGet ~= nil
        and g_ProductionBonus_SovietGet[playerIndex] == 1 then
        alreadyMarked = true
    end
    -- 顺序与 GrantProtocolToPlayer 一致：先把钥匙基地立起来，再解科技锁。
    local previous = SetWorldBuilderThisPlayer(1)
    if not skipYard then
        self:EnsureProtocolYard(playerName, self.MassProductionYard, playerIndex)
    end
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName,
        self.MassProductionPlayerTech, 0)
    SetWorldBuilderThisPlayer(previous)
    SchedulerModule.delay_call(HextechRune.ReunlockPlayerTech, 1,
        {playerName, self.MassProductionPlayerTech})
    SchedulerModule.delay_call(HextechRune.ReunlockPlayerTech, 60,
        {playerName, self.MassProductionPlayerTech})
    local techEventFired = false
    if g_ProductionBonus_SovietGet == nil then
        g_ProductionBonus_SovietGet = {}
    end
    if g_ProductionBonus_SovietGet ~= nil then
        techEventFired = g_ProductionBonus_SovietGet[playerIndex] == 1
        g_ProductionBonus_SovietGet[playerIndex] = 1
    end
    -- 与苏联玩家自己点出这条协议同一句播报；引擎若已经派人来过，就不要再播一遍。
    if not alreadyMarked and not techEventFired then
        local sideName = ""
        if PlayerSideName ~= nil and PlayerSideName[playerName] ~= nil then
            sideName = PlayerSideName[playerName]
        end
        exMessageAppendToMessageArea(Localization.get(
            "upgrade.tech.production_bonus_soviet", sideName, playerIndex))
    end
end

-- 讲解见 analysis/地图注释说明文档.md 8.6（走正常获取协议流程，但不发基地车）
HextechRune.FreeTradePlayerTech = "PlayerTech_ProductionBonus_Allies"

function HextechRune:GrantFreeTrade(playerIndex)
    local playerName = "Player_" .. playerIndex
    -- 自由贸易的持有判定就是 Upgrade.lua 生成的那块地标墙块 PlayerA_<i>，
    local markerName = "PlayerA_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName,
        self.FreeTradePlayerTech, 0)
    local createdHere = false
    if GetObjectByScriptName(markerName) == nil then
        local computerPlayer = "PlyrCivilian"
        if PlayerToComputer ~= nil and PlayerToComputer[playerName] ~= nil then
            computerPlayer = PlayerToComputer[playerName]
        end
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", markerName,
            "AlliedWallPiece", computerPlayer .. "/team" .. computerPlayer,
            "jiaoyidian")
        createdHere = GetObjectByScriptName(markerName) ~= nil
    end
    SetWorldBuilderThisPlayer(previous)
    -- 引擎若自己已经把标记建出来（说明协议事件照常触发了），就不要再播一遍。
    if createdHere then
        local sideName = ""
        if PlayerSideName ~= nil and PlayerSideName[playerName] ~= nil then
            sideName = PlayerSideName[playerName]
        end
        exMessageAppendToMessageArea(Localization.get(
            "upgrade.tech.production_bonus_allied", sideName, playerIndex))
    end
end

-- 讲解见 analysis/地图注释说明文档.md 8.7（金·AT立场：每回合给本人载具/舰船套纳米护盾）。
-- 实测口径：这件武器只对载具与舰船生效，步兵/飞机怎么调都不出盾，所以这张卡只开放这两个兵种。
HextechRune.AtFieldShieldWeapon = "PlayerPowerPointDefenseDronesWeapon_Individual"
-- 目标兵种就写在 rune.UnitType 上，滤网直接取 UnitTypeFilters[UnitType]。
HextechRune.AtFieldShielded = HextechRune.AtFieldShielded or {}
HextechRune.AtFieldShieldedRound = nil

-- 开火锚点照帝国全体护盾用本侧陆地塔 T74/T84（实测自锚点不出盾）；死亡模式塔被清掉，
-- 退到侧容器 P[侧号]，再不行才用单位自己。落点始终是目标单位坐标。
function HextechRune:GetAtFieldFireAnchor(sideIndex, unit)
    local anchor = T74
    if sideIndex == 8 then
        anchor = T84
    end
    if anchor == nil or not ObjectIsAlive(anchor) then
        anchor = nil
        if P ~= nil and sideIndex ~= nil then
            anchor = P[sideIndex]
        end
    end
    if anchor == nil or not ObjectIsAlive(anchor) then
        anchor = unit
    end
    return anchor
end

function HextechRune:ApplyAtFieldShieldToUnit(unit, sideIndex)
    if unit == nil or not ObjectIsAlive(unit) then
        return
    end
    local anchor = self:GetAtFieldFireAnchor(sideIndex, unit)
    local x, y, z = ObjectGetPosition(unit)
    ObjectCreateAndFireTempWeaponToTarget(anchor, self.AtFieldShieldWeapon,
        { X = x, Y = y, Z = z }, unit)
end

function HextechRune:ApplyAtFieldShields()
    if P == nil or self.BattleUnitAssignments == nil then
        return
    end
    local round = self.CurrentRound or 0
    if self.AtFieldShieldedRound ~= round then
        self.AtFieldShielded = {}
        self.AtFieldShieldedRound = round
    end
    for playerIndex = 1, 6, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        local owned = self.PlayerOwnedRunes[playerIndex]
        for runeIndex = 1, getn(owned), 1 do
            local rune = owned[runeIndex]
            if rune.Effect == "at_field" and rune.UnitType ~= nil then
                self:ApplyAtFieldShieldsForType(playerIndex, rune.UnitType, round)
            end
        end
    end
end

function HextechRune:ApplyAtFieldShieldsForType(playerIndex, unitType, round)
    local filter = self.UnitTypeFilters[unitType]
    local sideIndex = self:GetPlayerSideIndex(playerIndex)
    if filter == nil or sideIndex == nil or P[sideIndex] == nil then
        return
    end
    local units, count = ObjectFindObjects(P[sideIndex], nil, filter)
    for i = 1, count, 1 do
        local unit = units[i]
        local objectId = ObjectGetId(unit)
        local assignment = self.BattleUnitAssignments[objectId]
        if assignment ~= nil and assignment.PlayerIndex == playerIndex
            and ObjectIsAlive(unit) and self.AtFieldShielded[objectId] ~= round then
            self.AtFieldShielded[objectId] = round
            self:ApplyAtFieldShieldToUnit(unit, sideIndex)
        end
    end
end
