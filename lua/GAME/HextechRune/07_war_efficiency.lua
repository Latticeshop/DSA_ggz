-- 讲解见 analysis/地图注释说明文档.md 附录 A.15、A.26、A.40

HextechRune = HextechRune or {}

HextechRune.WarEfficiencyRuneId = "prismatic_war_efficiency"
HextechRune.WarEfficiencyBonusPerDeathByEconomy = {
    [0.5] = 0.01,
    [1] = 0.01,
    [1.5] = 0.005,
    [2] = 0.005,
}
-- 兜底：认不出的经济倍率按高倍经济口径（默认 0.5%）。
HextechRune.WarEfficiencyDefaultBonusPerDeath = 0.005
-- 计数（Pending=上一回合累计、Active=本回合生效）与已加载标记都按玩家下标 1~6。
HextechRune.WarEfficiencyPending = HextechRune.WarEfficiencyPending or {}
HextechRune.WarEfficiencyActive = HextechRune.WarEfficiencyActive or {}
HextechRune.WarEfficiencyApplied = HextechRune.WarEfficiencyApplied or {}
HextechRune.WarEfficiencyModifiers = HextechRune.WarEfficiencyModifiers or {}
-- 本回合计已滚存过的回合号，保证同一回合只结算一次（见 RollWarEfficiencyCounters）。
HextechRune.WarEfficiencyRolledRound = HextechRune.WarEfficiencyRolledRound or nil

-- 本场每个死亡单位提供的基础加成：经济 <= 1 为 1%，1 < x <= 2 为 0.5%。
function HextechRune:GetWarEfficiencyBonusPerDeath()
    local perDeath = self.WarEfficiencyBonusPerDeathByEconomy[exModeGetCheatMultiplier()]
    if perDeath ~= nil then
        return perDeath
    end
    return self.WarEfficiencyDefaultBonusPerDeath
end

-- 百分比文案：0.5% 档会出现 x.5，整数不显示小数位（卡面简介与回合播报共用这一份换算）。
function HextechRune:FormatWarEfficiencyPercent(percent)
    local tenths = floor(percent * 10 + 0.5)
    if mod(tenths, 10) == 0 then
        return format("%d", tenths / 10)
    end
    return format("%d.%d", floor(tenths / 10), mod(tenths, 10))
end

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

function HextechRune:RollWarEfficiencyCounters()
    local round = tonumber(exCounterGetByName("lvc")) or 0
    if round >= 1 then
        if self.WarEfficiencyRolledRound == round then
            return
        end
        self.WarEfficiencyRolledRound = round
    end
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
    local percentPerDeath = self:GetWarEfficiencyBonusPerDeath() * 100
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local copies = self:GetPlayerWarEfficiencyCopies(playerIndex, unitType)
        if copies > 0 then
            local text = Localization.get("hextech.rune.war_efficiency.broadcast",
                Localization.get("hextech.unit_type." .. unitType),
                self:FormatWarEfficiencyPercent(counts[1] * copies * percentPerDeath),
                self:FormatWarEfficiencyPercent(counts[2] * copies * percentPerDeath),
                self:FormatWarEfficiencyPercent(counts[3] * copies * percentPerDeath),
                self:FormatWarEfficiencyPercent(counts[4] * copies * percentPerDeath))
            exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, text, 10)
        end
    end
end

-- 同一玩家的多份符文直接相加：每份让同一个死亡单位多提供一份基础加成
-- （基础值随经济倍率取 1% 或 0.5%，见 GetWarEfficiencyBonusPerDeath）。
function HextechRune:GetWarEfficiencyModifier(playerIndex, unitType, counts, copies)
    local perDeathPerCopy = self:GetWarEfficiencyBonusPerDeath()
    local cacheKey = tostring(playerIndex) .. ":" .. unitType .. ":"
        .. tostring(counts[1]) .. "," .. tostring(counts[2]) .. ","
        .. tostring(counts[3]) .. "," .. tostring(counts[4]) .. ":"
        .. tostring(copies) .. ":" .. tostring(perDeathPerCopy)
    if self.WarEfficiencyModifiers[cacheKey] == nil then
        local perDeath = perDeathPerCopy * copies
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
