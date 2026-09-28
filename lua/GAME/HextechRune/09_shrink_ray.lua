-- 海克斯符文“缩小射线”：每 N 回合让对手阵营的全体单位缩小一回合。
-- 效果本体复用缩小模式已验证的 AttributeMod_AlliedSupportAircraftShrinkRay_HighTechnology；
-- 该 Modifier 同名只有一份实例、后加载会改写剩余时长，所以必须按对象登记，
-- 下一回合开始时用 1 帧时长覆盖解除（与以战养战同一手法）。
-- 缩小模式（g_EnableShrinkMode == 1）下本符文不进候选池，见 01_rune_pool.lua。

HextechRune = HextechRune or {}

HextechRune.ShrinkRayRuneId = "prismatic_shrink_ray"
HextechRune.ShrinkRayModifierName = "AttributeMod_AlliedSupportAircraftShrinkRay_HighTechnology"
-- 基础周期 5 回合，同阵营每多一份减 1 回合：1/2/3 份 = 5/4/3 回合。
HextechRune.ShrinkRayBaseInterval = 5
HextechRune.ShrinkRayNextRound = HextechRune.ShrinkRayNextRound or {}
-- 按“被缩小的阵营”登记：记录本批缩小的回合号与对象，回合推进后才解除。
HextechRune.ShrinkRayActiveRound = HextechRune.ShrinkRayActiveRound or {}
HextechRune.ShrinkRayApplied = HextechRune.ShrinkRayApplied or { [7] = {}, [8] = {} }

function HextechRune:GetOpposingSideIndex(sideIndex)
    if sideIndex == 7 then
        return 8
    end
    return 7
end

function HextechRune:GetShrinkRayInterval(sideIndex)
    local copies = self:GetSideOwnedRuneCount(sideIndex, self.ShrinkRayRuneId)
    if copies <= 0 then
        return nil
    end
    local interval = self.ShrinkRayBaseInterval - (copies - 1)
    if interval < 1 then
        interval = 1
    end
    return interval
end

-- 不走单位池配额：目标阵营的全体战斗单位都要缩小。
function HextechRune:ApplyShrinkRayToSide(targetSideIndex, round)
    if P == nil or P[targetSideIndex] == nil then
        return
    end
    local applied = self.ShrinkRayApplied[targetSideIndex]
    local objects, count = ObjectFindObjects(P[targetSideIndex], nil,
        self.AllSideUnitsFilter)
    for i = 1, count, 1 do
        local objectId = ObjectGetId(objects[i])
        -- 已有的不再重复加载：同一回合内的多次扫描不会刷新时长。
        if applied[objectId] == nil then
            ObjectLoadAttributeModifier(objects[i], self.ShrinkRayModifierName,
                self.PersistentBuffDuration)
            applied[objectId] = true
        end
    end
    self.ShrinkRayActiveRound[targetSideIndex] = round
end

-- 缩小只持续一回合：下一回合开始时把上一批对象用 1 帧时长覆盖解除。
-- 同一回合内的重复调用（补充军队会再走一遍回合效果）不解除，避免把本回合的缩小截断。
function HextechRune:ExpireShrinkRay(targetSideIndex, round)
    local activeRound = self.ShrinkRayActiveRound[targetSideIndex]
    if activeRound == nil or round <= activeRound then
        return
    end
    local applied = self.ShrinkRayApplied[targetSideIndex]
    for objectId, value in applied do
        local unit = GetObjectById(objectId)
        if unit ~= nil and ObjectIsAlive(unit) then
            ObjectLoadAttributeModifier(objectId, self.ShrinkRayModifierName, 1)
        end
    end
    self.ShrinkRayApplied[targetSideIndex] = {}
    self.ShrinkRayActiveRound[targetSideIndex] = nil
end

-- 回合开始时：先解除上一轮的缩小，再给到点的阵营释放一次。
function HextechRune:ApplyShrinkRayPulse(round)
    for sideIndex = 7, 8, 1 do
        local targetSideIndex = self:GetOpposingSideIndex(sideIndex)
        self:ExpireShrinkRay(targetSideIndex, round)
        local nextRound = self.ShrinkRayNextRound[sideIndex]
        if nextRound ~= nil and round >= nextRound then
            local interval = self:GetShrinkRayInterval(sideIndex)
            if interval ~= nil then
                self:ApplyShrinkRayToSide(targetSideIndex, round)
                self.ShrinkRayNextRound[sideIndex] = round + interval
            end
        end
    end
end

-- 每一份符文取得时都立刻释放一次（与神圣干预/时间裂隙一致），
-- 并以「此刻的份数」把倒计时整体重排：1/2/3 份 → 距本次释放 5/4/3 回合。
-- 晚到的队友因此既立刻生效一次，又把后续节奏按更短的周期重新起算。
function HextechRune:OnShrinkRayChosen(sideIndex)
    local interval = self:GetShrinkRayInterval(sideIndex)
    if interval == nil then
        return
    end
    local round = tonumber(exCounterGetByName("lvc")) or 0
    self:ApplyShrinkRayToSide(self:GetOpposingSideIndex(sideIndex), round)
    self.ShrinkRayNextRound[sideIndex] = round + interval
end

-- 空军批次与补充军队后补扫：本轮处于缩小状态的阵营，新出场的单位也要补上。
function HextechRune:RescanShrinkRay()
    if P == nil then
        return
    end
    for sideIndex = 7, 8, 1 do
        local activeRound = self.ShrinkRayActiveRound[sideIndex]
        if activeRound ~= nil then
            self:ApplyShrinkRayToSide(sideIndex, activeRound)
        end
    end
end
