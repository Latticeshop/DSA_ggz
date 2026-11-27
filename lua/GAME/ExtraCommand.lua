g_BanSeaFilter = CreateObjectFilter({
    Rule = "ANY",

    IncludeThing = {
        "AlliedNavalYard", "SovietNavalYard", "JapanNavalYard", "CelestialNavalYard"
    }
})

function MsgCommand_BanSea()
    exMessageAppendToMessageArea(Localization.get("extra_command.ban_sea"))
    for i = 1, 8 do
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
    for i = 1, 8 do
        local playerName = "Player_" .. i
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedBarracks", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "SovietBarracks", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "JapanBarracks", 0)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialBarracks", 0)
    end
end

-- J：展开/隐藏当前玩家尚未完成的海克斯选择页。
exRegisterHotKey(74, 0, 2)
-- K：消耗一次玩家持有的部署类符文次数 / 触发 K 键技能。湮灭炸弹、视距打击、工厂维护
-- 共用这个键，三张两两互斥（见 01_rune_pool.lua），同一名玩家最多只持有其中一张。
exRegisterHotKey(75, 0, 3)

function onUserHotKeyEvent(playerName, commandCode, mouseWorldPos)
    if commandCode == 2 and HextechRune ~= nil then
        HextechRune:HandleSelectionHotKey(playerName)
        return
    end
    if commandCode == 3 and HextechRune ~= nil then
        HextechRune:HandleOblivionBombHotKey(playerName)
        HextechRune:HandleIlBeaconHotKey(playerName)
        HextechRune:HandleFactoryMaintenanceHotKey(playerName)
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

-- === 禁用模式（步兵 / 载具 / 空军 / 海军）===
-- 不可造 + 不出兵 + 不进抽卡/箱子替换/符文目标池，
-- 但不删场上已有单位、也不删建筑。兵种分类与判定在 LUABOX/UNITCOUNTERINI_0.lua，
BAN_MODE_DIALOG_ID = 205

function BanModeGetFlag(modeId)
    if modeId == "infantry" then
        return g_BanModeInfantry
    elseif modeId == "vehicle" then
        return g_BanModeVehicle
    elseif modeId == "aircraft" then
        return g_BanModeAir
    elseif modeId == "navy" then
        return g_DisableSeaArmy
    end
    return 0
end

function BanModeSetFlag(modeId, value)
    if modeId == "infantry" then
        g_BanModeInfantry = value
    elseif modeId == "vehicle" then
        g_BanModeVehicle = value
    elseif modeId == "aircraft" then
        g_BanModeAir = value
    elseif modeId == "navy" then
        g_DisableSeaArmy = value
    end
end

function BanModeNameOf(modeId)
    return Localization.get("ban_mode.name." .. modeId)
end

-- 用短兵种名 + "/" 连接而不是逐项「(禁步兵)」：按钮文本宽度有限，
function BanModeGetSummarySuffix()
    local names = {}
    for i = 1, getn(g_BanModeIds), 1 do
        if BanModeGetFlag(g_BanModeIds[i]) == 1 then
            tinsert(names, Localization.get("ban_mode.short." .. g_BanModeIds[i]))
        end
    end
    if getn(names) == 0 then
        return ''
    end
    local joined = names[1]
    for i = 2, getn(names), 1 do
        joined = joined .. "/" .. names[i]
    end
    return Localization.get("ban_mode.suffix", joined)
end

function BanModeRemoveFromOrder(modeId)
    for i = 1, getn(g_BanModeOrder), 1 do
        if g_BanModeOrder[i] == modeId then
            tremove(g_BanModeOrder, i)
            return
        end
    end
end

-- 已选满 3 项时再选第 4 项：自动取消「最初选的那项」，保证不可能四个全禁。
function BanModeToggle(modeId)
    if BanModeGetFlag(modeId) == 1 then
        BanModeSetFlag(modeId, 0)
        BanModeRemoveFromOrder(modeId)
        exMessageAppendToMessageArea(Localization.get("game_mode.host.canceled", BanModeNameOf(modeId)))
        return
    end
    if getn(g_BanModeOrder) >= 3 then
        local oldest = g_BanModeOrder[1]
        BanModeSetFlag(oldest, 0)
        tremove(g_BanModeOrder, 1)
        exMessageAppendToMessageArea(Localization.get("ban_mode.auto_clear", BanModeNameOf(oldest)))
    end
    BanModeSetFlag(modeId, 1)
    tinsert(g_BanModeOrder, modeId)
    exMessageAppendToMessageArea(Localization.get("game_mode.host.selected", BanModeNameOf(modeId)))
end

-- 禁用模式子页：四个兵种多选（最多 3 项）+ 返回上一页。
function BtnChoiceDialogEventFunc_ShowBanModeDialog(playerName)
    local dialogData = {
        DialogId = BAN_MODE_DIALOG_ID,
        PlayerName = playerName,
        Title = Localization.get("ban_mode.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {}
        for i = 1, getn(g_BanModeIds), 1 do
            local banName = Localization.get("ban_mode.option." .. g_BanModeIds[i])
            if BanModeGetFlag(g_BanModeIds[i]) == 1 then
                banName = banName .. Localization.get("game_mode.selected_suffix")
            end
            tinsert(self.Choices, banName)
        end
        tinsert(self.Choices, Localization.get("ban_mode.back"))
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex >= 1 and buttonIndex <= getn(g_BanModeIds) then
            BanModeToggle(g_BanModeIds[buttonIndex])
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        end
        if buttonIndex == getn(g_BanModeIds) + 1 then
            BtnChoiceDialogEventFunc_ShowMoreOptionsDialog(self.PlayerName)
            return
        end
        exMessageAppendToMessageArea(Localization.get("game_mode.error.invalid_button", self.PlayerName, buttonIndex))
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

-- === 单位上限模式（无数量限制 / 每人 50 / 100 / 150 / 200 / 300）===
UNIT_CAP_MODE_DIALOG_ID = 206
g_UnitCapModeOptions = { 0, 50, 100, 150, 200, 300 }
g_UnitCapMode = g_UnitCapMode or 0

function UnitCapModeNameOf(value)
    if (tonumber(value) or 0) <= 0 then
        return Localization.get("unit_cap.option.none")
    end
    return Localization.get("unit_cap.option.value", value)
end

function UnitCapModeGetSummarySuffix()
    local mode = tonumber(g_UnitCapMode) or 0
    if mode <= 0 then
        return ''
    end
    return Localization.get("unit_cap.suffix", mode)
end

-- 单位上限子页：六个档位（默认无数量限制）+ 返回上一页。
function BtnChoiceDialogEventFunc_ShowUnitCapModeDialog(playerName)
    local dialogData = {
        DialogId = UNIT_CAP_MODE_DIALOG_ID,
        PlayerName = playerName,
        Title = Localization.get("unit_cap.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {}
        for i = 1, getn(g_UnitCapModeOptions), 1 do
            local optionName = UnitCapModeNameOf(g_UnitCapModeOptions[i])
            if (tonumber(g_UnitCapMode) or 0) == g_UnitCapModeOptions[i] then
                optionName = optionName .. Localization.get("game_mode.selected_suffix")
            end
            tinsert(self.Choices, optionName)
        end
        tinsert(self.Choices, Localization.get("unit_cap.back"))
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex >= 1 and buttonIndex <= getn(g_UnitCapModeOptions) then
            g_UnitCapMode = g_UnitCapModeOptions[buttonIndex]
            exMessageAppendToMessageArea(Localization.get("game_mode.host.selected",
                UnitCapModeNameOf(g_UnitCapMode)))
            -- 中途改小上限时立刻把已有超额收掉（开局前是空池，等于空跑）。
            if TrimAllPlayersUnitPoolToCap ~= nil then
                TrimAllPlayersUnitPoolToCap()
            end
            if UpdateUnitCapHudAll ~= nil then
                UpdateUnitCapHudAll()
            end
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        end
        if buttonIndex == getn(g_UnitCapModeOptions) + 1 then
            BtnChoiceDialogEventFunc_ShowMoreOptionsDialog(self.PlayerName)
            return
        end
        exMessageAppendToMessageArea(Localization.get("game_mode.error.invalid_button", self.PlayerName, buttonIndex))
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function UnitCapMode_Setting()
    g_UnitCapMode = tonumber(g_UnitCapMode) or 0
    if UpdateUnitCapHudAll ~= nil then
        UpdateUnitCapHudAll(true)
    end
end
