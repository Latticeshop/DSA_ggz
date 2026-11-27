# 海克斯符文：开局测试三选一（开发用，发版前删除）

> **当前状态（2026-11 本轮三，测试态——这段代码已经贴回源码，正在用）**：
> 本轮测三张**协议授予符文**（同一套「地图外钥匙基地 + 授予协议技能」链路）：
> `testRuneIds = { "silver_emperors_rage", "silver_balloon_bomb", "gold_frost_zone" }`，
> `testUnitTypeByIndex` 仍留着（三张都不带 `NeedsUnitType`，会被自动清成 nil），
> `testTargetOverrides` 空着（没有随机指向单位的卡），`OpeningTestRounds = 1`。
>
> - **银·天皇之怒**（日本「天皇协议2级」）：`PlayerTech_Japan_EmperorsRage_Rank2` +
>   `SpecialPowerJapanEmperorsResolve_L2`。注意科技名 Rage、技能名 Resolve，不是同一个词。
> - **银·崩崩炸弹**（日本「气球炸弹3级」）：`PlayerTech_Japan_BalloonAttack_Rank3` +
>   `SpecialPowerJapanBalloonAttack_L3`。
> - **金·霜冻地带**（盟军「冷冻卫星2级」）：`PlayerTech_Allied_CryoSatellite_Rank2` +
>   `SpecialPowerCryoSatelliteLvl2`。就是原来注释掉没上线的「冷冻卫星」，降为 2 级后改名上线。
>
> 三张的验收点一致：①地图外多出/复用一把该阵营的钥匙基地（`HextechProtocolYard_<阵营>_<玩家名>`，
> 落在 `3324.27, 8979.87`，53 帧后被 HELD 禁用、造不出兵）；②技能按钮出现且**不是置灰**；
> ③退出继承（落墨 / 继承槽位）后技能仍在。三张都是**阵营互斥**的——非日本座席才有日本那两张，
> 非盟军座席才有霜冻地带；日本/盟军自己拿到时不会给钥匙基地（自己基地就够解锁）。
> 查名字的两张源表：`日冕地图lua例子/日冕协议表.txt`（选项名）与
> `日冕地图lua例子/【rrrl】巨人城废墟-登神_project/lua/ProtocolEnum.lua`（技能名）。
>
> 实现位置与口径见《地图注释说明文档》附录 **A.29**（协议授予链路原设计）、
> **A.81**（本次三张符文 + 「协议符文不必再登记进 04_buff 排除表」的收敛）。
> §3 的四段代码这次都在源码里（`FindRuneById` 在 `01_rune_pool.lua`，其余三段在 `02_event.lua`）。
>
> 以下为历史记录（上一轮）：测「金·登神 / 彩·最后的轻语（载具版）/ 彩·以一当二」，
> `testRuneIds = { "gold_ascension", "prismatic_last_whisper", "prismatic_one_equals_two" }`，
> 对应附录 A.75 / A.78 / A.79 / A.80。再往前是「金·登神 / 彩·全频段阻塞干扰（载具版）/ 彩·潘多拉魔盒」
> （附录 A.74 / A.77）；再往前「银·榴弹凌波 / 银·战斗要塞 / 彩·火箭飞行兵」（A.71 / A.72）；
> `{ "silver_mcv", "prismatic_illusory_weapon", "silver_factory_maintenance" }`（A.51 的 MCV 落点 +
> 工厂维护 K 键）、`{ "prismatic_illusory_weapon", "gold_ascension", "prismatic_ultimate_creature" }`（A.63）。
>
> **2026-11 另有一处实测修复**：箱子被扔进中央战场的惩罚落点曾报 `table index is nil` ——
> Lua 4.0 里 `表[nil]` 会直接抛错，而这条路径是**不带参数**调用落点函数的（`sideName` 为 nil），
> 把「阵营名 → 半场号」写成查表就当场炸；现已改成 `PureDrawOutpostSideIndex(sideName)` 函数式判定。

发版前需要复测某几张符文时，按本文改 §1 的 `testRuneIds` 即可，改完跑 `python analysis/tools/sync_scriptsdata.py` 同步；
彻底清理则按 §3 把四段代码删掉。

## 1. 代码块

**位置：`lua/GAME/HextechRune/02_event.lua`**

- 开关（放在 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试开关：开局前几回合固定显示指定的三张符文（发版前整段删除）。
-- OpeningTestRounds = 1 表示只在第 1 回合发一次同一组三张卡（实测发 2 次会连着弹两轮，只测一次就够了）。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestRounds = 1
HextechRune.OpeningTestTriggered = {}
```

> ⚠ `OpeningTestRounds` 默认写 **1**：发 2 次等于连着两回合各弹一次三选一，实测会觉得"开局选了两次"。
> 真要连着看两回合，再临时改成 2。

- 事件本体（放在 `ShowFormalEvent` 之后）：

```lua
-- 开发测试：第 1 回合固定三选一，展示 testRuneIds 指定的符文。
-- 本轮测「银·榴弹凌波」（凌波护卫战车→凌波火力支援战车）+「银·战斗要塞」（卡池里 4 辆守护者坦克
-- 合成 1 座特洛伊突击要塞）+「彩·火箭飞行兵」（敌方空军→火箭天使）：
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "silver_dragon_breathe",
        "silver_battle_fortress",
        "prismatic_sit_tight",
    }
    -- 兵种卡一次摆两张时按顺序指派兵种，其余兵种卡仍走随机。
    local testUnitTypeByIndex = { "infantry", "vehicle", "navy" }
    -- 测试局固定目标：命中这里的符文不走随机目标，直接把 Target 换成指定的那只单位。
    local testTargetOverrides = {
    }
    -- 4v4 共 8 个座席（`PanelSeatColumnGroups = { {1,2,8,3}, {4,5,7,6} }`），逐座位发同一组三张卡；
    -- 没有建筑的座席自动跳过。旧版 3v3 备份里这里是 `for playerIndex = 1, 6, 1`。
    for playerIndex = 1, 8, 1 do
        local playerName = "Player_" .. playerIndex
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if structureCount > 0 then
            local options = {}
            for i = 1, getn(testRuneIds), 1 do
                local template = self:FindRuneById(testRuneIds[i])
                local unitType = testUnitTypeByIndex[i]
                -- 不需要兵种的符文（如落墨 / 一言九鼎）不能塞兵种：
                -- 候选会把 UnitType 一起带上，判重键就变成「Id:兵种」，面板也会多出一段兵种名。
                if template ~= nil and not template.NeedsUnitType then
                    unitType = nil
                end
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
    -- 开发测试：开局前几回合的固定三选一必须先于正式事件判断。
    if g_EnableHextechRune == 1 and self.EnableOpeningRealTest
        and round <= self.OpeningTestRounds
        and not self.OpeningTestTriggered[round] then
        self.OpeningTestTriggered[round] = true
        self:ShowOpeningTestEvent()
        return
    end
```

- `FindRuneById`（放在 `lua/GAME/HextechRune/01_rune_pool.lua` 末尾，`ShowOpeningTestEvent` 依赖它按 Id 直取模板）：

```lua
-- 开发测试用：按 Id 直接取符文池里的原始模板，绕过筛池（发版前与 02_event.lua 的
-- ShowOpeningTestEvent 一并删除，见 analysis/自走棋海克斯系统/hextech_dev_test_backup.md）。
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

> **当前名单（2026-11-20 本轮）**：`silver_dragon_breathe`（榴弹凌波）/ `silver_battle_fortress`（战斗要塞）/
> `prismatic_sit_tight`（火箭飞行兵）。要验的：榴弹凌波把卡池里的凌波护卫战车换成凌波火力支援战车；战斗要塞在
> **选牌当帧**把卡池里 4 的倍数辆守护者坦克换成特洛伊突击要塞（余数保留）、之后每凑满 4 辆再合 1 座，
> 合成是**静默**的（2026-11-20 实测后按用户要求删掉了公共板播报），且第二份符文不会再给额外效果（`NonRepeatableRuneIds`）。

- `testRuneIds`：要测的三张符文 Id。测试事件按 Id 直取符文、**不过筛池**，所以互斥/禁模式限制在这里不生效；点选时 `HandleOptionClick` 仍有兜底拦截。
- `testUnitTypeByIndex`：兵种卡的兵种按格子顺序指定；不指定的兵种卡在可用兵种里随机。
- `testTargetOverrides`：固定「指定单位型」符文（登神 / 买二送一 / 究极生物）的目标单位，格式 `符文Id = "单位模板名"`。
- 第 4 个参数 `true`：测试局跳过阵营判定，任何座席都能拿到该符文。

> **历史名单（2026-11 上一轮，已作废）**：
> `{ "silver_mcv", "prismatic_illusory_weapon", "silver_factory_maintenance" }` ——
> 银·MCV / 彩·虚幻武器 / 银·工厂维护（2026-11 按用户要求把 MCV 与虚幻武器换了位置），
> `testUnitTypeByIndex` 与 `testTargetOverrides` 都留空（三张都没有「指定兵种」口径）。
> **要验的七件事**：
> ①**MCV 卡面标题居中** —— 卡面标题就是三个 ASCII 字母 `MCV`，这轮按「默认偏移往左推 1 个字母宽」
> 定档（`GetRuneTitleVisualOffsetX` 的 `grant_foreign_mcv` 分支），应与卡框中心对齐。
> ①**MCV 落点** —— 选 MCV 那张后拿到一台「自己还没有的阵营」的基地车，落在**自家半场那两座前哨站
> 点位**附近（不是出生点），单位头顶挂 15 秒文本框、小地图亮一次；连续拿两张也不会丢到对面半场。
> ②**箱子惩罚的落点**（本次修复的重点）—— 箱子被扔进中央战场时搬去任意一侧点位，控制台不再报
> `PureDrawGetOutpostDropPosition ... table index is nil`。
> ③**拿钱** —— 拿到工厂维护后 K 键提示「按'K'键进行'工厂维护'并获得 X 资金」出现在选卡提示下方
> （index 930+座位号、Y=104，与湮灭炸弹 / 视距打击同一行）；金额随经济倍率取档
> （0.5/1/1.5/2 倍 = 1000/1500/2000/3000）。
> ④**按 K 即锁** —— 按 K 立刻加该金额，四类单位建造栏（步兵 / 载具 / 飞机 / 舰船）全部变灰；
> **建筑不锁**（发电厂等照常可造，已实测确认）；K 键提示消失。
> ⑤**窗口只结算一次 + 90 秒整点解锁** —— 90 秒内连按 K 不再加钱；到点四类单位的生产按钮按各自规则
> 恢复（禁用模式禁掉的兵种、未到解锁回合的摩托 / 磁爆快艇、抽卡模式的生产余额，都不该被这次解锁
> 放开），K 键提示重新弹出来。
> ⑥**互斥** —— 手里已有湮灭炸弹 / 视距打击时，工厂维护不应再出现在三选一里（`ExclusiveRuneIds`
> 三处两两登记）；测试名单是写死的、不过筛池，所以互斥只能在正式回合里验。
> **历史记录（上一轮，已完成）· 银·先进坦克（替换型符文链路）**：
> `{ "prismatic_illusory_weapon", "prismatic_ultimate_creature", "silver_advanced_tank" }` ——
> 回收重锤 `SovietSledgehammerSPG` 直接进磁爆坦克 `SovietAntiVehicleVehicleTech2` 槽位；
> 先拿登神 / 买二送一后拿先进坦克时 `RemapReplacedRuneTargets` 改指目标名；第二份不入池；
> 该效果在 `SkipPerUnitAssignmentEffects` 里不逐单位挂载。
> **历史记录（更早的轮次，均已完成并删除）**：
> **究极生物 / 登神数值后缀**（2026-11 上一轮）：`{ "prismatic_ultimate_creature", "gold_ascension",
> "silver_easy_does_it" }`，验面板详情末尾的 `(…%血量,…%伤害,…%攻速,…%射程)` 与「消息区不再刷播报」；
> 第三格用银·顺手的事对照旧的「（已生效）」后缀。
> **以战养战（同批改造，未进当前名单）**：它的「本回合加成」也不再每回合逐兵种播报
> （`BroadcastWarEfficiency` 已删），改成面板详情末尾的 `(本回合加成：1%血量,1%伤害,…)`。
> 要复测就把某一格换成 `"prismatic_war_efficiency"`（`Effect = "war_efficiency"`、`NeedsUnitType = true`），
> 兵种由 `testUnitTypeByIndex` 对应格子指定（例：`{ "vehicle", "navy" }` 配前两格）；
> 因为数值是「本回合生效值」，选完当回合还没滚存，**要打一回合（有敌方单位死亡）再下一回合开面板**才看得到后缀。
> **历史记录（更早的轮次，均已完成并删除）**：
> **银·MCV**（2026-10-31 末轮）：三格都是 `silver_mcv`，验「没拥有的阵营才会给 / 抽卡抽到的基地车也算已有 /
> 展开成建造场之后仍算已有」；第一版只登记了建造场基础名，③ 没过，改成按
> `前缀 + ConstructionYard + 后缀` 生成后满意。
> **鸡汤来咯**（2026-10-31 十一测）：投毒在敌方随机载具/舰船上生效，`IRRADIATED` 是正确的中毒状态名，
> 预设守护神（`Overlordtank` 等六个）与技能召唤单位已排除出候选；调试日志已删。

## 3. 发版前清理（2026-10-31 已执行两次，最后一次为 MCV 收工）

1. 删掉上面四处代码（开关 `EnableOpeningRealTest` / `OpeningTestRounds` / `OpeningTestTriggered`、
   `ShowOpeningTestEvent`、`OnRoundBegin` 分支、`FindRuneById`）。**2026-11-20 这轮又贴回来了（测试态），
   发版前要再删一次**；上一次删净的判据是 `01_rune_pool.lua` 去注释 **60352 B**、`02_event.lua` 去注释
   **56991 B**（当前值见 `sync_scriptsdata.py` 输出，贴回后自然会更大）
2. 删掉两类调试日志：鸡汤来咯的 `HextechRune.IrradiateDebug` / `IrradiateLog`（含 8 处调用）、
   电脑补兵的 `AICOMP.Debug` / `AICOMP.Log`（含 3 处调用与只为日志服务的 `AICOMP.BandNames` /
   `WasPoolFallback` / `PoolFallback`）。✔ 已删
3. 回填 `ScriptsData.json`：在 `DSA_ggz/` 根目录跑 `python analysis/tools/sync_scriptsdata.py`
   （4v4 的 JSON 由 `analysis/tools/lua_payload.py` 的 `DEV_MAP_ID = "44"` 自动定位到
   `DSA_XXX%COR_44/ScriptsData.json`，不需要再传 `--map`）。
4. `grep -n "EnableOpeningRealTest\|ShowOpeningTestEvent\|FindRuneById\|IrradiateLog\|AICOMP.Log" lua/GAME/HextechRune/*.lua lua/LUABOX/AI/*.lua` 确认全部已删净。
5. 复核：`python analysis/audit_lua_json.py`（DRIFT 里不应出现 `02_event.lua` / `01_rune_pool.lua`）、
   `python analysis/check_payload_lua4.py` 同口径的 Lua 4.0 体检通过。

> 恢复前先 grep：常见情况是只干跑过清理、代码其实还在。


## 当前测试集：验证 payload 搬迁后的执行（2026-11）

开局测试事件（HextechRune:ShowOpeningTestEvent）的三张卡临时换成**会真正跑搬迁后代码**的三张：

| testRuneIds | 效果键 | 会执行的搬迁函数 | 现在住哪 |
|---|---|---|---|
| prismatic_five_thunder | ive_thunder | GrantFiveThunder → GrantFiveThunderPowers / SetFiveThunderCountdown / SetFiveThunderAvailability → EnsureFiveThunderMonitor（每帧）→ CheckFiveThunderTriggered | CenterTopBtnFuncExtra（原 04_buff） |
| prismatic_sea_overlord | grant_olympus_carrier | GrantOlympusCarrier（+ 留在 04 的 GetPlayerHomeSpawnPosition / MarkNextSpawnAsKnownPureDrawUnit） | CenterTopBtnFuncExtra（原 04_buff） |
| gold_cloudbreaker | grant_yaoguang | GrantYaoguang（+ RecordPlayerGrantedYaoguang） | CenterTopBtnFuncExtra（原 04_buff） |

发卡这一步本身就走新节点：FindRuneById / GetRuneCandidateUnitTypes / RandomIndex
（点选后 AddOwnedRune / MarkRoundSlot）全部在 lua/GAME/HextechRune/19_extra.lua。

**验收清单**

1. 第 1 回合能弹出三张卡（说明 FindRuneById / CreateRuneCandidateForPlayer 这条链没断）。
2. 三张都点得动、选完**不报错**（AddOwnedRune / OnRuneChosen 走得通）。
3. 五雷轰顶：神州座席应出现技能按钮（首次可用）；非神州座席只要不报错即可（那个协议是神州专属）。
4. 拿到五雷轰顶后的**下一个回合开始**不报错 —— 这条最关键：OnRoundBegin 里的
   OnFiveThunderRoundBegin 已经跨节点，靠空判兜底（A.84.3）。
5. 摇光 / 奥林帕斯航母：家里能刷出赠送单位，且不占生产限造。
6. 想顺带覆盖 BuildFilteredPool / PickThreeRunes 这条正式随机抽卡路径，就让这局继续打到
   正式海克斯回合（开局测试事件只覆盖前几回合的固定三选一）。

注意：gold_cash_reward（cash_reward → GrantCashRewardProtocol）在符文池里是**注释掉的**，
所以这次没法通过测试事件验证；	esla_air_assault 也不在池里。要验这两条只能临时放开池条目。
