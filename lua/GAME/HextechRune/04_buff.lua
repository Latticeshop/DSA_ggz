-- 海克斯符文系统：首批可实测效果。

HextechRune = HextechRune or {}

HextechRune.UnitTypeFilters = {
    infantry = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "INFANTRY",
        Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS"
    }),
    vehicle = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "VEHICLE HUGE_VEHICLE",
        Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS"
    }),
    aircraft = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "AIRCRAFT",
        Exclude = "STRUCTURE DEBRIS"
    }),
    navy = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "SHIP",
        Exclude = "STRUCTURE DEBRIS"
    }),
}
-- 可变形单位按其两种作战形态同时归入两个兵种，不依赖当前模型形态的
-- AIRCRAFT / VEHICLE / SHIP category。这样它们能同时享受两类兵种符文。
HextechRune.DualUnitTypeFilters = {
    {
        Types = { "vehicle", "aircraft" },
        Filter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            IncludeThing = {
                -- 天狗
                "JapanAntiInfantryVehicle",
                "JapanAntiInfantryVehicle_Enhanced",
                "JapanAntiInfantryVehicle_Enhanced_Water",
                -- VX
                "JapanAntiAirVehicleTech1",
                "JapanAntiAirVehicleTech1_Enhanced",
                "JapanAntiAirVehicleTech1_Enhanced_Water",
                -- 心神
                "JapanMissileMechaAdvanced",
                "JapanMissileMechaAdvanced_Enhanced",
                "JapanMissileMechaAdvanced_Enhanced_Water",
            },
            Exclude = "STRUCTURE DEBRIS"
        }),
    },
    {
        Types = { "aircraft", "navy" },
        Filter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            IncludeThing = {
                -- 海翼
                "JapanAntiAirShip",
                "JapanAntiAirShip_Enhanced",
                -- 超级要塞（空中要塞 / 大头轰炸形态）
                "JapanFortressShip",
                "JapanGigaFortress_Land",
            },
            Exclude = "STRUCTURE DEBRIS"
        }),
    },
}
-- 无限火力（飞机）只开放给指定对空战斗机、摇光巡天炮及其同机型变体。
-- 轰炸机、天狗、心神等其它飞机即使属于 aircraft 兵种，也不会获得无限弹药。
HextechRune.InfiniteAmmoAircraftFilter = CreateObjectFilter({
    Rule = "ANY", Relationship = "SAME_PLAYER",
    IncludeThing = {
        -- 阿波罗
        "AlliedFighterAircraft",
        "AlliedFighterAircraft_Enhanced",
        "AlliedFighterAircraft_WithTrailSomke",
        -- 阿瑞斯
        "AlliedInterceptorAircraft",
        "AlliedInterceptorAircraft_Enhanced",
        -- 凤凰
        "CelestialFighterAircraft",
        "CelestialFighterAircraft_WithBlueTrailSomke",
        "CelestialFighterAircraft_WithRedTrailSomke",
        "CelestialFighterAircraft_WithTrailSomke",
        "CelestialFighterAircraft_WithWhiteTrailSomke",
        -- 崇明
        "CelestialInterceptorAircraft",
        "CelestialInterceptorAircraft_Enhanced",
        -- 米格
        "SovietFighterAircraft",
        "SovietFighterAircraft_Enhanced",
        -- 苏霍伊
        "SovietInterceptorAircraft",
        "SovietInterceptorAircraft_Enhanced",
        -- 摇光巡天炮
        "CelestialAdvanceAircraftTech4",
        "CelestialAdvanceAircraftTech4_Enhanced",
    }
})
HextechRune.UnitTypeOrder = { "infantry", "vehicle", "aircraft", "navy" }
-- 与缩小模式一致，持续时间覆盖整场战斗；同一单位的同一符文只加载一次。
HextechRune.PersistentBuffDuration = 9999
-- 以战斗单位 objectId 为键，记录该单位按单位池配额归属的玩家及已加载符文。
-- Unit 句柄同时用于识别引擎复用 objectId 的情况。
HextechRune.BattleUnitAssignments = HextechRune.BattleUnitAssignments or {}

if not g_HextechDamageX150Modifier then
    g_HextechDamageX150Modifier = exAttributeModifierCreate({ DAMAGE_MULT = 1.5 }, 1)
end
if not g_HextechSpeedX140Modifier then
    g_HextechSpeedX140Modifier = exAttributeModifierCreate({ SPEED = 1.4 }, 1)
end
if not g_HextechRateOfFireX150Modifier then
    g_HextechRateOfFireX150Modifier = exAttributeModifierCreate({ RATE_OF_FIRE = 1.5 }, 1)
end
if not g_HextechRangeX115Modifier then
    g_HextechRangeX115Modifier = exAttributeModifierCreate({ RANGE = 1.15 }, 1)
end
if not g_HextechRangeX125Modifier then
    g_HextechRangeX125Modifier = exAttributeModifierCreate({ RANGE = 1.25 }, 1)
end
if not g_HextechRangeX150Modifier then
    g_HextechRangeX150Modifier = exAttributeModifierCreate({ RANGE = 1.5 }, 1)
end
if not g_HextechAstralBodyModifier then
    g_HextechAstralBodyModifier = exAttributeModifierCreate({
        HEALTH_MULT = 1.9,
        DAMAGE_MULT = 0.75,
    }, 1)
end
if not g_HextechEnemyRangeX075Modifier then
    g_HextechEnemyRangeX075Modifier = exAttributeModifierCreate({ RANGE = 0.75 }, 1)
end

-- 全频段阻塞干扰只处理战斗单位；神圣干预则同时包含单位和建筑。
HextechRune.AllSideUnitsFilter = HextechRune.AllSideUnitsFilter or CreateObjectFilter({
    Rule = "ANY", Relationship = "SAME_PLAYER",
    Include = "INFANTRY VEHICLE HUGE_VEHICLE AIRCRAFT SHIP",
    Exclude = "STRUCTURE DEBRIS"
})
HextechRune.AllSideUnitsAndStructuresFilter = HextechRune.AllSideUnitsAndStructuresFilter
    or CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER",
        Include = "INFANTRY VEHICLE HUGE_VEHICLE AIRCRAFT SHIP STRUCTURE",
        Exclude = "DEBRIS"
    })
HextechRune.BroadbandJammingApplied = HextechRune.BroadbandJammingApplied or {}
HextechRune.DivineInterventionInterval = 450
-- 基础铁幕 45 帧（3 秒）；同阵营每多一份增加基础时长的一半，22.5 帧向上取 23 帧。
HextechRune.DivineInterventionBaseDuration = 45
HextechRune.DivineInterventionExtraDurationPerCopy = 23
HextechRune.DivineInterventionSchedulerId = HextechRune.DivineInterventionSchedulerId or nil
HextechRune.FiveThunderFirstPower = "SpecialPower_CelestialPantaOrbitalStrike"
HextechRune.FiveThunderRepeatPower = "SpecialPower_CelestialOrbitalStrike0cd"
HextechRune.FiveThunderState = HextechRune.FiveThunderState or {}
HextechRune.FiveThunderMonitorSchedulerId = HextechRune.FiveThunderMonitorSchedulerId or nil
HextechRune.FiveThunderCooldownRounds = 3
HextechRune.TeslaAirAssaultPower = "SpecialPower_SovietTeslaAirAssault"
HextechRune.CombustionInterestMoney = 6
HextechRune.CombustionInterestObserverReady =
    HextechRune.CombustionInterestObserverReady or false
HextechRune.CombustionInterestCombatActive =
    HextechRune.CombustionInterestCombatActive or false
-- 现金奖励同时受玩家科技锁和 SpecialPower 可用性两层控制。
-- 使用日冕协议枚举中的规范 ID，避免只生成按钮但仍因科技锁置灰。
HextechRune.CashRewardSpecialPower = "SpecialPower_ProductionKickbacks"
HextechRune.CashRewardPlayerTech = "PlayerTech_Soviet_ProductionKickbacks"
HextechRune.FortifiedTowerState = HextechRune.FortifiedTowerState or {}
HextechRune.TranscendentEvilModifiers = HextechRune.TranscendentEvilModifiers or {}
HextechRune.FiveTigerGeneralsPower = "SpecialPower_CelestialCenturionUpgrade"
HextechRune.FiveTigerGeneralsCommand = "Command_Celestial_CenturionUpgrade"
HextechRune.BattleUnitEffectDelay = 45
HextechRune.FiveTigerPowerGranted = HextechRune.FiveTigerPowerGranted or {}
HextechRune.CenturionSpellbookFilter = HextechRune.CenturionSpellbookFilter
    or CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER",
        IncludeThing = { "playerspellbook" },
    })
g_HextechFiveTigerPendingTargets = g_HextechFiveTigerPendingTargets or {}

g_HextechRecycleBonus = g_HextechRecycleBonus or { 0, 0, 0, 0, 0, 0 }
g_HextechBuyTwoGetOne = g_HextechBuyTwoGetOne or {}
g_HextechOilDerrickSerial = g_HextechOilDerrickSerial or { 0, 0, 0, 0, 0, 0 }
g_HextechTowerDefenseExpert = g_HextechTowerDefenseExpert or { false, false, false, false, false, false }
g_HextechUltimateRefreshCount = g_HextechUltimateRefreshCount or { 0, 0, 0, 0, 0, 0 }
g_HextechOblivionBombCharges = g_HextechOblivionBombCharges or { 0, 0, 0, 0, 0, 0 }
-- 东风速递符文赠送的东风不占建造额度：拥有符文的玩家保有上限从 1 提高到 2。
-- UnitCreate.lua 的兜底击杀与 RescueBlockedProductions.lua 的建造门槛都读取本表。
g_HextechDF41ExtraQuota = g_HextechDF41ExtraQuota or {}

-- 在现有经济倍率/苏联大生产修正之后叠加玩家自己的破烂王倍率。
if HextechRune_BaseGetRecycleRate == nil and GetRecycleRate ~= nil then
    HextechRune_BaseGetRecycleRate = GetRecycleRate
    function GetRecycleRate(playerIndex)
        local baseRate = HextechRune_BaseGetRecycleRate(playerIndex)
        return baseRate * (1 + (g_HextechRecycleBonus[playerIndex] or 0))
    end
end

-- 奖励符文不再抽到“质变/赌怪”本身，避免奖励链递归展开；其余筛池规则
-- 与正式三选一完全一致（阵营、禁海、兵种版本、不可重复符文）。
function HextechRune:PickBonusRune(playerIndex, rarity)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    local candidates = {}
    for i = 1, getn(pool), 1 do
        local rune = pool[i]
        if rune.Effect ~= "quality_transformation"
            and rune.Effect ~= "gambling_addict" then
            tinsert(candidates, rune)
        end
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

function HextechRune:GrantBonusRune(playerIndex, rarity, sourceName)
    local rune = self:PickBonusRune(playerIndex, rarity)
    if rune == nil or not self:AddOwnedRune(playerIndex, rune) then
        return false
    end
    self:OnRuneChosen(playerIndex, rune)
    exAddTextToPublicBoard(Localization.get("hextech.bonus.broadcast",
        playerIndex, sourceName, self:GetRuneDisplayName(rune)), 10)
    return true
end

function HextechRune:ApplyQualityTransformation(playerIndex, rune)
    self:GrantBonusRune(playerIndex, rune.UpgradeRarity,
        Localization.get("hextech.rune.quality_transformation.name"))
end

function HextechRune:RollGamblingAddictRarity()
    local roll = GetRandomNumber() * 100
    if roll < 5 then
        return 1
    elseif roll < 35 then
        return 2
    end
    return 3
end

function HextechRune:ApplyGamblingAddict(playerIndex)
    for rewardIndex = 1, 2, 1 do
        local rarity = self:RollGamblingAddictRarity()
        self:GrantBonusRune(playerIndex, rarity,
            Localization.get("hextech.rune.gambling_addict.name"))
    end
end

function HextechRune:GetPlayerSideIndex(playerIndex)
    if playerIndex <= 3 then
        return 7
    end
    return 8
end

function HextechRune:GetEnemySideIndex(playerIndex)
    if playerIndex <= 3 then
        return 8
    end
    return 7
end

function HextechRune:GetSidePlayerRange(sideIndex)
    if sideIndex == 7 then
        return 1, 3
    end
    return 4, 6
end

function HextechRune:GetSideOwnedRuneCount(sideIndex, runeId)
    local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
    local count = 0
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        if self.PlayerOwnedRuneIds[playerIndex][runeId] then
            count = count + 1
        end
    end
    return count
end

-- 每个玩家的干扰符文实例独立加载一次；同阵营队友也持有时允许效果叠加。
function HextechRune:ApplyBroadbandJamming(playerIndex, rune, sourceName)
    local enemySideIndex = self:GetEnemySideIndex(playerIndex)
    if P == nil or P[enemySideIndex] == nil then
        return
    end
    local effectInstanceId = "P" .. tostring(playerIndex) .. ":"
        .. self:GetRuneEffectInstanceId(rune)
    if self.BroadbandJammingApplied[effectInstanceId] == nil then
        self.BroadbandJammingApplied[effectInstanceId] = {}
    end
    local applied = self.BroadbandJammingApplied[effectInstanceId]
    local units, count = ObjectFindObjects(P[enemySideIndex], nil, self.AllSideUnitsFilter)
    for i = 1, count, 1 do
        local unit = units[i]
        local objectId = ObjectGetId(unit)
        local previous = applied[objectId]
        if previous == nil or previous ~= unit then
            ObjectLoadAttributeModifier(unit, g_HextechEnemyRangeX075Modifier,
                self.PersistentBuffDuration)
            applied[objectId] = unit
        end
    end
end

function HextechRune:ApplyAllBroadbandJamming(sourceName)
    for playerIndex = 1, 6, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        local owned = self.PlayerOwnedRunes[playerIndex]
        for runeIndex = 1, getn(owned), 1 do
            local rune = owned[runeIndex]
            if rune.Effect == "broadband_jamming" then
                self:ApplyBroadbandJamming(playerIndex, rune, sourceName)
            end
        end
    end
end

function HextechRune:ApplyDivineInterventionToSide(sideIndex, sourceName)
    local ownedCount = self:GetSideOwnedRuneCount(sideIndex,
        "prismatic_divine_intervention")
    if ownedCount <= 0 or P == nil or P[sideIndex] == nil then
        return
    end
    local duration = self.DivineInterventionBaseDuration
        + self.DivineInterventionExtraDurationPerCopy * (ownedCount - 1)
    local objects, count = ObjectFindObjects(P[sideIndex], nil,
        self.AllSideUnitsAndStructuresFilter)
    for i = 1, count, 1 do
        ObjectLoadAttributeModifier(objects[i], "AttributeModifier_IronCurtain", duration)
    end
end

function HextechRune:ApplyDivineInterventionPulse(sourceName)
    self:ApplyDivineInterventionToSide(7, sourceName)
    self:ApplyDivineInterventionToSide(8, sourceName)
end

function HextechRune:EnsureDivineInterventionScheduler()
    if self.DivineInterventionSchedulerId ~= nil then
        return
    end
    self.DivineInterventionSchedulerId = SchedulerModule.call_every_x_frame(function()
        HextechRune:ApplyDivineInterventionPulse("周期触发")
    end, self.DivineInterventionInterval, nil, {})
end

function HextechRune:SetFiveThunderAvailability(playerIndex, availability)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    -- 首发与 0cd 属于同一套原生技能流程，开放和冷却必须同步控制。
    -- 触发检测会检查两段，但命中后也同步禁用两段，避免 0cd 持续运行。
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.FiveThunderFirstPower, availability)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.FiveThunderRepeatPower, availability)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:SetFiveThunderFirstAvailability(playerIndex, availability)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.FiveThunderFirstPower, availability)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:GrantFiveThunderPowers(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.FiveThunderFirstPower, playerName)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.FiveThunderRepeatPower, playerName)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:SetFiveThunderCountdown(playerIndex, seconds)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        self.FiveThunderFirstPower, seconds)
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        self.FiveThunderRepeatPower, seconds)
    SetWorldBuilderThisPlayer(previous)
end


function HextechRune:GrantFiveThunder(playerIndex)
    if self.FiveThunderState[playerIndex] == nil then
        self.FiveThunderState[playerIndex] = {}
    end
    local state = self.FiveThunderState[playerIndex]
    state.Owned = true
    state.Ready = true
    state.ReadyRound = nil
    state.WaitingForTriggerClear = false

    -- 两段都显式授予并同步开放：首发负责玩家选点，0cd 完成原生连发。
    self:GrantFiveThunderPowers(playerIndex)
    self:SetFiveThunderCountdown(playerIndex, 0)
    self:SetFiveThunderAvailability(playerIndex, "Available")
    self:EnsureFiveThunderMonitor()
end

function HextechRune:CheckFiveThunderTriggered()
    for playerIndex = 1, 6, 1 do
        local state = self.FiveThunderState[playerIndex]
        if state ~= nil and state.Owned then
            local playerName = "Player_" .. playerIndex
            local firstTriggered = EvaluateCondition("PLAYER_TRIGGERED_SPECIAL_POWER",
                playerName, self.FiveThunderFirstPower)
            local repeatTriggered = EvaluateCondition("PLAYER_TRIGGERED_SPECIAL_POWER",
                playerName, self.FiveThunderRepeatPower)
            if state.WaitingForTriggerClear then
                -- 只有旧的五雷连发触发态真正结束后才解锁。恢复时不再
                -- Grant，避免重新授予 0cd 又制造一次瞬时触发；同时把两段
                -- 的引擎内部倒计时清零，解决图标亮起但仍无法释放。
                if not firstTriggered and not repeatTriggered then
                    self:SetFiveThunderCountdown(playerIndex, 0)
                    self:SetFiveThunderAvailability(playerIndex, "Available")
                    state.WaitingForTriggerClear = false
                    state.Ready = true
                    state.ReadyRound = nil
                end
            elseif state.Ready and (firstTriggered or repeatTriggered) then
                state.Ready = false
                state.ReadyRound = exCounterGetByName("lvc")
                    + self.FiveThunderCooldownRounds
                -- 首发只负责开启本次原生五连发；检测到输出段后只关闭
                -- 首发入口，保留 0cd 连发段，让引擎完整走完后续四次落雷。
                self:SetFiveThunderFirstAvailability(playerIndex, "Disabled")
            end
        end
    end
end


function HextechRune:EnsureFiveThunderMonitor()
    if self.FiveThunderMonitorSchedulerId ~= nil then
        return
    end
    self.FiveThunderMonitorSchedulerId = SchedulerModule.call_every_x_frame(function()
        HextechRune:CheckFiveThunderTriggered()
    end, 1, nil, {})
end

function HextechRune:OnFiveThunderRoundBegin(round)
    for playerIndex = 1, 6, 1 do
        local state = self.FiveThunderState[playerIndex]
        if state ~= nil and state.Owned and not state.Ready
            and not state.WaitingForTriggerClear and state.ReadyRound ~= nil
            and round >= state.ReadyRound then
            state.WaitingForTriggerClear = true
        end
    end
end

function HextechRune:GrantCashRewardProtocol(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    -- PLAYER_GRANT_SPECIAL_POWER 会授予能力及所需科技等级，但不会
    -- 覆盖 PLAYER_LOCK_PLAYER_TECH 的显式锁。先解锁现金协议科技，
    -- 再授予并开放 SpecialPower，避免图标已出现但仍置灰。
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName,
        self.CashRewardPlayerTech, 0)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.CashRewardSpecialPower, playerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.CashRewardSpecialPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        self.CashRewardSpecialPower, 0)
    SetWorldBuilderThisPlayer(previous)
    -- 技能实例由 PLAYER_GRANT_SPECIAL_POWER 延迟创建；同帧的 Available 可能只
    -- 改到全局禁用记录而没有改到新按钮，因此下一帧再对持有者单独解禁一次。
    SchedulerModule.delay_call(function(index)
        local delayedPlayerName = "Player_" .. index
        local delayedPrevious = SetWorldBuilderThisPlayer(1)
        ExecuteAction("PLAYER_LOCK_PLAYER_TECH", delayedPlayerName,
            HextechRune.CashRewardPlayerTech, 0)
        ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", delayedPlayerName,
            HextechRune.CashRewardSpecialPower, "Available")
        ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", delayedPlayerName,
            HextechRune.CashRewardSpecialPower, 0)
        SetWorldBuilderThisPlayer(delayedPrevious)
    end, 1, {playerIndex})
end

-- 磁暴突袭符文：暂不启用（实测直接赋予该协议会有0cd问题），代码保留待后续开发。
-- 取得符文只做两件事：授予协议、解禁按钮；冷却与释放节奏全部交给原版。
function HextechRune:GrantTeslaAirAssault(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.TeslaAirAssaultPower, playerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.TeslaAirAssaultPower, "Available")
    SetWorldBuilderThisPlayer(previous)
end

-- 死亡事件属于全局入口，使用固定函数转发到当前海克斯对象。
function HextechCombustionInterestUnitDie(dyingObjId, attackerId,
    dyingObjInstanceId, attackerInstanceId, ownerPlayerName)
    if HextechRune ~= nil and HextechRune.OnCombustionInterestUnitDie ~= nil then
        HextechRune:OnCombustionInterestUnitDie(dyingObjId, ownerPlayerName)
    end
end

function HextechRune:EnsureCombustionInterestObserver()
    if self.CombustionInterestObserverReady then
        return
    end
    if RegisterUnitDieCallback == nil or UNITLIST == nil or unitcountmax == nil then
        return
    end
    for unitIndex = 1, unitcountmax, 1 do
        RegisterUnitDieCallback(UNITLIST[unitIndex],
            HextechCombustionInterestUnitDie)
    end

    -- 回合结算后的脚本清场不算单位死亡；下一回合开始后重新接受死亡事件。
    self.CombustionInterestCombatActive = true
    if RoundLuaManager ~= nil then
        RoundLuaManager.CallOnEveryRoundBegin(function()
            HextechRune.CombustionInterestCombatActive = true
        end)
        RoundLuaManager.CallOnEveryRoundEnd(function()
            HextechRune.CombustionInterestCombatActive = false
        end)
    end
    self.CombustionInterestObserverReady = true
end

function HextechRune:OnCombustionInterestUnitDie(dyingObjId, ownerPlayerName)
    -- BUFF 登记只用于防止同一单位重复获得持续效果；
    -- 炽燃利息直接根据战场 AI 归属和战斗阶段结算，不再要求死亡单位已获得 BUFF。
    self.BattleUnitAssignments[dyingObjId] = nil
    if not self.CombustionInterestCombatActive then
        return
    end

    local firstPlayerIndex = nil
    local lastPlayerIndex = nil
    if ownerPlayerName == "PlyrCivilian" then
        firstPlayerIndex = 4
        lastPlayerIndex = 6
    elseif ownerPlayerName == "PlyrCreeps" then
        firstPlayerIndex = 1
        lastPlayerIndex = 3
    else
        return
    end

    local rewarded = false
    local previous = SetWorldBuilderThisPlayer(1)
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        if self.PlayerOwnedRuneIds[playerIndex]["gold_combustion_interest"] then
            ExecuteAction("PLAYER_GIVE_MONEY", "Player_" .. playerIndex,
                self.CombustionInterestMoney)
            rewarded = true
        end
    end
    SetWorldBuilderThisPlayer(previous)
    if rewarded then
        -- 多名队友各自获得 6，但死亡位置只显示一次与小电厂同款的 +6。
        exShowFloatingIntAtObject(dyingObjId, self.CombustionInterestMoney)
    end
end

function HextechRune:GetPlayerHomeSpawnPosition(playerIndex, forwardOffset, sideOffset)
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = 1
    if PureDrawGetQuotaDisplayDirection ~= nil then
        direction = PureDrawGetQuotaDisplayDirection(playerIndex)
    end
    return {
        X = p[1] + direction * forwardOffset,
        Y = p[2] + sideOffset,
        Z = p[3],
    }
end

function HextechRune:MarkNextSpawnAsKnownPureDrawUnit()
    local nextObjectId = GetNextObjectId()
    if g_PureDrawScriptCreatedUnitIds ~= nil then
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
    end
    return nextObjectId
end

function HextechRune:GrantYaoguang(playerIndex)
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "CelestialAdvanceAircraftTech4",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 80), 0)
end

function HextechRune:GrantOlympusCarrier(playerIndex)
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "AlliedGaintAirCraftCarrier_B",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, -80), 0)
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "JapanYumiAircraftCarrier",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 80), 0)
end

-- 落点与灯火辉煌正好相反：取敌方最前排防御塔，炸在塔前方（我方这一侧）200 处。
function HextechRune:GrantOblivionBomb(playerIndex)
    local forwardDirection = 1
    local enemyTowerPos = { X = 4030, Y = 3102.5, Z = 210 }
    if playerIndex >= 4 then
        forwardDirection = -1
        enemyTowerPos = { X = 3000, Y = 3102.5, Z = 210 }
    end
    local enemyIndex = playerIndex + 3
    if enemyIndex > 6 then
        enemyIndex = playerIndex - 3
    end
    local enemyFrontTower = BtnChoiceDialogEventFunc_GetFrontDefenseTower(enemyIndex)
    if ObjectIsAlive(enemyFrontTower) then
        local towerX, towerY, towerZ = ObjectGetPosition(enemyFrontTower)
        enemyTowerPos = { X = towerX, Y = towerY, Z = towerZ }
    end
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "japanomegaoblivionbomb",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        {
            X = enemyTowerPos.X - forwardDirection * 200,
            Y = enemyTowerPos.Y,
            Z = enemyTowerPos.Z,
        }, 0)
end

function HextechRune:AddOblivionBombCharge(playerIndex)
    g_HextechOblivionBombCharges[playerIndex] =
        (g_HextechOblivionBombCharges[playerIndex] or 0) + 1
    if self.RefreshOblivionBombHint ~= nil then
        self:RefreshOblivionBombHint(playerIndex)
    end
end

function HextechRune:DeployOblivionBomb(playerIndex)
    local charges = g_HextechOblivionBombCharges[playerIndex] or 0
    if charges <= 0 then
        return false
    end
    g_HextechOblivionBombCharges[playerIndex] = charges - 1
    self:GrantOblivionBomb(playerIndex)
    if self.RefreshOblivionBombHint ~= nil then
        self:RefreshOblivionBombHint(playerIndex)
    end
    return true
end

function HextechRune:HandleOblivionBombHotKey(playerName)
    for playerIndex = 1, 6, 1 do
        if playerName == "Player_" .. playerIndex then
            return self:DeployOblivionBomb(playerIndex)
        end
    end
    return false
end

function HextechRune:GrantGigaFortress(playerIndex)
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "JapanGigaFortressShipEgg",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 0), 0)
    -- UnitCreate.lua 已为该核心注册 UnitCountFunc：8 帧后计数并删除实体。
end

-- 东风速递：赠送的东风不占建造额度，因此先记额度再生成，玩家仍可自产一辆。
function HextechRune:GrantDongfengExpress(playerIndex)
    g_HextechDF41ExtraQuota[playerIndex] = true
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "CelestialDF41",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 0), 0)
end

function HextechRune:GrantSafetyAegisTowers(playerIndex)
    local playerOwn = "PlyrCivilian"
    local behindDirection = -1
    local towerPos = { X = 2900, Y = 3102.5, Z = 210 }
    if playerIndex >= 4 then
        playerOwn = "PlyrCreeps"
        behindDirection = 1
        towerPos = { X = 4150, Y = 3102.5, Z = 210 }
    end
    local frontTower = BtnChoiceDialogEventFunc_GetFrontDefenseTower(playerIndex)
    if ObjectIsAlive(frontTower) then
        local towerX, towerY, towerZ = ObjectGetPosition(frontTower)
        towerPos = {
            X = towerX + behindDirection * 126.75,
            Y = towerY,
            Z = towerZ,
        }
    end
    -- 复用交易市场埃奎斯的左右布局，但不写入 g_BuyTowerId：
    -- 符文塔允许重复生成，也不占用市场的两个常规购买名额。
    for i = 1, 2, 1 do
        local lateralDirection = 1
        if i == 2 then
            lateralDirection = -1
        end
        exCreateObject({
            ObjectType = FastHash("AlliedAegisLargeDefenseBase"),
            TeamName = playerOwn .. "/team" .. playerOwn,
            Position = {
                X = towerPos.X,
                Y = towerPos.Y + lateralDirection * 126.75,
                Z = towerPos.Z,
            },
            Angle = 0,
            Health = 9000,
        })
    end
end

function HextechRune:GrantBrilliantLights(playerIndex)
    local forwardDirection = 1
    local towerPos = { X = 3000, Y = 3102.5, Z = 210 }
    if playerIndex >= 4 then
        forwardDirection = -1
        towerPos = { X = 4030, Y = 3102.5, Z = 210 }
    end
    local frontTower = BtnChoiceDialogEventFunc_GetFrontDefenseTower(playerIndex)
    if ObjectIsAlive(frontTower) then
        local towerX, towerY, towerZ = ObjectGetPosition(frontTower)
        towerPos = {
            X = towerX + forwardDirection * 200,
            Y = towerY,
            Z = towerZ,
        }
    end
    local teamName = format("Player_%d/teamPlayer_%d", playerIndex, playerIndex)
    for i = 1, 2, 1 do
        local sideOffset = -100
        if i == 2 then
            sideOffset = 100
        end
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
            "CelestialEngineerRepairDroneLv2", teamName,
            { X = towerPos.X, Y = towerPos.Y + sideOffset, Z = towerPos.Z }, 0)
    end
end

function HextechRune:ApplyUltimateRefreshToButtons(playerIndex, buttons)
    local copyCount = g_HextechUltimateRefreshCount[playerIndex] or 0
    if copyCount <= 0 or buttons == nil then
        return 0
    end
    local applied = 0
    for buttonIndex = 1, 2, 1 do
        local button = buttons[buttonIndex]
        if button ~= nil and button.MaxUseCount ~= nil then
            local previousApplied = button._hextechUltimateRefreshAppliedCount or 0
            local addCount = copyCount - previousApplied
            if addCount > 0 then
                button.MaxUseCount = button.MaxUseCount + addCount
                button._hextechUltimateRefreshAppliedCount = copyCount
                if not button.IsLocked and (button._cooldownCount or 0) <= 0
                    and (button._usedCount or 0) < button.MaxUseCount then
                    button.IsEnabled = true
                end
                button:FormatText()
                applied = applied + 1
            end
        end
    end
    return applied
end

function HextechRune:GrantUltimateRefresh(playerIndex)
    g_HextechUltimateRefreshCount[playerIndex]
        = (g_HextechUltimateRefreshCount[playerIndex] or 0) + 1
    local playerName = "Player_" .. playerIndex
    local buttons = {
        ButtonManager:GetButton(playerName, 1),
        ButtonManager:GetButton(playerName, 2),
    }
    self:ApplyUltimateRefreshToButtons(playerIndex, buttons)
    for i = 1, 2, 1 do
        if buttons[i] ~= nil then
            ButtonManager:SetButton(buttons[i])
        end
    end
end

function HextechRune:EnableTowerDefenseExpert(playerIndex)
    g_HextechTowerDefenseExpert[playerIndex] = true
end

function HextechRune:GrantOilDerricks(playerIndex)
    local teamName = format("Player_%d/teamPlayer_%d", playerIndex, playerIndex)
    g_HextechOilDerrickSerial[playerIndex] = g_HextechOilDerrickSerial[playerIndex] + 1
    local serial = g_HextechOilDerrickSerial[playerIndex]
    for i = 1, 2, 1 do
        local sideOffset = -170
        if i == 2 then
            sideOffset = 170
        end
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
            format("HextechOilDerrick_%d_%d_%d", playerIndex, serial, i),
            "oilderrick", teamName,
            self:GetPlayerHomeSpawnPosition(playerIndex, 180, sideOffset), 0)
    end
end

function HextechRune:GrantStartingFunds(playerIndex)
    local playerName = "Player_" .. playerIndex
    -- 主动回收和青龙船自动回收都在 WorldBuilder 玩家上下文中执行加钱。
    -- 海克斯按钮回调没有这个上下文，必须显式切换后再恢复。
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GIVE_MONEY", playerName, 15000)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:GrantForeignMCV(playerIndex)
    local ownFaction = 1
    if g_PlayerSide ~= nil and g_PlayerSide[playerIndex] ~= nil then
        ownFaction = g_PlayerSide[playerIndex]
    end
    local mcvTypes = {
        [1] = "AlliedMCV",
        [2] = "SovietMCV",
        [3] = "JapanMCV",
        [4] = "CelestialMCV",
    }
    local candidates = {}
    for faction = 1, 4, 1 do
        if faction ~= ownFaction then
            tinsert(candidates, faction)
        end
    end
    local targetFaction = candidates[self:RandomIndex(getn(candidates))]
    local playerName = "Player_" .. playerIndex
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        mcvTypes[targetFaction], playerName .. "/teamPlayer_" .. playerIndex,
        self:GetPlayerHomeSpawnPosition(playerIndex, 140, 0), 0)
end

function HextechRune:EnableBuyTwoGetOne(playerIndex, rune)
    if g_HextechBuyTwoGetOne[playerIndex] == nil then
        g_HextechBuyTwoGetOne[playerIndex] = {}
    end
    tinsert(g_HextechBuyTwoGetOne[playerIndex], {
        UnitIndex = rune.TargetUnitIndex,
        UnitType = rune.TargetUnitType,
        UnitName = rune.TargetUnitName,
        Progress = 0,
        RuneInstanceId = self:GetRuneEffectInstanceId(rune),
    })
end

-- 在 unitgetcountanddelet 的真实单位回收计数后调用，参考狂热武士“每二赠一”。
function HextechRune:OnPlayerUnitCollected(playerIndex, unitIndex)
    local states = g_HextechBuyTwoGetOne[playerIndex]
    if states == nil then
        return
    end
    for i = 1, getn(states), 1 do
        local state = states[i]
        if state.UnitIndex == unitIndex then
            state.Progress = state.Progress + 1
            if state.Progress >= 2 then
                state.Progress = 0
                ANYUNITCOUNT[playerIndex] = ANYUNITCOUNT[playerIndex] + 1
                UNITCOUNT[playerIndex][unitIndex] = UNITCOUNT[playerIndex][unitIndex] + 1
            end
        end
    end
end

function HextechRune:GetAvailableUnitTypes(playerIndex)
    -- 每个兵种版本都是独立符文，即使玩家当前尚未生产该兵种也可选择，
    -- 让效果覆盖之后生产/刷新的单位。禁海配置下仅排除海军版本。
    local result = { "infantry", "vehicle", "aircraft" }
    if g_DisableSeaArmy ~= 1 then
        tinsert(result, "navy")
    end
    return result
end

-- 构建阵营战斗单位的兵种查找表。战斗复制体属于 P7/P8，不能再按 Player_1..6 所有权扫描。
function HextechRune:BuildSideUnitTypeLookup(sideIndex)
    local result = {}
    if P == nil or P[sideIndex] == nil then
        return result
    end
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local units, count = ObjectFindObjects(P[sideIndex], nil, self.UnitTypeFilters[unitType])
        local lookup = {}
        for i = 1, count, 1 do
            lookup[ObjectGetId(units[i])] = true
        end
        result[unitType] = lookup
    end
    -- 把指定双形态单位补入两张兵种查找表；同一个 objectId 可以同时存在于
    -- 两个表中，因此会分别响应玩家持有的两类兵种符文。
    for dualIndex = 1, getn(self.DualUnitTypeFilters), 1 do
        local dual = self.DualUnitTypeFilters[dualIndex]
        local units, count = ObjectFindObjects(P[sideIndex], nil, dual.Filter)
        for i = 1, count, 1 do
            local objectId = ObjectGetId(units[i])
            for typeIndex = 1, getn(dual.Types), 1 do
                result[dual.Types[typeIndex]][objectId] = true
            end
        end
    end
    return result
end

-- 在单位池正式计数前替换回收目标。抽卡单位的获得播报同样读取替换后的槽位，
-- 因而会直接显示升级单位，而不是先加入原单位再做二次转换。
function HextechRune:ResolveCollectedUnitIndex(playerIndex, unitIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local sourceType = UNITLIST[unitIndex]
    local replacementType = nil
    if sourceType == "JapanAntiNavyShipTech3"
        and self.PlayerOwnedRuneIds[playerIndex]["silver_export_domestic"] then
        replacementType = "CelestialSeized_JapanAntiNavyShipTech3"
    elseif sourceType == "SovietAntiAirShip"
        and self.PlayerOwnedRuneIds[playerIndex]["silver_dual_purpose"] then
        replacementType = "VUAntiAirVehicleTech1"
    elseif sourceType == "AlliedGunshipAircraft"
        and self.PlayerOwnedRuneIds[playerIndex]["silver_advanced_artillery"] then
        replacementType = "AlliedAC130GunshipAircraft"
    end
    if replacementType == nil or g_UnitNameToUnitIndex == nil then
        return unitIndex
    end
    return g_UnitNameToUnitIndex[replacementType] or unitIndex
end

function HextechRune:IsUnitInRuneType(unit, rune, typeLookup)
    if rune.UnitType == nil or typeLookup[rune.UnitType] == nil then
        return false
    end
    return typeLookup[rune.UnitType][ObjectGetId(unit)] == true
end

function HextechRune:ApplyInfiniteAmmoToUnit(unit)
    -- 与空军元帅苏霍伊脚本相同：武器槽 1~5 写入 100000 弹药。
    for weaponIndex = 1, 5, 1 do
        ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(unit, 1, 1, weaponIndex, 100000)
    end
end

-- 给一只已经按单位池配额分配到玩家的战斗单位加载一个持续型符文。
-- 返回 true 表示兵种匹配且本次确实执行了效果。
function HextechRune:ApplyPersistentRuneToUnit(playerIndex, rune, unit, typeLookup)
    if not self:IsUnitInRuneType(unit, rune, typeLookup) then
        return false
    end
    if rune.Effect == "damage" then
        ObjectLoadAttributeModifier(unit, g_HextechDamageX150Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "rate_of_fire" then
        ObjectLoadAttributeModifier(unit, g_HextechRateOfFireX150Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "speed" then
        ObjectLoadAttributeModifier(unit, g_HextechSpeedX140Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "range_silver" then
        ObjectLoadAttributeModifier(unit, g_HextechRangeX115Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "range_gold" then
        ObjectLoadAttributeModifier(unit, g_HextechRangeX125Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "range_prismatic" then
        ObjectLoadAttributeModifier(unit, g_HextechRangeX150Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "astral_body" then
        ObjectLoadAttributeModifier(unit, g_HextechAstralBodyModifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "transcendent_evil" then
        -- 同兵种多份按回合数直接相加，只加载一个合并后的 Modifier。
        if not self:IsPrimaryTranscendentEvilRune(playerIndex, rune) then
            return false
        end
        ObjectLoadAttributeModifier(unit,
            self:GetTranscendentEvilModifier(playerIndex, rune),
            self.PersistentBuffDuration)
    elseif rune.Effect == "infinite_ammo" then
        local eligible = typeLookup.infiniteAmmoAircraft
        if eligible == nil or not eligible[ObjectGetId(unit)] then
            return false
        end
        self:ApplyInfiniteAmmoToUnit(unit)
    else
        return false
    end
    return true
end

function HextechRune:IsCurrentAssignment(unit, assignment)
    if assignment == nil or not ObjectIsAlive(unit)
        or assignment.Unit == nil or not ObjectIsAlive(assignment.Unit) then
        return false
    end
    local objectId = ObjectGetId(unit)
    local assignedObjectId = assignment.ObjectId
        or ObjectGetId(assignment.Unit)
    return assignedObjectId == objectId
end

function HextechRune:IsPersistentBattleRune(rune)
    return rune.Effect == "damage" or rune.Effect == "rate_of_fire"
        or rune.Effect == "speed" or rune.Effect == "range_silver"
        or rune.Effect == "range_gold" or rune.Effect == "range_prismatic"
        or rune.Effect == "astral_body" or rune.Effect == "transcendent_evil"
        or rune.Effect == "infinite_ammo"
end

-- 只有该玩家真正有效果可施加到这只单位时，才占用其单位池配额。
-- 普通持续 BUFF 使用全配额；究极生物每回合 1 只，五虎上将单独按份数限制名额。
function HextechRune:GetPlayerBattleEffectQuota(playerIndex, unit, unitIndex,
    typeLookup)
    local poolCount = UNITCOUNT[playerIndex][unitIndex] or 0
    if poolCount <= 0 then
        return 0
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for runeIndex = 1, getn(owned), 1 do
        local rune = owned[runeIndex]
        if self:IsPersistentBattleRune(rune)
            and self:IsUnitInRuneType(unit, rune, typeLookup) then
            if rune.Effect ~= "infinite_ammo"
                or (typeLookup.infiniteAmmoAircraft ~= nil
                    and typeLookup.infiniteAmmoAircraft[ObjectGetId(unit)]) then
                return poolCount
            end
        end
    end

    local oniIndex = g_UnitNameToUnitIndex["JapanMechaX"]
    if self.UltimateCreatureStates ~= nil
        and self.UltimateCreatureStates[playerIndex] ~= nil
        and unitIndex == oniIndex then
        return 1
    end

    local fiveTigerCount = self:GetFiveTigerGeneralsCopyCount(playerIndex)
    if fiveTigerCount > 0 and typeLookup.infantry[ObjectGetId(unit)] then
        local fiveTigerQuota = 5 * fiveTigerCount
        if fiveTigerQuota < poolCount then
            return fiveTigerQuota
        end
        return poolCount
    end
    return 0
end

-- 对一个阵营仅收集尚无 BUFF 登记的同类单位。按玩家单位池数量取至多 COUNT 个，
-- 只有该玩家确实有可施加效果时才占用单位；无效果的玩家和额外单位不登记。
function HextechRune:AssignNewSideBattleUnits(sideIndex, firstPlayerIndex,
    lastPlayerIndex, typeLookup)
    local newlyAssigned = {}
    if P == nil or P[sideIndex] == nil then
        return newlyAssigned
    end
    for unitIndex = 1, unitcountmax, 1 do
        local units, count = ObjectFindObjects(P[sideIndex], nil, FilterLIST[unitIndex])
        local newUnits = {}
        for i = 1, count, 1 do
            local unit = units[i]
            local objectId = ObjectGetId(unit)
            local assignment = self.BattleUnitAssignments[objectId]
            if not self:IsCurrentAssignment(unit, assignment) then
                tinsert(newUnits, unit)
            end
        end

        local claimed = {}
        for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
            local grantedCount = 0
            for unitPosition = 1, getn(newUnits), 1 do
                if not claimed[unitPosition] then
                    local unit = newUnits[unitPosition]
                    local quota = self:GetPlayerBattleEffectQuota(playerIndex,
                        unit, unitIndex, typeLookup)
                    if quota > grantedCount then
                        local assignment = {
                            Unit = unit,
                            ObjectId = ObjectGetId(unit),
                            UnitIndex = unitIndex,
                            PlayerIndex = playerIndex,
                            AppliedRunes = {},
                        }
                        self.BattleUnitAssignments[ObjectGetId(unit)] = assignment
                        claimed[unitPosition] = true
                        grantedCount = grantedCount + 1
                        tinsert(newlyAssigned, assignment)
                    end
                end
            end
        end
    end
    return newlyAssigned
end

function HextechRune:AssignNewBattleUnits(typeLookup)
    local result = {}
    if UNITCOUNT == nil or FilterLIST == nil or unitcountmax == nil then
        return result
    end
    typeLookup = typeLookup or self:BuildAllBattleUnitTypeLookup()
    local left = self:AssignNewSideBattleUnits(7, 1, 3, typeLookup)
    local right = self:AssignNewSideBattleUnits(8, 4, 6, typeLookup)
    for i = 1, getn(left), 1 do
        tinsert(result, left[i])
    end
    for i = 1, getn(right), 1 do
        tinsert(result, right[i])
    end
    return result
end

function HextechRune:BuildAllBattleUnitTypeLookup()
    local left = self:BuildSideUnitTypeLookup(7)
    local right = self:BuildSideUnitTypeLookup(8)
    local result = {}
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local lookup = {}
        if left[unitType] ~= nil then
            for objectId, value in left[unitType] do
                lookup[objectId] = value
            end
        end
        if right[unitType] ~= nil then
            for objectId, value in right[unitType] do
                lookup[objectId] = value
            end
        end
        result[unitType] = lookup
    end
    local infiniteAmmoAircraft = {}
    for sideIndex = 7, 8, 1 do
        if P ~= nil and P[sideIndex] ~= nil then
            local units, count = ObjectFindObjects(P[sideIndex], nil,
                self.InfiniteAmmoAircraftFilter)
            for i = 1, count, 1 do
                infiniteAmmoAircraft[ObjectGetId(units[i])] = true
            end
        end
    end
    result.infiniteAmmoAircraft = infiniteAmmoAircraft
    return result
end

-- AppliedRunes 是“单位 + 独立符文”级标记，阻止幸存单位跨回合重复叠加 Buff。
function HextechRune:ApplyRuneToAssignment(rune, assignment, typeLookup)
    local effectInstanceId = self:GetRuneEffectInstanceId(rune)
    if assignment.AppliedRunes[effectInstanceId] then
        return false
    end
    if self:ApplyPersistentRuneToUnit(assignment.PlayerIndex, rune, assignment.Unit, typeLookup) then
        assignment.AppliedRunes[effectInstanceId] = true
        return true
    end
    return false
end

-- 给本次刚登记的新单位应用其归属玩家的全部持续符文。
function HextechRune:ApplyOwnedRunesToNewAssignments(assignments, sourceName,
    excludedPlayerIndex, excludedOwnershipId, typeLookup)
    typeLookup = typeLookup or self:BuildAllBattleUnitTypeLookup()
    for playerIndex = 1, 6, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        local owned = self.PlayerOwnedRunes[playerIndex]
        for runeIndex = 1, getn(owned), 1 do
            local rune = owned[runeIndex]
            local isExcluded = playerIndex == excludedPlayerIndex
                and self:GetRuneEffectInstanceId(rune) == excludedOwnershipId
            if not isExcluded and rune.Effect ~= "starting_funds" and rune.Effect ~= "fortified"
                and rune.Effect ~= "recycler" and rune.Effect ~= "broadband_jamming"
                and rune.Effect ~= "divine_intervention" and rune.Effect ~= "grant_foreign_mcv"
                and rune.Effect ~= "grant_yaoguang" and rune.Effect ~= "oil_king"
                and rune.Effect ~= "buy_two_get_one" and rune.Effect ~= "five_thunder"
                and rune.Effect ~= "combustion_interest"
                and rune.Effect ~= "tesla_air_assault"
                and rune.Effect ~= "grant_olympus_carrier"
                and rune.Effect ~= "grant_oblivion_bomb"
                and rune.Effect ~= "grant_giga_fortress"
                and rune.Effect ~= "grant_dongfeng_express"
                and rune.Effect ~= "safety"
                and rune.Effect ~= "tower_defense_expert"
                and rune.Effect ~= "cash_reward"
                and rune.Effect ~= "brilliant_lights"
                and rune.Effect ~= "ultimate_refresh"
                and rune.Effect ~= "quality_transformation"
                and rune.Effect ~= "gambling_addict"
                and rune.Effect ~= "upgrade_tachi_cruiser"
                and rune.Effect ~= "upgrade_bullfrog"
                and rune.Effect ~= "upgrade_vanguard_gunship"
                and rune.Effect ~= "ultimate_creature" then
                for i = 1, getn(assignments), 1 do
                    local assignment = assignments[i]
                    if assignment.PlayerIndex == playerIndex then
                        self:ApplyRuneToAssignment(rune, assignment, typeLookup)
                    end
                end
            end
        end
    end
end

function HextechRune:ApplyFortifiedToTowerLine(playerIndex, towerNames, lineName)
    for i = 1, getn(towerNames), 1 do
        local tower = GetObjectByScriptName(towerNames[i])
        if ObjectIsAlive(tower) then
            local maxHealth = exObjectGetMaxHealth(ObjectGetId(tower))
            local towerState = self.FortifiedTowerState[towerNames[i]]
            if towerState == nil then
                towerState = {
                    BaseMaxHealth = maxHealth,
                    CopyCount = 0,
                }
                self.FortifiedTowerState[towerNames[i]] = towerState
            end
            towerState.CopyCount = towerState.CopyCount + 1
            -- 队友各自持有一份时按基础生命直接相加：1/2/3份 = +25%/+50%/+75%，
            -- 不以已经强化过的生命继续乘算。
            local newMaxHealth = towerState.BaseMaxHealth
                * (1 + 0.25 * towerState.CopyCount)
            ExecuteAction("NAMED_SET_MAX_HEALTH", towerNames[i], newMaxHealth, 1)
            return true
        end
    end
    return false
end

function HextechRune:ApplyFortified(playerIndex)
    local landTowerNames = { "T71", "T72", "T73", "T74" }
    local seaTowerNames = { "T71F", "T72F", "T73F" }
    if playerIndex >= 4 then
        landTowerNames = { "T81", "T82", "T83", "T84" }
        seaTowerNames = { "T81F", "T82F", "T83F" }
    end
    -- 不判断禁海配置：选择符文时，陆地和海上两条防线各强化最前端存活塔。
    self:ApplyFortifiedToTowerLine(playerIndex, landTowerNames, "陆地")
    self:ApplyFortifiedToTowerLine(playerIndex, seaTowerNames, "海上")
end

function HextechRune:ApplyPersistentRune(playerIndex, rune)
    -- 持续型符文由回合延迟扫描统一处理。选择时不再提前登记场上单位，
    -- 避免部分出兵尚未生成时占用后续 COUNT 配额。
end

function HextechRune:GetFiveTigerGeneralsCopyCount(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local count = 0
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        if owned[i].Effect == "five_tiger_generals" then
            count = count + 1
        end
    end
    return count
end

function HextechRune:EnsureFiveTigerGeneralsPower(playerIndex)
    local sideIndex = self:GetPlayerSideIndex(playerIndex)
    if self.FiveTigerPowerGranted[sideIndex] then
        return
    end
    local sidePlayerName = "PlyrCivilian"
    if sideIndex == 8 then
        sidePlayerName = "PlyrCreeps"
    end
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.FiveTigerGeneralsPower,
        sidePlayerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", sidePlayerName,
        self.FiveTigerGeneralsPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", sidePlayerName,
        self.FiveTigerGeneralsPower, 0)
    SetWorldBuilderThisPlayer(previous)
    self.FiveTigerPowerGranted[sideIndex] = true
end

function HextechRune:HasCenturionUpgradeObject(unit)
    local attachers, count = ObjectGetAttachers(unit)
    for i = 1, count, 1 do
        if ObjectIsAlive(attachers[i])
            and ObjectTemplateName(attachers[i]) == "CelestialCenturionUpgradeObject" then
            return true
        end
    end
    return false
end

function HextechRune:ShuffleAssignments(assignments)
    for i = getn(assignments), 2, -1 do
        local j = self:RandomIndex(i)
        local temporary = assignments[i]
        assignments[i] = assignments[j]
        assignments[j] = temporary
    end
end

-- 固定出兵完成 3 秒后，从每名持有者本回合的新步兵中随机选择至多 5 个。
-- 通过 AI 魔导书调用原生协议，以保留百夫长的附着物、模型标记和光环表现。
function HextechRune:ApplyFiveTigerGenerals(assignments)
    local typeLookup = self:BuildAllBattleUnitTypeLookup()
    for playerIndex = 1, 6, 1 do
        local copyCount = self:GetFiveTigerGeneralsCopyCount(playerIndex)
        if copyCount > 0 then
            local eligible = {}
            for i = 1, getn(assignments), 1 do
                local assignment = assignments[i]
                local unit = assignment.Unit
                local objectId = ObjectGetId(unit)
                if assignment.PlayerIndex == playerIndex
                    and not assignment.FiveTigerGranted
                    and self:IsCurrentAssignment(unit, assignment)
                    and typeLookup.infantry[objectId]
                    and not self:HasCenturionUpgradeObject(unit) then
                    tinsert(eligible, assignment)
                end
            end
            if getn(eligible) > 0 then
                self:ShuffleAssignments(eligible)
                self:EnsureFiveTigerGeneralsPower(playerIndex)
                local spellbooks, spellbookCount = ObjectFindObjects(
                    eligible[1].Unit, nil, self.CenturionSpellbookFilter)
                if spellbookCount > 0 and ObjectIsAlive(spellbooks[1]) then
                    local spellbookReference = "HextechFiveTigerSpellbook_"
                        .. tostring(playerIndex)
                    ExecuteAction("SET_UNIT_REFERENCE", spellbookReference,
                        spellbooks[1])
                    local grantCount = 5 * copyCount
                    if grantCount > getn(eligible) then
                        grantCount = getn(eligible)
                    end
                    for i = 1, grantCount, 1 do
                        local assignment = eligible[i]
                        local unit = assignment.Unit
                        local objectId = ObjectGetId(unit)
                        local targetReference = "HextechFiveTigerTarget_"
                            .. tostring(objectId)
                        assignment.FiveTigerGranted = true
                        g_HextechFiveTigerPendingTargets[objectId] = true
                        ExecuteAction("SET_UNIT_REFERENCE", targetReference, unit)
                        ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY_ON_NAMED",
                            spellbookReference, self.FiveTigerGeneralsCommand,
                            targetReference)
                    end
                end
            end
        end
    end
end

function HextechRune:GetTranscendentEvilCopyCount(playerIndex, unitType)
    self:EnsurePlayerRuneState(playerIndex)
    local count = 0
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local current = owned[i]
        if current.Effect == "transcendent_evil" and current.UnitType == unitType then
            count = count + 1
        end
    end
    return count
end

function HextechRune:IsPrimaryTranscendentEvilRune(playerIndex, rune)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local current = owned[i]
        if current.Effect == "transcendent_evil" and current.UnitType == rune.UnitType then
            return current == rune
        end
    end
    return false
end

function HextechRune:GetTranscendentEvilModifier(playerIndex, rune)
    local round = tonumber(exCounterGetByName("lvc")) or 0
    local copyCount = self:GetTranscendentEvilCopyCount(playerIndex, rune.UnitType)
    local bonus = round * 0.03 * copyCount
    local cacheKey = tostring(round) .. ":" .. tostring(copyCount)
    if self.TranscendentEvilModifiers[cacheKey] == nil then
        self.TranscendentEvilModifiers[cacheKey] = exAttributeModifierCreate({
            HEALTH_MULT = 1 + bonus,
            DAMAGE_MULT = 1 + bonus,
        }, 1)
    end
    return self.TranscendentEvilModifiers[cacheKey]
end

function HextechRune:OnRuneChosen(playerIndex, rune)
    if rune.Effect == "grant_yaoguang" then
        self:GrantYaoguang(playerIndex)
    elseif rune.Effect == "grant_olympus_carrier" then
        self:GrantOlympusCarrier(playerIndex)
    elseif rune.Effect == "grant_oblivion_bomb" then
        self:AddOblivionBombCharge(playerIndex)
    elseif rune.Effect == "grant_giga_fortress" then
        self:GrantGigaFortress(playerIndex)
    elseif rune.Effect == "grant_dongfeng_express" then
        self:GrantDongfengExpress(playerIndex)
    elseif rune.Effect == "safety" then
        self:GrantSafetyAegisTowers(playerIndex)
    elseif rune.Effect == "tower_defense_expert" then
        self:EnableTowerDefenseExpert(playerIndex)
    elseif rune.Effect == "brilliant_lights" then
        self:GrantBrilliantLights(playerIndex)
    elseif rune.Effect == "ultimate_refresh" then
        self:GrantUltimateRefresh(playerIndex)
    elseif rune.Effect == "quality_transformation" then
        self:ApplyQualityTransformation(playerIndex, rune)
    elseif rune.Effect == "gambling_addict" then
        self:ApplyGamblingAddict(playerIndex)
    elseif rune.Effect == "ultimate_creature" then
        self:CreateUltimateCreature(playerIndex)
    elseif rune.Effect == "grant_foreign_mcv" then
        self:GrantForeignMCV(playerIndex)
    elseif rune.Effect == "oil_king" then
        self:GrantOilDerricks(playerIndex)
    elseif rune.Effect == "buy_two_get_one" then
        self:EnableBuyTwoGetOne(playerIndex, rune)
    elseif rune.Effect == "starting_funds" then
        self:GrantStartingFunds(playerIndex)
    elseif rune.Effect == "fortified" then
        self:ApplyFortified(playerIndex)
    elseif rune.Effect == "recycler" then
        g_HextechRecycleBonus[playerIndex] = (g_HextechRecycleBonus[playerIndex] or 0) + 0.2
    elseif rune.Effect == "broadband_jamming" then
        self:ApplyBroadbandJamming(playerIndex, rune, "选择符文")
    elseif rune.Effect == "divine_intervention" then
        self:EnsureDivineInterventionScheduler()
        self:ApplyDivineInterventionToSide(self:GetPlayerSideIndex(playerIndex), "选择符文")
    elseif rune.Effect == "five_thunder" then
        self:GrantFiveThunder(playerIndex)
    elseif rune.Effect == "combustion_interest" then
        self:EnsureCombustionInterestObserver()
    elseif rune.Effect == "tesla_air_assault" then
        self:GrantTeslaAirAssault(playerIndex)
    elseif rune.Effect == "five_tiger_generals" then
        self:EnsureFiveTigerGeneralsPower(playerIndex)
    elseif rune.Effect == "cash_reward" then
        self:GrantCashRewardProtocol(playerIndex)
    elseif rune.Effect == "upgrade_tachi_cruiser"
        or rune.Effect == "upgrade_bullfrog"
        or rune.Effect == "upgrade_vanguard_gunship" then
        -- 被动回收替换由 unitgetcountanddelet 在每次单位入池时查询持有状态。
    else
        self:ApplyPersistentRune(playerIndex, rune)
    end
end

-- 固定出兵和“补充军队”共用入口：只登记并处理本次新增单位。
function HextechRune:ApplyNewBattleUnitEffects(sourceName)
    local typeLookup = self:BuildAllBattleUnitTypeLookup()
    local assignments = self:AssignNewBattleUnits(typeLookup)
    self:ApplyOwnedRunesToNewAssignments(assignments, sourceName or "出兵",
        nil, nil, typeLookup)
    -- 敌方全体类符文不依赖混编配额，固定出兵与补充军队后扫描新对象。
    self:ApplyAllBroadbandJamming(sourceName or "出兵")
    return assignments
end

function HextechRune:FinalizeBattleUnitAssignments(assignments)
    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local hasEffect = assignment.UltimateCreatureGranted
            or assignment.FiveTigerGranted
        if not hasEffect then
            for effectInstanceId, applied in assignment.AppliedRunes do
                if applied then
                    hasEffect = true
                    break
                end
            end
        end
        if not hasEffect
            and self.BattleUnitAssignments[assignment.ObjectId] == assignment then
            self.BattleUnitAssignments[assignment.ObjectId] = nil
        end
    end
end

function HextechRune:ApplyRoundEffects(round)
    -- 出兵命令执行完时，引擎仍可能在后续帧创建或混编单位。
    -- 延迟 45 帧后再做首次登记和 COUNT 切片，避免过早登记导致本轮新单位遗漏。
    SchedulerModule.delay_call(function(effectRound)
        local assignments = HextechRune:ApplyNewBattleUnitEffects(
            "第" .. tostring(effectRound) .. "回合固定出兵")
        HextechRune:ApplyUltimateCreatures(assignments)
        HextechRune:ApplyFiveTigerGenerals(assignments)
        -- 只保留真正获得了 BUFF 的单位登记；其余单位仍可被后续扫描选中。
        HextechRune:FinalizeBattleUnitAssignments(assignments)
    end, self.BattleUnitEffectDelay, { round })
end
