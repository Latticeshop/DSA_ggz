
g_Name_ShipIndex = 1;

-- 超级要塞只在登场时随机一次形态：50% 飞行船只，50% 大头轰炸。
-- 如需调整概率，只修改这个值（0.0 至 1.0）。
g_GigaFortressBigHeadSpawnChance = 0.5

function EnsureGigaFortressAirForm(objectName)
    local unit = GetObjectByScriptName(objectName)
    if ObjectIsAlive(unit)
        and not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit, "AIRBORNE_TARGET") then
        ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", unit, "Command_ToggleJapanFortressShipTransformMode")
        ExecuteAction("UNIT_CLEAR_MODELCONDITION", unit, "USER_1")
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", unit, "TRANSFORMATION_TOGGLE_STATE", 0)
    end
end

function SpawnRandomGigaFortress(name, team, spawnPos)
    if BanModeIsNameBanned ~= nil and BanModeIsNameBanned("JapanFortressShip") == 1 then
        return
    end
    local isBigHead = GetRandomNumber() < g_GigaFortressBigHeadSpawnChance
    if isBigHead then
        -- JapanGigaFortress_Land 才是大头轰炸形态，使用陆地载具出生点。
        ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION",
            name, "JapanGigaFortress_Land", team, spawnPos)
        return
    end

    -- 空中要塞也从 LIGHTVEH 陆地出生点登场，避免从海面生成。
    -- 生成后立即变形，再在第 1、30 帧复查，避免首次指令丢失。
    ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION",
        name, "JapanFortressShip", team, spawnPos)
    EnsureGigaFortressAirForm(name)
    SchedulerModule.delay_call(EnsureGigaFortressAirForm, 1, {name})
    SchedulerModule.delay_call(EnsureGigaFortressAirForm, 30, {name})
end

-- 超级要塞已统一进 UNITLIST 兵表（UNITCOUNTERINI_0.lua 第 135 格），旧的独立计数槽 g_UnitCount
-- 整体退役（见附录 D.18）。这一格只存数量，实际生成仍由本文件的专用函数负责。
function GetGigaFortressUnitIndex()
    if g_UnitNameToUnitIndex == nil then
        return nil
    end
    return g_UnitNameToUnitIndex["JapanGigaFortressShipEgg"]
end

function GetGigaFortressCount(playerIndex)
    local unitIndex = GetGigaFortressUnitIndex()
    if unitIndex == nil or UNITCOUNT == nil or UNITCOUNT[playerIndex] == nil then
        return 0
    end
    return tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0
end

-- 核心实体入池：UnitCreate.lua 的 UnitCountFunc 在生成 8 帧后调这里，然后再把核心实体删掉。
-- 所以这里必须和 UNITCOUNT 成对累加，否则超级要塞只进兵表不进部队数量（见附录 D.20）。
function CountGigaFortressCore(playerIndex)
    local unitIndex = GetGigaFortressUnitIndex()
    if unitIndex == nil or UNITCOUNT == nil or UNITCOUNT[playerIndex] == nil then
        return false
    end
    UNITCOUNT[playerIndex][unitIndex] =
        (tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0) + 1
    if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[playerIndex] ~= nil then
        ANYUNITCOUNT[playerIndex] = (tonumber(ANYUNITCOUNT[playerIndex]) or 0) + 1
    end
    return true
end

function SpawnGigaFortressAir()
    SpawnGigaFortressAir_left()
    SpawnGigaFortressAir_right()
end

-- 兼容部分旧地图脚本中大小写不同的调用名；Lua 函数名区分大小写。
function spawnGigafortressAir()
    SpawnGigaFortressAir()
end

function SpawnGigaFortressAir_left()
    local _seatsDemon = g_SideSeatsOf(7)
for _si = 1, 4 do
    local i = _seatsDemon[_si]
        local teamIndex = g_SeatToSide(i)
        local landSpawnPosPrefix = "LIGHTVEH" .. tostring(teamIndex - 6)
        local angle = 0;
        if teamIndex == 8 then
            angle = 180
        end
        for j = 1, GetGigaFortressCount(i) do
            local suffix = mod(j, 6);
            if suffix == 0 then
                suffix = 6;
            end
            local spawnPos = landSpawnPosPrefix .. tostring(suffix)
            local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            SpawnRandomGigaFortress(name, AIRTEAM[teamIndex][suffix], spawnPos)

            g_Name_ShipIndex = g_Name_ShipIndex + 1;

        end
    end

    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", AIRTEAM[7][spindex]) then
            for levelindex = 1 , (LEVELUP[7] or 0) , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",AIRTEAM[7][spindex],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",AIRTEAM[7][spindex],AIRATTACK[7][spindex])
        end
    end

end

function SpawnGigaFortressAir_right()
    local _seatsAngel = g_SideSeatsOf(8)
for _si = 1, 4 do
    local i = _seatsAngel[_si]
        local teamIndex = g_SeatToSide(i)
        local landSpawnPosPrefix = "LIGHTVEH" .. tostring(teamIndex - 6)
        local angle = 0;
        if teamIndex == 8 then
            angle = 180
        end
        for j = 1, GetGigaFortressCount(i) do
            local suffix = mod(j, 6);
            if suffix == 0 then
                suffix = 6;
            end
            local spawnPos = landSpawnPosPrefix .. tostring(suffix)
            local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            SpawnRandomGigaFortress(name, AIRTEAM[teamIndex][suffix], spawnPos)

            g_Name_ShipIndex = g_Name_ShipIndex + 1;

        end
    end

    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", AIRTEAM[8][spindex]) then
            for levelindex = 1 , (LEVELUP[8] or 0) , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",AIRTEAM[8][spindex],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",AIRTEAM[8][spindex],AIRATTACK[8][spindex])
        end
    end

end
