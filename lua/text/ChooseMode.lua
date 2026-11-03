exMessageAppendToMessageArea(Localization.get("dialog.choose_mode.waiting"))
g_objectTeamNameToPlayerName = {
    ["teamPlayer_1"] = "Player_1",
    ["teamPlayer_2"] = "Player_2",
    ["teamPlayer_3"] = "Player_3",
    ["teamPlayer_4"] = "Player_4",
    ["teamPlayer_5"] = "Player_5",
    ["teamPlayer_6"] = "Player_6",
    ["teamPlayer_7"] = "Player_7",
    ["teamPlayer_8"] = "Player_8",
}
-- 移除语言按钮
exCustomBtnRemove(999)
exCustomBtnRemove(1000)
exCustomTextUpdateVisibility(1000, 0)

local previous = SetWorldBuilderThisPlayer(1)

local structures, count = CopyPlayerRegisteredObjectSet("<1st Human Player>", "STRUCTURES")

local teamName = ObjectTeamName(structures[1])
g_RoomOwnerPlayer = g_objectTeamNameToPlayerName[teamName]
if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
    SchedulerModule.delay_call(function() BtnChoiceDialogEventFunc_ShowGameModeDialog(g_RoomOwnerPlayer) end, 2)
else
    BtnChoiceDialogEventFunc_ShowGameModeDialog(g_RoomOwnerPlayer)
end


SetWorldBuilderThisPlayer(previous)