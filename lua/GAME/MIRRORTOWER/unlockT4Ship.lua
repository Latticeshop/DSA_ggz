
local enableT4Ship = {
    [1] = 'AlliedAntiStructureShip',
    [2] = 'AlliedAntiStructureShip_Enhanced',
    [3] = 'CelestialAntiStructureShip',
    [4] = 'CelestialAntiStructureShip_Enhanced',
    [5] = 'SovietAntiStructureShip',
    [6] = 'SovietAntiStructureShip_Enhanced',
    [7] = 'JapanAntiStructureShip',
    [8] = 'JapanAntiStructureShip_Enhanced',
    [9] = 'JapanGigaFortressShipEgg',
}

for i = 1 , 3 , 1 do
    for j = 1, 9, 1 do
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING","Player_"..i , enableT4Ship[j], 1)
    end
end

exAddTextToPublicBoard(Localization.get("mirrortower.unlock_t4_ship.devil"), 10)

SchedulerModule.delay_call(function()
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "Sea3ProtectShip8", "JapanFortressShip", "PlyrCreeps/teamPlyrCreeps", "seaTower8");
    local Sea3ProtectShip8 = GetObjectByScriptName("Sea3ProtectShip8");
    ExecuteAction("UNIT_SET_HEALTH", "Sea3ProtectShip8", 10000);
end, 15 * 16)

if g_GameMode == 3 then
    exWaypointSetPos("PLANEREBORN8", 5327, 4484, 200)
end
