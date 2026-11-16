-- 讲解见 analysis/地图注释说明文档.md 附录 A.30

-- 死亡触发类符文：金·炽燃利息（发钱）、银·狩猎律动（回血）。
HextechRune = HextechRune or {}

-- 狩猎律动：敌方**持有人选定兵种**的单位死亡时，在本方场上随机挑一只未满血、同兵种、
-- 且模板属于该玩家回收卡池的单位，回复其血量上限的 10%。
HextechRune.HuntRhythmRuneId = "silver_hunt_rhythm"
HextechRune.HuntRhythmHealRate = 0.10

-- 模板 FastHash → 兵种集合（双形态单位同时属于两个兵种，与 DualUnitTypeFilters 同口径）。
-- 同一模板的兵种整局不变，所以这张表只增不减。
HextechRune.BattleUnitTypeByInstance = HextechRune.BattleUnitTypeByInstance or {}
-- 已经为它补扫过一次的死者模板，避免同一个不认识的模板反复全图扫描。
HextechRune.HuntTypeSeedTried = HextechRune.HuntTypeSeedTried or {}

-- 死亡事件属于全局入口，用固定函数名转发到当前海克斯对象。
function HextechBattleUnitDie(dyingObjId, attackerId,
    dyingObjInstanceId, attackerInstanceId, ownerPlayerName)
    if HextechRune == nil then
        return
    end
    if HextechRune.OnWarEfficiencyUnitDie ~= nil then
        HextechRune:OnWarEfficiencyUnitDie(dyingObjInstanceId, ownerPlayerName)
    end
    if HextechRune.OnDeathRewardUnitDie ~= nil then
        HextechRune:OnDeathRewardUnitDie(dyingObjId, dyingObjInstanceId, ownerPlayerName)
    end
end

function HextechRune:EnsureBattleDeathObserver()
    if self.BattleDeathObserverReady then
        return
    end
    if RegisterUnitDieCallback == nil or UNITLIST == nil or unitcountmax == nil then
        return
    end
    for unitIndex = 1, unitcountmax, 1 do
        RegisterUnitDieCallback(UNITLIST[unitIndex],
            HextechBattleUnitDie)
    end
    self:RegisterFormDeathCallbacks()

    -- 回合结算后的脚本清场不算单位死亡；下一回合开始后重新接受死亡事件。
    self.BattleDeathPhaseActive = true
    if RoundLuaManager ~= nil then
        RoundLuaManager.CallOnEveryRoundBegin(function()
            HextechRune.BattleDeathPhaseActive = true
        end)
        RoundLuaManager.CallOnEveryRoundEnd(function()
            HextechRune.BattleDeathPhaseActive = false
        end)
    end
    self.BattleDeathObserverReady = true
end

-- 形态名来自 g_PureDrawProductionAliases（本体 → 强化/环境/变形形态），加上替换型符文
-- 的升级单位。RegisterUnitDieCallback 内部已按 FastHash 去重，重复调用没有副作用。
function HextechRune:RegisterFormDeathCallbacks()
    if RegisterUnitDieCallback == nil then
        return
    end
    if g_PureDrawProductionAliases ~= nil then
        for baseType, aliases in g_PureDrawProductionAliases do
            for i = 1, getn(aliases), 1 do
                RegisterUnitDieCallback(aliases[i], HextechBattleUnitDie)
            end
        end
    end
    for i = 1, getn(self.UnitReplacementRunes), 1 do
        RegisterUnitDieCallback(self.UnitReplacementRunes[i].ReplacementType,
            HextechBattleUnitDie)
    end
end

function HextechRune:RememberUnitTypes(lookup)
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local objects = lookup[unitType]
        if objects ~= nil then
            for objectId, value in objects do
                local instanceId = ObjectGetInstanceId(objectId)
                local types = self.BattleUnitTypeByInstance[instanceId]
                if types == nil then
                    types = {}
                    self.BattleUnitTypeByInstance[instanceId] = types
                end
                types[unitType] = true
            end
        end
    end
end

-- 死亡单位所属阵营的对手阵营才是奖励方。
function HextechRune:GetDeathRewardSideIndex(ownerPlayerName)
    local deadSideIndex = self:GetBattleOwnerSideIndex(ownerPlayerName)
    if deadSideIndex == nil then
        return nil
    end
    if deadSideIndex == 8 then
        return 7
    end
    return 8
end

-- 该玩家持有的狩猎律动兵种集合（带兵种的符文按 Id:兵种 判重，所以步兵/载具两张可以同时持有，
-- 每张各自独立触发）。没有则返回 nil，避免空表被当成「持有」。
function HextechRune:GetHuntRhythmUnitTypes(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local counts = self.PlayerOwnedRuneCounts[playerIndex]
    local result = nil
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        if counts[self.HuntRhythmRuneId .. ":" .. unitType] then
            if result == nil then
                result = {}
            end
            result[unitType] = true
        end
    end
    -- 元神互锁：同步组里的另一个兵种按同一张狩猎律动独立结算 —— 它那边死人（deadTypes 命中）时
    -- 也治你自己的一只同类单位，两兵种各治各的、不互相翻倍。
    if result ~= nil then
        for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
            local unitType = self.UnitTypeOrder[typeIndex]
            if result[unitType] == true then
                local partner = self:GetInterlockPartnerType(playerIndex, unitType)
                if partner ~= nil then
                    result[partner] = true
                end
            end
        end
    end
    return result
end

-- 本方是否有人持有狩猎律动（决定要不要为死者阵营补扫一次兵种）。
function HextechRune:SideHasHuntRhythm(sideSeats)
    for seatPos = 1, getn(sideSeats), 1 do
        if self:GetHuntRhythmUnitTypes(sideSeats[seatPos]) ~= nil then
            return true
        end
    end
    return false
end

HextechRune.ExtraVariantTemplates = HextechRune.ExtraVariantTemplates or {
    { Variant = "AlliedChronoBeacon_Vindicator", Base = "AlliedAntiGroundAircraft" },
}

function HextechRune:GetVariantPoolIndex()
    if self.HuntVariantPoolIndex ~= nil then
        return self.HuntVariantPoolIndex
    end
    if g_UnitNameToUnitIndex == nil or g_PureDrawProductionAliases == nil then
        return {}
    end
    local result = {}
    for baseType, aliases in g_PureDrawProductionAliases do
        local poolIndex = g_UnitNameToUnitIndex[baseType]
        if poolIndex ~= nil then
            for i = 1, getn(aliases), 1 do
                result[FastHash(aliases[i])] = poolIndex
            end
        end
    end
    -- 替换型符文：升级形态入池时可能仍记在原单位槽上（见 ResolveCollectedUnitIndex）。
    for i = 1, getn(self.UnitReplacementRunes), 1 do
        local entry = self.UnitReplacementRunes[i]
        local poolIndex = g_UnitNameToUnitIndex[entry.ReplacementType]
            or g_UnitNameToUnitIndex[entry.SourceType]
        if poolIndex ~= nil then
            result[FastHash(entry.ReplacementType)] = poolIndex
        end
    end
    -- 生产别名表没登记的衍生形态，在这里补（维护者的超时空信标形态）。
    for i = 1, getn(self.ExtraVariantTemplates), 1 do
        local entry = self.ExtraVariantTemplates[i]
        local poolIndex = g_UnitNameToUnitIndex[entry.Base]
        if poolIndex ~= nil then
            result[FastHash(entry.Variant)] = poolIndex
        end
    end
    self.HuntVariantPoolIndex = result
    return result
end

-- 符文按兵种槽派发（AssignNewSideBattleUnits 只按 UNITLIST 的精确模板名扫 FilterLIST），
function HextechRune:GetSideVariantUnitsByIndex(sideIndex)
    local result = {}
    local variantIndex = self:GetVariantPoolIndex()
    local units, count = g_SideFindObjects(sideIndex, nil, self.AllSideUnitsFilter)
    for i = 1, count, 1 do
        local unit = units[i]
        local instanceId = ObjectGetInstanceId(unit)
        -- 本体模板有自己的池槽位，FilterLIST 已经扫到了，这里只补衍生形态。
        if g_UnitNameToUnitIndex == nil
            or g_UnitNameToUnitIndex[instanceId] == nil then
            local poolIndex = variantIndex[instanceId]
            if poolIndex ~= nil then
                if result[poolIndex] == nil then
                    result[poolIndex] = {}
                end
                tinsert(result[poolIndex], unit)
            end
        end
    end
    return result
end

function HextechRune:PickHuntTarget(playerIndex, lookup, unitType)
    if UNITCOUNT == nil or UNITCOUNT[playerIndex] == nil or g_UnitNameToUnitIndex == nil then
        return nil
    end
    local objects = lookup[unitType]
    if objects == nil then
        return nil
    end
    local variantIndex = self:GetVariantPoolIndex()
    local candidates = {}
    for objectId, value in objects do
        local instanceId = ObjectGetInstanceId(objectId)
        local unitIndex = g_UnitNameToUnitIndex[instanceId]
        if unitIndex == nil then
            unitIndex = variantIndex[instanceId]
        end
        if unitIndex ~= nil and (tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0) > 0
            and not self:IsPresetMapUnitId(objectId) then
            local maxHealth = exObjectGetMaxHealth(objectId)
            local currentHealth = exObjectGetCurrentHealth(objectId)
            if maxHealth ~= nil and maxHealth > 0 and currentHealth ~= nil
                and currentHealth < maxHealth then
                tinsert(candidates, objectId)
            end
        end
    end
    if getn(candidates) <= 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

-- 实测结论：UNIT_SET_HEALTH 收的是**百分比 0~100**、不是绝对血量——直接传「44+22=66」
-- 会被当成 66% 写成 145/220，所以目标血量必须按上限换算成百分比再写。
function HextechRune:HealHuntRhythmUnit(objectId)
    local unit = GetObjectById(objectId)
    if unit == nil or not ObjectIsAlive(unit) then
        return false
    end
    local maxHealth = exObjectGetMaxHealth(objectId)
    local currentHealth = exObjectGetCurrentHealth(objectId)
    if maxHealth == nil or maxHealth <= 0 or currentHealth == nil
        or currentHealth >= maxHealth then
        return false
    end
    local targetHealth = currentHealth + maxHealth * self.HuntRhythmHealRate
    if targetHealth > maxHealth then
        targetHealth = maxHealth
    end
    ExecuteAction("SET_UNIT_REFERENCE", "hextech_hunt_" .. objectId, unit)
    ExecuteAction("UNIT_SET_HEALTH", "hextech_hunt_" .. objectId, targetHealth / maxHealth * 100)
    return true
end

-- 狩猎律动结算：死者兵种与持有人兵种不一致的不触发；同一次死亡里，持有人每兵种各治一只。
function HextechRune:ApplyHuntRhythmHeal(sideIndex, sideSeats, deadTypes)
    if deadTypes == nil then
        return
    end
    local lookup
    for seatPos = 1, getn(sideSeats), 1 do
        local playerIndex = sideSeats[seatPos]
        local heldTypes = self:GetHuntRhythmUnitTypes(playerIndex)
        if heldTypes ~= nil then
            for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
                local unitType = self.UnitTypeOrder[typeIndex]
                if heldTypes[unitType] == true and deadTypes[unitType] == true then
                    if lookup == nil then
                        lookup = self:BuildSideUnitTypeLookup(sideIndex)
                        self:RememberUnitTypes(lookup)
                    end
                    local targetId = self:PickHuntTarget(playerIndex, lookup, unitType)
                    if targetId ~= nil then
                        self:HealHuntRhythmUnit(targetId)
                    end
                end
            end
        end
    end
end

-- 炽燃利息：本方每名持有者各拿一份钱，但死亡位置只飘一次字（与小电厂同款）。
function HextechRune:PayCombustionInterest(dyingObjId, sideSeats)
    local interestMoney = GetCombustionInterestMoney()
    local rewarded = false
    local previous = SetWorldBuilderThisPlayer(1)
    for seatPos = 1, getn(sideSeats), 1 do
        local playerIndex = sideSeats[seatPos]
        self:EnsurePlayerRuneState(playerIndex)
        if self.PlayerOwnedRuneIds[playerIndex]["gold_combustion_interest"] then
            ExecuteAction("PLAYER_GIVE_MONEY", "Player_" .. playerIndex, interestMoney)
            rewarded = true
        end
    end
    SetWorldBuilderThisPlayer(previous)
    if rewarded then
        exShowFloatingIntAtObject(dyingObjId, interestMoney)
    end
end

-- 敌方战斗单位死亡时的全部奖励结算。两条效果互相独立、并行触发；利息不看兵种，律动看。
function HextechRune:OnDeathRewardUnitDie(dyingObjId, dyingObjInstanceId, ownerPlayerName)
    -- 死亡单位的归属登记当场清掉：句柄可能已被引擎回收复用。
    self.BattleUnitAssignments[dyingObjId] = nil
    -- 虚幻武器：底座死了，绑在它身上的隐形炮台一起消失（实现见本文件末尾的虚幻武器段）。
    if self.IllusoryTurretsByBase ~= nil then
        self:KillIllusoryTurretsOf(dyingObjId)
    end
    if not self.BattleDeathPhaseActive then
        return
    end
    local deadSideIndex = self:GetBattleOwnerSideIndex(ownerPlayerName)
    local sideIndex = self:GetDeathRewardSideIndex(ownerPlayerName)
    if sideIndex == nil then
        return
    end
    local sideSeats = self:GetSidePlayerRange(sideIndex)
    self:PayCombustionInterest(dyingObjId, sideSeats)

    local deadTypes = self.BattleUnitTypeByInstance[dyingObjInstanceId]
    if deadTypes == nil and deadSideIndex ~= nil
        and self.HuntTypeSeedTried[dyingObjInstanceId] == nil
        and self:SideHasHuntRhythm(sideSeats) then
        self.HuntTypeSeedTried[dyingObjInstanceId] = true
        self:RememberUnitTypes(self:BuildSideUnitTypeLookup(deadSideIndex))
        deadTypes = self.BattleUnitTypeByInstance[dyingObjInstanceId]
    end
    -- 缓存没见过这个模板（首次登场就阵亡）时按「不匹配」处理，宁可少治也不乱治。
    self:ApplyHuntRhythmHeal(sideIndex, sideSeats, deadTypes)
end

-- 虚幻武器（棱彩符文 · 可重复获取）：从「选底座的单位卡」到「隐形炮台跟随/共命/吃 buff」
-- 讲解见 analysis/地图注释说明文档.md 附录 A.12（虚幻武器）

HextechRune = HextechRune or {}

-- ===== 状态表 =====
-- 键=炮台 objectId，值=entry
HextechRune.IllusoryTurretByObjectId = {}
-- 键=底座 objectId，值={ 炮台 objectId = entry }
HextechRune.IllusoryTurretsByBase = {}
-- 键=底座 objectId，值={ 符文实例键 = true }：一对选择对一只底座只绑一次
HextechRune.IllusoryBoundKeys = {}
-- 选卡临时状态：[玩家] = { Stage = 1/2, Rune = 符文实例, Chassis = {...} }
HextechRune.IllusoryPending = {}
HextechRune.IllusorySerial = 0
HextechRune.IllusoryWatchdogStarted = false
HextechRune.IllusorySweepCounter = 0
-- 已经在地图外生成、还没融合到底座上的炮台：[玩家] = { entry... }（entry.Parked = true）。
HextechRune.IllusoryParkedTurrets = {}
HextechRune.IllusoryRoundHookReady = false
-- 选卡提示文字的 index（文字 index 只用到 200..232，这里取一个空档）。
HextechRune.IllusoryHintTextIndex = 240
-- 排查用开关：true 时炮台一个状态都不加，就当一只普通可见单位（能看、能被打死），
-- 用来确认它到底出生了没有、会不会自己开火。确认完记得改回 false。
HextechRune.IllusoryVisibleTest = false
-- 懒构建缓存
HextechRune.IllusoryTierMap = nil
HextechRune.IllusoryCatalog = nil
HextechRune.IllusoryTurretCatalog = nil

-- 炮台不参与单位池/寿命/编队的统一口径：所有"按单位池扫对象"的地方都用这几张表过滤。
function HextechRune:IsIllusoryTurretObject(objectId)
    if objectId == nil then
        return false
    end
    return self.IllusoryTurretByObjectId[objectId] ~= nil
end

-- 被选成「底座」的单位对象 id：载具装车系统（PassengerLoadSpawn 的 g_PLSpawnCandidates）
HextechRune.IllusoryChassisIds = {}

function HextechRune:MarkIllusoryChassis(objectId)
    if objectId == nil then
        return
    end
    if HextechRune.IllusoryChassisIds == nil then
        HextechRune.IllusoryChassisIds = {}
    end
    HextechRune.IllusoryChassisIds[objectId] = true
end

-- 这个对象是不是某只炮台的底座（现在挂着炮台，或本轮被标记过）。
function HextechRune:IsIllusoryChassisObject(objectId)
    if objectId == nil then
        return false
    end
    if self.IllusoryTurretsByBase[objectId] ~= nil then
        return true
    end
    if HextechRune.IllusoryChassisIds ~= nil
        and HextechRune.IllusoryChassisIds[objectId] == true then
        return true
    end
    return false
end

-- 底座被装进载具就请它下车：载具（尤其是炮台本身）无敌+隐身，待在车里等于卡无敌。
function HextechRune:EjectIllusoryChassis(unit)
    if unit == nil or not ObjectIsAlive(unit) then
        return
    end
    -- 0 是真值，只显式比成功值（同 PassengerLoadSpawn 的口径）
    local inside = EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unit, "INSIDE_GARRISON")
    if inside == 1 or inside == true then
        ExecuteAction("NAMED_EXIT_BUILDING", unit)
    end
end

-- 单位池扫描过滤（UNITCOUNTERINI_0 的 unitgetcountanddelet 调用）：
-- 炮台是"真单位"，但绝不能计入 UNITCOUNT / 箱子单位 / 买二送一，也不能被回合末清场删掉。
function HextechRune:FilterIllusoryTurrets(units, count)
    if units == nil or type(count) ~= "number" or count < 1 then
        return units, 0
    end
    if next(self.IllusoryTurretByObjectId) == nil then
        return units, count
    end
    local kept = {}
    for i = 1, count, 1 do
        local unit = units[i]
        if unit ~= nil then
            local objectId = ObjectGetId(unit)
            if objectId == nil or self.IllusoryTurretByObjectId[objectId] == nil then
                tinsert(kept, unit)
            end
        end
    end
    return kept, getn(kept)
end

-- ===== 单位目录：类型 → { Type, Name, Icon, Faction, Tier } =====
-- 05_ultimate_creature.lua 的非生产单位阶级表。

function HextechRune:GetIllusoryUnitTier(unitType)
    if unitType == nil then
        return nil
    end
    if self.IllusoryTierMap == nil then
        local map = {}
        if g_PureDrawBuildableUnitPool ~= nil then
            for tier = 1, 6, 1 do
                local tierPool = g_PureDrawBuildableUnitPool[tier]
                if tierPool ~= nil then
                    for i = 1, getn(tierPool), 1 do
                        local unitInfo = tierPool[i]
                        if unitInfo ~= nil and unitInfo.Type ~= nil
                            and map[unitInfo.Type] == nil then
                            map[unitInfo.Type] = tier
                        end
                    end
                end
            end
        end
        if self.NonProductionUnitTier ~= nil then
            for unitTypeKey, tier in self.NonProductionUnitTier do
                if map[unitTypeKey] == nil then
                    map[unitTypeKey] = tier
                end
            end
        end
        if self.ProductionFormTierOverride ~= nil then
            for unitTypeKey, tier in self.ProductionFormTierOverride do
                map[unitTypeKey] = tier
            end
        end
        self.IllusoryTierMap = map
    end
    local tier = self.IllusoryTierMap[unitType]
    if tier ~= nil then
        return tier
    end
    -- 形态名兜底：抽卡池只登记基础形态，回收表里的形态（AC130 / 超时空信标形态 /
    -- 一式磁轨炮重巡…）在池里查不到阶级，按基础形态的阶级算。
    local baseType = self:GetIllusoryTierBaseType(unitType)
    if baseType ~= nil then
        local baseTier = self.IllusoryTierMap[baseType]
        if baseTier ~= nil then
            self.IllusoryTierMap[unitType] = baseTier
            return baseTier
        end
    end
    -- 再退到 05 的完整口径（hash 表 Tier / NonProductionUnitTier / TechN 名字后缀）。
    if self.GetUltimateCreatureUnitTier ~= nil then
        local otherTier = self:GetUltimateCreatureUnitTier(unitType)
        if otherTier ~= nil then
            self.IllusoryTierMap[unitType] = otherTier
            return otherTier
        end
    end
    -- 先锋武装炮艇机的超时空信标形态（AlliedChronoBeacon 一族）用户裁定统一 T4。
    if strfind(unitType, "ChronoBeacon") ~= nil then
        self.IllusoryTierMap[unitType] = 4
        return 4
    end
    return nil
end

-- 阶数兜底用的「形态 → 基础形态」：先查显式表，再查抽卡池的形态别名表。
HextechRune.IllusoryTierBaseTypes = {
    AlliedGunshipAircraft_Enhanced = "AlliedGunshipAircraft",
    AlliedAC130GunshipAircraft = "AlliedGunshipAircraft",
    AlliedChronoBeacon_Harbinger = "AlliedGunshipAircraft",
    AlliedChronoBeacon_Vindicator = "AlliedGunshipAircraft",
}

function HextechRune:GetIllusoryTierBaseType(unitType)
    if unitType == nil then
        return nil
    end
    local explicit = HextechRune.IllusoryTierBaseTypes[unitType]
    if explicit ~= nil then
        return explicit
    end
    local baseType = self:GetIllusoryBaseType(unitType)
    if baseType == nil or baseType == unitType then
        return nil
    end
    return baseType
end

-- 卡框稀有度：T2 及以下=白银(3)、T3=黄金(2)、T4 及以上=棱彩(1)。
-- 查不到阶级的单位按白银展示（宁低勿高，避免把杂兵卡画成棱彩）。
function HextechRune:GetIllusoryCardRarity(unitType)
    local tier = self:GetIllusoryUnitTier(unitType)
    if tier == nil then
        return 3
    end
    if tier <= 2 then
        return 3
    end
    if tier == 3 then
        return 2
    end
    return 1
end

-- 阵营号 → 单位条目数组。回收表尚未加载时返回 nil（调用方等下一次再试）。
function HextechRune:GetIllusoryFactionUnits(faction)
    if g_RecycleBtnsMapByFaction == nil or faction == nil then
        return nil
    end
    local byCategory = g_RecycleBtnsMapByFaction[faction]
    if byCategory == nil then
        return nil
    end
    local result = {}
    for category = 1, 4, 1 do
        local unitInfos = byCategory[category]
        if unitInfos ~= nil then
            for i = 1, getn(unitInfos), 1 do
                tinsert(result, unitInfos[i])
            end
        end
    end
    return result
end

function HextechRune:IsIllusoryUnitUsable(unitType)
    if unitType == nil then
        return false
    end
    if g_UnitNameToUnitIndex ~= nil and g_UnitNameToUnitIndex[unitType] == nil then
        return false
    end
    if BanModeIsNameBanned ~= nil and BanModeIsNameBanned(unitType) ~= 0 then
        return false
    end
    return true
end

-- 形态名 → 基础形态名（g_PureDrawProductionAliases 的反向表，懒构建）。
function HextechRune:GetIllusoryBaseType(unitType)
    if unitType == nil then
        return nil
    end
    if self.IllusoryBaseTypeMap == nil then
        local map = {}
        if g_PureDrawProductionAliases ~= nil then
            for baseType, aliases in g_PureDrawProductionAliases do
                if aliases ~= nil then
                    for i = 1, getn(aliases), 1 do
                        if map[aliases[i]] == nil then
                            map[aliases[i]] = baseType
                        end
                    end
                end
            end
        end
        self.IllusoryBaseTypeMap = map
    end
    return self.IllusoryBaseTypeMap[unitType]
end

-- 单位中文名。地编 ID 与引擎名称键不一致的单位（CelestialLongRangeMissileVehicle 的名字键
-- 其实是 unit.CelestialHJ-10）ObjectsTranslate 会原样返回 ID，所以先用回收表/箱子表里
-- 已经登记好的 Name，再退到 ObjectsTranslate，最后拿基础形态的名字兜一次。
function HextechRune:EnsureIllusoryNameMap()
    if self.IllusoryNameMap ~= nil then
        return self.IllusoryNameMap
    end
    local map = {}
    if g_RecycleBtnsMapByFaction ~= nil then
        for faction = 1, 4, 1 do
            local byCategory = g_RecycleBtnsMapByFaction[faction]
            if byCategory ~= nil then
                for category = 1, 4, 1 do
                    local unitInfos = byCategory[category]
                    if unitInfos ~= nil then
                        for i = 1, getn(unitInfos), 1 do
                            local unitInfo = unitInfos[i]
                            if unitInfo ~= nil and unitInfo.Type ~= nil
                                and unitInfo.Name ~= nil then
                                map[unitInfo.Type] = unitInfo.Name
                            end
                        end
                    end
                end
            end
        end
    end
    if g_CrateUnits ~= nil then
        for crateType = 1, 4, 1 do
            local unitInfos = g_CrateUnits[crateType]
            if unitInfos ~= nil then
                for i = 1, getn(unitInfos), 1 do
                    local unitInfo = unitInfos[i]
                    if unitInfo ~= nil and unitInfo.Type ~= nil
                        and unitInfo.Name ~= nil and map[unitInfo.Type] == nil then
                        map[unitInfo.Type] = unitInfo.Name
                    end
                end
            end
        end
    end
    self.IllusoryNameMap = map
    return map
end

function HextechRune:GetIllusoryUnitName(unitType)
    if unitType == nil then
        return ""
    end
    local map = self:EnsureIllusoryNameMap()
    local name = map[unitType]
    if name ~= nil then
        return name
    end
    name = self:PickUltimateCreatureDisplayName(unitType)
    if name ~= nil and name ~= unitType then
        return name
    end
    -- 还没本地化：换成基础形态的名字再试一次（用户口径：以有中文的基础形态为准）。
    local base = self:GetIllusoryBaseType(unitType)
    if base ~= nil and base ~= unitType then
        name = map[base]
        if name == nil then
            name = self:PickUltimateCreatureDisplayName(base)
        end
        if name ~= nil and name ~= base then
            return name
        end
    end
    return unitType
end

function HextechRune:BuildIllusoryCardInfo(unitType)
    local info = {
        Type = unitType,
        Name = self:GetIllusoryUnitName(unitType),
        Rarity = self:GetIllusoryCardRarity(unitType),
    }
    info.Icon = self:GetIllusoryUnitIcon(unitType)
    info.Tier = self:GetIllusoryUnitTier(unitType)
    return info
end

-- 卡面图标：优先用回收表的 Image（地编实测可用的按钮贴图），退到日冕的按钮/头像命名约定。
function HextechRune:IsIllusoryUnitProducible(unitType)
    if unitType == nil then
        return false
    end
    if g_PureDrawBuildableUnitSet == nil then
        return true
    end
    if g_PureDrawBuildableUnitSet[unitType] ~= nil then
        return true
    end
    if FastHash ~= nil and g_PureDrawBuildableUnitSet[FastHash(unitType)] ~= nil then
        return true
    end
    return false
end

function HextechRune:GetIllusoryUnitIcon(unitType)
    if self.IllusoryIconMap == nil then
        local map = {}
        if g_RecycleBtnsMapByFaction ~= nil then
            for faction = 1, 4, 1 do
                local byCategory = g_RecycleBtnsMapByFaction[faction]
                if byCategory ~= nil then
                    for category = 1, 4, 1 do
                        local unitInfos = byCategory[category]
                        if unitInfos ~= nil then
                            for i = 1, getn(unitInfos), 1 do
                                local unitInfo = unitInfos[i]
                                if unitInfo ~= nil and unitInfo.Type ~= nil
                                    and unitInfo.Image ~= nil then
                                    map[unitInfo.Type] = unitInfo.Image
                                end
                            end
                        end
                    end
                end
            end
        end
        self.IllusoryIconMap = map
    end
    local icon = self.IllusoryIconMap[unitType]
    if icon ~= nil then
        return icon
    end
    return "Button_" .. unitType
end

-- 近战单位（名单唯一出处：BasicVar1.lua 的 g_TargetGroupNames.MeleeUnit）：当炮台没有远程输出。
function HextechRune:IsIllusoryMeleeUnit(unitType)
    if g_IsMeleeUnitType == nil then
        return false
    end
    return g_IsMeleeUnitType(unitType) == true
end

-- 禁兵种模式：被禁兵种的单位不能当底座。
function HextechRune:IsIllusoryBannedUnitType(unitType)
    if unitType == nil or BanModeIsNameBanned == nil then
        return false
    end
    if BanModeIsNameBanned(unitType) == 1 then
        return true
    end
    return false
end

-- 底座候选池：只给玩家自己阵营，且必须是玩家真能生产的单位。
-- 另外要剔掉「被替换型符文换掉的原形态」
function HextechRune:BuildIllusoryChassisPool(playerIndex)
    local faction = g_PlayerSide[playerIndex]
    local unitInfos = self:GetIllusoryFactionUnits(faction)
    if unitInfos == nil then
        return nil
    end
    local blocked = nil
    if self.GetReplacementTargetFilter ~= nil then
        blocked = self:GetReplacementTargetFilter(playerIndex)
    end
    local result = {}
    for i = 1, getn(unitInfos), 1 do
        local unitType = unitInfos[i].Type
        if self:IsIllusoryUnitUsable(unitType)
            and self:IsIllusoryUnitProducible(unitType)
            and not self:IsIllusoryBannedUnitType(unitType)
            and (blocked == nil or blocked[unitType] ~= true) then
            if result[unitType] == nil then
                result[unitType] = true
                tinsert(result, unitType)
            end
        end
    end
    return result
end

-- 炮台候选池：全阵营；开启抽卡/抽卡模式后再把抽卡池里"回收表没登记"的单位（箱子单位）并进来。
-- 范围口径与电脑出兵一致：电脑只按单位池里的单位类型出兵，所以这里也是取单位池。
function HextechRune:BuildIllusoryTurretPool(playerIndex)
    local seen = {}
    local result = {}
    for faction = 1, 4, 1 do
        local unitInfos = self:GetIllusoryFactionUnits(faction)
        if unitInfos ~= nil then
            for i = 1, getn(unitInfos), 1 do
                local unitType = unitInfos[i].Type
                if seen[unitType] == nil and self:IsIllusoryUnitUsable(unitType)
                    and not self:IsIllusoryMeleeUnit(unitType) then
                    seen[unitType] = true
                    tinsert(result, unitType)
                end
            end
        end
    end
    if self:IsIllusoryCrateDrawActive() and g_PureDrawBuildableUnitPool ~= nil then
        for tier = 1, 6, 1 do
            local tierPool = g_PureDrawBuildableUnitPool[tier]
            if tierPool ~= nil then
                for i = 1, getn(tierPool), 1 do
                    local unitType = tierPool[i].Type
                    if unitType ~= nil and seen[unitType] == nil
                        and self:IsIllusoryUnitUsable(unitType)
                        and not self:IsIllusoryMeleeUnit(unitType) then
                        seen[unitType] = true
                        tinsert(result, unitType)
                    end
                end
            end
        end
    end
    return result
end

-- 抽卡模式(g_DrawMode 2) 或 抽卡功能（一塔后开启的幸运箱子）任一开着就算是"有箱子单位"。
function HextechRune:IsIllusoryCrateDrawActive()
    if g_DrawMode ~= nil and g_DrawMode ~= 0 then
        return true
    end
    if g_LuckyCrateMode ~= nil and g_LuckyCrateMode == 1 then
        return true
    end
    return false
end

-- ===== 选卡 =====
-- 与符文三选一同款：无放回抽 N 张，N = GetRuneOptionDrawCount（默认 3，持有精挑细选 4）。

-- 炮台卡稀有度权重：白银 90% / 黄金 8% / 棱彩 2%。
-- 稀有度口径沿用 GetIllusoryCardRarity（T1/T2 = 白银 3、T3 = 黄金 2、T4+ = 棱彩 1）。
HextechRune.IllusoryTurretRarityWeights = { { 3, 90 }, { 2, 8 }, { 1, 2 } }

-- 底座卡的阶级权重（用户裁定 2026-11-16）：T1 2% / T2 8% / T3 及以上 90%。
HextechRune.IllusoryChassisTierWeights = { { 1, 2 }, { 2, 8 }, { 3, 90 } }

-- 按权重摇一个 key：weights = { { key, 权重 }, ... }
function HextechRune:RollIllusoryWeightedKey(weights, defaultKey)
    if weights == nil then
        return defaultKey
    end
    local total = 0
    for i = 1, getn(weights), 1 do
        total = total + weights[i][2]
    end
    if total < 1 then
        return defaultKey
    end
    local roll = self:RandomIndex(total)
    local accumulated = 0
    for i = 1, getn(weights), 1 do
        accumulated = accumulated + weights[i][2]
        if roll <= accumulated then
            return weights[i][1]
        end
    end
    return weights[1][1]
end

function HextechRune:RollIllusoryTurretRarity()
    return self:RollIllusoryWeightedKey(HextechRune.IllusoryTurretRarityWeights, 3)
end

function HextechRune:RollIllusoryChassisTierGroup()
    return self:RollIllusoryWeightedKey(HextechRune.IllusoryChassisTierWeights, 3)
end

-- 阶级组：T1 → 1、T2 → 2、T3 及以上 → 3（查不到阶级的按 3 记，底座池全是可生产单位）。
function HextechRune:GetIllusoryTierGroup(unitType)
    local tier = self:GetIllusoryUnitTier(unitType)
    if tier == nil or tier >= 3 then
        return 3
    end
    if tier < 1 then
        return 1
    end
    return tier
end

function HextechRune:PickIllusoryChassisCandidates(pool, drawCount)
    local buckets = { {}, {}, {} }
    for i = 1, getn(pool), 1 do
        local unitType = pool[i]
        local bucket = buckets[self:GetIllusoryTierGroup(unitType)]
        if bucket == nil then
            bucket = buckets[3]
        end
        tinsert(bucket, unitType)
    end
    local picked = {}
    for i = 1, drawCount, 1 do
        local candidates = buckets[self:RollIllusoryChassisTierGroup()]
        local chosen = nil
        if candidates ~= nil and getn(candidates) > 0 then
            local index = self:RandomIndex(getn(candidates))
            chosen = candidates[index]
            tremove(candidates, index)
        else
            local fallbackOrder = { 3, 2, 1 }
            for k = 1, getn(fallbackOrder), 1 do
                local other = buckets[fallbackOrder[k]]
                if chosen == nil and other ~= nil and getn(other) > 0 then
                    local index = self:RandomIndex(getn(other))
                    chosen = other[index]
                    tremove(other, index)
                end
            end
        end
        if chosen == nil then
            break
        end
        tinsert(picked, chosen)
    end
    return picked
end

-- 炮台卡：先按权重摇稀有度，再在该稀有度桶里无放回取一张。
-- 桶空了就按「白银 → 黄金 → 棱彩」的顺序退到下一个非空桶，保证张数够。
function HextechRune:PickIllusoryTurretCandidates(pool, drawCount)
    local buckets = { {}, {}, {} }
    for i = 1, getn(pool), 1 do
        local unitType = pool[i]
        local bucket = buckets[self:GetIllusoryCardRarity(unitType)]
        if bucket == nil then
            bucket = buckets[3]
        end
        tinsert(bucket, unitType)
    end
    local picked = {}
    for i = 1, drawCount, 1 do
        local candidates = buckets[self:RollIllusoryTurretRarity()]
        local chosen = nil
        if candidates ~= nil and getn(candidates) > 0 then
            local index = self:RandomIndex(getn(candidates))
            chosen = candidates[index]
            tremove(candidates, index)
        else
            local fallbackOrder = { 3, 2, 1 }
            for k = 1, getn(fallbackOrder), 1 do
                local other = buckets[fallbackOrder[k]]
                if chosen == nil and other ~= nil and getn(other) > 0 then
                    local index = self:RandomIndex(getn(other))
                    chosen = other[index]
                    tremove(other, index)
                end
            end
        end
        if chosen == nil then
            break
        end
        tinsert(picked, chosen)
    end
    return picked
end

function HextechRune:SetIllusoryCardOptions(playerIndex, unitTypes, stage)
    local cards = {}
    for i = 1, getn(unitTypes), 1 do
        local info = self:BuildIllusoryCardInfo(unitTypes[i])
        local card = {
            -- 假装成一张符文卡：复用 CreateOptionBox / 悬浮详情 / 标题字号的整套排版。
            Id = "illusory_card",
            Effect = "illusory_card",
            Rarity = info.Rarity,
            Icon = info.Icon,
            UnitDisplayName = info.Name,
            UnitTypeName = info.Type,
            UnitTier = info.Tier,
            Stage = stage,
        }
        tinsert(cards, card)
    end
    return cards
end

function HextechRune:ShowIllusoryCards(playerIndex, stage)
    local pending = self.IllusoryPending[playerIndex]
    if pending == nil or pending.Rune == nil then
        return false
    end
    local pool = nil
    if stage == 1 then
        pool = self:BuildIllusoryChassisPool(playerIndex)
    else
        pool = self:BuildIllusoryTurretPool(playerIndex)
    end
    if pool == nil then
        -- 回收表尚未加载：1 秒后重试（不改状态，重进同一个 stage）。
        SchedulerModule.delay_call(function(retryPlayerIndex, retryStage)
            HextechRune:ShowIllusoryCards(retryPlayerIndex, retryStage)
        end, 15, { playerIndex, stage })
        return false
    end
    if getn(pool) < 1 then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("hextech.illusory.error.no_units"), 10)
        self.IllusoryPending[playerIndex] = nil
        return false
    end
    local drawCount = self:GetRuneOptionDrawCount(playerIndex)
    if drawCount > getn(pool) then
        drawCount = getn(pool)
    end
    local cards = nil
    if stage == 1 then
        -- 底座卡按阶级权重抽（T1 2% / T2 8% / T3+ 90%）。
        cards = self:SetIllusoryCardOptions(playerIndex,
            self:PickIllusoryChassisCandidates(pool, drawCount), stage)
    else
        -- 炮台卡按稀有度权重抽（白银 90% / 黄金 8% / 棱彩 2%）。
        cards = self:SetIllusoryCardOptions(playerIndex,
            self:PickIllusoryTurretCandidates(pool, drawCount), stage)
    end
    self.IllusoryPending[playerIndex].Stage = stage
    self.PlayerOptions[playerIndex] = cards
    self.PlayerOptionCount[playerIndex] = getn(cards)
    self.PlayerSelectionVisible[playerIndex] = true
    for i = 1, getn(cards), 1 do
        self:CreateOptionBox(playerIndex, i, cards[i].Rarity,
            self.RarityFrameImageIds[cards[i].Rarity], cards[i])
    end
    self:ShowIllusoryHint(playerIndex, stage)
    return true
end

-- 卡面上方的居中提示：「请选择底座 / 请选择炮台」。
function HextechRune:ShowIllusoryHint(playerIndex, stage)
    local key = "hextech.illusory.hint.turret"
    if stage == 1 then
        key = "hextech.illusory.hint.chassis"
    end
    local content = Localization.get(key)
    -- 实机反馈：字号要更大，并且按「再往右一个字宽」才正好居中、再往上半个字。
    local size = 24
    exCreateCustomTextForPlayer("Player_" .. playerIndex, {
        Index = self.IllusoryHintTextIndex,
        Content = content,
        X = self:GetCenteredTextLeftX(self.CenterX, content, size) + size + size / 2,
        Y = self.CenterY - self.OptionCardHeight / 2 - 30 - 34 - size / 2,
        Color = 16777215,
        Size = size,
        AlignX = "left",
        AlignY = "top",
    })
end

function HextechRune:HideIllusoryHint(playerIndex)
    exCustomTextUpdateVisibilityForPlayer("Player_" .. playerIndex,
        self.IllusoryHintTextIndex, 0)
end

-- 符文被选中时（OnRuneChosen）调用：延迟几帧，等符文三选一的卡面拆掉再弹单位卡。
function HextechRune:StartIllusoryWeaponSelection(playerIndex, rune)
    self.IllusoryPending[playerIndex] = { Stage = 1, Rune = rune }
    -- 共命的第一层走 die 事件（更快），这里顺带把死亡观察者挂上：
    -- 与金·炽燃利息 / 银·狩猎律动同一个入口，重复调用无副作用。
    if self.EnsureBattleDeathObserver ~= nil then
        self:EnsureBattleDeathObserver()
    end
    -- 每回合开始先把炮台在地图外备好（融合与 BUFF 都在后面做）。
    self:EnsureIllusoryRoundHook()
    SchedulerModule.delay_call(function(startPlayerIndex)
        HextechRune:ShowIllusoryCards(startPlayerIndex, 1)
    end, 3, { playerIndex })
end

-- 点卡入口（02_event.lua 的 HandleOptionClick 顶部转进来）。
function HextechRune:HandleIllusoryCardClick(playerIndex, optionIndex)
    local pending = self.IllusoryPending[playerIndex]
    local cards = self.PlayerOptions[playerIndex]
    if pending == nil or cards == nil or cards[optionIndex] == nil then
        return false
    end
    local card = cards[optionIndex]
    self.PlayerOptions[playerIndex] = nil
    self.PlayerOptionCount[playerIndex] = nil
    self.PlayerSelectionVisible[playerIndex] = false
    self:HideSelectionHint(playerIndex)
    self:HideIllusoryHint(playerIndex)
    self:RemoveOptionBoxes(playerIndex)
    if pending.Stage == 1 then
        pending.ChassisType = card.UnitTypeName
        pending.ChassisName = card.UnitDisplayName
        SchedulerModule.delay_call(function(nextPlayerIndex)
            HextechRune:ShowIllusoryCards(nextPlayerIndex, 2)
        end, 3, { playerIndex })
        return true
    end
    -- 第二张：炮台。落到符文实例上，然后立刻给场上已有的底座补炮台。
    local rune = pending.Rune
    self.IllusoryPending[playerIndex] = nil
    if rune == nil or pending.ChassisType == nil then
        return true
    end
    rune.IllusoryChassisType = pending.ChassisType
    rune.IllusoryChassisName = pending.ChassisName
    rune.IllusoryTurretType = card.UnitTypeName
    rune.IllusoryTurretName = card.UnitDisplayName
    self:RefreshIllusoryBindings()
    -- 面板正开着就立刻刷新，让末尾后缀马上出现。
    if self.PanelVisible ~= nil and self.PanelVisible[playerIndex] then
        self:HidePanel(playerIndex)
        self:ShowPanel(playerIndex)
    end
    return true
end

-- ===== 持有数据 =====
function HextechRune:GetIllusoryPairs(playerIndex)
    local result = {}
    if playerIndex == nil then
        return result
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == "illusory_weapon" and rune.IllusoryChassisType ~= nil
            and rune.IllusoryTurretType ~= nil then
            tinsert(result, {
                Key = self:GetRuneEffectInstanceId(rune),
                ChassisType = rune.IllusoryChassisType,
                TurretType = rune.IllusoryTurretType,
                ChassisName = rune.IllusoryChassisName,
                TurretName = rune.IllusoryTurretName,
            })
        end
    end
    return result
end

-- 面板详情末尾后缀：（底座：X，炮台：Y）；还没选完就什么都不加。
function HextechRune:GetIllusoryBonusText(playerIndex, rune)
    if rune == nil or rune.Effect ~= "illusory_weapon" then
        return nil
    end
    if rune.IllusoryChassisName == nil or rune.IllusoryTurretName == nil then
        return nil
    end
    return Localization.get("hextech.illusory.suffix",
        rune.IllusoryChassisName, rune.IllusoryTurretName)
end

-- ===== 出生绑定 =====
-- 见 RefreshIllusoryPair。

function HextechRune:IsIllusoryPairBound(chassisObjectId, pairKey)
    local bound = self.IllusoryBoundKeys[chassisObjectId]
    if bound == nil then
        return false
    end
    return bound[pairKey] == true
end

function HextechRune:MarkIllusoryPairBound(chassisObjectId, pairKey)
    local bound = self.IllusoryBoundKeys[chassisObjectId]
    if bound == nil then
        bound = {}
        self.IllusoryBoundKeys[chassisObjectId] = bound
    end
    bound[pairKey] = true
end

-- 隐身 + 无敌：照出生点那只无敌隐身迅雷车（LUABOX/HIDEINI_0.lua 的 HIDEOBJ）的做法，
function HextechRune:ConfigureIllusoryTurret(turret)
    if turret == nil then
        return
    end
    -- 排查开关：IllusoryVisibleTest 时一个状态都不加，就当一只普通可见单位用。
    if HextechRune.IllusoryVisibleTest == true then
        return
    end
    ObjectSetObjectStatus(turret, "STEALTHED")
    ObjectSetObjectStatus(turret, "UNDER_IRON_CURTAIN")
    ObjectSetObjectStatus(turret, "UNSELECTABLE")
    ObjectSetObjectStatus(turret, "NO_COLLISIONS")
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", turret, "STEALTHED", "TRUE")
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", turret, "UNDER_IRON_CURTAIN", "TRUE")
    ExecuteAction("UNIT_SET_MODELCONDITION_GENERIC", turret, "HIDDEN", 0)
    ExecuteAction("UNIT_AFFECT_OBJECT_PANEL_FLAGS", turret, "Indestructible", true)
    exObjectSetFixedScale(ObjectGetId(turret), 0.01)
    -- 索敌与开火交给引擎默认行为：脚本出生的单位本身就会自动打人，这里不再下发 stance
end

-- ===== 地图外停泊 → 融合 =====
-- 生成通道保证归属与形态，落点再单独挪一次，与 16_cryo_satellite 的钥匙基地同一套做法），
-- 等底座单位出现后再把炮台挪到它身上（融合），最后补 BUFF。
HextechRune.IllusoryParkX = 3324.27
HextechRune.IllusoryParkY = 8979.87

function HextechRune:EnsureIllusoryRoundHook()
    if self.IllusoryRoundHookReady or RoundLuaManager == nil
        or RoundLuaManager.CallOnEveryRoundBegin == nil then
        return
    end
    self.IllusoryRoundHookReady = true
    RoundLuaManager.CallOnEveryRoundBegin(function()
        HextechRune:PrepareIllusoryTurretPool()
    end, {})
end

function HextechRune:GetIllusoryParkedList(playerIndex)
    local list = self.IllusoryParkedTurrets[playerIndex]
    if list == nil then
        list = {}
        self.IllusoryParkedTurrets[playerIndex] = list
    end
    return list
end

function HextechRune:CountParkedIllusoryTurrets(playerIndex, turretType)
    local list = self.IllusoryParkedTurrets[playerIndex]
    if list == nil then
        return 0
    end
    local count = 0
    for i = 1, getn(list), 1 do
        local entry = list[i]
        if entry ~= nil and entry.Parked == true and entry.TurretType == turretType
            and ObjectIsAlive(entry.ObjectId) then
            count = count + 1
        end
    end
    return count
end

function HextechRune:GetIllusoryTurretOwner(playerIndex)
    local sideIndex = nil
    if self.GetPlayerSideIndex ~= nil then
        sideIndex = self:GetPlayerSideIndex(playerIndex)
    end
    if sideIndex ~= nil and g_SideAnchorName ~= nil
        and g_SideAnchorName[sideIndex] ~= nil then
        return g_SideAnchorName[sideIndex]
    end
    return "Player_" .. tostring(playerIndex)
end

-- 在地图外生成一只炮台。返回 entry；引擎没建出来就返回 nil。
function HextechRune:CreateParkedIllusoryTurret(playerIndex, turretType)
    self.IllusorySerial = (self.IllusorySerial or 0) + 1
    local name = format("HexIllusoryTurret%d", self.IllusorySerial)
    local ownerName = self:GetIllusoryTurretOwner(playerIndex)
    local teamName = ownerName .. "/team" .. ownerName
    local parkX = self.IllusoryParkX + self.IllusorySerial * 20
    local parkY = self.IllusoryParkY
    -- 地图外没有航点：走该玩家自己起点的航点通道生成（归属只由 team 参数决定），再挪到图外。
    local waypoint = "Player_" .. tostring(playerIndex) .. "_Start"
    -- 告知抽卡系统：这不是箱子开出来的单位。
    if self.MarkNextSpawnAsKnownPureDrawUnit ~= nil then
        self:MarkNextSpawnAsKnownPureDrawUnit()
    end
    -- 先走航点通道（保证阵营/形态，钥匙基地同一套通道），取不到再退到坐标通道。
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT_WITH_ORIENTATION", name,
        turretType, teamName, waypoint, 0)
    local unit = GetObjectByScriptName(name)
    if unit == nil then
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", name, turretType,
            teamName, { X = parkX, Y = parkY, Z = 0 }, 0)
        unit = GetObjectByScriptName(name)
    end
    if unit == nil then
        -- 两次都没取到对象：按脚本名删掉，别留一只没入账的隐形单位在场外被算进单位池。
        ExecuteAction("NAMED_DELETE", name)
        return nil
    end
    ObjectSetPosition(unit, parkX, parkY, 0)
    -- 一生成就当技能召唤单位登记：它跟场上的真单位同模板同一边，不登记会被席位认领当成
    -- 玩家的普通单位（抢兵种配额）。AssignNewSideBattleUnits 本来就会跳过技能召唤单位。
    if RegisterSkillSummonedUnit ~= nil then
        RegisterSkillSummonedUnit(unit)
    end
    local entry = {
        Name = name,
        Unit = unit,
        ObjectId = ObjectGetId(unit),
        InstanceId = ObjectGetInstanceId(unit),
        PlayerIndex = playerIndex,
        TurretType = turretType,
        Parked = true,
    }
    self.IllusoryTurretByObjectId[entry.ObjectId] = entry
    tinsert(self:GetIllusoryParkedList(playerIndex), entry)
    self:EnsureIllusoryWatchdog()
    return entry
end

-- 从停泊堆里取一只同类型的炮台（顺手清掉已经死掉的）。类型不符的留着给别的对子用。
function HextechRune:TakeParkedIllusoryTurret(playerIndex, turretType)
    local list = self.IllusoryParkedTurrets[playerIndex]
    if list == nil then
        return nil
    end
    local remain = {}
    local chosen = nil
    for i = 1, getn(list), 1 do
        local entry = list[i]
        if entry ~= nil then
            if not ObjectIsAlive(entry.ObjectId) then
                self:RemoveIllusoryEntry(entry)
            elseif entry.Parked ~= true then
                -- 已融合，不再留在停泊堆里
            elseif chosen == nil and entry.TurretType == turretType then
                chosen = entry
            else
                -- 类型不符的、同类型的第二只都留着，后面还有别的底座要用。
                tinsert(remain, entry)
            end
        end
    end
    self.IllusoryParkedTurrets[playerIndex] = remain
    return chosen
end

-- 回合开始后重试融合的帧位（15 帧 = 1 秒）：出兵与合成是分批落地的，
-- 单靠出兵扫描那一帧经常只看得到 1 个单位（实测「扫描 1 个单位，本轮新绑 0 只炮台」就是它）。
HextechRune.IllusoryRefreshDelays = { 45, 75, 120, 180, 240, 330, 420 }

-- 回合开始：把本轮要用的炮台先在地图外备好（每对配对备「底座单位数」只，至少 1 只）。
function HextechRune:PrepareIllusoryTurretPool()
    for playerIndex = 1, 8, 1 do
        local pairList = self:GetIllusoryPairs(playerIndex)
        if getn(pairList) > 0 then
            for pairIndex = 1, getn(pairList), 1 do
                local pair = pairList[pairIndex]
                -- 回合开始先在地图外备 1 只打底，融合时不够再按需现造（不维护数量账）。
                local need = 1
                local have = self:CountParkedIllusoryTurrets(playerIndex, pair.TurretType)
                for i = have + 1, need, 1 do
                    self:CreateParkedIllusoryTurret(playerIndex, pair.TurretType)
                end
            end
            -- 反复补融合：单位是分批生成的，早几帧经常只扫到 1 个单位（实测就这么漏掉了）。
            for i = 1, getn(self.IllusoryRefreshDelays), 1 do
                SchedulerModule.delay_call(function()
                    HextechRune:RefreshIllusoryBindings()
                end, self.IllusoryRefreshDelays[i], {})
            end
        end
    end
end

-- 融合：把停泊在图外的炮台挪到底座身上，套隐形/不可摧毁状态，再补 BUFF。
function HextechRune:FuseIllusoryTurret(entry, chassisUnit, pair)
    if entry == nil or entry.Unit == nil then
        return nil
    end
    if not ObjectIsAlive(entry.ObjectId) or not ObjectIsAlive(chassisUnit) then
        self:RemoveIllusoryEntry(entry)
        return nil
    end
    local x, y, z = ObjectGetPosition(chassisUnit)
    if x ~= nil then
        ObjectSetPosition(entry.Unit, x, y, z)
    end
    -- 关键：队伍必须跟底座一致。脚本生成的单位默认落在「待命队」
    -- （PlyrCivilian/teamPlyrCivilian），不进 AI 进攻队就会原地待命、永远不开火
    local teamName = nil
    if ObjectTeamName ~= nil then
        teamName = ObjectTeamName(chassisUnit)
    end
    local ownerName = self:GetIllusoryTurretOwner(entry.PlayerIndex)
    if teamName == nil or type(teamName) ~= "string" then
        teamName = "ATTACK"
    end
    if strfind(teamName, "/") == nil then
        teamName = ownerName .. "/" .. teamName
    end
    ExecuteAction("UNIT_SET_TEAM", entry.Unit, teamName)
    -- 技能召唤单位登记在生成时就做过了（见 CreateParkedIllusoryTurret），这里不重复登记。
    entry.Parked = false
    entry.BaseObjectId = ObjectGetId(chassisUnit)
    -- 底座登记进「不许装车」名单：炮台是运输载具时，装车逻辑会把底座塞进去 → 底座卡无敌。
    self:MarkIllusoryChassis(entry.BaseObjectId)
    self:EjectIllusoryChassis(chassisUnit)
    entry.ChassisType = pair.ChassisType
    entry.PairKey = pair.Key
    -- 记录底座当前的兵种槽号，镜像符文时按它的口径取阶级/护甲。
    entry.BaseUnitIndex = self:GetIllusoryUnitIndex(pair.ChassisType)
    local byBase = self.IllusoryTurretsByBase[entry.BaseObjectId]
    if byBase == nil then
        byBase = {}
        self.IllusoryTurretsByBase[entry.BaseObjectId] = byBase
    end
    byBase[entry.ObjectId] = entry
    -- 立刻补一次符文增益，不用等到下回合的出兵扫描。
    self:MirrorRunesToAllIllusoryTurrets()
    -- 隐形/无敌放在最后：状态位在换队之后加（换队会重建对象状态），而且万一某个状态位
    self:ConfigureIllusoryTurret(entry.Unit)
    return entry
end

-- 给某只底座配一只炮台：优先用回合开始就在地图外备好的那只，没有就现造一只。
function HextechRune:SpawnIllusoryTurret(playerIndex, chassisUnit, pair)
    local entry = self:TakeParkedIllusoryTurret(playerIndex, pair.TurretType)
    if entry == nil then
        entry = self:CreateParkedIllusoryTurret(playerIndex, pair.TurretType)
    end
    if entry == nil then
        return nil
    end
    return self:FuseIllusoryTurret(entry, chassisUnit, pair)
end

function HextechRune:GetIllusoryUnitIndex(unitType)
    if g_UnitNameToUnitIndex == nil or unitType == nil then
        return nil
    end
    return g_UnitNameToUnitIndex[unitType]
end

-- 每回合给「场上自己这一边的该底座单位」补齐炮台，口径与符文 BUFF 一致：
function HextechRune:RefreshIllusoryPair(playerIndex, pair)
    local matched = 0
    local scanned = 0
    if pair == nil or pair.ChassisType == nil then
        return matched, scanned
    end
    local unitIndex = self:GetIllusoryUnitIndex(pair.ChassisType)
    local sideIndex = nil
    if self.GetPlayerSideIndex ~= nil then
        sideIndex = self:GetPlayerSideIndex(playerIndex)
    end
    if unitIndex == nil or sideIndex == nil or FilterLIST == nil
        or FilterLIST[unitIndex] == nil or g_SideFindObjects == nil then
        return matched, scanned
    end
    local units, count = g_SideFindObjects(sideIndex, nil, FilterLIST[unitIndex])
    if units == nil or type(count) ~= "number" then
        return matched, scanned
    end
    local mine = {}
    local others = {}
    for i = 1, count, 1 do
        local unit = units[i]
        if unit ~= nil and ObjectIsAlive(unit) then
            scanned = scanned + 1
            local objectId = ObjectGetId(unit)
            if not self:IsIllusoryPairBound(objectId, pair.Key) then
                local assignment = self.BattleUnitAssignments[
                    objectId]
                if assignment ~= nil
                    and assignment.PlayerIndex == playerIndex then
                    tinsert(mine, unit)
                else
                    tinsert(others, unit)
                end
            end
        end
    end
    for i = 1, getn(others), 1 do
        tinsert(mine, others[i])
    end
    for i = 1, getn(mine), 1 do
        local chassisUnit = mine[i]
        -- 只有真的融合成功才标记已绑定：失败就留给下一帧/下回合重试。
        if self:SpawnIllusoryTurret(playerIndex, chassisUnit, pair) ~= nil then
            self:MarkIllusoryPairBound(ObjectGetId(chassisUnit), pair.Key)
            matched = matched + 1
        end
    end
    return matched, scanned
end

-- 回合开始/拿卡后扫一遍：每只底座按已持有的每一对"底座+炮台"补一只炮台。
function HextechRune:RefreshIllusoryBindings()
    local hasAny = false
    for playerIndex = 1, 8, 1 do
        local pairList = self:GetIllusoryPairs(playerIndex)
        if getn(pairList) > 0 then
            hasAny = true
            local matched = 0
            local scanned = 0
            for pairIndex = 1, getn(pairList), 1 do
                local pairMatched, pairScanned = self:RefreshIllusoryPair(
                    playerIndex, pairList[pairIndex])
                matched = matched + pairMatched
                scanned = scanned + pairScanned
            end
            if matched > 0 or scanned > 0 then
            end
        end
    end
    return hasAny
end

-- ===== 每帧看门狗：跟随 + 共命 =====
function HextechRune:EnsureIllusoryWatchdog()
    if self.IllusoryWatchdogStarted then
        return
    end
    self.IllusoryWatchdogStarted = true
    -- 每 3 帧一次（约 0.2 秒）：跟随用不着每帧，但共命必须够快。
    SchedulerModule.call_every_x_frame(function()
        HextechRune:SweepIllusoryTurrets()
    end, 3, nil, {})
end

-- 跟随：只在离底座太远时才把它挪回去。不要每 3 帧硬拉：
-- 炮台进了 AI 进攻队以后由引擎自己驱动走位/开火，频繁传送会打断它的行动。
HextechRune.IllusoryFollowMaxDistance = 50

-- 只对飞机炮台动手：读弹药的接口要求单位带 WeaponSetUpdate 组件，地面/海军炮台不必去碰。
HextechRune.IllusoryAmmoWeaponIndexMax = 6
HextechRune.IllusoryAmmoRefillFallback = 100

-- 退一步按模板名里的 "Aircraft" 认——本图所有机型名都带这个词，非飞机单位不带。
function HextechRune:IsIllusoryAircraftUnitType(unitType)
    if unitType == nil then
        return false
    end
    if BanModeGetNameTypes ~= nil then
        local types = BanModeGetNameTypes(unitType)
        if types ~= nil then
            for i = 1, getn(types), 1 do
                if types[i] == "aircraft" then
                    return true
                end
            end
            return false
        end
    end
    if strfind(unitType, "Aircraft") ~= nil then
        return true
    end
    return false
end

-- 把炮台打空的武器槽补满（读当前弹药 → 为 0 才补；补到 max ammo，读不到就用兜底值）。
function HextechRune:RefillIllusoryTurretAmmo(entry)
    if entry == nil or entry.Unit == nil then
        return
    end
    if ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount == nil
        or ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount == nil then
        return
    end
    if not self:IsIllusoryAircraftUnitType(entry.TurretType) then
        return
    end
    for weaponIndex = 1, HextechRune.IllusoryAmmoWeaponIndexMax, 1 do
        local current = ObjectGetWeaponSetUpdateWeaponCurrentAmmoCount(
            entry.Unit, 1, 1, weaponIndex)
        if current ~= nil and current == 0 then
            local maxAmmo = nil
            if ObjectGetWeaponSetUpdateWeaponMaxAmmoCount ~= nil then
                maxAmmo = ObjectGetWeaponSetUpdateWeaponMaxAmmoCount(
                    entry.Unit, 1, 1, weaponIndex)
            end
            if maxAmmo == nil or maxAmmo < 1 then
                maxAmmo = HextechRune.IllusoryAmmoRefillFallback
            end
            ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(
                entry.Unit, 1, 1, weaponIndex, maxAmmo)
        end
    end
end

function HextechRune:FollowIllusoryTurret(entry, chassisUnit)
    local x, y, z = ObjectGetPosition(chassisUnit)
    if x == nil then
        return
    end
    local turretX, turretY = ObjectGetPosition(entry.Unit)
    if turretX ~= nil and turretY ~= nil then
        local dx = turretX - x
        local dy = turretY - y
        local maxDistance = HextechRune.IllusoryFollowMaxDistance
        if dx * dx + dy * dy <= maxDistance * maxDistance then
            return
        end
    end
    if ObjectSetPosition ~= nil then
        ObjectSetPosition(entry.Unit, x, y, z)
    elseif exObjectMoveTo ~= nil then
        exObjectMoveTo(entry.ObjectId, x, y, z)
    end
    self:RefillIllusoryTurretAmmo(entry)
end

function HextechRune:RemoveIllusoryEntry(entry)
    if entry == nil then
        return
    end
    if entry.ObjectId ~= nil then
        self.IllusoryTurretByObjectId[entry.ObjectId] = nil
    end
    local byBase = self.IllusoryTurretsByBase[entry.BaseObjectId]
    if byBase ~= nil and entry.ObjectId ~= nil then
        byBase[entry.ObjectId] = nil
        if next(byBase) == nil then
            self.IllusoryTurretsByBase[entry.BaseObjectId] = nil
        end
    end
    if g_SkillSummonedUnits ~= nil and entry.ObjectId ~= nil then
        g_SkillSummonedUnits[entry.ObjectId] = nil
    end
end

-- 停泊堆清理：每 3 帧把已经死掉的炮台从停泊堆里摘掉（它们没融合，不需要共命）。
function HextechRune:SweepIllusoryParkedTurrets()
    for playerIndex = 1, 8, 1 do
        local list = self.IllusoryParkedTurrets[playerIndex]
        if list ~= nil and getn(list) > 0 then
            local remain = {}
            for i = 1, getn(list), 1 do
                local entry = list[i]
                if entry ~= nil then
                    if not ObjectIsAlive(entry.ObjectId) then
                        self:RemoveIllusoryEntry(entry)
                    elseif entry.Parked == true then
                        tinsert(remain, entry)
                    end
                end
            end
            self.IllusoryParkedTurrets[playerIndex] = remain
        end
    end
end

function HextechRune:UnmarkIllusoryPairBound(chassisObjectId, pairKey)
    local bound = self.IllusoryBoundKeys[chassisObjectId]
    if bound ~= nil and pairKey ~= nil then
        bound[pairKey] = nil
        if next(bound) == nil then
            self.IllusoryBoundKeys[chassisObjectId] = nil
        end
    end
end

-- 底座死亡（17_death_triggers.lua 的 OnDeathRewardUnitDie 调用）：炮台一起消失。
-- 这是「共命」的事件层；看门狗那一层负责兜住回合末清场、引擎回收等不触发 die 的情形。
function HextechRune:KillIllusoryTurretsOf(baseObjectId)
    local byBase = self.IllusoryTurretsByBase[baseObjectId]
    if byBase == nil then
        return false
    end
    local turretIds = {}
    for turretObjectId, entry in byBase do
        tinsert(turretIds, turretObjectId)
    end
    for i = 1, getn(turretIds), 1 do
        local entry = byBase[turretIds[i]]
        if entry ~= nil then
            if ObjectIsAlive(entry.ObjectId) then
                ExecuteAction("NAMED_DELETE", entry.Unit)
            end
            self:RemoveIllusoryEntry(entry)
        end
    end
    self.IllusoryTurretsByBase[baseObjectId] = nil
    self.IllusoryBoundKeys[baseObjectId] = nil
    return true
end

-- 补融合请求：30 帧内最多排一次（看门狗每 3 帧会调，防止失败时反复重试刷屏）。
function HextechRune:RequestIllusoryRefresh()
    if self.IllusoryRefreshPending then
        return
    end
    self.IllusoryRefreshPending = true
    SchedulerModule.delay_call(function()
        HextechRune.IllusoryRefreshPending = false
        HextechRune:RefreshIllusoryBindings()
    end, 30, {})
end

function HextechRune:SweepIllusoryTurrets()
    self:SweepIllusoryParkedTurrets()
    local chassisIds = {}
    for baseObjectId, byBase in self.IllusoryTurretsByBase do
        tinsert(chassisIds, baseObjectId)
    end
    for i = 1, getn(chassisIds), 1 do
        local baseObjectId = chassisIds[i]
        local byBase = self.IllusoryTurretsByBase[baseObjectId]
        if byBase ~= nil then
            local baseAlive = ObjectIsAlive(baseObjectId)
            local chassisUnit = nil
            if baseAlive then
                chassisUnit = GetObjectById(baseObjectId)
                if chassisUnit == nil then
                    baseAlive = false
                end
            end
            local turretIds = {}
            for turretObjectId, entry in byBase do
                tinsert(turretIds, turretObjectId)
            end
            for k = 1, getn(turretIds), 1 do
                local entry = byBase[turretIds[k]]
                if entry == nil then
                    -- 已在本轮被清掉
                elseif not baseAlive then
                    -- 共命：底座没了（被打死 / 回合末清场 / 被回收）→ 炮台一起消失。
                    if ObjectIsAlive(entry.ObjectId) then
                        ExecuteAction("NAMED_DELETE", entry.Unit)
                    end
                    self:RemoveIllusoryEntry(entry)
                    -- 底座死透了，把「不许装车」的标记也撤掉（objectId 会被引擎复用给新单位）
                    if HextechRune.IllusoryChassisIds ~= nil then
                        HextechRune.IllusoryChassisIds[baseObjectId] = nil
                    end
                elseif not ObjectIsAlive(entry.ObjectId)
                    or ObjectGetInstanceId(entry.Unit) ~= entry.InstanceId then
                    -- 炮台被清掉或对象 id 被复用（炮台现在归 AI 阵营，会吃到 4 回合寿命）：
                    -- 解除绑定并排队补一次融合，底座还在就当场补一只，不让它整轮哑火。
                    local lostPairKey = entry.PairKey
                    self:RemoveIllusoryEntry(entry)
                    self:UnmarkIllusoryPairBound(baseObjectId, lostPairKey)
                    self:RequestIllusoryRefresh()
                else
                    -- 底座被载具装车系统的巡收又塞回车里时，这里每 3 帧请它下车（卡无敌）。
                    self:EjectIllusoryChassis(chassisUnit)
                    self:FollowIllusoryTurret(entry, chassisUnit)
                    -- 每 45 帧（15 次看门狗）再刷一次隐身/无敌：引擎在进图、换队、升级、
                    -- 被打之后都可能把状态位清掉，靠这一遍自愈。
                    entry.ConfigTicks = (entry.ConfigTicks or 0) + 1
                    if entry.ConfigTicks >= 15 then
                        entry.ConfigTicks = 0
                        self:ConfigureIllusoryTurret(entry.Unit)
                    end
                end
            end
        end
    end
end

-- ===== 吃底座的 BUFF =====
-- 炮台对象 id 混入底座所属兵种的 typeLookup 桶（04_buff.lua 的 BuildSideUnitTypeLookup 调用），
-- 注意先把炮台从它自己类型的桶里摘掉：炮台是"真单位"，本来就会落进自己兵种的桶，
function HextechRune:InjectIllusoryTurretsToTypeLookup(sideIndex, typeLookup)
    if typeLookup == nil or next(self.IllusoryTurretByObjectId) == nil then
        return typeLookup
    end
    for turretObjectId, entry in self.IllusoryTurretByObjectId do
        -- 停泊中（还没融合）的炮台没有底座口径，跳过；BaseObjectId 为 nil 时也不能拿去索引。
        if entry.Parked ~= true and entry.BaseObjectId ~= nil
            and self:GetPlayerSideIndex(entry.PlayerIndex) == sideIndex
            and ObjectIsAlive(turretObjectId) then
            local chassisBuckets = {}
            for typeName, bucket in typeLookup do
                if type(bucket) == "table" then
                    bucket[turretObjectId] = nil
                    if bucket[entry.BaseObjectId] then
                        tinsert(chassisBuckets, bucket)
                    end
                end
            end
            for i = 1, getn(chassisBuckets), 1 do
                chassisBuckets[i][turretObjectId] = true
            end
        end
    end
    return typeLookup
end

-- 炮台吃底座的符文增益：全部炮台合成一次 ApplyOwnedRunesToNewAssignments 调用。
-- 每只炮台配一个「固定的」assignment，靠它的 AppliedRunes 去重，同一份符文不会跨回合重复叠；
-- 合成一次调用也让 BuildAllBattleUnitTypeLookup 只跑一遍（它内部会扫全图）。
function HextechRune:MirrorRunesToAllIllusoryTurrets()
    if next(self.IllusoryTurretByObjectId) == nil then
        return
    end
    local ids = {}
    for turretObjectId, entry in self.IllusoryTurretByObjectId do
        -- 停泊在图外、还没融合的炮台不参与（没有底座兵种口径，也还没有 baseid）。
        if entry.Parked ~= true and entry.BaseObjectId ~= nil
            and ObjectIsAlive(turretObjectId) then
            tinsert(ids, turretObjectId)
        end
    end
    if getn(ids) < 1 then
        return
    end
    local assignments = {}
    for i = 1, getn(ids), 1 do
        local entry = self.IllusoryTurretByObjectId[ids[i]]
        if entry ~= nil then
            if entry.Assignment == nil then
                entry.Assignment = {
                    Unit = entry.Unit,
                    ObjectId = entry.ObjectId,
                    UnitIndex = entry.BaseUnitIndex,
                    PlayerIndex = entry.PlayerIndex,
                    AppliedRunes = {},
                    IsIllusoryTurret = true,
                }
            end
            tinsert(assignments, entry.Assignment)
        end
    end
    if getn(assignments) < 1 then
        return
    end
    self:ApplyOwnedRunesToNewAssignments(assignments, "虚幻武器炮台")
end

-- 主入口：每回合出兵扫描后调用（04_buff.lua 的 ApplyBattleUnitEffectPass）。
function HextechRune:ApplyIllusoryWeaponPass(sourceName, skipObjects, seenObjects)
    local hasAny = self:RefreshIllusoryBindings()
    -- 没有新炮台也可能有新符文（重复获取），所以镜像这一步不看 hasAny。
    self:MirrorRunesToAllIllusoryTurrets()
    return hasAny
end
