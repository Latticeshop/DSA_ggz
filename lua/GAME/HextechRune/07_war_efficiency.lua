-- 海克斯符文“以战养战（兵种）”：敌方单位死亡按阶级累计，
--   累计值只用于下一回合该玩家自己名下的本兵种战斗单位。
-- 计数/生效全部按玩家独立（与诸神黄昏同一套单位归属口径）：队友持有的份数不再
-- 共享，只有同一玩家重复获取该符文才叠加（每份让一个死亡单位多提供 1%）。

HextechRune = HextechRune or {}

HextechRune.WarEfficiencyRuneId = "prismatic_war_efficiency"
-- 每一个 T1/T2/T3/T4 死亡单位提供 1% 血量/伤害/攻速/射程。
HextechRune.WarEfficiencyBonusPerDeath = 0.01
-- 计数（Pending=上一回合累计、Active=本回合生效）与已加载标记都按玩家下标 1~6。
HextechRune.WarEfficiencyPending = HextechRune.WarEfficiencyPending or {}
HextechRune.WarEfficiencyActive = HextechRune.WarEfficiencyActive or {}
HextechRune.WarEfficiencyApplied = HextechRune.WarEfficiencyApplied or {}
HextechRune.WarEfficiencyModifiers = HextechRune.WarEfficiencyModifiers or {}

function HextechRune:EnsureWarEfficiencyPlayerState(playerIndex)
    if self.WarEfficiencyPending[playerIndex] == nil then
        self.WarEfficiencyPending[playerIndex] = { 0, 0, 0, 0 }
    end
    if self.WarEfficiencyActive[playerIndex] == nil then
        self.WarEfficiencyActive[playerIndex] = { 0, 0, 0, 0 }
    end
    if self.WarEfficiencyApplied[playerIndex] == nil then
        self.WarEfficiencyApplied[playerIndex] = {}
    end
end

-- 该玩家自己持有某兵种以战养战的份数。
function HextechRune:GetPlayerWarEfficiencyCopies(playerIndex, unitType)
    self:EnsurePlayerRuneState(playerIndex)
    return self.PlayerOwnedRuneCounts[playerIndex][
        self.WarEfficiencyRuneId .. ":" .. unitType] or 0
end

function HextechRune:HasAnyWarEfficiency(playerIndex)
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        if self:GetPlayerWarEfficiencyCopies(playerIndex,
            self.UnitTypeOrder[typeIndex]) > 0 then
            return true
        end
    end
    return false
end

-- 死亡单位归属的战场 AI → 其所在阵营；对手阵营才是计数受益方。
function HextechRune:GetBattleOwnerSideIndex(ownerPlayerName)
    if ownerPlayerName == "PlyrCivilian" then
        return 7
    elseif ownerPlayerName == "PlyrCreeps" then
        return 8
    end
    return nil
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
    -- 同一批敌方死亡对每名持有者各计一次：数值只取决于自己的份数。
    local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        if self:HasAnyWarEfficiency(playerIndex) then
            self:EnsureWarEfficiencyPlayerState(playerIndex)
            local counts = self.WarEfficiencyPending[playerIndex]
            counts[tier] = counts[tier] + 1
        end
    end
end

-- 回合开始时把上一回合的敌方死亡数换成该玩家本回合数值，并向持有者本人播报。
function HextechRune:RollWarEfficiencyCounters()
    for playerIndex = 1, 6, 1 do
        self:EnsureWarEfficiencyPlayerState(playerIndex)
        self:ExpireWarEfficiencyBuffs(playerIndex)
        self.WarEfficiencyActive[playerIndex] = self.WarEfficiencyPending[playerIndex]
        self.WarEfficiencyPending[playerIndex] = { 0, 0, 0, 0 }
        self:BroadcastWarEfficiency(playerIndex)
    end
end

function HextechRune:BroadcastWarEfficiency(playerIndex)
    local counts = self.WarEfficiencyActive[playerIndex]
    if counts == nil or counts[1] + counts[2] + counts[3] + counts[4] <= 0 then
        return
    end
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local copies = self:GetPlayerWarEfficiencyCopies(playerIndex, unitType)
        if copies > 0 then
            local text = Localization.get("hextech.rune.war_efficiency.broadcast",
                Localization.get("hextech.unit_type." .. unitType),
                floor(counts[1] * copies), floor(counts[2] * copies),
                floor(counts[3] * copies), floor(counts[4] * copies))
            exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, text, 10)
        end
    end
end

-- 同一玩家的多份符文直接相加：每份让同一个死亡单位多提供 1%。
function HextechRune:GetWarEfficiencyModifier(playerIndex, unitType, counts, copies)
    local cacheKey = tostring(playerIndex) .. ":" .. unitType .. ":"
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
function HextechRune:ExpireWarEfficiencyBuffs(playerIndex)
    local applied = self.WarEfficiencyApplied[playerIndex]
    if applied == nil then
        return
    end
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

-- 只作用到按单位池配额归属给该玩家的战斗单位上（见 GetPlayerBattleEffectQuota）。
function HextechRune:ApplyWarEfficiencyBuffs(playerIndex, unitType, lookup)
    local copies = self:GetPlayerWarEfficiencyCopies(playerIndex, unitType)
    local counts = self.WarEfficiencyActive[playerIndex]
    if copies <= 0 or counts == nil
        or counts[1] + counts[2] + counts[3] + counts[4] <= 0 then
        return
    end
    local objects = lookup[unitType]
    if objects == nil then
        return
    end
    self:EnsureWarEfficiencyPlayerState(playerIndex)
    if self.WarEfficiencyApplied[playerIndex][unitType] == nil then
        self.WarEfficiencyApplied[playerIndex][unitType] = {}
    end
    local modifier = self:GetWarEfficiencyModifier(playerIndex, unitType, counts, copies)
    local applied = self.WarEfficiencyApplied[playerIndex][unitType]
    for objectId, value in objects do
        local assignment = self.BattleUnitAssignments[objectId]
        -- 登记的 Modifier 与本轮实例不同才重新加载：同一回合内的多次补扫
        -- 不会重复叠加，换回合后数值变化则自动换成新的本轮实例。
        if assignment ~= nil and assignment.PlayerIndex == playerIndex
            and assignment.Unit ~= nil and ObjectIsAlive(assignment.Unit)
            and applied[objectId] ~= modifier then
            ObjectLoadAttributeModifier(objectId, modifier,
                self.PersistentBuffDuration)
            applied[objectId] = modifier
            -- 以战养战每回合换一份实例，不走 AppliedRunes 标记，靠 Expire 覆盖过期。
            assignment.WarEfficiencyGranted = true
        end
    end
end

function HextechRune:ApplyAllWarEfficiencyBuffs()
    if P == nil then
        return
    end
    for sideIndex = 7, 8, 1 do
        local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
        local sideHasHolder = false
        for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
            if self:HasAnyWarEfficiency(playerIndex) then
                sideHasHolder = true
            end
        end
        if sideHasHolder then
            local lookup = self:BuildSideUnitTypeLookup(sideIndex)
            for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
                for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
                    self:ApplyWarEfficiencyBuffs(playerIndex,
                        self.UnitTypeOrder[typeIndex], lookup)
                end
            end
        end
    end
end
