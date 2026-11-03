if g_GameMode ~= 4 then
    exEnableWBScript('Player_4/UNLOCK2__4')
    exEnableWBScript('Player_7/UNLOCK2__7')
    exEnableWBScript('Player_5/UNLOCK2__5')
    exEnableWBScript('Player_6/UNLOCK2__6')
    ExecuteAction("UNIT_KILL_ALL_IN_AREA", "PlyrCreeps", "nofire51")
    if PureDrawReapplyPlayerQuota ~= nil then
        local reapplySeats = g_Seat8
        if reapplySeats == nil then reapplySeats = { 4, 5, 7, 6 } end
        for k = 1, getn(reapplySeats), 1 do PureDrawReapplyPlayerQuota(reapplySeats[k]) end
    end
end
