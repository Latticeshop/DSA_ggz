local units, count = ObjectFindObjects(T74, nil, unitall)
local aliveUnits = {}
for i = 1, count, 1 do
    if ObjectIsAlive(units[i]) then
        tinsert(aliveUnits, units[i])
    end
end
local getRandomUnit = function(unitList)
    local index = ceil(GetRandomNumber() * getn(unitList))
    if index < 1 then
        index = 1
    end
    if index > getn(unitList) then
        index = getn(unitList)
    end
    return unitList[index]
end

-- 每次达摩克利斯之剑的第一轮，保证至少有一发命中敌方当前最前方的存活防御塔。
local getFrontTower = function()
    local towerNames = { "T71", "T72", "T73", "T74" }
    for i = 1, getn(towerNames), 1 do
        local tower = GetObjectByScriptName(towerNames[i])
        if ObjectIsAlive(tower) then
            return tower
        end
    end
    return nil
end

local frontTower = getFrontTower()
local attackTargets = {}
if g_AngelDamoclesMustHitFrontTower == 1 then
    if frontTower ~= nil then
        -- 整次技能仅首轮的第一发瞄准最前方塔。
        tinsert(attackTargets, frontTower)
    end
    g_AngelDamoclesMustHitFrontTower = 0
end

-- 剩余攻击只从非建筑单位池抽取；没有单位时宁可少攻击，也不再拿塔补位。
while getn(attackTargets) < 3 and getn(aliveUnits) > 0 do
    tinsert(attackTargets, getRandomUnit(aliveUnits))
end
for i = 1, getn(attackTargets), 1 do
    local targetId = ObjectGetId(attackTargets[i])
    local x, y, z = ObjectGetPosition(targetId)
    ExecuteAction("CREATE_OBJECT", "CelestialOrbitalStrikeTarget", "PlyrCreeps/teamPlyrCreeps", {X=x,Y=y,Z=z}, '0')
end
