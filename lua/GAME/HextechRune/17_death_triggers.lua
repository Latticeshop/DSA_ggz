-- 讲解见 analysis/地图注释说明文档.md 附录 A.36

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

-- 把一次兵种扫描的结果并进「模板 → 兵种」缓存。死亡瞬间拿不到死者的 category（引擎没有
-- 单对象类别接口，尸体也扫不到），只能靠它生前被扫到过；扫描本身就是本符文要做的，
-- 顺手记一遍几乎免费。
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
    return result
end

-- 本方是否有人持有狩猎律动（决定要不要为死者阵营补扫一次兵种）。
function HextechRune:SideHasHuntRhythm(firstPlayerIndex, lastPlayerIndex)
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        if self:GetHuntRhythmUnitTypes(playerIndex) ~= nil then
            return true
        end
    end
    return false
end

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
    self.HuntVariantPoolIndex = result
    return result
end

-- 候选 = 场上该兵种 ∩ 玩家卡池里买过该兵种的模板 ∩ 未满血。卡池槽位靠 instanceId 反查
-- （与回收计数 unitgetcountanddelet 同一句写法），查不到再用形态反查表并回本体槽，
-- 所以场上多出来的、玩家没买的模板不会被治到。
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
        if unitIndex ~= nil and (tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0) > 0 then
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
function HextechRune:ApplyHuntRhythmHeal(sideIndex, firstPlayerIndex, lastPlayerIndex,
    deadTypes)
    if deadTypes == nil then
        return
    end
    local lookup
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
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
function HextechRune:PayCombustionInterest(dyingObjId, firstPlayerIndex, lastPlayerIndex)
    local interestMoney = GetCombustionInterestMoney()
    local rewarded = false
    local previous = SetWorldBuilderThisPlayer(1)
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
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
    if not self.BattleDeathPhaseActive then
        return
    end
    local deadSideIndex = self:GetBattleOwnerSideIndex(ownerPlayerName)
    local sideIndex = self:GetDeathRewardSideIndex(ownerPlayerName)
    if sideIndex == nil then
        return
    end
    local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
    self:PayCombustionInterest(dyingObjId, firstPlayerIndex, lastPlayerIndex)

    -- 死者阵营补扫一次喂兵种缓存：只在「缓存没见过这个模板」且本方确实有人持卡时才扫，
    -- 并且每个模板只试一次（一次要 ObjectFindObjects 九遍，密了会卡）。死者本身已经扫不到了，
    -- 补扫的意义在于同模板的其它单位还活着，认过一次以后就一直认得。
    local deadTypes = self.BattleUnitTypeByInstance[dyingObjInstanceId]
    if deadTypes == nil and deadSideIndex ~= nil
        and self.HuntTypeSeedTried[dyingObjInstanceId] == nil
        and self:SideHasHuntRhythm(firstPlayerIndex, lastPlayerIndex) then
        self.HuntTypeSeedTried[dyingObjInstanceId] = true
        self:RememberUnitTypes(self:BuildSideUnitTypeLookup(deadSideIndex))
        deadTypes = self.BattleUnitTypeByInstance[dyingObjInstanceId]
    end
    -- 缓存没见过这个模板（首次登场就阵亡）时按「不匹配」处理，宁可少治也不乱治。
    self:ApplyHuntRhythmHeal(sideIndex, firstPlayerIndex, lastPlayerIndex, deadTypes)
end
