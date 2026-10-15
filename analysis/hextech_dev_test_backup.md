# 海克斯符文：开发/测试用代码备份

发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。

> **当前状态（2026-10-16）：已贴回 —— 复测中。** §1 三段与 `FindRuneById` 已按本节原样回到
> `lua/` 与 `ScriptsData.json`，`testRuneIds` 为 **MCV / 秒速五厘米 / 无限火力**（本轮改动：
> 回收按钮连点越界、MCV 落点改 Player_2/Player_5 前哨站、天堂制造 5→7 回合、五雷天罚 2→3 回合，
> 加上新增的秒速五厘米）。与 2026-10-14 那版相比 §1 的代码有两处实质变化：**凑不满 3 张也照发**
> （`getn(options) > 0`，因为秒速五厘米限帝国、无限火力排除帝国，帝国与非帝国座位看到的张数天然不同），
> 以及补上 `self.PlayerOptionCount[playerIndex]`（正式路径按实际张数居中排版，测试事件必须同步设置）。
> 发版前照例跑 `analysis/_remove_opening_test.py`（2026-10-16 已干跑确认四处锚点全部命中）。
> 上一次清理是 2026-10-14，被删掉的最后一版三张为 **鸡汤来咯 / 以战养战 / 神威**
> （神威当天由金降银、改授「时空裂缝2级」；第二张由「现金奖励」换成「以战养战」，
> 同时现金奖励符文再次下架留档）；再上一次是 2026-10-13（百虎上将 / 现金奖励 / MCV）。


---

## 1. 开局第 1 回合固定三选一测试事件

**原位置**：`lua/GAME/HextechRune/02_event.lua`
- 开关（原 23-25 行，位于 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试：第 1 回合固定显示指定的三张符文。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestTriggered = false
```

- 事件本体（本轮贴回后位于 `ShowFormalEvent` 之后）：

```lua
-- 开发测试：第 1 回合固定三选一，展示 testRuneIds 指定的符文。
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "silver_mcv",
        "silver_five_centimeters",
        "prismatic_infinite_ammo",
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
                local unitType = nil
                if template ~= nil and template.NeedsUnitType then
                    local availableTypes = self:GetRuneCandidateUnitTypes(playerIndex, template)
                    if getn(availableTypes) > 0 then
                        unitType = availableTypes[self:RandomIndex(getn(availableTypes))]
                    end
                end
                -- 一律走正式入口：等价交换这类要在候选里随机抽定兵种，直接复制模板会带着空兵种被点选。
                local candidate = nil
                if template ~= nil then
                    candidate = self:CreateRuneCandidateForPlayer(playerIndex, template, unitType)
                end
                if candidate ~= nil then
                    tinsert(options, candidate)
                end
            end
            if getn(options) > 0 then
                self.PlayerOptionCount[playerIndex] = getn(options)
                self.PlayerOptions[playerIndex] = options
                self.PlayerRerollUsed[playerIndex] = false
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
   **2026-10-14 第四次换（原名单）**：第一、二张仍是 **百虎上将 / 现金奖励**，第三张由
   `silver_mcv`（MCV）换成 **`silver_divine_might`（神威，银）** —— 神威同日由金降银
   （原 `gold_divine_might` / Rarity 2 / 时空裂缝3级 → Rarity 3 / 时空裂缝2级，Id 随档位改名、
   图标换 `Button_PlayerPower_ChronoRift2`）。用这张验证的就是降档后的协议授予流程，
   以及「非盟军玩家靠地图外那栋钥匙基地解锁」是否照常可用。
   **2026-10-14 第五次换**：第一张 **百虎上将** 换成同日新增的
   **`silver_chicken_soup`（鸡汤来咯，银）** —— 授予苏联协议「毒质腐蚀」
   （`PlayerTech_Soviet_IrradiateTarget` + `SpecialPower_IrradiateTarget`）。
   要验的是**苏联协议**的同一条钥匙基地路线，尤其是「先拿了现金奖励（已有苏联钥匙基地）、
   再拿鸡汤来咯**不该再生成第二栋**」（两张同阵营卡共用 `HextechProtocolYard_2_<玩家编>`）。
   当次三张为 **鸡汤来咯 / 现金奖励 / 神威**；实测结论是**鸡汤来咯正常**。
   **2026-10-14 第六次换（发版前最后一版）**：第二张 **`gold_cash_reward`（现金奖励）** 换成
   **`prismatic_war_efficiency`（以战养战，彩）** —— 同日晚些时候用户要求「将以战养战符文替换测试
   符文选项的现金协议」，并把**现金奖励符文再次下架留档**（池内条目与不可重复名单重新注释，
   理由：3 人以上对局里协议放不出来、也不结算的问题未定性）；神威与鸡汤来咯两张新协议保留。
   以战养战带 `NeedsUnitType = true`，测试事件本来就会随机抽一个可用兵种再走
   `CreateRuneCandidateForPlayer`，不用额外处理。最后一版三张为 **鸡汤来咯 / 以战养战 / 神威**，
   一局覆盖「苏联协议 ×1 + 盟军协议 ×1 + 以战养战」，第 1 回合就能点；**随后按用户要求发版清理，
   整段删除**（见文首状态）。
   **2026-10-16 贴回（当前名单）**：三张换成 **`silver_mcv`（MCV）/ `silver_five_centimeters`
   （秒速五厘米，当日新增的白银替换型符文）/ `prismatic_infinite_ammo`（无限火力）**——
   分别验「MCV 落点改用 Player_2/Player_5 预设前哨站」「樱花回天雷入池计数落到鬼樱特攻机槽」
   「名单去掉摇光后摇光不再获得无限弹药」。天堂制造 7 回合、五雷天罚 3 回合属于周期数值，
   要换就占用其中一格。注意这一版**允许张数不足 3**：秒速五厘米 `RequiredFaction = 3`、
   无限火力 `ExcludedFaction = 3`，帝国座位与非帝国座位天然各缺一角。
2. **候选构造统一走正式入口**：上面 §1 的 `CopyRuneForCandidate` + 三类特殊符文的二次兜底
   已合并为一句 `self:CreateRuneCandidateForPlayer(playerIndex, template, unitType)`（§1 现在就是合并后的版本）。
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
> 的 `testRuneIds`）在本文件里一向是**较新的复测组合**（现在是 鸡汤来咯 / 以战养战 / 神威），
> 而快照里还是更早的（吸星大法 / 致命节奏 / 十连），所以该脚本会稳定报 `mismatch = 1`；
> 判定「贴回内容是否与源码一致」请看源码本身与 §2，不要以该脚本的结论为准。
