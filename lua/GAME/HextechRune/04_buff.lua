-- 讲解见 analysis/地图注释说明文档.md 附录 A.4、A.44、A.79

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
    {
        Types = { "infantry", "aircraft" },
        Filter = CreateObjectFilter({
            Rule = "ANY", Relationship = "SAME_PLAYER",
            IncludeThing = {
                -- 火箭天使：会飞的帝国反装甲步兵，模板带 AIRCRAFT，地图也按飞机批次登场
                "JapanAntiVehicleInfantryTech3",
            },
            Exclude = "STRUCTURE DEBRIS"
        }),
    },
}
-- 无限火力（飞机）只开放给指定对空战斗机。
-- 轰炸机、天狗、心神、摇光等其它飞机即使属于 aircraft 兵种，也不会获得无限弹药。
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
    }
})
HextechRune.UnitTypeOrder = { "infantry", "vehicle", "aircraft", "navy" }
-- 与缩小模式一致，持续时间覆盖整场战斗；同一单位的同一符文只加载一次。
HextechRune.PersistentBuffDuration = 9999
-- 以战斗单位 objectId 为键，记录该单位按单位池配额归属的玩家及已加载符文。
-- Unit 句柄同时用于识别引擎复用 objectId 的情况。
HextechRune.BattleUnitAssignments = HextechRune.BattleUnitAssignments or {}
-- 诸神黄昏生效中的单位 id 集合。跨帧只认 id：句柄可能指向已被引擎回收的对象，
-- 真要操作时再 GetObjectById 现取（同时停 sweep 的写法）。
HextechRune.RagnarokUnits = HextechRune.RagnarokUnits or {}

if not g_HextechDamageX150Modifier then
    g_HextechDamageX150Modifier = exAttributeModifierCreate({ DAMAGE_MULT = 1.5 }, 1)
end
if not g_HextechSpeedX140Modifier then
    g_HextechSpeedX140Modifier = exAttributeModifierCreate({ SPEED = 1.4 }, 1)
end
if not g_HextechRateOfFireX150Modifier then
    g_HextechRateOfFireX150Modifier = exAttributeModifierCreate({ RATE_OF_FIRE = 1.5 }, 1)
end
-- VISION 必须与 RANGE 同步，否则单位会在射程边缘停下却看不见目标。
if not g_HextechRangeX115Modifier then
    g_HextechRangeX115Modifier = exAttributeModifierCreate({ RANGE = 1.15, VISION = 1.15 }, 1)
end
if not g_HextechRangeX125Modifier then
    g_HextechRangeX125Modifier = exAttributeModifierCreate({ RANGE = 1.25, VISION = 1.25 }, 1)
end
if not g_HextechRangeX150Modifier then
    g_HextechRangeX150Modifier = exAttributeModifierCreate({ RANGE = 1.5, VISION = 1.5 }, 1)
end
if not g_HextechAstralBodyModifier then
    -- 血量 90% → 75%（2026-10-11，用户要求）；伤害 -25% 不变。
    g_HextechAstralBodyModifier = exAttributeModifierCreate({
        HEALTH_MULT = 1.75,
        DAMAGE_MULT = 0.75,
    }, 1)
end
if not g_HextechRagnarokModifier then
    g_HextechRagnarokModifier = exAttributeModifierCreate({ DAMAGE_MULT = 1.9 }, 1)
end
if not g_HextechGoliathModifier then
    -- 血量 +90%、伤害 +25%（2026-10-11 用户要求：血量由 75% 恢复 90%，伤害由 50% 降到 25%）。
    g_HextechGoliathModifier = exAttributeModifierCreate({
        HEALTH_MULT = 1.9,
        DAMAGE_MULT = 1.25,
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
-- 铁幕本体沿用技能组已验证的 AttributeModifier_IronCurtain；同名 Modifier 只有一份
-- 实例、后加载会改写剩余时长，所以施加统一走 g_ApplyIronCurtain（已有更长铁幕就不覆盖）。
HextechRune.DivineInterventionSchedulerId = HextechRune.DivineInterventionSchedulerId or nil
HextechRune.FiveThunderFirstPower = "SpecialPower_CelestialPantaOrbitalStrike"
HextechRune.FiveThunderRepeatPower = "SpecialPower_CelestialOrbitalStrike0cd"
HextechRune.FiveThunderState = HextechRune.FiveThunderState or {}
HextechRune.FiveThunderMonitorSchedulerId = HextechRune.FiveThunderMonitorSchedulerId or nil
HextechRune.FiveThunderCooldownRounds = 3
HextechRune.TeslaAirAssaultPower = "SpecialPower_SovietTeslaAirAssault"
-- 炽燃利息资金由 GetCombustionInterestMoney() 按经济倍率取值。
-- 死亡观察者由炽燃利息与以战养战共用，因此状态名不再绑定单个符文。
HextechRune.BattleDeathObserverReady =
    HextechRune.BattleDeathObserverReady or false
HextechRune.BattleDeathPhaseActive =
    HextechRune.BattleDeathPhaseActive or false
-- 现金奖励同时受玩家科技锁和 SpecialPower 可用性两层控制。
-- 使用日冕协议枚举中的规范 ID，避免只生成按钮但仍因科技锁置灰。
HextechRune.CashRewardSpecialPower = "SpecialPower_ProductionKickbacks"
HextechRune.CashRewardPlayerTech = "PlayerTech_Soviet_ProductionKickbacks"
HextechRune.FortifiedTowerState = HextechRune.FortifiedTowerState or {}
HextechRune.TranscendentEvilModifiers = HextechRune.TranscendentEvilModifiers or {}
HextechRune.FiveTigerGeneralsPower = "SpecialPower_CelestialCenturionUpgrade"
HextechRune.FiveTigerGeneralsCommand = "Command_Celestial_CenturionUpgrade"
HextechRune.BattleUnitEffectDelay = 45
-- 空军批次补扫：AIRSPACT 节点在出兵 10 秒后才生成 step3+1~step35 的飞机，
-- 首扫（45 帧）赶不上，这里在飞机出现后再留 3 秒余量。
HextechRune.AirBatchEffectDelay = 200
HextechRune.FiveTigerPowerGranted = HextechRune.FiveTigerPowerGranted or {}
-- 百虎上将：objectId → 已下过百夫长命令的回合号，挡住同回合内的重复发放。
HextechRune.CenturionGranted = HextechRune.CenturionGranted or {}
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
-- 符文赠送的埃奎斯用独立台账，与市场的两个常规购买名额互不影响（同阵营共用一条走廊）。
g_HextechGrantAegisSlots = g_HextechGrantAegisSlots or { ["angel"] = { 0, 0 }, ["evil"] = { 0, 0 } }
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

function HextechRune:PickBonusRune(playerIndex, rarity, sourceEffect)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    local candidates = {}
    for i = 1, getn(pool), 1 do
        local rune = pool[i]
        if not (sourceEffect == "gambling_addict"
            and rune.Effect == "gambling_addict") then
            tinsert(candidates, rune)
        end
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

function HextechRune:GrantBonusRune(playerIndex, rarity, sourceName, sourceEffect,
    silentBroadcast)
    local rune = self:PickBonusRune(playerIndex, rarity, sourceEffect)
    if rune == nil or not self:AddOwnedRune(playerIndex, rune) then
        return nil
    end
    self:OnRuneChosen(playerIndex, rune)
    if silentBroadcast ~= true then
        exAddTextToPublicBoard(Localization.get("hextech.bonus.broadcast",
            playerIndex, sourceName, self:GetRuneDisplayName(rune)), 10)
    end
    return rune
end

function HextechRune:ApplyQualityTransformation(playerIndex, rune)
    self:GrantBonusRune(playerIndex, rune.UpgradeRarity,
        Localization.get("hextech.rune.quality_transformation.name"), rune.Effect)
end

function HextechRune:RollGamblingAddictRarity()
    local roll = GetRandomNumber() * 100
    if roll < 10 then
        return 1
    elseif roll < 50 then
        return 2
    end
    return 3
end

function HextechRune:ApplyGamblingAddict(playerIndex)
    local sourceName = Localization.get("hextech.rune.gambling_addict.name")
    local granted = {}
    for rewardIndex = 1, 2, 1 do
        local rarity = self:RollGamblingAddictRarity()
        local rune = self:GrantBonusRune(playerIndex, rarity, sourceName,
            "gambling_addict", true)
        if rune ~= nil then
            tinsert(granted, rune)
        end
    end
    -- 两张合起来播一次，避免同一句「通过【赌怪】获得符文」连刷两条。
    if getn(granted) == 2 then
        exAddTextToPublicBoard(Localization.get("hextech.gambling_addict.broadcast",
            playerIndex, sourceName, self:GetRuneDisplayName(granted[1]),
            self:GetRuneDisplayName(granted[2])), 10)
    elseif getn(granted) == 1 then
        exAddTextToPublicBoard(Localization.get("hextech.bonus.broadcast",
            playerIndex, sourceName, self:GetRuneDisplayName(granted[1])), 10)
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

-- 持有键是“符文 ID + 兵种”，带兵种的符文需要按 ownershipId 统计队伍份数。
function HextechRune:GetSideRuneCopyCount(sideIndex, ownershipId)
    local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
    local count = 0
    for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        if self.PlayerOwnedRuneIds[playerIndex][ownershipId] then
            count = count + 1
        end
    end
    return count
end

function HextechRune:GetSideOwnedRuneCount(sideIndex, runeId)
    return self:GetSideRuneCopyCount(sideIndex, runeId)
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
        if not self:IsPresetMapUnit(unit)
            and (previous == nil or previous ~= unit) then
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
        -- 已经有铁幕的单位直接跳过：符文的铁幕不该改写技能组（或上一批符文）留下的更长期约，
        -- 真正施加的那批仍走 g_ApplyIronCurtain 的取最长仲裁。
        if not g_IsIronCurtainActive(objects[i])
            and not self:IsPresetMapUnit(objects[i]) then
            g_ApplyIronCurtain(objects[i], duration)
        end
    end
end

function HextechRune:ApplyDivineInterventionPulse(sourceName)
    self:ApplyDivineInterventionToSide(7, sourceName)
    self:ApplyDivineInterventionToSide(8, sourceName)
end

-- 详情文案展示的铁幕时长：按“这份符文到手后”的本方份数换算（1/2/3 份 = 3/4.5/6 秒）。
function HextechRune:GetDivineInterventionDisplaySeconds(playerIndex)
    return self:GetRuneBuffDurationText(self:GetRuneDisplayCopyCount(playerIndex,
        "prismatic_divine_intervention"))
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

-- 死亡事件的转发与观察者（HextechBattleUnitDie / EnsureBattleDeathObserver）在
-- 17_death_triggers.lua：04 是全树最紧的 payload，死亡触发类符文集中在 17 这个包。

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
    if BanModeIsTypeEnabled ~= nil and BanModeIsTypeEnabled("aircraft") == 0 then
        return
    end
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
    local sideName = "evil"
    local playerOwn = "PlyrCivilian"
    local behindDirection = -1
    local towerPos = { X = 2900, Y = 3102.5, Z = 210 }
    if playerIndex >= 4 then
        sideName = "angel"
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
    -- 沿用交易市场的「内优先、满了才外扩」槽位规则，但用独立台账：
    -- 符文塔允许重复生成，也不占用市场的两个常规购买名额。
    local slots = g_HextechGrantAegisSlots[sideName]
    for i = 1, 2, 1 do
        local slotIndex = BtnChoiceDialogEventFunc_AllocateAegisSlot(slots, getn(slots))
        if slotIndex == nil then
            slotIndex = getn(slots) + 1
            slots[slotIndex] = 0
        end
        local id = exCreateObject({
            ObjectType = FastHash("AlliedAegisLargeDefenseBase"),
            TeamName = playerOwn .. "/team" .. playerOwn,
            Position = {
                X = towerPos.X,
                Y = towerPos.Y + BtnChoiceDialogEventFunc_GetAegisLateralOffset(slotIndex),
                Z = towerPos.Z,
            },
            Angle = 0,
            Health = 9000,
        })
        slots[slotIndex] = id
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
                local wasExhausted = (button._usedCount or 0) >= button.MaxUseCount
                button.MaxUseCount = button.MaxUseCount + addCount
                button._hextechUltimateRefreshAppliedCount = copyCount
                if wasExhausted and (button._cooldownCount or 0) > 0 then
                    button._cooldownCount = 0
                    -- 让已经排队的旧冷却回调失效，免得它在下一段冷却里提前点亮按钮。
                    button._cooldownGeneration = (button._cooldownGeneration or 0) + 1
                end
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
    ExecuteAction("PLAYER_GIVE_MONEY", playerName, GetStartingFundsMoney())
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
    -- 落点同箱子惩罚那套坐标，但只在自己半场的前哨站里挑（基地车不能丢到敌人家里）。
    local sideName = "PlyrCivilian"
    if self:GetPlayerSideIndex(playerIndex) == 8 then
        sideName = "PlyrCreeps"
    end
    local position = nil
    if PureDrawGetOutpostDropPosition ~= nil then
        position = PureDrawGetOutpostDropPosition(sideName, playerIndex)
    end
    if position == nil then
        position = self:GetPlayerHomeSpawnPosition(playerIndex, 140, 0)
    end
    local mcvObjectId = GetNextObjectId()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        mcvTypes[targetFaction], playerName .. "/teamPlayer_" .. playerIndex,
        position, 0)
    local mcv = GetObjectById(mcvObjectId)
    -- 挂到新基地车上 15 秒：文本框跟着单位走，玩家一眼就知道该展开哪台车
    TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", mcv, "SCRIPT:ally", 15, "")
    -- 小地图亮一次标记（与抽卡空投同款）：落点在前哨站里随机挑，光看文本框容易漏
    ExecuteAction("OBJECT_CREATE_RADAR_EVENT", mcv, "Information")
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
-- 登神转化的单位也会走到这里（见 06_ascension.lua），进度照常累计。
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
                -- 与登神指向同一个单位时，赠送的 1 个转为登神层数，不进入单位池。
                local absorbed = self.AbsorbBuyTwoGetOneBonus ~= nil
                    and self:AbsorbBuyTwoGetOneBonus(playerIndex, unitIndex)
                if not absorbed then
                    ANYUNITCOUNT[playerIndex] = ANYUNITCOUNT[playerIndex] + 1
                    UNITCOUNT[playerIndex][unitIndex] = UNITCOUNT[playerIndex][unitIndex] + 1
                end
            end
        end
    end
end

function HextechRune:GetAvailableUnitTypes(playerIndex)
    -- 每个兵种版本都是独立符文，即使玩家当前尚未生产该兵种也可选择，
    -- 让效果覆盖之后生产/刷新的单位。被禁用模式的兵种不进候选池。
    return BanModeEnabledUnitTypes()
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

-- 替换型符文的回收替换表（UnitReplacementRunes）与 ResolveCollectedUnitIndex /
-- IsKamikazeGiftWarrior 已于 2026-10-19 外移到 18_basics_exchange.lua（本 payload 只余 106 B）。

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
function HextechRune:ApplyPersistentRuneToUnit(playerIndex, rune, unit, typeLookup, unitIndex)
    if not self:IsRuneMatchingUnit(rune, unit, typeLookup, playerIndex) then
        return false
    end
    -- 纯数值加成按符文实例取修正器，多形态单位吃到两个兵种变体时才能真正叠两份。
    local statMod = self:GetPerTypeStatModifier(rune, unit, typeLookup, playerIndex)
    if rune.Effect == "damage" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechDamageX150Modifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "rate_of_fire" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechRateOfFireX150Modifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "speed" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechSpeedX140Modifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "range_silver" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechRangeX115Modifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "range_gold" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechRangeX125Modifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "range_prismatic" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechRangeX150Modifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "astral_body" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechAstralBodyModifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "goliath" then
        ObjectLoadAttributeModifier(unit, statMod or g_HextechGoliathModifier,
            self.PersistentBuffDuration)
    elseif rune.Effect == "ragnarok" then
        local objectId = ObjectGetId(unit)
        ObjectLoadAttributeModifier(unit, statMod or g_HextechRagnarokModifier,
            self.PersistentBuffDuration)
        self.RagnarokUnits[objectId] = true
        -- 出兵当帧先压一次；此后每回合开始由 ApplyAllRagnarokHealthClamps 维持。
        self:ClampRagnarokUnitHealth(objectId)
        -- 出兵当帧单位可能还在部署保护中，稍后再确认一次；已达标时该调用直接返回。
        SchedulerModule.delay_call(function(id)
            HextechRune:ClampRagnarokUnitHealth(id)
        end, 60, { objectId })
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
    elseif rune.Effect == "back_to_basics" or rune.Effect == "equivalent_exchange" then
        -- 按阶级/双兵种取 Modifier 的细节都在 18_basics_exchange.lua（本 payload 已贴上限）。
        return self:ApplyBasicsOrExchangeToUnit(rune, unit, typeLookup, unitIndex,
            playerIndex)
    else
        return false
    end
    return true
end

function HextechRune:ClampRagnarokUnitHealth(objectId)
    if not ObjectIsAlive(objectId) then
        return
    end
    local maxHealth = exObjectGetMaxHealth(objectId)
    if maxHealth == nil or maxHealth <= 0 then
        return
    end
    local halfHealth = floor(maxHealth * 0.5)
    if halfHealth < 1 then
        halfHealth = 1
    end
    local currentHealth = exObjectGetCurrentHealth(objectId)
    if currentHealth == nil or currentHealth <= halfHealth then
        return
    end
    local unit = GetObjectById(objectId)
    if unit == nil or not ObjectIsAlive(unit) then
        return
    end
    local reference = "hextech_ragnarok_" .. objectId
    ExecuteAction("SET_UNIT_REFERENCE", reference, unit)
    -- UNIT_SET_HEALTH 收百分比（实测结论见 17_death_triggers.lua），按上限换算后再写。
    ExecuteAction("UNIT_SET_HEALTH", reference, halfHealth / maxHealth * 100)
    local afterHealth = exObjectGetCurrentHealth(objectId)
    if afterHealth ~= nil and afterHealth <= halfHealth
        and exObjectGetMaxHealth(objectId) == maxHealth then
        return
    end
    ExecuteAction("NAMED_SET_MAX_HEALTH", reference, halfHealth, "TRUE")
    ExecuteAction("NAMED_SET_MAX_HEALTH", reference, maxHealth, "FALSE")
    local afterMax = exObjectGetMaxHealth(objectId)
    afterHealth = exObjectGetCurrentHealth(objectId)
    if afterMax ~= maxHealth then
        -- 上限没还原就强行写回原值；这会把当前血量一起拉满，随后按差额扣掉。
        ExecuteAction("NAMED_SET_MAX_HEALTH", reference, maxHealth, "TRUE")
        afterHealth = exObjectGetCurrentHealth(objectId)
    end
    if afterHealth ~= nil and afterHealth > halfHealth then
        ExecuteAction("NAMED_DAMAGE", unit, afterHealth - halfHealth)
    end
end

-- 每回合开始时重新压血：被治疗、吸血抬回一半以上的单位会再次压回。
-- 顺带清掉已经阵亡（或 id 已被引擎回收）的登记。
function HextechRune:ApplyAllRagnarokHealthClamps()
    for objectId, value in self.RagnarokUnits do
        if ObjectIsAlive(objectId) then
            self:ClampRagnarokUnitHealth(objectId)
        else
            self.RagnarokUnits[objectId] = nil
        end
    end
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
        or rune.Effect == "infinite_ammo" or rune.Effect == "goliath"
        or rune.Effect == "ragnarok" or rune.Effect == "war_efficiency"
        -- 阶级型（回归基本功）与双兵种型（等价交换）同样走单位池配额分配。
        or rune.Effect == "back_to_basics" or rune.Effect == "equivalent_exchange"
        -- 百虎上将（步兵）与致命节奏（全兵种）也要走份额分配：战斗复制体属于 P7/P8，
        -- 只能靠这份登记认归属，按 Player_N 所有权是扫不出来的。
        or rune.Effect == "five_tiger_generals" or rune.Effect == "lethal_tempo"
end

-- 只有该玩家真正有效果可施加到这只单位时，才占用其单位池配额。
-- 普通持续 BUFF 使用全配额；究极生物每回合 1 只。百虎上将不占配额（见本函数末尾）。
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
            and self:IsRuneMatchingUnit(rune, unit, typeLookup, playerIndex) then
            if rune.Effect ~= "infinite_ammo"
                or (typeLookup.infiniteAmmoAircraft ~= nil
                    and typeLookup.infiniteAmmoAircraft[ObjectGetId(unit)]) then
                return poolCount
            end
        end
    end

    local creature = self.UltimateCreatureStates
    if creature ~= nil and creature[playerIndex] ~= nil
        and unitIndex == creature[playerIndex].UnitIndex then
        return 1
    end

    -- 登神：目标单位只保留 1 个，其余已转化为层数。
    local ascensionRune = self:GetAscensionRune(playerIndex)
    if ascensionRune ~= nil and unitIndex == ascensionRune.TargetUnitIndex
        and self:GetAscensionStacks(playerIndex) > 0 then
        return poolCount
    end

    -- 百虎上将不再占用单位池名额：它按「名下所有步兵」全量发百夫长，登记与否都不影响发放。
    return 0
end

function HextechRune:AssignNewSideBattleUnits(sideIndex, firstPlayerIndex,
    lastPlayerIndex, typeLookup, skipObjects, seenObjects)
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
            if seenObjects ~= nil then
                seenObjects[objectId] = true
            end
            local assignment = self.BattleUnitAssignments[objectId]
            if not self:IsCurrentAssignment(unit, assignment)
                and not self:IsPresetMapUnit(unit)
                -- 技能召唤单位（空军元帅苏霍伊、龙船等）同模板同阵营，不能占玩家的符文名额。
                and not IsSkillSummonedUnitId(objectId)
                and (skipObjects == nil or skipObjects[objectId] == nil) then
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

function HextechRune:AssignNewBattleUnits(typeLookup, skipObjects, seenObjects)
    local result = {}
    if UNITCOUNT == nil or FilterLIST == nil or unitcountmax == nil then
        return result
    end
    typeLookup = typeLookup or self:BuildAllBattleUnitTypeLookup()
    local left = self:AssignNewSideBattleUnits(7, 1, 3, typeLookup, skipObjects,
        seenObjects)
    local right = self:AssignNewSideBattleUnits(8, 4, 6, typeLookup, skipObjects,
        seenObjects)
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
    if self:ApplyPersistentRuneToUnit(assignment.PlayerIndex, rune,
        assignment.Unit, typeLookup, assignment.UnitIndex) then
        assignment.AppliedRunes[effectInstanceId] = true
        return true
    end
    return false
end

-- 效果不挂在“本次新出兵”身上的符文：一次性赠送、全局/经济类、被动替换型。
-- 逐兵施加的循环按这张表跳过，新增符文只需在这里登记一行，不用再改判定条件。
HextechRune.SkipPerUnitAssignmentEffects = {
    starting_funds = true, fortified = true, recycler = true,
    broadband_jamming = true, divine_intervention = true, grant_foreign_mcv = true,
    grant_yaoguang = true, oil_king = true, buy_two_get_one = true,
    five_thunder = true, combustion_interest = true, tesla_air_assault = true,
    grant_olympus_carrier = true, grant_oblivion_bomb = true,
    grant_giga_fortress = true, grant_dongfeng_express = true, safety = true,
    tower_defense_expert = true, cash_reward = true, brilliant_lights = true,
    grant_cryo_satellite = true, grant_chrono_rift = true,
    grant_irradiate = true, grant_desolator_bomb = true,
    grant_magnetic_singularity = true, grant_time_bomb = true,
    ultimate_refresh = true, quality_transformation = true, gambling_addict = true,
    upgrade_tachi_cruiser = true, upgrade_bullfrog = true,
    upgrade_waverider_dragon_breathe = true, upgrade_vanguard_gunship = true,
    upgrade_imperial_warrior = true, upgrade_v4_tulip = true,
    upgrade_sakura_rocket = true,
    upgrade_rhino_tank = true,
    prepare_backpack = true,
    easy_does_it = true,
    -- 元神互锁：不逐单位派发，两个兵种的加成互通在 IsRuneMatchingUnit 里实时判定。
    soul_interlock = true,
    ultimate_creature = true,
    war_efficiency = true, time_rift = true,
    hunt_rhythm = true,
    -- 百虎上将 / 致命节奏：效果由各自的整批扫描负责（同以战养战），不逐单位挂。
    five_tiger_generals = true, lethal_tempo = true,
}

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
            if not isExcluded
                and not self.SkipPerUnitAssignmentEffects[rune.Effect] then
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

function HextechRune:GrantCenturionLayer(playerIndex)
    if P == nil then
        return
    end
    local sideIndex = self:GetPlayerSideIndex(playerIndex)
    if P[sideIndex] == nil then
        return
    end
    local units, count = ObjectFindObjects(P[sideIndex], nil,
        self.UnitTypeFilters.infantry)
    local round = tonumber(exCounterGetByName("lvc")) or 0
    local targets = {}
    for i = 1, count, 1 do
        local unit = units[i]
        local objectId = ObjectGetId(unit)
        local assignment = self.BattleUnitAssignments[objectId]
        -- 同一回合内的多次扫描（固定出兵 / 补兵 / 空军补扫）不重复下命令：
        -- 百夫长附着物是异步生成的，光靠 HasCenturionUpgradeObject 挡不住同回合的重复发放。
        if assignment ~= nil and assignment.PlayerIndex == playerIndex
            and ObjectIsAlive(unit) and not self:HasCenturionUpgradeObject(unit)
            and not self:IsPresetMapUnit(unit)
            and self.CenturionGranted[objectId] ~= round then
            self.CenturionGranted[objectId] = round
            tinsert(targets, unit)
        end
    end
    local total = getn(targets)
    if total == 0 then
        return
    end
    self:EnsureFiveTigerGeneralsPower(playerIndex)
    local spellbooks, spellbookCount = ObjectFindObjects(targets[1], nil,
        self.CenturionSpellbookFilter)
    if spellbookCount == 0 or not ObjectIsAlive(spellbooks[1]) then
        return
    end
    local spellbookReference = "HextechFiveTigerSpellbook_" .. playerIndex
    ExecuteAction("SET_UNIT_REFERENCE", spellbookReference, spellbooks[1])
    for i = 1, total, 1 do
        local objectId = ObjectGetId(targets[i])
        local targetReference = "HextechFiveTigerTarget_" .. tostring(objectId)
        -- 登记待办：这批百夫长的出生回调要跳过第 9 回合后的千夫长晋升（见 UnitCreate.lua）。
        g_HextechFiveTigerPendingTargets[objectId] = true
        ExecuteAction("SET_UNIT_REFERENCE", targetReference, targets[i])
        ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY_ON_NAMED", spellbookReference,
            self.FiveTigerGeneralsCommand, targetReference)
    end
end

function HextechRune:ApplyFiveTigerGenerals()
    for playerIndex = 1, 6, 1 do
        if self:GetFiveTigerGeneralsCopyCount(playerIndex) > 0 then
            self:GrantCenturionLayer(playerIndex)
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
    elseif rune.Effect == "grant_railgun" then
        -- 赠送逻辑与市场购买共用，放在 BtnChoiceDialogEventFunc 的塔族里。
        BtnChoiceDialogEventFunc_CreateCelestialRailgun(playerIndex)
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
        self:CreateUltimateCreature(playerIndex, rune)
    elseif rune.Effect == "ascension" then
        self:GrantAscension(playerIndex, rune)
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
        g_HextechRecycleBonus[playerIndex] = (g_HextechRecycleBonus[playerIndex] or 0)
            + GetHextechRecycleBonusRate()
    elseif rune.Effect == "broadband_jamming" then
        self:ApplyBroadbandJamming(playerIndex, rune, "选择符文")
    elseif rune.Effect == "divine_intervention" then
        self:EnsureDivineInterventionScheduler()
        self:ApplyDivineInterventionToSide(self:GetPlayerSideIndex(playerIndex), "选择符文")
    elseif rune.Effect == "five_thunder" then
        self:GrantFiveThunder(playerIndex)
    elseif rune.Effect == "combustion_interest" or rune.Effect == "hunt_rhythm" then
        -- 死亡奖励符文：取符文时只挂上死亡观察者，触发时才读持有状态。
        self:EnsureBattleDeathObserver()
    elseif rune.Effect == "war_efficiency" then
        self:EnsureBattleDeathObserver()
        self:ApplyAllWarEfficiencyBuffs()
    elseif rune.Effect == "time_rift" then
        self:EnsureTimeRiftScheduler()
        self:ApplyTimeRiftPulse("选择符文")
    elseif rune.Effect == "shrink_ray" then
        self:OnShrinkRayChosen(self:GetPlayerSideIndex(playerIndex))
    elseif rune.Effect == "tesla_air_assault" then
        self:GrantTeslaAirAssault(playerIndex)
    elseif rune.Effect == "five_tiger_generals" then
        self:EnsureFiveTigerGeneralsPower(playerIndex)
    elseif rune.Effect == "recombobulator_same" then
        self:ApplyRecombobulator(playerIndex, false)
    elseif rune.Effect == "recombobulator_upgrade" then
        self:ApplyRecombobulator(playerIndex, true)
    elseif rune.Effect == "poach" then
        self:EnsurePoachScheduler()
    elseif rune.Effect == "investment" then
        self:ApplyInvestment(playerIndex)
    elseif rune.Effect == "ten_pull" then
        self:GrantTenPull(playerIndex)
    elseif rune.Effect == "lethal_tempo" then
        self:ApplyAllLethalTempoBuffs()
    elseif rune.Effect == "drain" then
        self:ApplyDrainToPlayer(playerIndex)
    elseif self.ProtocolGrants[rune.Effect] ~= nil then
        -- ProtocolGrants，新增一张协议符文只改那张表和符文池，派发不用动。
        self:GrantProtocol(playerIndex, rune.Effect)
    elseif rune.Effect == "prepare_backpack" then
        -- 升阶只在下一次符文选择的筛池上体现，见 02_event.lua 的 CanAscendRuneRarity。
        self.PendingRuneAscend[playerIndex] = true
    elseif rune.Effect == "easy_does_it" then
        -- 多拿一张只在下一次符文选择界面上体现，见 02_event.lua 的 ShowRuneOptionsForPlayer。
        self.PendingExtraRunePick[playerIndex] = true
    elseif rune.Effect == "upgrade_tachi_cruiser"
        or rune.Effect == "upgrade_bullfrog"
        or rune.Effect == "upgrade_waverider_dragon_breathe"
        or rune.Effect == "upgrade_vanguard_gunship"
        or rune.Effect == "upgrade_imperial_warrior"
        or rune.Effect == "upgrade_v4_tulip"
        or rune.Effect == "upgrade_sakura_rocket"
        or rune.Effect == "upgrade_rhino_tank" then
        -- 被动回收替换由 unitgetcountanddelet 在每次单位入池时查询持有状态。
        -- 已指向原形态的登神/买二送一同时改指升级形态。
        self:RemapReplacedRuneTargets(playerIndex)
    else
        self:ApplyPersistentRune(playerIndex, rune)
    end
end

-- 固定出兵和“补充军队”共用入口：只登记并处理本次新增单位。
function HextechRune:ApplyNewBattleUnitEffects(sourceName, skipObjects, seenObjects)
    local typeLookup = self:BuildAllBattleUnitTypeLookup()
    local assignments = self:AssignNewBattleUnits(typeLookup, skipObjects, seenObjects)
    self:ApplyOwnedRunesToNewAssignments(assignments, sourceName or "出兵",
        nil, nil, typeLookup)
    -- 敌方全体类符文不依赖混编配额，固定出兵与补充军队后扫描新对象。
    self:ApplyAllBroadbandJamming(sourceName or "出兵")
    -- 以战养战同理：本方兵种全体都要吃到本轮数值，不占单位池配额。
    self:ApplyAllWarEfficiencyBuffs()
    -- 致命节奏同理：持有者的全部兵种单位都要带上固定 +40% 攻速与祝融速射。
    self:ApplyAllLethalTempoBuffs()
    -- 缩小射线同理：本轮处于缩小状态的阵营，新出场的敌方单位也要补上。
    self:RescanShrinkRay()
    return assignments
end

function HextechRune:FinalizeBattleUnitAssignments(assignments)
    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local hasEffect = assignment.UltimateCreatureGranted
            or assignment.AscensionGranted
            or assignment.WarEfficiencyGranted
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

-- 一次完整的符文扫描：登记新单位并依次施加各类符文。
-- 未被本次扫描看到的对象留给后续扫描，避免重复占用究极生物的名额。
function HextechRune:ApplyBattleUnitEffectPass(sourceName, skipObjects, seenObjects)
    local assignments = self:ApplyNewBattleUnitEffects(sourceName, skipObjects,
        seenObjects)
    self:ApplyUltimateCreatures(assignments)
    self:ApplyAscensionUnits(assignments)
    self:ApplyFiveTigerGenerals()
    -- 只保留真正获得了 BUFF 的单位登记；其余单位仍可被后续扫描选中。
    self:FinalizeBattleUnitAssignments(assignments)
end

function HextechRune:ApplyRoundEffects(round)
    -- 投资已于 2026-10-13 改成选符当场结算（见 12_investment.lua），回合开始时不再有到期返还。
    -- 以战养战：本回合用上一回合累计的敌方死亡数，之后重新从零累计。
    self:RollWarEfficiencyCounters()
    -- 登神：与以战养战同一时机播报各自的累计加成。
    for ascensionPlayerIndex = 1, 6, 1 do
        self:BroadcastAscension(ascensionPlayerIndex)
    end
    -- 诸神黄昏：回合开始时把被治疗抬回一半以上的单位重新压回一半。
    self:ApplyAllRagnarokHealthClamps()
    -- 缩小射线：到点的阵营让对手全体单位缩小一回合。
    self:ApplyShrinkRayPulse(round)
    -- 出兵命令执行完时，引擎仍可能在后续帧创建或混编单位。
    -- 延迟 45 帧后再做首次登记和 COUNT 切片，避免过早登记导致本轮新单位遗漏。
    SchedulerModule.delay_call(function(effectRound)
        -- seenObjects 记录首扫看到的所有对象，作为空军补扫的排除表。
        local seenObjects = {}
        HextechRune:ApplyBattleUnitEffectPass(
            "第" .. tostring(effectRound) .. "回合固定出兵", nil, seenObjects)
        -- 陆军战机以外的飞机由 AIRSPACT 节点在出兵 10 秒后才生成，
        -- 赶不上上面这次扫描，这里用排除表只对本轮之后新增的对象补一遍。
        SchedulerModule.delay_call(function(airRound, seen)
            HextechRune:ApplyBattleUnitEffectPass(
                "第" .. tostring(airRound) .. "回合空军批次", seen, nil)
        end, HextechRune.AirBatchEffectDelay, { effectRound, seenObjects })
    end, self.BattleUnitEffectDelay, { round })
end
