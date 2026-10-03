# 海克斯符文：开发/测试用代码备份

本文件放在 `analysis/` 下，被 `analysis/.gitignore` 的 `*.md` 规则忽略，因此不会随提交上传。
发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。

> **当前状态（2026-09-29 深夜，第四次删除，准备发版）**：本轮改动实测全部通过（面板座位改为**按出生点坐标自动排序**、买二送一/登神排除 `LockPlayerProduction`、登神 5/3/2/1 + 每回合播报、以战养战改玩家独立可重复、彩卡概率上调、赌怪概率改为首轮口径），第 1 节的开局三选一测试事件**已整段删除**：`lua/` 与 `ScriptsData.json` 里 `EnableOpeningRealTest` / `OpeningTestTriggered` / `ShowOpeningTestEvent` / `testRuneIds` 计数均为 0，`02_event.lua` payload 回落到 45729 B（余 19807 B）。需要再复测时按本节贴回，**改完记得重跑 sync**。
>
> **2026-10-03 更新**：本节代码**目前又在 `lua/` 里并且已启用**（`HextechRune.EnableOpeningRealTest = true`、`OpeningTestTriggered = false`，见 `lua/GAME/HextechRune/02_event.lua` 顶部与 `OnRoundBegin`），当前组合为「登神 / 时间裂隙 / 升级重组器」，`02_event.lua` payload 48423 B（余 17113 B）。发版前仍按上文说明整段删除。
>
> 本轮实测用的组合：`{ "gold_ascension", "prismatic_time_rift", "prismatic_upgrade_recombobulator" }`（登神 / 时间裂隙 / 升级重组器，2026-10-03 起；上一轮为 登神 / 以战养战 / 升级重组器；登神与买二送一同属“选目标单位”型，需要 §1 里那个 `buy_two_get_one` / `ascension` 专属分支）。上一轮（重组器第三次调整）用的是 `{ "gold_ragnarok", "silver_recombobulator", "prismatic_upgrade_recombobulator" }`，当时 `02_event.lua` 曾回落到 43861 B。
>
> **还原时注意保留 `tools/sync_scriptsdata.py` 的 needle**：`02_event.lua` 的定位关键字是 `function HextechRune:ShowFormalEvent` + `function HextechRune:OnRoundBegin`，删测试代码不影响（两个函数都在）；`10_recombobulator` 的定位关键字现为 `RecombobulatorRareChance` + `RollRecombobulatorTargetIndex`（历史值 `RecombobulatorHighTierChance` → `RecombobulatorCarrierChance` 都已不存在）；`07_war_efficiency.lua` 的定位关键字因 2026-09-29 玩家独立化删掉了旧符号 `GetSideWarEfficiencyCopies`，已改为 `WarEfficiencyBonusPerDeath` + `ExpireWarEfficiencyBuffs`（needle 必须同时存在于 JSON 的旧内容与 lua 新内容里，否则 sync 报 found 0）。needle 未提交，`git restore .` 会一并还原掉。

---

## 1. 开局第 1 回合固定三选一测试事件

**原位置**：`lua/GAME/HextechRune/02_event.lua`
- 开关（原 29-31 行，位于 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试：第 1 回合固定显示指定的三张符文。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestTriggered = false
```

- 事件本体（原 655-710 行，`ShowFormalEvent` 之后）：

```lua
-- 开发测试：第 1 回合固定三选一，展示 testRuneIds 指定的三个符文。
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "gold_ascension",
        "prismatic_time_rift",
        "prismatic_upgrade_recombobulator",
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
                        or candidate.Effect == "ascension") then
                        -- “买二送一/登神”的目标在正式事件里由 CreateRuneCandidateForPlayer
                        -- 随机固定；测试事件若直接复制模板，目标为空，点选后毫无效果。
                        -- 因此这类符文改走正式路径，保持测试与正式行为一致。
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

- `OnRoundBegin` 里的触发分支（原 1044-1049 行，**必须**放在正式事件判断之前）：

```lua
    -- 开发测试：第 1 回合的固定三选一必须先于正式事件判断。
    if g_EnableHextechRune == 1 and self.EnableOpeningRealTest
        and not self.OpeningTestTriggered and round == 1 then
        self.OpeningTestTriggered = true
        self:ShowOpeningTestEvent()
    end
```

**复测用的固定三选一**：改 `testRuneIds` 即可。买二送一用 `"gold_buy_two_get_one"`、登神用 `"gold_ascension"`（目标由 `CreateRuneCandidateForPlayer` 随机固定，悬浮详情会显示具体单位）；固若金汤用 `"gold_fortified"`；时间裂隙用 `"prismatic_time_rift"`（无 `NeedsUnitType`，走 `CopyRuneForCandidate` 普通路径）。

**注意**：`testRuneIds` 里出现两个 `gold_buy_two_get_one` 时，三次 `CreateRuneCandidateForPlayer` 是各自独立随机的，不去重（实测正常，两张卡会指向不同单位；若撞到同一单位属小概率）。

---

## 1b. 登神诊断日志（2026-09-25 实测通过后移除）

排查“登神 BUFF 未生效”时临时加入，确认正常后已整段删除；再出问题时按下述贴回
`lua/GAME/HextechRune/06_ascension.lua`（全部改动都在该文件内）。

- 文件顶部（常量之后）加两个辅助函数：

```lua
-- 诊断日志：直接打到公共信息栏，便于游戏内确认回收与叠加是否真的发生。
function HextechRune:AscensionLog(msg)
    if _ALERT ~= nil then
        _ALERT("[登神] " .. msg)
    end
end

-- 当前层数对应的乘区数值，配合叠加日志确认 BUFF 数值是否在增长。
-- 2026-10-03 登神改随机单项后：常量由 Ascension*PerUnit 改为 Ascension*PerStack，
-- 四维次数分开记（AscensionBonusCounts[playerIndex]）。
function HextechRune:GetAscensionBuffText(playerIndex)
    local stacks = self:GetAscensionStacks(playerIndex)
    return "层数" .. stacks
        .. "，生命x" .. (1 + self:GetAscensionBonusCount(playerIndex, "Health")
            * self.AscensionHealthPerStack)
        .. "，伤害x" .. (1 + self:GetAscensionBonusCount(playerIndex, "Damage")
            * self.AscensionDamagePerStack)
        .. "，攻速x" .. (1 + self:GetAscensionBonusCount(playerIndex, "RateOfFire")
            * self.AscensionRateOfFirePerStack)
        .. "，射程x" .. (1 + self:GetAscensionBonusCount(playerIndex, "Range")
            * self.AscensionRangePerStack)
end
```

---