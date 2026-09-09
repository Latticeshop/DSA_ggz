
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

for i = 4 , 6 , 1 do
    if g_PureDrawT4ShipUnlocked ~= nil then
        g_PureDrawT4ShipUnlocked[i] = true
    end
    for j = 1, 9, 1 do
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING","Player_"..i , enableT4Ship[j], 1)
    end
    if PureDrawReapplyPlayerQuota ~= nil then
        PureDrawReapplyPlayerQuota(i)
    end
end

exAddTextToPublicBoard(Localization.get("mirrortower.unlock_t4_ship.angel"), 10)

SchedulerModule.delay_call(function()
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "Sea3ProtectShip7", "JapanFortressShip", "PlyrCivilian/teamPlyrCivilian", "seaTower7");
    local Sea3ProtectShip7 = GetObjectByScriptName("Sea3ProtectShip7");
    ExecuteAction("UNIT_SET_HEALTH", "Sea3ProtectShip7", 10000);
end, 15 * 16)

if g_EnableShrinkMode == 1 then
    exWaypointSetPos("PLANEREBORN7", 1709, 4512, 200)
end
