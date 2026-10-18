-- 讲解见 analysis/地图注释说明文档.md 附录 A.42、A.59、A.74、A.80、A.83

HextechRune = HextechRune or {}

-- 匹配口径登记表：04_buff.lua 的统一入口 IsRuneMatchingUnit 按 Effect 查这几张表。
-- 阶级型（不看兵种）目前没有符文：回归基本功自 2026-10-19 起改成按兵种拆四份，表留空备用。
HextechRune.TierWideRuneEffects = {}
HextechRune.DualUnitTypeRuneEffects = { equivalent_exchange = true }
-- 全兵种型（致命节奏：步兵/载具/飞机/海军全都要）与固定兵种型（百虎上将：只认步兵）。
HextechRune.AllTypeRuneEffects = { lethal_tempo = true }
HextechRune.TypeSpecificRuneEffects = { five_tiger_generals = "infantry" }
HextechRune.InterlockUnsyncableEffects = { infinite_ammo = true }

-- 每族数值加成的规格：同族多份按加算合并成一枚、异族乘算。讲解见 analysis/地图注释说明文档.md 附录 A.83。
HextechRune.PerTypeStatModifierSpecs = {
    damage = { DAMAGE_MULT = 1.5 },
    rate_of_fire = { RATE_OF_FIRE = 1.5 },
    speed = { SPEED = 1.4 },
    range_silver = { RANGE = 1.15, VISION = 1.15 },
    range_gold = { RANGE = 1.25, VISION = 1.25 },
    range_prismatic = { RANGE = 1.5, VISION = 1.5 },
    astral_body = { HEALTH_MULT = 1.75, DAMAGE_MULT = 0.75 },
    goliath = { HEALTH_MULT = 1.9, DAMAGE_MULT = 1.25 },
    ragnarok = { DAMAGE_MULT = 1.9 },
}

-- 这只单位吃到同一族符文的几份：同名多张、载具/空军两个变体、元神互锁外溢过来的都算一份。
-- 互锁之所以会算进「两份」，是因为 IsRuneMatchingUnit 的互锁分支让伙伴兵种那张也命中同一只单位。
function HextechRune:CountMatchingRuneCopies(playerIndex, effect, unit, typeLookup)
    if playerIndex == nil or unit == nil then
        return 1
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    local count = 0
    for runeIndex = 1, getn(owned), 1 do
        local ownedRune = owned[runeIndex]
        if ownedRune.Effect == effect
            and self:IsRuneMatchingUnit(ownedRune, unit, typeLookup, playerIndex) then
            count = count + 1
        end
    end
    if count < 1 then
        return 1
    end
    return count
end

-- 按「族 + 份数」取合并后的修正器：1 + (倍率 - 1) * 份数，即同族多份线性相加。
-- 不在规格表里的效果返回 nil，调用方回落到原全局实例（行为不变）。
HextechRune.PerTypeStatModifiers = HextechRune.PerTypeStatModifiers or {}
function HextechRune:GetPerTypeStatModifier(rune, unit, typeLookup, playerIndex)
    local specs = self.PerTypeStatModifierSpecs[rune.Effect]
    if specs == nil then
        return nil
    end
    local count = self:CountMatchingRuneCopies(playerIndex, rune.Effect, unit, typeLookup)
    local cacheKey = rune.Effect .. ":" .. tostring(count)
    local modifier = self.PerTypeStatModifiers[cacheKey]
    if modifier == nil then
        local scaled = {}
        for key, value in specs do
            scaled[key] = 1 + (value - 1) * count
        end
        modifier = exAttributeModifierCreate(scaled, 1)
        self.PerTypeStatModifiers[cacheKey] = modifier
    end
    return modifier
end

-- 回归基本功（T1/T2 档）：血量、伤害、攻速、射程全部 +90%。
-- 射程与索敌视野必须同倍率，否则单位会在射程边缘停下却看不见目标。
if not g_HextechBackToBasicsHighModifier then
    g_HextechBackToBasicsHighModifier = exAttributeModifierCreate({
        HEALTH_MULT = 1.9, DAMAGE_MULT = 1.9,
        RATE_OF_FIRE = 1.9, RANGE = 1.9, VISION = 1.9,
    }, 1)
end
-- 回归基本功（T3/T4 档）：血量、伤害、攻速、射程全部降低 50%。
-- 射程下调刻意不联动 VISION（同全频段阻塞干扰）：只砍射程，不让自家单位变瞎。
if not g_HextechBackToBasicsLowModifier then
    g_HextechBackToBasicsLowModifier = exAttributeModifierCreate({
        HEALTH_MULT = 0.5, DAMAGE_MULT = 0.5,
        RATE_OF_FIRE = 0.5, RANGE = 0.5,
    }, 1)
end

-- 等价交换（兵种1，受益方）：血量 +90%、伤害/攻速/射程 +25%。
if not g_HextechExchangeBuffModifier then
    g_HextechExchangeBuffModifier = exAttributeModifierCreate({
        HEALTH_MULT = 1.9, DAMAGE_MULT = 1.25,
        RATE_OF_FIRE = 1.25, RANGE = 1.25, VISION = 1.25,
    }, 1)
end
-- 等价交换（兵种2，受损方）：血量 -90%、伤害/攻速/射程 -50%；射程同样不联动 VISION。
if not g_HextechExchangeDebuffModifier then
    g_HextechExchangeDebuffModifier = exAttributeModifierCreate({
        HEALTH_MULT = 0.1, DAMAGE_MULT = 0.5,
        RATE_OF_FIRE = 0.5, RANGE = 0.5,
    }, 1)
end

-- 指定兵种槽的命中判定：等价交换的第二个兵种挂在 rune.UnitType2 上，
-- 04_buff.lua 的 IsUnitInRuneType 只认 rune.UnitType，这里补一个按兵种名取表的版本。
function HextechRune:IsUnitInRuneTypeSlot(unit, typeLookup, unitType)
    if unitType == nil or typeLookup == nil or typeLookup[unitType] == nil then
        return false
    end
    return typeLookup[unitType][ObjectGetId(unit)] == true
end

function HextechRune:IsInterlockSlotUnit(unit, typeLookup, playerIndex, slotType)
    if slotType == nil then
        return false
    end
    if self:IsUnitInRuneTypeSlot(unit, typeLookup, slotType) then
        return true
    end
    if playerIndex == nil then
        return false
    end
    local partner = self:GetInterlockPartnerType(playerIndex, slotType)
    if partner == nil then
        return false
    end
    return self:IsUnitInRuneTypeSlot(unit, typeLookup, partner)
end

function HextechRune:IsRuneMatchingUnit(rune, unit, typeLookup, playerIndex)
    if rune == nil then
        return false
    end
    if self.TierWideRuneEffects[rune.Effect] == true then
        return true
    end
    if self.AllTypeRuneEffects[rune.Effect] == true then
        return true
    end
    if self.TypeSpecificRuneEffects[rune.Effect] ~= nil then
        return self:IsUnitInRuneTypeSlot(unit, typeLookup,
            self.TypeSpecificRuneEffects[rune.Effect])
    end
    if self:IsUnitInRuneType(unit, rune, typeLookup) then
        return true
    end
    if self.DualUnitTypeRuneEffects[rune.Effect] == true then
        -- 等价交换：受损方那一槽命中即算（受益方已在上面判过）；元神互锁让组内另一个
        -- 兵种也能吃这一份，具体落到哪一份由 ApplyBasicsOrExchangeToUnit 再分。
        return self:IsInterlockSlotUnit(unit, typeLookup, playerIndex, rune.UnitType2)
    end
    if playerIndex ~= nil and rune.UnitType ~= nil
        and not self.InterlockUnsyncableEffects[rune.Effect] then
        local partner = self:GetInterlockPartnerType(playerIndex, rune.UnitType)
        if partner ~= nil then
            return self:IsUnitInRuneTypeSlot(unit, typeLookup, partner)
        end
    end
    return false
end

function HextechRune:GetRuneUnitTier(unitIndex)
    if unitIndex == nil or UNITLIST == nil or UNITLIST[unitIndex] == nil then
        return nil
    end
    return self:GetUltimateCreatureUnitTier(UNITLIST[unitIndex])
end

-- 这只单位该吃哪一份 Modifier；返回 nil 表示不受本符文影响。
function HextechRune:GetBasicsOrExchangeModifier(rune, unit, typeLookup, unitIndex)
    if rune.Effect == "back_to_basics" then
        local tier = self:GetRuneUnitTier(unitIndex)
        if tier ~= nil and tier >= 3 then
            return g_HextechBackToBasicsLowModifier
        end
        -- 查不到阶级时按 T1/T2 口径放行：宁可给弱单位加成，也不要让单位静默漏掉整张符文。
        return g_HextechBackToBasicsHighModifier
    end
    if self:IsUnitInRuneTypeSlot(unit, typeLookup, rune.UnitType) then
        return g_HextechExchangeBuffModifier
    end
    return g_HextechExchangeDebuffModifier
end

function HextechRune:ApplyBasicsOrExchangeToUnit(rune, unit, typeLookup, unitIndex,
    playerIndex)
    if rune.Effect ~= "back_to_basics" and playerIndex ~= nil then
        local applied = false
        if self:IsInterlockSlotUnit(unit, typeLookup, playerIndex, rune.UnitType) then
            ObjectLoadAttributeModifier(unit, g_HextechExchangeBuffModifier,
                self.PersistentBuffDuration)
            applied = true
        end
        if self:IsInterlockSlotUnit(unit, typeLookup, playerIndex, rune.UnitType2) then
            ObjectLoadAttributeModifier(unit, g_HextechExchangeDebuffModifier,
                self.PersistentBuffDuration)
            applied = true
        end
        return applied
    end
    local modifier = self:GetBasicsOrExchangeModifier(rune, unit, typeLookup,
        unitIndex)
    if modifier == nil then
        return false
    end
    ObjectLoadAttributeModifier(unit, modifier, self.PersistentBuffDuration)
    return true
end

-- ===== 替换型符文的回收替换表（2026-10-19 从 04_buff.lua 外移到这里） =====
-- 原因：04_buff.lua 的 payload 去注释后只剩 106 B 余量，而本节点还有 55KB。
-- 那两个函数与这张表都是**运行时**才被调用的，搬到本节点不影响加载顺序。
HextechRune.UnitReplacementRunes = {
    { RuneId = "silver_export_domestic", SourceType = "JapanAntiNavyShipTech3",
        ReplacementType = "CelestialSeized_JapanAntiNavyShipTech3" },
    { RuneId = "silver_dual_purpose", SourceType = "SovietAntiAirShip",
        ReplacementType = "VUAntiAirVehicleTech1" },
    { RuneId = "silver_dragon_breathe", SourceType = "CelestialAntiInfantryVehicle_B",
        ReplacementType = "CelestialWaveriderIFV_DragonBreathe" },
    { RuneId = "silver_advanced_artillery", SourceType = "AlliedGunshipAircraft",
        ReplacementType = "AlliedAC130GunshipAircraft" },
    { RuneId = "silver_banzai_charge", SourceType = "JapanAntiInfantryInfantry",
        ReplacementType = "JapanKamikazeInfantry" },
    { RuneId = "silver_tulip_mortar", SourceType = "SovietAntiStructureVehicle",
        ReplacementType = "SovietHeavyMortarVehicle" },
    { RuneId = "gold_five_centimeters", SourceType = "JapanInterceptorAircraft",
        ReplacementType = "JapanSakuraAttackRocket" },
    { RuneId = "silver_wheeled_cannon", SourceType = "SovietHeavyAntiVehicleVehicleTech2",
        ReplacementType = "SovietHeavyAntiAirVehicleTech2" },
}

-- 在单位池正式计数前替换回收目标。抽卡单位的获得播报同样读取替换后的槽位，
-- 因而会直接显示升级单位，而不是先加入原单位再做二次转换。
function HextechRune:ResolveCollectedUnitIndex(playerIndex, unitIndex)
    self:EnsurePlayerRuneState(playerIndex)
    -- 本引擎不接受 nil 键（会抛 table index is nil）：槽位号或兵种表缺失时原样返回。
    if unitIndex == nil or UNITLIST == nil then
        return unitIndex
    end
    local sourceType = UNITLIST[unitIndex]
    local replacementType = nil
    for i = 1, getn(self.UnitReplacementRunes), 1 do
        local entry = self.UnitReplacementRunes[i]
        if entry.SourceType == sourceType
            and self.PlayerOwnedRuneIds[playerIndex][entry.RuneId] then
            replacementType = entry.ReplacementType
            break
        end
    end
    if replacementType == nil or g_UnitNameToUnitIndex == nil then
        return unitIndex
    end
    return g_UnitNameToUnitIndex[replacementType] or unitIndex
end

function HextechRune:IsKamikazeGiftWarrior(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    return self.PlayerOwnedRuneIds[playerIndex]["silver_banzai_charge"] == true
end
