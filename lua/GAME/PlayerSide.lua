local playerBaseTech = {
    [1] = "PlayerTech_Allied",
    [2] = "PlayerTech_Soviet",
    [3] = "PlayerTech_Japan",
    [4] = "PlayerTech_Celestial"
}

g_PlayerSide = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 1,
    [5] = 1,
    [6] = 1,
}

for i = 1, 6, 1 do
    local playerName = "Player_" .. i
    for j = 1, 4, 1 do
        if EvaluateCondition("PLAYER_HAS_PLAYER_TECH", playerName, playerBaseTech[j]) then
            g_PlayerSide[i] = j
        end
    end
    -- 高强度机械变形由自走棋 AI 自带；真人帝国玩家不能从建造栏购买。
    if g_PlayerSide[i] == 3 then
        SchedulerModule.delay_call(function(targetPlayerName)
            ExecuteAction("ALLOW_DISALLOW_ONE_UPGRADE", targetPlayerName, "Upgrade_JapanNanoTransmissionStructure", 0)
        end, 1, {playerName})
    end
end
