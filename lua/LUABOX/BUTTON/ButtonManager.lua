ButtonManager = {
    _data = {},
    _sharedCooldown = {}, -- 用于存储共享冷却时间
    _customButtonHandlers = {},
}

function onCustomBtnClickEvent(playerName, index)
    local list = ButtonManager._customButtonHandlers
    for i = 1, getn(list), 1 do
        local f = list[i]
        if f(playerName, index) then
            return
        end
    end
end

function ButtonManager.RegisterCustomButtonHandler(self, handler)
    tinsert(self._customButtonHandlers, handler)
end

function ButtonManager.GetButton(self, playerName, buttonIndex)
    local playerData = self._data[playerName]
    if not playerData then
        return nil
    end
    return playerData[buttonIndex]
end

function ButtonManager.SetButton(self, buttonData)
    if not buttonData or not buttonData.PlayerName or not buttonData.ButtonIndex then
        exMessageAppendToMessageArea(Localization.get("button_manager.error.incomplete_data"))
        return
    end

    local playerName = buttonData.PlayerName
    local buttonIndex = buttonData.ButtonIndex
    
    local playerData = self._data[playerName]
    if not playerData then
        playerData = {}
        self._data[playerName] = playerData
    end
    local previousButton = playerData[buttonIndex]
    if previousButton ~= nil and previousButton ~= buttonData then
        -- 假如新设置的按钮和之前的按钮不同，则需要处理之前的按钮
        if previousButton.SharedCooldownId then
            -- 如果之前的按钮有共享冷却时间，则移除它
            self:_removeSharedCooldown(previousButton)
        end
    end
    playerData[buttonIndex] = buttonData
    if buttonData.SharedCooldownId then
        -- 如果当前按钮有共享冷却时间，则添加它
        self:_addSharedCooldown(buttonData)
    end

    exCenterTopBtnShowForPlayer(playerName, buttonIndex, buttonData.IconId, buttonData.Text)
    
    -- 目前 EnhancerCorona 会在设置按钮的时候自动（在 50 毫秒后）将按钮启用。
    -- 因此，直接把按钮禁用是没有用的，会在约 50 毫秒后被覆盖。
    -- 这里使用延时调用来确保按钮状态被正确设置。
    SchedulerModule.delay_call(function(buttonData)
        local isButtonEnabled = 1
        if not buttonData.IsEnabled or buttonData.IsEnabled == 0 then
            isButtonEnabled = 0
        end
        exCenterTopBtnSetEnableForPlayer(buttonData.PlayerName, buttonData.ButtonIndex, isButtonEnabled)
        if buttonData.IsHighlighted and buttonData.IsHighlighted ~= 0 then
            exCenterTopBtnToggleHighLightForPlayer(buttonData.PlayerName, buttonData.ButtonIndex, 1)
        end
    end, 2, { buttonData })
end

function ButtonManager.OnClick(self, playerName, buttonIndex)
    local buttonData = self:GetButton(playerName, buttonIndex)
    if not buttonData then
        return
    end
    if type(buttonData.OnClick) == "function" then
        buttonData:OnClick()
    else
        exMessageAppendToMessageArea(Localization.get("button_manager.error.no_click_event", playerName, buttonIndex))
    end
end

function ButtonManager.SharedCooldown(self, buttonData)
    local sharedCooldownId = buttonData.SharedCooldownId
    if not sharedCooldownId then
        exMessageAppendToMessageArea(Localization.get("button_manager.error.no_sharedcooldown_id", buttonData.PlayerName or "?", buttonData.Title or Localization.get("button.default.unknown")))
        return
    end
    local list = self._sharedCooldown[sharedCooldownId]
    if not list then
        return
    end
    for i = 1, getn(list) do
        local currentButton = list[i]
        if currentButton ~= buttonData then -- 避免自己触发自己的冷却
            if type(currentButton.SharedCooldown) == "function" then
                currentButton:SharedCooldown()
                else
                exMessageAppendToMessageArea(Localization.get("button_manager.error.no_sharedcooldown_handler", currentButton.PlayerName or "?", currentButton.Title or Localization.get("button.default.unknown")))
            end
        end
    end
end

function ButtonManager._addSharedCooldown(self, buttonData)
    if not buttonData.SharedCooldownId then
        return
    end
    local previousList = self._sharedCooldown[buttonData.SharedCooldownId]
    if not previousList then
        self._sharedCooldown[buttonData.SharedCooldownId] = { buttonData }
        return
    end
    local newList = {}
    for i = 1, getn(previousList) do
        local currentButton = previousList[i]
        if currentButton ~= buttonData then
            tinsert(newList, currentButton)
        end
    end
    tinsert(newList, buttonData)
    self._sharedCooldown[buttonData.SharedCooldownId] = newList
end

function ButtonManager._removeSharedCooldown(self, buttonData)
    if not buttonData.SharedCooldownId then
        return
    end
    local previousList = self._sharedCooldown[buttonData.SharedCooldownId]
    if not previousList then
        return
    end
    local newList = {}
    for i = 1, getn(previousList) do
        local currentButton = previousList[i]
        if currentButton ~= buttonData then
            tinsert(newList, currentButton)
        end
    end
    self._sharedCooldown[buttonData.SharedCooldownId] = newList
end

function CreateButton(buttonData)
    buttonData.Title = buttonData.Title or Localization.get("button.default.title")
    buttonData.Description = buttonData.Description or Localization.get("button.default.description")
    buttonData.MaxUseCount = buttonData.MaxUseCount or nil -- 最大使用次数，如果为 nil 则表示没有限制
    buttonData.CooldownSeconds = buttonData.CooldownSeconds or 0
    buttonData.CooldownRounds = buttonData.CooldownRounds or 0
    buttonData.Text = Localization.get("button_manager.text.not_initialized", buttonData.Title, buttonData.Description)
    if buttonData.SharedCooldownId then
        if not buttonData.PlayerIndex then
            exMessageAppendToMessageArea(Localization.get("button_manager.error.no_playerindex", buttonData.Title or Localization.get("button.default.unknown")))
            return
        end
        local side = "devil"
        if buttonData.PlayerIndex >= 4 then
            side = "angel"
        end
        buttonData.SharedCooldownId = format("%s_%s", side, buttonData.SharedCooldownId)
        buttonData.SharedCooldownSeconds = buttonData.SharedCooldownSeconds or 1
    end
    if buttonData.IsLocked then
        buttonData.IsEnabled = false
    end

    buttonData._usedCount = 0
    buttonData._cooldownCount = 0
    -- 冷却回调的代际号：外部强制清掉冷却（终极刷新）时 +1，让已经排队的旧回调失效，
    -- 避免它在下一段冷却期间把按钮提前点亮。
    buttonData._cooldownGeneration = 0
    buttonData._multipleUseOnClick = buttonData.OnClick

    buttonData.FormatText = function(self)
        local title = self.Title
        if self.MaxUseCount ~= nil and self._usedCount >= self.MaxUseCount then
            title = self.Title .. Localization.get("button.suffix.used")
        elseif self._cooldownCount > 0 then
            title = self.Title .. Localization.get("button.suffix.cooldown")
        elseif self.MaxUseCount ~= nil then
            if self.MaxUseCount == 1 then
                title = self.Title .. Localization.get("button.suffix.single_use")
            else
                title = self.Title .. Localization.get("button.suffix.use_count", self.MaxUseCount - self._usedCount)
            end
        end
        self.Text = format("%s\n%s", title, self.Description)
    end
    buttonData.OnClick = function(self)
        if not self.IsEnabled then
            return
        end
        if not self:_multipleUseOnClick() then
            return
        end

        -- 触发其他玩家的共享冷却
        if self.SharedCooldownId then
            ButtonManager:SharedCooldown(self)
        end

        self._usedCount = self._usedCount + 1

        local canStillUse = self.MaxUseCount == nil or self._usedCount < self.MaxUseCount
        if not canStillUse then
            self.IsEnabled = false
            self:FormatText()
            ButtonManager:SetButton(self)
            return
        end

        if self.CooldownSeconds > 0 then
            self._cooldownCount = self._cooldownCount + 1
            self.IsEnabled = false
            self:FormatText()
            ButtonManager:SetButton(self)
            local generation = self._cooldownGeneration
            SchedulerModule.delay_call(function(self)
                self:_reActivate(generation)
            end, self.CooldownSeconds * 15, { self })
            return
        end

        if self.CooldownRounds > 0 then
            self._cooldownCount = self._cooldownCount + 1
            self.IsEnabled = false
            self:FormatText()
            ButtonManager:SetButton(self)
            local generation = self._cooldownGeneration
            RoundLuaManager.DelayCallOnRoundBegin(function(self)
                self:_reActivate(generation)
            end, { self }, self.CooldownRounds)
            return
        end

        self.IsEnabled = true
        self:FormatText()
        ButtonManager:SetButton(self)
    end
    buttonData.SharedCooldown = function(self)
        if self.SharedCooldownSeconds ~= nil then
            self._cooldownCount = self._cooldownCount + 1
            self.IsEnabled = false
            self:FormatText()
            ButtonManager:SetButton(self)
            local generation = self._cooldownGeneration
            SchedulerModule.delay_call(function(self)
                self:_reActivate(generation)
            end, self.SharedCooldownSeconds * 15, { self })
            return
        end
    end
    buttonData._reActivate = function(self, generation)
        if ButtonManager:GetButton(self.PlayerName, self.ButtonIndex) ~= self then
            exMessageAppendToMessageArea(Localization.get("button_manager.error.overwritten_cannot_restore", self.PlayerName or "?", self.Title or Localization.get("button.default.unknown")))
            return
        end
        if generation ~= nil and generation ~= self._cooldownGeneration then
            -- 冷却已经被外部清掉（终极刷新补次数），这次回调作废。
            return
        end
        -- 冷却计数独立于使用次数，必须先扣再判断可用性：次数用尽或被锁时提前返回
        -- 会把计数永久卡在 >0（共享冷却也会加到用尽的按钮上），之后就算补了次数
        -- （终极刷新）也再没有任何回调能把这个按钮放回可用。
        if (self._cooldownCount or 0) > 0 then
            self._cooldownCount = self._cooldownCount - 1
        else
            self._cooldownCount = 0
        end
        if self._cooldownCount > 0 then
            return
        end
        if (self.MaxUseCount ~= nil and self._usedCount >= self.MaxUseCount) or self.IsLocked then
            -- 冷却已走完但按钮仍不可用（次数用尽 / 未解锁）：只刷新标题，保持禁用。
            self:FormatText()
            ButtonManager:SetButton(self)
            return
        end
        self.IsEnabled = true
        self:FormatText()
        ButtonManager:SetButton(self)
    end

    buttonData:FormatText()
    return buttonData
end

function _ALERT(msg)
    exAddTextToPublicBoard(msg, 10)
end