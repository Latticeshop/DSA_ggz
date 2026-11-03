g_PlayerSpellBookId = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
    [7] = 0,
    [8] = 0,
}

for i = 1, 32, 1 do
    if exObjectGetInstanceId(i) == 1627485 then
        local name = ObjectPlayerScriptName(i)
        -- 检测是否是 Player_ 开头
        if strsub(name, 1, 7) == "Player_" then
            local playerIndex = tonumber(strsub(name, 8))
            if playerIndex >= 1 and playerIndex <= 8 then
                g_PlayerSpellBookId[playerIndex] = i
            end
        end
    end
end