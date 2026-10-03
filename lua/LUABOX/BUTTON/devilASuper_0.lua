-- 讲解见 analysis/地图注释说明文档.md 附录 A.7

local groupSize = 8 -- 每组X个，只需修改此值。
local sourceTower = T74
local targetTower = T84
local sideTeam = "PlyrCivilian/teamPlyrCivilian"

local units, count = ObjectFindObjects(sourceTower, nil, T2tank)
if count <= 0 then
    return
end

local landingTargetFilter = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE",
    ExcludeThing = { "JapanFortressShip", "JapanigaFortressShip" },
    Exclude = "AIRCRAFT SHIP STRUCTURE DEBRIS IGNORE_IN_AI_HUNT_TACTIC",
})
local landingTargets, landingTargetCount = ObjectFindObjects(targetTower, nil, landingTargetFilter)
-- 特殊海塔和其后方的超级要塞守卫无法被 SHIP/STRUCTURE Kind 稳定排除。
-- 按地图对象 ID 再兜底一次，避免将 seaTower7/8 所在水域选为落点。
local excludedLandingTargetIds = {}
local excludedLandingTargetNames = {
    "T73F", "T83F", "Sea3ProtectShip7", "Sea3ProtectShip8"
}
for i = 1, getn(excludedLandingTargetNames), 1 do
    local excludedTarget = GetObjectByScriptName(excludedLandingTargetNames[i])
    if excludedTarget then
        excludedLandingTargetIds[ObjectGetId(excludedTarget)] = true
    end
end
local availableLandingTargets = {}
local availableLandingTargetCount = 0
for i = 1, landingTargetCount, 1 do
    local target = landingTargets[i]
    if ObjectIsAlive(target) and not excludedLandingTargetIds[ObjectGetId(target)] then
        tinsert(availableLandingTargets, target)
    end
end
availableLandingTargetCount = getn(availableLandingTargets)

local randomIndex = function(maxIndex)
    local index = ceil(GetRandomNumber() * maxIndex)
    if index < 1 then index = 1 end
    if index > maxIndex then index = maxIndex end
    return index
end

local randomOffset = function(radius)
    return (GetRandomNumber() * radius * 2) - radius
end

g_DevilChronosphereTransportIndex = (g_DevilChronosphereTransportIndex or 0)
local groupCount = ceil(count / groupSize)
for groupIndex = 1, groupCount, 1 do
    local position = nil
    if availableLandingTargetCount <= 0 and landingTargetCount > 0 then
        -- RA3LuaBridge 不允许局部函数捕获外层局部变量，因此直接在当前作用域补充目标池。
        availableLandingTargets = {}
        for i = 1, landingTargetCount, 1 do
            local target = landingTargets[i]
            if ObjectIsAlive(target) and not excludedLandingTargetIds[ObjectGetId(target)] then
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

    g_DevilChronosphereTransportIndex = g_DevilChronosphereTransportIndex + 1
    local transportName = "devilChronosphereTransport" .. tostring(g_DevilChronosphereTransportIndex)
    ExecuteAction("CREATE_OBJECT", "alliedsuperweaponeffect", sideTeam, position, 0)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", transportName,
        "japanlighttransportvehicle", sideTeam, position, 0)

    local firstUnitIndex = (groupIndex - 1) * groupSize + 1
    local lastUnitIndex = min(groupIndex * groupSize, count)
    for unitIndex = firstUnitIndex, lastUnitIndex, 1 do
        local unit = units[unitIndex]
        local referenceName = "devilChronosphereUnit" .. tostring(ObjectGetId(unit))
        ExecuteAction("SET_UNIT_REFERENCE", referenceName, unit)
        ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", referenceName, transportName)
        g_ApplyIronCurtain(unit, 75)
        ObjectLoadAttributeModifier(unit, "AttributeModifier_DefenseEffect_0", 30)
    end

    ExecuteAction("EXIT_SPECIFIC_BUILDING", transportName)
    ExecuteAction("NAMED_DELETE", transportName)
end
