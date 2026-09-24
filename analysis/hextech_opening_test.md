# 首次海克斯固定三选一测试事件

本文件是开发备用代码，不参与 `ScriptsData.json` 打包，也不会在游戏中运行。
需要测试时，将下列函数临时复制到 `lua/GAME/HextechRune/02_event.lua`，
并在 `HextechRune:OnRoundBegin` 中显式调用；发版前再次移除。

```lua

function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "prismatic_ultimate_creature",
        "gold_cloudbreaker",
        "gold_oblivion_bomb",
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
