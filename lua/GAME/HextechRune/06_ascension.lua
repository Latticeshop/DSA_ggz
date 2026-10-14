-- 讲解见 analysis/地图注释说明文档.md 附录 A.24、A.56

HextechRune = HextechRune or {}

-- 每回收 1 个目标单位掷一次：血量 / 伤害 / 攻速 / 射程 里随机命中一项。
-- 命中的幅度按目标单位的阶级取档：T1 30% / T2 40% / T3 50% / T4 60%。
HextechRune.AscensionTierPercent = { [1] = 30, [2] = 40, [3] = 50, [4] = 60 }
-- 体积固定倍率，与掷骰无关。
HextechRune.AscensionScale = 1.3
-- 掷骰概率：血量 40% / 伤害 30% / 攻速 20% / 射程 10%
-- （累计区间 0.40 / 0.70 / 0.90 / 1.00，最后一段就是射程）。
HextechRune.AscensionHealthChance = 0.40
HextechRune.AscensionDamageChance = 0.30
HextechRune.AscensionRateOfFireChance = 0.20
-- playerIndex → 已累计层数（= 掷骰次数，配额与播报都看它）。
HextechRune.AscensionStacks = HextechRune.AscensionStacks or {}
-- playerIndex → { Health, Damage, RateOfFire, Range }，各维已掷到的次数。
HextechRune.AscensionBonusCounts = HextechRune.AscensionBonusCounts or {}
-- 已转化过的对象，防止删除延迟导致同一只单位被重复计数。
HextechRune.AscensionConsumedUnitIds = HextechRune.AscensionConsumedUnitIds or {}
-- playerIndex → 已播报过的回合号，保证同一回合只播报一次（见 BroadcastAscension）。
HextechRune.AscensionBroadcastRound = HextechRune.AscensionBroadcastRound or {}

function HextechRune:GetAscensionRune(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == "ascension" then
            return rune
        end
    end
    return nil
end

function HextechRune:GetAscensionStacks(playerIndex)
    return self.AscensionStacks[playerIndex] or 0
end

-- 阶级判定与究极生物、以战养战共用同一个入口（返回 1~4，超阶按 T4 结算）。
function HextechRune:GetAscensionTierPercent(unitType)
    if unitType == nil then
        return 0
    end
    return self.AscensionTierPercent[self:GetUltimateCreatureUnitTier(unitType)] or 0
end

-- 回收 1 个单位掷一次加成种类：血量 / 伤害 / 攻速 / 射程。
function HextechRune:RollAscensionBonusKind()
    local roll = GetRandomNumber()
    if roll < self.AscensionHealthChance then
        return "Health"
    end
    if roll < self.AscensionHealthChance + self.AscensionDamageChance then
        return "Damage"
    end
    if roll < self.AscensionHealthChance + self.AscensionDamageChance
        + self.AscensionRateOfFireChance then
        return "RateOfFire"
    end
    return "Range"
end

function HextechRune:GetAscensionBonusCount(playerIndex, kind)
    local counts = self.AscensionBonusCounts[playerIndex]
    if counts == nil or counts[kind] == nil then
        return 0
    end
    return counts[kind]
end

-- 同一批回收的每个单位各自掷一次，可能掷到不同项。
function HextechRune:AddAscensionStacks(playerIndex, count)
    if count == nil or count <= 0 then
        return
    end
    self.AscensionStacks[playerIndex] = self:GetAscensionStacks(playerIndex) + count
    local counts = self.AscensionBonusCounts[playerIndex]
    if counts == nil then
        counts = { Health = 0, Damage = 0, RateOfFire = 0, Range = 0 }
        self.AscensionBonusCounts[playerIndex] = counts
    end
    for i = 1, count, 1 do
        local kind = self:RollAscensionBonusKind()
        counts[kind] = (counts[kind] or 0) + 1
    end
end

function HextechRune:BroadcastAscension(playerIndex)
    local round = tonumber(exCounterGetByName("lvc")) or 0
    if round >= 1 then
        if self.AscensionBroadcastRound[playerIndex] == round then
            return
        end
        self.AscensionBroadcastRound[playerIndex] = round
    end
    local rune = self:GetAscensionRune(playerIndex)
    local stacks = self:GetAscensionStacks(playerIndex)
    if rune == nil or stacks <= 0 then
        return
    end
    -- 播报各维累计到现在的加成；每层的幅度按目标单位阶级取档。
    local percent = self:GetAscensionTierPercent(rune.TargetUnitType)
    local text = Localization.get("hextech.rune.ascension.broadcast",
        rune.TargetUnitName or rune.TargetUnitType or "?",
        self:GetAscensionBonusCount(playerIndex, "Health") * percent,
        self:GetAscensionBonusCount(playerIndex, "Damage") * percent,
        self:GetAscensionBonusCount(playerIndex, "RateOfFire") * percent,
        self:GetAscensionBonusCount(playerIndex, "Range") * percent)
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, text, 10)
end

-- 目标单位在回收表里的配置项。超级要塞等使用 CountType 独立计数，需要一并匹配。
function HextechRune:FindAscensionUnitInfo(playerIndex, unitType)
    if g_PlayerSide == nil or g_RecycleBtnsMapByFaction == nil then
        return nil
    end
    local factionPool = g_RecycleBtnsMapByFaction[g_PlayerSide[playerIndex]]
    if factionPool == nil then
        return nil
    end
    for category = 1, 4, 1 do
        local unitInfos = factionPool[category]
        if unitInfos ~= nil then
            for i = 1, getn(unitInfos), 1 do
                local info = unitInfos[i]
                if info.Type == unitType or info.CountType == unitType then
                    return info
                end
            end
        end
    end
    return nil
end

-- 选择符文时：已有的目标单位回收掉，只留 1 个作为种子，其余直接转层数。
function HextechRune:GrantAscension(playerIndex, rune)
    if rune == nil or rune.TargetUnitType == nil then
        return
    end
    local unitInfo = self:FindAscensionUnitInfo(playerIndex, rune.TargetUnitType)
    if unitInfo == nil then
        return
    end
    local availableCount = GetRecycleUnitCount(playerIndex, unitInfo)
    if availableCount <= 1 then
        return
    end
    local removedCount = RemoveRecycleUnitCount(playerIndex, unitInfo, availableCount - 1)
    self:AddAscensionStacks(playerIndex, removedCount)
end

function HextechRune:GetAscensionPooledCount(playerIndex, rune)
    local unitInfo = self:FindAscensionUnitInfo(playerIndex, rune.TargetUnitType)
    if unitInfo == nil then
        return 0
    end
    return tonumber(GetRecycleUnitCount(playerIndex, unitInfo)) or 0
end

function HextechRune:AbsorbBuyTwoGetOneBonus(playerIndex, unitIndex)
    local rune = self:GetAscensionRune(playerIndex)
    if rune == nil or unitIndex ~= rune.TargetUnitIndex then
        return false
    end
    if self:GetAscensionPooledCount(playerIndex, rune) < 1 then
        return false
    end
    self:AddAscensionStacks(playerIndex, 1)
    return true
end

-- 兜底：买二送一赠送与同帧入池的种子撞在一起时，赠送会先落进单位池，
-- 池内就会出现 2 个。每帧回收计数后把多出来的部分统一转层，保证池内只有 1 个。
function HextechRune:TrimAscensionPoolSurplus(playerIndex)
    local rune = self:GetAscensionRune(playerIndex)
    if rune == nil then
        return
    end
    local unitInfo = self:FindAscensionUnitInfo(playerIndex, rune.TargetUnitType)
    if unitInfo == nil then
        return
    end
    local pooledCount = tonumber(GetRecycleUnitCount(playerIndex, unitInfo)) or 0
    if pooledCount <= 1 then
        return
    end
    local removedCount = RemoveRecycleUnitCount(playerIndex, unitInfo, pooledCount - 1)
    self:AddAscensionStacks(playerIndex, removedCount)
end

-- 系统回收（unitgetcountanddelet）计数前调用：单位池内已有种子时，本批目标单位
-- 不进入单位池，直接删除并转为层数；池内没有该单位时留 1 只走正常入池流程。
function HextechRune:FilterAscensionUnits(playerIndex, unitIndex, units, count)
    local rune = self:GetAscensionRune(playerIndex)
    if rune == nil or unitIndex ~= rune.TargetUnitIndex then
        return units, count
    end
    if count == nil or count <= 0 then
        return units, count
    end
    local pooledCount = self:GetAscensionPooledCount(playerIndex, rune)
    local needSeed = pooledCount < 1
    local kept = {}
    local keptCount = 0
    local converted = 0
    for i = 1, count, 1 do
        local unit = units[i]
        if ObjectIsAlive(unit) then
            local unitId = ObjectGetId(unit)
            if needSeed then
                needSeed = false
                keptCount = keptCount + 1
                kept[keptCount] = unit
            elseif self.AscensionConsumedUnitIds[unitId] == nil then
                self.AscensionConsumedUnitIds[unitId] = true
                if g_PureDrawProducedUnitIds ~= nil then
                    g_PureDrawProducedUnitIds[unitId] = nil
                end
                if PureDrawRemoveKnownPlayerUnit ~= nil then
                    PureDrawRemoveKnownPlayerUnit(unitId)
                end
                ExecuteAction("NAMED_DELETE", unit)
                converted = converted + 1
                -- 被转化的单位同样是玩家生产出来的，“买二送一”进度照常累计；
                -- 否则两个符文指同一个单位时，买二送一会永远停在 1。
                if self.OnPlayerUnitCollected ~= nil then
                    self:OnPlayerUnitCollected(playerIndex, unitIndex)
                end
            end
        end
    end
    if converted > 0 then
        self:AddAscensionStacks(playerIndex, converted)
    end
    return kept, keptCount
end

function HextechRune:CreateAscensionModifier(playerIndex)
    local rune = self:GetAscensionRune(playerIndex)
    local percent = self:GetAscensionTierPercent(rune.TargetUnitType)
    local healthCount = self:GetAscensionBonusCount(playerIndex, "Health")
    local damageCount = self:GetAscensionBonusCount(playerIndex, "Damage")
    local rateOfFireCount = self:GetAscensionBonusCount(playerIndex, "RateOfFire")
    local rangeCount = self:GetAscensionBonusCount(playerIndex, "Range")
    -- 各维只算自己掷到的次数；射程必须与索敌视野同倍率成对写入，
    -- 否则单位停在射程边缘却看不见目标。
    local rangeMult = 1 + rangeCount * percent / 100
    return exAttributeModifierCreate({
        HEALTH_MULT = 1 + healthCount * percent / 100,
        DAMAGE_MULT = 1 + damageCount * percent / 100,
        RATE_OF_FIRE = 1 + rateOfFireCount * percent / 100,
        RANGE = rangeMult,
        VISION = rangeMult,
    }, 1)
end

-- 每回合出兵后，把累计层数作为一个动态 Modifier 加载到该玩家的目标单位上。
-- 每只单位使用独立实例，与究极生物的处理方式一致。
function HextechRune:ApplyAscensionUnits(assignments)
    if assignments == nil then
        return
    end
    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local rune = self:GetAscensionRune(assignment.PlayerIndex)
        if rune ~= nil and assignment.UnitIndex == rune.TargetUnitIndex then
            local stacks = self:GetAscensionStacks(assignment.PlayerIndex)
            if self:IsCurrentAssignment(assignment.Unit, assignment) and stacks > 0
                and not assignment.AscensionGranted then
                ObjectLoadAttributeModifier(assignment.Unit,
                    self:CreateAscensionModifier(assignment.PlayerIndex),
                    self.PersistentBuffDuration)
                -- 体积与加成同时生效：固定倍率、永久缩放，不掷骰也不建信息框。
                exObjectSetFixedScale(ObjectGetId(assignment.Unit),
                    self.AscensionScale)
                RegisterNoStructureBuffUnit(assignment.Unit,
                    self:GetPlayerSideIndex(assignment.PlayerIndex))
                assignment.AscensionGranted = true
            end
        end
    end
end
