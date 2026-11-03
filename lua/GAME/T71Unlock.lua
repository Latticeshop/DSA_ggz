if g_GameMode ~= 4 then
    exEnableWBScript('Player_4/UNLOCK1__4')
    exEnableWBScript('Player_7/UNLOCK1__7')
    exEnableWBScript('Player_5/UNLOCK1__5')
    exEnableWBScript('Player_6/UNLOCK1__6')
    ExecuteAction("UNIT_KILL_ALL_IN_AREA", "PlyrCreeps", "nofire51")
    if PureDrawReapplyPlayerQuota ~= nil then
        -- 天使席位不是连续的 5..8，按 g_Seat8 = {4,5,7,6} 逐个重算配额，
        -- 否则 4 号位的可造性永远停留在解锁前的旧状态。
        local reapplySeats = g_Seat8
        if reapplySeats == nil then reapplySeats = { 4, 5, 7, 6 } end
        for k = 1, getn(reapplySeats), 1 do PureDrawReapplyPlayerQuota(reapplySeats[k]) end
    end
end
