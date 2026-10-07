-- 机制依据/失败记录/实测结论：analysis/地图注释说明文档.md §1（先读 §1.13）。
-- 硬约束：装填/巡收不删兵（删只在清要塞自带标枪兵）；只走 g_PLSpawnGarrison；成败由巡收复核。

g_PLSpawnLastRound = -1

g_PLSpawnHoldDelay = 30
g_PLSpawnHoldTries = 2
g_PLSpawnNoEvac = 1
g_PLSpawnRandScale = 1000000

-- 两个 AI 阵营的玩家脚本名（§1.15）
g_PLSpawnSideNames = { [7] = "PlyrCivilian", [8] = "PlyrCreeps" }

-- 台账条目 { CarId, UnitId, Tag, Retry }：只能用数组（§1.8）
g_PLSpawnEntries = {}

-- 名单即白名单，不写即被过滤（§1.6）
g_PLSpawnAllInf = {
    "AlliedCryoLegionnaire",
    "AlliedAntiInfantryInfantry",
    "CelestialAntiInfantryInfantryAdvanced",
    "CelestialAntiInfantryInfantry",
    "CelestialAntiVehicleInfantry",
    "CelestialAntiVehicleInfantry_EMC",
    "CelestialInfiltrationInfantry",
    "CelestialInfiltrationInfantry_02",
    "CelestialInfiltrationInfantry_03",
    "CelestialInfiltrationInfantry_EMC",
    "JapanAntiInfantryInfantry",
    "JapanAntiVehicleInfantry",
    "JapanAntiVehicleInfantry_Ambush",
    "JapanArcherInfantry",
    "SovietAntiInfantryInfantry",
    "SovietAntiVehicleInfantry",
    "SovietHeavyAntiVehicleInfantry",
    "SovietHeavyAntiVehicleInfantry_Enhanced",
    "JapanInfiltrationInfantry",
    "AlliedAntiVehicleInfantry",
    "AlliedRangerInfantry",
    "AlliedRangerInfantry_AirAssault",
}

-- 特殊载员池：只联盟/重型（进IFV要塞会不开火，§1.17）
g_PLSpawnSpecialInf = { "SovietMortarCycle", "JapanAntiVehicleInfantryTech3" }

-- 两型显示名重名，靠 Tag 区分（§1.7）
g_PLSpawnCars = {
    { Template = "AlliedAntiAirVehicleTech1",     Capacity = 1, Inf = g_PLSpawnAllInf, Tag = "IFV" },
    -- 要塞先被预扫趟清成 5 格空车（§1.14）
    { Template = "AlliedBattleFortress",          Capacity = 5, Inf = g_PLSpawnAllInf, Tag = "要塞",
      BuiltIn = "AlliedAntiVehicleInfantry" },
    { Template = "SovietAntiVehicleVehicleTech4", Capacity = 5, Inf = g_PLSpawnAllInf, Tag = "联盟",
      SpecialInf = g_PLSpawnSpecialInf },
    { Template = "Overlordtank",                  Capacity = 5, Inf = g_PLSpawnAllInf, Tag = "重型",
      SpecialInf = g_PLSpawnSpecialInf },
}

-- 下车按钮名按兵种不同，不做查表，全表一起下（§1.5）
g_PLSpawnEvacButtons = {
    "Command_Evacuate",
    "Command_SovietBattleBunkerEvacuate",
    "Command_SovietAntiGroundAircraftEvacuate",
    "Command_CelestialGroundEvacuate",
    "Command_AlliedAntiInfantryVehicleEvacuate",
    "Command_DisguisedEvacuate",
    "Command_SpecialPowerEvacuateShipPassengers",
}

function g_PLSpawnPassengerCount(car)
    local passengers, count = ObjectGetContainedPassengers(car)
    if count == nil then
        return nil
    end
    return count
end

function g_PLSpawnTrackedCount(carId)
    local count = 0
    for index = 1, getn(g_PLSpawnEntries), 1 do
        if g_PLSpawnEntries[index].CarId == carId then
            count = count + 1
        end
    end
    return count
end

function g_PLSpawnTrackedUnit(unitId)
    for index = 1, getn(g_PLSpawnEntries), 1 do
        if g_PLSpawnEntries[index].UnitId == unitId then
            return true
        end
    end
    return false
end

function g_PLSpawnFreeSlots(car, carEntry)
    local used = g_PLSpawnPassengerCount(car)
    local tracked = g_PLSpawnTrackedCount(ObjectGetId(car))
    if used == nil or tracked > used then
        used = tracked
    end
    if used >= carEntry.Capacity then
        return 0
    end
    return carEntry.Capacity - used
end

function g_PLSpawnRandomIndex(count)
    if count < 2 or GetRandomNumber == nil then
        return 1
    end
    local pick = floor(GetRandomNumber() * g_PLSpawnRandScale) + 1
    if pick < 1 then
        pick = 1
    end
    if pick > g_PLSpawnRandScale then
        pick = g_PLSpawnRandScale
    end
    -- 无 % 运算符，取模自己算
    local index = pick - floor((pick - 1) / count) * count
    if index < 1 then
        index = 1
    end
    if index > count then
        index = count
    end
    return index
end

function g_PLSpawnInsideGarrison(child)
    if child == nil or not ObjectIsAlive(child) then
        return false
    end
    -- 0 是真值，只显式比成功值
    local inside = EvaluateCondition("UNIT_HAS_OBJECT_STATUS", child, "INSIDE_GARRISON")
    if inside == 1 or inside == true then
        return true
    end
    return false
end

function g_PLSpawnGarrison(car, unit)
    ExecuteAction("SET_UNIT_REFERENCE", "Infantry1", unit)
    ExecuteAction("SET_UNIT_REFERENCE", "Vehicle1", car)
    ExecuteAction("NAMED_GARRISON_SPECIFIC_BUILDING_INSTANTLY", "Infantry1", "Vehicle1")
end

function g_PLSpawnTrackEntry(carId, unitId, tag)
    tinsert(g_PLSpawnEntries, { CarId = carId, UnitId = unitId, Tag = tag, Retry = 0 })
end

-- 明确跨阵营的车兵配对（§1.15）
function g_PLSpawnCrossPair(car, unit)
    if ObjectPlayerScriptName == nil then
        return false
    end
    local carName = ObjectPlayerScriptName(car)
    local unitName = ObjectPlayerScriptName(unit)
    if carName == nil or unitName == nil or carName == unitName then
        return false
    end
    local mine = g_PLSpawnSideNames[7]
    local theirs = g_PLSpawnSideNames[8]
    return (carName == mine or carName == theirs)
        and (unitName == mine or unitName == theirs)
end

function g_PLSpawnHold()
    local list = g_PLSpawnEntries
    g_PLSpawnEntries = {}

    for index = 1, getn(list), 1 do
        local item = list[index]
        local car = GetObjectById(item.CarId)
        local unit = GetObjectById(item.UnitId)
        -- 配对跨阵营就整条放手（兵不删）
        if car ~= nil and unit ~= nil and g_PLSpawnCrossPair(car, unit) then
            car = nil
        end
        if car ~= nil and ObjectIsAlive(car) and unit ~= nil and ObjectIsAlive(unit) then
            if g_PLSpawnInsideGarrison(unit) then
                item.Retry = 0
                tinsert(g_PLSpawnEntries, item)
            else
                item.Retry = item.Retry + 1
                if item.Retry <= g_PLSpawnHoldTries then
                    g_PLSpawnGarrison(car, unit)
                    tinsert(g_PLSpawnEntries, item)
                end
            end
        end
    end
end

function g_PLSpawnLoadCar(car, tag, slots, candidates, candidateCount)
    if candidates == nil or candidateCount == nil or candidateCount < 1 then
        return
    end
    local loaded = 0
    local carId = ObjectGetId(car)
    local index = g_PLSpawnRandomIndex(candidateCount)
    local checked = 0
    while loaded < slots and checked < candidateCount do
        checked = checked + 1
        local unit = candidates[index]
        index = index + 1
        if index > candidateCount then
            index = 1
        end
        if unit ~= nil and ObjectIsAlive(unit) then
            local unitId = ObjectGetId(unit)
            if not g_PLSpawnInsideGarrison(unit) and not g_PLSpawnTrackedUnit(unitId) then
                g_PLSpawnGarrison(car, unit)
                -- 乐观占位：下发即占槽，成败交给巡收
                loaded = loaded + 1
                g_PLSpawnTrackEntry(carId, unitId, tag)
            end
        end
    end
end

-- 对面阵营脚本名；认不出返回 nil（不过滤）。
function g_PLSpawnOtherSideName(sideIndex)
    local name = g_PLSpawnSideNames[sideIndex]
    if name == "PlyrCivilian" then
        return "PlyrCreeps"
    end
    if name == "PlyrCreeps" then
        return "PlyrCivilian"
    end
    return nil
end

-- 只剔掉明确属于对面的对象（§1.15）。
function g_PLSpawnKeepOwnSide(objects, count, sideIndex)
    if objects == nil or count == nil or count < 1 then
        return objects, 0
    end
    local otherName = g_PLSpawnOtherSideName(sideIndex)
    if otherName == nil or ObjectPlayerScriptName == nil then
        return objects, count
    end
    local kept = {}
    local keptCount = 0
    for index = 1, count, 1 do
        local obj = objects[index]
        if obj ~= nil and ObjectPlayerScriptName(obj) ~= otherName then
            keptCount = keptCount + 1
            kept[keptCount] = obj
        end
    end
    return kept, keptCount
end

-- 地编预制的 T3 塔守护者不是装车载具（§1.16）
g_PLSpawnGuardCarNames = { "overlord7", "overlord8" }

function g_PLSpawnIsGuardCar(car)
    if GetObjectByScriptName == nil then
        return false
    end
    local carId = ObjectGetId(car)
    for index = 1, getn(g_PLSpawnGuardCarNames), 1 do
        local guard = GetObjectByScriptName(g_PLSpawnGuardCarNames[index])
        if guard ~= nil and ObjectGetId(guard) == carId then
            return true
        end
    end
    return false
end

function g_PLSpawnDropGuardCars(objects, count)
    if objects == nil or count == nil or count < 1 then
        return objects, 0
    end
    local kept = {}
    local keptCount = 0
    for index = 1, count, 1 do
        local obj = objects[index]
        if obj ~= nil and not g_PLSpawnIsGuardCar(obj) then
            keptCount = keptCount + 1
            kept[keptCount] = obj
        end
    end
    return kept, keptCount
end

function g_PLSpawnClearBuiltInCrew(sideIndex, cars, count, carEntry)
    if carEntry.BuiltIn == nil or cars == nil or count == nil or count < 1 then
        return
    end
    local carIds = {}
    for index = 1, count, 1 do
        local car = cars[index]
        if car ~= nil and ObjectIsAlive(car) then
            carIds[ObjectGetId(car)] = true
        end
    end
    if carEntry.CrewFilter == nil then
        carEntry.CrewFilter = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = { carEntry.BuiltIn },
        })
    end
    local crew, crewCount = ObjectFindObjects(P[sideIndex], nil, carEntry.CrewFilter)
    if crew == nil or crewCount == nil then
        return
    end
    for index = 1, crewCount, 1 do
        local unit = crew[index]
        if unit ~= nil and ObjectIsAlive(unit) then
            local container = ObjectGetContainerObject(unit)
            -- 台账里的载员不删，只删要塞自带的（§1.14）
            if container ~= nil and carIds[ObjectGetId(container)] == true
                and not g_PLSpawnTrackedUnit(ObjectGetId(unit)) then
                ExecuteAction("NAMED_EXIT_BUILDING", unit)
                ExecuteAction("NAMED_DELETE", unit)
            end
        end
    end
end

function g_PLSpawnCandidates(sideIndex, carEntry)
    if carEntry.InfFilter == nil then
        carEntry.InfFilter = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = carEntry.Inf,
        })
    end
    local units, count = ObjectFindObjects(P[sideIndex], nil, carEntry.InfFilter)
    return g_PLSpawnKeepOwnSide(units, count, sideIndex)
end

function g_PLSpawnSpecialCandidates(sideIndex, carEntry)
    if carEntry.SpecialFilter == nil then
        carEntry.SpecialFilter = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = carEntry.SpecialInf,
        })
    end
    local units, count = ObjectFindObjects(P[sideIndex], nil, carEntry.SpecialFilter)
    return g_PLSpawnKeepOwnSide(units, count, sideIndex)
end

function g_PLSpawnDisableEvac(car)
    if g_PLSpawnNoEvac ~= 1 then
        return
    end
    ExecuteAction("SET_UNIT_REFERENCE", "Vehicle1", car)
    for index = 1, getn(g_PLSpawnEvacButtons), 1 do
        ExecuteAction("DISABLE_UI_UNIT_ABILITY_BUTTON", "Vehicle1",
            g_PLSpawnEvacButtons[index], 1)
    end
end

function g_PLSpawnFindCars(sideIndex, carEntry)
    if carEntry.Filter == nil then
        carEntry.Filter = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = { carEntry.Template },
        })
    end
    local cars, count = ObjectFindObjects(P[sideIndex], nil, carEntry.Filter)
    cars, count = g_PLSpawnKeepOwnSide(cars, count, sideIndex)
    return g_PLSpawnDropGuardCars(cars, count)
end

function g_PLSpawnClearAllBuiltIn(sideIndex)
    for index = 1, getn(g_PLSpawnCars), 1 do
        local carEntry = g_PLSpawnCars[index]
        if carEntry.BuiltIn ~= nil then
            local cars, count = g_PLSpawnFindCars(sideIndex, carEntry)
            g_PLSpawnClearBuiltInCrew(sideIndex, cars, count, carEntry)
        end
    end
end

function g_PLSpawnFillType(sideIndex, carEntry, useSpecial)
    local cars, count = g_PLSpawnFindCars(sideIndex, carEntry)
    if cars == nil or count == nil then
        return
    end
    local candidates, candidateCount
    if useSpecial == 1 then
        candidates, candidateCount = g_PLSpawnSpecialCandidates(sideIndex, carEntry)
    else
        candidates, candidateCount = g_PLSpawnCandidates(sideIndex, carEntry)
    end
    for index = 1, count, 1 do
        local car = cars[index]
        if car ~= nil and ObjectIsAlive(car) then
            local slots = g_PLSpawnFreeSlots(car, carEntry)
            if slots > 0 then
                g_PLSpawnDisableEvac(car)
                g_PLSpawnLoadCar(car, carEntry.Tag, slots, candidates, candidateCount)
            end
        end
    end
end

-- 按阵营不按座位：队友单位同属 7/8
function g_PLSpawnSide(sideIndex)
    if P == nil or P[sideIndex] == nil then
        return
    end

    g_PLSpawnClearAllBuiltIn(sideIndex)
    for index = 1, getn(g_PLSpawnCars), 1 do
        if g_PLSpawnCars[index].SpecialInf ~= nil then
            g_PLSpawnFillType(sideIndex, g_PLSpawnCars[index], 1)
        end
    end
    for index = 1, getn(g_PLSpawnCars), 1 do
        g_PLSpawnFillType(sideIndex, g_PLSpawnCars[index])
    end
end

function g_PLSpawnTry()
    g_PLSpawnSide(7)
    g_PLSpawnSide(8)
end

function g_PLSpawnExecute(roundArg)
    local round = roundArg
    if round == nil then
        round = 0
        if exCounterGetByName ~= nil then
            round = exCounterGetByName("lvc")
        end
    end

    if g_PLSpawnLastRound == round and round ~= 0 then
        return
    end
    g_PLSpawnLastRound = round

    g_PLSpawnTry()

    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(g_PLSpawnHold, g_PLSpawnHoldDelay, {})
    else
        g_PLSpawnHold()
    end
end
