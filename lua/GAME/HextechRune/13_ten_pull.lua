-- 讲解见 analysis/地图注释说明文档.md 附录 A.31、A.41

-- 海克斯符文「十连」（黄金，可重复）：一次获得 10 个随机可回收单位，
-- 其中至少 1 个为 T4 及以上。先把 10 个结果一次抽好（缺保底则替换第 1 个），
-- 再逐个生成给玩家，由 unitregenerate 的周期回收折算进单位池。

HextechRune = HextechRune or {}

HextechRune.TenPullCount = 10
-- 保底阶级：结果里至少要有一个单位的阶级不低于该值（4 = T4 及以上，阶级表里 >4 的超阶单位按 4 结算）。
HextechRune.TenPullGuaranteedTier = 4
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

function HextechRune:IsTenPullHighTierType(unitType)
    if unitType == nil then
        return false
    end
    -- 被禁兵种不能当保底产出（含没有 UNITLIST 槽的要塞核心，按模板名判定）。
    if BanModeIsNameBanned(unitType) == 1 then
        return false
    end
    return self:GetUltimateCreatureUnitTier(unitType) >= self.TenPullGuaranteedTier
end

function HextechRune:TryAddTenPullHighTierType(types, seen, unitType)
    if unitType == nil or seen[unitType] then
        return
    end
    seen[unitType] = true
    if self:IsTenPullHighTierType(unitType) then
        tinsert(types, unitType)
    end
end

function HextechRune:GetTenPullHighTierTypes()
    if self.TenPullHighTierTypes == nil then
        local types = {}
        local seen = {}
        if g_RecycleBtnsMapByFaction ~= nil then
            for faction = 1, 4, 1 do
                local byCategory = g_RecycleBtnsMapByFaction[faction]
                if byCategory ~= nil then
                    for category = 1, 4, 1 do
                        local unitInfos = byCategory[category]
                        if unitInfos ~= nil then
                            for i = 1, getn(unitInfos), 1 do
                                self:TryAddTenPullHighTierType(types, seen,
                                    unitInfos[i].Type)
                            end
                        end
                    end
                end
            end
        end
        if g_CrateUnitsTemplate ~= nil then
            for category = 1, 4, 1 do
                local unitInfos = g_CrateUnitsTemplate[category]
                if unitInfos ~= nil then
                    for i = 1, getn(unitInfos), 1 do
                        self:TryAddTenPullHighTierType(types, seen,
                            unitInfos[i].Type)
                    end
                end
            end
        end
        self.TenPullHighTierTypes = types
    end
    return self.TenPullHighTierTypes
end

-- 先按全滚池抽满 10 个（结果统一存模板名）；若这 10 个里没有保底档单位，
-- 再把第 1 个换成保底名单里的随机一条。同一单位可以重复出现，不做去重。
function HextechRune:RollTenPullResults()
    local pool = self:GetTenPullPool()
    local poolCount = getn(pool)
    local results = {}
    if poolCount == 0 then
        return results
    end
    local hasGuaranteed = false
    for i = 1, self.TenPullCount, 1 do
        local unitType = UNITLIST[pool[self:RandomIndex(poolCount)]]
        results[i] = unitType
        if self:IsTenPullHighTierType(unitType) then
            hasGuaranteed = true
        end
    end
    if not hasGuaranteed then
        local high = self:GetTenPullHighTierTypes()
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
        local unitType = results[i]
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
