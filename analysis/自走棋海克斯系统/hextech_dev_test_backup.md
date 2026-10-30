# 海克斯符文：开局测试三选一（开发用，发版前删除）

发版态下 `lua/` 与 `ScriptsData.json` 中没有这段代码。需要复测某几张符文时，按本文把下面三段贴回源码，再跑 `analysis/tools/sync_scriptsdata.py` 同步。

## 1. 代码块

**位置：`lua/GAME/HextechRune/02_event.lua`**

- 开关（放在 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试：第 1 回合固定显示指定的三张符文。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestTriggered = false
```

- 事件本体（放在 `ShowFormalEvent` 之后）：

```lua
-- 开发测试：第 1 回合固定三选一，展示 testRuneIds 指定的符文。
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "gold_at_field",
        "gold_at_field",
        "gold_free_trade",
    }
    -- 兵种卡一次摆两张时按顺序指派兵种，其余兵种卡仍走随机。
    local testUnitTypeByIndex = { "vehicle", "navy" }
    -- 测试局固定目标：命中这里的符文不走随机目标，直接把 Target 换成指定的那只单位。
    local testTargetOverrides = {
    }
    for playerIndex = 1, 6, 1 do
        local playerName = "Player_" .. playerIndex
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if structureCount > 0 then
            local options = {}
            for i = 1, getn(testRuneIds), 1 do
                local template = self:FindRuneById(testRuneIds[i])
                local unitType = testUnitTypeByIndex[i]
                if unitType == nil and template ~= nil and template.NeedsUnitType then
                    local availableTypes = self:GetRuneCandidateUnitTypes(playerIndex, template)
                    if getn(availableTypes) > 0 then
                        unitType = availableTypes[self:RandomIndex(getn(availableTypes))]
                    end
                end
                -- 一律走正式入口：等价交换这类要在候选里随机抽定兵种，直接复制模板会带着空兵种被点选。
                -- 测试局跳过阵营判定（第 4 个参数）：苏联座席也能拿到大生产，用来验协议栏是否被选。
                local candidate = nil
                if template ~= nil then
                    candidate = self:CreateRuneCandidateForPlayer(playerIndex, template,
                        unitType, true)
                end
                if candidate ~= nil then
                    local overrideType = testTargetOverrides[candidate.Id]
                    if overrideType ~= nil then
                        candidate.TargetUnitType = overrideType
                        candidate.TargetUnitIndex = self:LookupUnitPoolIndex(overrideType)
                        candidate.TargetUnitName = self:GetReplacementTargetName(playerIndex, overrideType)
                    end
                    tinsert(options, candidate)
                end
            end
            if getn(options) > 0 then
                self.PlayerOptionCount[playerIndex] = getn(options)
                self.PlayerOptions[playerIndex] = options
                self:ResetRerollState(playerIndex, options)
                for i = 1, getn(options), 1 do
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

- `OnRoundBegin` 里的触发分支（**必须**放在正式事件判断之前）：

```lua
    -- 开发测试：第 1 回合的固定三选一必须先于正式事件判断。
    if g_EnableHextechRune == 1 and self.EnableOpeningRealTest
        and not self.OpeningTestTriggered and round == 1 then
        self.OpeningTestTriggered = true
        self:ShowOpeningTestEvent()
    end
```

- `FindRuneById`（放在 `lua/GAME/HextechRune/01_rune_pool.lua` 末尾，`ShowOpeningTestEvent` 依赖它按 Id 直取模板）：

```lua
-- 开发测试用：按 Id 直接取符文池里的原始模板，绕过筛池。
-- 只服务于第 1 回合的开局自定义三选一（见 02_event.lua 的 ShowOpeningTestEvent），
-- 发版清理时与测试事件一并删除。
function HextechRune:FindRuneById(runeId)
    for i = 1, getn(self.RunePool), 1 do
        if self.RunePool[i].Id == runeId then
            return self.RunePool[i]
        end
    end
    return nil
end
```

## 2. 换测试内容只改这里

- `testRuneIds`：要测的三张符文 Id。测试事件按 Id 直取符文、**不过筛池**，所以互斥/禁模式限制在这里不生效；点选时 `HandleOptionClick` 仍有兜底拦截。
- `testUnitTypeByIndex`：兵种卡的兵种按格子顺序指定；不指定的兵种卡在可用兵种里随机。
- `testTargetOverrides`：固定「指定单位型」符文（登神 / 买二送一 / 究极生物）的目标单位，格式 `符文Id = "单位模板名"`。
- 第 4 个参数 `true`：测试局跳过阵营判定，任何座席都能拿到该符文。

## 3. 发版前清理

1. 删掉上面四处代码（开关、`ShowOpeningTestEvent`、`OnRoundBegin` 分支、`FindRuneById`）。
2. 跑 `python analysis/tools/sync_scriptsdata.py` 回填 `ScriptsData.json`。
3. `grep -n "EnableOpeningRealTest\|ShowOpeningTestEvent\|FindRuneById" lua/GAME/HextechRune/*.lua` 确认四处已全部删净。

> 恢复前先 grep：常见情况是只干跑过清理、代码其实还在。
