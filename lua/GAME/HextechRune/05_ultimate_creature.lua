-- 海克斯符文“究极生物”：献祭玩家单位池，并在每回合出兵时强化该玩家 1 只鬼王X。

HextechRune = HextechRune or {}

HextechRune.UltimateCreatureStates = HextechRune.UltimateCreatureStates or {}
HextechRune.UltimateCreatureEmperorsRageModifier =
    "AttributeModifer_JapanEmperorsResolve_L1"
HextechRune.UltimateCreatureScale = 1.3
HextechRune.UltimateCreatureRegisteredUnits =
    HextechRune.UltimateCreatureRegisteredUnits or {}

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
    local objectId = ObjectGetId(unit)
    local entry = self.UltimateCreatureRegisteredUnits[objectId]
    if entry == nil or entry.Unit == nil or not ObjectIsAlive(entry.Unit) then
        return false
    end
    local registeredObjectId = entry.ObjectId or ObjectGetId(entry.Unit)
    return registeredObjectId == objectId
end

function HextechRune:CleanupUltimateCreatureRegistrations()
    for objectId, entry in self.UltimateCreatureRegisteredUnits do
        if entry.Unit == nil or not ObjectIsAlive(entry.Unit)
            or (entry.ObjectId or ObjectGetId(entry.Unit)) ~= objectId then
            self.UltimateCreatureRegisteredUnits[objectId] = nil
        end
    end
end

-- NAMED_SHOW_INFOBOX 与天界守护者使用同一套命名对象信息框机制。
-- 鬼王X不是地编预命名单位，因此先按对象ID建立唯一单位引用，再显示本地化文案。
function HextechRune:ShowUltimateCreatureInfoBox(unit)
    local objectId = ObjectGetId(unit)
    local unitReference = "HextechUltimateCreature_" .. tostring(objectId)
    ExecuteAction("SET_UNIT_REFERENCE", unitReference, unit)
    TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", unitReference,
        "SCRIPT:UltimateCreature", 0, "")
    return unitReference
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
        HEALTH_MULT = 1 + (tierCounts[1] + tierCounts[4]) * 0.05,
        DAMAGE_MULT = 1 + tierCounts[2] * 0.02 + tierCounts[4] * 0.10,
        RATE_OF_FIRE = 1 + tierCounts[3] * 0.05,
    }, 1)
    ObjectLoadAttributeModifier(unit, modifier,
        self.PersistentBuffDuration)
    -- 只加载天皇之怒一级的实际数值，不释放其范围武器和地面特效。
    ObjectLoadAttributeModifier(unit,
        self.UltimateCreatureEmperorsRageModifier,
        self.PersistentBuffDuration)
    -- 复用塔防守护者的固定缩放接口，只放大模型表现。
    exObjectSetFixedScale(ObjectGetId(unit), self.UltimateCreatureScale)
    -- 与数值BUFF同步，为每只实际进化成功的鬼王X建立自己的常驻信息框。
    local infoBoxReference = self:ShowUltimateCreatureInfoBox(unit)
    self.UltimateCreatureRegisteredUnits[ObjectGetId(unit)] = {
        Unit = unit,
        ObjectId = ObjectGetId(unit),
        PlayerIndex = playerIndex,
        Modifier = modifier,
        InfoBoxReference = infoBoxReference,
    }
    return true
end

-- 复用普通数值BUFF的本轮新单位分配结果。即使普通载具 BUFF 使多只
-- 鬼王X同时进入 assignments，每名持有者每回合仍只进化其中 1 只。
-- 普通符文先于本函数加载，因此两个独立 Modifier 会按引擎属性规则叠加。
function HextechRune:ApplyUltimateCreatures(assignments)
    local oniIndex = g_UnitNameToUnitIndex["JapanMechaX"]
    if oniIndex == nil then
        return
    end
    local appliedPlayers = {}
    self:CleanupUltimateCreatureRegistrations()

    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local playerIndex = assignment.PlayerIndex
        local state = self.UltimateCreatureStates[playerIndex]
        if state ~= nil and not appliedPlayers[playerIndex]
            and assignment.UnitIndex == oniIndex
            and self:IsCurrentAssignment(assignment.Unit, assignment) then
            if self:ApplyUltimateCreatureToUnit(assignment.Unit, state,
                playerIndex) then
                assignment.UltimateCreatureGranted = true
                appliedPlayers[playerIndex] = true
            end
        end
    end
end
