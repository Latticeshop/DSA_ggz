-- 海克斯符文“登神”：随机指定一种单位，只保留 1 个作为种子，
-- 其余该单位被系统回收时直接转化为永久数值（生命 / 伤害 / 攻速）。

HextechRune = HextechRune or {}

-- 每转化 1 个单位提供的乘区加成。
-- 本地化 hextech.rune.ascension.desc 里写死了 2%%/1%%/1%%，改数值时同步改文案。
HextechRune.AscensionHealthPerUnit = 0.02
HextechRune.AscensionDamagePerUnit = 0.01
HextechRune.AscensionRateOfFirePerUnit = 0.01
HextechRune.AscensionStacks = HextechRune.AscensionStacks or {}
-- 已转化过的对象，防止删除延迟导致同一只单位被重复计数。
HextechRune.AscensionConsumedUnitIds = HextechRune.AscensionConsumedUnitIds or {}

function HextechRune:GetAscensionRune(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == "ascension" then
            return rune
        end
    end
    return nil
end

function HextechRune:GetAscensionStacks(playerIndex)
    return self.AscensionStacks[playerIndex] or 0
end

function HextechRune:AddAscensionStacks(playerIndex, count)
    if count == nil or count <= 0 then
        return
    end
    self.AscensionStacks[playerIndex] = self:GetAscensionStacks(playerIndex) + count
end

-- 目标单位在回收表里的配置项。超级要塞等使用 CountType 独立计数，需要一并匹配。
function HextechRune:FindAscensionUnitInfo(playerIndex, unitType)
    if g_PlayerSide == nil or g_RecycleBtnsMapByFaction == nil then
        return nil
    end
    local factionPool = g_RecycleBtnsMapByFaction[g_PlayerSide[playerIndex]]
    if factionPool == nil then
        return nil
    end
    for category = 1, 4, 1 do
        local unitInfos = factionPool[category]
        if unitInfos ~= nil then
            for i = 1, getn(unitInfos), 1 do
                local info = unitInfos[i]
                if info.Type == unitType or info.CountType == unitType then
                    return info
                end
            end
        end
    end
    return nil
end

-- 选择符文时：已有的目标单位回收掉，只留 1 个作为种子，其余直接转层数。
function HextechRune:GrantAscension(playerIndex, rune)
    if rune == nil or rune.TargetUnitType == nil then
        return
    end
    local unitInfo = self:FindAscensionUnitInfo(playerIndex, rune.TargetUnitType)
    if unitInfo == nil then
        return
    end
    local availableCount = GetRecycleUnitCount(playerIndex, unitInfo)
    if availableCount <= 1 then
        return
    end
    local removedCount = RemoveRecycleUnitCount(playerIndex, unitInfo, availableCount - 1)
    self:AddAscensionStacks(playerIndex, removedCount)
end

function HextechRune:GetAscensionPooledCount(playerIndex, rune)
    local unitInfo = self:FindAscensionUnitInfo(playerIndex, rune.TargetUnitType)
    if unitInfo == nil then
        return 0
    end
    return tonumber(GetRecycleUnitCount(playerIndex, unitInfo)) or 0
end

-- “买二送一”赠送的 1 个若与登神指同一单位：池内已有种子时，赠送也直接转层，
-- 不写入单位池，否则池内数量会超过 1，违背登神“只保留 1 个”。
-- 返回 true 表示调用方不要再加单位池计数。
function HextechRune:AbsorbBuyTwoGetOneBonus(playerIndex, unitIndex)
    local rune = self:GetAscensionRune(playerIndex)
    if rune == nil or unitIndex ~= rune.TargetUnitIndex then
        return false
    end
    if self:GetAscensionPooledCount(playerIndex, rune) < 1 then
        return false
    end
    self:AddAscensionStacks(playerIndex, 1)
    return true
end

-- 兜底：买二送一赠送与同帧入池的种子撞在一起时，赠送会先落进单位池，
-- 池内就会出现 2 个。每帧回收计数后把多出来的部分统一转层，保证池内只有 1 个。
function HextechRune:TrimAscensionPoolSurplus(playerIndex)
    local rune = self:GetAscensionRune(playerIndex)
    if rune == nil then
        return
    end
    local unitInfo = self:FindAscensionUnitInfo(playerIndex, rune.TargetUnitType)
    if unitInfo == nil then
        return
    end
    local pooledCount = tonumber(GetRecycleUnitCount(playerIndex, unitInfo)) or 0
    if pooledCount <= 1 then
        return
    end
    local removedCount = RemoveRecycleUnitCount(playerIndex, unitInfo, pooledCount - 1)
    self:AddAscensionStacks(playerIndex, removedCount)
end

-- 系统回收（unitgetcountanddelet）计数前调用：单位池内已有种子时，本批目标单位
-- 不进入单位池，直接删除并转为层数；池内没有该单位时留 1 只走正常入池流程。
function HextechRune:FilterAscensionUnits(playerIndex, unitIndex, units, count)
    local rune = self:GetAscensionRune(playerIndex)
    if rune == nil or unitIndex ~= rune.TargetUnitIndex then
        return units, count
    end
    if count == nil or count <= 0 then
        return units, count
    end
    local pooledCount = self:GetAscensionPooledCount(playerIndex, rune)
    local needSeed = pooledCount < 1
    local kept = {}
    local keptCount = 0
    local converted = 0
    for i = 1, count, 1 do
        local unit = units[i]
        if ObjectIsAlive(unit) then
            local unitId = ObjectGetId(unit)
            if needSeed then
                needSeed = false
                keptCount = keptCount + 1
                kept[keptCount] = unit
            elseif self.AscensionConsumedUnitIds[unitId] == nil then
                self.AscensionConsumedUnitIds[unitId] = true
                if g_PureDrawProducedUnitIds ~= nil then
                    g_PureDrawProducedUnitIds[unitId] = nil
                end
                if PureDrawRemoveKnownPlayerUnit ~= nil then
                    PureDrawRemoveKnownPlayerUnit(unitId)
                end
                ExecuteAction("NAMED_DELETE", unit)
                converted = converted + 1
                -- 被转化的单位同样是玩家生产出来的，“买二送一”进度照常累计；
                -- 否则两个符文指同一个单位时，买二送一会永远停在 1。
                if self.OnPlayerUnitCollected ~= nil then
                    self:OnPlayerUnitCollected(playerIndex, unitIndex)
                end
            end
        end
    end
    if converted > 0 then
        self:AddAscensionStacks(playerIndex, converted)
    end
    return kept, keptCount
end

function HextechRune:CreateAscensionModifier(playerIndex)
    local stacks = self:GetAscensionStacks(playerIndex)
    return exAttributeModifierCreate({
        HEALTH_MULT = 1 + stacks * self.AscensionHealthPerUnit,
        DAMAGE_MULT = 1 + stacks * self.AscensionDamagePerUnit,
        RATE_OF_FIRE = 1 + stacks * self.AscensionRateOfFirePerUnit,
    }, 1)
end

-- 每回合出兵后，把累计层数作为一个动态 Modifier 加载到该玩家的目标单位上。
-- 每只单位使用独立实例，与究极生物的处理方式一致。
function HextechRune:ApplyAscensionUnits(assignments)
    if assignments == nil then
        return
    end
    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local rune = self:GetAscensionRune(assignment.PlayerIndex)
        if rune ~= nil and assignment.UnitIndex == rune.TargetUnitIndex then
            local stacks = self:GetAscensionStacks(assignment.PlayerIndex)
            if self:IsCurrentAssignment(assignment.Unit, assignment) and stacks > 0
                and not assignment.AscensionGranted then
                ObjectLoadAttributeModifier(assignment.Unit,
                    self:CreateAscensionModifier(assignment.PlayerIndex),
                    self.PersistentBuffDuration)
                assignment.AscensionGranted = true
            end
        end
    end
end
