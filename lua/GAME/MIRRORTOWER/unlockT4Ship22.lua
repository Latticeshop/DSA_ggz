
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

-- 触发者：地编 MIRRORTOWER/MIRRORTOWER1__3 = 海3塔 T73F 被摧毁 → 解锁的是天使阵营。
-- 8 人局里同一个阵营的座位不是连续的 5..8，必须按 g_Seat8 = {4,5,7,6} 逐个来：
-- 原来写死 5..8 会让 4 号位永远拿不到解锁，还把一个恶魔座位当天使解锁。
local unlockSeats = g_Seat8
if unlockSeats == nil then
    unlockSeats = { 4, 5, 7, 6 }
end
for seatPos = 1, getn(unlockSeats), 1 do
    local i = unlockSeats[seatPos]
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
