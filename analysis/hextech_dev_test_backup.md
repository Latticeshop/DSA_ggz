# 海克斯符文：开发/测试用代码备份

发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。

> **当前状态（2026-10-24 发版清理）：已删除 —— 发版态。** 用户要求「去掉开局测试符文这块代码，准备发版」，
> 按 §1 的四处一次删净（顶部开关 / `ShowOpeningTestEvent` 整函数 / `OnRoundBegin` 的 `round == 1` 分支 /
> `01_rune_pool.lua` 末尾的 `FindRuneById`），脚本 `python analysis/_remove_opening_test.py`；
> 随后 `sync_scriptsdata.py` 回填、`_check_release_clean.py` 报「发版自检: 通过」。
> **本轮最后一版名单（第十批 / 第十一批）**：`gold_at_field`（金·AT立场，载具档）/ `gold_at_field`（同一 Id 的舰船档，
> 靠 `testUnitTypeByIndex = { "vehicle", "navy" }` 按格子顺序指派兵种）/ `gold_free_trade`（金·自由贸易）；
> 候选构造仍传 `ignoreFaction = true`（测试局跳过阵营过滤）。登神已让出测试位 —— `testTargetOverrides` 里那条
> `gold_ascension = "JapanNavyScoutShip"` 随函数一起删，池内登神与海军链路一行未动。
> 要复测就按 §1 原样贴回（`analysis/_patch_round.py` 是第八批的贴回脚本，锚点仍唯一、可重复执行；名单改成当轮要测的三张）。
>
> **上一轮状态（2026-10-19 第八批）：已贴回 —— 开发态。** 按 §1 原样贴回四处（顶部开关原 21-23 行、
> `ShowOpeningTestEvent` 原 782-844 行、`OnRoundBegin` 分支原 1267-1272 行、`01_rune_pool.lua` 末尾的
> `FindRuneById`），落盘脚本 `python analysis/_patch_round.py`（可重复执行，锚点都断言唯一）。
> 本轮名单（第八批）：`prismatic_back_to_basics`（彩·回归基本功，**顶掉原来的银·轮式大炮**）/
> `gold_oblivion_bomb`（金·湮灭炸弹）/ `gold_ascension`（金·登神，目标由苏霍伊截击机改成
> **帝国长枪迷你潜艇 `JapanNavyScoutShip`**，专测海军）。
> **2026-10-20 更正**：`JapanNavyScoutShip` 才是长枪迷你潜艇，`JapanAntiVehicleShip` 是薙刀驱逐舰
> （第一版写错，用户实测圈到薙刀）。模板名对照见《地图注释说明文档》附录 A.84.4。
> 选回归基本功是因为它 2026-10-19 拆成四兵种后标题变五字，正好顺带验卡面居中（与歌莉娅巨人同档）。
> 贴回后 payload：`01_rune_pool.lua` 57401 B（余 8135 B）、`02_event.lua` 56116 B（余 9420 B），
> `_verify_code_same.py` 报 code-changed = 0，本轮验收脚本 `analysis/_verify_opening_test_naval.py` 全绿。
> **发版前照旧整段删除**：`python analysis/_remove_opening_test.py` + 重新 `sync_scriptsdata.py` +
> `_check_release_clean.py` 复核（四处全部删净后它会重新报「发版自检: 通过」）。
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
- 开关（原 21-23 行，位于 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试：第 1 回合固定显示指定的三张符文。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestTriggered = false
```

- 事件本体（位于 `ShowFormalEvent` 之后，原 967-1032 行）：

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
    -- 长枪迷你潜艇的地编 ID 是 JapanNavyScoutShip（JapanAntiVehicleShip 是薙刀驱逐舰，别写错）；
    -- 它只在帝国座席的回收表里，其它座席拿到这张卡不会生效（调试用，不影响正式池）。
    local testTargetOverrides = {
        gold_ascension = "JapanNavyScoutShip",
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

- `OnRoundBegin` 里的触发分支（原 1457-1462 行，**必须**放在正式事件判断之前）：

```lua
    -- 开发测试：第 1 回合的固定三选一必须先于正式事件判断。
    if g_EnableHextechRune == 1 and self.EnableOpeningRealTest
        and not self.OpeningTestTriggered and round == 1 then
        self.OpeningTestTriggered = true
        self:ShowOpeningTestEvent()
    end
```

**复测用的固定三选一**：改 `testRuneIds` 即可；要固定某张「指定单位型」符文（登神 / 买二送一 / 究极生物）
的目标单位，在同函数里的 `testTargetOverrides` 加一行 `符文Id = "单位模板名"`（当前为
`gold_ascension = "JapanNavyScoutShip"`），它会在候选构造完之后覆盖随机目标。

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
   （秒速五厘米，当日新增的白银替换型符文；**2026-10-19 曾由银档改挂金档为
   `gold_five_centimeters`，同日又改回银档 `silver_five_centimeters`**）/ `prismatic_infinite_ammo`（无限火力）**——
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
   **2026-10-19 晚些时候再换一次（当前名单）**：用户要求把第二张「金·元神互锁」换成
   **`gold_oblivion_bomb`（金·湮灭炸弹）**，`testRuneIds` 现在是
   `{ "silver_wheeled_cannon", "gold_oblivion_bomb", "silver_divine_might" }`（银 / 金 / 银）。
   湮灭炸弹不带 `NeedsUnitType`、不限阵营、允许重复取得，所以六个座位都能摆满 3 张；
   这一局要验的是**选中后不立刻落弹**、只在 J 提示下方挂「按'K'键部署湮灭炸弹」，
   按 K（`ExtraCommand.lua` 的热键命令 75）消耗一次并在抽卡空投圆心 `(3547.06, 3055.49)`
   生成归属使用者的 `japanomegaoblivionbomb`、次数减 1，拿两份可连按两次。元神互锁本身没动，
   仍在金档池里正常可抽。
   同一天稍晚，**秒速五厘米又由金档改回银档**（`Rarity = 2 → 3`、Id 由
   `gold_five_centimeters` 改回 `silver_five_centimeters`，见设计文档 §7）；上面 2026-10-16
   那段里「Id 已改为 `gold_five_centimeters`」的说法请以银档 Id 为准。
   同样在这一天，**顺手的事也由金档降为银档**（`Rarity = 2 → 3`、Id 由 `gold_easy_does_it`
   改为 `silver_easy_does_it`，赌怪侧 `ExclusiveRuneIds` 同步改名），所以上面 2026-10-19 贴回
   那段里「`gold_easy_does_it`（顺手的事，金）」现在应读作银档 Id；多拿一张的流程与互斥都不变。
   **2026-10-19 第三批（当前名单）**：用户要求把第三张「银·神威」换成当日新增的
   **`gold_burn_furry`（金·烧福瑞）** 自己测，`testRuneIds` 现在是
   `{ "silver_wheeled_cannon", "gold_oblivion_bomb", "gold_burn_furry" }`（银 / 金 / 金）。
   烧福瑞**取符文时不会立刻触发**（`OnRuneChosen` 没有分支），要等回合开始那一次
   `ApplyRoundEffects`（出兵混编完成之后）才把对面步兵按比例换成警犬/战熊；点选一般排在
   这次结算之后，所以**基本要到下一回合才看得到效果**，这一局至少要打两回合；
   它按「同阵营份数」取比例（1/2/3 份 = 50%/75%/100%），单人拿不到第二份。
   测试事件按 Id 直取符文、不过筛池，因此**禁步兵模式下也会把它摆上来**（正常池里它 `RequiresType`
   会下架），这是预期行为。
    **2026-10-19 第四批（当前名单）**：用户要求把第三张「金·烧福瑞」换成 **`gold_ascension`
    （金·登神）**，并且**目标固定为苏霍伊截击机 `SovietInterceptorAircraft`**——`testRuneIds` 现在是
    `{ "silver_wheeled_cannon", "gold_oblivion_bomb", "gold_ascension" }`（银 / 金 / 金），
    另加一张 `testTargetOverrides = { gold_ascension = "SovietInterceptorAircraft" }`，在候选构造完之后
    直接把 `TargetUnitType / TargetUnitIndex / TargetUnitName` 改成苏霍伊（正式池仍按随机目标走）。
    这样能专门看**飞机吃登神**的链路：`AmmoAircraftUnitTypes` 登记了苏霍伊，所以卡面和播报会走
    带「弹药」的版本（T3 = 50% 档，五个维度随机命中一维）；苏霍伊只有**苏联座席**的回收表里有，
    其它座席这张卡不生效，属调试预期。烧福瑞本身没动，仍在金档池里正常可抽，验证脚本
    `analysis/_verify_burn_furry.py` 的测试名单断言已同步改成「已不含烧福瑞、名单仍三张」。
   **2026-10-19 第八批（当前名单）**：用户要求「开局测试里的一个改成回归基本功、一个改成登神潜艇」——
   第一张 **`silver_wheeled_cannon`（银·轮式大炮）→ `prismatic_back_to_basics`（彩·回归基本功）**
   （它同日拆成四兵种、标题变五字，顺便验卡面居中），第三张登神仍在，但 `testTargetOverrides`
   由 `SovietInterceptorAircraft` 改成 **`JapanAntiVehicleShip`（帝国长枪迷你潜艇）**，专测海军：
   `testRuneIds` 现在是 `{ "prismatic_back_to_basics", "gold_oblivion_bomb", "gold_ascension" }`
   （彩 / 金 / 金）。回归基本功带 `NeedsUnitType`，测试事件本来就会随机抽一个可用兵种（步兵 / 载具 /
   空军 / 海军之一），所以同一局重开可能拿到不同后缀的标题；**要专门验海军标题就把兵种禁到只剩海军**。
   长枪迷你潜艇的地编 ID 是 **`JapanNavyScoutShip`**（第一版误写成 `JapanAntiVehicleShip`，
   那是薙刀驱逐舰，2026-10-20 已改对），只在**帝国座席**的回收表里，其它座席这张登神不生效（调试预期）。轮式大炮本身没动，
   仍在银档池里正常可抽、与登神的改指链路照旧。
   **2026-10-24 第十批 / 第十一批（最后一版名单）**：这两批只改 `testRuneIds`、兵种指派与候选构造的跳过参数，
   三段代码本体没再动。第十批把「回归基本功」换成 **`gold_free_trade`（金·自由贸易）**、把「湮灭炸弹」换成
   **`prismatic_mass_production`（彩·大生产）**（名单 = 自由贸易 / 大生产 / 登神）；第十批之三给
   `CreateRuneCandidateForPlayer` 加第 4 个参数 `ignoreFaction`（只有测试事件传 `true`）；第十批之四把大生产
   下架留档、名单换回 `gold_oblivion_bomb`（自由贸易 / 湮灭炸弹 / 登神）；第十一批用
   **`prismatic_at_field`（彩·AT立场）** 顶掉湮灭炸弹，第十一批之二又把它降档成 **`gold_at_field`（金·兵种卡）**——
   同一 Id 摆两格、靠 `testUnitTypeByIndex = { "vehicle", "navy" }` 按格子顺序指派兵种，登神让出第三格：
   **最终名单 = AT立场(载具) / AT立场(舰船) / 自由贸易**。两轮的新卡（自由贸易、AT立场）都已在游戏内实测通过，
   2026-10-24 用户「去掉开局测试符文这块代码，准备发版」→ 按本文件整段删除；删除前的四处原文已同步进 §1，
   并逐字节存了两份快照 `analysis/_02_event_before_release_1024.lua` / `analysis/_01_rune_pool_before_release_1024.lua`。
2. **候选构造统一走正式入口**：上面 §1 的 `CopyRuneForCandidate` + 三类特殊符文的二次兜底
   已合并为一句 `self:CreateRuneCandidateForPlayer(playerIndex, template, unitType)`（§1 现在就是合并后的版本）。
   原因是新增的等价交换要在候选里**随机抽定两个兵种**（`NeedsUnitTypePair`），
   只复制模板会让它带着空兵种被点选、整张符文毫无效果。
   **2026-10-24 第十批之三**又给这个入口加了第 4 个参数 `ignoreFaction`：测试局传 `true`（苏联座席也能拿到大生产），正式路径不传。
3. **`FindRuneById` 也随之回归**：它当时和测试事件一起被删掉（`01_rune_pool.lua` 末尾，原 1249-1259 行，
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

> **`analysis/_verify_backup_doc.py` 现在对着「删除前快照」逐字校验**（2026-10-24 起）：它拿本文档 §1 的三段与
> `analysis/_02_event_before_release_1024.lua`（`02_event.lua` 删除前的完整副本）比对，第 4 段（`FindRuneById`）
> 对着 `analysis/_01_rune_pool_before_release_1024.lua` 比对；四处全中才算存档没走样，正常应报 `mismatch = 0`。
> 更早那份 `analysis/_02_event_before.lua`（2026-10-04）留作历史快照，不再参与校验（§1 的名单此后又换过多轮）。
