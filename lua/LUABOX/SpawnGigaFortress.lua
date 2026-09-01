
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

-- UnitCreate 的初始化触发器可能晚于首轮出兵，先为超级要塞计数准备安全槽位。
function GetGigaFortressCountSlot()
    if g_UnitCount == nil then
        g_UnitCount = {}
    end
    local instanceId = FastHash("JapanGigaFortressShipEgg")
    if g_UnitCount[instanceId] == nil then
        g_UnitCount[instanceId] = { 0, 0, 0, 0, 0, 0 }
    end
    return g_UnitCount[instanceId]
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
    local countSlot = GetGigaFortressCountSlot();
    for i = 1, 3 do
        local landSpawnPosPrefix = "LIGHTVEH1"
        if i >= 4 then
            landSpawnPosPrefix = "LIGHTVEH2"
        end
        local angle = 0;
        if i >= 4 then
            angle = 180
        end
        local teamIndex = 7;
        if i >= 4 then
            teamIndex = 8;
        end
        for j = 1, countSlot[i] do
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
            for levelindex = 1 , LEVELUP[7] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",AIRTEAM[7][spindex],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",AIRTEAM[7][spindex],AIRATTACK[7][spindex])
        end
    end

end

function SpawnGigaFortressAir_right()
    local countSlot = GetGigaFortressCountSlot();
    for i = 4, 6 do
        local landSpawnPosPrefix = "LIGHTVEH1"
        if i >= 4 then
            landSpawnPosPrefix = "LIGHTVEH2"
        end
        local angle = 0;
        if i >= 4 then
            angle = 180
        end
        local teamIndex = 7;
        if i >= 4 then
            teamIndex = 8;
        end
        for j = 1, countSlot[i] do
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
            for levelindex = 1 , LEVELUP[8] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",AIRTEAM[8][spindex],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",AIRTEAM[8][spindex],AIRATTACK[8][spindex])
        end
    end

end
