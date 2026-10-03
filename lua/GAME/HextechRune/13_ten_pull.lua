-- 讲解见 analysis/地图注释说明文档.md 附录 A.31

-- 海克斯符文「十连」（金色，可重复）：一次获得 10 个随机可回收单位，
-- 其中至少 1 个为 T3 及以上。先把 10 个结果一次抽好（缺保底则替换第 1 个），
-- 再逐个生成给玩家，由 unitregenerate 的周期回收折算进单位池。

HextechRune = HextechRune or {}

HextechRune.TenPullCount = 10
-- 保底阶级：结果里至少要有一个单位的阶级不低于该值。
HextechRune.TenPullGuaranteedTier = 3
-- 生成落点：2 行 5 列的小方阵，避免十个单位叠在同一个坐标上。
-- 前方偏移沿用石油王/挖角已验证过的范围（120~180），两侧 ±120。
HextechRune.TenPullRowCount = 2
HextechRune.TenPullColumnCount = 5
HextechRune.TenPullForwardStep = 60
HextechRune.TenPullSideStep = 60
-- 方阵以出生点前方 120 为中心向两侧铺开。
HextechRune.TenPullForwardBase = 120

function HextechRune:GetTenPullPool()
    if self.TenPullPool ~= nil then
        return self.TenPullPool
    end
    self:BuildRecombobulatorRareSet()
    local allowed = self:BuildRecombobulatorTypeFilter()
    local pool = {}
    for unitIndex = 1, unitcountmax, 1 do
        local unitType = UNITLIST[unitIndex]
        if unitType ~= nil and allowed[unitType]
            and not self:IsRecombobulatorNavalIndex(unitIndex) then
            tinsert(pool, unitIndex)
        end
    end
    self.TenPullPool = pool
    return pool
end

-- 保底用池：阶级不低于 TenPullGuaranteedTier 的那些下标。
function HextechRune:GetTenPullHighTierPool()
    if self.TenPullHighTierPool == nil then
        local pool = self:GetTenPullPool()
        local high = {}
        for i = 1, getn(pool), 1 do
            if self:GetUltimateCreatureUnitTier(UNITLIST[pool[i]])
                >= self.TenPullGuaranteedTier then
                tinsert(high, pool[i])
            end
        end
        self.TenPullHighTierPool = high
    end
    return self.TenPullHighTierPool
end

-- 先按全池抽满 10 个；若这 10 个里没有 T3 及以上，再把第 1 个换成保底池的结果。
-- 同一单位可以重复出现，不做去重。
function HextechRune:RollTenPullResults()
    local pool = self:GetTenPullPool()
    local poolCount = getn(pool)
    local results = {}
    if poolCount == 0 then
        return results
    end
    local hasGuaranteed = false
    for i = 1, self.TenPullCount, 1 do
        local unitIndex = pool[self:RandomIndex(poolCount)]
        results[i] = unitIndex
        if self:GetUltimateCreatureUnitTier(UNITLIST[unitIndex])
            >= self.TenPullGuaranteedTier then
            hasGuaranteed = true
        end
    end
    if not hasGuaranteed then
        local high = self:GetTenPullHighTierPool()
        if getn(high) > 0 then
            results[1] = high[self:RandomIndex(getn(high))]
        end
    end
    return results
end

function HextechRune:GrantTenPull(playerIndex)
    local results = self:RollTenPullResults()
    if getn(results) == 0 then
        return
    end
    for i = 1, getn(results), 1 do
        local unitType = UNITLIST[results[i]]
        if unitType ~= nil then
            local row = floor((i - 1) / self.TenPullColumnCount)
            local column = (i - 1) - row * self.TenPullColumnCount
            self:MarkNextSpawnAsKnownPureDrawUnit()
            ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
                unitType, format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
                self:GetPlayerHomeSpawnPosition(playerIndex,
                    self.TenPullForwardBase + row * self.TenPullForwardStep,
                    (column - 2) * self.TenPullSideStep), 0)
        end
    end
end
