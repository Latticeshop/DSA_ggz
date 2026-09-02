angel_money = 0
devil_money = 0
devil_surrender = 0
angel_surrender = 0

g_AlliedSuperWeaponBuilt = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
}

g_ProductionBonus_JapanGet = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
}

g_ProductionBonus_SovietGet = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
}

g_ProductionBonus_JapanWeaponEnable = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 1,
    [5] = 1,
    [6] = 1,
}

g_VehicleFilter = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="VEHICLE",
})

g_MoneyBonusTargetFilter = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="VEHICLE INFANTRY HUGE_VEHICLE",
    Exclude="IGNORE_IN_AI_HUNT_TACTIC DEBRIS SHIP"
})

g_CelestialSuperWeapon_Get = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
}

g_CelestialSuperWeapon_CelestialWeaponEnable = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 1,
    [5] = 1,
    [6] = 1,
}

g_angelButtonClickHistory = {}
g_evilButtonClickHistory = {}

g_CelestialEngineerRepairDroneIndex = 1;

g_VehicleInfantryAircraftFilter = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="INFANTRY VEHICLE AIRCRAFT",
})

function onCenterTopBtnClickEvent(playerName, btnIndex)
    ButtonManager:OnClick(playerName, btnIndex)
end

g_AutoSurrender = {
    PlayerInitiallyPresent = { 0, 0, 0, 0, 0, 0 },
    PlayerNowDied = { 0, 0, 0, 0, 0, 0 },
    DidPlayerAutoSurrender = { 0, 0, 0, 0, 0, 0 },
}
function CenterTopBtnFunc_InitializeAutoSurrender()
    for i = 1, 6, 1 do
        local playerName = "Player_" .. i
        -- check if player has at least one structure
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, count = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if count > 0 then
            g_AutoSurrender.PlayerInitiallyPresent[i] = 1
        end
    end
    SchedulerModule.call_every_x_frame(function()
        for i = 1, 6, 1 do
            local playerName = "Player_" .. i
            local previous = SetWorldBuilderThisPlayer(1)
            local structures, count = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
            SetWorldBuilderThisPlayer(previous)
            if count == 0 and g_AutoSurrender.PlayerInitiallyPresent[i] == 1 then
                g_AutoSurrender.PlayerNowDied[i] = 1
                -- 自动发起一次投降
                if g_AutoSurrender.DidPlayerAutoSurrender[i] ~= 1 then
                    g_AutoSurrender.DidPlayerAutoSurrender[i] = 1
                    -- 但假如是游戏即将正常结束那就不投降了
                    -- 检查 PlyrCivilian 和 PlyrCreeps 里是否还有建筑
                    -- 如果没有了说明游戏即将结束了，就不投降了
                    -- 只有在它们都还有建筑的情况下才自动投降
                    local previous2 = SetWorldBuilderThisPlayer(1)
                    local civilianStructures, civilianStructureCount = CopyPlayerRegisteredObjectSet("PlyrCivilian", "STRUCTURES")
                    local creepStructures, creepStructureCount = CopyPlayerRegisteredObjectSet("PlyrCreeps", "STRUCTURES")
                    SetWorldBuilderThisPlayer(previous2)
                    if civilianStructureCount > 0 and creepStructureCount > 0 then
                        RequestSurrender(i, true)
                    end
                end
            end
        end
    end, 15, nil)
end

function RequestSurrender(playerIndex, isAutoSurrender)
    local side, sideName, sideAiPlayer, sidePlayerIndexOffset = "devil", Localization.get("side.devil"), "PlyrCivilian", 0
    if playerIndex >= 4 then
        side, sideName, sideAiPlayer, sidePlayerIndexOffset = "angel", Localization.get("side.angel"), "PlyrCreeps", 3
    end
    local globalVariableName = format("%s_surrender", side)
    setglobal(globalVariableName, 0)
    exEnableWBScript(format("%s/%s_surrender", sideAiPlayer, side))
    exAddTextToPublicBoard(Localization.get("surrender.public.start", sideName, playerIndex), 10)
    local voteText = Localization.get("surrender.vote_text")
    for i = 1, 3, 1 do
        local p = sidePlayerIndexOffset + i
        local targetPlayerName = format("Player_%d", p)
        exHideCustomBtnChoiceDialogForPlayer(targetPlayerName)
        exHideLongTextDialogForPlayer(targetPlayerName)
        exShowLongTextDialogForPlayer(targetPlayerName, 200 + p, voteText, Localization.get("surrender.choice.surrender"), Localization.get("surrender.choice.pass"), Localization.get("surrender.choice.fight"))
    end
    if isAutoSurrender then
        exAddTextToPublicBoard(Localization.get("surrender.public.auto", sideName, playerIndex), 30)
        setglobal(globalVariableName, getglobal(globalVariableName) + 1)
    end
    return true
end

function CenterTopBtnFunc_CreateInitialButtons(playerIndex)
    local playerName = "Player_" .. playerIndex
    local buttons = {}
    local preselectedPlayerSkillKind = g_PreselectedSkillIndices[playerIndex]
    if preselectedPlayerSkillKind ~= nil then
        CenterTopBtnFunc_CreatePlayerSkillButtons(playerIndex, preselectedPlayerSkillKind)
    else
        buttons[1] = CreateButton({
            PlayerName = playerName,
            PlayerIndex = playerIndex,
            ButtonIndex = 1,
            IconId = 'Button_Toggle_Power',
            Title = Localization.get("button.choose_skill.title"),
            Description = Localization.get("button.choose_skill.description"),
            IsEnabled = true,
            IsHighlighted = true,
            OnClick = function(self)
                BtnChoiceDialogEventFunc_ShowPlayerChooseSkillDialog(self.PlayerName)
                return true
            end
        })
    end
    if g_PlayerSide[playerIndex] == 1 then
        buttons[3] = CreateChronosphereButton(playerIndex)
    elseif g_PlayerSide[playerIndex] == 3 then
        buttons[3] = CreateJapanShieldButton(playerIndex)
    elseif g_PlayerSide[playerIndex] == 4 then
        buttons[3] = CreateCelestialMoraleButton(playerIndex)
    end
    buttons[4] = CreateButton({
        PlayerName = playerName,
        PlayerIndex = playerIndex,
        ButtonIndex = 4,
        IconId = 'Button_PlayerPower_FreeTrade',
        Title = Localization.get("button.market.title"),
        Description = Localization.get("button.market.description"),
        IsEnabled = true,
        OnClick = function(self)
            BtnChoiceDialogEventFunc_ShowMarketDialog(self.PlayerIndex)
            return true
        end
    })
    buttons[6] = CreateButton({
        PlayerName = playerName,
        PlayerIndex = playerIndex,
        ButtonIndex = 6,
        IconId = g_HuoHuo_ImageId,
        Title = Localization.get("button.surrender.title"),
        Description = Localization.get("button.surrender.description"),
        MaxUseCount = 1,
        SharedCooldownId = 'surrender',
        SharedCooldownSeconds = 3,
        IsEnabled = true,
        OnClick = function(self)
            RequestSurrender(self.PlayerIndex, false)
            return true
        end
    })
    
    for i = 1, 6, 1 do
        local button = buttons[i]
        if button then
            ButtonManager:SetButton(button)
        end
    end
end

function CenterTopBtnFunc_CreatePlayerSkillButtons(playerIndex, kind)
    local buttons = {}
    if kind == 1 then
        buttons[1] = CreateDestructionButton(playerIndex)
        buttons[2] = CreateDamoclesSwordButton(playerIndex)
    elseif kind == 2 then
        buttons[1] = CreateIronCurtainButton(playerIndex)
        buttons[2] = CreateTimeStopButton(playerIndex)
    elseif kind == 3 then
        buttons[1] = CreateDragonshipButton(playerIndex)
        buttons[2] = CreateAirMarshalButton(playerIndex)
    elseif kind == 4 then
        buttons[1] = CreateSpawnArmyImmediatelyButton(playerIndex)
        buttons[2] = CreateNanoMaintainHiveButton(playerIndex)
    elseif kind == 5 then
        buttons[1] = CreateRepeatEnemySpecialPowerButton(playerIndex)
        buttons[2] = CreateRepeatSelfSpecialPowerButton(playerIndex)
    else
        exMessageAppendToMessageArea(Localization.get("error.invalid_kind"))
        return
    end
    for j = 1, 2 do
        if playerIndex <= 3 then
            for i = 1, 3 do
                exAddTextToPublicBoardForPlayer("Player_" .. i, Localization.get("button.skill_selected", playerIndex, buttons[j].Title), 8)
            end
        else
            for i = 4, 6 do
                exAddTextToPublicBoardForPlayer("Player_" .. i, Localization.get("button.skill_selected", playerIndex, buttons[j].Title), 8)
            end
        end
    end

    ButtonManager:SetButton(buttons[1])
    ButtonManager:SetButton(buttons[2])
end

function CenterTopBtnFunc_UpdatePlayer3rdButton(playerIndex)
    local playerName = "Player_" .. playerIndex
    local button = nil
    if g_ProductionBonus_JapanGet[playerIndex] == 1 then
        button = CreateJapanShieldButton(playerIndex)
    elseif g_CelestialSuperWeapon_Get[playerIndex] == 1 then
        button = CreateCelestialMoraleButton(playerIndex)
    elseif g_AlliedSuperWeaponBuilt[playerIndex] == 1 then
        button = CreateChronosphereButton(playerIndex)
    end
    if button then
        button.Description = button.UnlockedDescription
        button.IsLocked = false
        button.IsEnabled = true
        button:FormatText()
        ButtonManager:SetButton(button)
    end
end

function CreateDestructionButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'Button_SovietTeslaMissile',
        Title = Localization.get("button.destruction.title"),
        Description = Localization.get("button.destruction.description"),
        IsEnabled = true,
        MaxUseCount = 1,
        SharedCooldownId = "destruction",
        SharedCooldownSeconds = 5,
        OnClick = function(self)
            return RequestDestruction(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateDamoclesSwordButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 2,
        IconId = 'Button_CelestialPantaOrbitalStrike',
        Title = Localization.get("button.damocles.title"),
        Description = Localization.get("button.damocles.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 10,
        SharedCooldownId = "damoclessword",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestDamoclesSword(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateIronCurtainButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'Button_PlayerPower_IronCurtain',
        Title = Localization.get("button.iron_curtain.title"),
        Description = Localization.get("button.iron_curtain.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 10,
        SharedCooldownId = "ironcurtain",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestIronCurtain(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateTimeStopButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 2,
        IconId = 'AUA_Timebelt',
        Title = Localization.get("button.time_stop.title"),
        Description = Localization.get("button.time_stop.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 10,
        SharedCooldownId = "timestop",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestTimeStop(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateDragonshipButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'CEL_DragonShipLand',
        Title = Localization.get("button.dragonship.title"),
        Description = Localization.get("button.dragonship.description"),
        UnlockedDescription = Localization.get("button.dragonship.unlocked_description"),
        IsLocked = true,
        MaxUseCount = 2,
        CooldownRounds = 1,
        SharedCooldownId = "dragonship",
        SharedCooldownSeconds = 5,
        DragonshipNumber = 1,
        OnClick = function(self)
            if RequestDragonShip(self.PlayerIndex, self.DragonshipNumber) then
                self.DragonshipNumber = 2
                return true
            end
            return nil
        end,
    }
    local round = exCounterGetByName("lvc")
    if round >= 5 then
        buttonData.IsLocked = false
        buttonData.IsEnabled = true
        buttonData.Description = buttonData.UnlockedDescription
    else
        RoundLuaManager.DelayCallOnRoundBegin(function(self)
            self.IsLocked = false
            self.IsEnabled = true
            self.Description = self.UnlockedDescription
            self:FormatText()
            ButtonManager:SetButton(self)
        end, { buttonData }, 5 - round)
    end
    return CreateButton(buttonData)
end

function CreateAirMarshalButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 2,
        IconId = 'Button_SovietInterceptorAircraft',
        Title = Localization.get("button.air_marshal.title"),
        Description = Localization.get("button.air_marshal.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 10,
        SharedCooldownId = "airmarshal",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestAirMarshal(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateRepeatSelfSpecialPowerButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 2,
        IconId = 'CelestialPowerPlantDetection',
        Title = Localization.get("center_top.copy_our_skill.title"),
        Description = Localization.get("center_top.copy_our_skill.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 30,
        SharedCooldownId = "repeatselfspecialpower",
        SharedCooldownSeconds = 10,
        DragonshipNumber = 1,
        OnClick = function(self)
            return RequestRepeatSelfSpecialPower(self.PlayerIndex, self)
        end,
    }
    return CreateButton(buttonData)
end

function CreateRepeatEnemySpecialPowerButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'CelestialSonarOn',
        Title = Localization.get("center_top.copy_enemy_skill.title"),
        Description = Localization.get("center_top.copy_enemy_skill.description"),
        IsEnabled = true,
        MaxUseCount = 1,
        CooldownSeconds = 30,
        SharedCooldownId = "repeatenemyspecialpower",
        SharedCooldownSeconds = 10,
        DragonshipNumber = 1,
        OnClick = function(self)
            return RequestRepeatEnemySpecialPower(self.PlayerIndex, self)
        end,
    }
    return CreateButton(buttonData)
end

--function CreateBuyOverButton(playerIndex)
--    local buttonData = {
--        PlayerName = "Player_" .. playerIndex,
--        PlayerIndex = playerIndex,
--        ButtonIndex = 1,
--        IconId = 'Button_AlliedInfiltrationInfantry_on',
--        Title = '策反',
--        Description = '策反中间区域附近的陆军和空军',
--        IsEnabled = true,
--        MaxUseCount = 1,
--        SharedCooldownId = "buyover",
--        SharedCooldownSeconds = 10,
--        OnClick = function(self)
--            return RequestBuyOver(self.PlayerIndex)
--        end,
--    }
--    return CreateButton(buttonData)
--end

function CreateNanoMaintainHiveButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 2,
        IconId = 'Button_JapanNanoMaintainHive',
        Title = Localization.get("center_top.nano_repair.title"),
        Description = Localization.get("center_top.nano_repair.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 10,
        SharedCooldownId = "namomaintainhive",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestNanoMaintainHive(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

-- 立即再次生成一次军队
function CreateSpawnArmyImmediatelyButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'Button_JapanKamikazeTeammate',
        Title = Localization.get("center_top.reinforce_army.title"),
        Description = Localization.get("center_top.reinforce_army.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 70,
        SharedCooldownId = "SpawnArmyImmediately",
        SharedCooldownSeconds = 15,
        OnClick = function(self)
            return RequestSpawnArmyImmediately(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateCashBonusButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'AUA_Bribe',
        Title = Localization.get("center_top.kill_reward.title"),
        Description = Localization.get("center_top.kill_reward.description"),
        IsEnabled = true,
        MaxUseCount = 1,
        CooldownSeconds = 70,
        SharedCooldownId = "cashbonus",
        SharedCooldownSeconds = 70,
        OnClick = function(self)
            return RequestCashBonus(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

function CreateChronosphereButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 3,
        IconId = 'AUA_Aegis_Shield',
        Title = Localization.get("center_top.temporal_raid.title"),
        Description = Localization.get("center_top.temporal_raid.description"),
        UnlockedDescription = Localization.get("center_top.temporal_raid.unlocked_description"),
        IsLocked = true,
        MaxUseCount = nil, -- 没有限制
        CooldownRounds = 3,
        SharedCooldownId = "alliedsuperweapon",
        SharedCooldownSeconds = 2,
        OnClick = function(self)
            return RequestChronosphere(self.PlayerIndex)
        end
    }
    return CreateButton(buttonData)
end

function CreateJapanShieldButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 3,
        IconId = 'Button_PlayerPower_PointDefenseDrones',
        Title = Localization.get("center_top.japan_shield.title"),
        Description = Localization.get("center_top.japan_shield.description"),
        UnlockedDescription = Localization.get("center_top.japan_shield.unlocked_description"),
        IsLocked = true,
        MaxUseCount = nil, -- 没有限制
        CooldownSeconds = 200,
        SharedCooldownId = "japanshield",
        SharedCooldownSeconds = 5,
        OnClick = function(self)
            return RequestJapanShield(self.PlayerIndex)
        end
    }
    return CreateButton(buttonData)
end

function CreateCelestialMoraleButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 3,
        IconId = 'CelestialLightningTroop_Lv3',
        Title = Localization.get("center_top.morale_boost.title"),
        Description = Localization.get("center_top.morale_boost.description"),
        UnlockedDescription = Localization.get("center_top.morale_boost.unlocked_description"),
        IsLocked = true,
        MaxUseCount = nil, -- 没有限制
        CooldownSeconds = 220,
        SharedCooldownId = "celestialmorale",
        SharedCooldownSeconds = 5,
        OnClick = function(self)
            return RequestCelestialMorale(self.PlayerIndex)
        end
    }
    return CreateButton(buttonData)
end

function RequestDestruction(playerIndex)
    local sideName = Localization.get("side.devil")
    local sideScript = "KW"
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideScript = "KB"
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.local_destruction", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "A01_CoastalGun_ImpactExplosion")
    exEnableWBScript(sideScript)
    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestDestruction)
    else
        tinsert(g_angelButtonClickHistory, RequestDestruction)
    end
    return true
end

function RequestBuyOver(playerIndex)
    local sideName = Localization.get("side.devil")
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.bribe", sideName))
    --ExecuteAction("PLAY_SOUND_EFFECT", "A01_CoastalGun_ImpactExplosion")

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestDestruction)
    else
        tinsert(g_angelButtonClickHistory, RequestDestruction)
    end
    return true
end

function RequestDamoclesSword(playerIndex)
    local sideName = Localization.get("side.devil")
    local sideScript = "devil_nemesisplay"
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideScript = "angel_nemesisplay"
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.damocles_struck", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "CelestialEnergyGatling_Select")
    exEnableWBScript(sideScript)
    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestDamoclesSword)
    else
        tinsert(g_angelButtonClickHistory, RequestDamoclesSword)
    end
    return true
end

function RequestIronCurtain(playerIndex)
    local sideName = Localization.get("side.devil")
    local referenceObject = T74
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        referenceObject = T84
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.iron_curtain_speech", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "SOV_IronCurtain_Cast")
    local units, count = ObjectFindObjects(referenceObject, nil, FilterALLUNIT)
    for i = 1, count, 1 do
        ObjectLoadAttributeModifier(units[i], "AttributeModifier_IronCurtain", 196)
    end
    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestIronCurtain)
    else
        tinsert(g_angelButtonClickHistory, RequestIronCurtain)
    end
    return true
end

function RequestTimeStop(playerIndex)
    local sideName = Localization.get("side.devil")
    local sideScript = "devilstop"
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideScript = "angelstop"
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.time_stop", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "ALL_Chronosphere_Off")
    exEnableWBScript(sideScript)
    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestTimeStop)
    else
        tinsert(g_angelButtonClickHistory, RequestTimeStop)
    end
    return true
end

function RequestDragonShip(playerIndex, count)
    if count ~=1 and count ~= 2 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.dragonship_invalid_number"))
        return nil
    end
    local cutMCV = 5
    local counterValue = exCounterGetByName("lvc");
    if counterValue < cutMCV then
        exMessageAppendToMessageArea(Localization.get("center_top.error.dragonship_round_insufficient"))
        return nil
    end

    local sideName = Localization.get("side.devil")
    local sideAIPlayer = "PlyrCivilian"
    -- local mcvHealthScript = "MCVhealthD"
    local dragonshipAngle = "0"
    local waypoint = "TD7"
    local tower = T74
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideAIPlayer = "PlyrCreeps"
        -- mcvHealthScript = "MCVhealthA"
        dragonshipAngle = "180"
        waypoint = "TD8"
        tower = T84
    end
    local aiTeamName = sideAIPlayer .. '/ATTACK'

    exMessageAppendToMessageArea(Localization.get("center_top.used.dragon_core_called", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "CEL_DragonShip_VoicePack")
    local pos = exWaypointGetPos(waypoint)
    local x1 = pos[1];
    local y1 = pos[2];
    local z1 = pos[3];
    local positions = {
        { X = x1, Y = y1, Z = z1 },
    }
    if count == 2 then
        positions[1].Y = y1 - 150
        positions[2] = { X = x1, Y = y1 + 100, Z = z1 }
    end

    for j = 1, count, 1 do
        ExecuteAction("CREATE_OBJECT", 'CelestialMCV', aiTeamName, positions[j], dragonshipAngle)
    end
    -- exEnableWBScript(mcvHealthScript)
    local round = exCounterGetByName("lvc")
    if round > 18 then
        round = 18
    end
    local maxHealth = 8000 + max(round - 10, 0) * 3000
    local dragonships, dragonshipCount = ObjectFindObjects(tower, nil, CelestialMCV)
    for i = 1, count do
        local index = dragonshipCount - count + i
        local dragonship = dragonships[index]
        local id = ObjectGetId(dragonship)
        local str = "UnitStrRef" .. id
        local previousHp = ObjectGetCurrentHealth(dragonship)
        ExecuteAction("SET_UNIT_REFERENCE", str, dragonship)
        ExecuteAction("NAMED_SET_MAX_HEALTH", str, maxHealth, 'true')
        local currentHp = ObjectGetCurrentHealth(dragonship)
        exMessageAppendToMessageArea(Localization.get("center_top.dragonship.hp_change", id, previousHp, currentHp))
    end

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestDragonShip)
    else
        tinsert(g_angelButtonClickHistory, RequestDragonShip)
    end
    return true
end

function RequestAirMarshal(playerIndex)
    local sideName = Localization.get("side.devil")
    local sideScript = "devil_air"
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideScript = "angel_air"
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.air_marshal", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "SOV_SukhoiInterceptor_VoiceAttack")
    ExecuteAction("PLAY_SOUND_EFFECT", "CEL_NukeIncoming")
    exEnableWBScript(sideScript)

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestAirMarshal)
    else
        tinsert(g_angelButtonClickHistory, RequestAirMarshal)
    end
    return true
end

function RequestNanoMaintainHive(playerIndex)
    local sideName = Localization.get("side.devil")
    local sideAIPlayer = "PlyrCivilian"
    local tower = T74
    local seaTowers = { "T71F", "T72F", "T73F" }
    local positions = { X = 3000, Y = 3104, Z = 210 }
    local position2 = {
        { X = 3200, Y = 3200, Z = 210 },
        { X = 3200, Y = 3000, Z = 210 },
        { X = 3200, Y = 3300, Z = 210 },
        { X = 3200, Y = 2900, Z = 210 },
    }
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideAIPlayer = "PlyrCreeps"
        tower = T84
        seaTowers = { "T81F", "T82F", "T83F" }
        positions = { X = 4030, Y = 3104, Z = 210 }
        position2 = {
            { X = 3830, Y = 3200, Z = 210 },
            { X = 3830, Y = 3000, Z = 210 },
            { X = 3830, Y = 3300, Z = 210 },
            { X = 3830, Y = 2900, Z = 210 },
        }
    end

    exMessageAppendToMessageArea(Localization.get("center_top.used.nano_repair", sideName))
    -- 给海塔回血 15%
    for i = 1, getn(seaTowers), 1 do
        local seaTower = GetObjectByScriptName(seaTowers[i])
        if ObjectIsAlive(seaTower) then
            local currentHp = ObjectGetCurrentHealth(seaTower)
            -- 塔的血量被改过因此不适用 ObjectGetInitialHealth
            local maxHp = exObjectGetMaxHealth(ObjectGetId(seaTower))
            local healAmount = maxHp * 0.15
            ExecuteAction("NAMED_DAMAGE", seaTower, -healAmount)
        end
    end

    ExecuteAction("CREATE_OBJECT", 'JapanNanoMaintainHive', sideAIPlayer .. "/team" .. sideAIPlayer, positions, 0)
    for j = 1, 4, 1 do
        g_CelestialEngineerRepairDroneIndex = g_CelestialEngineerRepairDroneIndex + 1;
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "CelestialEngineerRepairDroneLv3" .. tostring(g_CelestialEngineerRepairDroneIndex),
                "CelestialEngineerRepairDroneLv3",
                sideAIPlayer .. "/team" .. sideAIPlayer, position2[j], 0)
        local object = GetObjectByScriptName("CelestialEngineerRepairDroneLv3" .. tostring(g_CelestialEngineerRepairDroneIndex))
        SchedulerModule.delay_call(function(objectId)
            ExecuteAction("NAMED_DELETE", GetObjectById(objectId))
        end, 450, {ObjectGetId(object)})
    end

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestNanoMaintainHive)
    else
        tinsert(g_angelButtonClickHistory, RequestNanoMaintainHive)
    end
    return true
end

function RequestRepeatSelfSpecialPower(playerIndex, self)
    local sideName = Localization.get("side.devil")
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
    end
    local destPowerFunc = nil;
    local history = g_evilButtonClickHistory;
    if playerIndex >= 4 then
        history = g_angelButtonClickHistory;
    end
    if getn(history) == 0 then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, Localization.get("center_top.error.no_skill_to_copy"), 8)
        return false;
    end
    for i = getn(history), 1, -1 do
        if history[i] ~= RequestRepeatSelfSpecialPower then
            destPowerFunc = history[i];
            break;
        end
    end

    if destPowerFunc ~= nil then
        exMessageAppendToMessageArea(Localization.get("center_top.used.copy_our_skill", sideName))
        if destPowerFunc == RequestDragonShip then
            if RequestDragonShip(self.PlayerIndex, self.DragonshipNumber) then
                self.DragonshipNumber = 2
                return true
            end
            return nil
        else
            return destPowerFunc(playerIndex)
        end

    else
                        exAddTextToPublicBoardForPlayer("Player_" .. i, Localization.get("center_top.error.no_suitable_skill"), 8)
        return false;
    end

end

function RequestRepeatEnemySpecialPower(playerIndex, self)
    local sideName = Localization.get("side.devil")
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
    end
    local destPowerFunc = nil;
    local history = g_angelButtonClickHistory;
    if playerIndex >= 4 then
        history = g_evilButtonClickHistory;
    end
    if getn(history) == 0 then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, Localization.get("center_top.error.enemy_no_skill_to_copy"), 8)
        return false;
    end
    for i = getn(history), 1, -1 do
        if history[i] ~= RequestRepeatSelfSpecialPower then
            destPowerFunc = history[i];
            break;
        end
    end

    if destPowerFunc ~= nil then
        exMessageAppendToMessageArea(Localization.get("center_top.used.copy_enemy_skill", sideName))
        if destPowerFunc == RequestDragonShip then
            if RequestDragonShip(self.PlayerIndex, self.DragonshipNumber) then
                self.DragonshipNumber = 2
                return true
            end
            return nil
        else
            return destPowerFunc(playerIndex)
        end

    else
        exAddTextToPublicBoardForPlayer("Player_" .. i, Localization.get("center_top.error.no_suitable_skill"), 8)
        return false;
    end

end

function RequestSpawnArmyImmediately(playerIndex)
    local sideName = Localization.get("side.devil")
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.reinforce_army", sideName))
    if playerIndex <= 3 then
        SchedulerModule.delay_call(function()
            UNITSPST_left (1,step1,INFANTSP,INFANTTEAM,INFANTATTACK,INFANTSPCH)
            UNITSPST_left (step1+1,step2,LIGHTVEHSP,LIGHTVEHTEAM,LIGHTVEHATTACK,LIGHTVEHSPCH)
            UNITSPST_left (step2+1,step3,HEAVYVEHSP,HEAVYVEHTEAM,HEAVYVEHATTACK,HEAVYVEHSPCH)
            UNITSPAIRST_left (step4+1,step5,INFANTSP,AIRTEAM,AIRATTACK,INFANTSPCH)
            SpawnGigaFortressAir_left()
            SpawnLandUnit_left()

            exEnableWBScript('SHIPNOCOACT')
            exEnableWBScript('PlyrCivilian/attackHEAVYVEHVEH__7')
            exEnableWBScript('PlyrCivilian/attackINFANT__7')
            exEnableWBScript('PlyrCivilian/attackLIGHTVEH__7')
            exEnableWBScript('BUFFACTONCE')
            exEnableWBScript('ShrinkMode_Trigger')

            UNITSPAIRST_left (step3+1,step35,LIGHTVEHSP,AIRTEAM,AIRATTACK,LIGHTVEHSPCH)
            UNITSPST_left (step5+1,step6,LIGHTVEHSP,LIGHTVEHTEAM,LIGHTVEHATTACK,LIGHTVEHSPCH)
            if g_DisableSeaArmy == 0 then
                SpawnSeaWingFromSea_left()
            else
                SpawnNoNavyAmphibiousLand_left()
                SpawnNoNavySeaWingAir_left()
            end
            exEnableWBScript('PlyrCivilian/attackAIR__7')
            exEnableWBScript('BUFFACTONCE__AIR')
        end, 5)
    else
        SchedulerModule.delay_call(function()
            UNITSPST_right (1,step1,INFANTSP,INFANTTEAM,INFANTATTACK,INFANTSPCH)
            UNITSPST_right (step1+1,step2,LIGHTVEHSP,LIGHTVEHTEAM,LIGHTVEHATTACK,LIGHTVEHSPCH)
            UNITSPST_right (step2+1,step3,HEAVYVEHSP,HEAVYVEHTEAM,HEAVYVEHATTACK,HEAVYVEHSPCH)
            UNITSPAIRST_right (step4+1,step5,INFANTSP,AIRTEAM,AIRATTACK,INFANTSPCH)
            SpawnGigaFortressAir_right()
            SpawnLandUnit_right()

            exEnableWBScript('SHIPNOCOACT')
            exEnableWBScript('PlyrCreeps/attackHEAVYVEHVEH__8')
            exEnableWBScript('PlyrCreeps/attackINFANT__8')
            exEnableWBScript('PlyrCreeps/attackLIGHTVEH__8')
            exEnableWBScript('BUFFACTONCE')
            exEnableWBScript('ShrinkMode_Trigger')

            UNITSPAIRST_right (step3+1,step35,LIGHTVEHSP,AIRTEAM,AIRATTACK,LIGHTVEHSPCH)
            UNITSPST_right (step5+1,step6,LIGHTVEHSP,LIGHTVEHTEAM,LIGHTVEHATTACK,LIGHTVEHSPCH)
            if g_DisableSeaArmy == 0 then
                SpawnSeaWingFromSea_right()
            else
                SpawnNoNavyAmphibiousLand_right()
                SpawnNoNavySeaWingAir_right()
            end
            exEnableWBScript('PlyrCreeps/attackAIR__8')
            exEnableWBScript('BUFFACTONCE__AIR')
        end, 5)
    end

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestSpawnArmyImmediately)
    else
        tinsert(g_angelButtonClickHistory, RequestSpawnArmyImmediately)
    end
    return true
end

function RequestChronosphere(playerIndex)
    if g_AlliedSuperWeaponBuilt[playerIndex] ~= 1 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.player_not_built_chronosphere", playerIndex))
        return false
    end
    local sideName = Localization.get("side.devil")
    local sideScript = "PlyrCivilian/devilASuper"
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        sideScript = "PlyrCreeps/angelASuper"
    end
    exMessageAppendToMessageArea(Localization.get("center_top.used.temporal_raid", sideName))
    ExecuteAction("PLAY_SOUND_EFFECT", "ALL_Chronosphere_Die")
    exEnableWBScript(sideScript)
    return true
end

function RequestJapanShield(playerIndex)
    if g_ProductionBonus_JapanGet[playerIndex] ~= 1 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.player_not_emp_mech_protocol", playerIndex))
        return false
    end
    local sideName = Localization.get("side.devil")
    local filterObj = T74
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        filterObj = T84
    end
    
    exMessageAppendToMessageArea(Localization.get("center_top.used.emp_nano_shield", sideName, playerIndex))
    local matchedObjects, count = ObjectFindObjects(filterObj, nil, g_VehicleFilter)
    if count == 0 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.no_tank_found"))
        return false
    end
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        local x, y, z = ObjectGetPosition(current)
        ObjectCreateAndFireTempWeaponToTarget(filterObj, "PlayerPowerPointDefenseDronesWeapon_Individual", {
            X = x, Y = y, Z = z
        }, current)
    end

    return true
end

function RequestCashBonus(playerIndex)
    local sideName = Localization.get("side.devil")
    local filterObj = T84
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        filterObj = T74
    end

    exMessageAppendToMessageArea(Localization.get("center_top.used.kill_reward", sideName))
    local matchedObjects, count = ObjectFindObjects(filterObj, nil, g_MoneyBonusTargetFilter)
    if count == 0 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.no_land_unit_found"))
        return false
    end
    local fireObject = GetObjectByScriptName("wan" .. tostring(playerIndex))
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        local x, y, z = ObjectGetPosition(current)
        ObjectCreateAndFireTempWeaponToTarget(fireObject, "PlayerPowerProductionKickbacksWeapon_Individual", {
            X = x, Y = y, Z = z
        }, current)
    end

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestCashBonus)
    else
        tinsert(g_angelButtonClickHistory, RequestCashBonus)
    end
    return true
end

function RequestCelestialMorale(playerIndex)
    if g_CelestialSuperWeapon_Get[playerIndex] ~= 1 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.player_not_obtained_morale", playerIndex))
        return false
    end
    local sideName = Localization.get("side.devil")
    local filterObj = T74
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
        filterObj = T84
    end
    
    exMessageAppendToMessageArea(Localization.get("center_top.used.global_morale", sideName, playerIndex))
    local matchedObjects, count = ObjectFindObjects(filterObj, nil, g_VehicleInfantryAircraftFilter)
    if count == 0 then
        exMessageAppendToMessageArea(Localization.get("center_top.error.no_unit_found"))
        return false
    end
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        ObjectLoadAttributeModifier(current, "AttributeMod_lightningTroop_Lv1", 270)
    end

    return true
end

local huohuo = {
    size = {126, 126},
    base64 = [[
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
]]
}
local textureId = exTextureCreateFromBase64(huohuo.base64, "DXT5")
-- 定义自定义贴图
g_HuoHuo_ImageId = exPackedTextureImageCreate({
    Texture = textureId,
    -- 贴图在纹理中的位置
    CoordsX = 0, CoordsY = 0,
    -- 贴图的尺寸
    DimensionsX = huohuo.size[1], DimensionsY = huohuo.size[2],
    -- 源纹理的尺寸
    TextureDimensionsX = huohuo.size[1], TextureDimensionsY = huohuo.size[2],
    -- 旋转角度
    Rotated = 0
})
