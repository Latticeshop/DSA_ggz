-- ============================================================
-- PureDraw: 工程师与箱子单位事件注册
--   - 四阵营工程师统一加速（抽卡工程师）
--   - 箱子里开出的要塞计入要塞核心计数
--   - 箱子航母/战列舰存活时间、龙船禁止攻击
-- ============================================================

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

-- 只有抽卡模式允许玩家从生产栏建造工程师；其他模式保持按钮禁用。
function SetPlayerEngineerProductionAvailability(enable)
    local availability = 0
    if enable and enable ~= 0 then
        availability = 1
    end
    for i = 1, 6, 1 do
        local playerName = "Player_" .. i
        for j = 1, getn(g_PlayerEngineerTypes), 1 do
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, g_PlayerEngineerTypes[j], availability)
        end
    end
end

function TryEnableLuckyCrateIfAllowed()
    local previous = SetWorldBuilderThisPlayer(1)
    SetPlayerEngineerProductionAvailability(g_LuckyCrateMode)
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
