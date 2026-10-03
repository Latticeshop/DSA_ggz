-- 讲解见 analysis/地图注释说明文档.md 附录 A.28

HextechRune = HextechRune or {}

HextechRune.LethalTempoRuneId = "prismatic_lethal_tempo"
-- 复用神州原生命名修正器（与 BUFF/BUFF_1.lua 岚影刺同一份）。
HextechRune.LethalTempoModifierName = "AttributeModifier_CelestialZhuRongRapidFire"
-- 加载时长：单位每回合都会被回收重建，取长时长避免中途过期。
HextechRune.LethalTempoModifierDuration = 9999
-- 已加载标记按「对象 ID → 回合号」记录：同一回合内的多次补扫不重复加载，
-- 换回合后单位是新对象，标记自然失效（同名修正器只有一份实例，重复加载不叠加）。
HextechRune.LethalTempoApplied = HextechRune.LethalTempoApplied or {}

function HextechRune:GetPlayerLethalTempoCopies(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local copies = 0
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        if owned[i].Effect == "lethal_tempo" or owned[i].Id == self.LethalTempoRuneId then
            copies = copies + 1
        end
    end
    return copies
end

function HextechRune:HasLethalTempo(playerIndex)
    return self:GetPlayerLethalTempoCopies(playerIndex) > 0
end

function HextechRune:ApplyLethalTempoBuffs(playerIndex, unitType, lookup, round)
    local objects = lookup[unitType]
    if objects == nil then
        return
    end
    for objectId, value in objects do
        local assignment = self.BattleUnitAssignments[objectId]
        if assignment ~= nil and assignment.PlayerIndex == playerIndex
            and assignment.Unit ~= nil and ObjectIsAlive(assignment.Unit)
            and self.LethalTempoApplied[objectId] ~= round then
            ObjectLoadAttributeModifier(objectId, self.LethalTempoModifierName,
                self.LethalTempoModifierDuration)
            self.LethalTempoApplied[objectId] = round
            assignment.LethalTempoGranted = true
        end
    end
end

-- 本方任一名玩家持有就扫该阵营一次，再按 BattleUnitAssignments 的归属只作用到
-- 持有者自己的单位上（同阵营队友的单位不吃）。
function HextechRune:ApplyAllLethalTempoBuffs()
    if P == nil then
        return
    end
    local round = tonumber(exCounterGetByName("lvc")) or 0
    for sideIndex = 7, 8, 1 do
        local firstPlayerIndex, lastPlayerIndex = self:GetSidePlayerRange(sideIndex)
        local sideHasHolder = false
        for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
            if self:HasLethalTempo(playerIndex) then
                sideHasHolder = true
            end
        end
        if sideHasHolder then
            local lookup = self:BuildSideUnitTypeLookup(sideIndex)
            for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
                for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
                    if self:HasLethalTempo(playerIndex) then
                        self:ApplyLethalTempoBuffs(playerIndex,
                            self.UnitTypeOrder[typeIndex], lookup, round)
                    end
                end
            end
        end
    end
end
