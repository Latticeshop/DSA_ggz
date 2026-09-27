-- 海克斯符文“以战养战（兵种）”：敌方单位死亡按阶级累计，
-- 累计值只用于下一回合本方该兵种的全体战斗单位。

HextechRune = HextechRune or {}

HextechRune.WarEfficiencyRuneId = "prismatic_war_efficiency"
-- 每一个 T1/T2/T3/T4 死亡单位提供 1% 血量/伤害/攻速/射程。
HextechRune.WarEfficiencyBonusPerDeath = 0.01
HextechRune.WarEfficiencyPending = HextechRune.WarEfficiencyPending or {
    [7] = { 0, 0, 0, 0 }, [8] = { 0, 0, 0, 0 },
}
HextechRune.WarEfficiencyActive = HextechRune.WarEfficiencyActive or {
    [7] = { 0, 0, 0, 0 }, [8] = { 0, 0, 0, 0 },
}
HextechRune.WarEfficiencyApplied = HextechRune.WarEfficiencyApplied or { [7] = {}, [8] = {} }
HextechRune.WarEfficiencyModifiers = HextechRune.WarEfficiencyModifiers or {}

-- 死亡单位归属的战场 AI → 其所在阵营；对手阵营才是计数受益方。
function HextechRune:GetBattleOwnerSideIndex(ownerPlayerName)
    if ownerPlayerName == "PlyrCivilian" then
        return 7
    elseif ownerPlayerName == "PlyrCreeps" then
        return 8
    end
    return nil
end

-- 计数按阵营共享，因此只要队伍里有任何一个兵种版本持有，就继续累计。
function HextechRune:GetSideWarEfficiencyCopies(sideIndex)
    local count = 0
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        count = count + self:GetSideRuneCopyCount(sideIndex,
            self.WarEfficiencyRuneId .. ":" .. self.UnitTypeOrder[typeIndex])
    end
    return count
end

function HextechRune:OnWarEfficiencyUnitDie(dyingObjInstanceId, ownerPlayerName)
    if not self.BattleDeathPhaseActive then
        return
    end
    local deadSideIndex = self:GetBattleOwnerSideIndex(ownerPlayerName)
    if deadSideIndex == nil then
        return
    end
    local sideIndex = 8
    if deadSideIndex == 8 then
        sideIndex = 7
    end
    if self:GetSideWarEfficiencyCopies(sideIndex) <= 0 then
        return
    end
    if g_UnitNameToUnitIndex == nil or UNITLIST == nil then
        return
    end
    local unitIndex = g_UnitNameToUnitIndex[dyingObjInstanceId]
    if unitIndex == nil then
        return
    end
    local tier = self:GetUltimateCreatureUnitTier(UNITLIST[unitIndex])
    if tier == nil or tier < 1 or tier > 4 then
        return
    end
    local counts = self.WarEfficiencyPending[sideIndex]
    counts[tier] = counts[tier] + 1
end

-- 回合开始时把上一回合的敌方死亡数换成本回合数值，并向持有队伍播报。
function HextechRune:RollWarEfficiencyCounters()
    for sideIndex = 7, 8, 1 do
        self:ExpireWarEfficiencyBuffs(sideIndex)
        self.WarEfficiencyActive[sideIndex] = self.WarEfficiencyPending[sideIndex]
        self.WarEfficiencyPending[sideIndex] = { 0, 0, 0, 0 }
        self:BroadcastWarEfficiency(sideIndex)
    end
end

function HextechRune:BroadcastWarEfficiency(sideIndex)
    local counts = self.WarEfficiencyActive[sideIndex]
    if counts[1] + counts[2] + counts[3] + counts[4] <= 0 then
        return
    end
    local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local copies = self:GetSideRuneCopyCount(sideIndex,
            self.WarEfficiencyRuneId .. ":" .. unitType)
        if copies > 0 then
            local text = Localization.get("hextech.rune.war_efficiency.broadcast",
                Localization.get("hextech.unit_type." .. unitType),
                floor(counts[1] * copies), floor(counts[2] * copies),
                floor(counts[3] * copies), floor(counts[4] * copies))
            for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
                exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, text, 10)
            end
        end
    end
end

-- 同一队伍的多份符文直接相加：每份让同一个死亡单位多提供 1%。
function HextechRune:GetWarEfficiencyModifier(sideIndex, unitType, counts, copies)
    local cacheKey = tostring(sideIndex) .. ":" .. unitType .. ":"
        .. tostring(counts[1]) .. "," .. tostring(counts[2]) .. ","
        .. tostring(counts[3]) .. "," .. tostring(counts[4]) .. ":"
        .. tostring(copies)
    if self.WarEfficiencyModifiers[cacheKey] == nil then
        local perDeath = self.WarEfficiencyBonusPerDeath * copies
        -- 射程与索敌视野必须同倍率，否则单位会停在射程边缘打不到目标。
        local rangeBonus = 1 + counts[4] * perDeath
        self.WarEfficiencyModifiers[cacheKey] = exAttributeModifierCreate({
            HEALTH_MULT = 1 + counts[1] * perDeath,
            DAMAGE_MULT = 1 + counts[2] * perDeath,
            RATE_OF_FIRE = 1 + counts[3] * perDeath,
            RANGE = rangeBonus,
            VISION = rangeBonus,
        }, 1)
    end
    return self.WarEfficiencyModifiers[cacheKey]
end

-- BUFF 只生效一回合：换回合时把上一份 Modifier 用 1 帧时长覆盖掉。
function HextechRune:ExpireWarEfficiencyBuffs(sideIndex)
    local applied = self.WarEfficiencyApplied[sideIndex]
    for unitType, objects in applied do
        for objectId, modifier in objects do
            local unit = GetObjectById(objectId)
            if unit ~= nil and ObjectIsAlive(unit) then
                ObjectLoadAttributeModifier(objectId, modifier, 1)
            end
        end
        applied[unitType] = {}
    end
end

-- 不走单位池配额：己方该兵种的全体战斗单位都要吃到本轮数值。
function HextechRune:ApplyWarEfficiencyBuffs(sideIndex, unitType, lookup)
    local copies = self:GetSideRuneCopyCount(sideIndex,
        self.WarEfficiencyRuneId .. ":" .. unitType)
    local counts = self.WarEfficiencyActive[sideIndex]
    if copies <= 0 or counts[1] + counts[2] + counts[3] + counts[4] <= 0 then
        return
    end
    local objects = lookup[unitType]
    if objects == nil then
        return
    end
    local modifier = self:GetWarEfficiencyModifier(sideIndex, unitType, counts, copies)
    if self.WarEfficiencyApplied[sideIndex][unitType] == nil then
        self.WarEfficiencyApplied[sideIndex][unitType] = {}
    end
    local applied = self.WarEfficiencyApplied[sideIndex][unitType]
    for objectId, value in objects do
        -- 登记的 Modifier 与本轮实例不同才重新加载：同一回合内的多次补扫
        -- 不会重复叠加，换回合后数值变化则自动换成新的本轮实例。
        if applied[objectId] ~= modifier then
            ObjectLoadAttributeModifier(objectId, modifier,
                self.PersistentBuffDuration)
            applied[objectId] = modifier
        end
    end
end

function HextechRune:ApplyAllWarEfficiencyBuffs()
    if P == nil then
        return
    end
    for sideIndex = 7, 8, 1 do
        local lookup = self:BuildSideUnitTypeLookup(sideIndex)
        for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
            self:ApplyWarEfficiencyBuffs(sideIndex, self.UnitTypeOrder[typeIndex],
                lookup)
        end
    end
end
