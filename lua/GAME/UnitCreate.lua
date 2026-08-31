g_UnitCreateEventFunc = {}

function ShowTimedHelp(ownerPlayerName, name, localizedText, x, y, z)
    name = format("%s_%s", ownerPlayerName, name)
    ExecuteAction("NAMED_DELETE", name)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", name, "MultiplayerBeacon", format("%s/team%s", ownerPlayerName, ownerPlayerName), {
        X = x,
        Y = y,
        Z = z,
    }, 0)
    TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", name, localizedText, 0, "")
    SchedulerModule.delay_call(function(id)
        -- 这里使用 id 而不是 name 是因为 name 有可能被重复利用
        -- 我们并不希望删除新的同名对象
        -- 我们只需要删除之前的这个 id 对应的对象就行了
        if ObjectIsAlive(id) then
            ExecuteAction("NAMED_DELETE", GetObjectById(id))
        end
    end, 100, {GetObjectById(GetObjectByScriptName(name))})
end

function limitCelestialBattery(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ExecuteAction("NAMED_DELETE", GetObjectById(id));
        end
    end, 15, {createdObjId})
end

function CelestialBatteryBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    ShowTimedHelp(ownerPlayerName, "CelestialBatteryHelp", "SCRIPT:CelestialBatteryHelp", x, y, z)
end

function CelestialLaserTowerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    ShowTimedHelp(ownerPlayerName, "CelestialLaserTowerHelp", "SCRIPT:CelestialLaserTowerHelp", x, y, z)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local teamName = ObjectTeamName(GetObjectById(id))
            local playerName = g_objectTeamNameToPlayerName[teamName]
            ExecuteAction("NAMED_DELETE", GetObjectById(id));
            ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", playerName, 'CelestialAntiVehicleInfantry', playerName .. '/team' .. playerName, 'commonSpawn')
        end
    end, 5, {createdObjId})
end

function CelestialSpaceReinforceMarkerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    ShowTimedHelp(ownerPlayerName, "CelestialReinforcementHelp", "SCRIPT:CelestialReinforcementHelp", x, y, z)
end

function CelestialCenturionUpgradeBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- 每当百夫长物体出生之后，先等一会（等百夫长机制初始化完毕），之后再看看是不是该给千夫长/万夫长了
    local round = exCounterGetByName("lvc")
    if round < 9 then
        -- 前面几个回合不给你用千夫长
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            -- 获取拥有百夫长的步兵
            local table, count = ObjectGetAttachees(id)
            if count > 0 and ObjectIsAlive(table[1]) then
                local centurion = table[1]
                -- 看看他是不是已经是千夫长
                local attachers, attachersCount = ObjectGetAttachers(centurion)
                for i = 1, attachersCount do
                    if ObjectTemplateName(attachers[i]) == ObjectTemplateName(GetObjectById(id)) then
                        if EvaluateCondition("UNIT_HAS_OBJECT_STATUS", attachers[i], "WEAPON_UPGRADED_02") then
                            -- 已经是千夫长了
                            return
                        end
                    end
                end
                -- 如果不是千夫长，就给他千夫长
                local x, y, z = ObjectGetPosition(centurion)
                ObjectUnloadAttributeModifier(centurion, "AttributeMod_CenturionUpgradeLeaderPrevent")
                ObjectUnloadAttributeModifier(centurion, "AttributeMod_CenturionUpgradeLeaderPreventPrevent")
                ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", centurion, "EXITING_COMBINED", 0);
                ObjectCreateAndFireTempWeaponToTarget(id, "CelestialCenturionUpgradeWeapon", {
                    X = x,
                    Y = y,
                    Z = z,
                }, centurion)
                ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", centurion, "EXITING_COMBINED", 0);
            end
        end
    end, 20, {createdObjId})
end

function AlliedSuperWeaponBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    g_AlliedSuperWeaponBuilt[g_PlayerNameToIndex[ownerPlayerName]] = 1
    CenterTopBtnFunc_UpdatePlayer3rdButton(g_PlayerNameToIndex[ownerPlayerName])

    SchedulerModule.delay_call(function(id, playerName)
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedSuperWeapon", 0)
        if ObjectIsAlive(id) then
            ExecuteAction("NAMED_DELETE", GetObjectById(id))
        end
    end, 10, {createdObjId, ownerPlayerName})

end

function GetLimitCommandoUnitCreateFunc(commandoName, limitCount)
    g_UnitCount[FastHash(commandoName)] = { 0, 0, 0, 0, 0, 0 }
    return function(createdObjId, createdObjInstanceId, ownerPlayerName)
        local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
        if playerIndex == nil then
            return
        end
        local countTable = g_UnitCount[createdObjInstanceId]
        if countTable == nil then
            countTable = {}
            g_UnitCount[createdObjInstanceId] = countTable
        end
        local newCount = (countTable[playerIndex] or 0) + 1
        if newCount >= %limitCount then
            -- 禁止造更多的
            local previous = SetWorldBuilderThisPlayer(1)
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", ownerPlayerName, %commandoName, 0)
            SetWorldBuilderThisPlayer(previous)
        end
        countTable[playerIndex] = newCount
    end
end

function JapanPointDefenseDroneBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unitTable = GetObjectById(id)
            local attachees = ObjectGetAttachees(id)
            local attachee = nil
            if attachees ~= nil then
                attachee = attachees[1]
            end
            if ObjectIsAlive(attachee) then
                local currentPlayerName = ObjectPlayerScriptName(id)
                local attacheePlayerName = ObjectPlayerScriptName(attachee)
                if currentPlayerName ~= attacheePlayerName then
                    local newTeamName = format("%s/%s", attacheePlayerName, ObjectTeamName(attachee))
                    ExecuteAction("UNIT_SET_TEAM", unitTable, newTeamName)
                end
            end
            ExecuteAction("UNIT_AFFECT_OBJECT_PANEL_FLAGS", unitTable, "Indestructible", false)
        end
    end, 1, {createdObjId})
end

function JapanKamikazeInfantryBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- 仅对于电脑的步兵：5 秒后自动启用技能
    if ownerPlayerName == "PlyrCreeps"
        or ownerPlayerName == "PlyrCivilian" then
        SchedulerModule.delay_call(function(id)
            if ObjectIsAlive(id) then
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", GetObjectById(id), "Command_SpecialPowerJapanKamikazeBonzai")
            end
        end, 15 * 5, {createdObjId})
    end
end

g_JapanAIAirFormCommands = {
    [FastHash("JapanAntiInfantryVehicle")] = "Command_JAIV_Transform",
    [FastHash("JapanAntiInfantryVehicle_Enhanced")] = "Command_JAIV_Transform",
    [FastHash("JapanAntiAirVehicleTech1")] = "Command_JAAVT1_Transform",
    [FastHash("JapanAntiAirVehicleTech1_Enhanced")] = "Command_JAAVT1_Transform",
    [FastHash("JapanMissileMechaAdvanced")] = "Command_JapanMissileMechaAdavanced_Transform",
    [FastHash("JapanMissileMechaAdvanced_Enhanced")] = "Command_JapanMissileMechaAdavanced_Transform",
}

function JapanAIAirFormVehicleBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if ownerPlayerName ~= "PlyrCreeps" and ownerPlayerName ~= "PlyrCivilian" then
        return
    end
    local commandName = g_JapanAIAirFormCommands[createdObjInstanceId]
    SchedulerModule.delay_call(function(id, command)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit, "AIRBORNE_TARGET") then
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", unit, command)
            end
        end
    end, 1, {createdObjId, commandName})
end

g_UnitCount = g_UnitCount or {}
g_UnitCount[FastHash("JapanGigaFortressShipEgg")] =
    g_UnitCount[FastHash("JapanGigaFortressShipEgg")] or { 0, 0, 0, 0, 0, 0 }
-- ACV 不需要特殊处理了，所以下面这两个应该是没用了？
g_UnitCount[FastHash("AlliedAntiInfantryVehicle")] =
    g_UnitCount[FastHash("AlliedAntiInfantryVehicle")] or { 0, 0, 0, 0, 0, 0 }
g_UnitCount[FastHash("AlliedAntiInfantryVehicle_Ground")] =
    g_UnitCount[FastHash("AlliedAntiInfantryVehicle_Ground")] or { 0, 0, 0, 0, 0, 0 }

function UnitCountFunc(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    SchedulerModule.delay_call(function(id, instanceId, playerName)
        local count = g_UnitCount[instanceId][g_PlayerNameToIndex[playerName]];
        g_UnitCount[instanceId][g_PlayerNameToIndex[playerName]] = count + 1;
        if ObjectIsAlive(id) then
            ExecuteAction("NAMED_DELETE", GetObjectById(id))
        end
    end, 8, {createdObjId, createdObjInstanceId, ownerPlayerName})

end

g_UnitCreateEventFunc[FastHash("CelestialElectricitySale_ForCelestialPower")] = limitCelestialBattery
g_UnitCreateEventFunc[FastHash("CelestialElectricitySale_ForCelestialAdvancedPower")] = limitCelestialBattery
g_UnitCreateEventFunc[FastHash("CelestialAlliesElectricitySale_ForCelestialAdvancedPower")] = limitCelestialBattery
g_UnitCreateEventFunc[FastHash("CelestialAlliesElectricitySale_ForCelestialPower")] = limitCelestialBattery
g_UnitCreateEventFunc[FastHash("CelestialElectricitySale_ForAlliedTurbine")] = limitCelestialBattery
g_UnitCreateEventFunc[FastHash("CelestialAlliesElectricitySale_ForAlliedTurbine")] = limitCelestialBattery
g_UnitCreateEventFunc[FastHash("CelestialAlliesElectricitySale_ForSovietAdvancedPower")] = limitCelestialBattery

g_UnitCreateEventFunc[FastHash("CelestialLaserTower")] = CelestialLaserTowerBorn
g_UnitCreateEventFunc[FastHash("CelestialBattery")] = CelestialBatteryBorn
g_UnitCreateEventFunc[FastHash("CelestialSpaceReinforceMarker")] = CelestialSpaceReinforceMarkerBorn

g_UnitCreateEventFunc[FastHash("CelestialCenturionUpgradeObject")] = CelestialCenturionUpgradeBorn
g_UnitCreateEventFunc[FastHash("AlliedSuperWeapon")] = AlliedSuperWeaponBorn

g_UnitCreateEventFunc[FastHash("JapanGigaFortressShipEgg")] = UnitCountFunc
-- ACV 不需要特殊处理了
-- g_UnitCreateEventFunc[FastHash("AlliedAntiInfantryVehicle")] = UnitCountFunc
-- g_UnitCreateEventFunc[FastHash("AlliedAntiInfantryVehicle_Ground")] = UnitCountFunc

-- 三阵营英雄统一限制为每位玩家两个。
g_UnitCreateEventFunc[FastHash("SovietCommandoTech1")] = GetLimitCommandoUnitCreateFunc("SovietCommandoTech1", 2)
g_UnitCreateEventFunc[FastHash("AlliedCommandoTech1")] = GetLimitCommandoUnitCreateFunc("AlliedCommandoTech1", 2)
-- 百合子的建筑索敌仍由微操脚本排除。
g_UnitCreateEventFunc[FastHash("JapanCommandoTech1")] = GetLimitCommandoUnitCreateFunc("JapanCommandoTech1", 2)

g_UnitCreateEventFunc[FastHash("JapanPointDefenseDrone")] = JapanPointDefenseDroneBorn

g_UnitCreateEventFunc[FastHash("JapanKamikazeInfantry")] = JapanKamikazeInfantryBorn

g_UnitCreateEventFunc[FastHash("JapanAntiInfantryVehicle")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanAntiInfantryVehicle_Enhanced")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanAntiAirVehicleTech1")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanAntiAirVehicleTech1_Enhanced")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanMissileMechaAdvanced")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanMissileMechaAdvanced_Enhanced")] = JapanAIAirFormVehicleBorn

--exObjectRegisterCreateEvent("CelestialElectricitySale_ForCelestialPower")
--exObjectRegisterCreateEvent("CelestialElectricitySale_ForCelestialAdvancedPower")
--exObjectRegisterCreateEvent("CelestialAlliesElectricitySale_ForCelestialAdvancedPower")
--exObjectRegisterCreateEvent("CelestialAlliesElectricitySale_ForCelestialPower")
--exObjectRegisterCreateEvent("CelestialElectricitySale_ForAlliedTurbine")
--exObjectRegisterCreateEvent("CelestialAlliesElectricitySale_ForAlliedTurbine")
--exObjectRegisterCreateEvent("CelestialAlliesElectricitySale_ForSovietAdvancedPower")
exObjectRegisterCreateEvent("CelestialLaserTower")
exObjectRegisterCreateEvent("CelestialBattery")
exObjectRegisterCreateEvent("CelestialSpaceReinforceMarker")

exObjectRegisterCreateEvent("CelestialCenturionUpgradeObject")
exObjectRegisterCreateEvent("AlliedSuperWeapon")
exObjectRegisterCreateEvent("JapanGigaFortressShipEgg")
-- ACV 不需要特殊处理了
-- exObjectRegisterCreateEvent("AlliedAntiInfantryVehicle")
-- exObjectRegisterCreateEvent("AlliedAntiInfantryVehicle_Ground")

exObjectRegisterCreateEvent("SovietCommandoTech1")
exObjectRegisterCreateEvent("AlliedCommandoTech1")
exObjectRegisterCreateEvent("JapanCommandoTech1")
exObjectRegisterCreateEvent("JapanPointDefenseDrone")

exObjectRegisterCreateEvent("JapanKamikazeInfantry")

exObjectRegisterCreateEvent("JapanAntiInfantryVehicle")
exObjectRegisterCreateEvent("JapanAntiInfantryVehicle_Enhanced")
exObjectRegisterCreateEvent("JapanAntiAirVehicleTech1")
exObjectRegisterCreateEvent("JapanAntiAirVehicleTech1_Enhanced")
exObjectRegisterCreateEvent("JapanMissileMechaAdvanced")
exObjectRegisterCreateEvent("JapanMissileMechaAdvanced_Enhanced")

function onUnitCreateEvent(createdObjId, createdObjInstanceId, ownerPlayerName)
    g_UnitCreateEventFunc[createdObjInstanceId](createdObjId, createdObjInstanceId, ownerPlayerName)
end
