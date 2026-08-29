
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

FilterLongRangeArtillery=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "PrismTank","AlliedPrismTank_Enhanced",
        "CelestialAntiStructureVehicle","CelestialAntiStructureVehicle_Enhanced",
        "JapanAntiStructureVehicle","JapanAntiStructureVehicle_Enhanced",
        "AlliedAntiStructureVehicle","AlliedAntiStructureVehicle_Enhanced"
    }
})

FilterLongRangeArtilleryEnemy=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="INFANTRY VEHICLE HUGE_VEHICLE STRUCTURE"
})

FilterJapanCommando=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = { "JapanCommandoTech1" }
})

FilterJapanCommandoEnemy=CreateObjectFilter({
    Rule="ANY",
    Relationship="ENEMIES",
    Include="INFANTRY VEHICLE HUGE_VEHICLE AIRCRAFT",
    Exclude="STRUCTURE"
})

g_LongRangeArtilleryLastTarget = {}

function IsJapanCommandoInAttackTeam(self, playindex)
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

function FindFarthestEnemyInRange(self, radius, filter)
    local x, y, z = ObjectGetPosition(self)
    local targets, count = ObjectFindObjects(self, {
        X=x, Y=y, Z=z, Radius=radius, DistType="CENTER_2D"
    }, filter)
    local farthest = nil
    local farthestDistance = -1
    for i = 1, count, 1 do
        if ObjectIsAlive(targets[i]) then
            local distance = ObjectsDistance2D(self, targets[i])
            if distance > farthestDistance then
                farthest = targets[i]
                farthestDistance = distance
            end
        end
    end
    return farthest
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

-- 首次接敌沿用单位原生索敌；当前目标死亡后，改打射程内最远目标。
function LongRangeArtilleryMICROCONTROL ()
    for playindex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[playindex], nil, FilterLongRangeArtillery)
        for i = 1, count, 1 do
            local self = units[i]
            local selfId = ObjectGetId(self)
            local currentTarget = ObjectGetTarget(self)
            local previousTargetId = g_LongRangeArtilleryLastTarget[selfId]
            local previousTargetDied = previousTargetId ~= nil and not ObjectIsAlive(previousTargetId)

            if previousTargetDied then
                local farthest = FindFarthestEnemyInRange(self, 500, FilterLongRangeArtilleryEnemy)
                if farthest ~= nil then
                    ExecuteAction("NAMED_ATTACK_NAMED", self, farthest)
                    g_LongRangeArtilleryLastTarget[selfId] = ObjectGetId(farthest)
                else
                    g_LongRangeArtilleryLastTarget[selfId] = nil
                end
            elseif currentTarget ~= nil and ObjectIsAlive(currentTarget) then
                g_LongRangeArtilleryLastTarget[selfId] = ObjectGetId(currentTarget)
            elseif previousTargetId ~= nil then
                -- 目标还活着但已离开索敌状态时，交回原生 AI 继续前进。
                g_LongRangeArtilleryLastTarget[selfId] = nil
            end
        end
    end
end

-- 百合子的百分比伤害不能直接用于推塔：有敌方单位时追击最近单位，
-- 全地图没有合法单位目标时把自身设为非法攻击目标，打断攻击前进并原地待命。
function JapanCommandoNoStructureMICROCONTROL ()
    for playindex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[playindex], nil, FilterJapanCommando)
        for i = 1, count, 1 do
            local self = units[i]
            local selfId = ObjectGetId(self)
            -- 只在当前确实被放回进攻编队时分离，待命状态下不会重复换队。
            if IsJapanCommandoInAttackTeam(self, playindex) then
                ExecuteAction("UNIT_SET_TEAM", self, DEFAULTIDLETEAM[playindex])
            end
            ObjectSetCustomTargetChooserData(self, {
                CustomFilter = FilterJapanCommandoEnemy
            })
            ObjectSetTargetChooserNextAutoAcquireDelay(selfId, 0)
            local target = ObjectGetTarget(self)
            local hasValidTarget = target ~= nil
                and ObjectIsAlive(target)
                and ObjectTestTargetObjectWithFilter(self, target, FilterJapanCommandoEnemy)
            if not hasValidTarget then
                local replacement = FindNearestEnemyAnywhere(self, FilterJapanCommandoEnemy)
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

function JapanAntiInfantryVehicleMICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanAntiInfantryVehicle)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterAIR)
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if TARcount > 0 and not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") then
                --  --exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JAIV_Transform" )
            elseif  TARcount == 0  and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") then
                -- --exMessageAppendToMessageArea("降落")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JAIV_Transform" )
            end
        end
    end
end


function JapanMissileMechaAdvancedMICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanMissileMechaAdvanced)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterAIR)
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if TARcount > 0 and not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") then
                ----exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JapanMissileMechaAdavanced_Transform" )
            elseif  TARcount == 0  and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") then
                ----exMessageAppendToMessageArea("降落")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JapanMissileMechaAdavanced_Transform" )
            end
        end
    end
end

function JapanAntiAirVehicleTech1MICROCONTROL ()
    for playindex = 7 , 8 , 1 do
        local SELF, count = ObjectFindObjects(P[playindex], nil, FilterJapanAntiAirVehicleTech1)
        ----exMessageAppendToMessageArea("count"..count)
        for i = 1 , count , 1 do
            local x0, y0, z0 = ObjectGetPosition(SELF[i]) ;
            local TAR, TARcount = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterAIR2)
            local TARLAND, TARcountLAND = ObjectFindObjects(P[playindex], {
                X=x0, Y=y0, Z=z0, Radius=400, DistType="CENTER_2D"
            }, FilterLAND)
            -- --exMessageAppendToMessageArea("TARcount"..TARcount)
            if  TARcountLAND > 0 and TARcount == 0 and not  EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") then
                ----exMessageAppendToMessageArea("起飞")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JAAVT1_Transform" )
            elseif  TARcount > 0  and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", SELF[i] , "AIRBORNE_TARGET") then
                ----exMessageAppendToMessageArea("降落")
                ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", SELF[i] , "Command_JAAVT1_Transform" )
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
