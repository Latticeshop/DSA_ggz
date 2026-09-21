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

    -- 金色
    { Id = "gold_starting_funds", Rarity = 2, NameKey = "hextech.rune.starting_funds.name",
        DescKey = "hextech.rune.starting_funds.desc", Effect = "starting_funds",
        Icon = "AUA_Bribe" },
    { Id = "gold_fortified", Rarity = 2, NameKey = "hextech.rune.fortified.name",
        DescKey = "hextech.rune.fortified.desc", Effect = "fortified",
        Icon = "Button_JapanPointShieldControlTower" },
    { Id = "gold_recycler", Rarity = 2, NameKey = "hextech.rune.recycler.name",
        DescKey = "hextech.rune.recycler.desc", Effect = "recycler",
        Icon = "Button_AlliedSalvageShip" },
    { Id = "gold_scope", Rarity = 2, NameKey = "hextech.rune.scope.gold.name",
        DescKey = "hextech.rune.scope.gold.desc", Effect = "range_gold", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },

    -- 彩色
    { Id = "prismatic_infinite_ammo", Rarity = 1, NameKey = "hextech.rune.infinite_ammo.name",
        DescKey = "hextech.rune.infinite_ammo.desc", Effect = "infinite_ammo", NeedsUnitType = true,
        UnitTypes = { "aircraft" },
        Icon = "Button_SovietInterceptorAircraft" },
    { Id = "prismatic_scope", Rarity = 1, NameKey = "hextech.rune.scope.prismatic.name",
        DescKey = "hextech.rune.scope.prismatic.desc", Effect = "range_prismatic", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
}

HextechRune.PlayerOwnedRunes = HextechRune.PlayerOwnedRunes or {}
HextechRune.PlayerOwnedRuneIds = HextechRune.PlayerOwnedRuneIds or {}
HextechRune.PlayerOptions = HextechRune.PlayerOptions or {}

function HextechRune:EnsurePlayerRuneState(playerIndex)
    if self.PlayerOwnedRunes[playerIndex] == nil then
        self.PlayerOwnedRunes[playerIndex] = {}
    end
    if self.PlayerOwnedRuneIds[playerIndex] == nil then
        self.PlayerOwnedRuneIds[playerIndex] = {}
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
    }
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
    return name
end

-- 标题字号随卡片尺寸同比缩放；较长的三档瞄准镜额外缩小。
function HextechRune:GetRuneTitleFontSize(rune, cardSize)
    local baseSize = 16
    if rune ~= nil and (rune.Effect == "range_silver" or rune.Effect == "range_gold"
        or rune.Effect == "range_prismatic") then
        baseSize = 10
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
        if rune.Rarity == rarity then
            if rune.NeedsUnitType then
                local availableTypes = self:GetRuneCandidateUnitTypes(playerIndex, rune)
                for typeIndex = 1, getn(availableTypes), 1 do
                    local candidate = self:CopyRuneForCandidate(rune, availableTypes[typeIndex])
                    local ownershipId = self:GetRuneOwnershipId(candidate)
                    if not self.PlayerOwnedRuneIds[playerIndex][ownershipId] then
                        tinsert(filtered, candidate)
                    end
                end
            elseif not self.PlayerOwnedRuneIds[playerIndex][rune.Id] then
                tinsert(filtered, self:CopyRuneForCandidate(rune, nil))
            end
        end
    end
    return filtered
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
    if self.PlayerOwnedRuneIds[playerIndex][ownershipId] then
        return false
    end
    self.PlayerOwnedRuneIds[playerIndex][ownershipId] = true
    tinsert(self.PlayerOwnedRunes[playerIndex], rune)
    return true
end
