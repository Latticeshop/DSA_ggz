
g_Name_ShipIndex = 1;

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
            --local spawnPos = spawnPosPrefix .. tostring(suffix)
            --local x, y, z = ObjectGetPosition(AIRSP[teamIndex][suffix])
            --exMessageAppendToMessageArea(tostring(x) .. " " .. tostring(y) .. " " .. tostring(z) .. " " .. SHIPTEAM[teamIndex][suffix])
            --local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            --ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, "JapanFortressShip", SHIPTEAM[teamIndex], spawnPos)
            --g_Name_ShipIndex = g_Name_ShipIndex + 1;

            local spawnPos = landSpawnPosPrefix .. tostring(suffix)
            local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, "JapanFortressShip", AIRTEAM[teamIndex][suffix], spawnPos)
            --local object = GetObjectByScriptName(name);
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", name, "Command_ToggleJapanFortressShipTransformMode");
            ExecuteAction("UNIT_CLEAR_MODELCONDITION", name, "USER_1");
            ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", name,"TRANSFORMATION_TOGGLE_STATE", 0)

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
            --local spawnPos = spawnPosPrefix .. tostring(suffix)
            --local x, y, z = ObjectGetPosition(AIRSP[teamIndex][suffix])
            --exMessageAppendToMessageArea(tostring(x) .. " " .. tostring(y) .. " " .. tostring(z) .. " " .. SHIPTEAM[teamIndex][suffix])
            --local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            --ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, "JapanFortressShip", SHIPTEAM[teamIndex], spawnPos)
            --g_Name_ShipIndex = g_Name_ShipIndex + 1;

            local spawnPos = landSpawnPosPrefix .. tostring(suffix)
            local name = "AIShip_" .. tostring(g_Name_ShipIndex);
            ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", name, "JapanFortressShip", AIRTEAM[teamIndex][suffix], spawnPos)
            --local object = GetObjectByScriptName(name);
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", name, "Command_ToggleJapanFortressShipTransformMode");
            ExecuteAction("UNIT_CLEAR_MODELCONDITION", name, "USER_1");
            ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", name,"TRANSFORMATION_TOGGLE_STATE", 0)

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
