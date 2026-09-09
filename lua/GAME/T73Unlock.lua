if g_GameMode ~= 4 then
    exEnableWBScript('Player_4/UNLOCK3__4')
    exEnableWBScript('Player_5/UNLOCK3__5')
    exEnableWBScript('Player_6/UNLOCK3__6')
    if PureDrawReapplyPlayerQuota ~= nil then
        for i = 4, 6, 1 do PureDrawReapplyPlayerQuota(i) end
    end
else
    --TODO 没有守护者
end
