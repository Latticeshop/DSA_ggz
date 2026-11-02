if g_GameMode == 2 then
    for i = 1, 8 do
        local playerName = "Player_" .. i
        exUnlockPlayerGenericRankTech(playerName, 10)
        ExecuteAction("PLAYER_SET_PLAYER_POWER_POINTS", playerName, 7)
    end
end
