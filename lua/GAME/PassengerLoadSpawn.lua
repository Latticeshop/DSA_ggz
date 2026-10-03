-- 机制依据、失败记录、字段含义、实测结论：DSA_ggz/analysis/地图注释说明文档.md §1（改之前先读 §1.13 自检清单）。
-- lua 里的注释会原样进 ScriptsData.json 的脚本 payload，所以这里只留指路行，不写说明。
-- 硬约束：兵一律不删（本方战斗单位）；装车只走 g_PLSpawnGarrison；成败只由 g_PLSpawnHold 延迟复核。

g_PLSpawnDebug = 1
g_PLSpawnLastRound = -1
g_PLSpawnConfigLogged = 0

g_PLSpawnCarsPerSide = 4
g_PLSpawnHoldDelay = 30
g_PLSpawnHoldTries = 2
g_PLSpawnNoEvac = 1
g_PLSpawnRandScale = 1000000

-- 台账条目 { CarId, UnitId, Tag, Retry }：Lua 4 没有 pairs，只能数组 + 整表重建（文档 §1.8）
g_PLSpawnEntries = {}

-- 载员名单 = 白名单，不写进来的兵种就等于被过滤（剔除原因见文档 §1.6）
g_PLSpawnAllInf = {
    "AlliedCryoLegionnaire",
    "AlliedAntiInfantryInfantry",
    "CelestialAntiInfantryInfantryAdvanced",
    "CelestialAntiInfantryInfantry",
    "CelestialAntiVehicleInfantry",
    "CelestialInfiltrationInfantry",
    "AlliedRangerInfantry",
    "JapanAntiInfantryInfantry",
    "JapanAntiVehicleInfantry",
    "JapanArcherInfantry",
    "SovietAntiInfantryInfantry",
    "SovietAntiVehicleInfantry",
    "SovietHeavyAntiVehicleInfantry",
    "JapanInfiltrationInfantry",
    "AlliedAntiVehicleInfantry",
}

-- 两型显示名都叫「联盟重型坦克」，所以日志靠 Tag 区分；牛蛙战车未配置（文档 §1.7）
g_PLSpawnCars = {
    { Template = "AlliedAntiAirVehicleTech1",     Capacity = 1, Inf = g_PLSpawnAllInf, Tag = "IFV" },
    -- 要塞登场自带 4 个标枪兵，只补 1 个位置；装满 5 会把自带的挤出去反复抽搐（文档 §1.14）
    { Template = "AlliedBattleFortress",          Capacity = 1, Inf = g_PLSpawnAllInf, Tag = "要塞" },
    { Template = "SovietAntiVehicleVehicleTech4", Capacity = 5, Inf = g_PLSpawnAllInf, Tag = "联盟" },
    { Template = "Overlordtank",                  Capacity = 5, Inf = g_PLSpawnAllInf, Tag = "重型" },
}

-- 下车按钮名按兵种不同，不做查表，全表一起下（文档 §1.5）
g_PLSpawnEvacButtons = {
    "Command_Evacuate",
    "Command_SovietBattleBunkerEvacuate",
    "Command_SovietAntiGroundAircraftEvacuate",
    "Command_CelestialGroundEvacuate",
    "Command_AlliedAntiInfantryVehicleEvacuate",
    "Command_DisguisedEvacuate",
    "Command_SpecialPowerEvacuateShipPassengers",
}

function g_PLSpawnLog(message)
    if g_PLSpawnDebug == 1 then
        _ALERT("PassengerLoadSpawn: " .. message)
    end
end

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
    -- Lua 4 没有 % 运算符，取模自己算
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
    -- Lua 里数字 0 是真值，所以只显式比成功值
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

function g_PLSpawnHold()
    local list = g_PLSpawnEntries
    g_PLSpawnEntries = {}
    local insideCount = 0
    local goneCount = 0
    local reloadCount = 0
    local dropCount = 0
    local ifvCount = 0
    local ifvInside = 0
    local ifvPassengers = 0

    for index = 1, getn(list), 1 do
        local item = list[index]
        local car = GetObjectById(item.CarId)
        local unit = GetObjectById(item.UnitId)
        local inside = false
        if car == nil or not ObjectIsAlive(car) then
            dropCount = dropCount + 1
        elseif unit == nil or not ObjectIsAlive(unit) then
            goneCount = goneCount + 1
        elseif g_PLSpawnInsideGarrison(unit) then
            inside = true
            insideCount = insideCount + 1
            item.Retry = 0
            tinsert(g_PLSpawnEntries, item)
        else
            item.Retry = item.Retry + 1
            if item.Retry > g_PLSpawnHoldTries then
                dropCount = dropCount + 1
            else
                reloadCount = reloadCount + 1
                g_PLSpawnGarrison(car, unit)
                tinsert(g_PLSpawnEntries, item)
            end
        end

        if item.Tag == "IFV" then
            ifvCount = ifvCount + 1
            if inside then
                ifvInside = ifvInside + 1
            end
            if ifvPassengers == 0 and car ~= nil and ObjectIsAlive(car) then
                local now = g_PLSpawnPassengerCount(car)
                if now ~= nil then
                    ifvPassengers = now
                end
            end
        end
    end

    if insideCount + goneCount + reloadCount + dropCount == 0 then
        return
    end
    g_PLSpawnLog("巡收 在=" .. insideCount .. " 没了=" .. goneCount
        .. " 塞回=" .. reloadCount .. " 放=" .. dropCount)
    if ifvCount > 0 then
        g_PLSpawnLog("IFV 台账=" .. ifvCount .. " 在车=" .. ifvInside
            .. " 车上=" .. ifvPassengers)
    end
end

function g_PLSpawnLoadCar(car, tag, slots, candidates, candidateCount)
    if candidates == nil or candidateCount == nil or candidateCount < 1 then
        return 0
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
                -- 乐观占位：下发就算成了，成败交给 g_PLSpawnHold
                loaded = loaded + 1
                g_PLSpawnTrackEntry(carId, unitId, tag)
            end
        end
    end
    return loaded
end

function g_PLSpawnCandidates(sideIndex, carEntry)
    if carEntry.InfFilter == nil then
        carEntry.InfFilter = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = carEntry.Inf,
        })
    end
    return ObjectFindObjects(P[sideIndex], nil, carEntry.InfFilter)
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
    return ObjectFindObjects(P[sideIndex], nil, carEntry.Filter)
end

function g_PLSpawnFillType(sideIndex, carEntry)
    local loaded = 0
    local filled = 0
    local short = 0
    local cars, count = g_PLSpawnFindCars(sideIndex, carEntry)
    if cars == nil or count == nil then
        return 0, 0, 0
    end
    for index = 1, count, 1 do
        if filled >= g_PLSpawnCarsPerSide then
            break
        end
        local car = cars[index]
        if car ~= nil and ObjectIsAlive(car) then
            local slots = g_PLSpawnFreeSlots(car, carEntry)
            if slots > 0 then
                g_PLSpawnDisableEvac(car)
                local candidates, candidateCount = g_PLSpawnCandidates(sideIndex, carEntry)
                local made = g_PLSpawnLoadCar(car, carEntry.Tag, slots,
                    candidates, candidateCount)
                loaded = loaded + made
                filled = filled + 1
                if made < slots then
                    short = short + 1
                end
            end
        end
    end
    return loaded, filled, short
end

function g_PLSpawnSide(sideIndex, sideName)
    if P == nil or P[sideIndex] == nil then
        g_PLSpawnLog("P[" .. sideIndex .. "] 未就绪，跳过 " .. sideName)
        return 0
    end

    local total = 0
    local cars = 0
    local short = 0
    for index = 1, getn(g_PLSpawnCars), 1 do
        if cars >= g_PLSpawnCarsPerSide then
            break
        end
        local loaded, filled, notEnough = g_PLSpawnFillType(sideIndex, g_PLSpawnCars[index])
        total = total + loaded
        cars = cars + filled
        short = short + notEnough
    end

    g_PLSpawnLog(sideName .. " 下发 " .. total .. " 名 车=" .. cars .. " 缺兵=" .. short)
    return total
end

function g_PLSpawnTry()
    local totalA = g_PLSpawnSide(7, "PlyrCivilian")
    local totalB = g_PLSpawnSide(8, "PlyrCreeps")
    return totalA + totalB
end

function g_PLSpawnDumpConfig()
    g_PLSpawnLog("配置 来源=自有兵 每阵营车数=" .. g_PLSpawnCarsPerSide
        .. " 兵池=" .. getn(g_PLSpawnAllInf) .. " 车种=" .. getn(g_PLSpawnCars)
        .. " 禁下车=" .. g_PLSpawnNoEvac)
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

    if g_PLSpawnConfigLogged ~= 1 then
        g_PLSpawnConfigLogged = 1
        g_PLSpawnDumpConfig()
    end

    local total = g_PLSpawnTry()
    g_PLSpawnLog("回合 " .. round .. " 共下发 " .. total .. " 名")

    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(g_PLSpawnHold, g_PLSpawnHoldDelay, {})
    else
        g_PLSpawnHold()
    end
end
