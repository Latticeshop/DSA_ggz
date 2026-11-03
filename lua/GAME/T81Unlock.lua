if g_GameMode ~= 4 then
    exEnableWBScript('Player_1/UNLOCK1__1')
    exEnableWBScript('Player_8/UNLOCK1__8')
    exEnableWBScript('Player_2/UNLOCK1__2')
    exEnableWBScript('Player_3/UNLOCK1__3')
    ExecuteAction("UNIT_KILL_ALL_IN_AREA", "PlyrCivilian", "nofire6")
    if PureDrawReapplyPlayerQuota ~= nil then
        -- 恶魔席位是 {1,2,8,3}，不是 1..4；写死 1..4 时 8 号位拿不到配额重算。
        local reapplySeats = g_Seat7
        if reapplySeats == nil then reapplySeats = { 1, 2, 8, 3 } end
        for k = 1, getn(reapplySeats), 1 do PureDrawReapplyPlayerQuota(reapplySeats[k]) end
    end
end
