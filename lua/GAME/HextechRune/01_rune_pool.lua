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

    -- 金色
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
    { Id = "gold_cash_reward", Rarity = 2,
        NameKey = "hextech.rune.cash_reward.name",
        DescKey = "hextech.rune.cash_reward.desc", Effect = "cash_reward",
        Icon = "Button_PlayerPower_ProductionKickback" },
    { Id = "gold_fortified", Rarity = 2, NameKey = "hextech.rune.fortified.name",
        DescKey = "hextech.rune.fortified.desc", Effect = "fortified",
        Icon = "Button_JapanPointShieldControlTower" },
    { Id = "gold_recycler", Rarity = 2, NameKey = "hextech.rune.recycler.name",
        DescKey = "hextech.rune.recycler.desc", Effect = "recycler",
        Icon = "Button_AlliedSalvageShip" },
    { Id = "gold_scope", Rarity = 2, NameKey = "hextech.rune.scope.gold.name",
        DescKey = "hextech.rune.scope.gold.desc", Effect = "range_gold", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "gold_sea_overlord", Rarity = 2, NameKey = "hextech.rune.sea_overlord.name",
        DescKey = "hextech.rune.sea_overlord.desc", Effect = "grant_olympus_carrier",
        RequiresSea = true, Icon = "Button_AlliedGaintAircraftCarrier" },

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
        Icon = "Button_JapanPointShieldControlTower" },
    { Id = "prismatic_divine_intervention", Rarity = 1,
        NameKey = "hextech.rune.divine_intervention.name",
        DescKey = "hextech.rune.divine_intervention.desc", Effect = "divine_intervention",
        Icon = "Button_PlayerPower_IronCurtain" },
    { Id = "prismatic_five_thunder", Rarity = 1,
        NameKey = "hextech.rune.five_thunder.name",
        DescKey = "hextech.rune.five_thunder.desc", Effect = "five_thunder",
        Icon = "Button_CelestialPantaOrbitalStrike" },
}

-- 只有列在这里的基础符文，才会在玩家持有后永久从该玩家后续候选池排除。
-- 同一轮三选一仍由 PickThreeRunes 的无放回抽取保证互不重复。
HextechRune.NonRepeatableRuneIds = {
    gold_fortified = true,
    prismatic_broadband_jamming = true,
    prismatic_divine_intervention = true,
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
    }
end

-- 从玩家自身阵营的回收/单位池中选一个可计数单位，供“买二送一”使用。
function HextechRune:PickBuyTwoGetOneTarget(playerIndex)
    if g_PlayerSide == nil or g_RecycleBtnsMapByFaction == nil
        or g_UnitNameToUnitIndex == nil then
        return nil
    end
    local faction = g_PlayerSide[playerIndex]
    local factionPool = g_RecycleBtnsMapByFaction[faction]
    if factionPool == nil then
        return nil
    end
    local candidates = {}
    for category = 1, 4, 1 do
        if category ~= 4 or g_DisableSeaArmy ~= 1 then
            local units = factionPool[category]
            for i = 1, getn(units), 1 do
                local info = units[i]
                local countType = info.CountType or info.Type
                local unitIndex = g_UnitNameToUnitIndex[countType]
                if unitIndex ~= nil and info.CountsTowardArmyTotal ~= false then
                    tinsert(candidates, {
                        Type = countType,
                        UnitIndex = unitIndex,
                        Name = info.Name or Localization.ObjectsTranslate(countType),
                    })
                end
            end
        end
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

function HextechRune:CreateRuneCandidateForPlayer(playerIndex, rune, unitType)
    local candidate = self:CopyRuneForCandidate(rune, unitType)
    if candidate.Effect == "buy_two_get_one" then
        local target = self:PickBuyTwoGetOneTarget(playerIndex)
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
    elseif rune.Effect == "buy_two_get_one" then
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
        if rune.Rarity == rarity and (not rune.RequiresSea or g_DisableSeaArmy ~= 1) then
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
