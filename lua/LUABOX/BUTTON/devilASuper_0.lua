-- 旧版超时空突袭逻辑（保留备查）：
-- 1. 在 devil-ASuper1 至 devil-ASuper4 四个固定路径点生成运输载具和传送特效。
-- 2. 将全部 T2tank 按总数量的四分之一平均分配给四辆载具。
-- 3. 驻军完成后依次放出单位，再删除四辆运输载具。
-- 旧版固定落点在单位数量较多时容易让大量单位聚团，因此不再执行。
-- 旧版分组核心代码如下（仅保留，不执行）：
-- for i = 1, count do
--     if i <= 1 / 4 * count then
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit" .. i, "devilchar1")
--     elseif i <= 1 / 2 * count then
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit" .. i, "devilchar2")
--     elseif i <= 3 / 4 * count then
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit" .. i, "devilchar3")
--     else
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit" .. i, "devilchar4")
--     end
-- end

local groupSize = 8 -- 每组X个，只需修改此值。
local sourceTower = T74
local targetTower = T84
local sideTeam = "PlyrCivilian/teamPlyrCivilian"
local fallbackWaypoints = { "devil-ASuper1", "devil-ASuper2", "devil-ASuper3", "devil-ASuper4" }

local units, count = ObjectFindObjects(sourceTower, nil, T2tank)
if count <= 0 then
    return
end

local landingTargetFilter = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE",
    Exclude = "AIRCRAFT SHIP STRUCTURE DEBRIS IGNORE_IN_AI_HUNT_TACTIC",
})
local landingTargets, landingTargetCount = ObjectFindObjects(targetTower, nil, landingTargetFilter)
local availableLandingTargets = {}
local availableLandingTargetCount = 0
for i = 1, landingTargetCount, 1 do
    if ObjectIsAlive(landingTargets[i]) then
        tinsert(availableLandingTargets, landingTargets[i])
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
            if ObjectIsAlive(landingTargets[i]) then
                tinsert(availableLandingTargets, landingTargets[i])
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
        local waypoint = fallbackWaypoints[randomIndex(getn(fallbackWaypoints))]
        local p = exWaypointGetPos(waypoint)
        position = { X = p[1] + randomOffset(90), Y = p[2] + randomOffset(90), Z = p[3] }
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
        ObjectLoadAttributeModifier(unit, "AttributeModifier_IronCurtain", 75)
        ObjectLoadAttributeModifier(unit, "AttributeModifier_DefenseEffect_0", 30)
    end

    ExecuteAction("EXIT_SPECIFIC_BUILDING", transportName)
    ExecuteAction("NAMED_DELETE", transportName)
end
