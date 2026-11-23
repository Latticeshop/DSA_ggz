-- 讲解见 analysis/地图注释说明文档.md 第 10 节 + 附录 A.6

-- 超时空突袭（天使侧 / PlyrCreeps）：把本方全部主战坦克按 8 个一组，分组空投到中央战场内。
local groupSize = 8 -- 每组8个。
local sourceTower = T84
local targetTower = T74
local sideTeam = "PlyrCreeps/teamPlyrCreeps"
local sideIndex = 8
local enemySideIndex = 7
local landingAreaName = "BATTLEFIELD"

local units, count = ObjectFindObjects(sourceTower, nil, T2tank)
if count <= 0 then
    -- 本方四塔还在就等于「本方」，但一只主战坦克都扫不到（塔被拆或全被禁兵种）时，
    -- 原来会静默结束、玩家只看到「使用了技能」，所以补一条整侧提示。
    g_BroadcastToSide(sideIndex,
        Localization.get("center_top.error.temporal_raid_no_tank"), 10)
    return
end

-- 与九头蛇/冰天雪地同款；落点排除群体统一取自 BasicVar 的登记表。
local landingTargetFilter = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    Include = "SELECTABLE",
    ExcludeThing = g_CollectTargetNames({ "GuardianFormTemplate", "AIAnchorMCV",
        "DragonShip", "DefenseTower" }),
    Exclude = "AIRCRAFT SHIP STRUCTURE DEBRIS IGNORE_IN_AI_HUNT_TACTIC IMMOBILE",
})

-- 一档 = 敌方在中央战场内的地面单位，取它们的原位。
local landingPoints = {}
local landingPointCount = 0
local candidates, candidateCount = ObjectFindObjects(targetTower, nil, landingTargetFilter)
for i = 1, candidateCount, 1 do
    if ObjectIsAlive(candidates[i]) and g_IsObjectInArea(candidates[i], landingAreaName) then
        do
            local x, y, z = ObjectGetPosition(candidates[i])
            landingPointCount = landingPointCount + 1
            landingPoints[landingPointCount] = { X = x, Y = y, Z = z }
        end
    end
end

-- 二档 = 对面的陆地出生点（PlyrCivilian 的 LIGHTVEH11..16）。
if landingPointCount <= 0 and LIGHTVEHSP ~= nil and LIGHTVEHSP[enemySideIndex] ~= nil then
    local spawnPoints = LIGHTVEHSP[enemySideIndex]
    for i = 1, getn(spawnPoints), 1 do
        if spawnPoints[i] ~= nil and ObjectIsAlive(spawnPoints[i])
            and g_IsObjectInArea(spawnPoints[i], landingAreaName) then
            do
                local x, y, z = ObjectGetPosition(spawnPoints[i])
                landingPointCount = landingPointCount + 1
                landingPoints[landingPointCount] = { X = x, Y = y, Z = z }
            end
        end
    end
end

if landingPointCount <= 0 then
    g_BroadcastToSide(sideIndex,
        Localization.get("center_top.error.temporal_raid_no_target"), 10)
    return
end

-- 本轮还没用过的落点（抽完一轮再重填，避免同一次施放里反复砸同一处而聚团）。
local availablePoints = {}
local availablePointCount = 0
for i = 1, landingPointCount, 1 do
    availablePointCount = availablePointCount + 1
    availablePoints[availablePointCount] = landingPoints[i]
end

local randomIndex = function(maxIndex)
    local index = ceil(GetRandomNumber() * maxIndex)
    if index < 1 then index = 1 end
    if index > maxIndex then index = maxIndex end
    return index
end

g_AngelChronosphereTransportIndex = (g_AngelChronosphereTransportIndex or 0)
local groupCount = ceil(count / groupSize)
for groupIndex = 1, groupCount, 1 do
    if availablePointCount <= 0 then
        -- RA3LuaBridge 不允许局部函数捕获外层局部变量，因此直接在当前作用域重填落点池。
        availablePoints = {}
        availablePointCount = 0
        for i = 1, landingPointCount, 1 do
            availablePointCount = availablePointCount + 1
            availablePoints[availablePointCount] = landingPoints[i]
        end
    end

    local position = nil
    if availablePointCount > 0 then
        local pointIndex = randomIndex(availablePointCount)
        position = availablePoints[pointIndex]
        tremove(availablePoints, pointIndex)
        availablePointCount = availablePointCount - 1
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
