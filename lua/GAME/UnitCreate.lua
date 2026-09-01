g_UnitCreateEventFunc = {}

-- 守护者坦克只能使用激光指示器：禁用玩家和 AI 的模式切换，出生脚本仍可强制切换一次。
ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", "<All Players>", "SpecialPower_ToggleTargetPainter", "Disabled")

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

function AlliedGuardianTankBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- 等技能组件初始化完成后，强制切换为激光指示器模式。
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", GetObjectById(id), "Command_ToggleTargetPainter")
        end
    end, 1, {createdObjId})
end

function JapanTsunamiTankBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ObjectLoadAttributeModifier(GetObjectById(id), "AttributeMod_SovietCompositeArmorForLargeUnit", 999999)
        end
    end, 1, {createdObjId})
end

function CelestialKylinTankBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ObjectLoadAttributeModifier(GetObjectById(id), "AttributeMod_CenturionUpgradeLeaderLv1", 999999)
        end
    end, 1, {createdObjId})
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

-- 索敌优化全部交给引擎 TargetChooser：单位自身射程内优先选择最远目标。
-- 只有白虎、V4、波能炮和雅典娜额外使用 坦克 > 步兵 > 建筑 的类别优先级。
g_FilterOptimizedGroundEnemy = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE STRUCTURE"
})

g_FilterOptimizedAirEnemy = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "SELECTABLE",
    StatusBitFlags = "AIRBORNE_TARGET"
})

g_FilterPrioritySiegeEnemyTank = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "VEHICLE HUGE_VEHICLE",
    Exclude = "AIRCRAFT STRUCTURE INFANTRY IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

g_FilterPrioritySiegeAllGroundEnemy = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE STRUCTURE",
    Exclude = "AIRCRAFT IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

g_FilterPrioritySiegeEnemyInfantry = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "INFANTRY",
    Exclude = "AIRCRAFT STRUCTURE IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

g_FilterPrioritySiegeEnemyStructure = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "STRUCTURE",
    Exclude = "IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

-- 四类炮车使用独立的单体攻击前进，不再接受 LIGHTVEHATTACK 的队伍级刷新。
g_PrioritySiegeTankPursuitActive = g_PrioritySiegeTankPursuitActive or {
    [7] = false,
    [8] = false
}
g_PrioritySiegeUnitMode = g_PrioritySiegeUnitMode or {}
g_PrioritySiegeStructureStopRange = 700
g_PrioritySiegeIdleTeam = g_PrioritySiegeIdleTeam or {
    [7] = "PlyrCivilian/teamPlyrCivilian",
    [8] = "PlyrCreeps/teamPlyrCreeps"
}
g_PrioritySiegeAttackWaypoint = g_PrioritySiegeAttackWaypoint or {
    [7] = "TD8",
    [8] = "TD7"
}

function SetPrioritySiegeTargetChooserMode(unit, tankPursuitActive)
    if tankPursuitActive then
        ObjectSetCustomTargetChooserData(unit, {
            -- 追击状态只认坦克，避免被前排步兵卡在最大射程。
            CustomFilter = g_FilterPrioritySiegeEnemyTank,
            ReverseRangeCompare = true,
            PreferTargetInsideRange = true
        })
    else
        ObjectSetCustomTargetChooserData(unit, {
            CustomFilter = g_FilterPrioritySiegeAllGroundEnemy,
            CompareFilterList = {
                g_FilterPrioritySiegeEnemyTank,
                g_FilterPrioritySiegeEnemyInfantry,
                g_FilterPrioritySiegeEnemyStructure
            },
            ReverseRangeCompare = true,
            PreferTargetInsideRange = true
        })
    end
    ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
end

function GetPrioritySiegeUnitMode(unit, enemyTankExists)
    local x, y, z = ObjectGetPosition(unit)
    local structures, structureCount = ObjectFindObjects(unit, {
        X = x, Y = y, Z = z,
        Radius = g_PrioritySiegeStructureStopRange,
        DistType = "CENTER_2D"
    }, g_FilterPrioritySiegeEnemyStructure)
    if structureCount > 0 then
        return "STRUCTURE_HOLD"
    end
    if enemyTankExists then
        return "TANK_PURSUIT"
    end
    return "NORMAL_ADVANCE"
end

function IsAutoChessAIPlayer(ownerPlayerName)
    return ownerPlayerName == "PlyrCreeps" or ownerPlayerName == "PlyrCivilian"
end

function FarthestGroundTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ObjectSetCustomTargetChooserData(unit, {
                CustomFilter = g_FilterOptimizedGroundEnemy,
                ReverseRangeCompare = true,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
        end
    end, 1, {createdObjId})
end

function PrioritySiegeTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    local playindex = 7
    if ownerPlayerName == "PlyrCreeps" then
        playindex = 8
    end
    SchedulerModule.delay_call(function(id, sideIndex)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            local mode = GetPrioritySiegeUnitMode(unit, g_PrioritySiegeTankPursuitActive[sideIndex])
            ExecuteAction("UNIT_SET_TEAM", unit, g_PrioritySiegeIdleTeam[sideIndex])
            SetPrioritySiegeTargetChooserMode(unit, mode == "TANK_PURSUIT")
            g_PrioritySiegeUnitMode[id] = mode
            if mode ~= "STRUCTURE_HOLD" then
                ExecuteAction("ATTACK_MOVE_NAMED_UNIT_TO", unit, g_PrioritySiegeAttackWaypoint[sideIndex])
            end
        end
    end, 1, {createdObjId, playindex})
end

function FarthestAirTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ObjectSetCustomTargetChooserData(unit, {
                CustomFilter = g_FilterOptimizedAirEnemy,
                ReverseRangeCompare = true,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
        end
    end, 1, {createdObjId})
end

function JapanAIAirFormVehicleAndTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    JapanAIAirFormVehicleBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    FarthestAirTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
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

g_UnitCreateEventFunc[FastHash("AlliedAntiVehicleVehicleTech1")] = AlliedGuardianTankBorn
g_UnitCreateEventFunc[FastHash("AlliedAntiVehicleVehicleTech1_Enhanced")] = AlliedGuardianTankBorn

g_UnitCreateEventFunc[FastHash("JapanAntiVehicleVehicleTech1")] = JapanTsunamiTankBorn
g_UnitCreateEventFunc[FastHash("JapanAntiVehicleVehicleTech1_Naval")] = JapanTsunamiTankBorn

g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech1")] = CelestialKylinTankBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech1_EMC")] = CelestialKylinTankBorn
g_UnitCreateEventFunc[FastHash("qilintank")] = CelestialKylinTankBorn

g_UnitCreateEventFunc[FastHash("JapanAntiInfantryVehicle")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanAntiInfantryVehicle_Enhanced")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanAntiAirVehicleTech1")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanAntiAirVehicleTech1_Enhanced")] = JapanAIAirFormVehicleBorn
g_UnitCreateEventFunc[FastHash("JapanMissileMechaAdvanced")] = JapanAIAirFormVehicleAndTargetChooserBorn
g_UnitCreateEventFunc[FastHash("JapanMissileMechaAdvanced_Enhanced")] = JapanAIAirFormVehicleAndTargetChooserBorn

-- 已配置的远程坦克：使用自身射程内最远目标。
g_UnitCreateEventFunc[FastHash("PrismTank")] = FarthestGroundTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedPrismTank_Enhanced")] = FarthestGroundTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialHeavyAntiAirVehicleTech3")] = FarthestGroundTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech3_EMC")] = FarthestGroundTargetChooserBorn

-- 仅四类 T3 攻城单位叠加 坦克 > 步兵 > 建筑 的优先级。
g_UnitCreateEventFunc[FastHash("CelestialAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("JapanAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("JapanAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn

-- 所有已配置的专职对空飞机：使用自身射程内最远空中目标。
g_UnitCreateEventFunc[FastHash("AlliedFighterAircraft")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedFighterAircraft_Enhanced")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedInterceptorAircraft")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedInterceptorAircraft_Enhanced")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialInterceptorAircraft")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialInterceptorAircraft_Enhanced")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietFighterAircraft")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietFighterAircraft_Enhanced")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietInterceptorAircraft")] = FarthestAirTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietInterceptorAircraft_Enhanced")] = FarthestAirTargetChooserBorn

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

exObjectRegisterCreateEvent("AlliedAntiVehicleVehicleTech1")
exObjectRegisterCreateEvent("AlliedAntiVehicleVehicleTech1_Enhanced")

exObjectRegisterCreateEvent("JapanAntiVehicleVehicleTech1")
exObjectRegisterCreateEvent("JapanAntiVehicleVehicleTech1_Naval")

exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech1")
exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech1_EMC")
exObjectRegisterCreateEvent("qilintank")

exObjectRegisterCreateEvent("JapanAntiInfantryVehicle")
exObjectRegisterCreateEvent("JapanAntiInfantryVehicle_Enhanced")
exObjectRegisterCreateEvent("JapanAntiAirVehicleTech1")
exObjectRegisterCreateEvent("JapanAntiAirVehicleTech1_Enhanced")
exObjectRegisterCreateEvent("JapanMissileMechaAdvanced")
exObjectRegisterCreateEvent("JapanMissileMechaAdvanced_Enhanced")

exObjectRegisterCreateEvent("PrismTank")
exObjectRegisterCreateEvent("AlliedPrismTank_Enhanced")
exObjectRegisterCreateEvent("CelestialHeavyAntiAirVehicleTech3")
exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech3_EMC")

exObjectRegisterCreateEvent("CelestialAntiStructureVehicle")
exObjectRegisterCreateEvent("CelestialAntiStructureVehicle_Enhanced")
exObjectRegisterCreateEvent("SovietAntiStructureVehicle")
exObjectRegisterCreateEvent("SovietAntiStructureVehicle_Enhanced")
exObjectRegisterCreateEvent("JapanAntiStructureVehicle")
exObjectRegisterCreateEvent("JapanAntiStructureVehicle_Enhanced")
exObjectRegisterCreateEvent("AlliedAntiStructureVehicle")
exObjectRegisterCreateEvent("AlliedAntiStructureVehicle_Enhanced")

exObjectRegisterCreateEvent("AlliedFighterAircraft")
exObjectRegisterCreateEvent("AlliedFighterAircraft_Enhanced")
exObjectRegisterCreateEvent("AlliedInterceptorAircraft")
exObjectRegisterCreateEvent("AlliedInterceptorAircraft_Enhanced")
exObjectRegisterCreateEvent("CelestialInterceptorAircraft")
exObjectRegisterCreateEvent("CelestialInterceptorAircraft_Enhanced")
exObjectRegisterCreateEvent("SovietFighterAircraft")
exObjectRegisterCreateEvent("SovietFighterAircraft_Enhanced")
exObjectRegisterCreateEvent("SovietInterceptorAircraft")
exObjectRegisterCreateEvent("SovietInterceptorAircraft_Enhanced")

function onUnitCreateEvent(createdObjId, createdObjInstanceId, ownerPlayerName)
    g_UnitCreateEventFunc[createdObjInstanceId](createdObjId, createdObjInstanceId, ownerPlayerName)
end
