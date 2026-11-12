# 海克斯符文：开局测试三选一（开发用，发版前删除）

> **当前状态（2026-11，测试态——这段代码眼下就活在源码里）**：`testRuneIds` =
> `{ "prismatic_ultimate_creature", "gold_ascension", "silver_easy_does_it" }`，
> `OpeningTestRounds = 1`。本轮验的是「究极生物 / 登神不再全图播报，改成海克斯面板详情末尾的
> 数值后缀」：选完这两张后按 J 开面板、悬浮卡片看简介末尾有没有
> `(…%血量,…%伤害,…%攻速,…%射程)`（带弹药的飞机多一维 `…%弹药`），并且回合切换时**消息区不再刷
> 那两条加成播报**。第三格留银·顺手的事，用来对照旧的「（已生效）」后缀仍照常显示。
> ⚠ 上一轮（2026-10-31 银·MCV 收工）记录的「已删净、发版态」不再代表当前工作区。

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
-- 本轮测「究极生物 / 登神」的面板数值后缀：三格分别给 彩·究极生物 / 金·登神 / 银·顺手的事，
-- 顺带覆盖三种稀有度。前两张选完就能在 J 面板里看到详情末尾的 (…%血量,…%伤害,…%攻速,…%射程)。
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "prismatic_ultimate_creature",
        "gold_ascension",
        "silver_easy_does_it",
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
-- 开发测试用：按 Id 直接取符文池里的原始模板，绕过筛池（发版前与测试事件一并删除）。
-- 只服务于第 1 回合的开局自定义三选一（见 02_event.lua 的 ShowOpeningTestEvent）。
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

> **当前名单（2026-11：测「究极生物 / 登神」的面板数值后缀）**：
> `{ "prismatic_ultimate_creature", "gold_ascension", "silver_easy_does_it" }` ——
> 彩·究极生物 / 金·登神 / 银·顺手的事，`testUnitTypeByIndex` 与 `testTargetOverrides` 都留空
> （前两张都不带兵种，目标由 `PickUltimateCreatureTarget` / `PickBuyTwoGetOneTarget` 自己随机定）。
> **要验的三件事**：
> ①**选完立刻有后缀** —— 究极生物按选卡那一刻献祭到的 T1/T2 数量换算，面板详情末尾应出现
> `(…%血量,…%伤害,…%攻速,…%射程)`；一张 T1/T2 都没献祭到就不显示（不显示一排 0%）。
> ②**登神随回收增长** —— 每回合目标单位超出 1 个的部分继续转层，面板里的四维数值随之变大；
> 层数为 0 时不显示后缀。
> ③**消息区不再刷播报** —— 旧实现每次结算都会发一条「究极生物加成：…」/「（xxx）登神加成：…」，
> 现在回合切换时消息区应当**看不到**这两条（`BroadcastUltimateCreature` / `BroadcastAscension`
> 与 `AscensionBroadcastRound` 已删除）；顺手的事的「（已生效）」后缀仍照常显示，用来对照。
>
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
   `ShowOpeningTestEvent`、`OnRoundBegin` 分支、`FindRuneById`）。✔ 已删净
   （删净的判据：`01_rune_pool.lua` 去注释 51144 B、`02_event.lua` 去注释 54761 B，与上一版发版态一致）
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
