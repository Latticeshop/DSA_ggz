-- 讲解见 analysis/地图注释说明文档.md 附录 A.23

HextechRune = HextechRune or {}

-- 每次获得（可重复获取）吸取的数量上限。
HextechRune.DrainCount = 7

-- 吸星只扫对面卡池（UNITLIST/UNITCOUNT），所以这里只登记有槽位的赠予单位。
-- 超级要塞走独立计数槽、没有槽位，本来就不会被吸，不需要保护条目。
HextechRune.DrainRuneGiftUnits = {
    grant_yaoguang = { { "CelestialAdvanceAircraftTech4", 1 } },
    grant_olympus_carrier = {
        { "AlliedGaintAirCraftCarrier_B", 1 },
        { "JapanYumiAircraftCarrier", 1 },
    },
}

-- 该玩家因符文赠予而需要保留的单位数量（unitType → 个数）。
function HextechRune:BuildDrainProtectedCounts(playerIndex)
    local counts = {}
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local effect = owned[i].Effect
        local gifts = nil
        if effect == "ultimate_creature" then
            -- 究极生物的种子单位是选符时才随机固定的，只能读候选自己记录的目标。
            if owned[i].TargetUnitType ~= nil then
                gifts = { { owned[i].TargetUnitType, 1 } }
            end
        elseif effect ~= nil then
            gifts = self.DrainRuneGiftUnits[effect]
        end
        if gifts ~= nil then
            for j = 1, getn(gifts), 1 do
                counts[gifts[j][1]] = (counts[gifts[j][1]] or 0) + gifts[j][2]
            end
        end
    end
    return counts
end

-- 对面三个玩家卡池里的每一个单位各占一个条目（按数量展开），所以随机是按数量加权的：
-- 池子里数量多的单位被吸到的概率更大。对面符文赠予的那几份先扣掉，不参与抽取。
function HextechRune:CollectDrainSourceEntries(playerIndex)
    local entries = {}
    if UNITCOUNT == nil or UNITLIST == nil or unitcountmax == nil then
        return entries
    end
    local firstPlayerIndex, lastPlayerIndex =
        self:GetSidePlayerRange(self:GetEnemySideIndex(playerIndex))
    for enemyIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        local enemyPool = UNITCOUNT[enemyIndex]
        if enemyPool ~= nil then
            local protected = self:BuildDrainProtectedCounts(enemyIndex)
            for unitIndex = 1, unitcountmax, 1 do
                local unitType = UNITLIST[unitIndex]
                if unitType ~= nil then
                    local count = (tonumber(enemyPool[unitIndex]) or 0)
                        - (protected[unitType] or 0)
                    for i = 1, count, 1 do
                        tinsert(entries, { PlayerIndex = enemyIndex, UnitIndex = unitIndex })
                    end
                end
            end
        end
    end
    return entries
end

-- 该单位在对面池子里是否记为「箱子单位」。
function HextechRune:IsDrainCrateUnit(enemyIndex, unitIndex)
    if CRATEUNITCOUNT == nil or CRATEUNITCOUNT[enemyIndex] == nil then
        return false
    end
    return (tonumber(CRATEUNITCOUNT[enemyIndex][unitIndex]) or 0) > 0
end

-- 从对面卡池扣掉 1 个，返回「是否扣掉」与「是否箱子单位」（箱子标记随单位一起搬走）。
function HextechRune:RemoveDrainedUnitFromPool(enemyIndex, unitType, unitIndex)
    local isCrate = self:IsDrainCrateUnit(enemyIndex, unitIndex)
    local unitInfo = self:FindAscensionUnitInfo(enemyIndex, unitType)
    if unitInfo ~= nil and RemoveRecycleUnitCount ~= nil then
        local removedCount = RemoveRecycleUnitCount(enemyIndex, unitInfo, 1)
        if (removedCount or 0) <= 0 then
            return false, false
        end
    else
        local enemyPool = UNITCOUNT[enemyIndex]
        if enemyPool == nil then
            return false, false
        end
        local count = tonumber(enemyPool[unitIndex]) or 0
        if count <= 0 then
            return false, false
        end
        enemyPool[unitIndex] = count - 1
        if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[enemyIndex] ~= nil then
            ANYUNITCOUNT[enemyIndex] = ANYUNITCOUNT[enemyIndex] - 1
        end
    end
    if isCrate and CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[enemyIndex] ~= nil then
        CRATEUNITCOUNT[enemyIndex][unitIndex] =
            (tonumber(CRATEUNITCOUNT[enemyIndex][unitIndex]) or 0) - 1
    end
    return true, isCrate
end

-- 来源是箱子单位时把箱子标记一起搬过来。
function HextechRune:AddDrainedUnitToPool(playerIndex, unitIndex, isCrate)
    if UNITCOUNT == nil or UNITCOUNT[playerIndex] == nil then
        return false
    end
    UNITCOUNT[playerIndex][unitIndex] =
        (tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0) + 1
    if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[playerIndex] ~= nil then
        ANYUNITCOUNT[playerIndex] = (tonumber(ANYUNITCOUNT[playerIndex]) or 0) + 1
    end
    if isCrate and CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[playerIndex] ~= nil then
        CRATEUNITCOUNT[playerIndex][unitIndex] =
            (tonumber(CRATEUNITCOUNT[playerIndex][unitIndex]) or 0) + 1
    end
    return true
end

-- 每个条目只尝试一次：真拿到才占一个名额，扣不掉的（对面配置里走独立计数槽等）
-- 就换下一个条目继续，直到拿满 DrainCount 或把对面条目试完——对面不足 DrainCount 个则全取。
function HextechRune:ApplyDrainToPlayer(playerIndex)
    local entries = self:CollectDrainSourceEntries(playerIndex)
    local remaining = getn(entries)
    local drained = 0
    while drained < self.DrainCount and remaining > 0 do
        local pick = self:RandomIndex(remaining)
        local entry = entries[pick]
        local unitType = UNITLIST[entry.UnitIndex]
        if unitType ~= nil then
            local removed, isCrate = self:RemoveDrainedUnitFromPool(entry.PlayerIndex,
                unitType, entry.UnitIndex)
            if removed then
                self:AddDrainedUnitToPool(playerIndex, entry.UnitIndex, isCrate)
                drained = drained + 1
            end
        end
        entries[pick] = entries[remaining]
        entries[remaining] = nil
        remaining = remaining - 1
    end
    return drained
end
