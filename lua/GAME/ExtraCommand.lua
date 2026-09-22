g_BanSeaFilter = CreateObjectFilter({
    Rule = "ANY",

    IncludeThing = {
        "AlliedNavalYard", "SovietNavalYard", "JapanNavalYard", "CelestialNavalYard"
    }
})

function MsgCommand_BanSea()
    exMessageAppendToMessageArea(Localization.get("extra_command.ban_sea"))
    for i = 1, 6 do
        local playerName = "Player_" .. i
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedNavalYard", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "SovietNavalYard", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "JapanNavalYard", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialNavalYard", 0)
    end

    local matchedObjects, count = ObjectFindObjects(nil, nil, g_BanSeaFilter)
    for i = 1, count, 1 do
        ExecuteAction("NAMED_DELETE", matchedObjects[i]);
    end

end

function MsgCommand_BanInfantry()
    exMessageAppendToMessageArea(Localization.get("extra_command.ban_infantry"))
    for i = 1, 6 do
        local playerName = "Player_" .. i
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedBarracks", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "SovietBarracks", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "JapanBarracks", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialBarracks", 0)
    end
end

-- J：展开/隐藏当前玩家尚未完成的海克斯选择页。
exRegisterHotKey(74, 0, 2)

function onUserHotKeyEvent(playerName, commandCode, mouseWorldPos)
    if commandCode == 2 and HextechRune ~= nil then
        HextechRune:HandleSelectionHotKey(playerName)
        return
    end
    if 1 then return end
    -- todo 必须要在第一回合开始前20秒内输入
    if commandCode == 1 and playerName == g_RoomOwnerPlayer then
        local round = exCounterGetByName("lvc")
        local start = exCounterGetByName("start")
        if round == 0 and start >= 30 then
            exShowCustomBtnChoiceDialogForPlayer(g_RoomOwnerPlayer, 301, Localization.get("extra_command.dialog.title"), Localization.get("extra_command.choice.ban_sea"), Localization.get("extra_command.choice.ban_infantry"), '', '', '', '', '')
        end
    end


end
