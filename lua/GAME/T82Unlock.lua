if g_GameMode ~= 4 then
    exEnableWBScript('Player_1/UNLOCK2__1')
    exEnableWBScript('Player_2/UNLOCK2__2')
    exEnableWBScript('Player_3/UNLOCK2__3')
    ExecuteAction("UNIT_KILL_ALL_IN_AREA", "PlyrCivilian", "nofire6")
    if PureDrawReapplyPlayerQuota ~= nil then
        for i = 1, 3, 1 do PureDrawReapplyPlayerQuota(i) end
    end
end
