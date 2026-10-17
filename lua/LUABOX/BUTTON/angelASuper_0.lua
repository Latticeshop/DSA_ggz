-- 讲解见 analysis/地图注释说明文档.md 附录 A.6

local groupSize = 8 -- 每组8个。
local sourceTower = T84
local targetTower = T74
local sideTeam = "PlyrCreeps/teamPlyrCreeps"

local units, count = ObjectFindObjects(sourceTower, nil, T2tank)
if count <= 0 then
    return
end

-- 与九头蛇/冰天雪地同款：
local landingTargetFilter = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    Include = "SELECTABLE",
    ExcludeThing = { "JapanFortressShip", "JapanigaFortressShip", "Overlordtank",
        "AlliedMCV",
        "CelestialMCV", "CelestialMCV_Ground", "CelestialMCV_Naval", "CelestialMCV_Air",
        "CelestialMCV_Enhanced", "CelestialMCV_Enhanced_Ground",
        "CelestialMCV_Enhanced_Naval", "CelestialMCV_Enhanced_Air",
        "CelestialBaseDefenseAdvanced", "CelestialBaseDefenseAdvanced_NoCore",
        "CelestialBaseDefenseAir", "CelestialEnergyGatlingTower",
        "AlliedHeavyArtilleryDefenseBase", "SovietBaseDefenseAdvanced",
        "JapanBaseDefenseAdvanced" },
    Exclude = "AIRCRAFT SHIP STRUCTURE DEBRIS IGNORE_IN_AI_HUNT_TACTIC IMMOBILE",
})
local landingTargets, landingTargetCount = ObjectFindObjects(targetTower, nil, landingTargetFilter)
local availableLandingTargets = {}
for i = 1, landingTargetCount, 1 do
    if ObjectIsAlive(landingTargets[i]) then
        tinsert(availableLandingTargets, landingTargets[i])
    end
end
local availableLandingTargetCount = getn(availableLandingTargets)

local randomIndex = function(maxIndex)
    local index = ceil(GetRandomNumber() * maxIndex)
    if index < 1 then index = 1 end
    if index > maxIndex then index = maxIndex end
    return index
end

local randomOffset = function(radius)
    return (GetRandomNumber() * radius * 2) - radius
end

g_AngelChronosphereTransportIndex = (g_AngelChronosphereTransportIndex or 0)
local groupCount = ceil(count / groupSize)
for groupIndex = 1, groupCount, 1 do
    local position = nil
    if availableLandingTargetCount <= 0 and landingTargetCount > 0 then
        -- RA3LuaBridge 不允许局部函数捕获外层局部变量，因此直接在当前作用域补充目标池。
        availableLandingTargets = {}
        for i = 1, landingTargetCount, 1 do
            local target = landingTargets[i]
            if ObjectIsAlive(target) then
                tinsert(availableLandingTargets, target)
            end
        end
        availableLandingTargetCount = getn(availableLandingTargets)
    end
    if availableLandingTargetCount > 0 then
        local targetIndex = randomIndex(availableLandingTargetCount)
        local target = availableLandingTargets[targetIndex]
        tremove(availableLandingTargets, targetIndex)
        availableLandingTargetCount = availableLandingTargetCount - 1
        if ObjectIsAlive(target) then
            local x, y, z = ObjectGetPosition(target)
            position = { X = x + randomOffset(90), Y = y + randomOffset(90), Z = z }
        end
    end
    if position == nil then
        return
    end

    g_AngelChronosphereTransportIndex = g_AngelChronosphereTransportIndex + 1
    local transportName = "angelChronosphereTransport" .. tostring(g_AngelChronosphereTransportIndex)
    ExecuteAction("CREATE_OBJECT", "alliedsuperweaponeffect", sideTeam, position, 0)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", transportName,
        "japanlighttransportvehicle", sideTeam, position, 180)

    local firstUnitIndex = (groupIndex - 1) * groupSize + 1
    local lastUnitIndex = min(groupIndex * groupSize, count)
    for unitIndex = firstUnitIndex, lastUnitIndex, 1 do
        local unit = units[unitIndex]
        local referenceName = "angelChronosphereUnit" .. tostring(ObjectGetId(unit))
        ExecuteAction("SET_UNIT_REFERENCE", referenceName, unit)
        ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", referenceName, transportName)
        g_ApplyIronCurtain(unit, 75)
        ObjectLoadAttributeModifier(unit, "AttributeModifier_DefenseEffect_0", 30)
    end

    ExecuteAction("EXIT_SPECIFIC_BUILDING", transportName)
    ExecuteAction("NAMED_DELETE", transportName)
end
