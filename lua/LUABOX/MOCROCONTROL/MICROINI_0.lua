-- 讲解见 analysis/地图注释说明文档.md 附录 A.43

if g_SideFindObjects == nil then
    function g_SideFindObjects(sideIndex, pos, filter)
        local anchor = nil
        if sideIndex == 7 then
            anchor = GetObjectByScriptName("PlyrCivilian")
        elseif sideIndex == 8 then
            anchor = GetObjectByScriptName("PlyrCreeps")
        elseif P ~= nil then
            anchor = P[sideIndex]
        end
        if anchor == nil then
            return {}, 0
        end
        local list, count = ObjectFindObjects(anchor, pos, filter)
        if list == nil then
            list = {}
        end
        if type(count) ~= "number" then
            count = getn(list)
        end
        return list, count
    end
end

-- 同上的最小版：只给中间 AI 阵营（PlyrCivilian / PlyrCreeps）自己的单位换队伍。
if g_SetSideTeam == nil then
    function g_SetSideTeam(unit, teamName)
        if teamName == nil then
            return
        end
        local ownerName = ObjectPlayerScriptName(unit)
        if ownerName == "PlyrCivilian" or ownerName == "PlyrCreeps" then
            ExecuteAction("UNIT_SET_TEAM", unit, teamName)
        end
    end
end

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

FilterJapanAntiVehicleShip=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "JapanAntiVehicleShip","JapanAntiVehicleShip_Enhanced"
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
        "SovietHeavyMortarVehicle","VUMissileAntiVehicleVehicleTech1",
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

-- 太刀（JapanAntiNavyShipTech3）专用过滤器与微操已整体停用，见下方 JapanAntiNavyShipTech3MICROCONTROL。
-- FilterJapanAntiNavyShipTech3=CreateObjectFilter({
--     Rule="ANY",
--     Relationship="SAME_PLAYER",
--     IncludeThing = {
--         "JapanAntiNavyShipTech3"
--     }
-- })

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
    for i = 1, 8, 1 do
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
        local units, count = g_SideFindObjects(playindex, nil, FilterJapanTsunamiTank)
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

-- 剃刀巡洋舰：附近有非空中敌人时尝试开 F，AI 不会自己开 F，只能由这里周期触发。
-- 现在把闸门放到 50 秒（15 帧 = 1 秒 → 750 帧），实际周期从 40 秒拉到 50 秒。
-- 闸门是整个阵营共用一个 nextScanFrame。
g_TorpedoShipSpreadEnemyRange = 900
g_TorpedoShipSpreadScanIntervalFrames = 15 * 50
g_TorpedoShipSpreadNextScanFrame = g_TorpedoShipSpreadNextScanFrame or 0

function JapanTorpedoShipSpreadMICROCONTROL ()
    local frame = GetFrame()
    if frame < g_TorpedoShipSpreadNextScanFrame then
        return
    end
    g_TorpedoShipSpreadNextScanFrame = frame + g_TorpedoShipSpreadScanIntervalFrames

    for playindex = 7, 8, 1 do
        local units, count = g_SideFindObjects(playindex, nil, FilterJapanAntiVehicleShip)
        for i = 1, count, 1 do
            local self = units[i]
            local x, y, z = ObjectGetPosition(self)
            local enemies, enemyCount = ObjectFindObjects(self, {
                X=x, Y=y, Z=z,
                Radius=g_TorpedoShipSpreadEnemyRange,
                DistType="CENTER_2D"
            }, FilterLAND)
            if enemyCount > 0 then
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self,
                    "Command_ActivateTorpedoSpread")
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
        local units, count = g_SideFindObjects(playindex, nil, FilterAntiAirHunterAircraft)
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
                g_SetSideTeam(self, idleTeamName)
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

-- 百合子禁止攻击建筑：独立队列——被进攻编队收走就立刻抢回 idle 队，
function CommandoNoStructureMICROCONTROL ()
    if g_PrioritySiegeIdleTeam == nil or g_PrioritySiegeAttackWaypoint == nil then
        return
    end
    for playindex = 7, 8, 1 do
        local units, count = g_SideFindObjects(playindex, nil, FilterNoStructureCommando)
        for i = 1, count, 1 do
            local self = units[i]
            local selfId = ObjectGetId(self)
            -- 只在当前确实被放回进攻编队时分离，待命状态下不会重复换队。
            if IsCommandoInAttackTeam(self, playindex) then
                g_SetSideTeam(self, g_PrioritySiegeIdleTeam[playindex])
                -- 离了主力编队就没人给她下推进命令，自己朝敌方 waypoints 攻击前进。
                ExecuteAction("ATTACK_MOVE_NAMED_UNIT_TO", self,
                    g_PrioritySiegeAttackWaypoint[playindex])
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
        end
    end
end

----exMessageAppendToMessageArea("定义过滤器")

-- 天狗和心神赶路/攻击空中目标时保持飞行形态；攻击地面目标时落地。
-- 空军清理完且当前没有目标时，只在附近仍有地面敌人的情况下落地继续作战。
function JapanIdleAirFormMICROCONTROL (unitFilter, transformCommand, updateTargetChooser)
    for playindex = 7 , 8 , 1 do
        local SELF, count = g_SideFindObjects(playindex, nil, unitFilter)
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
    -- UnitCreate 初始化若尚未完成，先跳过本帧，避免微操循环访问未创建的共享表。
    if g_FilterPrioritySiegeEnemyTank == nil
        or g_PrioritySiegeTankPursuitActive == nil
        or g_PrioritySiegeUnitMode == nil
        or g_PrioritySiegeIdleTeam == nil
        or g_PrioritySiegeAttackWaypoint == nil then
        return
    end
    for playindex = 7, 8, 1 do
        local enemyTanks, enemyTankCount = g_SideFindObjects(playindex, nil, g_FilterPrioritySiegeEnemyTank)
        local enemyTankExists = enemyTankCount > 0
        g_PrioritySiegeTankPursuitActive[playindex] = enemyTankExists

        local siegeUnits, siegeUnitCount = g_SideFindObjects(playindex, nil, FilterPrioritySiegeVehicle)
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
                g_SetSideTeam(siegeUnit, idleTeamName)
            end
            local siegeUnitId = ObjectGetId(siegeUnit)
            -- 被登神/究极生物圈中的炮车归脚本压目标那条线管（附录 A.63）：
            local ownedByRune = g_NoStructureBuffUnitIds ~= nil
                and g_NoStructureBuffUnitIds[siegeUnitId] ~= nil
            local desiredMode = GetPrioritySiegeUnitMode(siegeUnit, enemyTankExists)
            local stateChanged = g_PrioritySiegeUnitMode[siegeUnitId] ~= desiredMode
            if (stateChanged or wasReassigned) and not ownedByRune then
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterJapanAntiAirVehicleTech1)
        for i = 1 , count , 1 do
            local self = SELF[i]
            local isAirborne = EvaluateCondition("UNIT_HAS_OBJECT_STATUS", self, "AIRBORNE_TARGET")
            local x0, y0, z0 = ObjectGetPosition(self)
            local airTargets, airTargetCount = g_SideFindObjects(playindex, {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterAIR2)
            local groundTargets, groundTargetCount = g_SideFindObjects(playindex, {
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterJapanFortressShip)
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterJapanAntiAirShip)
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterSovietScoutVehicle)
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterCelestialAntiAirShip)
        --exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = g_SideFindObjects(playindex, {
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterCelestialAntiVehicleVehicleTech1)
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
        local SELF, count = g_SideFindObjects(playindex, nil, FilterCelestialAdvanceAircraftTech4)
        ----exMessageAppendToMessageArea("count"..count)
        local targetindex = 1
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = g_SideFindObjects(playindex, {
                X=x0, Y=y0, Z=z0, Radius=700, DistType="CENTER_2D"
            }, FilterALLENEMYUNIT)
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if TARcount > 0  then
                ExecuteAction("NAMED_ATTACK_NAMED", SELF[i] , TAR[targetindex])
                targetindex= targetindex + 1 ;
                if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "TRANSFORMATION_TOGGLE_STATE")  then
                    ----exMessageAppendToMessageArea("起飞")
                    g_SetSideTeam(SELF[i], DEFAULTATTCKTEAM[playindex])
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

-- 太刀微操已整体停用（2026-10-19）：自动施放 F 技能（Command_JANSTier3CombatMode）
-- 与“只索敌水面目标”的自定义索敌逻辑全部注释，恢复时取消本段注释即可。
-- g_FilterOnlyOverWater = CreateObjectFilter({
--     Rule="ALL",
--     StatusBitFlags="OVER_WATER"
-- })
-- g_LastJapanAntiNavyShipTech3Id_ForCustomTargetChooserData = 0
-- function JapanAntiNavyShipTech3MICROCONTROL ()
--     for playindex = 7 , 8 , 1 do
--         local SELF, count = g_SideFindObjects(playindex, nil, FilterJapanAntiNavyShipTech3)
--         ----exMessageAppendToMessageArea("count"..count)
--         for i = 1 , count , 1 do
--             local selfId = ObjectGetId(SELF[i])
--             local countdown = exObjectGetSpecialCountDownFrame(selfId, "SpecialPower_JANSTier3CombatMode")
--             if countdown ~= nil and countdown > 750 then
--                 -- 不能让太刀无限制使用技能，让它冷却一下吧
--             else
--                 ObjectUnloadAttributeModifier(selfId, "AttributeModifier_JANSTier3CombatMode")
--                 ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i], "Command_JANSTier3CombatMode")
--                 if selfId > g_LastJapanAntiNavyShipTech3Id_ForCustomTargetChooserData then
--                     -- ID 是单调递增的，所以只要 ID 大于上次记录的 ID，就说明是新生成的单位
--                     -- 为它设置索敌信息
--                     ObjectSetCustomTargetChooserData(selfId, {
--                         CustomFilter = g_FilterOnlyOverWater
--                     })
--                     -- 更新最后记录的 ID
--                     g_LastJapanAntiNavyShipTech3Id_ForCustomTargetChooserData = selfId
--                 end
--                 ObjectSetTargetChooserNextAutoAcquireDelay(selfId, 0)
--             end
--         end
--     end
-- end

-- 海军优先索敌：敌舰 > 敌方建筑(海塔) > 其余默认
-- 滤网与出生钩子在这里，出生登记在 UnitCreate.lua 的海军段循环里。
g_FilterNavalPriorityEnemyShip=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="SHIP",
    Exclude="IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

-- 第二档：海塔。地编脚本名 T71F~T73F / T81F~T83F 只能按对象查，过滤器只认模板与 KindOf，
g_FilterNavalPriorityEnemyStructure=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="STRUCTURE",
    Exclude="IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE"
})

g_NavalPriorityUnitHashes = g_NavalPriorityUnitHashes or {}

function NavalPriorityTargetChooserBorn (createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ObjectSetCustomTargetChooserData(GetObjectById(id), {
                CompareFilterList = {
                    g_FilterNavalPriorityEnemyShip,
                    g_FilterNavalPriorityEnemyStructure
                },
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(id, 0)
        end
    end, 1, {createdObjId})
end

-- 登神/究极生物点名的「别打」名单（下面三张滤网共用）：
g_NoStructureBuffExcludeThingNames = {
    -- 塔守护神 / 守护者形态（BasicVar1: GuardianFormTemplate）
    "Overlordtank", "JapanFortressShip", "JapanigaFortressShip",
    -- 龙船（BasicVar1: DragonShip）
    "CelestialMCV", "CelestialMCV_Enhanced", "CelestialMCV_Ground",
    "CelestialMCV_Naval", "CelestialMCV_Air", "CelestialMCV_Enhanced_Ground",
    "CelestialMCV_Enhanced_Naval", "CelestialMCV_Enhanced_Air",
    -- 超级要塞全家
    "JapanGigaFortressShipEgg", "JapanGigaFortressShip", "JapanGigaFortress_Land",
    -- 地编摆放在双方基地的 AI 锚点基地车（BasicVar1: g_TargetGroupNames.AIAnchorMCV）
    "AlliedMCV", "AlliedMCV_Enhanced", "AlliedMCV_Naval", "AlliedMCV_Enhanced_Naval",
}

-- 登神/究极生物的目标单位：只打单位，不碰任何建筑。
-- 滤网与百合子的 g_FilterYurikoEnemy 分开定义，两边的索敌调参互不影响。
g_FilterNoStructureBuffEnemy=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="INFANTRY VEHICLE HUGE_VEHICLE AIRCRAFT SHIP",
    Exclude="STRUCTURE IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE",
    ExcludeThing=g_NoStructureBuffExcludeThingNames
})

-- 按对象 ID 登记，不写模板名：这两张符文的目标单位每局随机，列不出固定名单。
g_NoStructureBuffUnitIds = g_NoStructureBuffUnitIds or {}
g_FilterNoStructureBuffedEnemy = g_FilterNoStructureBuffEnemy

-- 登神/究极生物的舰船优先打敌舰用的名单：只认水面目标，同样不含建筑（见 A.63.8）。
g_FilterNoStructureBuffNavalShipEnemy=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="SHIP",
    Exclude="STRUCTURE IGNORE_IN_AI_HUNT_TACTIC DEBRIS UNATTACKABLE NOT_AUTOACQUIRABLE",
    ExcludeThing=g_NoStructureBuffExcludeThingNames
})

-- 编队名里带 SHIP 就是海军（SHIPTEAM / SHIPATTACK / PlyrCreeps/SHIPATTACK）。
-- 登记那一刻单位还站在主力队里，按队名判定最稳（见附录 E.16）。
function IsNavalTeamName(teamName)
    if teamName == nil then
        return false
    end
    return strfind(teamName, "SHIP") ~= nil
end

-- 同一只单位的索敌只能有一个主人，她若被圈中就整只交回她自己的微操。
g_NoStructureBuffSkipInstanceIds = { [FastHash("JapanCommandoTech1")] = true }

function RegisterNoStructureBuffUnit(unit, sideIndex)
    if unit == nil or sideIndex == nil then
        return
    end
    local instanceId = ObjectGetInstanceId(unit)
    if instanceId ~= nil and ObjectIsAlive(unit)
        and g_NoStructureBuffSkipInstanceIds[instanceId] == nil then
        g_NoStructureBuffUnitIds[ObjectGetId(unit)] = {
            SideIndex = sideIndex,
            -- 圈中的是四类炮车 ⇒ 保留它自己的「载具＞步兵」，只是不打建筑（见 A.63）。
            IsSiege = IsPrioritySiegeUnit(unit, sideIndex),
            -- 舰船 ⇒ 压目标时先找敌舰，其次就近（见 A.63.8）。
            IsNaval = IsNavalTeamName(ObjectTeamName(unit))
        }
    end
end


-- 运行期取对象模板名：UNITCOUNTERINI_0 里 g_UnitNameToUnitIndex 同时按名字和 FastHash
function GetNoStructureBuffUnitTypeName(unit)
    if unit == nil or UNITLIST == nil or g_UnitNameToUnitIndex == nil then
        return nil
    end
    local instanceId = ObjectGetInstanceId(unit)
    if instanceId == nil then
        return nil
    end
    local unitIndex = g_UnitNameToUnitIndex[instanceId]
    if unitIndex == nil then
        return nil
    end
    return UNITLIST[unitIndex]
end

g_NoStructureBuffSkipUnitTypes = {
    ["AlliedMCV"] = true,
    ["AlliedMCV_Enhanced"] = true,
    ["AlliedMCV_Naval"] = true,
    ["AlliedMCV_Enhanced_Naval"] = true,
}

-- 六个预设守护神（overlord7/8、t533/t534、Sea3ProtectShip7/8，按脚本名/对象 id 判）、
-- 技能召唤单位（按对象 id 判）、地编锚点基地车（按模板名判）。
function IsNoStructureBuffForbiddenTarget(unit)
    if unit == nil then
        return true
    end
    local objectId = ObjectGetId(unit)
    if g_IsPresetGuardianUnitId ~= nil and g_IsPresetGuardianUnitId(objectId) then
        return true
    end
    if IsSkillSummonedUnitId ~= nil and IsSkillSummonedUnitId(objectId) then
        return true
    end
    local unitType = GetNoStructureBuffUnitTypeName(unit)
    if unitType ~= nil and g_NoStructureBuffSkipUnitTypes[unitType] == true then
        return true
    end
    return false
end

-- ===== 登神 / 究极生物的脚本压目标（机制与实测见附录 A.63）=====
g_NoStructureBuffAssign = g_NoStructureBuffAssign or {}
-- 候选按「帧 + 阵营」缓存：同一拍里所有登记单位共用，避免每只单位各扫一遍全图。
g_NoStructureBuffCandidateCache = g_NoStructureBuffCandidateCache or {
    Frame = nil, BySide = {}
}
-- 压目标后给引擎两拍（≈0.4 秒）接手时间，超时才判定「打不了」。
g_NoStructureBuffPressGraceFrames = 6
-- 撤掉一个不该打的目标后，让引擎静默多久再自动索敌（30 帧 = 1 秒）。
g_NoStructureBuffVetoAcquireDelayFrames = 30

function GetNoStructureBuffKindFilter(kind)
    if kind == "tank" then
        return g_FilterPrioritySiegeEnemyTank
    elseif kind == "infantry" then
        return g_FilterPrioritySiegeEnemyInfantry
    elseif kind == "ship" then
        -- 舰船的第一档：只认水面目标。
        return g_FilterNoStructureBuffNavalShipEnemy
    elseif kind == "any" then
        -- 就近目标用的候选集合：单位全收、建筑全剔（登神/究极生物拆塔太快，
        -- 而轰炸机的保底目标是允许炸建筑的，两边的滤网刻意不同）。
        return g_FilterNoStructureBuffEnemy
    end
    return g_FilterYurikoEnemyAircraft
end

-- 「any」这一档挑出来的目标要归到具体兵种，才好在引擎拒收时只拉黑那一类。
-- 按帧 + 阵营缓存一张「对象 ID → 兵种」表，避免每个候选都去扫一遍列表。
function GetNoStructureBuffKindById(sideIndex)
    local cache = g_NoStructureBuffCandidateCache
    local frame = GetFrame()
    if cache.Frame ~= frame then
        cache.Frame = frame
        cache.BySide = {}
    end
    local side = cache.BySide[sideIndex]
    if side == nil then
        side = {}
        cache.BySide[sideIndex] = side
    end
    if side.KindById == nil then
        local kindById = {}
        local kinds = { "tank", "infantry", "air", "ship" }
        for i = 1, getn(kinds), 1 do
            local targets, count = GetNoStructureBuffCandidates(sideIndex, kinds[i])
            if targets ~= nil and count ~= nil then
                for j = 1, count, 1 do
                    kindById[ObjectGetId(targets[j])] = kinds[i]
                end
            end
        end
        side.KindById = kindById
    end
    return side.KindById
end

function GetNoStructureBuffCandidates(sideIndex, kind)
    local cache = g_NoStructureBuffCandidateCache
    local frame = GetFrame()
    if cache.Frame ~= frame then
        cache.Frame = frame
        cache.BySide = {}
    end
    local side = cache.BySide[sideIndex]
    if side == nil then
        side = {}
        cache.BySide[sideIndex] = side
    end
    local entry = side[kind]
    if entry == nil then
        local filter = GetNoStructureBuffKindFilter(kind)
        if filter == nil then
            entry = { Units = {}, Count = 0 }
        else
            local units, count = g_SideFindObjects(sideIndex, nil, filter)
            entry = { Units = units, Count = count }
        end
        side[kind] = entry
    end
    return entry.Units, entry.Count
end

-- 登记时判一次「是不是四类炮车」：炮车有自己的索敌优先级（载具＞步兵）。
function IsPrioritySiegeUnit(unit, sideIndex)
    if FilterPrioritySiegeVehicle == nil or unit == nil or sideIndex == nil then
        return false
    end
    local units, count = g_SideFindObjects(sideIndex, nil, FilterPrioritySiegeVehicle)
    local unitId = ObjectGetId(unit)
    for i = 1, count, 1 do
        if ObjectGetId(units[i]) == unitId then
            return true
        end
    end
    return false
end

-- 按档位找最近的一只：整档空才看下一档（「载具＞步兵」就是这个语义）。
function FindNoStructureBuffTarget(unit, sideIndex, order, rejected)
    for i = 1, getn(order), 1 do
        local rung = order[i]
        if rejected == nil or rejected[rung] ~= true then
            local targets, count = GetNoStructureBuffCandidates(sideIndex, rung)
            local kindById = nil
            if rung == "any" then
                kindById = GetNoStructureBuffKindById(sideIndex)
            end
            local best = nil
            local bestKind = rung
            local bestDistance = nil
            if targets ~= nil and count ~= nil then
                for j = 1, count, 1 do
                    local candidate = targets[j]
                    local candidateId = ObjectGetId(candidate)
                    local candidateKind = rung
                    local allowed = ObjectIsAlive(candidate)
                    if allowed and IsNoStructureBuffForbiddenTarget(candidate) then
                        allowed = false
                    end
                    if allowed and kindById ~= nil then
                        -- 就近目标这一档：打不了的兵种（上一拍被拉黑）直接跳过，
                        -- 免得把最近的名额浪费在它身上、还要再等两拍才发现。
                        candidateKind = kindById[candidateId]
                        if candidateKind == nil then
                            candidateKind = "other"
                        end
                        if rejected ~= nil and rejected[candidateKind] == true then
                            allowed = false
                        end
                    end
                    if allowed then
                        local distance = ObjectsDistance2D(unit, candidate)
                        if bestDistance == nil or distance < bestDistance then
                            best = candidate
                            bestKind = candidateKind
                            bestDistance = distance
                        end
                    end
                end
            end
            if best ~= nil then
                return best, bestKind
            end
        end
    end
    return nil, nil
end

function UpdateNoStructureBuffTarget(unit, objectId, sideIndex, isSiege,
    isNaval)
    local record = g_NoStructureBuffAssign[objectId]
    if record == nil then
        record = { Rejected = {} }
        g_NoStructureBuffAssign[objectId] = record
    end
    -- 引擎自己已有目标：保持不抢（原生索敌同样按本单位武器挑合法目标）。
    local current = ObjectGetTarget(unit)
    if current ~= nil and ObjectIsAlive(current) then
        record.PressedId = nil
        record.PressedKind = nil
        record.PressFrame = nil
        return
    end
    -- 复核上一拍压过的目标：还活着 ⇒ 引擎不肯打这一类，拉黑换档；已死 ⇒ 打掉了，正常重选。
    if record.PressedId ~= nil then
        local pressedKind = record.PressedKind
        local pressFrame = record.PressFrame
        local pressed = GetObjectById(record.PressedId)
        if pressed == nil or not ObjectIsAlive(pressed) then
            -- 目标已经没了：打掉了，正常重选，不算拉黑。
            record.PressedId = nil
            record.PressedKind = nil
            record.PressFrame = nil
        elseif pressFrame ~= nil
            and GetFrame() - pressFrame < g_NoStructureBuffPressGraceFrames then
            -- 刚压下去不到两拍，引擎可能还没接手：这一拍先等（保留 PressedId，
            -- 下一拍重新判定，超过宽限期才拉黑）。
            return
        else
            -- 引擎两拍都不接手 ⇒ 这只单位打不了这一类，拉黑换下一档。
            if pressedKind ~= nil then
                record.Rejected[pressedKind] = true
            end
            record.PressedId = nil
            record.PressedKind = nil
            record.PressFrame = nil
        end
    end
    -- 档位：只有炮车和舰船有特殊优先级，其余单位一律「就近目标」——
    -- 候选集合已经剔掉建筑，所以就近只是「最近的一个能打的单位」。
    local order = { "any" }
    if isSiege then
        -- 炮车原优先级：载具 ＞ 步兵。
        order = { "tank", "infantry", "any" }
    elseif isNaval then
        -- 舰船：敌舰 ＞ 就近。不加这一档，最近的若是岸上载具/步兵，船就跑去打陆军了。
        order = { "ship", "any" }
    end
    local target, kind = FindNoStructureBuffTarget(unit, sideIndex, order,
        record.Rejected)
    if target == nil then
        return
    end
    record.PressedId = ObjectGetId(target)
    record.PressedKind = kind
    record.PressFrame = GetFrame()
    ObjectSetAssignedTarget(unit, target)
    ExecuteAction("NAMED_ATTACK_NAMED", unit, target)
end

function NoStructureBuffedUnitMICROCONTROL ()
    if g_PrioritySiegeIdleTeam == nil or g_NoStructureBuffUnitIds == nil then
        return
    end
    -- 陆军与舰船共用同一套：摘进 idle 队 → 刷索敌器（排除建筑）→ 每 3 帧由脚本压目标。
    for objectId, entry in g_NoStructureBuffUnitIds do
        local unit = GetObjectById(objectId)
        if unit == nil or not ObjectIsAlive(unit) then
            -- 引擎会复用对象 ID，登记不清理就会让新单位白拿免拆塔。
            g_NoStructureBuffUnitIds[objectId] = nil
            g_NoStructureBuffAssign[objectId] = nil
        else
            local sideIndex = entry.SideIndex
            local idleTeamName = g_PrioritySiegeIdleTeam[sideIndex]
            local idleTeamShortName = "teamPlyrCivilian"
            if sideIndex == 8 then
                idleTeamShortName = "teamPlyrCreeps"
            end
            local teamName = ObjectTeamName(unit)
            -- 摘进 idle 队以后队名就认不出船了，所以以登记时记下的为准。
            local isNavalUnit = entry.IsNaval == true
                or IsNavalTeamName(teamName)
            if teamName ~= idleTeamName and teamName ~= idleTeamShortName then
                g_SetSideTeam(unit, idleTeamName)
                -- idle 队的姿态不是进攻姿态（附录 E.14）；推进全靠脚本压目标，必须补进攻姿态。
                ExecuteAction("UNIT_SET_STANCE", unit, 1)
            end
            -- 索敌器：每拍刷一次，建筑一律不进候选；炮车加回「载具＞步兵」的原优先级。
            local targetChooserData = {
                CustomFilter = g_FilterNoStructureBuffEnemy,
                ReverseRangeCompare = false,
                PreferTargetInsideRange = true
            }
            if entry.IsSiege == true and g_FilterPrioritySiegeEnemyTank ~= nil
                and g_FilterPrioritySiegeEnemyInfantry ~= nil then
                targetChooserData.CompareFilterList = {
                    g_FilterPrioritySiegeEnemyTank,
                    g_FilterPrioritySiegeEnemyInfantry
                }
            elseif entry.IsNaval == true
                and g_FilterNoStructureBuffNavalShipEnemy ~= nil then
                -- 引擎自己索敌时也先看敌舰，和脚本压目标的档位保持一致。
                targetChooserData.CompareFilterList = {
                    g_FilterNoStructureBuffNavalShipEnemy
                }
            end
            ObjectSetCustomTargetChooserData(unit, targetChooserData)
            -- 逐拍复核目标：建筑 / 预设守护神 / 技能召唤单位 / 地编锚点基地车一律摘掉。
            local vetoed = false
            local currentTarget = ObjectGetTarget(unit)
            if currentTarget ~= nil and ObjectIsAlive(currentTarget) then
                local targetAllowed = ObjectTestTargetObjectWithFilter(unit,
                    currentTarget, g_FilterNoStructureBuffEnemy)
                if targetAllowed
                    and IsNoStructureBuffForbiddenTarget(currentTarget) then
                    targetAllowed = false
                end
                if not targetAllowed then
                    ObjectSetAssignedTarget(unit, nil)
                    ObjectSetTargetChooserNextAutoAcquireDelay(objectId,
                        g_NoStructureBuffVetoAcquireDelayFrames)
                    vetoed = true
                end
            end
            if not vetoed and ObjectGetTarget(unit) == nil then
                -- 已经压着目标就别强制重新获取，否则会把自己压的目标顶掉。
                ObjectSetTargetChooserNextAutoAcquireDelay(objectId, 0)
            end
            -- 每 3 帧一拍：没目标就按档位压一个（兼作赶路令），有目标就不打扰。
            UpdateNoStructureBuffTarget(unit, objectId, sideIndex,
                entry.IsSiege == true, isNavalUnit)
        end
    end
end

-- 轰炸机全图索敌优先攻敌方陆地炮车。
-- 名单收四种轰炸机：维护者（含超时空信标形态）、伊尔攻击机、金乌轰炸机、樱花回天雷（含陆基/船坞形态）。
g_BomberPriorityUnitTypes = {
    "AlliedAntiGroundAircraft",             -- 维护者轰炸机
    "AlliedChronoBeacon_Vindicator",        -- 维护者轰炸机（超时空信标形态）
    "SovietAntiGroundAttacker",             -- 伊尔攻击机
    "SovietAntiGroundAttacker_Enhanced",    -- 伊尔攻击机（升级形态）
    "CelestialBomberAircraft",              -- 金乌轰炸机
    "CelestialBomberAircraft_Enhanced",     -- 金乌轰炸机（升级形态）
    "JapanInterceptorAircraft",             -- 樱花回天雷
    "JapanInterceptorAircraft_Ground",      -- 樱花回天雷（陆基形态）
    "JapanInterceptorAircraft_WarfactoryWater" -- 樱花回天雷（船坞/水上形态）
}

-- 优先档：敌方陆地炮车（白虎 / V4 / 波能 / 雅典娜 / 郁金香）及其升级形态。
-- 超级要塞大头形态与“菊花”导弹车不列进来：它们由 PrioritySiegeAttackMove 的炮车 AI 另管一档。
g_FilterBomberPrioritySiegeVehicle = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "ENEMIES",
    IncludeThing = {
        "CelestialAntiStructureVehicle",             -- 白虎量子重炮运载车
        "CelestialAntiStructureVehicle_Enhanced",
        "SovietAntiStructureVehicle",                -- V4 导弹发射车
        "SovietAntiStructureVehicle_Enhanced",
        "JapanAntiStructureVehicle",                 -- 波能坦克
        "JapanAntiStructureVehicle_Enhanced",
        "AlliedAntiStructureVehicle",                -- 雅典娜炮
        "AlliedAntiStructureVehicle_Enhanced",
        "SovietHeavyMortarVehicle"                   -- 郁金香自行迫击炮
    }
})

-- 自己方轰炸机的过滤器只需要一个：阵营由 g_SideFindObjects 的锚点（PlyrCivilian / PlyrCreeps）
-- 决定，SAME_PLAYER 是相对锚点算的，和 FilterPrioritySiegeVehicle 同一套写法。
g_FilterBomberPrioritySelf = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    IncludeThing = g_BomberPriorityUnitTypes
})

-- 轰炸机只写 CompareFilterList、不写 CustomFilter：能打谁完全交回引擎，
-- 轰炸机会自己飞过去，而不是先就近随便找个步兵开火。
function ConfigureBomberPriorityTargetChooser(unit)
    ObjectSetCustomTargetChooserData(unit, {
        CompareFilterList = { g_FilterBomberPrioritySiegeVehicle },
        ReverseRangeCompare = false,
        PreferTargetInsideRange = false
    })
    ObjectSetTargetChooserNextAutoAcquireDelay(unit, 0)
end

function BomberPrioritySiegeTargetChooserBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if ownerPlayerName ~= "PlyrCreeps" and ownerPlayerName ~= "PlyrCivilian" then
        return
    end
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ConfigureBomberPriorityTargetChooser(GetObjectById(id))
        end
    end, 1, {createdObjId})
end

-- 引擎索敌扫描半径未必够到全图，所以再用一次“整侧只查一遍全图”的搜索把轰炸机拽过去。
-- 扫描周期 3 帧：与 TGMICRO 的节拍，
g_BomberPrioritySiegeScanIntervalFrames = 3
g_BomberPrioritySiegeNextScanFrame = g_BomberPrioritySiegeNextScanFrame or 0
g_BomberPrioritySiegeTargetByUnitId = g_BomberPrioritySiegeTargetByUnitId or {}
g_BomberAmmoSlotByUnitId = g_BomberAmmoSlotByUnitId or {}

-- 弹药打空的轰炸机会自动回机场补给；这时候压攻击令会把补给流程顶掉，
-- 一架永远回不去机场的轰炸机等于永久废掉，所以强制索敌前先放行返航。
-- 武器槽序号由模板决定（AI 维护者主武器在第 5 号），首次按区间扫一遍并把命中的槽记下来。
function BomberHasWeaponAmmo(self, selfId)
    if ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount == nil then
        return true
    end
    local slot = g_BomberAmmoSlotByUnitId[selfId]
    if slot ~= nil then
        local ammo = ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount(
            self, slot.Hardpoint, slot.Ordering, slot.WeaponIndex)
        if ammo ~= nil then
            return ammo ~= 0
        end
        g_BomberAmmoSlotByUnitId[selfId] = nil
    end
    local sawWeapon = false
    for hardpoint = 1, 2, 1 do
        for weaponIndex = 1, 6, 1 do
            local ammo = ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount(
                self, hardpoint, 1, weaponIndex)
            if ammo ~= nil then
                sawWeapon = true
                if ammo ~= 0 then
                    g_BomberAmmoSlotByUnitId[selfId] = {
                        Hardpoint = hardpoint,
                        Ordering = 1,
                        WeaponIndex = weaponIndex
                    }
                    return true
                end
            end
        end
    end
    -- 一个武器都读不到（单位没有 WeaponSetUpdate 组件）：不拦，交给引擎判断。
    return not sawWeapon
end

-- 不在攻击编队里的轰炸机 = 被摘进 idle 队的那些（例如视距打击召唤的信标机）。
-- 常规轰炸机那样把目标交回原生逻辑，得补一个保底目标，否则它会呆在原地不动也不开火。
function IsBomberTeamDetached(self)
    local teamName = ObjectTeamName(self)
    if teamName == nil then
        return false
    end
    if teamName == DEFAULTIDLETEAM[7] or teamName == DEFAULTIDLETEAM[8] then
        return true
    end
    -- 日冕的编队名有全名和短名两种写法，idle 队的短名是这两个。
    return teamName == "teamPlyrCivilian" or teamName == "teamPlyrCreeps"
end

function GetBomberSideIndex(self)
    if ObjectPlayerScriptName(self) == "PlyrCreeps" then
        return 8
    end
    return 7
end

-- 摘出去之前记一下原来在哪支编队：弹药打空时要塞回去，好让引擎的返航补给流程接管。
g_BomberOriginalTeamByUnitId = g_BomberOriginalTeamByUnitId or {}

function DetachBomberFromAttackTeam(self, selfId)
    if IsBomberTeamDetached(self) then
        return
    end
    g_BomberOriginalTeamByUnitId[selfId] =
        g_BomberOriginalTeamByUnitId[selfId] or ObjectTeamName(self)
    ExecuteAction("NAMED_STOP", self)
    ObjectSetAssignedTarget(self, nil)
    g_SetSideTeam(self, DEFAULTIDLETEAM[GetBomberSideIndex(self)])
end

-- 弹药打空：塞回原编队，把返航补给交给引擎。摘出编队的飞机没人指挥，
-- 压攻击令又会顶掉补给流程，所以这一步必须做，否则它会一直挂在原地发呆。
function ReattachBomberForRearm(self, selfId)
    local originalTeam = g_BomberOriginalTeamByUnitId[selfId]
    if originalTeam == nil or not IsBomberTeamDetached(self) then
        return
    end
    g_BomberOriginalTeamByUnitId[selfId] = nil
    ExecuteAction("NAMED_STOP", self)
    ObjectSetAssignedTarget(self, nil)
    g_SetSideTeam(self, originalTeam)
end

-- 没有炮车时的保底目标：最近的可攻击地面单位（含建筑、不含空中 —— 轰炸机打不了飞机）。
-- 候选按「侧 + 帧」缓存：引擎的敌对关系是按玩家算的，同一侧所有轰炸机的可攻击集合完全相同，
g_BomberFallbackCache = g_BomberFallbackCache or { Frame = nil, BySide = {} }

function GetBomberSideFallbackCandidates(self, sideIndex)
    local frame = GetFrame()
    if g_BomberFallbackCache.Frame ~= frame then
        g_BomberFallbackCache.Frame = frame
        g_BomberFallbackCache.BySide = {}
    end
    local cached = g_BomberFallbackCache.BySide[sideIndex]
    if cached ~= nil then
        return cached.List, cached.Count
    end
    local list = {}
    local count = 0
    if g_FilterOptimizedGroundEnemy ~= nil then
        list, count = ObjectFindObjects(self, nil, g_FilterOptimizedGroundEnemy)
    end
    if count == 0 and FilterALLENEMYUNIT ~= nil then
        list, count = ObjectFindObjects(self, nil, FilterALLENEMYUNIT)
    end
    g_BomberFallbackCache.BySide[sideIndex] = { List = list, Count = count }
    return list, count
end

function FindNearestBomberFallbackTarget(self, sideIndex)
    if sideIndex == nil then
        sideIndex = GetBomberSideIndex(self)
    end
    local list, count = GetBomberSideFallbackCandidates(self, sideIndex)
    return FindNearestTargetFromList(self, list, count)
end

-- target 是这一轮「均分」下来的那个炮车目标；为 nil 表示这一轮没分到（场上没有炮车了）。
function UpdateBomberPrioritySiegeTarget(self, target, sideIndex)
    local selfId = ObjectGetId(self)
    if not BomberHasWeaponAmmo(self, selfId) then
        -- 弹药打空的轰炸机要自己飞回机场补给，这时候压攻击令会把返航顶掉。
        ReattachBomberForRearm(self, selfId)
        return
    end
    local current = ObjectGetTarget(self)
    local currentId = nil
    if current ~= nil and ObjectIsAlive(current) then
        currentId = ObjectGetId(current)
    end
    if target == nil then
        -- 没分到炮车（场上炮车已经清空）：退化为「最近目标」，和制空机一个口径。
        -- 这一档仍由脚本压目标而不是交回引擎 —— 交回引擎就是各挑各的、全撞在同一只身上，
        -- 那正是「轰炸机有点蠢」的来源。
        target = FindNearestBomberFallbackTarget(self, sideIndex)
    end
    if target == nil then
        -- 连一个合法目标都没有：撤掉自己压过的目标、把编队还回去，让引擎的编队推进接管，
        -- 免得摘队以后永久挂在半空（旧实现只有弹药打空才会归队）。
        ReattachBomberForRearm(self, selfId)
        if g_BomberPrioritySiegeTargetByUnitId[selfId] ~= nil then
            g_BomberPrioritySiegeTargetByUnitId[selfId] = nil
            ObjectSetAssignedTarget(self, nil)
            ConfigureBomberPriorityTargetChooser(self)
        end
        return
    end
    -- 要压目标了：先确保它不在公共编队里，否则引擎的编队攻击令会把目标顶掉。
    if not IsBomberTeamDetached(self) then
        DetachBomberFromAttackTeam(self, selfId)
        currentId = nil
    end
    local targetId = ObjectGetId(target)
    if currentId ~= nil and targetId == currentId then
        -- 目标没变就不重复下令，免得抖航路。
        g_BomberPrioritySiegeTargetByUnitId[selfId] = targetId
        return
    end
    ObjectSetAssignedTarget(self, target)
    ExecuteAction("NAMED_ATTACK_NAMED", self, target)
    g_BomberPrioritySiegeTargetByUnitId[selfId] = targetId
end

-- 索敌器只需配一次：原生索敌是「压目标失败」时的兜底，仍按炮车优先排序。
g_BomberPriorityChooserConfiguredByUnitId =
    g_BomberPriorityChooserConfiguredByUnitId or {}

function EnsureBomberPriorityTargetChooser(unit)
    local unitId = ObjectGetId(unit)
    if unitId == nil or g_BomberPriorityChooserConfiguredByUnitId[unitId] then
        return
    end
    g_BomberPriorityChooserConfiguredByUnitId[unitId] = true
    ConfigureBomberPriorityTargetChooser(unit)
end

-- 把炮车目标「尽量均分」给本方轰炸机：连续的若干架打同一台（形成打击组，集火更快），
-- 每台分到的机数最多差 1 —— 20 架打 5 台 → 每台 4 架；20 架打 3 台 → 7 / 7 / 6。
-- 炮车比飞机多时就一对一，剩下的炮车这轮空着（下一轮前排被清掉后会重新分）。
-- 没有炮车（siegeCount = 0）时 groupSize 保持 0，每架都走「最近目标」那一档。
function AssignBomberTargets(bombers, bomberCount, sieges, siegeCount, sideIndex)
    if bomberCount == nil or bomberCount <= 0 then
        return
    end
    local groupSize = 0
    if siegeCount ~= nil and siegeCount > 0 then
        -- ceil(bomberCount / siegeCount)：Lua 4 没有整除和 %，用 floor 加补偿。
        groupSize = floor((bomberCount + siegeCount - 1) / siegeCount)
        if groupSize < 1 then
            groupSize = 1
        end
    end
    for i = 1, bomberCount, 1 do
        local target = nil
        if groupSize > 0 then
            local slot = floor((i - 1) / groupSize) + 1
            if slot > siegeCount then
                slot = siegeCount
            end
            target = sieges[slot]
        end
        -- 索敌器的排序表每架都要有：炮车清空后原生索敌还会按「炮车优先」排序。
        EnsureBomberPriorityTargetChooser(bombers[i])
        UpdateBomberPrioritySiegeTarget(bombers[i], target, sideIndex)
    end
end

-- 每 3 帧（TGMICRO 周期）只做一件最便宜的事：看自己压着的那台炮车还在不在。
function BomberPrioritySiegeWatchdog()
    if g_BomberPrioritySiegeTargetByUnitId == nil then
        return
    end
    for unitId, targetId in g_BomberPrioritySiegeTargetByUnitId do
        local bomber = GetObjectById(unitId)
        if bomber == nil or not ObjectIsAlive(bomber) then
            -- 引擎会复用对象 id，死机不清理就会拿旧目标一直触发重扫。
            g_BomberPrioritySiegeTargetByUnitId[unitId] = nil
        else
            local target = GetObjectById(targetId)
            if target == nil or not ObjectIsAlive(target) then
                -- 目标没了：把下一次全图扫描提前到本拍，重新均分 + 下令都走原来那条路。
                g_BomberPrioritySiegeNextScanFrame = 0
                return
            end
        end
    end
end

-- 每 3 帧（TGMICRO 周期，与空军其它微操同节拍）整侧扫一遍轰炸机与炮车，然后统一分配目标。
function BomberPrioritySiegeMICROCONTROL()
    if g_FilterBomberPrioritySiegeVehicle == nil or g_FilterBomberPrioritySelf == nil then
        return
    end
    local frame = GetFrame()
    if frame < g_BomberPrioritySiegeNextScanFrame then
        return
    end
    g_BomberPrioritySiegeNextScanFrame = frame + g_BomberPrioritySiegeScanIntervalFrames
    for playindex = 7, 8, 1 do
        local bombers, bomberCount = g_SideFindObjects(playindex, nil,
            g_FilterBomberPrioritySelf)
        local sieges, siegeCount = g_SideFindObjects(playindex, nil,
            g_FilterBomberPrioritySiegeVehicle)
        AssignBomberTargets(bombers, bomberCount, sieges, siegeCount, playindex)
    end
end
