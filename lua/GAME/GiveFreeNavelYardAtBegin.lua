local playerBaseTech = {
    [1] = "PlayerTech_Allied",
    [2] = "PlayerTech_Soviet",
    [3] = "PlayerTech_Japan",
    [4] = "PlayerTech_Celestial"
}

local freeNavalYard = {
    [1] = "AlliedNavalYard",
    [2] = "SovietNavalYard",
    [3] = "JapanNavalYard",
    [4] = "CelestialNavalYard",
}

-- 抽卡模式不赠送船厂，避免赠送建筑的特殊生产序列绕过生产余额。
if g_DrawMode ~= 2 then
    for i = 1, 6, 1 do
        local playerName = "Player_" .. i
        for j = 1, 4, 1 do
            if EvaluateCondition("PLAYER_HAS_PLAYER_TECH", playerName, playerBaseTech[j]) then
                ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT_WITH_ORIENTATION", "freeNavelYard"..tostring(i), freeNavalYard[j], playerName.."/team"..playerName, "navelYard" .. i,-3.1415926/4);
            end
        end
    end
end
