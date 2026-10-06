-- 讲解见 analysis/地图注释说明文档.md 附录 A.33

HextechRune = HextechRune or {}

-- ============ 协议授予类符文（金·冷冻卫星 / 金·神威）============
-- 键名与符文的 Effect 一致，派发处直接传 Effect。
HextechRune.ProtocolGrants = {
    grant_cryo_satellite = {
        PlayerTech = "PlayerTech_Allied_CryoSatellite_Rank3",
        SpecialPower = "SpecialPowerCryoSatelliteLvl3",
        Faction = 1, YardType = "AlliedConstructionYard" },
    grant_chrono_rift = {
        PlayerTech = "PlayerTech_Allied_ChronoRift_Rank3",
        SpecialPower = "SpecialPowerChronoRiftSelectLvl3",
        Faction = 1, YardType = "AlliedConstructionYard" },
}

-- 钥匙基地的停泊点，实测确认在地图外。
HextechRune.ProtocolYardOffmapX = 3324.27
HextechRune.ProtocolYardOffmapY = 8979.87

-- 两张盟军协议共用同一把钥匙，所以名字按阵营 + 玩家编。
function GetHextechProtocolYardName(playerIndex, faction)
    return "HextechProtocolYard_" .. faction .. "_" .. playerIndex
end

-- 地图外没有航点，仍走已验证的航点生成通道保证归属与形态，落点再单独挪一次（与伏龙殿同一套做法）。
-- 禁用走 HELD 位而不是 UNPACKING：HELD 是本图开局永久禁用 NANO1/NANO2 用的同一位。
function HextechRune.DisableProtocolYard(yardName)
    ExecuteAction("NAMED_SET_DISABLED", yardName, "HELD", 1)
end

function HextechRune:EnsureProtocolYard(playerIndex, grant)
    if g_PlayerSide ~= nil and g_PlayerSide[playerIndex] == grant.Faction then
        return
    end
    local name = GetHextechProtocolYardName(playerIndex, grant.Faction)
    if GetObjectByScriptName(name) ~= nil then
        return
    end
    local playerName = "Player_" .. playerIndex
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT_WITH_ORIENTATION", name,
        grant.YardType, playerName .. "/team" .. playerName,
        playerName .. "_Start", 0)
    local yard = GetObjectByScriptName(name)
    if yard == nil then
        return
    end
    local x, y, z = ObjectGetPosition(yard)
    ObjectSetPosition(yard, self.ProtocolYardOffmapX, self.ProtocolYardOffmapY, z)
    -- 同帧挂会被随后的展开流程改回去（实测就是那一小段展开空隙），等展开落定再挂：
    -- 建筑展开约 3.5 秒，取 53 帧（3.53 秒）略偏后。实测这样协议照常可用、基地造不出兵。
    SchedulerModule.delay_call(HextechRune.DisableProtocolYard, 53, { name })
end

-- 赋予手法与 04_buff.lua 的 GrantCashRewardProtocol 相同：先解掉科技显式锁，否则授予后图标仍置灰。
function HextechRune:GrantProtocol(playerIndex, grantKey)
    local grant = self.ProtocolGrants[grantKey]
    if grant == nil then
        return
    end
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    self:EnsureProtocolYard(playerIndex, grant)
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName, grant.PlayerTech, 0)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", grant.SpecialPower, playerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        grant.SpecialPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        grant.SpecialPower, 0)
    SetWorldBuilderThisPlayer(previous)
    -- 技能实例由 GRANT 延迟创建，同帧的 Available 可能只改到全局禁用记录，下一帧再解禁一次。
    SchedulerModule.delay_call(HextechRune.ReunlockProtocol, 1,
        {playerIndex, grant.PlayerTech, grant.SpecialPower})
end

-- 延迟解禁：只补解锁与可用性，不再重复 GRANT（重复授予会把冷却打回原形）。
function HextechRune.ReunlockProtocol(playerIndex, playerTech, specialPower)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName, playerTech, 0)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName, specialPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName, specialPower, 0)
    SetWorldBuilderThisPlayer(previous)
end
