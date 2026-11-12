-- 讲解见 analysis/地图注释说明文档.md 附录 A.32、A.47、A.48

HextechRune = HextechRune or {}

-- 匹配口径登记表：04_buff.lua 的统一入口 IsRuneMatchingUnit 按 Effect 查这几张表。
-- 阶级型（不看兵种）目前没有符文：回归基本功自 2026-10-19 起改成按兵种拆四份，表留空备用。
HextechRune.TierWideRuneEffects = {}
HextechRune.DualUnitTypeRuneEffects = { equivalent_exchange = true }
-- 全兵种型（致命节奏、泰坦的坚决：步兵/载具/飞机/海军全都要）与固定兵种型（百虎上将：只认步兵）。
HextechRune.AllTypeRuneEffects = { lethal_tempo = true, titan_resolve = true }
HextechRune.TypeSpecificRuneEffects = { five_tiger_generals = "infantry" }
HextechRune.InterlockUnsyncableEffects = { infinite_ammo = true }

-- 每族数值加成的规格：同族多份按加算合并成一枚、异族乘算。讲解见 analysis/地图注释说明文档.md 附录 A.32。
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

-- 回归基本功（T1/T2 档）：血量、伤害 +90%，攻速、射程 +50%（2026-10-24 数值调整）。
-- 射程与索敌视野必须同倍率，否则单位会在射程边缘停下却看不见目标。
if not g_HextechBackToBasicsHighModifier then
    g_HextechBackToBasicsHighModifier = exAttributeModifierCreate({
        HEALTH_MULT = 1.9, DAMAGE_MULT = 1.9,
        RATE_OF_FIRE = 1.5, RANGE = 1.5, VISION = 1.5,
    }, 1)
end
-- 回归基本功（T3/T4 档）：血量、伤害 -90%，攻速、射程 -50%（2026-10-24 数值调整）。
-- 射程下调刻意不联动 VISION（同全频段阻塞干扰）：只砍射程，不让自家单位变瞎。
if not g_HextechBackToBasicsLowModifier then
    g_HextechBackToBasicsLowModifier = exAttributeModifierCreate({
        HEALTH_MULT = 0.1, DAMAGE_MULT = 0.1,
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

-- ===== 护甲值系统=====
-- 护甲值 -> 减伤/增伤的换算口径、正负两支为什么能写成一条式子、以及为什么要在引擎的
-- ARMOR 之上再加这一层，讲解都搬到了 analysis/地图注释说明文档.md 附录 A.48

-- 护甲值 -> 减伤比例（正=减伤，负=增伤），四位小数。
function HextechRune.GetArmorReduction(armor)
    if armor == 0 then
        return 0
    end
    local denominator = 100 + armor
    if armor < 0 then
        -- 负护甲：分母取 100 + |护甲值|，避免 -100 时分母为 0。
        denominator = 100 - armor
    end
    return HextechRune.RoundToFourDecimals(armor / denominator)
end

-- 四位小数四舍五入（Lua 4.0 没有 round）。
function HextechRune.RoundToFourDecimals(value)
    local scaled = value * 10000
    if scaled >= 0 then
        return floor(scaled + 0.5) / 10000
    end
    return -floor(-scaled + 0.5) / 10000
end

-- 护甲值 -> COR 的 ARMOR 属性值（受伤倍率）。**给 BUFF 时一律走这里**，不要手写 ARMOR。
function HextechRune.GetArmorAttributeValue(armor)
    return HextechRune.RoundToFourDecimals(1 - HextechRune.GetArmorReduction(armor))
end

-- 护甲类符文：Effect -> 每份护甲点数。可重复，份数直接在护甲值上加算（边际效益递减）。
HextechRune.ArmorRunePoints = {
    armor_light = 25,      -- 锁子甲（白银）
    armor_heavy = 50,      -- 玄铁甲（黄金）
    armor_prismatic = 100, -- 金麟甲（棱彩）
    armor_shock = 25,      -- 装甲冲击（黄金）：25 点护甲，另外把护甲 1:1 折成伤害
    titan_resolve = 25,    -- 泰坦的坚决（棱彩）：25 点护甲，全兵种（不带 UnitType）
}

-- 护甲按「玩家 × 兵种」独立记账。兵种键与 UnitTypeOrder 一致。
HextechRune.ArmorUnitTypes = { "infantry", "vehicle", "aircraft", "navy" }
-- 非符文来源的护甲加成（预留给以后的技能 / 建筑 / 模式），加在符文护甲之上。
HextechRune.ArmorFlatBonus = { {}, {}, {}, {}, {}, {}, {}, {} }
-- 护甲值 -> ARMOR 修改器缓存（同一个护甲值只建一次）。
HextechRune.ArmorModifiers = {}

-- 某玩家某兵种当前的总护甲值 = 该兵种护甲类符文点数之和 + 全兵种护甲 + 非符文加成。
-- 元神互锁（数值 BUFF 两边同步）也照顾：锁住的伙伴兵种那侧的护甲同样加到这一侧。
-- 全兵种型（泰坦的坚决）在这里**只加一次**：如果塞进 GetPlayerArmorRunePoints，
-- 互锁那两个兵种的两次调用会把同一份点数算两遍。
function HextechRune:GetPlayerUnitTypeArmor(playerIndex, unitType)
    if playerIndex == nil or unitType == nil then
        return 0
    end
    self:EnsurePlayerRuneState(playerIndex)
    local total = self:GetPlayerArmorRunePoints(playerIndex, unitType)
    local partner = self:GetInterlockPartnerType(playerIndex, unitType)
    if partner ~= nil then
        total = total + self:GetPlayerArmorRunePoints(playerIndex, partner)
    end
    total = total + self:GetPlayerAllTypeArmorPoints(playerIndex)
    local flat = self.ArmorFlatBonus[playerIndex]
    if flat ~= nil then
        total = total + (flat[unitType] or 0)
        if partner ~= nil then
            total = total + (flat[partner] or 0)
        end
    end
    return total
end

-- 全兵种护甲类符文（不带 UnitType 的，如泰坦的坚决）的点数之和：每个兵种都吃这同一份。
function HextechRune:GetPlayerAllTypeArmorPoints(playerIndex)
    local total = 0
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        local points = self.ArmorRunePoints[rune.Effect]
        if points ~= nil and rune.UnitType == nil then
            total = total + points
        end
    end
    return total
end

-- 该兵种自己的护甲类符文点数之和（不含互锁外溢与非符文加成）。
function HextechRune:GetPlayerArmorRunePoints(playerIndex, unitType)
    local total = 0
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        local points = self.ArmorRunePoints[rune.Effect]
        if points ~= nil and rune.UnitType == unitType then
            total = total + points
        end
    end
    return total
end

-- 给某玩家某兵种加一笔非符文护甲（负数就是减甲）。
function HextechRune:AddPlayerUnitTypeArmorFlat(playerIndex, unitType, points)
    local flat = self.ArmorFlatBonus[playerIndex]
    if flat == nil then
        flat = {}
        self.ArmorFlatBonus[playerIndex] = flat
    end
    flat[unitType] = (flat[unitType] or 0) + points
end

-- 按护甲值取（并缓存）ARMOR 修改器；护甲值为 0 时返回 nil（不需要挂）。
function HextechRune:GetArmorModifier(armor)
    if armor == 0 then
        return nil
    end
    local cacheKey = tostring(armor)
    local modifier = self.ArmorModifiers[cacheKey]
    if modifier == nil then
        modifier = exAttributeModifierCreate(
            { ARMOR = HextechRune.GetArmorAttributeValue(armor) }, 1)
        self.ArmorModifiers[cacheKey] = modifier
    end
    return modifier
end

-- 装甲冲击（黄金）：持有这张符文的兵种，把「该兵种的总护甲值」按 1:1 折成伤害。
-- 口径 DAMAGE_MULT = 1 + 护甲值/100：护甲 25 → 1.25（+25% 伤害），护甲 -25 → 0.75（-25% 伤害）。
-- 负护甲这一段只有拿了这张符文才会生效——没拿的玩家负护甲仍然只是"更容易被打"。
-- 多份只是护甲 +25，伤害跟着护甲一起涨，所以不需要按份数另外叠。
HextechRune.ArmorShockRuneEffect = "armor_shock"
-- 护甲值 -> 伤害修改器缓存（同一个护甲值只建一次）。
HextechRune.ArmorShockModifiers = {}

-- 该玩家这个兵种有没有装甲冲击（元神互锁锁住的伙伴兵种那侧的也算，和护甲记账口径一致）。
function HextechRune:HasArmorShockRuneForType(playerIndex, unitType)
    if playerIndex == nil or unitType == nil then
        return false
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    local partner = self:GetInterlockPartnerType(playerIndex, unitType)
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == self.ArmorShockRuneEffect then
            if rune.UnitType == unitType then
                return true
            end
            if partner ~= nil and rune.UnitType == partner then
                return true
            end
        end
    end
    return false
end

-- 护甲值 -> 伤害修改器（1:1 折算）；护甲为 0 时返回 nil，不用挂。
function HextechRune:GetArmorShockModifier(armor)
    if armor == 0 then
        return nil
    end
    local cacheKey = tostring(armor)
    local modifier = self.ArmorShockModifiers[cacheKey]
    if modifier == nil then
        modifier = exAttributeModifierCreate(
            { DAMAGE_MULT = HextechRune.RoundToFourDecimals(1 + armor / 100) }, 1)
        self.ArmorShockModifiers[cacheKey] = modifier
    end
    return modifier
end

-- 把「登记玩家 × 该单位所属兵种」的护甲换算成 ARMOR 挂到单位上；拿了装甲冲击的兵种
-- 顺带把同一份护甲 1:1 折成伤害（DAMAGE_MULT）一起挂。
-- 同一只单位只挂一次（assignment.ArmorApplied）：护甲值是加算后再一次性换算的，
-- 绝不能按符文份数各挂一次，否则 25+25 会变成 0.8×0.8=0.64（36% 减伤）而不是正确的 33.3%。
function HextechRune:ApplyArmorToAssignment(assignment, typeLookup)
    if assignment == nil or assignment.ArmorApplied then
        return false
    end
    local unit = assignment.Unit
    if unit == nil or not ObjectIsAlive(unit) then
        return false
    end
    assignment.ArmorApplied = true
    local objectId = ObjectGetId(unit)
    for typeIndex = 1, getn(self.ArmorUnitTypes), 1 do
        local unitType = self.ArmorUnitTypes[typeIndex]
        local lookup = typeLookup[unitType]
        if lookup ~= nil and lookup[objectId] == true then
            local armor = self:GetPlayerUnitTypeArmor(assignment.PlayerIndex, unitType)
            local applied = false
            local modifier = self:GetArmorModifier(armor)
            if modifier ~= nil then
                ObjectLoadAttributeModifier(unit, modifier, self.PersistentBuffDuration)
                applied = true
            end
            if self:HasArmorShockRuneForType(assignment.PlayerIndex, unitType) then
                local shockModifier = self:GetArmorShockModifier(armor)
                if shockModifier ~= nil then
                    ObjectLoadAttributeModifier(unit, shockModifier,
                        self.PersistentBuffDuration)
                    applied = true
                end
            end
            -- 这一档没挂上任何东西就继续看下一档（多形态单位可能同时命中两个兵种表）。
            if applied then
                return true
            end
        end
    end
    return false
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
    { RuneId = "silver_five_centimeters", SourceType = "JapanInterceptorAircraft",
        ReplacementType = "JapanSakuraAttackRocket" },
    { RuneId = "silver_wheeled_cannon", SourceType = "SovietHeavyAntiVehicleVehicleTech2",
        ReplacementType = "SovietHeavyAntiAirVehicleTech2" },
}

-- 狂热武士：万岁冲锋持有者按上表的替换型条目 100% 换；
HextechRune.KamikazeBaseUnitType = "JapanAntiInfantryInfantry"
HextechRune.KamikazeUnitType = "JapanKamikazeInfantry"

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
    if replacementType == nil and sourceType == self.KamikazeBaseUnitType
        and self:RandomIndex(2) == 1 then
        -- 未持有万岁冲锋：回收时 50% 概率直接换成狂热武士（替换掉入池槽位，不额外赠送单位）。
        replacementType = self.KamikazeUnitType
    end
    if replacementType == nil or g_UnitNameToUnitIndex == nil then
        return unitIndex
    end
    return g_UnitNameToUnitIndex[replacementType] or unitIndex
end

-- 原「买二送一板载武士」
-- 现由 ResolveCollectedUnitIndex 的 50% 替换取代，保留注释以便回滚。
-- function HextechRune:IsKamikazeGiftWarrior(playerIndex)
--     self:EnsurePlayerRuneState(playerIndex)
--     return self.PlayerOwnedRuneIds[playerIndex]["silver_banzai_charge"] == true
-- end

-- ===== 金·烧福瑞 / 生异形 / 钓鱼佬 / 樱落：回合开始按本方份数比例替换敌方对应兵种 =====
HextechRune.BurnFurryRuneId = "gold_burn_furry"
HextechRune.SpawnAlienRuneId = "gold_spawn_alien"
HextechRune.AnglerRuneId = "gold_angler"
HextechRune.SitTightRuneId = "prismatic_sit_tight"
-- 同阵营份数 → 转化比例：1/2/3/4 份 = 25%/50%/75%/100%（超过 4 份按 100%）；
-- 当前 3v3 最多 3 份，第 4 档实际取不到，留给将来扩桌。
HextechRune.BurnFurryPercentByCopies = { 0.25, 0.50, 0.75, 1.00 }
-- 生成的动物随机取一个：警犬（盟军探路兵位）/ 战熊（苏联探路兵位）。
HextechRune.BurnFurryAnimalTypes = { "AlliedScoutInfantry", "SovietScoutInfantry" }
-- 生异形：敌方载具 → 恐怖机器人；钓鱼佬：敌方海军 → 海翼。
HextechRune.SpawnAlienUnitTypes = { "SovietScoutVehicle" }
HextechRune.AnglerUnitTypes = { "JapanAntiAirShip" }
HextechRune.SitTightUnitTypes = { "JapanInterceptorAircraft" }
-- 双形态单位按出生点归兵种：天狗/VX/心神/火箭天使算空军，不算载具/步兵。
-- 名单统一取自 BasicVar 的目标群体登记表；本节点早于它加载，所以过滤器懒建。
HextechRune.ConversionDualAirFilter = nil

function HextechRune:GetConversionDualAirFilter()
    if self.ConversionDualAirFilter == nil then
        self.ConversionDualAirFilter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            IncludeThing = g_CollectTargetNames(
                { "DualFormVehicleAir", "DualFormInfantryAir" }),
            Exclude = "STRUCTURE DEBRIS"
        })
    end
    return self.ConversionDualAirFilter
end

-- MCV 与运兵车不许被转化（运兵车一换会连带吞掉车上单位）；名单统一取自登记表。
HextechRune.ConversionNeverConvertInstanceIds = nil

function HextechRune:GetConversionNeverConvertInstanceIds()
    if self.ConversionNeverConvertInstanceIds == nil then
        local names = g_CollectTargetNames({ "MCV", "Transport" })
        local ids = {}
        for conversionTypeIndex = 1, getn(names), 1 do
            ids[FastHash(names[conversionTypeIndex])] = true
        end
        self.ConversionNeverConvertInstanceIds = ids
    end
    return self.ConversionNeverConvertInstanceIds
end

-- 载具转化要排除这些「空军出生点」单位，避免生异形把天狗/VX/心神当载具换掉。
HextechRune.ConversionVehicleFilter = nil

function HextechRune:GetConversionVehicleFilter()
    if self.ConversionVehicleFilter == nil then
        self.ConversionVehicleFilter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            Include = "VEHICLE HUGE_VEHICLE",
            Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS",
            ExcludeThing = g_CollectTargetNames({ "DualFormVehicleAir",
                "DualFormInfantryAir", "MCV", "Transport" })
        })
    end
    return self.ConversionVehicleFilter
end

-- 步兵转化同样按出生点：火箭天使走飞机批次，不能被烧福瑞换成狗熊。
HextechRune.ConversionInfantryFilter = nil

function HextechRune:GetConversionInfantryFilter()
    if self.ConversionInfantryFilter == nil then
        self.ConversionInfantryFilter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            Include = "INFANTRY",
            Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS",
            ExcludeThing = g_TargetGroupNames.DualFormInfantryAir
        })
    end
    return self.ConversionInfantryFilter
end
HextechRune.ConversionSystemInstanceIds = nil

function HextechRune:EnsureConversionSystemIds()
    if self.ConversionSystemInstanceIds ~= nil then
        return self.ConversionSystemInstanceIds
    end
    if BanModeBuildTypes == nil or g_BanModeNameTypes == nil then
        return nil
    end
    BanModeBuildTypes()
    if g_BanModeTypesReady ~= 1 then
        return nil
    end
    local ids = {}
    for unitName, types in g_BanModeNameTypes do
        ids[FastHash(unitName)] = true
    end
    if g_PureDrawProductionAliases ~= nil then
        for baseType, aliases in g_PureDrawProductionAliases do
            for i = 1, getn(aliases), 1 do
                ids[FastHash(aliases[i])] = true
            end
        end
    end
    if self.UnitReplacementRunes ~= nil then
        for i = 1, getn(self.UnitReplacementRunes), 1 do
            local replacementType = self.UnitReplacementRunes[i].ReplacementType
            if replacementType ~= nil then
                ids[FastHash(replacementType)] = true
            end
        end
    end
    self.ConversionSystemInstanceIds = ids
    return ids
end

-- 查表不可用时放行（宁可按老口径转化，也不要让符文静默失效）。
function HextechRune:IsConversionSystemUnit(unit)
    local ids = self:EnsureConversionSystemIds()
    if ids == nil then
        return true
    end
    local objectId = ObjectGetId(unit)
    if objectId == nil then
        return false
    end
    return ids[ObjectGetInstanceId(objectId)] == true
end

HextechRune.BurnFurryAppliedRound = HextechRune.BurnFurryAppliedRound or {}
HextechRune.SpawnAlienAppliedRound = HextechRune.SpawnAlienAppliedRound or {}
HextechRune.AnglerAppliedRound = HextechRune.AnglerAppliedRound or {}
HextechRune.SitTightAppliedRound = HextechRune.SitTightAppliedRound or {}
HextechRune.ConversionSpawnSerial = HextechRune.ConversionSpawnSerial or 0

function HextechRune:GetBurnFurryPercentByCopies(copies)
    local lastCopies = getn(self.BurnFurryPercentByCopies)
    if copies > lastCopies then
        copies = lastCopies
    end
    if copies < 1 then
        return 0
    end
    return self.BurnFurryPercentByCopies[copies]
end

-- 三个转化符文共用同一份份数口径。
function HextechRune:GetConversionRunePercent(sideIndex, runeId)
    local copies = self:GetSideOwnedRuneCount(sideIndex, runeId)
    if copies <= 0 then
        return 0
    end
    return self:GetBurnFurryPercentByCopies(copies)
end

function HextechRune:GetBurnFurryPercent(sideIndex)
    return self:GetConversionRunePercent(sideIndex, self.BurnFurryRuneId)
end

-- 卡面展示：三选一时候选还没到手，按「拿到之后」的份数算。
function HextechRune:GetConversionRuneDisplayPercent(playerIndex, runeId)
    local copies = 1
    if playerIndex ~= nil then
        self:EnsurePlayerRuneState(playerIndex)
        copies = self:GetSideOwnedRuneCount(self:GetPlayerSideIndex(playerIndex), runeId)
        if not self.PlayerOwnedRuneIds[playerIndex][runeId] then
            copies = copies + 1
        end
    end
    return floor(self:GetBurnFurryPercentByCopies(copies) * 100 + 0.5)
end

function HextechRune:GetBurnFurryDisplayPercent(playerIndex)
    return self:GetConversionRuneDisplayPercent(playerIndex, self.BurnFurryRuneId)
end

-- 对面是 AI 阵营（7=PlyrCivilian / 8=PlyrCreeps），没有「出兵出队」那一步，新单位要直接进攻击队才会参战。
function HextechRune:GetBurnFurryAttackTeam(sideIndex)
    if INFANTATTACK ~= nil and INFANTATTACK[sideIndex] ~= nil
        and INFANTATTACK[sideIndex][1] ~= nil then
        return INFANTATTACK[sideIndex][1]
    end
    if DEFAULTATTCKTEAM ~= nil and DEFAULTATTCKTEAM[sideIndex] ~= nil then
        return DEFAULTATTCKTEAM[sideIndex]
    end
    if sideIndex == 7 then
        return "PlyrCivilian/teamPlyrCivilian"
    end
    return "PlyrCreeps/teamPlyrCreeps"
end

-- 载具 / 海军走各自本回合的攻击队；取不到时退回默认队。
function HextechRune:GetConversionAttackTeam(sideIndex, unitType)
    if unitType == "vehicle" then
        if LIGHTVEHATTACK ~= nil and LIGHTVEHATTACK[sideIndex] ~= nil
            and LIGHTVEHATTACK[sideIndex][1] ~= nil then
            return LIGHTVEHATTACK[sideIndex][1]
        end
    elseif unitType == "navy" then
        if SHIPTEAMATTACK ~= nil and SHIPTEAMATTACK[sideIndex] ~= nil then
            return SHIPTEAMATTACK[sideIndex]
        end
    elseif unitType == "aircraft" then
        if AIRATTACK ~= nil and AIRATTACK[sideIndex] ~= nil
            and AIRATTACK[sideIndex][1] ~= nil then
            return AIRATTACK[sideIndex][1]
        end
    else
        return self:GetBurnFurryAttackTeam(sideIndex)
    end
    if DEFAULTATTCKTEAM ~= nil and DEFAULTATTCKTEAM[sideIndex] ~= nil then
        return DEFAULTATTCKTEAM[sideIndex]
    end
    if sideIndex == 7 then
        return "PlyrCivilian/teamPlyrCivilian"
    end
    return "PlyrCreeps/teamPlyrCreeps"
end

-- 在指定坐标生成替换单位；名字带序号，生成后回取句柄补星级。
function HextechRune:SpawnConvertedUnit(sideIndex, unitType, spawnTypes, spawnPrefix,
    x, y, z, levelCount)
    local spawnType = spawnTypes[self:RandomIndex(getn(spawnTypes))]
    self.ConversionSpawnSerial = self.ConversionSpawnSerial + 1
    local name = format("%s%d", spawnPrefix, self.ConversionSpawnSerial)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", name, spawnType,
        self:GetConversionAttackTeam(sideIndex, unitType), { X = x, Y = y, Z = z }, 0)
    local unit = GetObjectByScriptName(name)
    if unit == nil or not ObjectIsAlive(unit) then
        return false
    end
    -- 敌方单位按回合数升星，换出来的也要跟上，否则等于白送对面一波弱兵。
    for levelIndex = 1, levelCount, 1 do
        ExecuteAction("UNIT_GAIN_LEVEL", unit, 1)
    end
    return true
end

-- 烧福瑞的生成入口保留原名，内部走公共实现。
function HextechRune:SpawnBurnFurryAnimal(sideIndex, x, y, z, levelCount)
    return self:SpawnConvertedUnit(sideIndex, "infantry", self.BurnFurryAnimalTypes,
        "HextechBurnFurry", x, y, z, levelCount)
end

-- 任何转化符文都跳过：P[1..8] 锚点、MCV/龙船 MCV、6 个守护神、空军元帅技能召唤机。
function HextechRune:IsConversionProtectedUnit(unit)
    if unit == nil then
        return true
    end
    if P ~= nil then
        for anchorIndex = 1, 8, 1 do
            if P[anchorIndex] == unit then
                return true
            end
        end
    end
    -- 6 个守护神（overlord7/8、t533/t534、Sea3ProtectShip7/8）与塔守护者。
    if self:IsPresetMapUnit(unit) then
        return true
    end
    local objectId = ObjectGetId(unit)
    if objectId == nil then
        return false
    end
    -- 空军元帅等技能召唤出来的飞机，不参与任何转化。
    if IsSkillSummonedUnitId ~= nil and IsSkillSummonedUnitId(objectId) then
        return true
    end
    local instanceId = ObjectGetInstanceId(objectId)
    -- 龙船 MCV（龙行天下）与普通 MCV 同属禁转名单。
    if g_PlayerDragonShipHashes ~= nil
        and g_PlayerDragonShipHashes[instanceId] then
        return true
    end
    local neverIds = self:GetConversionNeverConvertInstanceIds()
    if neverIds == nil then
        return false
    end
    return neverIds[instanceId] == true
end

-- 登神 / 究极生物圈中的目标单位不参与任何转化：那两张符文把加成和体积都叠在唯一一只身上，
-- 被换掉等于白练。判定复用它们自己的登记表，不新增维护成本。
function HextechRune:IsConversionRuneBuffTargetUnit(unit)
    if unit == nil then
        return false
    end
    if self.IsUltimateCreatureRegistered ~= nil
        and self:IsUltimateCreatureRegistered(unit) then
        return true
    end
    if g_NoStructureBuffUnitIds == nil then
        return false
    end
    local objectId = ObjectGetId(unit)
    if objectId == nil or g_NoStructureBuffUnitIds[objectId] == nil then
        return false
    end
    return ObjectIsAlive(objectId)
end

-- 候选名单的统一口径：本方回收系统内、没被守护神/MCV/龙船/技能召唤占走、
-- 也不是登神/究极生物圈中的单位。
function HextechRune:IsConversionCandidateUnit(unit)
    return ObjectIsAlive(unit)
        and not self:IsPresetMapUnit(unit)
        and not self:IsConversionProtectedUnit(unit)
        and self:IsConversionSystemUnit(unit)
        and not self:IsConversionRuneBuffTargetUnit(unit)
end

-- 删掉对面该比例的指定兵种，并在原地生成等量的替换单位。只动 7/8 号阵营（PlyrCivilian / PlyrCreeps）
-- 的战场单位，不碰玩家单位池（UNITCOUNT 里的份数由玩家基地里的单位决定）。
function HextechRune:ConvertEnemyUnitsOfType(sideIndex, percent, filter, unitType,
    spawnTypes, spawnPrefix, extraFilter)
    if filter == nil or percent <= 0 then
        return 0
    end
    local units, count = g_SideFindObjects(sideIndex, nil, filter)
    if units == nil or type(count) ~= "number" then
        return 0
    end
    local candidates = {}
    local seen = {}
    for i = 1, count, 1 do
        if self:IsConversionCandidateUnit(units[i]) then
            seen[units[i]] = true
            tinsert(candidates, units[i])
        end
    end
    -- 双形态单位（天狗/VX/心神）当前可能是载具形态，AIRCRAFT 过滤器抓不到，
    -- 再用一份按模板名的过滤器补齐。
    if extraFilter ~= nil then
        local extraUnits, extraCount = g_SideFindObjects(sideIndex, nil, extraFilter)
        if extraUnits ~= nil and type(extraCount) == "number" then
            for i = 1, extraCount, 1 do
                local unit = extraUnits[i]
                if seen[unit] == nil
                    and self:IsConversionCandidateUnit(unit) then
                    seen[unit] = true
                    tinsert(candidates, unit)
                end
            end
        end
    end
    local total = getn(candidates)
    if total <= 0 then
        return 0
    end
    local targetCount = floor(total * percent + 0.5)
    if targetCount < 1 then
        targetCount = 1
    elseif targetCount > total then
        targetCount = total
    end
    local levelCount = 0
    if LEVELUP ~= nil and LEVELUP[sideIndex] ~= nil then
        levelCount = LEVELUP[sideIndex]
        if levelCount > 5 then
            levelCount = 5
        end
    end
    local converted = 0
    for i = 1, targetCount, 1 do
        -- 无放回随机：抽中的换到当前位置，后面的位置不会再抽到它。
        local pickIndex = i + self:RandomIndex(total - i + 1) - 1
        local pick = candidates[i]
        candidates[i] = candidates[pickIndex]
        candidates[pickIndex] = pick
        local x, y, z = ObjectGetPosition(pick)
        ExecuteAction("NAMED_DELETE", pick)
        if self:SpawnConvertedUnit(sideIndex, unitType, spawnTypes, spawnPrefix,
            x, y, z, levelCount) then
            converted = converted + 1
        end
    end
    return converted
end

function HextechRune:ConvertBurnFurryInfantry(sideIndex, percent)
    local filter = self:GetConversionInfantryFilter()
    return self:ConvertEnemyUnitsOfType(sideIndex, percent, filter, "infantry",
        self.BurnFurryAnimalTypes, "HextechBurnFurry")
end

-- 回合开始（出兵混编完成后）结算一次；补充军队会让回合效果重走一遍，按回合号去重。
-- 2026-10-19 用户实测反馈：去掉每回合的播报（会刷屏），只静默改造敌兵。
function HextechRune:ApplyBurnFurryPulse(round)
    if BanModeIsTypeEnabled ~= nil and BanModeIsTypeEnabled("infantry") ~= 1 then
        return
    end
    if round == nil then
        round = exCounterGetByName("lvc")
    end
    for holderSideIndex = 7, 8, 1 do
        local percent = self:GetBurnFurryPercent(holderSideIndex)
        if percent <= 0 then
            self.BurnFurryAppliedRound[holderSideIndex] = nil
        elseif self.BurnFurryAppliedRound[holderSideIndex] ~= round then
            self.BurnFurryAppliedRound[holderSideIndex] = round
            local targetSideIndex = self:GetOpposingSideIndex(holderSideIndex)
            self:ConvertBurnFurryInfantry(targetSideIndex, percent)
        end
    end
end

-- 生异形 / 钓鱼佬 / 樱落：与烧福瑞同份数口径，只换敌方兵种与替换单位。
-- 兵种被禁时该兵种不会出兵，对应的转化也不结算。
function HextechRune:ApplyConversionRuneBasePulse(runeId, unitType, spawnTypes,
    spawnPrefix, appliedRound, round, filter, extraFilter)
    if BanModeIsTypeEnabled ~= nil and BanModeIsTypeEnabled(unitType) ~= 1 then
        return
    end
    if round == nil then
        round = exCounterGetByName("lvc")
    end
    if filter == nil and self.UnitTypeFilters ~= nil then
        filter = self.UnitTypeFilters[unitType]
    end
    for holderSideIndex = 7, 8, 1 do
        local percent = self:GetConversionRunePercent(holderSideIndex, runeId)
        if percent <= 0 then
            appliedRound[holderSideIndex] = nil
        elseif appliedRound[holderSideIndex] ~= round then
            appliedRound[holderSideIndex] = round
            self:ConvertEnemyUnitsOfType(self:GetOpposingSideIndex(holderSideIndex),
                percent, filter, unitType, spawnTypes, spawnPrefix, extraFilter)
        end
    end
end

function HextechRune:ApplySpawnAlienPulse(round)
    self:ApplyConversionRuneBasePulse(self.SpawnAlienRuneId, "vehicle",
        self.SpawnAlienUnitTypes, "HextechSpawnAlien",
        self.SpawnAlienAppliedRound, round, self:GetConversionVehicleFilter())
end

function HextechRune:ApplyAnglerPulse(round)
    self:ApplyConversionRuneBasePulse(self.AnglerRuneId, "navy",
        self.AnglerUnitTypes, "HextechAngler",
        self.AnglerAppliedRound, round, self.UnitTypeFilters.navy)
end

function HextechRune:ApplySitTightPulse(round)
    self:ApplyConversionRuneBasePulse(self.SitTightRuneId, "aircraft",
        self.SitTightUnitTypes, "HextechSitTight",
        self.SitTightAppliedRound, round, self.UnitTypeFilters.aircraft,
        self:GetConversionDualAirFilter())
end

-- ===== 银·鸡汤来咯：回合开始让敌方随机 N 个载具或海军获得毒质腐蚀 =====
-- 口径与实测结论见 analysis/地图注释说明文档.md 附录 A.47。
HextechRune.IrradiateRuneId = "silver_chicken_soup"
HextechRune.IrradiateWeapon = "PlayerPowerIrradiateTargetWeapon"
HextechRune.IrradiateAppliedRound = HextechRune.IrradiateAppliedRound or {}

-- 「中毒」判据：2026-10-31 实测确认状态名就是 IRRADIATED。
HextechRune.IrradiatePoisonStatusName = "IRRADIATED"

function HextechRune:IsIrradiatePoisonedUnit(unit)
    if EvaluateCondition == nil or unit == nil or not ObjectIsAlive(unit) then
        return false
    end
    return EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit,
        self.IrradiatePoisonStatusName)
end

-- 统计候选里已经有几个中毒（用来「投满 N 个就收手、不够就换目标继续投」）。
function HextechRune:CountIrradiatePoisoned(candidates, total)
    local count = 0
    for i = 1, total, 1 do
        if self:IsIrradiatePoisonedUnit(candidates[i]) then
            count = count + 1
        end
    end
    return count
end

-- 候选扫描：引擎的 VEHICLE / HUGE_VEHICLE + 舰船 SHIP，不再做任何兵种过滤。
HextechRune.IrradiateScanFilter = nil

function HextechRune:GetIrradiateScanFilter()
    if self.IrradiateScanFilter == nil then
        self.IrradiateScanFilter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            Include = "VEHICLE HUGE_VEHICLE SHIP",
        })
    end
    return self.IrradiateScanFilter
end

-- 卡面展示：三选一时候选还没到手，按「拿到之后」的份数算（与烧福瑞同一口径）。
function HextechRune:GetIrradiateDisplayCount(playerIndex)
    local copies = 1
    if playerIndex ~= nil then
        self:EnsurePlayerRuneState(playerIndex)
        copies = self:GetSideOwnedRuneCount(self:GetPlayerSideIndex(playerIndex),
            self.IrradiateRuneId)
        if not self.PlayerOwnedRuneIds[playerIndex][self.IrradiateRuneId] then
            copies = copies + 1
        end
    end
    return copies
end

-- 开火锚点：本侧陆地塔 T74/T84（AT 立场的实测结论：从阵营锚点开火不出效果，要用塔）。
function HextechRune:GetSideTowerAnchor(sideIndex)
    local anchor = T74
    if sideIndex == 8 then
        anchor = T84
    end
    if anchor == nil or not ObjectIsAlive(anchor) then
        return nil
    end
    return anchor
end

-- 通用开火：把 weaponName 这把临时武器挂到 anchor 上，朝 unit 所在坐标开火。
function HextechRune:FireTempWeaponAtUnit(anchor, weaponName, unit)
    if anchor == nil or weaponName == nil or unit == nil then
        return false
    end
    if not ObjectIsAlive(anchor) or not ObjectIsAlive(unit) then
        return false
    end
    local x, y, z = ObjectGetPosition(unit)
    ObjectCreateAndFireTempWeaponToTarget(anchor, weaponName,
        { X = x, Y = y, Z = z }, unit)
    return true
end

-- 对一台载具投毒：从本侧陆地塔开一发 PlayerPowerIrradiateTargetWeapon。
function HextechRune:FireIrradiateAtUnit(sideIndex, unit)
    local anchor = self:GetSideTowerAnchor(sideIndex)
    if anchor == nil then
        return false
    end
    return self:FireTempWeaponAtUnit(anchor, self.IrradiateWeapon, unit)
end

-- 候选 = 敌方场上活着的载具/舰船，只排除预设单位（塔守护神 / 守护者）与技能召唤单位。
function HextechRune:CollectIrradiateTargets(sideIndex)
    local candidates = {}
    local units, count = g_SideFindObjects(sideIndex, nil,
        self:GetIrradiateScanFilter())
    if units ~= nil and type(count) == "number" then
        for i = 1, count, 1 do
            local unit = units[i]
            if unit ~= nil and ObjectIsAlive(unit)
                and not self:IsPresetMapUnit(unit)
                and not self:IsConversionProtectedUnit(unit) then
                tinsert(candidates, unit)
            end
        end
    end
    return candidates
end

-- 投一发，然后隔 15 帧（1 秒）复查中毒数量：投满了就收手，没投上就换下一个目标继续投。
function HextechRune:CastIrradiateAt(holderSideIndex, need, list, total, castIndex,
    attempts, maxAttempts, baseline)
    local target = list[castIndex]
    if target ~= nil and self:FireIrradiateAtUnit(holderSideIndex, target) then
        attempts = attempts + 1
    end
    SchedulerModule.delay_call(function(holder, count, cand, cnt, nextIndex, done, cap, base)
        HextechRune:RecheckIrradiate(holder, count, cand, cnt, nextIndex, done, cap, base)
    end, 15, { holderSideIndex, need, list, total, castIndex + 1, attempts, maxAttempts, baseline })
end

-- 复查：中毒数量补到 need 就不再投，否则换下一个候选继续投（最多 attempts 次）。
function HextechRune:RecheckIrradiate(holderSideIndex, need, list, total, castIndex,
    attempts, maxAttempts, baseline)
    local poisoned = self:CountIrradiatePoisoned(list, total) - baseline
    if poisoned >= need then
        return
    end
    if castIndex > total or attempts >= maxAttempts then
        return
    end
    self:CastIrradiateAt(holderSideIndex, need, list, total, castIndex, attempts,
        maxAttempts, baseline)
end

-- 回合开始（空军 / 轻载具批次出完之后）结算一次；按施放侧 + 回合号去重，
-- 补充军队让回合效果重走一遍也不会二次施放。
function HextechRune:ApplyIrradiatePulse(round)
    -- 载具与海军都被禁时没有任何可投毒目标，直接跳过。
    if BanModeTypesAllBanned ~= nil
        and BanModeTypesAllBanned({ "vehicle", "navy" }) == 1 then
        return
    end
    if round == nil then
        round = exCounterGetByName("lvc")
    end
    for holderSideIndex = 7, 8, 1 do
        local copies = self:GetSideOwnedRuneCount(holderSideIndex,
            self.IrradiateRuneId)
        if copies > 0 then
            -- 目标永远是「对面那一侧」的载具。
            local casterSideIndex = self:GetOpposingSideIndex(holderSideIndex)
            if self.IrradiateAppliedRound[casterSideIndex] ~= round then
                self.IrradiateAppliedRound[casterSideIndex] = round
                local candidates = self:CollectIrradiateTargets(casterSideIndex)
                local total = getn(candidates)
                if total > 0 then
                    if copies > total then
                        copies = total
                    end
                    -- 候选打乱一次，复查不过时换到的自然是别的目标。
                    for i = total, 2, -1 do
                        local j = self:RandomIndex(i)
                        local swap = candidates[i]
                        candidates[i] = candidates[j]
                        candidates[j] = swap
                    end
                    local baseline = self:CountIrradiatePoisoned(candidates, total)
                    self:CastIrradiateAt(holderSideIndex, copies, candidates, total,
                        1, 0, copies + 3, baseline)
                end
            end
        end
    end
end

function HextechRune:ApplyAllConversionPulses(round)
    self:ApplyBurnFurryPulse(round)
    self:ApplySpawnAlienPulse(round)
    self:ApplySitTightPulse(round)
    self:ApplyAnglerPulse(round)
    self:ApplyIrradiatePulse(round)
end

-- ===== 视距打击（伊尔信标）=====
-- 按 K 一次消耗 1 次、放出 n 架。次数不随份数膨胀，只有单次出机数量叠加。
-- 3 回合冷却：使用后 cd = 3，之后每个回合开始 -1，归零才补回 1 次。
g_HextechIlBeaconCharges = g_HextechIlBeaconCharges or { 0, 0, 0, 0, 0, 0, 0, 0 }
g_HextechIlBeaconCooldown = g_HextechIlBeaconCooldown or { 0, 0, 0, 0, 0, 0, 0, 0 }
HextechRune.IlBeaconCooldownRounds = 3

-- 部署出来的兵种取「带轰炸信标」的那一版：_Enhanced（升级形态）。
HextechRune.IlBeaconUnitType = "SovietAntiGroundAttacker_Enhanced"
-- 信标形态是伊尔的「变形切换」形态：带信标的单位对象状态上带着 TRANSFORMATION_TOGGLE_STATE。
HextechRune.IlBeaconTransformStatus = "TRANSFORMATION_TOGGLE_STATE"
HextechRune.IlBeaconTransformState = 1
-- 每架只给 1 发弹药 —— 它那一发就是「轰炸信标」。
HextechRune.IlBeaconShotsPerAircraft = 1
HextechRune.IlBeaconSpawnSerial = 0
-- 召唤点固定用轻型载具出生点第 3 个：LIGHTVEH13（恶魔侧）/ LIGHTVEH23（天使侧）。
-- 组名 + 侧号 + 序号，与 AIRRE1x / AIRRE2x 同一套写法（侧 7 = 恶魔 = "1"，侧 8 = 天使 = "2"）。
HextechRune.IlBeaconSpawnPointIndex = 3
-- 信标机的基础 buff：3 倍血量 + 2 倍移速。它是符文白送的临时单位、不占玩家配额，
HextechRune.IlBeaconHealthMultiplier = 3
HextechRune.IlBeaconSpeedMultiplier = 2
-- 这架不是正常出兵流程的编制，所以单独记账，由看门狗盯着：一飞回本方机场的换弹区就删掉。
HextechRune.IlBeaconMarkByObjectId = HextechRune.IlBeaconMarkByObjectId or {}
HextechRune.IlBeaconWatchIntervalFrames = 5     -- 每 5 帧查一次
HextechRune.IlBeaconArmDelayFrames = 15         -- 出生后 1 秒内不判定
HextechRune.IlBeaconRearmRadius = 500           -- 与 PLANEREBORN 删除返航飞机的半径同口径
HextechRune.IlBeaconWatchdogStarted = false
-- 下回合发次数时提示重新长出来。帧级窗口会让按钮“按了没反应、其实已经放出去”，所以不用它。
g_HextechIlBeaconUsedThisRound = g_HextechIlBeaconUsedThisRound or {}
-- 兜底寿命：万一既没飞回换弹区也没被打掉，到点直接删，不留场。
HextechRune.IlBeaconMaxLifetimeFrames = 900
-- 屏幕提示与湮灭炸弹同一行（两张符文 K 键互斥，不可能同时持有，所以不会叠字）。
HextechRune.IlBeaconHintTextIndexBase = 920
HextechRune.IlBeaconHintCenterX = 683
HextechRune.IlBeaconHintY = 104
HextechRune.IlBeaconHintFontSize = 16

-- 持有份数 = 已选到这张可重复符文的次数；同时也是每次部署的架数。
function HextechRune:GetIlBeaconCopyCount(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    local count = 0
    for i = 1, getn(owned), 1 do
        if owned[i].Effect == "grant_il_beacon" then
            count = count + 1
        end
    end
    return count
end

function HextechRune:AddIlBeaconCharge(playerIndex)
    g_HextechIlBeaconCharges[playerIndex] =
        (g_HextechIlBeaconCharges[playerIndex] or 0) + 1
    if self.RefreshIlBeaconHint ~= nil then
        self:RefreshIlBeaconHint(playerIndex)
    end
end

-- 由 02_event.lua 的 OnRoundBegin 驱动（与五雷轰顶同一条回调链）。
function HextechRune:OnIlBeaconRoundBegin(round)
    for playerIndex = 1, 8, 1 do
        g_HextechIlBeaconUsedThisRound[playerIndex] = nil
        if self:GetIlBeaconCopyCount(playerIndex) > 0 then
            local cooldown = g_HextechIlBeaconCooldown[playerIndex] or 0
            if cooldown > 0 then
                cooldown = cooldown - 1
                g_HextechIlBeaconCooldown[playerIndex] = cooldown
            end
            if cooldown <= 0
                and (g_HextechIlBeaconCharges[playerIndex] or 0) <= 0 then
                self:AddIlBeaconCharge(playerIndex)
            end
        end
    end
end

-- 04_buff.lua 的 OnRuneChosen 分发过来：选到当刻先把这一回合的次数发下去，不必等下一回合。
function HextechRune:OnIlBeaconChosen(playerIndex)
    self:AddIlBeaconCharge(playerIndex)
end

-- 座位 → 本方阵营号。空军侧一共两个阵营（恶魔 7 / 天使 8）。
function HextechRune:GetIlBeaconSideIndex(playerIndex)
    if g_SeatToSide == nil then
        return nil
    end
    return g_SeatToSide(playerIndex)
end

-- 这架飞机挂在「本方 AI 阵营的空军攻击队」里，由飞机 AI 自己管控，不走玩家队伍。
function HextechRune:GetIlBeaconAircraftTeam(sideIndex)
    if AIRATTACK ~= nil and AIRATTACK[sideIndex] ~= nil
        and AIRATTACK[sideIndex][1] ~= nil then
        return AIRATTACK[sideIndex][1]
    end
    if AIRTEAM ~= nil and AIRTEAM[sideIndex] ~= nil
        and AIRTEAM[sideIndex][1] ~= nil then
        return AIRTEAM[sideIndex][1]
    end
    if DEFAULTATTCKTEAM ~= nil and DEFAULTATTCKTEAM[sideIndex] ~= nil then
        return DEFAULTATTCKTEAM[sideIndex]
    end
    if sideIndex == 7 then
        return "PlyrCivilian/teamPlyrCivilian"
    end
    return "PlyrCreeps/teamPlyrCreeps"
end

-- 日冕里伊尔的空对地弹药就是「轰炸信标」本身。把弹药压到 1 发，保证一次部署只打一次信标：
-- 打完这架 AI 飞机就飞回机场，随后被空军重生流程（LUABOX/PLANEBACK/PLANEINI_0.lua）在
-- 机场附近收掉换成新的一架 —— 也就是「一回合一次信标」。
-- 弹药槽的读法照 MICROINI_0.lua: BomberHasWeaponAmmo（hardpoint 1~2 × 武器序号 1~6）。
-- 两个弹药接口任一缺失时不动，保留原生弹药，不至于把飞机改成打不出东西。
function HextechRune:LimitIlBeaconAmmo(unit)
    if unit == nil then
        return
    end
    if ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount == nil
        or ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount == nil then
        return
    end
    local shots = self.IlBeaconShotsPerAircraft or 1
    for hardpoint = 1, 2, 1 do
        for weaponIndex = 1, 6, 1 do
            local ammo = ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount(
                unit, hardpoint, 1, weaponIndex)
            -- 只压「确实有弹药且多于 1 发」的槽，空槽不去碰。
            if ammo ~= nil and ammo > shots then
                ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(
                    unit, hardpoint, 1, weaponIndex, shots)
            end
        end
    end
end

-- 召唤点：轻型载具出生点 LIGHTVEH13（恶魔侧）/ LIGHTVEH23（天使侧），
-- 即 LIGHTVEH1..3 / LIGHTVEH2..3，与 AIRRE1x / AIRRE2x 的「组名 + 侧号 + 序号」同规则。
-- 新点取不到就退回改之前的老点位 AIRRE11 / AIRRE21（AIRRESP[阵营][1] → AIRRE1/2..1），
function HextechRune:GetIlBeaconSpawnPosition(sideIndex)
    local pointIndex = self.IlBeaconSpawnPointIndex or 3
    if GetObjectByScriptName ~= nil then
        local prefix = "LIGHTVEH1"
        if sideIndex == 8 then
            prefix = "LIGHTVEH2"
        end
        local point = GetObjectByScriptName(prefix .. pointIndex)
        if point ~= nil then
            local x, y, z = ObjectGetPosition(point)
            if x ~= nil then
                return { X = x, Y = y, Z = z }
            end
        end
    end
    -- 兜底点位的序号与轻型载具点无关，固定用老口径的第 1 个。
    local fallbackIndex = 1
    if AIRRESP ~= nil and AIRRESP[sideIndex] ~= nil
        and AIRRESP[sideIndex][fallbackIndex] ~= nil then
        local x, y, z = ObjectGetPosition(AIRRESP[sideIndex][fallbackIndex])
        if x ~= nil then
            return { X = x, Y = y, Z = z }
        end
    end
    if GetObjectByScriptName ~= nil then
        local prefix = "AIRRE1"
        if sideIndex == 8 then
            prefix = "AIRRE2"
        end
        local point = GetObjectByScriptName(prefix .. fallbackIndex)
        if point ~= nil then
            local x, y, z = ObjectGetPosition(point)
            if x ~= nil then
                return { X = x, Y = y, Z = z }
            end
        end
    end
    return nil
end

-- 本方机场（换弹区中心）：与 PLANEREBORN 用同一个锚点 AIRFIELD[阵营]。
function HextechRune:GetIlBeaconAirfield(sideIndex)
    if AIRFIELD ~= nil and AIRFIELD[sideIndex] ~= nil then
        return AIRFIELD[sideIndex]
    end
    if GetObjectByScriptName ~= nil then
        local airfield = GetObjectByScriptName("AIRFIELD" .. sideIndex)
        if airfield ~= nil then
            return airfield
        end
        airfield = GetObjectByScriptName("AirField" .. sideIndex)
        if airfield ~= nil then
            return airfield
        end
    end
    return nil
end


-- 看门狗：只遍历 IlBeaconMarkByObjectId 里登记过的那几架，正常出兵的伊尔不受影响。
-- 判定走位置不走弹药：这架飞机一飞回本方机场的换弹区（半径 IlBeaconRearmRadius，
-- 与 PLANEREBORN 删返航飞机同口径）就地删掉，不给空军重生流程把它补回编制的机会。
function HextechRune:UpdateIlBeaconAircraft()
    local marks = self.IlBeaconMarkByObjectId
    local step = self.IlBeaconWatchIntervalFrames
    local radius = self.IlBeaconRearmRadius
    for objectId, mark in marks do
        local unit = GetObjectById(objectId)
        if unit == nil or not ObjectIsAlive(unit) then
            -- 被打掉 / 已经不在场上了，直接销账。
            marks[objectId] = nil
        else
            mark.AgeFrames = (mark.AgeFrames or 0) + step
            if mark.AgeFrames >= self.IlBeaconMaxLifetimeFrames then
                -- 兜底寿命：既不返航也不挨打的飞机到点直接删，别让它一直挂在场。
                ExecuteAction("NAMED_DELETE", unit)
                marks[objectId] = nil
            else
                local airfield = self:GetIlBeaconAirfield(mark.SideIndex)
                if airfield ~= nil and mark.AgeFrames >= self.IlBeaconArmDelayFrames then
                    local ux, uy = ObjectGetPosition(unit)
                    local ax, ay = ObjectGetPosition(airfield)
                    if ux ~= nil and ax ~= nil then
                        local dx = ux - ax
                        local dy = uy - ay
                        -- 用平方比，省掉开方（平面距离，和 CENTER_2D 同口径）。
                        if dx * dx + dy * dy <= radius * radius then
                            ExecuteAction("NAMED_DELETE", unit)
                            marks[objectId] = nil
                        end
                    end
                end
            end
        end
    end
end

function HextechRune:EnsureIlBeaconWatchdog()
    -- 备用取机用的过滤器（只有脚本名取不到时才用到），运行时才建，避开加载顺序。
    -- 两个形态都算：召唤的是 _Enhanced，万一引擎回落的又是基础型也得认得出来。
    if g_FilterIlBeaconAircraft == nil and CreateObjectFilter ~= nil then
        g_FilterIlBeaconAircraft = CreateObjectFilter({
            Rule = "ANY",
            Relationship = "SAME_PLAYER",
            IncludeThing = { "SovietAntiGroundAttacker",
                             "SovietAntiGroundAttacker_Enhanced" },
        })
    end
    if self.IlBeaconWatchdogStarted then
        return
    end
    if SchedulerModule == nil or SchedulerModule.call_every_x_frame == nil then
        return
    end
    self.IlBeaconWatchdogStarted = true
    SchedulerModule.call_every_x_frame(function()
        HextechRune:UpdateIlBeaconAircraft()
    end, self.IlBeaconWatchIntervalFrames, nil, {})
end

-- 取回刚召唤出来的那一架：先按脚本名取（UNIT_SPAWN_NAMED_LOCATION_ORIENTATION 的 name），
-- 取不到就在召唤点附近捞一次本阵营的伊尔，挑第一个还没记账的 —— 保证看门狗一定拿得到句柄。
function HextechRune:FindIlBeaconAircraft(sideIndex, position, name)
    if GetObjectByScriptName ~= nil then
        local named = GetObjectByScriptName(name)
        if named ~= nil then
            return named
        end
    end
    if g_SideFindObjects == nil or g_FilterIlBeaconAircraft == nil then
        return nil
    end
    local units, count = g_SideFindObjects(sideIndex,
        { X = position.X, Y = position.Y, Z = position.Z, Radius = 200,
          DistType = "CENTER_2D" },
        g_FilterIlBeaconAircraft)
    for i = 1, count, 1 do
        local candidate = units[i]
        if candidate ~= nil and ObjectIsAlive(candidate) then
            if self.IlBeaconMarkByObjectId[ObjectGetId(candidate)] == nil then
                return candidate
            end
        end
    end
    return nil
end

-- 切到信标形态：直接改对象状态即可切换武器组，写法和
-- GAME/CelestialBomberAircraft_ChangeMode.lua 一致（它在两个形态之间就是靠这条状态位来回切）。
function HextechRune:EnableIlBeaconMode(unit)
    if unit == nil or ExecuteAction == nil then
        return
    end
    if EvaluateCondition ~= nil
        and EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit,
            self.IlBeaconTransformStatus) then
        return
    end
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", unit,
        self.IlBeaconTransformStatus, self.IlBeaconTransformState)
end

-- 移速修正器延迟创建：本节点在 map.xml 里排最前，别在加载期碰这些 ex* 接口。
function HextechRune:GetIlBeaconSpeedModifier()
    if g_HextechIlBeaconSpeedModifier == nil and exAttributeModifierCreate ~= nil then
        g_HextechIlBeaconSpeedModifier = exAttributeModifierCreate(
            { SPEED = self.IlBeaconSpeedMultiplier }, 1)
    end
    return g_HextechIlBeaconSpeedModifier
end

-- 信标机的基础 buff：3 倍血量 + 2 倍移速。
function HextechRune:ApplyIlBeaconBaseBuffs(unit)
    if unit == nil or not ObjectIsAlive(unit) then
        return
    end
    local speedMod = self:GetIlBeaconSpeedModifier()
    if speedMod ~= nil then
        ObjectLoadAttributeModifier(unit, speedMod,
            self.PersistentBuffDuration or 9999)
    end
    if exObjectGetMaxHealth == nil or ExecuteAction == nil then
        return
    end
    local objectId = ObjectGetId(unit)
    local maxHealth = exObjectGetMaxHealth(objectId)
    if maxHealth == nil or maxHealth <= 0 then
        return
    end
    local reference = "hextech_il_beacon_" .. objectId
    ExecuteAction("SET_UNIT_REFERENCE", reference, unit)
    ExecuteAction("NAMED_SET_MAX_HEALTH", reference,
        floor(maxHealth * self.IlBeaconHealthMultiplier), "TRUE")
end

-- 独立 AI 队列：照 UnitCreate.lua: AntiAirHunterBorn 的做法，把飞机从公共 AIRATTACK
-- 编队摘出来放进 idle 队。这样引擎不会再给它下编队攻击令，索敌完全由看门狗
function HextechRune:ReleaseIlBeaconToIdleTeam(unit, sideIndex)
    if unit == nil or not ObjectIsAlive(unit) then
        return
    end
    if g_SetSideTeam == nil or DEFAULTIDLETEAM == nil
        or DEFAULTIDLETEAM[sideIndex] == nil then
        return
    end
    ExecuteAction("NAMED_STOP", unit)
    ObjectSetAssignedTarget(unit, nil)
    g_SetSideTeam(unit, DEFAULTIDLETEAM[sideIndex])
end

function HextechRune:SummonIlBeaconAircraft(playerIndex)
    local sideIndex = self:GetIlBeaconSideIndex(playerIndex)
    if sideIndex == nil then
        return false
    end
    local position = self:GetIlBeaconSpawnPosition(sideIndex)
    if position == nil then
        return false
    end
    self.IlBeaconSpawnSerial = (self.IlBeaconSpawnSerial or 0) + 1
    local name = format("HextechIlBeacon%d", self.IlBeaconSpawnSerial)
    -- 赠送路径不过出兵函数，先占一个「已知的脚本生成单位」标记，
    -- 免得纯抽卡 / 余额墙把它当成本回合正式生产的单位。
    self:MarkNextSpawnAsKnownPureDrawUnit()
    -- 朝向照 PLANEREBORN 的写法定：恶魔侧 0、天使侧 180。
    local orientation = 0
    if sideIndex == 8 then
        orientation = 180
    end
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", name,
        self.IlBeaconUnitType,
        self:GetIlBeaconAircraftTeam(sideIndex),
        position, orientation)
    self:EnsureIlBeaconWatchdog()
    local unit = self:FindIlBeaconAircraft(sideIndex, position, name)
    if unit ~= nil then
        -- 独立标记：一次性信标机单独记账，看门狗只认这张表。
        local unitId = ObjectGetId(unit)
        self.IlBeaconMarkByObjectId[unitId] =
            { AgeFrames = 0, SideIndex = sideIndex }
        -- 先切信标形态，再上 buff / 压弹药：变形会换武器组、也可能重建模型，
        -- 顺序反了会压到旧的那一组上。变形要下一帧才真正生效，所以这些都延迟 1 帧再上。
        self:EnableIlBeaconMode(unit)
        if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
            SchedulerModule.delay_call(function(id, side)
                local target = GetObjectById(id)
                if target ~= nil and ObjectIsAlive(target) then
                    HextechRune:ApplyIlBeaconBaseBuffs(target)
                    HextechRune:LimitIlBeaconAmmo(target)
                    HextechRune:ReleaseIlBeaconToIdleTeam(target, side)
                end
            end, 1, { unitId, sideIndex })
        else
            self:ApplyIlBeaconBaseBuffs(unit)
            self:LimitIlBeaconAmmo(unit)
            self:ReleaseIlBeaconToIdleTeam(unit, sideIndex)
        end
        if ConfigureBomberPriorityTargetChooser ~= nil then
            ConfigureBomberPriorityTargetChooser(unit)
        end
    end
    return true
end

function HextechRune:DeployIlBeacon(playerIndex)
    -- 一回合只放一次：本回合已经走完召唤逻辑就直接拒绝，不再用帧窗口
    -- （帧窗口会造成“按钮按不动、但其实已经放出去了”的错觉）。
    if g_HextechIlBeaconUsedThisRound[playerIndex] then
        return false
    end
    local charges = g_HextechIlBeaconCharges[playerIndex] or 0
    if charges <= 0 then
        return false
    end
    local copyCount = self:GetIlBeaconCopyCount(playerIndex)
    if copyCount <= 0 then
        return false
    end
    -- 禁空军时整张符文本来就不入池（RequiresType），这里再兜一次：中途被禁也不放出来。
    if BanModeIsTypeEnabled ~= nil and BanModeIsTypeEnabled("aircraft") == 0 then
        return false
    end
    g_HextechIlBeaconCharges[playerIndex] = charges - 1
    g_HextechIlBeaconUsedThisRound[playerIndex] = true
    -- 使用之后才开始冷确：3 个回合之后（回合开始 -1）才补回下一次。
    g_HextechIlBeaconCooldown[playerIndex] = self.IlBeaconCooldownRounds
    for i = 1, copyCount, 1 do
        self:SummonIlBeaconAircraft(playerIndex)
    end
    -- 走完召唤逻辑就把 K 键提示（按钮）强制摘掉，下回合发次数时再长出来。
    self:HideIlBeaconHint(playerIndex)
    return true
end

function HextechRune:HandleIlBeaconHotKey(playerName)
    for playerIndex = 1, 8, 1 do
        if playerName == "Player_" .. playerIndex then
            return self:DeployIlBeacon(playerIndex)
        end
    end
    return false
end

-- 强制摘掉 K 键提示（按钮）。走完召唤逻辑就调它，本回合不再显示。
function HextechRune:HideIlBeaconHint(playerIndex)
    exCustomTextUpdateVisibilityForPlayer("Player_" .. playerIndex,
        self.IlBeaconHintTextIndexBase + playerIndex, 0)
end

function HextechRune:RefreshIlBeaconHint(playerIndex)
    local playerName = "Player_" .. playerIndex
    local textIndex = self.IlBeaconHintTextIndexBase + playerIndex
    exCustomTextUpdateVisibilityForPlayer(playerName, textIndex, 0)
    local charges = g_HextechIlBeaconCharges[playerIndex] or 0
    -- 本回合已经部署过就不再显示：按钮只在这回合的次数到手时出现一次。
    if charges <= 0 or g_HextechIlBeaconUsedThisRound[playerIndex] then
        return
    end
    local hint = Localization.get("hextech.il_beacon.hotkey_hint")
    exCreateCustomTextForPlayer(playerName, {
        Index = textIndex,
        Content = hint,
        X = self:GetCenteredTextLeftX(self.IlBeaconHintCenterX, hint,
            self.IlBeaconHintFontSize),
        Y = self.IlBeaconHintY,
        Color = 16777215,
        Size = self.IlBeaconHintFontSize,
        AlignX = "left",
        AlignY = "top",
    })
end
