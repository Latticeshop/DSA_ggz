
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

-- 触发者：地编 MIRRORTOWER/MIRRORTOWER1__6 = 海3塔 T83F 被摧毁 → 解锁的是恶魔阵营。
-- 8 人局里同一个阵营的座位不是连续的 1..4，必须按 g_Seat7 = {1,2,8,3} 逐个来：
-- 原来写死 1..4 会让 8 号位永远拿不到解锁，还把一个天使座位当恶魔解锁。
local unlockSeats = g_Seat7
if unlockSeats == nil then
    unlockSeats = { 1, 2, 8, 3 }
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

exAddTextToPublicBoard(Localization.get("mirrortower.unlock_t4_ship.devil"), 10)

SchedulerModule.delay_call(function()
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "Sea3ProtectShip8", "JapanFortressShip", "PlyrCreeps/teamPlyrCreeps", "seaTower8");
    local Sea3ProtectShip8 = GetObjectByScriptName("Sea3ProtectShip8");
    ExecuteAction("UNIT_SET_HEALTH", "Sea3ProtectShip8", 10000);
end, 15 * 16)

if g_EnableShrinkMode == 1 then
    exWaypointSetPos("PLANEREBORN8", 5327, 4484, 200)
end
