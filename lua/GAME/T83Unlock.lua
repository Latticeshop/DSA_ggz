if g_GameMode ~= 4 then
    exEnableWBScript('Player_1/UNLOCK3__1')
    exEnableWBScript('Player_2/UNLOCK3__2')
    exEnableWBScript('Player_3/UNLOCK3__3')
    if PureDrawReapplyPlayerQuota ~= nil then
        for i = 1, 3, 1 do PureDrawReapplyPlayerQuota(i) end
    end

end
