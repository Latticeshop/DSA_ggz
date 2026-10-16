-- 讲解见 analysis/地图注释说明文档.md 附录 A.28、A.61

HextechRune = HextechRune or {}

HextechRune.LethalTempoRuneId = "prismatic_lethal_tempo"
-- 「越打越快」这一段复用神州原生命名修正器（与 BUFF/BUFF_1.lua 岚影刺同一份）。
HextechRune.LethalTempoModifierName = "AttributeModifier_CelestialZhuRongRapidFire"
-- 加载时长：单位每回合都会被回收重建，取长时长避免中途过期。
HextechRune.LethalTempoModifierDuration = 9999
-- 固定 +40% 攻速，单开一份修正器（不借用「迅捷」那份）。
if not g_HextechLethalTempoRateOfFireModifier then
    g_HextechLethalTempoRateOfFireModifier =
        exAttributeModifierCreate({ RATE_OF_FIRE = 1.4 }, 1)
end
-- 已加载标记按「对象 ID → 回合号」记录：同一回合内的多次补扫不重复加载，
-- 换回合后单位是新对象，标记自然失效（补兵与空军补扫都会再走一遍扫描）。
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
            self.LethalTempoApplied[objectId] = round
            ObjectLoadAttributeModifier(assignment.Unit,
                g_HextechLethalTempoRateOfFireModifier,
                self.LethalTempoModifierDuration)
            ObjectLoadAttributeModifier(assignment.Unit, self.LethalTempoModifierName,
                self.LethalTempoModifierDuration)
        end
    end
end

-- 与以战养战同一套写法（07_war_efficiency.lua）：本方有持有者就扫一次阵营，
-- 再按登记归属只作用到持有者本人的单位上（同阵营队友的单位不吃）。
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
