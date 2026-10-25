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

-- ===== 金·烧福瑞 / 生异形 / 钓鱼佬：回合开始按本方份数比例替换敌方对应兵种 =====
HextechRune.BurnFurryRuneId = "gold_burn_furry"
HextechRune.SpawnAlienRuneId = "gold_spawn_alien"
HextechRune.AnglerRuneId = "gold_angler"
HextechRune.SitTightRuneId = "prismatic_sit_tight"
-- 同阵营份数 → 转化比例：1/2/3 份 = 50%/75%/100%（超过 3 份按 100%）。
HextechRune.BurnFurryPercentByCopies = { 0.50, 0.75, 1.00 }
-- 生成的动物随机取一个：警犬（盟军探路兵位）/ 战熊（苏联探路兵位）。
HextechRune.BurnFurryAnimalTypes = { "AlliedScoutInfantry", "SovietScoutInfantry" }
-- 生异形：敌方载具 → 恐怖机器人；钓鱼佬：敌方海军 → 海翼。
HextechRune.SpawnAlienUnitTypes = { "SovietScoutVehicle" }
HextechRune.AnglerUnitTypes = { "JapanAntiAirShip" }
HextechRune.SitTightUnitTypes = { "JapanInterceptorAircraft" }
-- 双形态单位按出生点归兵种：天狗/VX/心神/火箭天使算空军，不算载具/步兵。
HextechRune.ConversionDualAirTypes = {
    "JapanAntiInfantryVehicle",
    "JapanAntiInfantryVehicle_Enhanced",
    "JapanAntiInfantryVehicle_Enhanced_Water",
    "JapanAntiAirVehicleTech1",
    "JapanAntiAirVehicleTech1_Enhanced",
    "JapanAntiAirVehicleTech1_Enhanced_Water",
    "JapanMissileMechaAdvanced",
    "JapanMissileMechaAdvanced_Enhanced",
    "JapanMissileMechaAdvanced_Enhanced_Water",
    "JapanAntiVehicleInfantryTech3",
}
HextechRune.ConversionDualAirFilter = CreateObjectFilter({
    Rule = "ANY", Relationship = "SAME_PLAYER",
    IncludeThing = HextechRune.ConversionDualAirTypes,
    Exclude = "STRUCTURE DEBRIS"
})
-- P[7]/P[8] 是 AI 阵营锚点 MCV；任何转化符文都不能把它们换掉
HextechRune.ConversionNeverConvertTypes = {
    "AlliedMCV", "AlliedMCV_Enhanced", "AlliedMCV_Naval", "AlliedMCV_Enhanced_Naval",
    "SovietMCV", "SovietMCV_Enhanced", "SovietMCV_Naval", "SovietMCV_Enhanced_Naval",
    "JapanMCV", "JapanMCV_Enhanced", "JapanMCV_Naval", "JapanMCV_Enhanced_Naval",
    "CelestialMCV", "CelestialMCV_Enhanced", "CelestialMCV_Ground", "CelestialMCV_Naval",
    "CelestialMCV_Air", "CelestialMCV_Enhanced_Ground", "CelestialMCV_Enhanced_Naval",
    "CelestialMCV_Enhanced_Air",
    -- 迅雷载具三形态（与九头蛇万岁、EnvKillAllUnit 的清场排除同口径）：
    -- 运兵车被转化会连带吞掉车上单位，同时它们属于载具批次。
    "JapanLightTransportVehicle",
    "JapanLightTransportVehicle_AntiTank",
    "JapanLightTransportVehicle_Kamikaze",
}
HextechRune.ConversionNeverConvertInstanceIds = {}
for conversionTypeIndex = 1, getn(HextechRune.ConversionNeverConvertTypes), 1 do
    HextechRune.ConversionNeverConvertInstanceIds[
        FastHash(HextechRune.ConversionNeverConvertTypes[conversionTypeIndex])] = true
end
-- 载具转化要排除这些「空军出生点」单位，避免生异形把天狗/VX/心神当载具换掉。
HextechRune.ConversionVehicleExcludeTypes = {}
for conversionTypeIndex = 1, getn(HextechRune.ConversionDualAirTypes), 1 do
    tinsert(HextechRune.ConversionVehicleExcludeTypes,
        HextechRune.ConversionDualAirTypes[conversionTypeIndex])
end
for conversionTypeIndex = 1, getn(HextechRune.ConversionNeverConvertTypes), 1 do
    tinsert(HextechRune.ConversionVehicleExcludeTypes,
        HextechRune.ConversionNeverConvertTypes[conversionTypeIndex])
end
HextechRune.ConversionVehicleFilter = CreateObjectFilter({
    Rule = "ANY", Relationship = "SAME_PLAYER",
    Include = "VEHICLE HUGE_VEHICLE",
    Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS",
    ExcludeThing = HextechRune.ConversionVehicleExcludeTypes
})
-- 步兵转化同样按出生点：火箭天使走飞机批次，不能被烧福瑞换成狗熊。
HextechRune.ConversionInfantryFilter = CreateObjectFilter({
    Rule = "ANY", Relationship = "SAME_PLAYER",
    Include = "INFANTRY",
    Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS",
    ExcludeThing = { "JapanAntiVehicleInfantryTech3" }
})
-- 转化目标只认回收系统的兵种配置：不走出兵系统的单位（地编摆放、技能召唤、
-- 其它非本系统产物）本来就不会出兵，自然也不该被换掉。
-- 名单来自 g_BanModeNameTypes（回收表 + 箱子表 + 双形态例外），补上形态别名
-- 与替换型产物；具体兵种仍由各符文的引擎类别过滤 + 排除名单决定。
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

-- 对面是 AI 阵营（P7/P8），没有「出兵出队」那一步，新单位要直接进攻击队才会参战。
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
    local neverIds = self.ConversionNeverConvertInstanceIds
    if neverIds == nil then
        return false
    end
    return neverIds[instanceId] == true
end

-- 删掉对面该比例的指定兵种，并在原地生成等量的替换单位。只动 P7/P8 的战场单位，
-- 不碰玩家单位池（UNITCOUNT 里的份数由玩家基地里的单位决定）。
function HextechRune:ConvertEnemyUnitsOfType(sideIndex, percent, filter, unitType,
    spawnTypes, spawnPrefix, extraFilter)
    if P == nil or P[sideIndex] == nil or not ObjectIsAlive(P[sideIndex])
        or filter == nil or percent <= 0 then
        return 0
    end
    local units, count = ObjectFindObjects(P[sideIndex], nil, filter)
    if units == nil or type(count) ~= "number" then
        return 0
    end
    local candidates = {}
    local seen = {}
    for i = 1, count, 1 do
        if ObjectIsAlive(units[i]) and not self:IsPresetMapUnit(units[i])
            and not self:IsConversionProtectedUnit(units[i])
            and self:IsConversionSystemUnit(units[i]) then
            seen[units[i]] = true
            tinsert(candidates, units[i])
        end
    end
    -- 双形态单位（天狗/VX/心神）当前可能是载具形态，AIRCRAFT 过滤器抓不到，
    -- 再用一份按模板名的过滤器补齐。
    if extraFilter ~= nil then
        local extraUnits, extraCount = ObjectFindObjects(P[sideIndex], nil, extraFilter)
        if extraUnits ~= nil and type(extraCount) == "number" then
            for i = 1, extraCount, 1 do
                local unit = extraUnits[i]
                if ObjectIsAlive(unit) and not self:IsPresetMapUnit(unit)
                    and not self:IsConversionProtectedUnit(unit)
                    and self:IsConversionSystemUnit(unit)
                    and seen[unit] == nil then
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
    local filter = nil
    if self.ConversionInfantryFilter ~= nil then
        filter = self.ConversionInfantryFilter
    elseif self.UnitTypeFilters ~= nil then
        filter = self.UnitTypeFilters.infantry
    end
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
        self.SpawnAlienAppliedRound, round, self.ConversionVehicleFilter)
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
        self.ConversionDualAirFilter)
end

-- 四个转化符文统一在 AIRSPACT 的空军/轻载具批次出完后结算（由该节点调度，
-- 不再挂在 LandArmySpawn 末尾的 ApplyRoundEffects 上，否则会早于空军批次）。
-- 顺序固定：烧福瑞 → 生异形 → 樱落 → 钓鱼佬。先结算的符文产出的替换单位
-- 不再被后面的符文二次转化，钓鱼佬必须最后，避免海军替换出的海翼被空军再换一遍。
function HextechRune:ApplyAllConversionPulses(round)
    self:ApplyBurnFurryPulse(round)
    self:ApplySpawnAlienPulse(round)
    self:ApplySitTightPulse(round)
    self:ApplyAnglerPulse(round)
end
