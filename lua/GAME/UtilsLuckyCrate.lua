-- 启用箱子模式：确保箱子技能可用，每个玩家送一个迅雷
-- 目前由 GiveFreeStructure__2 启用
if not g_SuperSpeedModifier then
    g_SuperSpeedModifier = exAttributeModifierCreate({ SPEED = 8.0 }, 1)
end

-- 工程师保留在玩家家中，不进入 UNITLIST/自走棋对战池；四阵营工程师统一获得抽卡工程师的加速。
function PlayerEngineerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ObjectLoadAttributeModifier(GetObjectById(id), g_SuperSpeedModifier)
        end
    end, 1, {createdObjId})
end

g_PlayerEngineerTypes = {
    "AlliedEngineer",
    "SovietEngineer",
    "JapanEngineer",
    "CelestialEngineer",
}
for i = 1, getn(g_PlayerEngineerTypes), 1 do
    local engineerType = g_PlayerEngineerTypes[i]
    exObjectRegisterCreateEvent(engineerType)
    g_UnitCreateEventFunc[FastHash(engineerType)] = PlayerEngineerBorn
end

-- 覆盖地图旧版的全局封禁；延迟一帧可确保初始化动作已经执行完。
SchedulerModule.delay_call(function()
    for i = 1, 6, 1 do
        local playerName = "Player_" .. i
        for j = 1, getn(g_PlayerEngineerTypes), 1 do
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, g_PlayerEngineerTypes[j], 1)
        end
    end
end, 1, {})

function TryEnableLuckyCrateIfAllowed()
    local previous = SetWorldBuilderThisPlayer(1)
    local EnableLuckyCrateImplementation = function(enable)
        if not enable or enable == 0 then
            return
        end
        if g_LuckyCreateEnableComplete then
            return
        end
        g_LuckyCreateEnableComplete = 1
        ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", "SpecialPower_LuckyUnitCrate", "<All Human Players>")
        ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", "SpecialPower_LuckyUnitCrateX10", "<All Human Players>")
        for i = 1, 6, 1 do
            local playerName = "Player_" .. i
            local isHuman = EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", playerName, "Human")
            if isHuman then
                local p = exWaypointGetPos(format("Player_%d_Start", i))
                local offsetX = 200
                local position = { X = p[1] + offsetX, Y = p[2], Z = p[3] }
                local nextObjectId = GetNextObjectId()
                ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
                    "",
                    "JapanEngineer",
                    format("%s/crate", playerName),
                    position, 
                    0
                )
                TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", GetObjectById(nextObjectId), "SCRIPT:CrateEnabled", 120, "")
            end
        end
    end
    EnableLuckyCrateImplementation(g_LuckyCrateMode)
    SetWorldBuilderThisPlayer(previous)
end

-- 箱子里开出来的要塞也和要塞核心一起计算
exObjectRegisterCreateEvent("JapanFortressShip")
exObjectRegisterCreateEvent("JapanGigaFortress_Land")
function CountAsFortressShipEgg(createdObjId, createdObjInstanceId, ownerPlayerName)
    return UnitCountFunc(createdObjId, FastHash("JapanGigaFortressShipEgg"), ownerPlayerName)
end
g_UnitCreateEventFunc[FastHash("JapanFortressShip")] = CountAsFortressShipEgg
g_UnitCreateEventFunc[FastHash("JapanGigaFortress_Land")] = CountAsFortressShipEgg

-- 箱子里开出来的航母 / 战列舰有存活时间
exObjectRegisterCreateEvent("AlliedGaintAirCraftCarrier_B")
exObjectRegisterCreateEvent("AlliedThetisBattleShip")
exObjectRegisterCreateEvent("JapanYumiAircraftCarrier")
function SetCrateShipLifetime(createdObjId, createdObjInstanceId, ownerPlayerName)
    if ownerPlayerName ~= "PlyrCreeps"
        and ownerPlayerName ~= "PlyrCivilian" then
        return
    end
    local lifetime = 2
    if createdObjInstanceId == FastHash("AlliedGaintAirCraftCarrier_B") then
        lifetime = 1
    end
    RoundLuaManager.DelayCallOnRoundBegin(function(id)
        if not ObjectIsAlive(id) then
            return
        end
        ExecuteAction("NAMED_KILL", GetObjectById(id))
    end, { createdObjId }, lifetime)
end
g_UnitCreateEventFunc[FastHash("AlliedGaintAirCraftCarrier_B")] = SetCrateShipLifetime
g_UnitCreateEventFunc[FastHash("AlliedThetisBattleShip")] = SetCrateShipLifetime
g_UnitCreateEventFunc[FastHash("JapanYumiAircraftCarrier")] = SetCrateShipLifetime

-- 箱子里开出来的龙船禁止攻击
exObjectRegisterCreateEvent("CelestialMCV")
function DisableCrateDragonAttack(createdObjId, createdObjInstanceId, ownerPlayerName)
    Scheduler.delay_call(function(id)
        if not ObjectIsAlive(id) then
            return
        end
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", GetObjectById(id), "NO_ATTACK", 1)
    end, 1, { createdObjId })
end
g_UnitCreateEventFunc[FastHash("CelestialMCV")] = DisableCrateDragonAttack

-- 箱子模式：只允许抽卡，不允许在地图上刷随机箱子（万一被 AI 捡了太麻烦）
SchedulerModule.delay_call(function()
    local crateFilter = CreateObjectFilter({ IncludeThing = { "GenericCrateSpawner" } })
    local units, count = ObjectFindObjects(nil, nil, crateFilter)
    for j = 1, count, 1 do
        -- 先禁用抽卡技能（后面可以启用）
        ExecuteAction("NAMED_DELETE", units[j])
        -- 此外假如检测到随机宝箱，就默认启用抽卡模式
        g_LuckyCrateMode = 1
    end
end, 1, {})
SchedulerModule.delay_call(function()
    local crateFilter = CreateObjectFilter({
        IncludeThing = {
            "GenericCrateSpawner",
            "UnitCrateNew",
            "ShroudCrate",
            "MoneyCrateMP",
        }
    })
    local units, count = ObjectFindObjects(nil, nil, crateFilter)
    for j = 1, count, 1 do
        ExecuteAction("NAMED_DELETE", units[j])
    end
end, 45, {})

-- 检测箱子是否被扔到中央战场
function NoCreatesInCenter(id)
    if not ObjectIsAlive(id) then
        return
    end
    local crate = GetObjectById(id)
    local isCrateInCenter = false
    if EvaluateCondition("NAMED_INSIDE_AREA", crate, "SHOW7")
        and EvaluateCondition("NAMED_INSIDE_AREA", crate, "SHOW8") then
        -- SHOW7 SHOW8 这两个区域都包含中央战场
        -- 所以假如单位处于中央战场，就会同时处于这两个区域内
        isCrateInCenter = true
    end
    if not isCrateInCenter then
        -- 不在中间就没事
        return
    end
    -- 寻找一个合法的位置
    if not g_CelestialOutpostsFilter then
        g_CelestialOutpostsFilter = CreateObjectFilter({ IncludeThing = { "CelestialOutpost" } })
    end
    local outposts, count = ObjectFindObjects(nil, nil, g_CelestialOutpostsFilter)
    if count <= 0 then
        return
    end
    local index = ceil(GetRandomNumber() * count)
    if index < 1 then
        index = 1
    end
    if index > count then
        index = count
    end
    local outpost = outposts[index]
    local RandomInRange = function(min, max)
        local sign = 1
        if GetRandomNumber() < 0.5 then
            sign = -1
        end
        return (min + (GetRandomNumber() * (max - min))) * sign
    end
    local offsetX = RandomInRange(50, 200)
    local offsetY = RandomInRange(50, 150)
    local x, y, z = ObjectGetPosition(outpost)
    ObjectSetPosition(crate, x + offsetX, y + offsetY, z)
    -- 发送警告
    ExecuteAction("OBJECT_CREATE_RADAR_EVENT", crate, "Information")
    if g_LastWarningFrame ~= nil and g_LastWarningFrame + 30 > GetFrame() then
        -- 一段时间内只提示一次
    else
        g_LastWarningFrame = GetFrame()
        exMessageAppendToMessageArea(Localization.get("error.crate_in_battlefield"))
    end
end
exObjectRegisterCreateEvent("LuckyUnitCrateSeed")
g_UnitCreateEventFunc[FastHash("LuckyUnitCrateSeed")] = function(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(NoCreatesInCenter, 1, {createdObjId})
end
