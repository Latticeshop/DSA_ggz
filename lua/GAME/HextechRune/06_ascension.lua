-- 讲解见 analysis/地图注释说明文档.md 附录 A.24、A.56、A.75

HextechRune = HextechRune or {}

HextechRune.AscensionTierPercent = { [1] = 30, [2] = 40, [3] = 50, [4] = 60 }
-- 体积固定倍率，与掷骰无关。
HextechRune.AscensionScale = 1.3
-- 掷骰概率：血量 40% / 伤害 30% / 攻速 20% / 射程 10%
-- （累计区间 0.40 / 0.70 / 0.90 / 1.00，最后一段就是射程）。
HextechRune.AscensionHealthChance = 0.40
HextechRune.AscensionDamageChance = 0.30
HextechRune.AscensionRateOfFireChance = 0.20
HextechRune.AscensionRangeChance = 0.10
HextechRune.AscensionAmmoChance = 0.10
-- 名单与 04_buff.lua 的无限火力飞机同源，统一取自 BasicVar 的登记表。
HextechRune.AmmoAircraftUnitTypes = nil

function HextechRune:GetAmmoAircraftUnitTypes()
    if self.AmmoAircraftUnitTypes == nil then
        local lookup = {}
        local names = g_TargetGroupNames.AmmoAircraftFamily
        for i = 1, getn(names), 1 do
            lookup[names[i]] = true
        end
        self.AmmoAircraftUnitTypes = lookup
    end
    return self.AmmoAircraftUnitTypes
end
-- playerIndex → 已累计层数（= 掷骰次数，配额与播报都看它）。
HextechRune.AscensionStacks = HextechRune.AscensionStacks or {}
-- playerIndex → { Health, Damage, RateOfFire, Range, Ammo }，各维已掷到的次数。
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

-- 回收 1 个单位掷一次加成种类：血量 / 伤害 / 攻速 / 射程，带弹药的飞机再多一维弹药。
function HextechRune:RollAscensionBonusKind(hasAmmo)
    local roll = GetRandomNumber()
    local damageChance = self.AscensionDamageChance
    if hasAmmo then
        damageChance = damageChance - self.AscensionAmmoChance
    end
    if roll < self.AscensionHealthChance then
        return "Health"
    end
    local threshold = self.AscensionHealthChance + damageChance
    if roll < threshold then
        return "Damage"
    end
    threshold = threshold + self.AscensionRateOfFireChance
    if roll < threshold then
        return "RateOfFire"
    end
    if not hasAmmo or roll < threshold + self.AscensionRangeChance then
        return "Range"
    end
    return "Ammo"
end

function HextechRune:IsAmmoAircraftUnitType(unitType)
    if unitType == nil then
        return false
    end
    return self:GetAmmoAircraftUnitTypes()[unitType] == true
end

function HextechRune:ApplyAmmoBonusToUnit(unit, multiplier)
    if multiplier == nil or multiplier <= 1 then
        return
    end
    for weaponIndex = 1, 5, 1 do
        local maxAmmo = ObjectGetWeaponSetUpdateWeaponMaxAmmoCount(unit, 1, 1, weaponIndex)
        if maxAmmo ~= nil and maxAmmo > 0 then
            local bonusAmmo = floor(maxAmmo * multiplier + 0.5)
            local currentAmmo = ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount(
                unit, 1, 1, weaponIndex)
            if currentAmmo == nil or bonusAmmo > currentAmmo then
                ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(unit, 1, 1, weaponIndex,
                    bonusAmmo)
            end
        end
    end
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
        counts = { Health = 0, Damage = 0, RateOfFire = 0, Range = 0, Ammo = 0 }
        self.AscensionBonusCounts[playerIndex] = counts
    end
    local rune = self:GetAscensionRune(playerIndex)
    local hasAmmo = rune ~= nil and self:IsAmmoAircraftUnitType(rune.TargetUnitType)
    for i = 1, count, 1 do
        local kind = self:RollAscensionBonusKind(hasAmmo)
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
    local health = self:GetAscensionBonusCount(playerIndex, "Health") * percent
    local damage = self:GetAscensionBonusCount(playerIndex, "Damage") * percent
    local rateOfFire = self:GetAscensionBonusCount(playerIndex, "RateOfFire") * percent
    local range = self:GetAscensionBonusCount(playerIndex, "Range") * percent
    local targetName = rune.TargetUnitName or rune.TargetUnitType or "?"
    local text
    if self:IsAmmoAircraftUnitType(rune.TargetUnitType) then
        text = Localization.get("hextech.rune.ascension.broadcast_ammo", targetName,
            health, damage, rateOfFire, range,
            self:GetAscensionBonusCount(playerIndex, "Ammo") * percent)
    else
        text = Localization.get("hextech.rune.ascension.broadcast", targetName,
            health, damage, rateOfFire, range)
    end
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, text, 10)
end

-- 目标单位在回收表里的配置项。超级要塞等使用 CountType 独立计数，需要一并匹配。
function HextechRune:FindAscensionUnitInfo(playerIndex, unitType)
    if g_PlayerSide == nil or g_RecycleBtnsMapByFaction == nil then
        return nil
    end
    -- 本引擎不接受 nil 键（会抛 table index is nil），座位表里查不到就先返回。
    local faction = g_PlayerSide[playerIndex]
    if faction == nil then
        return nil
    end
    local factionPool = g_RecycleBtnsMapByFaction[faction]
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
        if rune.TargetUnitIndex == nil or UNITCOUNT == nil
            or UNITCOUNT[playerIndex] == nil then
            return 0
        end
        return tonumber(UNITCOUNT[playerIndex][rune.TargetUnitIndex]) or 0
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
-- 名额：每名玩家每回合只登神一只（同兵种出了两只也只给第一只），跨两次出兵扫描都生效。
function HextechRune:ApplyAscensionUnits(assignments)
    if assignments == nil then
        return
    end
    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local playerIndex = assignment.PlayerIndex
        local rune = self:GetAscensionRune(playerIndex)
        if rune ~= nil and assignment.UnitIndex == rune.TargetUnitIndex then
            local stacks = self:GetAscensionStacks(playerIndex)
            if self:IsCurrentAssignment(assignment.Unit, assignment) and stacks > 0
                and not assignment.AscensionGranted
                and not self:IsRoundSlotTaken(playerIndex, "ascension") then
                ObjectLoadAttributeModifier(assignment.Unit,
                    self:CreateAscensionModifier(assignment.PlayerIndex),
                    self.PersistentBuffDuration)
                -- 弹药走武器槽，不进 Modifier：按掷到弹药的次数放大当前弹量。
                if self:IsAmmoAircraftUnitType(rune.TargetUnitType) then
                    local percent = self:GetAscensionTierPercent(rune.TargetUnitType)
                    self:ApplyAmmoBonusToUnit(assignment.Unit,
                        1 + self:GetAscensionBonusCount(assignment.PlayerIndex, "Ammo")
                            * percent / 100)
                end
                -- 体积与加成同时生效：固定倍率、永久缩放，不掷骰也不建信息框。
                exObjectSetFixedScale(ObjectGetId(assignment.Unit),
                    self.AscensionScale)
                RegisterNoStructureBuffUnit(assignment.Unit,
                    self:GetPlayerSideIndex(playerIndex))
                self:MarkRoundSlot(playerIndex, "ascension", assignment.Unit)
                assignment.AscensionGranted = true
            end
        end
    end
end
