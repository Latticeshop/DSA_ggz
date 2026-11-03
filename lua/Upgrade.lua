Airpower = FastHash("PlayerTech_Allied_AirPower")
HighTechnology = FastHash("PlayerTech_Allied_HighTechnology")
CrushPuppies = FastHash('PlayerTech_Soviet_CrushPuppies')
TerrorDroneEggs = FastHash('PlayerTech_Soviet_TerrorDroneEggs')
NavalPower = FastHash('PlayerTech_Japan_NavalPower')
EnhancedKamikaze = FastHash('PlayerTech_Japan_EnhancedKamikaze')
AdvancedMissilePacks = FastHash('PlayerTech_Japan_AdvancedMissilePacks')
ElectromagneticGun = FastHash('PlayerTech_Celestial_ElectromagneticGun')
ProductionBonus = FastHash('PlayerTech_ProductionBonus_Allies')
PlayerTech_Celestial_PowerSealOffId = FastHash('PlayerTech_Celestial_PowerSealOff')
PlayerTech_ProductionBonus_SovietId = FastHash('PlayerTech_ProductionBonus_Soviet')
PlayerTech_ProductionBonus_JapanId = FastHash('PlayerTech_ProductionBonus_Japan')
exTogglePlayerGetTechEvent(1)

PlayerSideName = Localization.map("player_side_name")
Localization.on_language_changed(function()
    PlayerSideName = Localization.map("player_side_name")
end)

PlayerIndex = {
    ["Player_1"] = 1,
    ["Player_2"] = 2,
    ["Player_3"] = 3,
    ["Player_4"] = 4,
    ["Player_5"] = 5,
    ["Player_6"] = 6,
    ["Player_7"] = 7,
    ["Player_8"] = 8,
}

-- 开局自动分队：座位号 → 该席所属阵营的 AI 队名。44 图出生点是连续两段，
-- 下沿 Player_1~4 归恶魔 PlyrCivilian，上沿 Player_5~8 归天使 PlyrCreeps。
PlayerToComputer = {
    ["Player_1"] = "PlyrCivilian",
    ["Player_2"] = "PlyrCivilian",
    ["Player_3"] = "PlyrCivilian",
    ["Player_4"] = "PlyrCreeps",
    ["Player_5"] = "PlyrCreeps",
    ["Player_6"] = "PlyrCreeps",
    ["Player_7"] = "PlyrCreeps",
    ["Player_8"] = "PlyrCivilian",
}

function onPlayerGetTechEvent(playerName, techInstanceId)
    local sideName = PlayerSideName[playerName];
    local previous = SetWorldBuilderThisPlayer(1)
    local i = PlayerIndex[playerName];
    local computerPlayer = PlayerToComputer[playerName]
    if techInstanceId == Airpower then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_AlliedAirPower")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.airpower", sideName, i))
    elseif techInstanceId == HighTechnology then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_AlliedHighTechnology")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.high_technology", sideName, i))
    elseif techInstanceId == CrushPuppies then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_SovietCrushPuppiesPower")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.crush_puppies", sideName, i))
    elseif techInstanceId == TerrorDroneEggs then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_SovietTerrorDroneEggs")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.terror_drone_eggs", sideName, i))
    elseif techInstanceId == NavalPower then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_JapanNavalPower")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.naval_power", sideName, i))
    elseif techInstanceId == EnhancedKamikaze then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_JapanEnhancedKamikaze")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.enhanced_kamikaze", sideName, i))
    elseif techInstanceId == AdvancedMissilePacks then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_JapanAdvancedMissilePacks")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.advanced_missile_packs", sideName, i))
    elseif techInstanceId == ElectromagneticGun then
        ExecuteAction("GIVE_PLAYER_UPGRADE", computerPlayer, "Upgrade_CelestialEMG")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.electromagnetic_gun", sideName, i))
    elseif techInstanceId == PlayerTech_Celestial_PowerSealOffId then
        local round = exCounterGetByName("lvc")
        if round >= 3 then
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialBattery", 1)
            exMessageAppendToMessageArea(Localization.get("upgrade.tech.power_seal_off_now", sideName, i))
        else
            SchedulerModule.call_every_x_frame(function(pName)
                local round1 = exCounterGetByName("lvc")
                if round1 >= 3 then
                    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", pName, "CelestialBattery", 1)
                end
            end, 30, nil, {playerName})
            exMessageAppendToMessageArea(Localization.get("upgrade.tech.power_seal_off_later", sideName, i))
        end
    elseif techInstanceId == ProductionBonus then
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", 'PlayerA_' .. i, 'AlliedWallPiece', computerPlayer .. '/team' .. computerPlayer, "jiaoyidian")
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.production_bonus_allied", sideName, i))
    elseif techInstanceId == PlayerTech_ProductionBonus_JapanId then
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.production_bonus_japan", sideName, i));
        g_ProductionBonus_JapanGet[g_PlayerNameToIndex[playerName]] = 1
        CenterTopBtnFunc_UpdatePlayer3rdButton(i)
    elseif techInstanceId == PlayerTech_ProductionBonus_SovietId then
        exMessageAppendToMessageArea(Localization.get("upgrade.tech.production_bonus_soviet", sideName, i));
        g_ProductionBonus_SovietGet[g_PlayerNameToIndex[playerName]] = 1
    end
    SetWorldBuilderThisPlayer(previous)

end

-- Upgrade completed notifications.
-- Localization keys are derived from the upgrade name: upgrade.<UpgradeName>
local upgrades = {
    "Upgrade_AlliedMissileIntercept",
    "Upgrade_AlliedPrismTankReduceSpeed",
    "Upgrade_AlliedAircraftAutoDivideBombs",
    "Upgrade_AlliedAdvancedPrismEquipment",
    "Upgrade_AlliedCommandControlSystem",
    "Upgrade_AlliedAircraftCarrierDrone",

    "Upgrade_SovietMissileIntercept",
    "Upgrade_SovietCompositeArmor",
    "Upgrade_SovietImprovedTeslaCoil",
    "Upgrade_SovietMultiModeGuidance",

    "Upgrade_JapanSubmarineAttack",
    "Upgrade_JapanMechaRush",
    "Upgrade_JapanNanoTransmissionStructure",
    "Upgrade_JapanNanoSustainingForceField",

    "Upgrade_CelestialSpeedUpdate",
    "Upgrade_CelestialSupplyElectricitySystem",
    "Upgrade_CelestialAuxiliaryAimingSystem",

    "Upgrade_CelestialLodestarDevice",
    "Upgrade_JapanIntelligentAmmunition",
    "Upgrade_SovietGloriousArmedForce",

    "Upgrade_AlliedCryoWeaponArray",
    "Upgrade_SovietAdvancedTeslaCoil",
}
RANK3_NAME = "Upgrade_CelestialTech_RANK3"
RANK3_ID = FastHash(RANK3_NAME)

-- lookup: id -> {name, msg}
local upgradeLookup = {}
-- build lookup + register events
for i = 1, getn(upgrades) do
    local name = upgrades[i]

    local id = FastHash(name)
    upgradeLookup[id] = {
        Name = name,
        MessageKey = "upgrade." .. name,
    }

    exRegisterUpgradeCompleteEvent(name)
end
exRegisterUpgradeCompleteEvent(RANK3_NAME)

function onPlayerUpgradeCompleteEvent(playerName, upgradeInstanceId, objectId)
    local playerIndex = PlayerIndex[playerName];

    local isFirstTeam = g_IsDevilSeat(playerIndex)

    local factionName = PlayerSideName[playerName]
    local targetPlayer = PlayerToComputer[playerName]

    -- "$pXName"
    local playerToken = "$p" .. playerIndex .. "Name"

    -- Special case
    if upgradeInstanceId == RANK3_ID then
        local previous = SetWorldBuilderThisPlayer(1)

        ExecuteAction("ALLOW_DISALLOW_ONE_UPGRADE", playerName, RANK3_NAME, 'false')
        if isFirstTeam then
            exEnableWBScript("LEVELUP7")
        else
            exEnableWBScript("LEVELUP8")
        end

        SetWorldBuilderThisPlayer(previous)
        return
    end

    -- O(1) lookup
    local entry = %upgradeLookup[upgradeInstanceId]
    if not entry then
        _ALERT("Unknown upgrade completed: " .. upgradeInstanceId)
        return
    end

    local previous = SetWorldBuilderThisPlayer(1)

    ExecuteAction("GIVE_PLAYER_UPGRADE", targetPlayer, entry.Name)

    exMessageAppendToMessageArea(
        factionName .. playerToken .. Localization.get(entry.MessageKey)
    )

    SetWorldBuilderThisPlayer(previous)
end
