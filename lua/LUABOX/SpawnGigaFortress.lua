
g_Name_ShipIndex = 1;

-- 超级要塞只在登场时随机一次形态：50% 飞行船只，50% 大头轰炸。
-- 如需调整概率，只修改这个值（0.0 至 1.0）。
g_GigaFortressBigHeadSpawnChance = 0.5

function SpawnRandomGigaFortress(name, team, spawnPos)
    local unitType = "JapanFortressShip"
    local isBigHead = GetRandomNumber() < g_GigaFortressBigHeadSpawnChance
    if isBigHead then
        unitType = "JapanGigaFortress_Land"
    end

    ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, unitType, team, spawnPos)

    -- 两个随机模板都只在登场时校正为空中状态。
    -- 创建同一帧调用变形技能会偶发丢失，因此延迟执行并在变形完成后复查一次。
    SchedulerModule.delay_call(function(objectName)
        local unit = GetObjectByScriptName(objectName)
        if ObjectIsAlive(unit)
            and not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit, "AIRBORNE_TARGET") then
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", unit, "Command_ToggleJapanFortressShipTransformMode")
        end
    end, 1, {name})
    SchedulerModule.delay_call(function(objectName)
        local unit = GetObjectByScriptName(objectName)
        if ObjectIsAlive(unit)
            and not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit, "AIRBORNE_TARGET") then
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", unit, "Command_ToggleJapanFortressShipTransformMode")
        end
    end, 30, {name})
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

function SpawnGigaFortressAir_left()
    local countSlot = GetGigaFortressCountSlot();
    for i = 1, 3 do
        local spawnPosPrefix = "AIR1"
        if i >= 4 then
            spawnPosPrefix = "AIR2"
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
            --local spawnPos = spawnPosPrefix .. tostring(suffix)
            --local x, y, z = ObjectGetPosition(AIRSP[teamIndex][suffix])
            --exMessageAppendToMessageArea(tostring(x) .. " " .. tostring(y) .. " " .. tostring(z) .. " " .. SHIPTEAM[teamIndex][suffix])
            --local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            --ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, "JapanFortressShip", SHIPTEAM[teamIndex], spawnPos)
            --g_Name_ShipIndex = g_Name_ShipIndex + 1;

            local spawnPos = spawnPosPrefix .. tostring(suffix)
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
        local spawnPosPrefix = "AIR1"
        if i >= 4 then
            spawnPosPrefix = "AIR2"
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
            --local spawnPos = spawnPosPrefix .. tostring(suffix)
            --local x, y, z = ObjectGetPosition(AIRSP[teamIndex][suffix])
            --exMessageAppendToMessageArea(tostring(x) .. " " .. tostring(y) .. " " .. tostring(z) .. " " .. SHIPTEAM[teamIndex][suffix])
            --local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            --ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, "JapanFortressShip", SHIPTEAM[teamIndex], spawnPos)
            --g_Name_ShipIndex = g_Name_ShipIndex + 1;

            local spawnPos = spawnPosPrefix .. tostring(suffix)
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
