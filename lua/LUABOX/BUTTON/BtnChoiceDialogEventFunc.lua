-- 讲解见 analysis/地图注释说明文档.md 附录 A.27、A.34

devil_max = 200
angel_max = 200

g_GameMode = 1;
g_EnableDeathModeEffect = 0;
g_EnableShrinkMode = 0;
g_DisableSeaArmy = 0;
g_DrawMode = 0; -- 0: disabled, 1: original lucky crate, 2: pure draw
g_LuckyCrateMode = 0; -- compatibility flag used by the existing lucky-crate implementation
g_HextechCount = 0; -- 海克斯符文发放次数：可选 0~4，默认随局外“开启随机箱子”配置选择 0 或 3
g_HextechCountManuallySet = false; -- 房主是否在选项 5 手动设置过海克斯次数（设置过就不再被随机箱子默认值覆盖）
g_EnableHextechRune = 0; -- 海克斯符文系统是否启用（g_HextechCount > 0 时置 1）

function BtnChoiceDialogEventFunc_ApplyHostHextechSetting()
    g_EnableHextechRune = 0
    if g_HextechCount ~= nil and g_HextechCount > 0 then
        g_EnableHextechRune = 1
    end
    if CenterTopBtnFunc_UpdateHextechPanelButton ~= nil then
        CenterTopBtnFunc_UpdateHextechPanelButton()
    end
end

g_GameModeName = {
    [1] = Localization.get("game_mode.name.1"),
    [2] = Localization.get("game_mode.name.2"),
    [4] = Localization.get("game_mode.name.4"),
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
DRAW_MODE_DIALOG_ID = 202
HEXTECH_MODE_DIALOG_ID = 203
MORE_OPTIONS_DIALOG_ID = 204

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
        [4] = Localization.get("game_mode.name.4"),
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
    },
    ["JapanKamikazeCommandTower"] = {
        ["angel"] = 0,
        ["evil"] = 0,
    },
    ["CelestialEnergyRailgunBase"] = {
        ["angel"] = 0,
        ["evil"] = 0,
    },
    ["AlliedAegisLargeDefenseBase"] = {
        ["angel"] = { 0, 0 },
        ["evil"] = { 0, 0 },
    }
}
g_HextechTowerDefenseExpert = g_HextechTowerDefenseExpert or { false, false, false, false, false, false }

function BtnChoiceDialogEventFunc_HasTowerDefenseExpert(playerIndex)
    return g_HextechTowerDefenseExpert ~= nil
        and g_HextechTowerDefenseExpert[playerIndex] == true
end

function BtnChoiceDialogEventFunc_GetTowerPrice(playerIndex, basePrice)
    if BtnChoiceDialogEventFunc_HasTowerDefenseExpert(playerIndex) then
        return floor(basePrice * 0.5)
    end
    return basePrice
end

-- 返回本方当前最前排的存活陆地防御塔；前排损失后自动依次后退到下一座塔。
function BtnChoiceDialogEventFunc_GetFrontDefenseTower(playerIndex)
    local towerNames = { "T71", "T72", "T73", "T74" }
    if playerIndex >= 4 then
        towerNames = { "T81", "T82", "T83", "T84" }
    end
    for i = 1, 4, 1 do
        local tower = GetObjectByScriptName(towerNames[i])
        if ObjectIsAlive(tower) then
            return tower
        end
    end
    return nil
end

-- 从内圈往外找第一个空槽；scanLimit 以外的外圈槽位只允许塔防专家使用。
function BtnChoiceDialogEventFunc_AllocateAegisSlot(slots, scanLimit)
    for i = 1, scanLimit, 1 do
        if not ObjectIsAlive(slots[i]) then
            return i
        end
    end
    return nil
end

-- 槽位索引 → 相对走廊中心点的横向偏移：奇数索引在 +Y 侧、偶数索引在 -Y 侧，每外扩一环距离加 60。
function BtnChoiceDialogEventFunc_GetAegisLateralOffset(slotIndex)
    local ringCount = floor((slotIndex - 1) / 2)
    local lateralDirection = 1
    if slotIndex - ringCount * 2 == 2 then
        lateralDirection = -1
    end
    return lateralDirection * (126.75 + ringCount * 60)
end

g_CelestialTowerShadowFilter = nil

function BtnChoiceDialogEventFunc_GetCelestialTowerShadowFilter()
    if g_CelestialTowerShadowFilter == nil then
        g_CelestialTowerShadowFilter = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = { "CC_ShadowObject", "CC_ShadowParalyzer" },
        })
    end
    return g_CelestialTowerShadowFilter
end

-- 延迟回调只收 objectId（跨帧不缓存单位句柄）；这几帧里塔被打掉就跳过。
function BtnChoiceDialogEventFunc_ClearCelestialTowerCore(objectId)
    if not ObjectIsAlive(objectId) then
        return
    end
    local object = GetObjectById(objectId)
    local x, y, z = ObjectGetPosition(object)
    local shadows, count = ObjectFindObjects(object,
        {X = x, Y = y, Z = z, Radius = 5, DistType = "CENTER_2D"},
        BtnChoiceDialogEventFunc_GetCelestialTowerShadowFilter())
    for i = 1, count, 1 do
        if shadows[i] ~= nil then
            ExecuteAction("NAMED_DELETE", shadows[i])
        end
    end
end

function BtnChoiceDialogEventFunc_FinishCelestialTower(objectId)
    ObjectSetObjectStatus(GetObjectById(objectId), "POINT_DEFENSE_DRONE_ATTACHED")
    SchedulerModule.delay_call(BtnChoiceDialogEventFunc_ClearCelestialTowerCore,
        3, {objectId})
end

-- 天门神弓的取位与加成，市场购买与符文赠送共用：站在樱花井再往后一格（253.5），
-- 血量与埃奎斯同款 9000，只加射程 ×1.75、不带视野（带视野会使天弓推塔）。
function BtnChoiceDialogEventFunc_CreateCelestialRailgun(playerIndex)
    local behindDirection = -1;
    local playerOwn = "PlyrCivilian";
    local pos = {X = 2646.5, Y = 3102.5, Z = 210};
    if playerIndex >= 4 then
        behindDirection = 1;
        playerOwn = "PlyrCreeps";
        pos = {X = 4403.5, Y = 3102.5, Z = 210};
    end
    local frontTower = BtnChoiceDialogEventFunc_GetFrontDefenseTower(playerIndex)
    if ObjectIsAlive(frontTower) then
        local towerX, towerY, towerZ = ObjectGetPosition(frontTower);
        pos = {X = towerX + behindDirection * 253.5, Y = towerY, Z = towerZ};
    end
    local id = exCreateObject({
        ObjectType = FastHash("CelestialEnergyRailgunBase"),
        TeamName = playerOwn.."/team"..playerOwn,
        Position = pos,
        Angle = 0,
        Health = 9000
    });
    if not g_CelestialEnergyRailgunBaseRangeX175Modifier then
        g_CelestialEnergyRailgunBaseRangeX175Modifier = exAttributeModifierCreate(
            { RANGE = 1.75 }, 1)
    end
    ObjectLoadAttributeModifier(GetObjectById(id), g_CelestialEnergyRailgunBaseRangeX175Modifier)
    BtnChoiceDialogEventFunc_FinishCelestialTower(id)
    return id
end


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
        Page = 1,
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

        if self.Page == 2 then
            local shieldTowerPrice = BtnChoiceDialogEventFunc_GetTowerPrice(playerIndex, 10000)
            local sakuraWellPrice = BtnChoiceDialogEventFunc_GetTowerPrice(playerIndex, 10000)
            local poplarTowerPrice = BtnChoiceDialogEventFunc_GetTowerPrice(playerIndex, 12000)
            local aegisPrice = BtnChoiceDialogEventFunc_GetTowerPrice(playerIndex, 15000)
            local tianmenBowPrice = BtnChoiceDialogEventFunc_GetTowerPrice(playerIndex, 20000)
            self.Choices = {
                Localization.get("market.buy_shield_tower", shieldTowerPrice), -- 1
                Localization.get("market.buy_sakura_well", sakuraWellPrice), -- 2
                Localization.get("market.buy_poplar_tower", poplarTowerPrice), -- 3
                Localization.get("market.buy_aegis_shield_generator", aegisPrice), -- 4
                Localization.get("market.buy_tianmen_bow", tianmenBowPrice), -- 5
                Localization.get("market.back_to_main_page"), -- 6
            }
        else
            self.Choices = {
                Localization.get("market.transfer.choice", roles[transferToA_Index], playerA_Color), -- 1
                Localization.get("market.transfer.choice", roles[transferToB_Index], playerB_Color), -- 2
                nextInvestmentText, -- 3
                Localization.get("market.back_to_battle"), -- 4
                Localization.get("market.more_defense_buildings"), -- 5
            }
        end
        --if g_PlayerDebtCount[self.PlayerName] == 0 then
        --    local debtMoney = g_TowerDestroyProgress * 2600 + 4000;
        --    tinsert(self.Choices, format("向银行贷款 %d\n(将会3分钟无收入)", debtMoney)) -- 5
        --else
            -- 您已贷款，无法再次贷款
        --end
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if self.Page == 2 then
            if buttonIndex == 1 then
                self:BuyJapanPointShieldControlTower()
                return
            elseif buttonIndex == 2 then
                self:BuyJapanKamikazeCommandTower()
                return
            elseif buttonIndex == 3 then
                self:BuySovietHeavyAntiAirMissileTurret()
                return
            elseif buttonIndex == 4 then
                self:BuyAlliedAegisLargeDefenseBase()
                return
            elseif buttonIndex == 5 then
                self:BuyCelestialEnergyRailgunBase()
                return
            elseif buttonIndex == 6 then
                self.Page = 1
            end
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        end
        if buttonIndex == 1 or buttonIndex == 2 then
            self:TransferMoney(buttonIndex)
        elseif buttonIndex == 3 then
            self:InvestMoney()
        elseif buttonIndex == 4 then
            -- 回到战场（因此不再显示交易市场对话框）
            return
        elseif buttonIndex == 5 then
            self.Page = 2
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
        local ignoresLimit = BtnChoiceDialogEventFunc_HasTowerDefenseExpert(self.PlayerIndex)
        if ObjectIsAlive(objectId) and not ignoresLimit then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
            return;
        end
        local price = BtnChoiceDialogEventFunc_GetTowerPrice(self.PlayerIndex, 10000)
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < price then
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
        if not ignoresLimit then
            g_BuyTowerId["JapanPointShieldControlTower"][sideName] = id;
        end
        local tower = GetObjectById(id);
        ObjectLoadAttributeModifier(tower,'AttributeModifier_BoxRateOfFireUp', 999999)
        ObjectLoadAttributeModifier(tower,'AttributeModifier_BoxRangeUp', 999999)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"IN_SHIELD_SPHERE", 1)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"UNPACKING", 0)

        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -price);

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
        local ignoresLimit = BtnChoiceDialogEventFunc_HasTowerDefenseExpert(self.PlayerIndex)
        if ObjectIsAlive(objectId) and not ignoresLimit then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
            return;
        end
        local price = BtnChoiceDialogEventFunc_GetTowerPrice(self.PlayerIndex, 12000)
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < price then
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
        if not ignoresLimit then
            g_BuyTowerId["SovietHeavyAntiAirMissileTurret"][sideName] = id;
        end
        local tower = GetObjectById(id);
        ObjectLoadAttributeModifier(tower,'AttributeModifier_MAP_Area_FireSpeed_Up', 999999)
        ObjectLoadAttributeModifier(tower,'AttributeModifier_JapanNanoEnhanceDroneReinforcement', 999999)
        -- 胡杨塔射程增加 50%，最终为基础射程的 1.5 倍；塔不会移动，视野必须同步放大才能真正打到。
        if not g_SovietHeavyAntiAirMissileTurretRangeX15Modifier then
            g_SovietHeavyAntiAirMissileTurretRangeX15Modifier = exAttributeModifierCreate(
                { RANGE = 1.5, VISION = 1.5 }, 1)
        end
        ObjectLoadAttributeModifier(tower, g_SovietHeavyAntiAirMissileTurretRangeX15Modifier)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"IN_SHIELD_SPHERE", 1)
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", tower,"UNPACKING", 0)

        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -price);

    end
    dialogData.BuyJapanKamikazeCommandTower = function(self)
        local sideName = "evil";
        local playerOwn = "PlyrCivilian";
        local behindDirection = -1;
        local pos = {X = 2773.25, Y = 3102.5, Z = 210};
        if self.PlayerIndex >= 4 then
            sideName = "angel";
            playerOwn = "PlyrCreeps";
            behindDirection = 1;
            pos = {X = 4276.75, Y = 3102.5, Z = 210};
        end
        local frontTower = BtnChoiceDialogEventFunc_GetFrontDefenseTower(self.PlayerIndex)
        if ObjectIsAlive(frontTower) then
            local towerX, towerY, towerZ = ObjectGetPosition(frontTower);
            -- 以当前最前排存活塔为中心：左侧向左、右侧向右是后方。
            local behindDistance = 126.75;
            pos = {X = towerX + behindDirection * behindDistance, Y = towerY, Z = towerZ};
        end
        local objectId = g_BuyTowerId["JapanKamikazeCommandTower"][sideName];
        local ignoresLimit = BtnChoiceDialogEventFunc_HasTowerDefenseExpert(self.PlayerIndex)
        if ObjectIsAlive(objectId) and not ignoresLimit then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
            return;
        end
        local price = BtnChoiceDialogEventFunc_GetTowerPrice(self.PlayerIndex, 10000)
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < price then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.funds.insufficient"), 10);
            return;
        end
        local id = exCreateObject({
            ObjectType = FastHash("JapanKamikazeCommandTower"),
            TeamName = playerOwn.."/team"..playerOwn,
            Position = {X = pos.X, Y = pos.Y, Z = pos.Z},
            Angle = 0,
            -- 与埃奎斯护盾发生器使用相同的 9000 生命值。
            Health = 9000
        });
        -- 樱花井射程增加 50%，最终为基础射程的 1.5 倍；塔不会移动，视野必须同步放大才能真正打到。
        if not g_JapanKamikazeCommandTowerRangeX15Modifier then
            g_JapanKamikazeCommandTowerRangeX15Modifier = exAttributeModifierCreate(
                { RANGE = 1.5, VISION = 1.5 }, 1)
        end
        ObjectLoadAttributeModifier(GetObjectById(id), g_JapanKamikazeCommandTowerRangeX15Modifier)
        if not ignoresLimit then
            g_BuyTowerId["JapanKamikazeCommandTower"][sideName] = id;
        end
        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -price);
    end
    -- 天门神弓（神州防御塔）：限购 1 座，塔防专家半价且无视数量限制。
    dialogData.BuyCelestialEnergyRailgunBase = function(self)
        local sideName = "evil";
        if self.PlayerIndex >= 4 then
            sideName = "angel";
        end
        local objectId = g_BuyTowerId["CelestialEnergyRailgunBase"][sideName];
        local ignoresLimit = BtnChoiceDialogEventFunc_HasTowerDefenseExpert(self.PlayerIndex)
        if ObjectIsAlive(objectId) and not ignoresLimit then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
            return;
        end
        local price = BtnChoiceDialogEventFunc_GetTowerPrice(self.PlayerIndex, 20000)
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < price then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.funds.insufficient"), 10);
            return;
        end
        local id = BtnChoiceDialogEventFunc_CreateCelestialRailgun(self.PlayerIndex)
        if not ignoresLimit then
            g_BuyTowerId["CelestialEnergyRailgunBase"][sideName] = id;
        end
        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -price);
    end
    dialogData.BuyAlliedAegisLargeDefenseBase = function(self)
        local sideName = "evil";
        local playerOwn = "PlyrCivilian";
        local behindDirection = -1;
        local towerPos = {X = 2900, Y = 3102.5, Z = 210};
        if self.PlayerIndex >= 4 then
            sideName = "angel";
            playerOwn = "PlyrCreeps";
            behindDirection = 1;
            towerPos = {X = 4150, Y = 3102.5, Z = 210};
        end
        local frontTower = BtnChoiceDialogEventFunc_GetFrontDefenseTower(self.PlayerIndex)
        if ObjectIsAlive(frontTower) then
            local towerX, towerY, towerZ = ObjectGetPosition(frontTower);
            towerPos = {X = towerX + behindDirection * 126.75, Y = towerY, Z = towerZ};
        end
        local ignoresLimit = BtnChoiceDialogEventFunc_HasTowerDefenseExpert(self.PlayerIndex)
        -- 同阵营三名玩家取的是同一组前排塔（T71~T74 / T81~T84），走廊是共享的，所以槽位表按 sideName 存。
        local slots = g_BuyTowerId["AlliedAegisLargeDefenseBase"][sideName];
        -- 常规配额只有内圈这两个槽，向外扩出去的槽位属于塔防专家专用，否则队友用专家扩出的外圈空位
        -- 会让没有专家的玩家也突破 2 座上限制。
        local scanLimit = getn(slots);
        if not ignoresLimit then
            scanLimit = 2;
        end
        local slotIndex = BtnChoiceDialogEventFunc_AllocateAegisSlot(slots, scanLimit)
        if slotIndex == nil then
            if not ignoresLimit then
                exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.tower.already_exists"), 10);
                return;
            end
            -- 所有槽位都被占用时才向外扩一环（塔防专家无视数量限制）。
            slotIndex = getn(slots) + 1;
            slots[slotIndex] = 0;
        end
        local price = BtnChoiceDialogEventFunc_GetTowerPrice(self.PlayerIndex, 15000)
        local money = exPlayerGetCurrentMoney(self.PlayerName)
        if money < price then
            exAddTextToPublicBoardForPlayer(self.PlayerName, Localization.get("market.funds.insufficient"), 10);
            return;
        end
        -- 先取当前最前排存活塔的后方作为走廊中心，再按槽位索引对称填充左右两侧。
        local pos = {
            X = towerPos.X,
            Y = towerPos.Y + BtnChoiceDialogEventFunc_GetAegisLateralOffset(slotIndex),
            Z = towerPos.Z
        };
        local id = exCreateObject({
            ObjectType = FastHash("AlliedAegisLargeDefenseBase"),
            TeamName = playerOwn.."/team"..playerOwn,
            Position = {X = pos.X, Y = pos.Y, Z = pos.Z},
            Angle = 0,
            Health = 9000
        });
        slots[slotIndex] = id;
        ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, -price);
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
            if i == 4 then
                -- 抽卡模式选择：显示当前状态
                local drawModeName = Localization.get("draw_mode.disabled")
                if g_DrawMode == 1 then
                    drawModeName = Localization.get("draw_mode.original")
                elseif g_DrawMode == 2 then
                    drawModeName = Localization.get("draw_mode.pure")
                end
                tinsert(self.Choices, Localization.get("draw_mode.open", drawModeName))
            elseif i == 5 then
                -- 海克斯符文设置：显示当前状态
                local hextechName = Localization.get("hextech.option.0")
                if g_HextechCount ~= nil then
                    if g_HextechCount >= 1 and g_HextechCount <= 4 then
                        hextechName = Localization.get("hextech.option." .. tostring(g_HextechCount))
                    end
                end
                tinsert(self.Choices, Localization.get("hextech.entry", hextechName))
            elseif i == 6 then
                -- 更多选项：显示缩小/禁海状态
                local moreOptionsName = ""
                if g_EnableShrinkMode == 1 then
                    moreOptionsName = moreOptionsName .. Localization.get("game_mode.shrink_suffix")
                end
                if g_DisableSeaArmy == 1 then
                    moreOptionsName = moreOptionsName .. Localization.get("game_mode.no_navy_suffix")
                end
                tinsert(self.Choices, Localization.get("more_options.entry") .. moreOptionsName)
            elseif option.IsSelected then
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
        local purchaseTechMode = g_GameModeOptions[3]
        -- 是否选择了确认按钮
        if buttonIndex == getn(g_GameModeOptions) + 1 then
            -- 假如选择了确认按钮，设置游戏模式
            g_EnableDeathModeEffect = self:BooleanToNumber(deathGameOption.IsSelected)
            g_LuckyCrateMode = 0
            if g_DrawMode == 1 or g_DrawMode == 2 then
                g_LuckyCrateMode = 1
            end
            -- 海克斯与抽卡解耦：这里不再由随机箱子/抽卡状态推导海克斯次数，
            -- 只按「海克斯符文设置」（选项 5）当前的 g_HextechCount 折算启用标志。
            -- 未手动设置时保持初始默认，随后由局外“开启随机箱子”的检测决定是否改为三个。
            BtnChoiceDialogEventFunc_ApplyHostHextechSetting()
            if g_DisableSeaArmy == 1 then
                -- 火炮机车同款开局限制：禁海军时磁暴快艇到第 3 回合才允许生产。
                g_NoNavyTeslaBoatUnlocked = 0
                for i = 1, 6 do
                    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. i, "SovietAntiNavyShipTech1", 0)
                end
            end
            if purchaseTechMode.IsSelected then
                g_GameMode = 4
            elseif g_EnableDeathModeEffect == 1 then
                g_GameMode = 2
            else
                g_GameMode = 1 -- 默认标准模式
            end
            BtnChoiceDialogEventFunc_ShowHostChoosePlayerSkillModeDialog(self.PlayerName)
            return
        end
        -- 抽卡模式选择入口（选项 4）
        if buttonIndex == 4 then
            BtnChoiceDialogEventFunc_ShowDrawModeDialog(self.PlayerName)
            return
        end
        -- 海克斯符文设置入口（选项 5）
        if buttonIndex == 5 then
            BtnChoiceDialogEventFunc_ShowHextechModeDialog(self.PlayerName)
            return
        end
        -- 更多选项入口（选项 6：缩小/禁止海军）
        if buttonIndex == 6 then
            BtnChoiceDialogEventFunc_ShowMoreOptionsDialog(self.PlayerName)
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
            -- 标准、死亡、升本是互斥的基础模式。
            deathGameOption.IsSelected = nil
            purchaseTechMode.IsSelected = nil
        elseif option == deathGameOption then
            normalGameOption.IsSelected = nil
            purchaseTechMode.IsSelected = nil
        elseif option == purchaseTechMode then
            normalGameOption.IsSelected = nil
            deathGameOption.IsSelected = nil
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

-- 更多选项对话框（缩小模式 / 禁止海军）
function BtnChoiceDialogEventFunc_ShowMoreOptionsDialog(playerName)
    local dialogData = {
        DialogId = MORE_OPTIONS_DIALOG_ID,
        PlayerName = playerName,
        Title = Localization.get("more_options.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {
            Localization.get("more_options.shrink") .. (g_EnableShrinkMode == 1 and Localization.get("game_mode.selected_suffix") or ""),
            Localization.get("more_options.no_navy") .. (g_DisableSeaArmy == 1 and Localization.get("game_mode.selected_suffix") or ""),
            Localization.get("more_options.back"),
        }
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex == 1 then
            if g_EnableShrinkMode == 1 then
                g_EnableShrinkMode = 0
                exMessageAppendToMessageArea(Localization.get("game_mode.host.canceled", Localization.get("more_options.shrink")))
            else
                g_EnableShrinkMode = 1
                exMessageAppendToMessageArea(Localization.get("game_mode.host.selected", Localization.get("more_options.shrink")))
            end
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        elseif buttonIndex == 2 then
            if g_DisableSeaArmy == 1 then
                g_DisableSeaArmy = 0
                exMessageAppendToMessageArea(Localization.get("game_mode.host.canceled", Localization.get("more_options.no_navy")))
            else
                g_DisableSeaArmy = 1
                exMessageAppendToMessageArea(Localization.get("game_mode.host.selected", Localization.get("more_options.no_navy")))
            end
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        elseif buttonIndex == 3 then
            BtnChoiceDialogEventFunc_ShowGameModeDialog(self.PlayerName)
            return
        end
        exMessageAppendToMessageArea(Localization.get("game_mode.error.invalid_button", self.PlayerName, buttonIndex))
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function BtnChoiceDialogEventFunc_ShowDrawModeDialog(playerName)
    local dialogData = {
        DialogId = DRAW_MODE_DIALOG_ID,
        PlayerName = playerName,
        Title = Localization.get("draw_mode.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {
            Localization.get("draw_mode.disabled"),
            Localization.get("draw_mode.original"),
            Localization.get("draw_mode.pure"),
            Localization.get("draw_mode.back"),
        }
        if g_DrawMode >= 0 and g_DrawMode <= 2 then
            self.Choices[g_DrawMode + 1] = self.Choices[g_DrawMode + 1]
                .. Localization.get("game_mode.selected_suffix")
        end
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex >= 1 and buttonIndex <= 3 then
            g_DrawMode = buttonIndex - 1
            g_LuckyCrateMode = 0
            if g_DrawMode ~= 0 then
                g_LuckyCrateMode = 1
            end
            -- 抽卡模式与海克斯符文是两个独立选项：这里只改抽卡，绝不联动 g_HextechCount。
            local selectedDrawModeName = Localization.get("draw_mode.disabled")
            if g_DrawMode == 1 then
                selectedDrawModeName = Localization.get("draw_mode.original")
            elseif g_DrawMode == 2 then
                selectedDrawModeName = Localization.get("draw_mode.pure")
            end
            exMessageAppendToMessageArea(
                Localization.get("game_mode.host.selected", selectedDrawModeName))
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        elseif buttonIndex == 4 then
            BtnChoiceDialogEventFunc_ShowGameModeDialog(self.PlayerName)
            return
        end
        exMessageAppendToMessageArea(Localization.get("game_mode.error.invalid_button", self.PlayerName, buttonIndex))
    end
    dialogData:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialogData)
end

function BtnChoiceDialogEventFunc_ShowHextechModeDialog(playerName)
    local dialogData = {
        DialogId = HEXTECH_MODE_DIALOG_ID,
        PlayerName = playerName,
        Title = Localization.get("hextech.dialog.title"),
        Choices = {},
    }
    dialogData.RefreshData = function(self)
        self.Choices = {
            Localization.get("hextech.option.0"),
            Localization.get("hextech.option.1"),
            Localization.get("hextech.option.2"),
            Localization.get("hextech.option.3"),
            Localization.get("hextech.option.4"),
            Localization.get("hextech.back"),
        }
        if g_HextechCount >= 0 and g_HextechCount <= 4 then
            self.Choices[g_HextechCount + 1] = self.Choices[g_HextechCount + 1]
                .. Localization.get("game_mode.selected_suffix")
        end
    end
    dialogData.OnChoice = function(self, buttonIndex)
        if buttonIndex >= 1 and buttonIndex <= 5 then
            g_HextechCount = buttonIndex - 1
            g_HextechCountManuallySet = true
            local selectedHextechName = Localization.get("hextech.option." .. g_HextechCount)
            exMessageAppendToMessageArea(
                Localization.get("game_mode.host.selected", selectedHextechName))
            self:RefreshData()
            ButtonChoiceDialogManager:ShowDialog(self)
            return
        elseif buttonIndex == 6 then
            BtnChoiceDialogEventFunc_ShowGameModeDialog(self.PlayerName)
            return
        end
        exMessageAppendToMessageArea(Localization.get("game_mode.error.invalid_button", self.PlayerName, buttonIndex))
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
    -- 基础模式
    if g_GameMode == 1 then
        gameModeText = Localization.get("game_mode.standard")
    elseif g_GameMode == 2 then
        gameModeText = Localization.get("game_mode.death")
    elseif g_GameMode == 4 then
        gameModeText = Localization.get("game_mode.level_up")
    end
    -- 括号内并列功能：海克斯符文排最前，缩小/禁海随后（参考缩小模式/禁海的开局播报）
    local featureText = ''
    if g_EnableHextechRune == 1 then
        featureText = Localization.get("game_mode.hextech_name")
    end
    if g_EnableShrinkMode == 1 then
        if featureText ~= '' then
            featureText = featureText .. Localization.get("game_mode.feature_separator")
        end
        featureText = featureText .. Localization.get("game_mode.shrink_name")
    end
    if g_DisableSeaArmy == 1 then
        if featureText ~= '' then
            featureText = featureText .. Localization.get("game_mode.feature_separator")
        end
        featureText = featureText .. Localization.get("game_mode.no_navy_name")
    end
    if featureText ~= '' then
        gameModeText = gameModeText .. Localization.get("game_mode.feature_bracket", featureText)
    end
    -- 抽卡后缀（括号外）
    if g_DrawMode == 1 then
        gameModeText = gameModeText .. Localization.get("game_mode.lucky_crate_suffix")
    elseif g_DrawMode == 2 then
        gameModeText = gameModeText .. Localization.get("game_mode.pure_draw_suffix")
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
    local economicMultiplier = exModeGetCheatMultiplier()
    exAddTextToPublicBoard(format("%s\n%s\n%s", Localization.get("game.start.begin", gameModeText), skillText, Localization.get("game.start.economic_multiplier", economicMultiplier, GetBaseRecycleRate(economicMultiplier) * 100)), 15)
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
        if PureDrawReapplyPlayerQuota ~= nil then
            local firstPlayer = 1
            if pIndex >= 4 then
                firstPlayer = 4
            end
            for i = firstPlayer, firstPlayer + 2, 1 do
                PureDrawReapplyPlayerQuota(i)
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

            local recycleUnitInfo = g_CurrentClickRecycleUnit[playerIndex2]
            local availableCount = GetRecycleUnitCount(playerIndex2, recycleUnitInfo)

            if availableCount > 0 then
                local count = g_RecycleUnitCount[buttonIndex];
                local leftCount = 0
                count, leftCount = RemoveRecycleUnitCount(playerIndex2, recycleUnitInfo, count)
                ExecuteAction('PLAYER_GIVE_MONEY', self.PlayerName, count * recycleUnitInfo.Money * GetRecycleRate(playerIndex2)) ;
                -- 同时也要告诉盟友
                local msg = Localization.get("recycle.message", tostring(playerIndex2), count, recycleUnitInfo.Name, tostring(leftCount));
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
