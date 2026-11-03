if g_GameMode ~= 4 then
    exEnableWBScript('Player_4/UNLOCK3__4')
    exEnableWBScript('Player_7/UNLOCK3__7')
    exEnableWBScript('Player_5/UNLOCK3__5')
    exEnableWBScript('Player_6/UNLOCK3__6')
    if PureDrawReapplyPlayerQuota ~= nil then
        local reapplySeats = g_Seat8
        if reapplySeats == nil then reapplySeats = { 4, 5, 7, 6 } end
        for k = 1, getn(reapplySeats), 1 do PureDrawReapplyPlayerQuota(reapplySeats[k]) end
    end
else
    --TODO 没有守护者
end
