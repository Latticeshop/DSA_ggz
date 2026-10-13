# 海克斯符文：开发/测试用代码备份

发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。

> **当前状态（2026-10-13）：已发版清理，测试代码不在 `lua/` 与 `ScriptsData.json` 里**
> （`analysis/_remove_opening_test.py` 已跑过，自检全绿；最后复测用的三张是
> 「百虎上将 / 现金奖励 / MCV」）。
> 需要再复测时按 §1 + §2 原样贴回，发版前再跑一次同一个清理脚本即可。


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

## 2. 2026-10-12 复测版的差异（改动以源码为准）

本次复测除了上述三段，还差三处，贴回时注意：

1. **测试符文换人**：`testRuneIds` 由「狩猎律动 / 护盾局 / 战争效率」改为
   `prismatic_back_to_basics`（回归基本功）、`prismatic_equivalent_exchange`（等价交换）、
   `prismatic_tower_defense_expert`（塔防专家）。前两张是本轮新增的棱彩符文，用开局三选一
   直接在低回合数里验证数值与兵种对。
   **2026-10-13 又换过一次**：第三张由塔防专家改成 **`silver_mcv`（MCV）**，用来顺带验证
   MCV 符文的新落点（中央战场外围前哨站旁、同箱子惩罚坐标）与 15 秒 `<<<<你的基地>>>>`
   文本框（挂在**新基地车身上**、复用 `map.str` 的 `SCRIPT:ally`，不是屏幕播报）；`prismatic_tower_defense_expert` 已不在测试名单里（符文本体仍在池中）。
   **2026-10-13 再换一次**：回归基本功与等价交换**已在游戏内实测通过**，
   前两张换成 **`silver_five_tiger_generals`（百虎上将）** 与 **`silver_investment`（投资）** ——
   前者验证「名下全部步兵各一层百夫长」（不再只有 5 个，含会飞的火箭天使），后者验证「选符当场
   失去全部金钱、立刻拿回两倍」；第三张仍是 `silver_mcv`。
   **2026-10-13 第三次换（当前名单）**：投资也实测通过让位，第二张换成 **`gold_cash_reward`
   （现金奖励，金）** —— 它同日刚从留档状态重新上线，要验的是「**非苏联玩家**选到它时，地图外
   会不会补出一栋**造不出兵**的苏联基地当协议钥匙、协议按钮能不能正常用」（苏联玩家自己阵营
   则不该多任何基地）。当前三张为 **百虎上将 / 现金奖励 / MCV**，第 1 回合就能点。
   以后要复测别的组合，只改这一处 `testRuneIds` 即可。
2. **候选构造统一走正式入口**：上面 §1 的 `CopyRuneForCandidate` + 三类特殊符文的二次兜底
   合并为一句 `self:CreateRuneCandidateForPlayer(playerIndex, template, unitType)`。
   原因是新增的等价交换要在候选里**随机抽定两个兵种**（`NeedsUnitTypePair`），
   只复制模板会让它带着空兵种被点选、整张符文毫无效果。
3. **`FindRuneById` 也随之回归**：它当时和测试事件一起被删掉（`01_rune_pool.lua` 末尾，
   备份漏记），复测版重新加回，清理脚本已补上这一段：

```lua
-- 开发测试用：按 Id 直接取符文池里的原始模板，绕过筛池。
-- 只服务于第 1 回合的开局自定义三选一（见 02_event.lua 的 ShowOpeningTestEvent），
-- 发版清理时与测试事件一并删除（脚本见 analysis/_remove_opening_test.py）。
function HextechRune:FindRuneById(runeId)
    for i = 1, getn(self.RunePool), 1 do
        if self.RunePool[i].Id == runeId then
            return self.RunePool[i]
        end
    end
    return nil
end
```

> **`analysis/_verify_backup_doc.py` 的既有偏差（不是本次引入）**：它拿本文档 §1 的三段
> 与早先的全文快照 `analysis/_02_event_before.lua` 逐字比对。§1 第 2 段（`ShowOpeningTestEvent`
> 的 `testRuneIds`）在本文件里一直是**较新的复测组合**（狩猎律动 / 护盾局 / 战争效率），
> 而快照里还是更早的（吸星大法 / 致命节奏 / 十连），所以该脚本会稳定报 `mismatch = 1`；
> 判定「贴回内容是否与源码一致」请看源码本身与 §2，不要以该脚本的结论为准。
