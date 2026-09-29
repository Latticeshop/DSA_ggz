-- 海克斯符文“重组器”两档：
--   银色 变形重组器（recombobulator_same）：把单位池里的每个普通单位重滚成同一阶的随机单位；
--   彩色 升级重组器（recombobulator_upgrade）：重滚成高一阶的随机单位（T4 来源为随机 T4）。
-- 结果池只取生产单位与箱子单位（UNITLIST 里的可参战战斗单位，含已实装的别名形态），
-- 矿车、工程师、MCV 与尚未实装的预留单位由白名单排除。
-- 稀有单位（T5 双母舰 + T4 特等奖九台）合并成一个无视阶级的稀有池：
--   · 稀有来源 50% 抽整个稀有池（母舰与特等奖可互相转换，转回自身也算正常结果），
--     50% 当成普通单位继续走下面的普通规则；
--   · 普通来源只要目标档位落在 T4，就有 3% 抽进稀有池，即变形重组器的 T4 来源、
--     升级重组器的 T3 与 T4 来源；T5 在阶级表里按 T4 结算，双母舰也吃这条。
-- 稀有单位不进普通结果池，只能通过上面的概率抽中。
-- 禁海模式时海军（UNITLIST 的舰船与海上箱子段）从全部结果池中剔除。

HextechRune = HextechRune or {}

-- 普通来源目标落在 T4 时的稀有概率，和稀有来源保住稀有的概率。
HextechRune.RecombobulatorRareChance = 0.03
HextechRune.RecombobulatorRareKeepChance = 0.5
-- 稀有池无视阶级：母舰（T5，阶级表里按 T4 结算）与特等奖混在同一张表里互滚。
HextechRune.RecombobulatorRareTypes = {
    "AlliedGaintAirCraftCarrier_B",   -- 奥林匹斯级航空母舰
    "JapanYumiAircraftCarrier",       -- 千鸟特攻母舰
    "CelestialAdvanceAircraftTech4",  -- 摇光巡天炮
    "AlliedAntiStructureShip",        -- 航母
    "SovietAntiStructureShip",        -- 无畏
    "JapanAntiStructureShip",         -- 将军
    "CelestialAntiStructureShip",     -- 玄武
    "AlliedThetisBattleShip",         -- 忒提斯战列舰
    "SovietTransportAircraft_HeavyCannon", -- 重炮纤夫（实测武器过强，按稀有处理）
}

-- 稀有单位按 UNITLIST 下标登记：摇光的强化形态共用同一个下标，按类型名判定会漏。
function HextechRune:BuildRecombobulatorRareSet()
    if self.RecombobulatorRareIndexes ~= nil then
        return
    end
    local rare = {}
    local types = self.RecombobulatorRareTypes
    for i = 1, getn(types), 1 do
        local unitIndex = g_UnitNameToUnitIndex[types[i]]
        if unitIndex ~= nil then
            rare[unitIndex] = true
        end
    end
    self.RecombobulatorRareIndexes = rare
end

function HextechRune:IsRecombobulatorRareIndex(unitIndex)
    return self.RecombobulatorRareIndexes[unitIndex] == true
end

-- 结果类型白名单：抽卡生产池（含生产别名）+ 箱子模板。用白名单而不是 UNITLIST
-- 全量，是为了把尚未实装的预留单位排除在结果之外，避免重组出无法正常参战的单位。
function HextechRune:BuildRecombobulatorTypeFilter()
    if self.RecombobulatorAllowedTypes ~= nil then
        return self.RecombobulatorAllowedTypes
    end
    local allowed = {}
    if g_PureDrawBuildableUnitPool ~= nil then
        for tier = 1, 4, 1 do
            local tierPool = g_PureDrawBuildableUnitPool[tier]
            if tierPool ~= nil then
                for i = 1, getn(tierPool), 1 do
                    local unitType = tierPool[i].Type
                    if unitType ~= nil then
                        allowed[unitType] = true
                        local aliases = g_PureDrawProductionAliases[unitType]
                        if aliases ~= nil then
                            for aliasIndex = 1, getn(aliases), 1 do
                                allowed[aliases[aliasIndex]] = true
                            end
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
                    if unitInfos[i].Type ~= nil then
                        allowed[unitInfos[i].Type] = true
                    end
                end
            end
        end
    end
    self.RecombobulatorAllowedTypes = allowed
    return allowed
end

-- 禁海模式时海军不能作为结果：UNITLIST 的 step35+1..step4 是舰船与海上箱子段
-- （含海翼、忒提斯、双母舰）。牛蛙等在陆地物资段，不算海军。
function HextechRune:IsRecombobulatorNavalIndex(unitIndex)
    if g_DisableSeaArmy ~= 1 then
        return false
    end
    if step35 == nil or step4 == nil then
        return false
    end
    return unitIndex > step35 and unitIndex <= step4
end

-- 结果池按“类型 + 阶 + 海况”缓存：数据静态，每种组合只构建一次。
-- kind 为 "rare" 时 tier 省略，返回无视阶级的稀有池。
function HextechRune:GetRecombobulatorPool(kind, tier)
    if self.RecombobulatorPools == nil then
        self.RecombobulatorPools = {}
    end
    local key = kind .. (tier or 0)
    if g_DisableSeaArmy == 1 then
        key = key .. "_x"
    end
    if self.RecombobulatorPools[key] == nil then
        self.RecombobulatorPools[key] = self:CollectRecombobulatorPool(kind, tier)
    end
    return self.RecombobulatorPools[key]
end

function HextechRune:CollectRecombobulatorPool(kind, tier)
    self:BuildRecombobulatorRareSet()
    local allowed = self:BuildRecombobulatorTypeFilter()
    local pool = {}
    for unitIndex = 1, unitcountmax, 1 do
        if not self:IsRecombobulatorNavalIndex(unitIndex) then
            local wanted
            if kind == "rare" then
                wanted = self.RecombobulatorRareIndexes[unitIndex]
            else
                wanted = not self:IsRecombobulatorRareIndex(unitIndex)
                    and allowed[UNITLIST[unitIndex]] ~= nil
                    and self:GetUltimateCreatureUnitTier(UNITLIST[unitIndex]) == tier
            end
            if wanted then
                tinsert(pool, unitIndex)
            end
        end
    end
    return pool
end

function HextechRune:PickRecombobulatorPoolIndex(pool)
    if getn(pool) == 0 then
        return nil
    end
    return pool[self:RandomIndex(getn(pool))]
end

-- 单次重滚的目标下标。isUpgrade=false 为同阶（变形重组器），true 为升一阶（升级重组器）。
-- 稀有来源先抽 50%：中了就从无视阶级的稀有池里取一台（可能取回自身），
-- 没中则当普通单位继续走下面的普通规则。
-- 普通来源按目标档位重滚，目标落在 T4 时先抽 3% 稀有池。sourceIndex 缺失时按普通来源处理。
function HextechRune:RollRecombobulatorTargetIndex(sourceTier, isUpgrade, sourceIndex)
    local targetTier = sourceTier
    if isUpgrade and targetTier < 4 then
        targetTier = sourceTier + 1
    end

    local isRareSource = false
    if sourceIndex ~= nil then
        isRareSource = self:IsRecombobulatorRareIndex(sourceIndex)
    end
    if isRareSource and GetRandomNumber() < self.RecombobulatorRareKeepChance then
        local rarePool = self:GetRecombobulatorPool("rare")
        if getn(rarePool) > 0 then
            return self:PickRecombobulatorPoolIndex(rarePool)
        end
    end

    if targetTier >= 4 and GetRandomNumber() < self.RecombobulatorRareChance then
        local rarePool = self:GetRecombobulatorPool("rare")
        if getn(rarePool) > 0 then
            return self:PickRecombobulatorPoolIndex(rarePool)
        end
    end

    return self:PickRecombobulatorPoolIndex(self:GetRecombobulatorPool("tier", targetTier))
end

function HextechRune:ApplyRecombobulator(playerIndex, isUpgrade)
    self:BuildRecombobulatorRareSet()
    local newCounts = {}
    local newCrateCounts = {}

    for unitIndex = 1, unitcountmax, 1 do
        local count = tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0
        if count > 0 then
            local tier = self:GetUltimateCreatureUnitTier(UNITLIST[unitIndex])
            local crateCount = 0
            if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[playerIndex] ~= nil then
                crateCount = tonumber(CRATEUNITCOUNT[playerIndex][unitIndex]) or 0
                if crateCount > count then
                    crateCount = count
                end
            end
            -- 每个单位独立随机，不做整摞复用，重组结果因此可能分散成多种单位。
            for unit = 1, count, 1 do
                local targetIndex = self:RollRecombobulatorTargetIndex(tier, isUpgrade,
                    unitIndex)
                if targetIndex == nil then
                    -- 结果池为空时保留原单位，避免静默损失。
                    targetIndex = unitIndex
                end
                newCounts[targetIndex] = (newCounts[targetIndex] or 0) + 1
                if unit <= crateCount then
                    newCrateCounts[targetIndex] = (newCrateCounts[targetIndex] or 0) + 1
                end
            end
        end
    end

    -- 超级要塞核心走独立计数槽，按普通 T4 来源同规则重滚后清空；核心原本不计入
    -- ANYUNITCOUNT（见 05_ultimate_creature.lua），转成常规战斗单位后补上数量。
    local eggCount = 0
    if g_UnitCount ~= nil then
        local gigaSlot = g_UnitCount[FastHash("JapanGigaFortressShipEgg")]
        if gigaSlot ~= nil then
            eggCount = tonumber(gigaSlot[playerIndex]) or 0
            gigaSlot[playerIndex] = 0
        end
    end
    for egg = 1, eggCount, 1 do
        local targetIndex = self:RollRecombobulatorTargetIndex(4, isUpgrade)
        if targetIndex ~= nil then
            newCounts[targetIndex] = (newCounts[targetIndex] or 0) + 1
        end
    end
    if eggCount > 0 then
        ANYUNITCOUNT[playerIndex] = (tonumber(ANYUNITCOUNT[playerIndex]) or 0) + eggCount
    end

    -- 先清空全部计数（稀有单位同样被回收，只是走自己的 50% 稀有池规则），
    -- 再写入重组结果；箱子标记按来源数量搬走。
    for unitIndex = 1, unitcountmax, 1 do
        UNITCOUNT[playerIndex][unitIndex] = 0
        if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[playerIndex] ~= nil then
            CRATEUNITCOUNT[playerIndex][unitIndex] = 0
        end
    end
    for targetIndex, targetCount in newCounts do
        UNITCOUNT[playerIndex][targetIndex] =
            (UNITCOUNT[playerIndex][targetIndex] or 0) + targetCount
    end
    for targetIndex, targetCount in newCrateCounts do
        if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[playerIndex] ~= nil then
            CRATEUNITCOUNT[playerIndex][targetIndex] =
                (CRATEUNITCOUNT[playerIndex][targetIndex] or 0) + targetCount
        end
    end
end
