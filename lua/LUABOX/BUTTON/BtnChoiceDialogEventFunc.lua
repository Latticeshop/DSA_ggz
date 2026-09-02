devil_max = 200
angel_max = 200

g_GameMode = 1;
g_EnableDeathModeEffect = 0;
g_DisableSeaArmy = 0;

g_GameModeName = {
    [1] = Localization.get("game_mode.name.1"),
    [2] = Localization.get("game_mode.name.2"),
    [3] = Localization.get("game_mode.name.3"),
}

g_GameModeOptions = {
    { Name = Localization.get("game_mode.option.1.name") },
    { Name = Localization.get("game_mode.option.2.name") },
    { Name = Localization.get("game_mode.option.3.name") },
    { Name = Localization.get("game_mode.option.4.name") },
    { Name = Localization.get("game_mode.option.5.name") },
    { Name = Localization.get("game_mode.option.6.name") },
}

MARKET_DIALOG_ID_OFFSET = 100

GAMEMODE_DIALOG_ID = 201

SKILL_DIALOG_ID_OFFSET = 1000
SKILL_DIALOG_ID_OFFSET2 = 2000
PURCHASE_TECH_DIALOG_ID = 701
RECYCLE_UNIT_DIALOG_ID = 801
g_SkillNames = {
    Localization.get("skill.name.1"),
    Localization.get("skill.name.2"),
    Localization.get("skill.name.3"),
    Localization.get("skill.name.4"),
    Localization.get("skill.name.5"),
}
Localization.on_language_changed(function()
    g_GameModeName = {
        [1] = Localization.get("game_mode.name.1"),
        [2] = Localization.get("game_mode.name.2"),
        [3] = Localization.get("game_mode.name.3"),
    }
    g_GameModeOptions[1].Name = Localization.get("game_mode.option.1.name")
    g_GameModeOptions[2].Name = Localization.get("game_mode.option.2.name")
    g_GameModeOptions[3].Name = Localization.get("game_mode.option.3.name")
    g_GameModeOptions[4].Name = Localization.get("game_mode.option.4.name")
    g_GameModeOptions[5].Name = Localization.get("game_mode.option.5.name")
    g_GameModeOptions[6].Name = Localization.get("game_mode.option.6.name")
    g_SkillNames = {
        Localization.get("skill.name.1"),
        Localization.get("skill.name.2"),
        Localization.get("skill.name.3"),
        Localization.get("skill.name.4"),
        Localization.get("skill.name.5"),
    }
end)
g_PreselectedSkillIndices = {}

g_BuyTowerId = {
    ["JapanPointShieldControlTower"] = {
        ["angel"] = 0,
        ["evil"] = 0,
    },
    ["SovietHeavyAntiAirMissileTurret"] = {
        ["angel"] = 0,
        ["evil"] = 0,
    }
}


function onUserBtnChoiceDialogEvent(playerName, btnIndex, dialogId)
    local round = exCounterGetByName("lvc")
    local previous = SetWorldBuilderThisPlayer(1)

    ButtonChoiceDialogManager:OnUserButtonChoiceDialogEvent(playerName, dialogId, btnIndex)
    
    if dialogId == 301 then
        if btnIndex == 1 then
            MsgCommand_BanSea()
        elseif btnIndex == 2 then
            MsgCommand_BanInfantry()
        end
    end

    SetWorldBuilderThisPlayer(previous)
end

function BtnChoiceDialogEventFunc_ShowMarketDialog(playerIndex)
    local dialogData = {
        DialogId = MARKET_DIALOG_ID_OFFSET + playerIndex,
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        Title = Localization.get("market.title"),
    }
    dialogData.RefreshData = function(self)
        local playerIndex = self.PlayerIndex
        local investedMax, investedMoney = devil_max, devil_money
        if playerIndex >= 4 then
            investedMax, investedMoney = angel_max, angel_money
        end
        self.Title = Localization.get("market.title_with_investment", investedMax, investedMoney)

        local transferToA_Index, transferToB_Index = BtnChoiceDialogEventFunc_GetTransferMoneyIndices(playerIndex)
        local roles = {
            Localization.get("market.role.1"),
            Localization.get("market.role.2"),
            Localization.get("market.role.3"),
            Localization.get("market.role.4"),
            Localization.get("market.role.5"),
            Localization.get("market.role.6"),
        }
        function getColorText(index)
            local color = BtnChoiceDialogEventFunc_CalculateColor(index)
            if color == nil then
                return ""
            else
                return format("(%s)", color)
            end
        end
        local playerA_Color = getColorText(transferToA_Index)
        local playerB_Color = getColorText(transferToB_Index)
        
        local nextInvestmentText = Localization.get("market.next_investment.devil")
        if playerIndex >= 4 then
            nextInvestmentText = Localization.get("market.next_investment.angel")
        end
        nextInvestmentText = nextInvestmentText .. Localization.get("market.next_investment.benefit")

        self.Choices = {
            Localization.get("market.transfer.choice", roles[transferToA_Index], playerA_Color), -- 1
            Localization.get("market.transfer.choice", roles[transferToB_Index], playerB_Color), -- 2
            Localization.get("market.back_to_battle"), -- 3
            nextInvestmentText, -- 4
            Localization.get("market.buy_shield_tower", 10000), -- 5
            Localization.get("market.buy_poplar_tower", 12000), -- 6
        }
        --if g_PlayerDebtCount[self.PlayerName] == 0 then
        --    local debtMoney = g_TowerDestroyProgress * 2600 + 4000;
        --    tinsert(self.Choices, format("向银行贷款 %d\n(将会3分钟无收入)", debtMoney)) -- 5
        --else
            -- 您已贷款，无法再次贷款
        --end
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex == 1 or buttonIndex == 2 then
            self:TransferMoney(buttonIndex)
        elseif buttonIndex == 3 then
            -- 回到战场（因此不再显示交易市场对话框）
            return
        elseif buttonIndex == 4 then
            self:InvestMoney()
        elseif buttonIndex == 5 then
            self:BuyJapanPointShieldControlTower()
            return
        elseif buttonIndex == 6 then
            self:BuySovietHeavyAntiAirMissileTurret()
            return
        end
        -- 重新刷新数据并显示对话框
        self:RefreshData()
        ButtonChoiceDialogManager:ShowDialog(self)
    end
    dialogData.TransferMoney = function(self, buttonIndex)
        local transferToA_Index, transferToB_Index = BtnChoiceDialogEventFunc_GetTransferMoneyIndices(self.PlayerIndex)
        local transferTargetIndex = transferToA_Index
        if buttonIndex == 2 then
            transferTargetIndex = transferToB_Index
        end
        local transferTargetName = "Player_" .. transferTargetIndex
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money >= 1000 then
            ExecuteAction('PLAYER_GIVE_MONEY', transferTargetName, '1000')
            ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, '-1000')
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.transfer.success", transferTargetIndex), 5)
        else
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.transfer.insufficient"), 5)
        end
    end
    -- 处理购买投资
    dialogData.InvestMoney = function(self)
        local playerIndex = self.PlayerIndex
        local start = exCounterGetByName("start")
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        local isInvestementMax, totalInvestedMoney = false, 0
        if playerIndex <= 3 and devil_money >= devil_max then
            isInvestementMax = true
        elseif playerIndex >= 4 and angel_money >= angel_max then
            isInvestementMax = true
        end
        if isInvestementMax then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.invest.failed.max"), 5)
        elseif start <= 600 then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.invest.failed.start_only"), 5)
        elseif money < 100 then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.invest.failed.insufficient"), 5)
        else
            if playerIndex <= 3 then
                devil_money = devil_money + 100
                totalInvestedMoney = devil_money
            else
                angel_money = angel_money + 100
                totalInvestedMoney = angel_money
            end
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.invest.success", totalInvestedMoney), 5)
            ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, '-100')
        end
    end
    -- 处理贷款
    dialogData.TakeLoan = function(self)
        local debtMoney = g_TowerDestroyProgress * 2600 + 4000;
        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, debtMoney)
        exMessageAppendToMessageArea(Localization.get("market.loan.message", self.PlayerIndex))
        exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.loan.success"), 10)

        g_PlayerInDebt[self.PlayerName] = 1;
        g_PlayerDebtCount[self.PlayerName] = g_PlayerDebtCount[self.PlayerName] + 1;

        SchedulerModule.delay_call(function(pName)
            g_PlayerInDebt[pName] = 0;
        end, 15 * 60 * 3, {self.PlayerName})
    end
    dialogData.BuyJapanPointShieldControlTower = function(self)
        local sideName = "evil";
        local playerOwn = "PlyrCivilian";
        local pos = {X = 2900, Y = 3187};
        if self.PlayerIndex >= 4 then
            sideName = "angel";
            playerOwn = "PlyrCreeps";
            pos = {X = 4150, Y = 3187};
        end
        local objectId = g_BuyTowerId["JapanPointShieldControlTower"][sideName];
        if ObjectIsAlive(objectId) then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
            return;
        end
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < 10000 then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.funds.insufficient"), 10);
            return;
        end
        local id = exCreateObject({
            ObjectType = FastHash("JapanPointShieldControlTower"),
            TeamName = playerOwn.."/team"..playerOwn,
            Position = {X = pos.X, Y = pos.Y, Z = 210},
            Angle = 0,
            Health = 5500
        });
        g_BuyTowerId["JapanPointShieldControlTower"][sideName] = id;
        local tower = GetObjectById(id);
        ObjectLoadAttributeModifier(tower,'AttributeModifier_BoxRateOfFireUp', 999999)
        ObjectLoadAttributeModifier(tower,'AttributeModifier_BoxRangeUp', 999999)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"IN_SHIELD_SPHERE", 1)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"UNPACKING", 0)

        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -10000);

    end
    dialogData.BuySovietHeavyAntiAirMissileTurret = function(self)
        local sideName = "evil";
        local playerOwn = "PlyrCivilian";
        local pos = {X = 2900, Y = 3018};
        if self.PlayerIndex >= 4 then
            sideName = "angel";
            playerOwn = "PlyrCreeps";
            pos = {X = 4150, Y = 3018};
        end
        local objectId = g_BuyTowerId["SovietHeavyAntiAirMissileTurret"][sideName];
        if ObjectIsAlive(objectId) then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
            return;
        end
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < 12000 then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.funds.insufficient"), 10);
            return;
        end
        local id = exCreateObject({
            ObjectType = FastHash("SovietHeavyAntiAirMissileTurret"),
            TeamName = playerOwn.."/team"..playerOwn,
            Position = {X = pos.X, Y = pos.Y, Z = 210},
            Angle = 0,
            Health = 9000
        });
        g_BuyTowerId["SovietHeavyAntiAirMissileTurret"][sideName] = id;
        local tower = GetObjectById(id);
        ObjectLoadAttributeModifier(tower,'AttributeModifier_MAP_Area_FireSpeed_Up', 999999)
        ObjectLoadAttributeModifier(tower,'AttributeModifier_JapanNanoEnhanceDroneReinforcement', 999999)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"IN_SHIELD_SPHERE", 1)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"UNPACKING", 0)

        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -12000);

    end

    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

-- 假如是 Player_1，他应该转账给 Player_2 和 3；假如是 2，则应该转账给 1 和 3
-- 假如是 4，应该转账给 5 和 6；假如是 6，则应该转账给 4 和 5
function BtnChoiceDialogEventFunc_GetTransferMoneyIndices(playerIndex)
    local transferToA_Index, transferToB_Index
    if playerIndex == 1 or playerIndex == 4 then
        transferToA_Index = playerIndex + 1
        transferToB_Index = playerIndex + 2
    elseif playerIndex == 2 or playerIndex == 5 then
        transferToA_Index = playerIndex - 1
        transferToB_Index = playerIndex + 1
    elseif playerIndex == 3 or playerIndex == 6 then
        transferToA_Index = playerIndex - 2
        transferToB_Index = playerIndex - 1
    end
    return transferToA_Index, transferToB_Index
end

function BtnChoiceDialogEventFunc_CalculateColor(playerIndex)
    local playerName = "Player_" .. playerIndex
    local color = exPlayerGetColor(playerName)
    if color == nil or color[1] == nil or color[1] <= 0 then
        return nil
    end
    -- from 0~255 RGB values, determine human readable color
    -- maybe we can convert RGB to HSL and determine color based on hue?
    local red = color[1] / 255
    local green = color[2] / 255
    local blue = color[3] / 255
    local maxValue = max(red, green, blue)
    local minValue = min(red, green, blue)
    local lightness = (maxValue + minValue) / 2
    if lightness < 0.1 then
        return Localization.get("color.black")
    elseif lightness > 0.95 then
        return Localization.get("color.white")
    elseif maxValue == minValue then
        return Localization.get("color.gray")
    end
    local d = maxValue - minValue
    local saturation = 0
    if lightness > 0.5 then
        saturation = d / (2 - maxValue - minValue)
    else
        saturation = d / (maxValue + minValue)
    end
    if saturation < 0.1 then
        return Localization.get("color.gray")
    end
    local hue = 0
    if maxValue == red then
        hue = (green - blue) / d
    elseif maxValue == green then
        hue = (blue - red) / d + 2
    elseif maxValue == blue then
        hue = (red - green) / d + 4
    end
    if hue < 0 then
        hue = hue + 6
    end
    hue = hue * 60
    if hue < 20 or hue >= 330 then
        return Localization.get("color.red")
    elseif hue < 45 then
        return Localization.get("color.orange")
    elseif hue < 75 then
        return Localization.get("color.yellow")
    elseif hue < 160 then
        return Localization.get("color.green")
    elseif hue < 200 then
        return Localization.get("color.cyan")
    elseif hue < 270 then
        return Localization.get("color.blue")
    elseif hue < 300 then
        return Localization.get("color.purple")
    elseif hue < 330 then
        return Localization.get("color.pink")
    end
    return nil
end

function BtnChoiceDialogEventFunc_ShowGameModeDialog(playerName)
    local dialogData = {
        DialogId = GAMEMODE_DIALOG_ID,
        PlayerName = playerName,
        Title = Localization.get("game_mode.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {}
        local hasSelected = false
        for i = 1, getn(g_GameModeOptions) do
            local option = g_GameModeOptions[i]
            if i == 6 and not self._initialized then
                -- 假如随机宝箱模式已经开启，则默认选中抽卡模式
                if g_LuckyCrateMode and g_LuckyCrateMode ~= 0 then
                    option.IsSelected = true
                end
            end
            if option.IsSelected then
                tinsert(self.Choices, option.Name .. Localization.get("game_mode.selected_suffix"))
                hasSelected = true
            else
                tinsert(self.Choices, option.Name)
            end
        end
        if hasSelected then
            tinsert(self.Choices, Localization.get("game_mode.confirm"))
        end
        self._initialized = true
    end
    dialogData.OnChoice = function(self, buttonIndex)
        local normalGameOption = g_GameModeOptions[1]
        local deathGameOption = g_GameModeOptions[2]
        local shrinkGameOption = g_GameModeOptions[3]
        local purchaseTechMode = g_GameModeOptions[4]
        local banSeaGameOption = g_GameModeOptions[5]
        local luckyCrateGameOption = g_GameModeOptions[6]
        -- 是否选择了确认按钮
        if buttonIndex == getn(g_GameModeOptions) + 1 then
            -- 假如选择了确认按钮，设置游戏模式
            g_EnableDeathModeEffect = self:BooleanToNumber(deathGameOption.IsSelected)
            g_DisableSeaArmy = self:BooleanToNumber(banSeaGameOption.IsSelected)
            g_LuckyCrateMode = self:BooleanToNumber(luckyCrateGameOption.IsSelected)
            if g_DisableSeaArmy == 1 then
                -- 火炮机车同款开局限制：禁海军时磁暴快艇到第 3 回合才允许生产。
                g_NoNavyTeslaBoatUnlocked = 0
                for i = 1, 6 do
                    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. i, "SovietAntiNavyShipTech1", 0)
                end
            end
            if shrinkGameOption.IsSelected then
                g_GameMode = 3
            elseif purchaseTechMode.IsSelected then
                g_GameMode = 4
            elseif g_EnableDeathModeEffect == 1 then
                g_GameMode = 2
            else
                g_GameMode = 1 -- 默认正常模式
            end
            BtnChoiceDialogEventFunc_ShowHostChoosePlayerSkillModeDialog(self.PlayerName)
            return
        end
        local option = g_GameModeOptions[buttonIndex]
        if not option then
            exMessageAppendToMessageArea(Localization.get("game_mode.error.invalid_button", self.PlayerName, buttonIndex))
            return
        end
        if not option.IsSelected then
            option.IsSelected = true
            exMessageAppendToMessageArea(Localization.get("game_mode.host.selected", option.Name))
        elseif option ~= normalGameOption then
            option.IsSelected = nil
            exMessageAppendToMessageArea(Localization.get("game_mode.host.canceled", option.Name))
        end
        if option == normalGameOption then
            -- 假如选择了正常模式，取消选择死亡模式和缩小模式
            deathGameOption.IsSelected = nil
            shrinkGameOption.IsSelected = nil
        elseif option == deathGameOption or option == shrinkGameOption then
            -- 假如选择了死亡模式或缩小模式，取消选择正常模式
            normalGameOption.IsSelected = nil
        end
        -- 重新刷新数据并显示对话框
        self:RefreshData()
        ButtonChoiceDialogManager:ShowDialog(self)
    end
    dialogData.BooleanToNumber = function(self, value)
        if value then
            return 1
        else
            return 0
        end
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function BtnChoiceDialogEventFunc_ShowHostChoosePlayerSkillModeDialog(playerName)
    local dialogData = {
        DialogId = SKILL_DIALOG_ID_OFFSET + 0, -- 0 是特殊的、房主预选技能组的对话框
        PlayerName = playerName,
        Title = Localization.get("skill_mode.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {}
        local preselectedSkillCount = getn(g_PreselectedSkillIndices)
        if preselectedSkillCount == 0 then
            tinsert(self.Choices, Localization.get("skill_mode.choose_yourself"))
        end
        tinsert(self.Choices, Localization.get("skill_mode.host_symmetric"))
        -- 假如房主还未选择技能，额外提供随机技能选项
        if preselectedSkillCount == 0 then
            -- 关于为什么是可重复的，
            -- 看下面 RandomSymmetricSkill 与 RandomAsymmetricSkill 里面的注释
            tinsert(self.Choices, Localization.get("skill_mode.random_symmetric"))
            tinsert(self.Choices, Localization.get("skill_mode.random_asymmetric"))
        end
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex == 1 then
            if getn(g_PreselectedSkillIndices) == 0 then
                -- 让玩家自行选择技能组
                -- 可以开始游戏了
                BtnChoiceDialogEventFunc_InvokeStartGame()
                return
            end
            return
        end
        if buttonIndex == 2 then
            BtnChoiceDialogEventFunc_ShowHostChooseSkillForAllDialog(self.PlayerName)
            return
        elseif buttonIndex == 3 then
            self:RandomSkill(true)
            BtnChoiceDialogEventFunc_InvokeStartGame()
            return
        elseif buttonIndex == 4 then
            self:RandomSkill(false)
            BtnChoiceDialogEventFunc_InvokeStartGame()
            return
        end

    end
    dialogData.EnsureSideHasNonCopySkill = function(self, playerIndexStart, skillIndexOffset, copySkillIndex)
        local humanPlayerIndices = {}
        local allCopy = 1
        for playerIndex = playerIndexStart, playerIndexStart + 2 do
            local playerName = "Player_" .. playerIndex
            if EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", playerName, "Human") then
                tinsert(humanPlayerIndices, playerIndex)
                if g_PreselectedSkillIndices[playerIndex + skillIndexOffset] ~= copySkillIndex then
                    allCopy = nil
                end
            end
        end
        if getn(humanPlayerIndices) > 0 and allCopy then
            local humanListIndex = self:RandomInteger(1, getn(humanPlayerIndices))
            local playerIndex = humanPlayerIndices[humanListIndex]
            g_PreselectedSkillIndices[playerIndex + skillIndexOffset] = self:RandomInteger(1, copySkillIndex - 1)
        end
    end

    dialogData.RandomSkill = function(self, isSymmetric)
        -- 复制技能需要队友先释放其他技能才有效。
        -- 因此每边至少要有一名真人玩家抽到非复制技能：
        -- 单人时不会抽到复制，多人时不会全是复制。
        local copySkillIndex = 5
        g_PreselectedSkillIndices = {}
        g_PreselectedSkillIndices.IsRandom = true
        local skillNamesCount = getn(g_SkillNames)
        tinsert(g_PreselectedSkillIndices, self:RandomInteger(1, skillNamesCount))
        tinsert(g_PreselectedSkillIndices, self:RandomInteger(1, skillNamesCount))
        tinsert(g_PreselectedSkillIndices, self:RandomInteger(1, skillNamesCount))
        if isSymmetric then
            g_PreselectedSkillIndices.IsSymmetric = true
            -- 两边都映射到前 3 个随机结果，修正后再复制以保持对称。
            self:EnsureSideHasNonCopySkill(1, 0, copySkillIndex)
            self:EnsureSideHasNonCopySkill(4, -3, copySkillIndex)
            -- 对称的随机技能组，复制前 3 个技能组
            tinsert(g_PreselectedSkillIndices, g_PreselectedSkillIndices[1])
            tinsert(g_PreselectedSkillIndices, g_PreselectedSkillIndices[2])
            tinsert(g_PreselectedSkillIndices, g_PreselectedSkillIndices[3])
        else
            g_PreselectedSkillIndices.IsSymmetric = false
            -- 不对称的随机技能组
            tinsert(g_PreselectedSkillIndices, self:RandomInteger(1, skillNamesCount))
            tinsert(g_PreselectedSkillIndices, self:RandomInteger(1, skillNamesCount))
            tinsert(g_PreselectedSkillIndices, self:RandomInteger(1, skillNamesCount))
            self:EnsureSideHasNonCopySkill(1, 0, copySkillIndex)
            self:EnsureSideHasNonCopySkill(4, 0, copySkillIndex)
        end
    end
    dialogData.RandomInteger = function(self, min, max)
        -- 每次调用之前先“洗”一下随机数
        for i = 1, mod(GetFrame(), 7) do
            GetRandomNumber()
        end

        local range = max - min + 1
        local value = GetRandomNumber() * range + min
        value = floor(value)
        if value < min then
            value = min
        elseif value > max then
            value = max
        end
        return value
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end


function BtnChoiceDialogEventFunc_ShowHostChooseSkillForAllDialog(playerName)
    local dialogData = {
        DialogId = SKILL_DIALOG_ID_OFFSET2 + 0, -- 0 是特殊的、房主预选技能组的对话框
        PlayerName = playerName,
        Title = Localization.get("skill_mode.all.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {}
        local preselectedSkillCount = getn(g_PreselectedSkillIndices)
        if preselectedSkillCount > 0 then
            tinsert(self.Choices, Localization.get("skill_mode.cancel"))
            if preselectedSkillCount < 3 then
                -- 假如预选技能组少于 3 个，继续选择
                self.Title = Localization.get("skill_mode.continue", 3 - preselectedSkillCount)
            end
        else
            self.Title = Localization.get("skill_mode.all.title")
        end
        for i = 1, getn(g_SkillNames) do
            local name = g_SkillNames[i]
            for j = 1, getn(g_PreselectedSkillIndices) do
                if g_PreselectedSkillIndices[j] == i then
                    name = name .. Localization.get("skill_mode.selected_suffix")
                    break
                end
            end
            tinsert(self.Choices, name)
        end
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex == 1 and getn(g_PreselectedSkillIndices) > 0 then
            -- 假如房主点击的是“取消”，清空预选技能组
            g_PreselectedSkillIndices = {}
            -- 重新显示对话框
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        end

        -- 假如房主选择了某个技能组
        -- 因为第一个按钮是“让玩家自行选择”，所以技能索引从 2 开始，要减去 1
        local skillIndex = buttonIndex - 1
        local preselectedSkillCount = getn(g_PreselectedSkillIndices)
        -- 但如果此时还一个技能都没选，没有第一个 取消选择 这个按钮
        if preselectedSkillCount == 0 then
            skillIndex = buttonIndex
        end
        if skillIndex < 1 or skillIndex > getn(g_SkillNames) then
            exMessageAppendToMessageArea(Localization.get("skill_mode.invalid_button", self.PlayerName, buttonIndex))
            return
        end
        local alreadySelected = false
        for i = 1, getn(g_PreselectedSkillIndices) do
            if g_PreselectedSkillIndices[i] == skillIndex then
                alreadySelected = true
                break
            end
        end
        if not alreadySelected then
            tinsert(g_PreselectedSkillIndices, skillIndex)
        end

        if getn(g_PreselectedSkillIndices) == 3 then
            -- 已经选择了 3 个技能组，可以开始游戏了
            -- 复制、补全到 6 个技能组
            tinsert(g_PreselectedSkillIndices, g_PreselectedSkillIndices[1])
            tinsert(g_PreselectedSkillIndices, g_PreselectedSkillIndices[2])
            tinsert(g_PreselectedSkillIndices, g_PreselectedSkillIndices[3])
            -- 开始游戏
            BtnChoiceDialogEventFunc_InvokeStartGame()
            return
        end

        -- 继续选择下一个技能组
        self:RefreshData()
        ButtonChoiceDialogManager:ShowDialog(self)
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function BtnChoiceDialogEventFunc_InvokeStartGame()
    -- 这里可以添加一些额外的逻辑，比如检查玩家是否准备好等
    local gameModeText = ''
    local skillText = ''
    if g_GameMode == 1 then
        gameModeText = Localization.get("game_mode.normal")
    elseif g_GameMode == 2 then
        gameModeText = Localization.get("game_mode.death")
    elseif g_GameMode == 3 then
        if g_EnableDeathModeEffect == 1 then
            gameModeText = Localization.get("game_mode.shrink_with_effect")
        else
            gameModeText = Localization.get("game_mode.shrink")
        end
    elseif g_GameMode == 4 then
        gameModeText = Localization.get("game_mode.level_up")
    end
    if g_DisableSeaArmy == 1 then
        gameModeText = gameModeText .. Localization.get("game_mode.no_navy_suffix")
    end
    if g_LuckyCrateMode == 1 then
        gameModeText = gameModeText .. Localization.get("game_mode.lucky_crate_suffix")
    end
    local preselectedSkillCount = getn(g_PreselectedSkillIndices)
    if preselectedSkillCount == 6 then
        if g_PreselectedSkillIndices.IsRandom then
            if g_PreselectedSkillIndices.IsSymmetric then
                skillText = Localization.get("game.start.skill_random_symmetric")
            else
                skillText = Localization.get("game.start.skill_random_asymmetric")
            end
            -- 调试版本：显示随机选择的技能组
            -- 正式发布的版本里，注释掉下面的代码，给玩家一个“惊喜”
            -- for i = 1, preselectedSkillCount do
            --     skillText = skillText .. g_SkillNames[g_PreselectedSkillIndices[i]]
            --     if i < preselectedSkillCount then
            --         skillText = skillText .. ','
            --     end
            -- end
        else
            skillText = Localization.get("game.start.skill_prefix")
            for i = 1, 3 do
                skillText = skillText .. g_SkillNames[g_PreselectedSkillIndices[i]]
                if i < preselectedSkillCount then
                    skillText = skillText .. ','
                end
            end
        end
    elseif preselectedSkillCount == 0 then
        skillText = Localization.get("game.start.skill_free_choice")
    else
        exMessageAppendToMessageArea(Localization.get("skill_mode.error.preselected_count", preselectedSkillCount))
        return
    end
    exMessageAppendToMessageArea(Localization.get("game.start.begin", gameModeText))
    exMessageAppendToMessageArea(skillText)
    exAddTextToPublicBoard(format("%s\n%s\n%s", Localization.get("game.start.begin", gameModeText), skillText, Localization.get("game.start.economic_multiplier", exModeGetCheatMultiplier())), 15)
    exEnableWBScript("readyForStartCam")
end

function BtnChoiceDialogEventFunc_ShowPlayerChooseSkillDialog(playerName)
    local playerIndex = g_PlayerNameToIndex[playerName]
    if type(playerIndex) ~= 'number' or playerIndex < 1 or playerIndex > 6 then
        exMessageAppendToMessageArea(Localization.get("skill_mode.player_choose.invalid_player_name"))
        return
    end
    local dialogData = {
        DialogId = SKILL_DIALOG_ID_OFFSET + g_PlayerNameToIndex[playerName],
        PlayerName = playerName,
        Title = Localization.get("skill_mode.player_choose.title"),
        Choices = {},
    }
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex == getn(g_SkillNames) + 1 then
            -- 假如玩家选择了退出，则不做任何操作
            return
        end
        CenterTopBtnFunc_CreatePlayerSkillButtons(g_PlayerNameToIndex[self.PlayerName], buttonIndex)
    end
    for i = 1, getn(g_SkillNames) do
        tinsert(dialogData.Choices, g_SkillNames[i])
    end
    tinsert(dialogData.Choices, Localization.get("skill_mode.player_choose.exit"))
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function BtnChoiceDialogEventFunc_ShowPurchaseTechDialog(playerName)
    local playerIndex = g_PlayerNameToIndex[playerName]
    if type(playerIndex) ~= 'number' or playerIndex < 1 or playerIndex > 6 then
        exMessageAppendToMessageArea(Localization.get("skill_mode.player_choose.invalid_tech_player_name"))
        return
    end
    local techLevel = g_evilTechLevel
    if playerIndex >= 4 then
        techLevel = g_angelTechLevel
    end

    local dialogData = {
        DialogId = PURCHASE_TECH_DIALOG_ID + g_PlayerNameToIndex[playerName],
        PlayerName = playerName,
        Choices = {},
    }

    dialogData.getNeededMoney = function(self, techLevel3)
        local playerIndex2 = g_PlayerNameToIndex[self.PlayerName]
        local neededMoneyOriginal = g_techLevelNeededMoney[techLevel3]
        local roundRecord = g_evilTechBuyRound;
        if playerIndex2 >= 4 then
            roundRecord = g_angelTechBuyRound
        end
        local round = exCounterGetByName("lvc")
        local diffRound = round - roundRecord[techLevel3]
        return neededMoneyOriginal - min(g_maxTechLevelDecreaseMoney[techLevel3], diffRound * g_maxTechLevelDecreaseRate[techLevel3])
    end

    local neededMoney = dialogData:getNeededMoney(techLevel)
    dialogData.Title = Localization.get("skill_mode.purchase.tech.title", neededMoney)

    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex == 1 then

            local previous = SetWorldBuilderThisPlayer(1)

            local playerIndex2 = g_PlayerNameToIndex[self.PlayerName]
            local techLevel2 = g_evilTechLevel
            if playerIndex2 >= 4 then
                techLevel2 = g_angelTechLevel
            end

            local neededMoney2 = self:getNeededMoney(techLevel2)

            local money = exPlayerGetCurrentMoney(self.PlayerName)
            if money >= neededMoney2 then
                ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -neededMoney2)

                self:onPurchaseSuccess(playerIndex2)

            else
                exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("skill_mode.purchase.tech.failed"), 10)
            end

            SetWorldBuilderThisPlayer(previous)
        end
    end

    dialogData.onPurchaseSuccess = function(self, pIndex)
        if pIndex >= 4 then
            g_angelTechLevel = g_angelTechLevel + 1
            if g_angelTechLevel < 4 then
                for i = 4, 6 do
                    exAddTextToPublicBoardForPlayer("Player_" .. tostring(i), Localization.get("skill_mode.purchase.tech.success"), 20)
                    exCreateCustomButtonForPlayer("Player_" .. tostring(i), {
                        Index = 7,
                        TextureName = "AUA_Bribe",
                        Desc = Localization.get("skill_mode.purchase.tech.description", g_angelTechLevel),
                        X = 250,
                        Y = 20,
                        GroupIndex = 1,
                        AlignX = "right",
                        AlignY = "top",
                    })
                end

            else
                for i = 4, 6 do
                    exCustomBtnSetVisibilityForPlayer("Player_" .. tostring(i), 7, 0)
                end
            end

            -- TODO 自定义文本更新   解锁科技，解锁电厂数量

            local powerNum = 5;
            local celestialPowerNum = 4;
            if g_angelTechLevel == 2 then
                exEnableWBScript('Player_4/UNLOCK1__4')
                exEnableWBScript('Player_5/UNLOCK1__5')
                exEnableWBScript('Player_6/UNLOCK1__6')
                LIMITPOWERC = 6
                powerNum = 7;
                celestialPowerNum = 6;
                g_angelTechBuyRound[2] = exCounterGetByName("lvc")
            elseif g_angelTechLevel == 3 then
                exEnableWBScript('Player_4/UNLOCK2__4')
                exEnableWBScript('Player_5/UNLOCK2__5')
                exEnableWBScript('Player_6/UNLOCK2__6')
                LIMITPOWERC = 8
                powerNum = 9;
                celestialPowerNum = 8;
                g_angelTechBuyRound[3] = exCounterGetByName("lvc")
            elseif g_angelTechLevel == 4 then
                exEnableWBScript('Player_4/UNLOCK3__4')
                exEnableWBScript('Player_5/UNLOCK3__5')
                exEnableWBScript('Player_6/UNLOCK3__6')
                LIMITPOWERC = 10
                powerNum = 11;
                celestialPowerNum = 10;
            end

            ExecuteAction("PLAY_SOUND_EFFECT", "MAP_Rescue");

            for i = 4, 6 do
                exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 1, Localization.get("purchase_tech.level", g_angelTechLevel))
                exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 2, Localization.get("purchase_tech.power_plants", powerNum))
                exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 3, Localization.get("purchase_tech.celestial_plants", celestialPowerNum))
            end


        else
            g_evilTechLevel = g_evilTechLevel + 1
            if g_evilTechLevel < 4 then
                for i = 1, 3 do
                    exAddTextToPublicBoardForPlayer("Player_" .. tostring(i), Localization.get("skill_mode.purchase.tech.success"), 20)
                    exCreateCustomButtonForPlayer("Player_" .. tostring(i), {
                        Index = 7,
                        TextureName = "AUA_Bribe",
                        Desc = Localization.get("skill_mode.purchase.tech.description", g_evilTechLevel),
                        X = 250,
                        Y = 20,
                        GroupIndex = 1,
                        AlignX = "right",
                        AlignY = "top",
                    })
                end

            else
                for i = 1, 3 do
                    exCustomBtnSetVisibilityForPlayer("Player_" .. tostring(i), 7, 0)
                end
            end

            LIMITPOWERC = LIMITPOWERC  + 2
            local powerNum = 5;
            local celestialPowerNum = 4;
            if g_evilTechLevel == 2 then
                exEnableWBScript('Player_1/UNLOCK1__1')
                exEnableWBScript('Player_2/UNLOCK1__2')
                exEnableWBScript('Player_3/UNLOCK1__3')
                LIMITPOWERC = 6
                powerNum = 7;
                celestialPowerNum = 6;
                g_evilTechBuyRound[2] = exCounterGetByName("lvc")
            elseif g_evilTechLevel == 3 then
                exEnableWBScript('Player_1/UNLOCK2__1')
                exEnableWBScript('Player_2/UNLOCK2__2')
                exEnableWBScript('Player_3/UNLOCK2__3')
                LIMITPOWERC = 8
                powerNum = 9;
                celestialPowerNum = 8;
                g_evilTechBuyRound[3] = exCounterGetByName("lvc")
            elseif g_evilTechLevel == 4 then
                exEnableWBScript('Player_1/UNLOCK3__1')
                exEnableWBScript('Player_2/UNLOCK3__2')
                exEnableWBScript('Player_3/UNLOCK3__3')
                LIMITPOWERC = 10
                powerNum = 11;
                celestialPowerNum = 10;
            end

            ExecuteAction("PLAY_SOUND_EFFECT", "MAP_Rescue");

            for i = 1, 3 do
                exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 1, Localization.get("purchase_tech.level", g_evilTechLevel))
                exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 2, Localization.get("purchase_tech.power_plants", powerNum))
                exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 3, Localization.get("purchase_tech.celestial_plants", celestialPowerNum))
            end

        end
    end

    tinsert(dialogData.Choices, Localization.get("skill_mode.purchase.tech.choice.buy"))
    tinsert(dialogData.Choices, Localization.get("skill_mode.purchase.tech.choice.no_buy"))
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function BtnChoiceDialogEventFunc_RecycleUnitDialog(playerName)
    local playerIndex = g_PlayerNameToIndex[playerName]
    if type(playerIndex) ~= 'number' or playerIndex < 1 or playerIndex > 6 then
        exMessageAppendToMessageArea(Localization.get("skill_mode.player_choose.invalid_tech_player_name"))
        return
    end

    local dialogData = {
        DialogId = RECYCLE_UNIT_DIALOG_ID + g_PlayerNameToIndex[playerName],
        PlayerName = playerName,
        Choices = {},
    }

    dialogData.Title = Localization.get("recycle.dialog.title", g_CurrentClickRecycleUnit[playerIndex].Name)

    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex <= 4 then

            local previous = SetWorldBuilderThisPlayer(1)

            local playerIndex2 = g_PlayerNameToIndex[self.PlayerName]

            local targetUnitIndex = g_UnitNameToUnitIndex[g_CurrentClickRecycleUnit[playerIndex2].Type] or -1

            if targetUnitIndex > 0 then
                local count = g_RecycleUnitCount[buttonIndex];
                if UNITCOUNT[playerIndex2][targetUnitIndex] > count then
                    UNITCOUNT[playerIndex2][targetUnitIndex] = UNITCOUNT[playerIndex2][targetUnitIndex] - count;
                    ANYUNITCOUNT[playerIndex2] = ANYUNITCOUNT[playerIndex2] - count ;
                else
                    count = UNITCOUNT[playerIndex2][targetUnitIndex];
                    ANYUNITCOUNT[playerIndex2] = ANYUNITCOUNT[playerIndex2] - count ;
                    UNITCOUNT[playerIndex2][targetUnitIndex] = 0;
                end
                local leftCount = UNITCOUNT[playerIndex2][targetUnitIndex];
                -- 苏联拿到大生产之后需要乘一个系数  可能会导致苏联后期回收亏钱，不过也很难管了
                local getSovietBonus = g_ProductionBonus_SovietGet[playerIndex2];
                -- 只给90%回收
                local discount = 0.9;
                if getSovietBonus then
                    discount = 0.72;
                end
                ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, count * g_CurrentClickRecycleUnit[playerIndex2].Money * discount) ;
                -- 同时也要告诉盟友
                local msg = Localization.get("recycle.message", tostring(playerIndex2), count, g_CurrentClickRecycleUnit[playerIndex2].Name, tostring(leftCount));
                if playerIndex2 >= 4 then
                    exAddTextToPublicBoardForPlayer("Player_4", msg, 5);
                    exAddTextToPublicBoardForPlayer("Player_5", msg, 5);
                    exAddTextToPublicBoardForPlayer("Player_6", msg, 5);
                else
                    exAddTextToPublicBoardForPlayer("Player_1", msg, 5);
                    exAddTextToPublicBoardForPlayer("Player_2", msg, 5);
                    exAddTextToPublicBoardForPlayer("Player_3", msg, 5);
                end
            end

            SetWorldBuilderThisPlayer(previous)
        end
    end

    tinsert(dialogData.Choices, Localization.get("recycle.choice.1"))
    tinsert(dialogData.Choices, Localization.get("recycle.choice.5"))
    tinsert(dialogData.Choices, Localization.get("recycle.choice.10"))
    tinsert(dialogData.Choices, Localization.get("recycle.choice.20"))
    tinsert(dialogData.Choices, Localization.get("recycle.choice.cancel"))
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end
