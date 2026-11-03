if g_GameMode ~= 4 then
    exEnableWBScript('Player_1/UNLOCK2__1')
    exEnableWBScript('Player_8/UNLOCK2__8')
    exEnableWBScript('Player_2/UNLOCK2__2')
    exEnableWBScript('Player_3/UNLOCK2__3')
    ExecuteAction("UNIT_KILL_ALL_IN_AREA", "PlyrCivilian", "nofire6")
    if PureDrawReapplyPlayerQuota ~= nil then
        local reapplySeats = g_Seat7
        if reapplySeats == nil then reapplySeats = { 1, 2, 8, 3 } end
        for k = 1, getn(reapplySeats), 1 do PureDrawReapplyPlayerQuota(reapplySeats[k]) end
    end
end
