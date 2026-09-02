
DEFAULTATTCKTEAM = {}
DEFAULTATTCKTEAM[7] = "PlyrCivilian/ATTACK"
DEFAULTATTCKTEAM[8] = "PlyrCreeps/ATTACK"
DEFAULTIDLETEAM = {}
DEFAULTIDLETEAM[7] = "PlyrCivilian/teamPlyrCivilian"
DEFAULTIDLETEAM[8] = "PlyrCreeps/teamPlyrCreeps"


FilterJapanAntiInfantryVehicle=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiInfantryVehicle","JapanAntiInfantryVehicle_Enhanced"
    }
})

FilterJapanAntiAirVehicleTech1=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiAirVehicleTech1" , "JapanAntiAirVehicleTech1_Enhanced"
    }
})

FilterJapanMissileMechaAdvanced=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanMissileMechaAdvanced","JapanMissileMechaAdvanced_Enhanced"
    }
})

FilterJapanFortressShip=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="SELECTABLE",
    IncludeThing = {
        "JapanFortressShip","JapanigaFortressShip"
    }
})

FilterJapanAntiAirShip=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiAirShip","JapanAntiAirShip_Enhanced"
    }
})

FilterSovietScoutVehicle=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "SovietScoutVehicle"
    }
})

FilterJapanTsunamiTank=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiVehicleVehicleTech1","JapanAntiVehicleVehicleTech1_Naval"
    }
})

FilterAntiAirHunterAircraft=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiInfantryVehicle","JapanAntiInfantryVehicle_Enhanced",
        "JapanMissileMechaAdvanced","JapanMissileMechaAdvanced_Enhanced",
        "AlliedFighterAircraft","AlliedFighterAircraft_Enhanced",
        "AlliedInterceptorAircraft","AlliedInterceptorAircraft_Enhanced",
        "CelestialFighterAircraft",
        "CelestialInterceptorAircraft","CelestialInterceptorAircraft_Enhanced",
        "SovietFighterAircraft","SovietFighterAircraft_Enhanced",
        "SovietInterceptorAircraft","SovietInterceptorAircraft_Enhanced"
    }
})

FilterPrioritySiegeVehicle=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialAntiStructureVehicle","CelestialAntiStructureVehicle_Enhanced",
        "SovietAntiStructureVehicle","SovietAntiStructureVehicle_Enhanced",
        "JapanAntiStructureVehicle","JapanAntiStructureVehicle_Enhanced",
        "AlliedAntiStructureVehicle","AlliedAntiStructureVehicle_Enhanced",
        "JapanGigaFortress_Land"
    }
})

FilterCelestialAntiAirShip=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialAntiAirShip"
    }
})

FilterCelestialAntiAirShip=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialAntiAirShip"
    }
})

FilterCelestialAntiVehicleVehicleTech1=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialAntiVehicleVehicleTech1"
    }
})



Filterbigship=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "AlliedAntiNavyShipTech3","AlliedAntiStructureShip","CelestialAntiNavyShipTech3","CelestialAntiStructureShip","JapanAntiNavyShipTech3","SovietAntiNavyShipTech3","SovietAntiStructureShip","JapanAntiVehicleShip","CelestialAntiNavyShipTech1"
    }
})


FilterAIR=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="SELECTABLE",
    StatusBitFlags = "AIRBORNE_TARGET",
    ExcludeThing={
        "JapanAntiInfantryVehicle","JapanMissileMechaAdvanced"
    }
})

FilterAIR2=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="SELECTABLE",
    StatusBitFlags = "AIRBORNE_TARGET"
})

FilterLAND=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="SELECTABLE",
    StatusBitFlagsExclude = "AIRBORNE_TARGET"
})

FilterCelestialAdvanceAircraftTech4=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialAdvanceAircraftTech4"
    }
})

FilterJapanAntiNavyShipTech3=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiNavyShipTech3"
    }
})

FilterALLENEMYUNIT=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="INFANTRY VEHICLE STRUCTURE AIRCRAFT"
})

FilterNoStructureCommando=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    -- 百合子继续禁止攻击建筑；谭雅允许爆破一次，并由出生脚本在爆破后删除。
    IncludeThing = { "JapanCommandoTech1" }
})

FilterCommandoEnemy=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="INFANTRY VEHICLE HUGE_VEHICLE AIRCRAFT",
    Exclude="STRUCTURE"
})

function IsCommandoInAttackTeam(self, playindex)
    local teamName = ObjectTeamName(self)
    local playerName = "PlyrCivilian"
    if playindex == 8 then
        playerName = "PlyrCreeps"
    end
    if teamName == "ATTACK" or teamName == DEFAULTATTCKTEAM[playindex] then
        return true
    end
    for i = 1, 6, 1 do
        if teamName == "INFANTATTACK" .. i
            or teamName == playerName .. "/INFANTATTACK" .. i then
            return true
        end
    end
    return false
end

function FindNearestEnemyAnywhere(self, filter)
    local targets, count = ObjectFindObjects(self, nil, filter)
    local nearest = nil
    local nearestDistance = nil
    for i = 1, count, 1 do
        if ObjectIsAlive(targets[i]) then
            local distance = ObjectsDistance2D(self, targets[i])
            if nearestDistance == nil or distance < nearestDistance then
                nearest = targets[i]
                nearestDistance = distance
            end
        end
    end
    return nearest
end

g_TsunamiShieldEnemyRange = 300
g_TsunamiShieldScanIntervalFrames = 15 * 5
g_TsunamiShieldNextScanFrame = g_TsunamiShieldNextScanFrame or 0

-- 海啸坦克每 5 秒统一检测一次，只在自身作战射程内有敌人时尝试开启纳米护盾。
-- 技能本身的持续时间和冷却由单位模板控制。
function JapanTsunamiTankShieldMICROCONTROL ()
    local frame = GetFrame()
    if frame < g_TsunamiShieldNextScanFrame then
        return
    end
    g_TsunamiShieldNextScanFrame = frame + g_TsunamiShieldScanIntervalFrames

    for playindex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[playindex], nil, FilterJapanTsunamiTank)
        for i = 1, count, 1 do
            local self = units[i]
            local x, y, z = ObjectGetPosition(self)
            local enemies, enemyCount = ObjectFindObjects(self, {
                X=x, Y=y, Z=z,
                Radius=g_TsunamiShieldEnemyRange,
                DistType="CENTER_2D"
            }, FilterLAND)
            if enemyCount > 0 then
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, "Command_ToggleEnergizedArmorSpecialPower")
            end
        end
    end
end

g_AirHunterReacquireRange = 500
g_AirHunterTargetByUnitId = g_AirHunterTargetByUnitId or {}
g_AirHunterTransformCommandByInstanceId = {
    [FastHash("JapanAntiInfantryVehicle")] = "Command_JAIV_Transform",
    [FastHash("JapanAntiInfantryVehicle_Enhanced")] = "Command_JAIV_Transform",
    [FastHash("JapanMissileMechaAdvanced")] = "Command_JapanMissileMechaAdavanced_Transform",
    [FastHash("JapanMissileMechaAdvanced_Enhanced")] = "Command_JapanMissileMechaAdavanced_Transform",
}

-- 对空飞机分离出公共 AIRATTACK 编队：锁定最近空中目标并持续追踪，
-- 只在目标死亡、失效或超出作战射程时重新选择最近目标。
function AntiAirAircraftHunterMICROCONTROL ()
    for playindex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[playindex], nil, FilterAntiAirHunterAircraft)
        for i = 1, count, 1 do
            local self = units[i]
            if not IsAirMarshalAircraft(self) then
            local selfId = ObjectGetId(self)
            local teamName = ObjectTeamName(self)
            local idleTeamName = DEFAULTIDLETEAM[playindex]
            local idleTeamShortName = "teamPlyrCivilian"
            if playindex == 8 then
                idleTeamShortName = "teamPlyrCreeps"
            end
            local wasReassigned = teamName ~= idleTeamName and teamName ~= idleTeamShortName
            if wasReassigned then
                ExecuteAction("NAMED_STOP", self)
                ObjectSetAssignedTarget(self, nil)
                ExecuteAction("UNIT_SET_TEAM", self, idleTeamName)
            end

            local transformCommand = g_AirHunterTransformCommandByInstanceId[ObjectGetInstanceId(selfId)]
            local isAirborne = EvaluateCondition("UNIT_HAS_OBJECT_STATUS", self, "AIRBORNE_TARGET")
            if transformCommand ~= nil and not isAirborne then
                -- 天狗、心神的地面形态：有空中目标时重新起飞，
                -- 没有空中目标时留在地面并攻击最近地面单位。
                local nearestAir = FindNearestEnemyAnywhere(self, g_FilterOptimizedAirEnemy)
                if nearestAir ~= nil then
                    ExecuteAction("NAMED_STOP", self)
                    ObjectSetAssignedTarget(self, nil)
                    ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedAirEnemy)
                    ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, transformCommand)
                    g_AirHunterTargetByUnitId[selfId] = nil
                else
                    ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedGroundEnemy)
                    local target = ObjectGetTarget(self)
                    local targetIsValid = target ~= nil
                        and ObjectIsAlive(target)
                        and ObjectTestTargetObjectWithFilter(self, target, g_FilterOptimizedGroundEnemy)
                    if not targetIsValid then
                        local replacement = FindNearestEnemyAnywhere(self, g_FilterOptimizedGroundEnemy)
                        if replacement ~= nil then
                            ExecuteAction("NAMED_STOP", self)
                            ObjectSetAssignedTarget(self, replacement)
                            ExecuteAction("NAMED_ATTACK_NAMED", self, replacement)
                            g_AirHunterTargetByUnitId[selfId] = ObjectGetId(replacement)
                        else
                            if g_AirHunterTargetByUnitId[selfId] ~= nil then
                                ExecuteAction("NAMED_STOP", self)
                                ObjectSetAssignedTarget(self, nil)
                            end
                            g_AirHunterTargetByUnitId[selfId] = nil
                        end
                    else
                        g_AirHunterTargetByUnitId[selfId] = ObjectGetId(target)
                    end
                end
            else
                ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedAirEnemy)
                local target = ObjectGetTarget(self)
                local targetIsValid = target ~= nil
                    and ObjectIsAlive(target)
                    and ObjectTestTargetObjectWithFilter(self, target, g_FilterOptimizedAirEnemy)
                local targetIsOutOfRange = targetIsValid
                    and ObjectsDistance2D(self, target) > g_AirHunterReacquireRange

                if not targetIsValid or targetIsOutOfRange then
                    local replacement = FindNearestEnemyAnywhere(self, g_FilterOptimizedAirEnemy)
                    if replacement ~= nil then
                        local replacementId = ObjectGetId(replacement)
                        local currentTargetId = nil
                        if targetIsValid then
                            currentTargetId = ObjectGetId(target)
                        end
                        if currentTargetId ~= replacementId then
                            ObjectSetAssignedTarget(self, replacement)
                            ExecuteAction("NAMED_ATTACK_NAMED", self, replacement)
                        end
                        g_AirHunterTargetByUnitId[selfId] = replacementId
                    else
                        -- 天狗、心神清空空中目标后，改为寻找最近地面单位并落地。
                        local groundReplacement = nil
                        if transformCommand ~= nil then
                            groundReplacement = FindNearestEnemyAnywhere(self, g_FilterOptimizedGroundEnemy)
                        end
                        if groundReplacement ~= nil then
                            ExecuteAction("NAMED_STOP", self)
                            ObjectSetAssignedTarget(self, nil)
                            ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedGroundEnemy)
                            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, transformCommand)
                        elseif g_AirHunterTargetByUnitId[selfId] ~= nil then
                            ExecuteAction("NAMED_STOP", self)
                            ObjectSetAssignedTarget(self, nil)
                        end
                        g_AirHunterTargetByUnitId[selfId] = nil
                    end
                else
                    g_AirHunterTargetByUnitId[selfId] = ObjectGetId(target)
                end
            end
            end
        end
    end
end

-- 百合子禁止攻击建筑：有敌方单位时追击最近单位，
-- 全地图没有合法单位目标时把自身设为非法攻击目标，打断攻击前进并原地待命。
function CommandoNoStructureMICROCONTROL ()
    for playindex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[playindex], nil, FilterNoStructureCommando)
        for i = 1, count, 1 do
            local self = units[i]
            local selfId = ObjectGetId(self)
            -- 只在当前确实被放回进攻编队时分离，待命状态下不会重复换队。
            if IsCommandoInAttackTeam(self, playindex) then
                ExecuteAction("UNIT_SET_TEAM", self, DEFAULTIDLETEAM[playindex])
            end
            ObjectSetCustomTargetChooserData(self, {
                CustomFilter = g_FilterYurikoEnemy,
                CompareFilterList = {
                    g_FilterPrioritySiegeEnemyTank,
                    g_FilterYurikoEnemyAircraft,
                    g_FilterPrioritySiegeEnemyInfantry
                },
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(selfId, 0)
            local target = ObjectGetTarget(self)
            local hasValidTarget = target ~= nil
                and ObjectIsAlive(target)
                and ObjectTestTargetObjectWithFilter(self, target, g_FilterYurikoEnemy)
            if not hasValidTarget then
                local replacement = FindNearestEnemyAnywhere(self, g_FilterPrioritySiegeEnemyTank)
                if replacement == nil then
                    replacement = FindNearestEnemyAnywhere(self, g_FilterYurikoEnemyAircraft)
                end
                if replacement == nil then
                    replacement = FindNearestEnemyAnywhere(self, g_FilterPrioritySiegeEnemyInfantry)
                end
                if replacement ~= nil then
                    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", self, "NO_ATTACK", 0)
                    ObjectSetAssignedTarget(self, replacement)
                    ExecuteAction("NAMED_ATTACK_NAMED", self, replacement)
                else
                    -- 引擎层禁用武器，ATTACK 编队即使再次刷新命令也无法攻击建筑。
                    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", self, "NO_ATTACK", 1)
                    ObjectSetAssignedTarget(self, self)
                end
            else
                ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", self, "NO_ATTACK", 0)
            end
        end
    end
end

----exMessageAppendToMessageArea("定义过滤器")

-- 天狗和心神赶路/攻击空中目标时保持飞行形态；攻击地面目标时落地。
-- 空军清理完且当前没有目标时，只在附近仍有地面敌人的情况下落地继续作战。
function JapanIdleAirFormMICROCONTROL (unitFilter, transformCommand, updateTargetChooser)
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, unitFilter)
        for i = 1 , count , 1 do
            local self = SELF[i]
            local target = ObjectGetTarget(self)
            local hasTarget = target ~= nil and ObjectIsAlive(target)
            local targetIsAir = hasTarget and ObjectTestTargetObjectWithFilter(self, target, FilterAIR2)
            local x, y, z = ObjectGetPosition(self)
            local airTargets, airCount = ObjectFindObjects(self, {
                X=x, Y=y, Z=z, Radius=500, DistType="CENTER_2D"
            }, FilterAIR)
            local hasAirEnemyNearby = airCount > 0
            local hasGroundEnemyNearby = false
            if not hasTarget then
                local groundTargets, groundCount = ObjectFindObjects(self, {
                    X=x, Y=y, Z=z, Radius=500, DistType="CENTER_2D"
                }, FilterLAND)
                hasGroundEnemyNearby = groundCount > 0
            end
            local isAirborne = EvaluateCondition("UNIT_HAS_OBJECT_STATUS", self, "AIRBORNE_TARGET")
            -- 空军优先：附近有空军时立即起飞；没有空军且空闲时，附近有地面敌人才落地。
            local shouldBeAirborne = hasAirEnemyNearby
                or targetIsAir
                or (not hasTarget and not hasGroundEnemyNearby)

            if shouldBeAirborne and not isAirborne then
                if updateTargetChooser then
                    ObjectSetCustomTargetChooserData(self, {
                        CustomFilter = g_FilterOptimizedAirEnemy,
                        ReverseRangeCompare = true,
                        PreferTargetInsideRange = true
                    })
                    ObjectSetTargetChooserNextAutoAcquireDelay(self, 0)
                end
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, transformCommand)
            elseif not shouldBeAirborne and isAirborne then
                if updateTargetChooser then
                    ObjectSetCustomTargetChooserData(self, {
                        CustomFilter = g_FilterOptimizedGroundEnemy,
                        ReverseRangeCompare = true,
                        PreferTargetInsideRange = true
                    })
                    ObjectSetTargetChooserNextAutoAcquireDelay(self, 0)
                end
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, transformCommand)
            end
        end
    end
end

function JapanAntiInfantryVehicleMICROCONTROL ()
    JapanIdleAirFormMICROCONTROL(FilterJapanAntiInfantryVehicle, "Command_JAIV_Transform")
end

function JapanMissileMechaAdvancedMICROCONTROL ()
    JapanIdleAirFormMICROCONTROL(FilterJapanMissileMechaAdvanced, "Command_JapanMissileMechaAdavanced_Transform", true)
end

-- 炮车只使用单体攻击前进：有坦克时忽略步兵继续追击；无坦克时恢复常规优先级。
-- 任意状态下，700 范围内有建筑就停止前进并原地开火；建筑消失后恢复推进，新塔出现时再次停止。
function PrioritySiegeAttackMoveMICROCONTROL ()
    for playindex = 7, 8, 1 do
        local enemyTanks, enemyTankCount = ObjectFindObjects(P[playindex], nil, g_FilterPrioritySiegeEnemyTank)
        local enemyTankExists = enemyTankCount > 0
        g_PrioritySiegeTankPursuitActive[playindex] = enemyTankExists

        local siegeUnits, siegeUnitCount = ObjectFindObjects(P[playindex], nil, FilterPrioritySiegeVehicle)
        for i = 1, siegeUnitCount, 1 do
            local siegeUnit = siegeUnits[i]
            local teamName = ObjectTeamName(siegeUnit)
            local idleTeamName = g_PrioritySiegeIdleTeam[playindex]
            local idleTeamShortName = "teamPlyrCivilian"
            if playindex == 8 then
                idleTeamShortName = "teamPlyrCreeps"
            end
            local wasReassigned = teamName ~= idleTeamName and teamName ~= idleTeamShortName
            if wasReassigned then
                ExecuteAction("UNIT_SET_TEAM", siegeUnit, idleTeamName)
            end
            local siegeUnitId = ObjectGetId(siegeUnit)
            local desiredMode = GetPrioritySiegeUnitMode(siegeUnit, enemyTankExists)
            local stateChanged = g_PrioritySiegeUnitMode[siegeUnitId] ~= desiredMode
            if stateChanged or wasReassigned then
                -- 同一条攻击前进指令可能沿用旧模式的内部攻击上下文；先停下并清空配置再重建。
                ExecuteAction("NAMED_STOP", siegeUnit)
                ObjectSetCustomTargetChooserData(siegeUnit, nil)
                SetPrioritySiegeTargetChooserMode(siegeUnit, desiredMode == "TANK_PURSUIT")
                g_PrioritySiegeUnitMode[siegeUnitId] = desiredMode
                -- 建筑存在时驻停；建筑消失后恢复向敌方方向攻击前进。
                if desiredMode ~= "STRUCTURE_HOLD" then
                    ExecuteAction("ATTACK_MOVE_NAMED_UNIT_TO", siegeUnit, g_PrioritySiegeAttackWaypoint[playindex])
                end
            end
        end
    end
end

function FindNearestTargetFromList(self, targets, count)
    local nearest = nil
    local nearestDistance = nil
    for i = 1, count, 1 do
        if ObjectIsAlive(targets[i]) then
            local distance = ObjectsDistance2D(self, targets[i])
            if nearestDistance == nil or distance < nearestDistance then
                nearest = targets[i]
                nearestDistance = distance
            end
        end
    end
    return nearest
end

function ClearVXTarget(self)
    ExecuteAction("NAMED_STOP", self)
    ObjectSetAssignedTarget(self, nil)
end

function AssignVXNearestTarget(self, targets, count)
    local replacement = FindNearestTargetFromList(self, targets, count)
    if replacement ~= nil then
        ObjectSetAssignedTarget(self, replacement)
        ExecuteAction("NAMED_ATTACK_NAMED", self, replacement)
    end
end

function JapanAntiAirVehicleTech1MICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanAntiAirVehicleTech1)
        for i = 1 , count , 1 do
            local self = SELF[i]
            local isAirborne = EvaluateCondition("UNIT_HAS_OBJECT_STATUS", self, "AIRBORNE_TARGET")
            local x0, y0, z0 = ObjectGetPosition(self)
            local airTargets, airTargetCount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterAIR2)
            local groundTargets, groundTargetCount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=400, DistType="CENTER_2D"
            }, FilterLAND)
            local currentTarget = ObjectGetTarget(self)

            if not isAirborne then
                -- 地面形态优先对空；旧飞机目标离开 500 范围后立即清除，不再追出射程。
                ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedAirEnemy)
                local currentAirTargetIsValid = currentTarget ~= nil
                    and ObjectIsAlive(currentTarget)
                    and ObjectTestTargetObjectWithFilter(self, currentTarget, g_FilterOptimizedAirEnemy)
                    and ObjectsDistance2D(self, currentTarget) <= 500

                if airTargetCount > 0 then
                    if not currentAirTargetIsValid then
                        ClearVXTarget(self)
                        AssignVXNearestTarget(self, airTargets, airTargetCount)
                    end
                elseif groundTargetCount > 0 then
                    -- 附近无飞机时放弃旧对空目标，再切换为飞行形态对地。
                    if currentTarget ~= nil then
                        ClearVXTarget(self)
                    end
                    ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedGroundEnemy)
                    ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, "Command_JAAVT1_Transform")
                elseif currentTarget ~= nil then
                    ClearVXTarget(self)
                end
            else
                -- 飞行形态发现飞机时降落对空；否则只在 400 范围内重新选择最近地面目标。
                if airTargetCount > 0 then
                    if currentTarget ~= nil then
                        ClearVXTarget(self)
                    end
                    ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedAirEnemy)
                    ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, "Command_JAAVT1_Transform")
                else
                    ConfigureNearestNoChaseTargetChooser(self, g_FilterOptimizedGroundEnemy)
                    local currentGroundTargetIsValid = currentTarget ~= nil
                        and ObjectIsAlive(currentTarget)
                        and ObjectTestTargetObjectWithFilter(self, currentTarget, g_FilterOptimizedGroundEnemy)
                        and ObjectsDistance2D(self, currentTarget) <= 400
                    if groundTargetCount > 0 then
                        if not currentGroundTargetIsValid then
                            ClearVXTarget(self)
                            AssignVXNearestTarget(self, groundTargets, groundTargetCount)
                        end
                    elseif currentTarget ~= nil then
                        ClearVXTarget(self)
                    end
                end
            end
        end
    end
end

--TARcountLAND > 0 and not  EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET")


function JapanFortressShipMICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanFortressShip)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if  not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") and EvaluateCondition("UNIT_TEST_OBJECT_PANEL_FLAGS", SELF[i] , "Selectable") then
                ----exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_ToggleJapanFortressShipTransformMode" )
            end
        end
    end
end

function JapanAntiAirShipMICROCONTROL ()
    -- 启用海军时海翼保持潜艇形态并留在海军编队。
    if g_DisableSeaArmy == 0 then
        return
    end
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanAntiAirShip)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if  not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET")  then
                ----exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JAAS_Transform" )
            end
        end
    end
end


function SovietScoutVehicleMICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterSovietScoutVehicle)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if  not EvaluateCondition("UNIT_HAS_MODELCONDITION", SELF[i] , "USER_4")  then
                ----exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_ToggleBinaryWeapon" )
            end
        end
    end
end

function CelestialAntiAirShipMICROCONTROL ()
    --exMessageAppendToMessageArea("执行")
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterCelestialAntiAirShip)
        --exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterAIR)
            --exMessageAppendToMessageArea("TARcount"..TARcount)
            if TARcount > 0 and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "TRANSFORMATION_TOGGLE_STATE") then
                --  --exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "CommandCelestialAntiAirVehicleTransform" )
            elseif  TARcount == 0  and not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "TRANSFORMATION_TOGGLE_STATE") then
                -- --exMessageAppendToMessageArea("降落")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "CommandCelestialAntiAirVehicleTransform" )
            end
        end
    end
end

function CelestialAntiVehicleVehicleTech1MICROCONTROL ()
    --exMessageAppendToMessageArea("执行")
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterCelestialAntiVehicleVehicleTech1)
        -- exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "TRANSFORMATION_TOGGLE_STATE") then
                --  --exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_ToggleRangeUpdateCelestial" )
            end
        end
    end
end


function CelestialAdvanceAircraftTech4MICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterCelestialAdvanceAircraftTech4)
        ----exMessageAppendToMessageArea("count"..count)
        local targetindex = 1
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=700, DistType="CENTER_2D"
            }, FilterALLENEMYUNIT)
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if TARcount > 0  then
                ExecuteAction("NAMED_ATTACK_NAMED", SELF[i] , TAR[targetindex])
                targetindex= targetindex + 1 ;
                if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "TRANSFORMATION_TOGGLE_STATE")  then
                    ----exMessageAppendToMessageArea("起飞")
                    ExecuteAction("UNIT_SET_TEAM", SELF[i] , DEFAULTATTCKTEAM[playindex])
                    ObjectLoadAttributeModifier(SELF[i], "AttributeModifier_CelestialZhuRongRapidFire",9999)
                    ObjectLoadAttributeModifier(SELF[i], "AttributeModifier_CelestialInterceptorRapidFire",9999)
                    ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(SELF[i], 1, 1, 10, 10)
                    ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_CAAT4_Transform" )
                end
            elseif  TARcount == 0  and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "TRANSFORMATION_TOGGLE_STATE") then
                ----exMessageAppendToMessageArea("降落")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_CAAT4_Transform" )
            end
        end
    end
end

g_FilterOnlyOverWater = CreateObjectFilter({
    Rule="ALL",
    StatusBitFlags="OVER_WATER"
})
g_LastJapanAntiNavyShipTech3Id_ForCustomTargetChooserData = 0
function JapanAntiNavyShipTech3MICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanAntiNavyShipTech3)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            local selfId = ObjectGetId(SELF[i])
            local countdown = exObjectGetSpecialCountDownFrame(selfId, "SpecialPower_JANSTier3CombatMode")
            if countdown ~= nil and countdown > 750 then
                -- 不能让太刀无限制使用技能，让它冷却一下吧
            else
                ObjectUnloadAttributeModifier(selfId, "AttributeModifier_JANSTier3CombatMode")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i], "Command_JANSTier3CombatMode")
                if selfId > g_LastJapanAntiNavyShipTech3Id_ForCustomTargetChooserData then
                    -- ID 是单调递增的，所以只要 ID 大于上次记录的 ID，就说明是新生成的单位
                    -- 为它设置索敌信息
                    ObjectSetCustomTargetChooserData(selfId, {
                        CustomFilter = g_FilterOnlyOverWater
                    })
                    -- 更新最后记录的 ID
                    g_LastJapanAntiNavyShipTech3Id_ForCustomTargetChooserData = selfId
                end
                ObjectSetTargetChooserNextAutoAcquireDelay(selfId, 0)
            end
        end
    end
end
