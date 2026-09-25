-- 海克斯符文系统：首批正式符文池与候选抽取。
-- 抽取顺序：先确定全场稀有度，再按玩家状态筛池，最后无放回抽取 3 个。

HextechRune = HextechRune or {}

HextechRune.RunePool = {
    -- 银色
    { Id = "silver_strength", Rarity = 3, NameKey = "hextech.rune.strength.name",
        DescKey = "hextech.rune.strength.desc", Effect = "damage", NeedsUnitType = true,
        Icon = "Button_PlayerPower_EmperorRage3" },
    { Id = "silver_swiftness", Rarity = 3, NameKey = "hextech.rune.swiftness.name",
        DescKey = "hextech.rune.swiftness.desc", Effect = "rate_of_fire", NeedsUnitType = true,
        Icon = "Upgrade_CelestialSpeedUpdate" },
    { Id = "silver_hunt", Rarity = 3, NameKey = "hextech.rune.hunt.name",
        DescKey = "hextech.rune.hunt.desc", Effect = "speed", NeedsUnitType = true,
        Icon = "SUA_Grinder_TurboBoost" },
    { Id = "silver_scope", Rarity = 3, NameKey = "hextech.rune.scope.silver.name",
        DescKey = "hextech.rune.scope.silver.desc", Effect = "range_silver", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "silver_astral_body", Rarity = 3,
        NameKey = "hextech.rune.astral_body.name",
        DescKey = "hextech.rune.astral_body.desc", Effect = "astral_body",
        NeedsUnitType = true, Icon = "SovietCompositeArmorUpgrade" },
    { Id = "silver_mcv", Rarity = 3, NameKey = "hextech.rune.mcv.name",
        DescKey = "hextech.rune.mcv.desc", Effect = "grant_foreign_mcv",
        Icon = "Button_JapanMCV" },
    { Id = "silver_giga_fortress", Rarity = 3,
        NameKey = "hextech.rune.giga_fortress.name",
        DescKey = "hextech.rune.giga_fortress.desc", Effect = "grant_giga_fortress",
        Icon = "Button_JapanGigaFortressShip" },
    { Id = "silver_five_tiger_generals", Rarity = 3,
        NameKey = "hextech.rune.five_tiger_generals.name",
        DescKey = "hextech.rune.five_tiger_generals.desc",
        Effect = "five_tiger_generals", Icon = "CelestialCenturion" },
    { Id = "silver_quality_transformation", Rarity = 3,
        NameKey = "hextech.rune.quality_transformation.name",
        DescKey = "hextech.rune.quality_transformation.desc",
        Effect = "quality_transformation", UpgradeRarity = 2,
        Icon = "CAAT4_Transform" },
    { Id = "silver_export_domestic", Rarity = 3,
        NameKey = "hextech.rune.export_domestic.name",
        DescKey = "hextech.rune.export_domestic.desc",
        Effect = "upgrade_tachi_cruiser", RequiredFaction = 3,
        Icon = "Button_JapanAntiNavyShipTech3" },
    { Id = "silver_dual_purpose", Rarity = 3,
        NameKey = "hextech.rune.dual_purpose.name",
        DescKey = "hextech.rune.dual_purpose.desc",
        Effect = "upgrade_bullfrog", RequiredFaction = 2,
        Icon = "Button_VDVAntiAirVehicleTech1" },
    { Id = "silver_advanced_artillery", Rarity = 3,
        NameKey = "hextech.rune.advanced_artillery.name",
        DescKey = "hextech.rune.advanced_artillery.desc",
        Effect = "upgrade_vanguard_gunship", RequiredFaction = 1,
        Icon = "Button_AlliedHarbingerGunship" },

    -- 金色
    { Id = "gold_oblivion_bomb", Rarity = 2,
        NameKey = "hextech.rune.oblivion_bomb.name",
        DescKey = "hextech.rune.oblivion_bomb.desc", Effect = "grant_oblivion_bomb",
        Icon = "Button_PlayerPower_Telekenetic" },
    { Id = "gold_cloudbreaker", Rarity = 2, NameKey = "hextech.rune.cloudbreaker.name",
        DescKey = "hextech.rune.cloudbreaker.desc", Effect = "grant_yaoguang",
        Icon = "Button_CelestialAdvancedAircraftTech4" },
    { Id = "gold_oil_king", Rarity = 2, NameKey = "hextech.rune.oil_king.name",
        DescKey = "hextech.rune.oil_king.desc", Effect = "oil_king",
        Icon = "Button_PlayerPower_FreeTrade" },
    { Id = "gold_buy_two_get_one", Rarity = 2, NameKey = "hextech.rune.buy_two_get_one.name",
        DescKey = "hextech.rune.buy_two_get_one.desc", Effect = "buy_two_get_one",
        Icon = "Button_JapanAntiInfantryInfantry" },
    { Id = "gold_starting_funds", Rarity = 2, NameKey = "hextech.rune.starting_funds.name",
        DescKey = "hextech.rune.starting_funds.desc", Effect = "starting_funds",
        Icon = "AUA_Bribe" },
    -- 现金奖励符文：暂不启用（协议本身有问题，与磁暴突袭同因下架留档）。
    -- 恢复时需同时取消 04_buff.lua 的 cash_reward 派发分支注释。
    -- { Id = "gold_cash_reward", Rarity = 2,
    --     NameKey = "hextech.rune.cash_reward.name",
    --     DescKey = "hextech.rune.cash_reward.desc", Effect = "cash_reward",
    --     RequiredFaction = 2, Icon = "Button_PlayerPower_ProductionKickback" },
    { Id = "gold_safety", Rarity = 2,
        NameKey = "hextech.rune.safety.name",
        DescKey = "hextech.rune.safety.desc", Effect = "safety",
        Icon = "Button_AlliedAegisLargeDefenseBase" },
    { Id = "gold_fortified", Rarity = 2, NameKey = "hextech.rune.fortified.name",
        DescKey = "hextech.rune.fortified.desc", Effect = "fortified",
        Icon = "Button_CelestialAntiVehicleInfantry_Skill" },
    { Id = "gold_recycler", Rarity = 2, NameKey = "hextech.rune.recycler.name",
        DescKey = "hextech.rune.recycler.desc", Effect = "recycler",
        Icon = "Button_AlliedSalvageShip" },
    { Id = "gold_scope", Rarity = 2, NameKey = "hextech.rune.scope.gold.name",
        DescKey = "hextech.rune.scope.gold.desc", Effect = "range_gold", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "gold_transcendent_evil", Rarity = 2,
        NameKey = "hextech.rune.transcendent_evil.name",
        DescKey = "hextech.rune.transcendent_evil.desc",
        Effect = "transcendent_evil", NeedsUnitType = true,
        Icon = "Button_PlayerPower_EmperorRage3" },
    { Id = "gold_brilliant_lights", Rarity = 2,
        NameKey = "hextech.rune.brilliant_lights.name",
        DescKey = "hextech.rune.brilliant_lights.desc",
        Effect = "brilliant_lights", Icon = "CelestialEngineerDroneSpecialPower" },
    { Id = "gold_quality_transformation", Rarity = 2,
        NameKey = "hextech.rune.quality_transformation.name",
        DescKey = "hextech.rune.quality_transformation.desc",
        Effect = "quality_transformation", UpgradeRarity = 1,
        Icon = "CAAT4_Transform" },
    { Id = "gold_combustion_interest", Rarity = 2,
        NameKey = "hextech.rune.combustion_interest.name",
        DescKey = "hextech.rune.combustion_interest.desc",
        Effect = "combustion_interest", Icon = "Button_PlayerPower_ProductionKickback" },
    { Id = "gold_ascension", Rarity = 2,
        NameKey = "hextech.rune.ascension.name",
        DescKey = "hextech.rune.ascension.desc",
        Effect = "ascension", Icon = "JapanAVVT4Heal" },

    -- 彩色
    { Id = "prismatic_infinite_ammo", Rarity = 1, NameKey = "hextech.rune.infinite_ammo.name",
        DescKey = "hextech.rune.infinite_ammo.desc", Effect = "infinite_ammo", NeedsUnitType = true,
        UnitTypes = { "aircraft" },
        Icon = "Button_SovietInterceptorAircraft" },
    { Id = "prismatic_scope", Rarity = 1, NameKey = "hextech.rune.scope.prismatic.name",
        DescKey = "hextech.rune.scope.prismatic.desc", Effect = "range_prismatic", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "prismatic_broadband_jamming", Rarity = 1,
        NameKey = "hextech.rune.broadband_jamming.name",
        DescKey = "hextech.rune.broadband_jamming.desc", Effect = "broadband_jamming",
        Icon = "Upgrade_AlliedAircraftCarrierDrone" },
    { Id = "prismatic_divine_intervention", Rarity = 1,
        NameKey = "hextech.rune.divine_intervention.name",
        DescKey = "hextech.rune.divine_intervention.desc", Effect = "divine_intervention",
        Icon = "Button_PlayerPower_IronCurtain" },
    { Id = "prismatic_five_thunder", Rarity = 1,
        NameKey = "hextech.rune.five_thunder.name",
        DescKey = "hextech.rune.five_thunder.desc", Effect = "five_thunder",
        Icon = "Button_CelestialPantaOrbitalStrike" },
    -- 磁暴突袭符文：暂不启用（实测直接赋予该协议会有0cd问题），代码保留待后续开发。
    -- { Id = "prismatic_tesla_air_assault", Rarity = 1,
    --     NameKey = "hextech.rune.tesla_air_assault.name",
    --     DescKey = "hextech.rune.tesla_air_assault.desc",
    --     Effect = "tesla_air_assault", Icon = "Button_SovietTeslaAirAssault" },
    { Id = "prismatic_tower_defense_expert", Rarity = 1,
        NameKey = "hextech.rune.tower_defense_expert.name",
        DescKey = "hextech.rune.tower_defense_expert.desc",
        Effect = "tower_defense_expert",
        Icon = "Button_JapanPointShieldControlTower" },
    { Id = "prismatic_ultimate_refresh", Rarity = 1,
        NameKey = "hextech.rune.ultimate_refresh.name",
        DescKey = "hextech.rune.ultimate_refresh.desc",
        Effect = "ultimate_refresh", Icon = "Button_PlayerPower_PointDefenseDrones" },
    { Id = "prismatic_gambling_addict", Rarity = 1,
        NameKey = "hextech.rune.gambling_addict.name",
        DescKey = "hextech.rune.gambling_addict.desc",
        Effect = "gambling_addict", Icon = "Button_PlayerPower_FreeTrade" },
    { Id = "prismatic_ultimate_creature", Rarity = 1,
        NameKey = "hextech.rune.ultimate_creature.name",
        DescKey = "hextech.rune.ultimate_creature.desc",
        Effect = "ultimate_creature", Icon = "Button_RedKingOni" },
    { Id = "prismatic_sea_overlord", Rarity = 1,
        NameKey = "hextech.rune.sea_overlord.name",
        DescKey = "hextech.rune.sea_overlord.desc", Effect = "grant_olympus_carrier",
        RequiresSea = true, Icon = "Button_AlliedGaintAircraftCarrier" },
    { Id = "prismatic_dongfeng_express", Rarity = 1,
        NameKey = "hextech.rune.dongfeng_express.name",
        DescKey = "hextech.rune.dongfeng_express.desc",
        Effect = "grant_dongfeng_express", Icon = "Button_CelestialDF41" },
}

-- 只有列在这里的基础符文，才会在玩家持有后永久从该玩家后续候选池排除。
-- 同一轮三选一仍由 PickThreeRunes 的无放回抽取保证互不重复。
HextechRune.NonRepeatableRuneIds = {
    silver_export_domestic = true,
    silver_dual_purpose = true,
    silver_advanced_artillery = true,
    gold_fortified = true,
    gold_transcendent_evil = true,
    prismatic_broadband_jamming = true,
    prismatic_divine_intervention = true,
    gold_combustion_interest = true,
    prismatic_tower_defense_expert = true,
    prismatic_gambling_addict = true,
    prismatic_ultimate_creature = true,
    prismatic_five_thunder = true,
    prismatic_dongfeng_express = true,
    gold_ascension = true,
    -- prismatic_tesla_air_assault = true, -- 磁暴突袭符文：暂不启用
}

HextechRune.PlayerOwnedRunes = HextechRune.PlayerOwnedRunes or {}
HextechRune.PlayerOwnedRuneIds = HextechRune.PlayerOwnedRuneIds or {}
HextechRune.PlayerOwnedRuneCounts = HextechRune.PlayerOwnedRuneCounts or {}
HextechRune.PlayerOptions = HextechRune.PlayerOptions or {}

function HextechRune:EnsurePlayerRuneState(playerIndex)
    if self.PlayerOwnedRunes[playerIndex] == nil then
        self.PlayerOwnedRunes[playerIndex] = {}
    end
    if self.PlayerOwnedRuneIds[playerIndex] == nil then
        self.PlayerOwnedRuneIds[playerIndex] = {}
    end
    if self.PlayerOwnedRuneCounts[playerIndex] == nil then
        self.PlayerOwnedRuneCounts[playerIndex] = {}
    end
end

function HextechRune:CopyRuneForCandidate(rune, unitType)
    return {
        Id = rune.Id,
        Rarity = rune.Rarity,
        NameKey = rune.NameKey,
        DescKey = rune.DescKey,
        Effect = rune.Effect,
        UnitType = unitType,
        Icon = rune.Icon,
        TargetUnitType = rune.TargetUnitType,
        TargetUnitIndex = rune.TargetUnitIndex,
        TargetUnitName = rune.TargetUnitName,
        RequiresSea = rune.RequiresSea,
        RequiredFaction = rune.RequiredFaction,
        UpgradeRarity = rune.UpgradeRarity,
    }
end

-- “买二送一”目标池筛选
-- 目标池直接取自回收表（g_RecycleBtnsMapByFaction），但回收表里混有两类
-- 玩家永远无法自己产出、因而永远无法累计进度的目标，抽到等于一张空符文：
--   1) 本版本 Corona 尚未实装的预留单位：JapanAntiAirVehicleTech3 /
--      SovietPineElectronicRadarTruck / CelestialAntiAirVehicleTech3 /
--      AlliedAirForceDispatchVehicle；
--   2) 只能由其它符文转换出来的形态：先进火炮的 AlliedAC130GunshipAircraft、
--      青锋 _B 的形态别名 CelestialLongRangeMissileVehicle。
-- 因此用抽卡模式的显式生产池 g_PureDrawBuildableUnitPool 作为“可生产”白名单
function HextechRune:BuildBuyTwoGetOneTargetFilter()
    if self.BuyTwoGetOneProducibleTypes ~= nil then
        return self.BuyTwoGetOneProducibleTypes, self.BuyTwoGetOneAliasOnlyTypes
    end
    local producible = {}
    local producibleCount = 0
    if g_PureDrawBuildableUnitPool ~= nil then
        for tier = 1, 4, 1 do
            local tierPool = g_PureDrawBuildableUnitPool[tier]
            if tierPool ~= nil then
                for i = 1, getn(tierPool), 1 do
                    local unitType = tierPool[i].Type
                    if unitType ~= nil and producible[unitType] == nil then
                        producible[unitType] = true
                        producibleCount = producibleCount + 1
                    end
                end
            end
        end
    end
    if producibleCount == 0 then
        -- 生产池尚未加载或数据缺失：不缓存、不启用白名单，退回原有行为，
        -- 避免把整个候选池清空导致“买二送一”从三选一里消失。
        return nil, nil
    end
    local aliasOnly = {}
    if g_PureDrawProductionAliases ~= nil then
        for baseType, aliases in g_PureDrawProductionAliases do
            for i = 1, getn(aliases), 1 do
                local alias = aliases[i]
                if alias ~= nil and producible[alias] == nil then
                    aliasOnly[alias] = true
                end
            end
        end
    end
    self.BuyTwoGetOneProducibleTypes = producible
    self.BuyTwoGetOneAliasOnlyTypes = aliasOnly
    return producible, aliasOnly
end

-- 玩家已持有的“买二送一”指定的单位类型。“买二送一”本身可重复选择，
-- 但同一玩家的两个买二送一不能圈同一个单位，否则等于把同一份进度叠了两遍。
function HextechRune:GetOwnedBuyTwoGetOneTargetTypes(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    local result = {}
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == "buy_two_get_one" and rune.TargetUnitType ~= nil then
            result[rune.TargetUnitType] = true
        end
    end
    return result
end

-- 从玩家自身阵营的回收/单位池中选一个可计数、且玩家确实能生产的单位。
-- excluded 里的单位类型会被跳过：只有“买二送一”用它排除已持有的同类符文目标，
-- 登神不排除，允许与买二送一指向同一个单位。
function HextechRune:PickBuyTwoGetOneTarget(playerIndex, excluded)
    if g_PlayerSide == nil or g_RecycleBtnsMapByFaction == nil
        or g_UnitNameToUnitIndex == nil then
        return nil
    end
    local faction = g_PlayerSide[playerIndex]
    local factionPool = g_RecycleBtnsMapByFaction[faction]
    if factionPool == nil then
        return nil
    end
    local producible, aliasOnly = self:BuildBuyTwoGetOneTargetFilter()
    local candidates = self:CollectBuyTwoGetOneCandidates(factionPool, producible, aliasOnly,
        excluded)
    if getn(candidates) == 0 and producible ~= nil then
        -- 保证符文仍然出现在三选一里（宁可目标偏弱，也不要整张符文消失）。
        candidates = self:CollectBuyTwoGetOneCandidates(factionPool, nil, nil, excluded)
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

-- 汇总自身阵营四类回收表里“可计数 + 可生产”的单位，并按单位类型去重
function HextechRune:CollectBuyTwoGetOneCandidates(factionPool, producible, aliasOnly, excluded)
    local seen = {}
    local candidates = {}
    for category = 1, 4, 1 do
        if category ~= 4 or g_DisableSeaArmy ~= 1 then
            local units = factionPool[category]
            if units ~= nil then
                for i = 1, getn(units), 1 do
                    local info = units[i]
                    local countType = info.CountType or info.Type
                    local unitIndex = g_UnitNameToUnitIndex[countType]
                    local allowed = producible == nil
                        or (producible[countType] == true and aliasOnly[countType] == nil)
                    if unitIndex ~= nil and info.CountsTowardArmyTotal ~= false
                        and allowed and seen[countType] == nil
                        and (excluded == nil or excluded[countType] == nil) then
                        seen[countType] = true
                        tinsert(candidates, {
                            Type = countType,
                            UnitIndex = unitIndex,
                            Name = info.Name or Localization.ObjectsTranslate(countType),
                        })
                    end
                end
            end
        end
    end
    return candidates
end

function HextechRune:IsRuneFactionAvailable(playerIndex, rune)
    if rune.RequiredFaction == nil then
        return true
    end
    return g_PlayerSide ~= nil
        and g_PlayerSide[playerIndex] == rune.RequiredFaction
end

function HextechRune:CreateRuneCandidateForPlayer(playerIndex, rune, unitType)
    if not self:IsRuneFactionAvailable(playerIndex, rune) then
        return nil
    end
    local candidate = self:CopyRuneForCandidate(rune, unitType)
    if candidate.Effect == "buy_two_get_one" or candidate.Effect == "ascension" then
        -- “买二送一”可重复选择，但同一个玩家的两个买二送一不能圈同一个单位；
        -- 登神不做排除，允许与买二送一指向同一个单位。
        local excluded = nil
        if candidate.Effect == "buy_two_get_one" then
            excluded = self:GetOwnedBuyTwoGetOneTargetTypes(playerIndex)
        end
        local target = self:PickBuyTwoGetOneTarget(playerIndex, excluded)
        if target == nil then
            return nil
        end
        candidate.TargetUnitType = target.Type
        candidate.TargetUnitIndex = target.UnitIndex
        candidate.TargetUnitName = target.Name
    end
    return candidate
end

-- 带兵种的符文按“基础符文 + 兵种”视为独立符文。
-- 例如大力（步兵）与大力（载具）可以同时出现在同一次三选一中，
-- 玩家也可以分别持有它们。
function HextechRune:GetRuneOwnershipId(rune)
    if rune.UnitType ~= nil then
        return rune.Id .. ":" .. rune.UnitType
    end
    return rune.Id
end

function HextechRune:IsRuneNonRepeatable(rune)
    return rune ~= nil and self.NonRepeatableRuneIds[rune.Id] == true
end

function HextechRune:IsRuneCandidateAvailable(playerIndex, rune)
    if not self:IsRuneNonRepeatable(rune) then
        return true
    end
    return not self.PlayerOwnedRuneIds[playerIndex][self:GetRuneOwnershipId(rune)]
end

-- 可重复符文每次选择都获得独立实例 ID，用于持续效果的单位级加载标记。
function HextechRune:GetRuneEffectInstanceId(rune)
    if rune.OwnedInstanceId ~= nil then
        return rune.OwnedInstanceId
    end
    return self:GetRuneOwnershipId(rune)
end

function HextechRune:GetRuneUnitTypeLabel(rune)
    if rune == nil or rune.UnitType == nil then
        return ""
    end
    return Localization.get("hextech.unit_type." .. rune.UnitType)
end

function HextechRune:GetRuneDisplayName(rune)
    if rune == nil then
        return ""
    end
    local name = Localization.get(rune.NameKey)
    if rune.UnitType ~= nil then
        name = name .. Localization.get("hextech.unit_type.suffix", self:GetRuneUnitTypeLabel(rune))
    end
    return name
end

function HextechRune:GetRuneDescription(rune)
    if rune == nil then
        return ""
    end
    if rune.UnitType ~= nil then
        return Localization.get(rune.DescKey, self:GetRuneUnitTypeLabel(rune))
    elseif rune.Effect == "buy_two_get_one" or rune.Effect == "ascension" then
        return Localization.get(rune.DescKey, rune.TargetUnitName or rune.TargetUnitType or "?")
    end
    return Localization.get(rune.DescKey)
end

-- 带兵种标题拆成两行；事件卡与缩小后的总览卡都可避免标题越界。
function HextechRune:GetRuneCompactTitle(rune)
    if rune == nil then
        return ""
    end
    local name = Localization.get(rune.NameKey)
    if rune.UnitType ~= nil then
        return name .. "\n" .. self:GetRuneUnitTypeLabel(rune)
    end
    if rune.Effect == "broadband_jamming" then
        return "全频段阻塞\n干扰"
    end
    return name
end

-- 标题字号随卡片尺寸同比缩放；较长的三档瞄准镜额外缩小。
function HextechRune:GetRuneTitleFontSize(rune, cardSize)
    local baseSize = 16
    if rune ~= nil and (rune.Effect == "range_silver" or rune.Effect == "range_gold"
        or rune.Effect == "range_prismatic") then
        baseSize = 10
    elseif rune ~= nil and rune.Effect == "broadband_jamming" then
        baseSize = 12
    elseif rune ~= nil and rune.UnitType ~= nil then
        baseSize = 14
    end
    local result = floor(baseSize * cardSize / 200)
    if result < 3 then
        result = 3
    end
    return result
end

-- 默认展开全部允许兵种；个别符文可用 UnitTypes 限制当前已经开放的版本。
-- 例如无限火力目前只开放飞机，以后只需扩展其 UnitTypes 即可增加其他兵种。
function HextechRune:GetRuneCandidateUnitTypes(playerIndex, rune)
    if rune.UnitTypes == nil then
        return self:GetAvailableUnitTypes(playerIndex)
    end
    local result = {}
    for i = 1, getn(rune.UnitTypes), 1 do
        local unitType = rune.UnitTypes[i]
        if unitType ~= "navy" or g_DisableSeaArmy ~= 1 then
            tinsert(result, unitType)
        end
    end
    return result
end

function HextechRune:RandomIndex(count)
    if count <= 1 then
        return 1
    end
    local index = floor(GetRandomNumber() * count) + 1
    if index < 1 then
        index = 1
    elseif index > count then
        index = count
    end
    return index
end

function HextechRune:BuildFilteredPool(playerIndex, rarity)
    self:EnsurePlayerRuneState(playerIndex)
    local filtered = {}
    for i = 1, getn(self.RunePool), 1 do
        local rune = self.RunePool[i]
        local factionAllowed = self:IsRuneFactionAvailable(playerIndex, rune)
        if rune.Rarity == rarity and factionAllowed
            and (not rune.RequiresSea or g_DisableSeaArmy ~= 1) then
            if rune.NeedsUnitType then
                local availableTypes = self:GetRuneCandidateUnitTypes(playerIndex, rune)
                for typeIndex = 1, getn(availableTypes), 1 do
                    local candidate = self:CreateRuneCandidateForPlayer(playerIndex, rune,
                        availableTypes[typeIndex])
                    if self:IsRuneCandidateAvailable(playerIndex, candidate) then
                        tinsert(filtered, candidate)
                    end
                end
            else
                local candidate = self:CreateRuneCandidateForPlayer(playerIndex, rune, nil)
                if candidate ~= nil and self:IsRuneCandidateAvailable(playerIndex, candidate) then
                    tinsert(filtered, candidate)
                end
            end
        end
    end
    return filtered
end

function HextechRune:FindRuneById(runeId)
    for i = 1, getn(self.RunePool), 1 do
        if self.RunePool[i].Id == runeId then
            return self.RunePool[i]
        end
    end
    return nil
end

function HextechRune:PickThreeRunes(playerIndex, rarity)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    if getn(pool) < 3 then
        return nil
    end
    local picked = {}
    for i = 1, 3, 1 do
        local poolIndex = self:RandomIndex(getn(pool))
        tinsert(picked, pool[poolIndex])
        tremove(pool, poolIndex)
    end
    return picked
end

-- 遭遇战电脑不操作符文选择界面，直接从自身筛选后的同阶池中等概率抽取一个。
-- 与真人三选一使用同一套阵营、禁海、兵种版本和不可重复规则。
function HextechRune:PickOneRune(playerIndex, rarity)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    if getn(pool) < 1 then
        return nil
    end
    return pool[self:RandomIndex(getn(pool))]
end

function HextechRune:AddOwnedRune(playerIndex, rune)
    self:EnsurePlayerRuneState(playerIndex)
    local ownershipId = self:GetRuneOwnershipId(rune)
    if self:IsRuneNonRepeatable(rune)
        and self.PlayerOwnedRuneIds[playerIndex][ownershipId] then
        return false
    end
    local ownedCount = (self.PlayerOwnedRuneCounts[playerIndex][ownershipId] or 0) + 1
    self.PlayerOwnedRuneCounts[playerIndex][ownershipId] = ownedCount
    self.PlayerOwnedRuneIds[playerIndex][ownershipId] = true
    rune.OwnedInstanceId = ownershipId .. "#" .. tostring(ownedCount)
    tinsert(self.PlayerOwnedRunes[playerIndex], rune)
    return true
end
