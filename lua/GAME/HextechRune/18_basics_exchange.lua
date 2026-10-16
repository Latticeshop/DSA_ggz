-- 讲解见 analysis/地图注释说明文档.md 附录 A.42、A.59

HextechRune = HextechRune or {}

-- 匹配口径登记表：04_buff.lua 的统一入口 IsRuneMatchingUnit 按 Effect 查这几张表。
HextechRune.TierWideRuneEffects = { back_to_basics = true }
HextechRune.DualUnitTypeRuneEffects = { equivalent_exchange = true }
-- 全兵种型（致命节奏：步兵/载具/飞机/海军全都要）与固定兵种型（百虎上将：只认步兵）。
HextechRune.AllTypeRuneEffects = { lethal_tempo = true }
HextechRune.TypeSpecificRuneEffects = { five_tiger_generals = "infantry" }

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

-- 04_buff.lua 的统一匹配入口：普通兵种符文仍看 UnitType；
-- 阶级型不看兵种，双兵种型两个槽位任一命中即算匹配（受哪一份加成由下面再分）。
function HextechRune:IsRuneMatchingUnit(rune, unit, typeLookup)
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
        return self:IsUnitInRuneTypeSlot(unit, typeLookup, rune.UnitType2)
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

-- 施加：与其它持续型符文一样整场有效（PersistentBuffDuration）。
-- 同一只单位被同时加载两份（例如 T1 步兵又正好是等价交换的兵种1）时按引擎属性规则叠加。
function HextechRune:ApplyBasicsOrExchangeToUnit(rune, unit, typeLookup, unitIndex)
    local modifier = self:GetBasicsOrExchangeModifier(rune, unit, typeLookup,
        unitIndex)
    if modifier == nil then
        return false
    end
    ObjectLoadAttributeModifier(unit, modifier, self.PersistentBuffDuration)
    return true
end
