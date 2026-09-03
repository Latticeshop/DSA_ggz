g_UnitCreateEventFunc = {}

-- 守护者坦克只能使用激光指示器：禁用玩家和 AI 的模式切换，出生脚本仍可强制切换一次。
-- 地编动作不能在 Lua 块加载时立即执行，否则桥接层尚未注册当前的 Fname 函数。
SchedulerModule.delay_call(function()
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", "<All Players>", "SpecialPower_ToggleTargetPainter", "Disabled")
    -- 光荣级导弹巡洋舰禁用 F 技能（反潜机）。
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", "<All Players>", "SpecialPower_ToggleAimLaser", "Disabled")
end, 1)

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
    -- 已停用：电脑的狂热武士出生 5 秒后无条件开 F。
    -- 改为出生时配置引擎索敌；Lua 只读取引擎选中的目标并触发 F。
    -- if ownerPlayerName == "PlyrCreeps"
    --     or ownerPlayerName == "PlyrCivilian" then
    --     SchedulerModule.delay_call(function(id)
    --         if ObjectIsAlive(id) then
    --             ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", GetObjectById(id), "Command_SpecialPowerJapanKamikazeBonzai")
    --         end
    --     end, 15 * 5, {createdObjId})
    -- end
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ObjectSetCustomTargetChooserData(unit, {
                CustomFilter = g_FilterPrioritySiegeAllGroundEnemy,
                CompareFilterList = {
                    g_FilterKamikazeBonzaiEnemy,
                    g_FilterPrioritySiegeEnemyInfantry
                },
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
            TrackJapanKamikazeAutoBonzai(id)
        end
    end, 1, {createdObjId})
end

-- 空军元帅使用双方现有的 BASE 编队作为专用飞行编队，避开普通 AIR/AIRATTACK 编队 AI。
-- 命名检测作为后备；GetObjectByScriptName 查询单位命名空间，不会与同名路径点冲突。
g_AirMarshalTeamNames = {
    ["BASE"] = true,
    ["PlyrCivilian/BASE"] = true,
    ["PlyrCreeps/BASE"] = true,
}

function IsAirMarshalAircraft(unit)
    if unit == nil then
        return false
    end
    if g_AirMarshalTeamNames[ObjectTeamName(unit)] then
        return true
    end
    local unitId = ObjectGetId(unit)
    for i = 1, 8, 1 do
        local angelUnit = GetObjectByScriptName("angel" .. i)
        if angelUnit ~= nil and ObjectGetId(angelUnit) == unitId then
            return true
        end
        local devilUnit = GetObjectByScriptName("devil" .. i)
        if devilUnit ~= nil and ObjectGetId(devilUnit) == unitId then
            return true
        end
    end
    return false
end

g_TanyaTowerBombState = g_TanyaTowerBombState or {}
g_TanyaBombTowerScriptNames = g_TanyaBombTowerScriptNames or {
    "T71", "T72", "T73", "T74",
    "T81", "T82", "T83", "T84"
}
-- 日冕使用 Lua 4；这里固定数量，不依赖 getn 或长度运算符。
g_TanyaBombTowerScriptNameCount = 8

function IsTanyaAttachedToBombTower(id)
    for i = 1, g_TanyaBombTowerScriptNameCount, 1 do
        local towerName = g_TanyaBombTowerScriptNames[i]
        local tower = GetObjectByScriptName(towerName)
        if tower ~= nil and ObjectIsAlive(tower) then
            local attachers, attacherCount = ObjectGetAttachers(tower)
            if attachers ~= nil and attacherCount ~= nil then
                for j = 1, attacherCount, 1 do
                    local attacher = attachers[j]
                    -- 当前循环只跟踪这个出生事件给出的谭雅 ID；ID 相同已经足以排除 C4 对象，
                    -- 不再额外依赖 ObjectTemplateName 的返回格式。
                    if attacher ~= nil and ObjectGetId(attacher) == id then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function KillTanyaAfterTowerBomb(id)
    if g_TanyaTowerBombState[id] == nil then
        return
    end
    g_TanyaTowerBombState[id] = nil
    if ObjectIsAlive(id) then
        ExecuteAction("NAMED_DELETE", GetObjectById(id))
    end
end

function TrackTanyaTowerBomb(id)
    local state = g_TanyaTowerBombState[id]
    if state == nil then
        return
    end
    if not ObjectIsAlive(id) then
        g_TanyaTowerBombState[id] = nil
        return
    end

    -- 谭雅是 Attacher，塔是被附着对象。只认塔的 Attachers 中与当前出生 ID 匹配的对象。
    if IsTanyaAttachedToBombTower(id) then
        -- 进入爆破流程后等待 2 秒再清除，给原版 C4 留出完成时间，同时阻止再次进塔。
        SchedulerModule.delay_call(KillTanyaAfterTowerBomb, 15 * 2, {id})
        return
    end

    SchedulerModule.delay_call(TrackTanyaTowerBomb, 1, {id})
end

function TanyaTowerBombTrackerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- 不按所有者过滤，避免单位转交或特殊生成方式导致检测根本没有启动。
    g_TanyaTowerBombState[createdObjId] = true
    SchedulerModule.delay_call(TrackTanyaTowerBomb, 1, {createdObjId})
end

function AlliedGuardianTankBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- 等技能组件初始化完成后，强制切换为激光指示器模式。
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", GetObjectById(id), "Command_ToggleTargetPainter")
        end
    end, 1, {createdObjId})
    FarthestTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
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

-- 索敌优化全部交给引擎 TargetChooser。
-- 只有白虎、V4、波能炮和雅典娜额外使用 坦克 > 步兵 > 建筑 的类别优先级。
g_FilterOptimizedGroundEnemy = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE STRUCTURE",
    StatusBitFlagsExclude = "AIRBORNE_TARGET"
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

g_FilterKamikazeBonzaiEnemy = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "VEHICLE HUGE_VEHICLE STRUCTURE",
    Exclude = "AIRCRAFT IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE",
    StatusBitFlagsExclude = "AIRBORNE_TARGET"
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

-- 百合子只索敌单位，并按 坦克 > 飞机 > 步兵 排序。
g_FilterYurikoEnemy = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE AIRCRAFT",
    Exclude = "STRUCTURE IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

g_FilterYurikoEnemyAircraft = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    Include = "SELECTABLE",
    Exclude = "STRUCTURE IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE",
    StatusBitFlags = "AIRBORNE_TARGET"
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

g_KamikazeBonzaiEnemyRange = 300
g_AutoAbilityTargetCheckInterval = 3
g_ArmybreakerAutoAbilityInterval = 15 * 10

-- TargetChooser 负责筛选、距离排序和目标死亡后的重选。
-- 此处不再做范围搜索，只读取单位已有目标并尝试触发技能。
function TrackJapanKamikazeAutoBonzai(id)
    if not ObjectIsAlive(id) then
        return
    end
    local unit = GetObjectById(id)
    local target = ObjectGetTarget(unit)
    if target ~= nil
        and ObjectIsAlive(target)
        and ObjectTestTargetObjectWithFilter(unit, target, g_FilterKamikazeBonzaiEnemy)
        and ObjectsDistance2D(unit, target) <= g_KamikazeBonzaiEnemyRange then
        ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", unit, "Command_SpecialPowerJapanKamikazeBonzai")
    end
    SchedulerModule.delay_call(TrackJapanKamikazeAutoBonzai, g_AutoAbilityTargetCheckInterval, {id})
end

function TrackCelestialArmybreakerAutoCharge(id, unitReferenceName)
    if not ObjectIsAlive(id) then
        return
    end
    local unit = GetObjectById(id)
    local target = ObjectGetTarget(unit)
    local nextCheckInterval = g_AutoAbilityTargetCheckInterval
    if target ~= nil
        and ObjectIsAlive(target)
        and ObjectTestTargetObjectWithFilter(unit, target, g_FilterPrioritySiegeEnemyTank)
        and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit, "IS_FIRING_WEAPON") then
        -- IS_FIRING_WEAPON 表示目标已经进入该实例当前的实际武器射程。
        local targetReferenceName = "ArmybreakerAutoFTarget_" .. id
        ExecuteAction("SET_UNIT_REFERENCE", targetReferenceName, target)
        ExecuteAction(
            "NAMED_USE_COMMANDBUTTON_ABILITY_ON_NAMED",
            unitReferenceName,
            "Command_SpecialPowerCelestialArmybreakerCharge",
            targetReferenceName
        )
        nextCheckInterval = g_ArmybreakerAutoAbilityInterval
    end
    SchedulerModule.delay_call(
        TrackCelestialArmybreakerAutoCharge,
        nextCheckInterval,
        {id, unitReferenceName}
    )
end

function CelestialArmybreakerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ObjectSetCustomTargetChooserData(unit, {
                CustomFilter = g_FilterPrioritySiegeAllGroundEnemy,
                CompareFilterList = {
                    g_FilterPrioritySiegeEnemyTank,
                    g_FilterPrioritySiegeEnemyInfantry,
                    g_FilterPrioritySiegeEnemyStructure
                },
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
            local unitReferenceName = "ArmybreakerAutoFUnit_" .. id
            ExecuteAction("SET_UNIT_REFERENCE", unitReferenceName, unit)
            TrackCelestialArmybreakerAutoCharge(id, unitReferenceName)
        end
    end, 1, {createdObjId})
end

function NatashaPriorityTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ObjectSetCustomTargetChooserData(unit, {
                CustomFilter = g_FilterPrioritySiegeAllGroundEnemy,
                CompareFilterList = {
                    g_FilterPrioritySiegeEnemyInfantry,
                    g_FilterPrioritySiegeEnemyTank,
                    g_FilterPrioritySiegeEnemyStructure
                },
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
        end
    end, 1, {createdObjId})
end

function YurikoPriorityTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ObjectSetCustomTargetChooserData(unit, {
                CustomFilter = g_FilterYurikoEnemy,
                CompareFilterList = {
                    g_FilterPrioritySiegeEnemyTank,
                    g_FilterYurikoEnemyAircraft,
                    g_FilterPrioritySiegeEnemyInfantry
                },
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
        end
    end, 1, {createdObjId})
end

function ConfigureNearestNoChaseTargetChooser(unit, targetFilter)
    ObjectSetCustomTargetChooserData(unit, {
        CustomFilter = targetFilter,
        ReverseRangeCompare = false,
        PreferTargetInsideRange = true
    })
    ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
end

function ConfigureFarthestNoChaseTargetChooser(unit, targetFilter)
    ObjectSetCustomTargetChooserData(unit, {
        CustomFilter = targetFilter,
        ReverseRangeCompare = true,
        PreferTargetInsideRange = true
    })
    ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
end

g_NearestNoChaseFilterByInstanceId = {
    -- VX 保留独立的最近目标与空地形态切换逻辑。
    [FastHash("JapanAntiAirVehicleTech1")] = g_FilterOptimizedGroundEnemy,
    [FastHash("JapanAntiAirVehicleTech1_Enhanced")] = g_FilterOptimizedGroundEnemy,
}

function NearestNoChaseTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    local targetFilter = g_NearestNoChaseFilterByInstanceId[createdObjInstanceId]
    SchedulerModule.delay_call(function(id, filter)
        if ObjectIsAlive(id) then
            local unit = GetObjectById(id)
            ConfigureNearestNoChaseTargetChooser(unit, filter)
        end
    end, 1, {createdObjId, targetFilter})
end

g_FarthestNoChaseFilterByInstanceId = {
    [FastHash("PrismTank")] = g_FilterOptimizedGroundEnemy,
    [FastHash("AlliedPrismTank_Enhanced")] = g_FilterOptimizedGroundEnemy,
    [FastHash("JapanMechaX")] = g_FilterOptimizedGroundEnemy,
    [FastHash("AlliedAntiVehicleVehicleTech1")] = g_FilterOptimizedGroundEnemy,
    [FastHash("AlliedAntiVehicleVehicleTech1_Enhanced")] = g_FilterOptimizedGroundEnemy,
    [FastHash("CelestialHeavyAntiAirVehicleTech3")] = g_FilterOptimizedGroundEnemy,
    [FastHash("CelestialAntiVehicleVehicleTech3_EMC")] = g_FilterOptimizedGroundEnemy,
    -- 青锋导弹车的内部名虽然带 AntiAir，实际武器只能攻击地面单位。
    [FastHash("CelestialAntiAirVehicleTech3")] = g_FilterOptimizedGroundEnemy,
    [FastHash("SovietSledgehammerSPG")] = g_FilterOptimizedGroundEnemy,
    [FastHash("SovietSledgehammerSPG_Enhanced")] = g_FilterOptimizedGroundEnemy,
    [FastHash("SovietSPG")] = g_FilterOptimizedGroundEnemy,
}

function FarthestTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if not IsAutoChessAIPlayer(ownerPlayerName) then
        return
    end
    local targetFilter = g_FarthestNoChaseFilterByInstanceId[createdObjInstanceId]
    SchedulerModule.delay_call(function(id, filter)
        if ObjectIsAlive(id) then
            ConfigureFarthestNoChaseTargetChooser(GetObjectById(id), filter)
        end
    end, 1, {createdObjId, targetFilter})
end

function JapanAIAirFormVehicleAndNearestNoChaseBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    JapanAIAirFormVehicleBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    NearestNoChaseTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
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

g_AirHunterTargetByUnitId = g_AirHunterTargetByUnitId or {}

function AntiAirHunterBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
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
            if IsAirMarshalAircraft(unit) then
                return
            end
            ExecuteAction("NAMED_STOP", unit)
            ExecuteAction("UNIT_SET_TEAM", unit, g_PrioritySiegeIdleTeam[sideIndex])
            ConfigureNearestNoChaseTargetChooser(unit, g_FilterOptimizedAirEnemy)
            g_AirHunterTargetByUnitId[id] = nil
        end
    end, 1, {createdObjId, playindex})
end

function JapanAIAirFormVehicleAndAirHunterBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    JapanAIAirFormVehicleBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    AntiAirHunterBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
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

-- 三阵营英雄不再限造；保留原调用作为配置参考。
-- g_SovietCommandoLimitBorn = GetLimitCommandoUnitCreateFunc("SovietCommandoTech1", 2)
function SovietCommandoBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- g_SovietCommandoLimitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    NatashaPriorityTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
end
g_UnitCreateEventFunc[FastHash("SovietCommandoTech1")] = SovietCommandoBorn
-- g_AlliedCommandoLimitBorn = GetLimitCommandoUnitCreateFunc("AlliedCommandoTech1", 2)
if not g_TanyaRangeX125Modifier then
    g_TanyaRangeX125Modifier = exAttributeModifierCreate({ RANGE = 1.25 }, 1)
end
function AlliedCommandoBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- g_AlliedCommandoLimitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ObjectLoadAttributeModifier(GetObjectById(id), g_TanyaRangeX125Modifier)
        end
    end, 1, {createdObjId})
    TanyaTowerBombTrackerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
end
g_UnitCreateEventFunc[FastHash("AlliedCommandoTech1")] = AlliedCommandoBorn
-- g_JapanCommandoLimitBorn = GetLimitCommandoUnitCreateFunc("JapanCommandoTech1", 2)
if not g_YurikoRangeX25Modifier then
    g_YurikoRangeX25Modifier = exAttributeModifierCreate({ RANGE = 2.5 }, 1)
end
function JapanCommandoBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- g_JapanCommandoLimitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            local yuriko = GetObjectById(id)
            ObjectLoadAttributeModifier(yuriko, g_YurikoRangeX25Modifier)
        end
    end, 1, {createdObjId})
    YurikoPriorityTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
end
-- 百合子的建筑索敌与类别优先级也由微操脚本持续保持。
g_UnitCreateEventFunc[FastHash("JapanCommandoTech1")] = JapanCommandoBorn

g_UnitCreateEventFunc[FastHash("JapanPointDefenseDrone")] = JapanPointDefenseDroneBorn

g_UnitCreateEventFunc[FastHash("JapanKamikazeInfantry")] = JapanKamikazeInfantryBorn

g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech4")] = CelestialArmybreakerBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech4_Enhanced")] = CelestialArmybreakerBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech4_S01")] = CelestialArmybreakerBorn

g_UnitCreateEventFunc[FastHash("AlliedAntiVehicleVehicleTech1")] = AlliedGuardianTankBorn
g_UnitCreateEventFunc[FastHash("AlliedAntiVehicleVehicleTech1_Enhanced")] = AlliedGuardianTankBorn

g_UnitCreateEventFunc[FastHash("JapanAntiVehicleVehicleTech1")] = JapanTsunamiTankBorn
g_UnitCreateEventFunc[FastHash("JapanAntiVehicleVehicleTech1_Naval")] = JapanTsunamiTankBorn

g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech1")] = CelestialKylinTankBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech1_EMC")] = CelestialKylinTankBorn
g_UnitCreateEventFunc[FastHash("qilintank")] = CelestialKylinTankBorn

g_UnitCreateEventFunc[FastHash("JapanAntiInfantryVehicle")] = JapanAIAirFormVehicleAndAirHunterBorn
g_UnitCreateEventFunc[FastHash("JapanAntiInfantryVehicle_Enhanced")] = JapanAIAirFormVehicleAndAirHunterBorn
g_UnitCreateEventFunc[FastHash("JapanAntiAirVehicleTech1")] = JapanAIAirFormVehicleAndNearestNoChaseBorn
g_UnitCreateEventFunc[FastHash("JapanAntiAirVehicleTech1_Enhanced")] = JapanAIAirFormVehicleAndNearestNoChaseBorn
g_UnitCreateEventFunc[FastHash("JapanMissileMechaAdvanced")] = JapanAIAirFormVehicleAndAirHunterBorn
g_UnitCreateEventFunc[FastHash("JapanMissileMechaAdvanced_Enhanced")] = JapanAIAirFormVehicleAndAirHunterBorn

-- 配置坦克统一在射程内优先选择最远目标。
g_UnitCreateEventFunc[FastHash("PrismTank")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedPrismTank_Enhanced")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("JapanMechaX")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialHeavyAntiAirVehicleTech3")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiVehicleVehicleTech3_EMC")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiAirVehicleTech3")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietSledgehammerSPG")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietSledgehammerSPG_Enhanced")] = FarthestTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietSPG")] = FarthestTargetChooserBorn

-- 仅四类 T3 攻城单位叠加 坦克 > 步兵 > 建筑 的优先级。
g_UnitCreateEventFunc[FastHash("CelestialAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("CelestialAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("SovietAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("JapanAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("JapanAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedAntiStructureVehicle")] = PrioritySiegeTargetChooserBorn
g_UnitCreateEventFunc[FastHash("AlliedAntiStructureVehicle_Enhanced")] = PrioritySiegeTargetChooserBorn
-- 专职对空飞机使用独立编队和锁定式最近目标 AI。
g_UnitCreateEventFunc[FastHash("AlliedFighterAircraft")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("AlliedFighterAircraft_Enhanced")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("AlliedInterceptorAircraft")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("AlliedInterceptorAircraft_Enhanced")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("CelestialFighterAircraft")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("CelestialInterceptorAircraft")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("CelestialInterceptorAircraft_Enhanced")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("SovietFighterAircraft")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("SovietFighterAircraft_Enhanced")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("SovietInterceptorAircraft")] = AntiAirHunterBorn
g_UnitCreateEventFunc[FastHash("SovietInterceptorAircraft_Enhanced")] = AntiAirHunterBorn

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

exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech4")
exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech4_Enhanced")
exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech4_S01")

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
exObjectRegisterCreateEvent("JapanMechaX")
exObjectRegisterCreateEvent("CelestialHeavyAntiAirVehicleTech3")
exObjectRegisterCreateEvent("CelestialAntiVehicleVehicleTech3_EMC")
exObjectRegisterCreateEvent("CelestialAntiAirVehicleTech3")
exObjectRegisterCreateEvent("SovietSledgehammerSPG")
exObjectRegisterCreateEvent("SovietSledgehammerSPG_Enhanced")
exObjectRegisterCreateEvent("SovietSPG")

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
exObjectRegisterCreateEvent("CelestialFighterAircraft")
exObjectRegisterCreateEvent("CelestialInterceptorAircraft")
exObjectRegisterCreateEvent("CelestialInterceptorAircraft_Enhanced")
exObjectRegisterCreateEvent("SovietFighterAircraft")
exObjectRegisterCreateEvent("SovietFighterAircraft_Enhanced")
exObjectRegisterCreateEvent("SovietInterceptorAircraft")
exObjectRegisterCreateEvent("SovietInterceptorAircraft_Enhanced")

function onUnitCreateEvent(createdObjId, createdObjInstanceId, ownerPlayerName)
    g_UnitCreateEventFunc[createdObjInstanceId](createdObjId, createdObjInstanceId, ownerPlayerName)
end
