
SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T71")
    ExecuteAction("NAMED_KILL", object);
end, 2)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T72")
    ExecuteAction("NAMED_KILL", object);
end, 3)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T73")
    ExecuteAction("NAMED_KILL", object);
end, 4)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T81")
    ExecuteAction("NAMED_KILL", object);
end, 5)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T82")
    ExecuteAction("NAMED_KILL", object);
end, 6)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T83")
    ExecuteAction("NAMED_KILL", object);
end, 7)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T83")
    ExecuteAction("NAMED_KILL", object);
end, 8)


SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T71F")
    ExecuteAction("NAMED_DELETE", object);
end, 9)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T72F")
    ExecuteAction("NAMED_DELETE", object);
end, 10)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T81F")
    ExecuteAction("NAMED_DELETE", object);
end, 11)

SchedulerModule.delay_call(function()
    local object = GetObjectByScriptName("T82F")
    ExecuteAction("NAMED_DELETE", object);
end, 12)

SchedulerModule.delay_call(function()
    -- 删除展示体前必须解除守护者登记：引擎复用对象 id 后，新单位会被当成守护神。
    local object = GetObjectByScriptName("t533")
    UnregisterTowerGuardian(object)
    ExecuteAction("NAMED_DELETE", object);
    object = GetObjectByScriptName("t534")
    UnregisterTowerGuardian(object)
    ExecuteAction("NAMED_DELETE", object);

    object = GetObjectByScriptName("overlord7")
    UnregisterTowerGuardian(object)
    ExecuteAction("NAMED_DELETE", object);
    object = GetObjectByScriptName("overlord8")
    UnregisterTowerGuardian(object)
    ExecuteAction("NAMED_DELETE", object);
end, 13)

for i = 1, 6 do
    local playerName = "Player_" .. i
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "alliedsuperweapon", 1)
end

SchedulerModule.delay_call(function()
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", "<All Players>", "SpecialPower_AlliedChronoAccelerate", "Available")
    for i = 1, 6, 1 do
        local playerName = "Player_" .. i
        if not EvaluateCondition("PLAYER_HAS_PLAYER_TECH", playerName,"PlayerTech_Allied") then
            exPlayerTechUnlockBaseTechForPlayer(playerName)
            ExecuteAction("UNIT_SPAWN_NAMED_OBJECT_ON_TEAM_AT_NAMED_OBJECT_LOCATION", "alliedAdditionalTech" .. tostring(i), "AlliesAdditionalPlayerTechStructure", playerName.."/team"..playerName, "wan1");

        end
    end
end, 1800)

for i = 1, 6, 1 do
    local playerName = "Player_" .. i
    if EvaluateCondition("PLAYER_HAS_PLAYER_TECH", playerName,"PlayerTech_Celestial") then
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "extraPower1"..tostring(i), "CelestialPowerPlant", playerName.."/team"..playerName, "navelYard" .. i);
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "extraPower2"..tostring(i), "CelestialPowerPlant", playerName.."/team"..playerName, "navelYard" .. i);
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "extraPower3"..tostring(i), "CelestialPowerPlant", playerName.."/team"..playerName, "navelYard" .. i);
    end
end
