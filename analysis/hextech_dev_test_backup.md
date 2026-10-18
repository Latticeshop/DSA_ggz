# 海克斯符文：开发/测试用代码备份

发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。

> **当前状态（2026-10-19 第二批）：已贴回 —— 待游戏内实测。** 按 §1 原文把四处（顶部声明、
> `ShowOpeningTestEvent`、`OnRoundBegin` 分支、`FindRuneById`）全部贴回 `lua/` 并同步进
> `ScriptsData.json`；按用户要求把 `testRuneIds` **换成当轮新符文**：
> **`silver_wheeled_cannon`（轮式大炮，银）/ `gold_soul_interlock`（元神互锁，金）/
> `gold_easy_does_it`（顺手的事，金）**——前两张是第二批新卡，第三张留「顺手的事」是
> 因为它的多拿一张流程还没在游戏里验过（第一批的享辐 / 赌怪已从名单撤下）。
> **测轮式大炮要选苏联阵营**（`RequiredFaction = 2`，且源单位犀牛坦克只有苏联有）；
> 测元神互锁要先拿到至少一张别的兵种符文，否则同步组没有可同步的对象，且同步组是**随机**的。
> **实测通过后照旧整段删除**：`python analysis/_remove_opening_test.py`（四处一起删，
> 包括 `FindRuneById`），再跑 `analysis/tools/sync_scriptsdata.py` 与
> `analysis/_check_release_clean.py`。静态复核见 `analysis/_verify_easy_does_it.py` 与
> `analysis/_verify_wheeled_cannon_interlock.py`。
>
> **贴回期间会出现的一批「预期内失败」**：`_verify_basics_exchange.py` / `_verify_cash_reward.py` /
> `_verify_chicken_soup.py` / `_verify_silver_divine_might.py` / `_check_release_clean.py` /
> `_tmp_release_audit.py` 里都带「开局测试已清理」的断言，只要这四处还贴在源码里，它们就会报 BAD。
> 这些断言针对的是**发版态**，不是本次改坏的，清理完自然恢复。
> 另外第 1 回合的测试三选一会先给每个座位一张符文，于是①`PlayerFormalSelectionCount` 从此不为 0，
> 第 3 回合不再算「第一次正式选择」（`ExcludeOnFirstFormalSelection` 的重组器 / 回归基本功会照常出现）；
> ②整局张数会多一张（拿到顺手的事时是 6 张，超出面板 5 格）。两条都只在贴回期间成立，属预期。
>
> **上一轮状态（2026-10-17 收尾）：已删除 —— 发版清理。** 三张测试符文（享辐 / 万象天引 / 艾卡西亚的惊喜）
> 同日实测正常后跑了 `analysis/_remove_opening_test.py`，四处（顶部声明、`ShowOpeningTestEvent`、
> `OnRoundBegin` 分支、`FindRuneById`）整段删除，删完 01 payload 47799 B、02 48421 B，
> `_check_release_clean.py` 通过。要复测按 §1 原样贴回，**`FindRuneById` 也一起补回**（清理脚本连它一并删）。
> 本轮贴回的情况：§1 三段与 `FindRuneById` 曾全在 `lua/` 与 `ScriptsData.json` 里，`testRuneIds` 为上面三张
> 协议授予符文（两张棱彩一张黄金，都不带 `NeedsUnitType`、不限阵营，六个座位都能拿满三张）。
> 上一版是 2026-10-16 的 **MCV / 秒速五厘米 / 无限火力**，那一版**只干跑过清理脚本、没有真删**，
> 所以本次只换了 `testRuneIds` 一处，其余三段代码原样未动。清理脚本按内容锚点定位、与名单无关，
> 发版前照例跑 `analysis/_remove_opening_test.py`。
> 更早两次清理：2026-10-14（末版三张 鸡汤来咯 / 以战养战 / 神威）、2026-10-13（百虎上将 / 现金奖励 / MCV）。


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
        "silver_wheeled_cannon",
        "gold_soul_interlock",
        "gold_easy_does_it",
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
   **2026-10-16 贴回（当时名单）**：三张换成 **`silver_mcv`（MCV）/ `silver_five_centimeters`
   （秒速五厘米，当日新增的白银替换型符文，**2026-10-19 由银档改挂金档、Id 已改为
   `gold_five_centimeters`**）/ `prismatic_infinite_ammo`（无限火力）**——
   分别验「MCV 落点改用 Player_2/Player_5 预设前哨站」「樱花回天雷入池计数落到鬼樱特攻机槽」
   「名单去掉摇光后摇光不再获得无限弹药」。天堂制造 7 回合、五雷天罚 3 回合属于周期数值，
   要换就占用其中一格。注意这一版**允许张数不足 3**：秒速五厘米 `RequiredFaction = 3`、
   无限火力 `ExcludedFaction = 3`，帝国座位与非帝国座位天然各缺一角。
   **2026-10-17 换**：三张全换成同日新增的协议授予符文 **`prismatic_radiant_bliss`
   （享辐，彩，苏联三级投毒）/ `prismatic_myriad_pull`（万象天引，彩，苏联磁力奇点）/
   `gold_icathia_surprise`（艾卡西亚的惊喜，金，盟军三级时空炸弹）**。要验的是查表化之后的派发链路
   （`04_buff.lua` 现在只认 `HextechRune.ProtocolGrants` 一张表）、苏联两张共用同一把钥匙基地不该
   生成第二栋、盟军那张对苏联玩家补出 `HextechProtocolYard_1_<玩家编>`，以及七字标题拆成
   「艾卡西亚 / 的惊喜」两行后的排版。三张都不限阵营、不带兵种，所以六个座位都能拿满 3 张。
   **2026-10-19 贴回（当前名单）**：换成 **`gold_easy_does_it`（顺手的事，金，当日新增）/
   `prismatic_radiant_bliss`（享辐，**同日由彩降金**）/ `prismatic_gambling_addict`（赌怪，彩）**。
   要验的有三件事：①顺手的事本身正常入池、占一个正式选择槽位，**下一次**选择界面点掉一张后
   剩下的候选仍留在屏幕上、可以再点第二张，点完正常关闭；②享辐降到金档后只出现在金档三选一里，
   协议派发（苏联三级投毒 + 地图外钥匙基地）不受档位影响；③**顺手的事 × 赌怪互斥**——
   已持有赌怪时金档池里不再有顺手的事，已持有顺手的事时彩档池里不再有赌怪（双向都验）。
   注意测试事件按 Id 直取符文、**不过筛池**，所以它会把两张互斥符文摆在同一排里；
   点选时 `HandleOptionClick` 还有一层兜底拦截（播报 `hextech.error.rune_exclusive`），
   因此这一局可以顺手验一下那层兜底。
   **2026-10-19 晚（当前名单）**：用户要求把开局第三张「顺手的事」换成 **`silver_divine_might`
   （银·神威，时空裂缝 2 级）**，所以 `testRuneIds` 现在是
   `{ "silver_wheeled_cannon", "gold_soul_interlock", "silver_divine_might" }`。
   顺手的事本身没动，仍留在金档池里正常可抽，只是不再进开局测试；它和赌怪的互斥也照旧。
   这一局顺带要验的两件事：①拿轮式大炮**不再报错**（原先 `RemapReplacedRuneTargets` 拿 nil 键
   查表会抛 `table index is nil`，2026-10-19 已修，见设计文档 §7.2）；②银·神威授予的是
   **时空裂缝 2 级**（`PurcChronoRift2`），不是 3 级。
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
> 的 `testRuneIds`）在本文件里一向是**较新的复测组合**（现在是 顺手的事 / 享辐 / 赌怪），
> 而快照里还是更早的（吸星大法 / 致命节奏 / 十连），所以该脚本会稳定报 `mismatch = 1`；
> 判定「贴回内容是否与源码一致」请看源码本身与 §2，不要以该脚本的结论为准。
