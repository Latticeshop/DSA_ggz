-- 海克斯溢出节点（HextechRuneExtra）—— 讲解见 analysis/地图注释说明文档.md 附录 A.84

-- 默认展开全部允许兵种；个别符文可用 UnitTypes 限制当前已经开放的版本。
-- 例如无限火力目前只开放飞机，以后只需扩展其 UnitTypes 即可增加其他兵种。
HextechRune = HextechRune or {}

function HextechRune:GetRuneCandidateUnitTypes(playerIndex, rune)
    if rune.UnitTypes == nil then
        return self:GetAvailableUnitTypes(playerIndex)
    end
    local result = {}
    for i = 1, getn(rune.UnitTypes), 1 do
        local unitType = rune.UnitTypes[i]
        if BanModeIsTypeEnabled(unitType) == 1 then
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

-- 本槽位已经收到过几次正式符文选择（0 起算）。潘多拉魔盒这类「只在前几次出现」的符文用它筛池。
function HextechRune:GetGrantSlotFormalSelectionCount(playerIndex)
    local slotIndex = self.CurrentGrantSlot[playerIndex] or playerIndex
    return self.SlotFormalSelectionCount[slotIndex] or 0
end

function HextechRune:BuildFilteredPool(playerIndex, rarity)
    self:EnsurePlayerRuneState(playerIndex)
    local filtered = {}
    for i = 1, getn(self.RunePool), 1 do
        local rune = self.RunePool[i]
        local factionAllowed = self:IsRuneFactionAvailable(playerIndex, rune)
        if rune.Rarity == rarity and factionAllowed
            and (not rune.RequiresSea or BanModeIsTypeEnabled("navy") == 1)
            -- 通用兵种约束：只对某个兵种有效的符文（含 grant_* 直接生成单位的），该兵种被禁
            -- 时就不入池 —— 赠送路径不过出兵函数，漏声明会绕过整套禁用判定（见 §4.5.1）。
            and (rune.RequiresType == nil or BanModeIsTypeEnabled(rune.RequiresType) == 1)
            -- 「多兵种任一可用即可」的符文（例如鸡汤来咯对载具或海军都生效）：
            -- 列出的兵种全被禁才不入池。
            and (rune.RequiresAnyType == nil
                or BanModeTypesAllBanned == nil
                or BanModeTypesAllBanned(rune.RequiresAnyType) ~= 1)
            -- 元神互锁要从可用兵种里随机抽两个配成同步组，凑不出两个时整张不发
            -- （禁用页最多同时禁 3 项，禁到 3 项就只剩一个兵种，这张牌等于空牌）。
            and (not rune.RequireTwoUnitTypes
                or getn(self:GetAvailableUnitTypes(playerIndex)) >= 2)
            and (not rune.ExcludeInShrinkMode or g_EnableShrinkMode ~= 1)
            -- 本场已无下一次正式事件时，这类「只对下一次起作用」的符文不发。
            and (not rune.ExcludeOnLastFormalRound or self:HasNextFormalEvent())
            -- 玩家的第一次正式选择里，这类「前期过强 / 依赖已有单位池」的符文不发（与回合数无关）。
            and (not rune.ExcludeOnFirstFormalSelection
                or not self:IsFirstFormalSelection(playerIndex))
            -- 「只在前面几次正式选择出现」的符文（潘多拉魔盒只给第 2、3 次，避免开局换掉整池）。
            and (rune.ExcludeFromFormalSelectionCount == nil
                or self:GetGrantSlotFormalSelectionCount(playerIndex)
                    < rune.ExcludeFromFormalSelectionCount)
            -- 与已持有的符文互斥时同样不发（顺手的事 × 赌怪，避免单人整局超过 5 张）。
            and not self:IsRuneExclusiveBlocked(playerIndex, rune) then
            if rune.NeedsUnitTypePair then
                -- 等价交换这一类：兵种对在候选里定死，一次事件只出 1 个候选，
                -- 不像普通兵种符文那样把每个兵种各展开一份（否则会霸占整个棱彩池）。
                local candidate = self:CreateRuneCandidateForPlayer(playerIndex, rune, nil)
                if candidate ~= nil and candidate.UnitType2 ~= nil
                    and self:IsRuneCandidateAvailable(playerIndex, candidate) then
                    tinsert(filtered, candidate)
                end
            elseif rune.NeedsUnitType then
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

-- 某玩家是否持有指定 Effect 的符文。
function HextechRune:HasOwnedRuneEffect(playerIndex, effect)
    if effect == nil then
        return false
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        if owned[i].Effect == effect then
            return true
        end
    end
    return false
end

-- 这次选择摆几张候选：默认 3 张；持有精挑细选就摆 4 张（每人一份，不叠加）。
function HextechRune:GetRuneOptionDrawCount(playerIndex)
    if self:HasOwnedRuneEffect(playerIndex, "extra_rune_option") then
        return self.MaxOptionsPerPlayer or 4
    end
    return 3
end

function HextechRune:PickThreeRunes(playerIndex, rarity)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    -- 不足目标张数时按实际张数发（有几张展示几张），只有 0 张才放弃本次事件。
    if getn(pool) < 1 then
        return nil
    end
    local picked = {}
    local drawCount = getn(pool)
    local drawLimit = self:GetRuneOptionDrawCount(playerIndex)
    if drawCount > drawLimit then
        drawCount = drawLimit
    end
    for i = 1, drawCount, 1 do
        -- 互斥剔除可能把池子清空，抽到一半没牌了就按实际张数发。
        if getn(pool) < 1 then
            break
        end
        local poolIndex = self:RandomIndex(getn(pool))
        local chosen = pool[poolIndex]
        tinsert(picked, chosen)
        tremove(pool, poolIndex)
        -- 互斥的两张（例如共用 K 键的湮灭炸弹与视距打击）不进同一批候选：
        local dropIndex = getn(pool)
        while dropIndex >= 1 do
            if self:IsRunePairExclusive(chosen, pool[dropIndex]) then
                tremove(pool, dropIndex)
            end
            dropIndex = dropIndex - 1
        end
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

function HextechRune:AddOwnedRune(playerIndex, rune, slotIndex)
    -- 槽位展示数据：正常选择时槽位就是玩家自己；退出继承后的额外选择由调用方传 slotIndex。
    if slotIndex == nil then
        slotIndex = self.CurrentGrantSlot[playerIndex]
    end
    if slotIndex == nil then
        slotIndex = playerIndex
    end
    self:EnsurePlayerRuneState(playerIndex)
    -- 必须在写入聚合表之前初始化槽位，否则会把刚加的这一条再复制一次。
    self:EnsureRuneSlotState(slotIndex)
    local ownershipId = self:GetRuneOwnershipId(rune)
    if self:IsRuneNonRepeatable(rune)
        and self.PlayerOwnedRuneIds[playerIndex][ownershipId] then
        return false
    end
    local ownedCount = (self.PlayerOwnedRuneCounts[playerIndex][ownershipId] or 0) + 1
    self.PlayerOwnedRuneCounts[playerIndex][ownershipId] = ownedCount
    self.PlayerOwnedRuneIds[playerIndex][ownershipId] = true
    rune.OwnedInstanceId = ownershipId .. "#" .. tostring(ownedCount)
    -- 席位归属：同名多份按「席内相加、跨席取最大」统计（见附录 A.59）。
    rune.OwnedSlotIndex = slotIndex
    tinsert(self.PlayerOwnedRunes[playerIndex], rune)
    tinsert(self.PlayerSlotOwnedRunes[slotIndex], rune)
    self.PlayerSlotOwnedRuneIds[slotIndex][ownershipId] = true
    -- 战斗要塞：拿到这张就先把卡池里已有的 4 的倍数合成掉（余数保留），
    -- 之后由入池回调继续累计（实现见 05_ultimate_creature.lua 末尾）。
    if rune.Effect == "battle_fortress_merge" and self.OnBattleFortressChosen ~= nil then
        self:OnBattleFortressChosen(playerIndex)
    end
    if rune.Effect == "pandora_box" and self.ApplyPandoraBox ~= nil then
        self:ApplyPandoraBox(playerIndex, rune, slotIndex)
    end
    -- 这张符文没有选卡步骤，所以拿到就装钩子并立刻补一次，实现见 17_death_triggers.lua。
    if rune.Effect == "one_equals_two" then
        if self.EnsureIllusoryRoundHook ~= nil then
            self:EnsureIllusoryRoundHook()
        end
        if self.RefreshIllusoryBindings ~= nil then
            self:RefreshIllusoryBindings()
        end
    end
    return true
end

-- 退出继承：把一条符文并进继承者的“效果聚合”，槽位展示列表保持原样。
function HextechRune:TransferOwnedRuneToPlayer(playerIndex, rune)
    self:EnsurePlayerRuneState(playerIndex)
    local ownershipId = self:GetRuneOwnershipId(rune)
    local ownedCount = (self.PlayerOwnedRuneCounts[playerIndex][ownershipId] or 0) + 1
    self.PlayerOwnedRuneCounts[playerIndex][ownershipId] = ownedCount
    self.PlayerOwnedRuneIds[playerIndex][ownershipId] = true
    -- 用继承者名下的新序号，避免与继承者已有的同 ID 副本撞实例 ID 而少叠一层。
    rune.OwnedInstanceId = ownershipId .. "#" .. tostring(ownedCount)
    tinsert(self.PlayerOwnedRunes[playerIndex], rune)
end

HextechRune.RoundSlots = HextechRune.RoundSlots or {}

function HextechRune:GetBattleRoundIndex()
    return tonumber(exCounterGetByName("lvc")) or 0
end

-- 该玩家本回合的名额是否已被占用。名额上的单位已经死了就当场收回，避免新单位拿不到。
function HextechRune:IsRoundSlotTaken(playerIndex, slotName)
    local slot = self.RoundSlots[playerIndex]
    if slot == nil or slot.Name ~= slotName then
        return false
    end
    if slot.Round ~= self:GetBattleRoundIndex() then
        return false
    end
    local unit = GetObjectById(slot.ObjectId)
    if unit == nil or not ObjectIsAlive(unit) then
        self.RoundSlots[playerIndex] = nil
        return false
    end
    return true
end

function HextechRune:MarkRoundSlot(playerIndex, slotName, unit)
    if playerIndex == nil or unit == nil then
        return
    end
    self.RoundSlots[playerIndex] = {
        Name = slotName,
        Round = self:GetBattleRoundIndex(),
        ObjectId = ObjectGetId(unit)
    }
end

-- 符文条目与互斥判定留在这里，效果层不再往这个节点里加。

-- 开发测试用：按 Id 直接取符文池里的原始模板，绕过筛池（发版前与 02_event.lua 的
-- ShowOpeningTestEvent 一并删除，见 analysis/自走棋海克斯系统/hextech_dev_test_backup.md）。
function HextechRune:FindRuneById(runeId)
    for i = 1, getn(self.RunePool), 1 do
        if self.RunePool[i].Id == runeId then
            return self.RunePool[i]
        end
    end
    return nil
end
