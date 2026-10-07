# 海克斯符文：开发/测试用代码备份

发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。


---

## 1. 开局第 1 回合固定三选一测试事件

**原位置**：`lua/GAME/HextechRune/02_event.lua`
- 开关（原 23-25 行，位于 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试：第 1 回合固定显示指定的三张符文。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestTriggered = false
```

- 事件本体（原 659-714 行，`ShowFormalEvent` 之后）：

```lua
-- 开发测试：第 1 回合固定三选一，展示 testRuneIds 指定的三个符文。
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "silver_hunt_rhythm",
        "gold_shield_bureau",
        "prismatic_war_efficiency",
    }
    for playerIndex = 1, 6, 1 do
        local playerName = "Player_" .. playerIndex
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if structureCount > 0 then
            local options = {}
            for i = 1, 3, 1 do
                local template = self:FindRuneById(testRuneIds[i])
                local unitType = nil
                if template ~= nil and template.NeedsUnitType then
                    local availableTypes = self:GetRuneCandidateUnitTypes(playerIndex, template)
                    if getn(availableTypes) > 0 then
                        unitType = availableTypes[self:RandomIndex(getn(availableTypes))]
                    end
                end
                local candidate = nil
                if template ~= nil then
                    candidate = self:CopyRuneForCandidate(template, unitType)
                    if candidate ~= nil and (candidate.Effect == "buy_two_get_one"
                        or candidate.Effect == "ascension"
                        or candidate.Effect == "ultimate_creature") then
                        -- “买二送一/登神/究极生物”的目标在正式事件里由
                        -- CreateRuneCandidateForPlayer 随机固定；测试事件若直接复制模板，
                        -- 目标为空，点选后毫无效果。因此这类符文改走正式路径，
                        -- 保持测试与正式行为一致。
                        candidate = self:CreateRuneCandidateForPlayer(playerIndex,
                            template, unitType)
                    end
                end
                if candidate ~= nil then
                    tinsert(options, candidate)
                end
            end
            if getn(options) == 3 then
                self.PlayerOptions[playerIndex] = options
                self.PlayerRerollUsed[playerIndex] = false
                for i = 1, 3, 1 do
                    self:CreateOptionBox(playerIndex, i, options[i].Rarity,
                        self.RarityFrameImageIds[options[i].Rarity], options[i])
                    self:CreateRerollButton(playerIndex, i)
                end
                self.PlayerSelectionVisible[playerIndex] = true
                self:HideSelectionHint(playerIndex)
            else
                exAddTextToPublicBoardForPlayer(playerName,
                    Localization.get("hextech.error.not_enough_candidates"), 10)
            end
        end
    end
end
```

- `OnRoundBegin` 里的触发分支（原 1093-1098 行，**必须**放在正式事件判断之前）：

```lua
    -- 开发测试：第 1 回合的固定三选一必须先于正式事件判断。
    if g_EnableHextechRune == 1 and self.EnableOpeningRealTest
        and not self.OpeningTestTriggered and round == 1 then
        self.OpeningTestTriggered = true
        self:ShowOpeningTestEvent()
    end
```

**复测用的固定三选一**：改 `testRuneIds` 即可

---
