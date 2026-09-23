-- 海克斯符文“究极生物”：献祭玩家单位池，并在正常回合出兵时强化一只鬼王X。

HextechRune = HextechRune or {}

HextechRune.UltimateCreatureStates = HextechRune.UltimateCreatureStates or {}
HextechRune.UltimateCreatureEmperorsRageModifier =
    "AttributeModifer_JapanEmperorsResolve_L1"
HextechRune.UltimateCreatureScale = 1.3
HextechRune.UltimateCreatureSpawnedOnis =
    HextechRune.UltimateCreatureSpawnedOnis or { [7] = {}, [8] = {} }
HextechRune.UltimateCreatureRegisteredUnits =
    HextechRune.UltimateCreatureRegisteredUnits or {}

-- 鬼王X实际出生时记录对象和回合。固定出兵按玩家顺序生成单位，因此这份队列
-- 可以在同阵营混编后仍按 UNITCOUNT 配额准确找到每名玩家本回合的新鬼王X。
function HextechRune:OnUltimateCreatureOniBorn(createdObjId, ownerPlayerName)
    local sideIndex = nil
    if ownerPlayerName == "PlyrCivilian" then
        sideIndex = 7
    elseif ownerPlayerName == "PlyrCreeps" then
        sideIndex = 8
    end
    if sideIndex == nil then
        return
    end
    tinsert(self.UltimateCreatureSpawnedOnis[sideIndex], {
        Id = createdObjId,
        Round = tonumber(exCounterGetByName("lvc")) or 0,
    })
end

-- 使用抽卡模式的显式 T1~T4 表作为权威阶级来源。
-- 箱子隐藏单位不一定在该表中：优先识别模板名中的 Tech 阶级，再按回收价兜底。
function HextechRune:GetUltimateCreatureRecycleMoney(unitType)
    if g_RecycleBtnsMapByFaction ~= nil then
        for faction = 1, 4, 1 do
            local factionMap = g_RecycleBtnsMapByFaction[faction]
            if factionMap ~= nil then
                for category = 1, 4, 1 do
                    local unitInfos = factionMap[category]
                    if unitInfos ~= nil then
                        for i = 1, getn(unitInfos), 1 do
                            local info = unitInfos[i]
                            if info.Type == unitType or info.CountType == unitType then
                                return tonumber(info.Money) or 0
                            end
                        end
                    end
                end
            end
        end
    end
    if g_CrateUnits ~= nil then
        for category = 1, 4, 1 do
            local unitInfos = g_CrateUnits[category]
            if unitInfos ~= nil then
                for i = 1, getn(unitInfos), 1 do
                    if unitInfos[i].Type == unitType then
                        return tonumber(unitInfos[i].Money) or 0
                    end
                end
            end
        end
    end
    return 0
end

function HextechRune:GetUltimateCreatureUnitTier(unitType)
    if g_PureDrawUnitInfoByHash ~= nil then
        local info = g_PureDrawUnitInfoByHash[FastHash(unitType)]
        if info ~= nil and info.Tier ~= nil then
            return info.Tier
        end
    end

    local specialTiers = {
        AlliedGaintAirCraftCarrier_B = 4,
        AlliedThetisBattleShip = 4,
        JapanYumiAircraftCarrier = 4,
        Overlordtank = 4,
        WinterArmyReaperHeavyMecha = 3,
    }
    if specialTiers[unitType] ~= nil then
        return specialTiers[unitType]
    end

    if string ~= nil and string.find ~= nil then
        if string.find(unitType, "Tech4", 1, true) ~= nil then
            return 4
        elseif string.find(unitType, "Tech3", 1, true) ~= nil then
            return 3
        elseif string.find(unitType, "Tech2", 1, true) ~= nil then
            return 2
        elseif string.find(unitType, "Tech1", 1, true) ~= nil then
            return 1
        end
    end

    local money = self:GetUltimateCreatureRecycleMoney(unitType)
    if money > 3000 then
        return 4
    elseif money > 1800 then
        return 3
    elseif money > 1000 then
        return 2
    end
    return 1
end

function HextechRune:SacrificeUnitPoolForUltimateCreature(playerIndex)
    local tierCounts = { 0, 0, 0, 0 }
    local yaoguangCount = 0
    for unitIndex = 1, unitcountmax, 1 do
        local count = tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0
        if count > 0 then
            local unitType = UNITLIST[unitIndex]
            local tier = self:GetUltimateCreatureUnitTier(unitType)
            tierCounts[tier] = tierCounts[tier] + count
            if unitType == "CelestialAdvanceAircraftTech4" then
                yaoguangCount = count
            end
        end
        UNITCOUNT[playerIndex][unitIndex] = 0
        if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[playerIndex] ~= nil then
            CRATEUNITCOUNT[playerIndex][unitIndex] = 0
        end
    end

    -- 超级要塞核心使用独立计数槽，不计入 ANYUNITCOUNT，但仍属于玩家单位池。
    if g_UnitCount ~= nil then
        local gigaSlot = g_UnitCount[FastHash("JapanGigaFortressShipEgg")]
        if gigaSlot ~= nil then
            local gigaCount = tonumber(gigaSlot[playerIndex]) or 0
            tierCounts[4] = tierCounts[4] + gigaCount
            gigaSlot[playerIndex] = 0
        end
    end
    if yaoguangCount > 0 and RemovePlayerProducedYaoguangFromPool ~= nil then
        RemovePlayerProducedYaoguangFromPool(playerIndex, yaoguangCount)
    end
    ANYUNITCOUNT[playerIndex] = 0
    return tierCounts
end

function HextechRune:CreateUltimateCreature(playerIndex)
    local tierCounts = self:SacrificeUnitPoolForUltimateCreature(playerIndex)
    self.UltimateCreatureStates[playerIndex] = {
        TierCounts = tierCounts,
    }

    local oniIndex = g_UnitNameToUnitIndex["JapanMechaX"]
    if oniIndex ~= nil then
        UNITCOUNT[playerIndex][oniIndex] = 1
        ANYUNITCOUNT[playerIndex] = 1
    end
end

function HextechRune:IsUltimateCreatureRegistered(unit)
    if not ObjectIsAlive(unit) then
        return false
    end
    local entry = self.UltimateCreatureRegisteredUnits[ObjectGetId(unit)]
    return entry ~= nil and entry.Unit == unit
end

function HextechRune:CleanupUltimateCreatureRegistrations()
    for objectId, entry in self.UltimateCreatureRegisteredUnits do
        if entry.Unit == nil or not ObjectIsAlive(entry.Unit)
            or ObjectGetId(entry.Unit) ~= objectId then
            self.UltimateCreatureRegisteredUnits[objectId] = nil
        end
    end
end

function HextechRune:ApplyUltimateCreatureToUnit(unit, state, playerIndex)
    if not ObjectIsAlive(unit) then
        return false
    end
    if self:IsUltimateCreatureRegistered(unit) then
        return false
    end

    -- 每只究极鬼王X使用独立的动态Modifier实例，避免同一实例在不同对象间
    -- 表现为全场唯一或后加载者覆盖前一只。
    local tierCounts = state.TierCounts
    local modifier = exAttributeModifierCreate({
        HEALTH_MULT = 1 + tierCounts[1] * 0.05,
        DAMAGE_MULT = 1 + tierCounts[2] * 0.02,
        RATE_OF_FIRE = 1 + tierCounts[3] * 0.05,
        RANGE = 1 + tierCounts[4] * 0.10,
    }, 1)
    ObjectLoadAttributeModifier(unit, modifier,
        self.PersistentBuffDuration)
    -- 只加载天皇之怒一级的实际数值，不释放其范围武器和地面特效。
    ObjectLoadAttributeModifier(unit,
        self.UltimateCreatureEmperorsRageModifier,
        self.PersistentBuffDuration)
    -- 复用塔防守护者的固定缩放接口，只放大模型表现。
    exObjectSetFixedScale(ObjectGetId(unit), self.UltimateCreatureScale)
    self.UltimateCreatureRegisteredUnits[ObjectGetId(unit)] = {
        Unit = unit,
        PlayerIndex = playerIndex,
        Modifier = modifier,
    }
    return true
end

-- 每回合按实际出生队列，为每名持有者强化一只本回合新生成的鬼王X。
-- assignments 仅作为出生回调缺失时的兼容兜底，不再承担主要识别职责。
function HextechRune:ApplyUltimateCreatures(assignments, round)
    local oniIndex = g_UnitNameToUnitIndex["JapanMechaX"]
    if oniIndex == nil then
        return
    end
    local oniInstanceId = FastHash("JapanMechaX")
    local currentRound = tonumber(round) or tonumber(exCounterGetByName("lvc")) or 0
    local appliedPlayers = {}
    local appliedObjectIds = {}
    self:CleanupUltimateCreatureRegistrations()

    for sideIndex = 7, 8, 1 do
        local queue = self.UltimateCreatureSpawnedOnis[sideIndex] or {}
        local currentUnits = {}
        local futureEntries = {}
        for i = 1, getn(queue), 1 do
            local entry = queue[i]
            if entry.Round == currentRound and ObjectIsAlive(entry.Id)
                and ObjectGetInstanceId(entry.Id) == oniInstanceId then
                tinsert(currentUnits, GetObjectById(entry.Id))
            elseif entry.Round > currentRound then
                tinsert(futureEntries, entry)
            end
        end
        -- 当前回合及更早的记录用完即丢弃，避免长期游戏中对象ID复用旧数据。
        self.UltimateCreatureSpawnedOnis[sideIndex] = futureEntries

        local firstPlayerIndex = 1
        if sideIndex == 8 then
            firstPlayerIndex = 4
        end
        local cursor = 1
        for playerIndex = firstPlayerIndex, firstPlayerIndex + 2, 1 do
            local quota = tonumber(UNITCOUNT[playerIndex][oniIndex]) or 0
            local last = cursor + quota - 1
            if last > getn(currentUnits) then
                last = getn(currentUnits)
            end
            local state = self.UltimateCreatureStates[playerIndex]
            if state ~= nil then
                for unitPosition = cursor, last, 1 do
                    local unit = currentUnits[unitPosition]
                    if self:ApplyUltimateCreatureToUnit(unit, state, playerIndex) then
                        appliedPlayers[playerIndex] = true
                        appliedObjectIds[ObjectGetId(unit)] = true
                        break
                    end
                end
            end
            cursor = cursor + quota
        end
    end

    -- 出生队列未命中时，按用户可见规则直接从场上尚未登记的鬼王X中补选。
    -- 已进化且仍存活的旧鬼王X均在注册表中，因此不会阻挡新一只获得强化。
    for sideIndex = 7, 8, 1 do
        local firstPlayerIndex = 1
        if sideIndex == 8 then
            firstPlayerIndex = 4
        end
        local unregisteredUnits = {}
        local units, count = ObjectFindObjects(P[sideIndex], nil,
            FilterLIST[oniIndex])
        for i = 1, count, 1 do
            local unit = units[i]
            local objectId = ObjectGetId(unit)
            if not appliedObjectIds[objectId]
                and not self:IsUltimateCreatureRegistered(unit) then
                tinsert(unregisteredUnits, unit)
            end
        end
        local candidateIndex = 1
        for playerIndex = firstPlayerIndex, firstPlayerIndex + 2, 1 do
            local state = self.UltimateCreatureStates[playerIndex]
            if state ~= nil and not appliedPlayers[playerIndex] then
                while candidateIndex <= getn(unregisteredUnits) do
                    local unit = unregisteredUnits[candidateIndex]
                    candidateIndex = candidateIndex + 1
                    if self:ApplyUltimateCreatureToUnit(unit, state, playerIndex) then
                        appliedPlayers[playerIndex] = true
                        appliedObjectIds[ObjectGetId(unit)] = true
                        break
                    end
                end
            end
        end
    end

    -- 兼容旧地图加载顺序或出生回调未捕获的情况，仍从本轮新单位分配结果补一次。
    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local playerIndex = assignment.PlayerIndex
        local state = self.UltimateCreatureStates[playerIndex]
        if state ~= nil and not appliedPlayers[playerIndex]
            and assignment.UnitIndex == oniIndex
            and not appliedObjectIds[ObjectGetId(assignment.Unit)]
            and self:IsCurrentAssignment(assignment.Unit, assignment) then
            if self:ApplyUltimateCreatureToUnit(assignment.Unit, state,
                playerIndex) then
                assignment.UltimateCreatureGranted = true
                appliedPlayers[playerIndex] = true
            end
        end
    end
end
