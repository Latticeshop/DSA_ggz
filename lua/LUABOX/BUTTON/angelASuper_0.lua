-- 旧版超时空突袭逻辑（保留备查）：
-- 1. 在 angel-ASuper1 至 angel-ASuper4 四个固定路径点生成运输载具和传送特效。
-- 2. 将全部 T2tank 按总数量的四分之一平均分配给四辆载具。
-- 3. 驻军完成后依次放出单位，再删除四辆运输载具。
-- 旧版固定落点在单位数量较多时容易让大量单位聚团，因此不再执行。
-- 旧版分组核心代码如下（仅保留，不执行）：
-- for i = 1, count do
--     if i <= 1 / 4 * count then
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit1" .. i, "angelchar1")
--     elseif i <= 1 / 2 * count then
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit1" .. i, "angelchar2")
--     elseif i <= 3 / 4 * count then
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit1" .. i, "angelchar3")
--     else
--         ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Unit1" .. i, "angelchar4")
--     end
-- end

local groupSize = 8 -- 每组8个。
local sourceTower = T84
local targetTower = T74
local sideTeam = "PlyrCreeps/teamPlyrCreeps"

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

g_AngelChronosphereTransportIndex = (g_AngelChronosphereTransportIndex or 0)
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
        ObjectLoadAttributeModifier(unit, "AttributeModifier_IronCurtain", 75)
        ObjectLoadAttributeModifier(unit, "AttributeModifier_DefenseEffect_0", 30)
    end

    ExecuteAction("EXIT_SPECIFIC_BUILDING", transportName)
    ExecuteAction("NAMED_DELETE", transportName)
end
