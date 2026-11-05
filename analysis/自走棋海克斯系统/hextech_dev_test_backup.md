# 海克斯符文：开局测试三选一（开发用，发版前删除）

> **当前状态（2026-10-31 收工）：发版态，§1 的四段代码已再次删净。**
> 本轮测的是银·MCV：`testRuneIds` = `{ "silver_mcv", "silver_mcv", "silver_mcv" }`，
> 触发窗口用 `HextechRune.OpeningTestRounds = 2`（第 1、2 回合各发一次同一组卡），
> 这样连着两回合各选一次就能看出「按已拥有阵营递进」有没有生效。
> 实测结论：第一版只登记了四个建造场基础名，**展开后的基地识别不出来**——引擎里同一个建造场有
> `_Enhanced` / `_Collapse` / 海军态等独立模板；改成按后缀生成后实测满意、逻辑正常（详见
> `analysis/地图注释说明文档.md` 补记之二·十一续 ⑥）。发放记录 `McvGrantedFactions` 试过又删了：
> 占地方且冗余，真正的缺口是建筑没扫上。
> 收工动作：删掉开关（`EnableOpeningRealTest` / `OpeningTestRounds` / `OpeningTestTriggered`）、
> `ShowOpeningTestEvent`、`OnRoundBegin` 的测试分支、`01_rune_pool.lua` 的 `FindRuneById`。
> 鸡汤来咯的投毒调试日志（`IrradiateDebug` / `IrradiateLog`）与电脑补兵日志（`AICOMP.Debug` / `AICOMP.Log`）
> 更早前就已删掉，这次没有贴回。

发版态下 `lua/` 与 `ScriptsData.json` 中没有这段代码。需要复测某几张符文时，按本文把下面几段贴回源码，再跑 `python sync44.py --map 44` 同步。

## 1. 代码块

**位置：`lua/GAME/HextechRune/02_event.lua`**

- 开关（放在 `HextechRune.RarityFrameImageIds` 之后）：

```lua
-- 开发测试开关：开局前几回合固定显示指定的三张符文（发版前整段删除）。
-- OpeningTestRounds = 2 表示第 1、2 回合各发一次同一组三张卡；只测一次就改成 1。
HextechRune.EnableOpeningRealTest = true
HextechRune.OpeningTestRounds = 2
HextechRune.OpeningTestTriggered = {}
```

- 事件本体（放在 `ShowFormalEvent` 之后）：

```lua
-- 开发测试：第 1 回合固定三选一，展示 testRuneIds 指定的符文。
function HextechRune:ShowOpeningTestEvent()
    local testRuneIds = {
        "gold_at_field",
        "gold_at_field",
        -- 2026-10-30：第三格由 gold_free_trade 换成银·鸡汤来咯，验「回合开始敌方随机 1 个载具
        -- 获得毒质腐蚀」这条新链路（不再是协议、不再给基地，改由本方 AI 阵营借 spellbook 下命令）。
        "silver_chicken_soup",
    }
    -- 兵种卡一次摆两张时按顺序指派兵种，其余兵种卡仍走随机。
    local testUnitTypeByIndex = { "vehicle", "navy" }
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

> **当前名单（2026-10-31 末轮：测 MCV，已测完并删除）**：`{ "silver_mcv", "silver_mcv", "silver_mcv" }` ——
> 三格都是 **银·MCV**（`Effect = "grant_foreign_mcv"`，实现见 `lua/GAME/HextechRune/04_buff.lua: GrantForeignMCV`），
> `testUnitTypeByIndex` 与 `testTargetOverrides` 都留空。
> **这张卡要验的三件事**：
> ①**没拥有的阵营才会给** —— 选卡后基地车落在自家水边的前哨站（`PureDrawGetOutpostDropPosition`），
> 阵营应该是「你还没有的那几族」之一（自身阵营永远算已有）；
> ②**抽卡抽到的基地车也算已有** —— 场上已有某族基地车（哪怕是从抽卡池抽出来的、还没展开），就不会再发该族；
> ③**展开成建造场之后仍算已有** —— 把发到的基地车展开，下一轮再选 MCV 时不该又发同一族
> （判定扫的是「基地车单位 + 建造场建筑」，建造场按 `前缀 + ConstructionYard + 后缀` 把
> `_Enhanced` / `_Collapse` / 海军态等变体全登记）。
> 三件事都过 = `GetPlayerMcvFactions` 的扫描口径正确。**实测结果：第一版 ③ 没过（只认了基础名），
> 补上后缀变体后满意、逻辑正常。**
> **鸡汤来咯复测记录（2026-10-31，已收工）**：十一测「开局三选一 + 一回合出兵」全绿 ——
> 投毒在敌方随机载具/舰船上生效，`[汤]poison 1/1 try1 st IRRADIATED` 证实中毒状态名是
> `IRRADIATED`，预设守护神（`Overlordtank` 等六个）与技能召唤单位已被排除出候选。
> 收工后代码里已删除 `HextechRune.IrradiateDebug` / `IrradiateLog` 及全部日志调用，
> 现在只看实际效果；要再定位问题时临时把日志加回去即可。

## 3. 发版前清理（2026-10-31 已执行两次，最后一次为 MCV 收工）

1. 删掉上面四处代码（开关 `EnableOpeningRealTest` / `OpeningTestRounds` / `OpeningTestTriggered`、
   `ShowOpeningTestEvent`、`OnRoundBegin` 分支、`FindRuneById`）。✔ 已删净
   （删净的判据：`01_rune_pool.lua` 去注释 51144 B、`02_event.lua` 去注释 54761 B，与上一版发版态一致）
2. 删掉两类调试日志：鸡汤来咯的 `HextechRune.IrradiateDebug` / `IrradiateLog`（含 8 处调用）、
   电脑补兵的 `AICOMP.Debug` / `AICOMP.Log`（含 3 处调用与只为日志服务的 `AICOMP.BandNames` /
   `WasPoolFallback` / `PoolFallback`）。✔ 已删
3. 回填 `ScriptsData.json`：在仓库根目录跑 `python sync44.py --map 44`（`sync_scriptsdata.py` 需要 `--map` 指定 4v4 的 JSON，根目录的 `sync44.py` 就是它的封装）。
4. `grep -n "EnableOpeningRealTest\|ShowOpeningTestEvent\|FindRuneById\|IrradiateLog\|AICOMP.Log" lua/GAME/HextechRune/*.lua lua/LUABOX/AI/*.lua` 确认全部已删净。
5. 复核：`python audit44.py`（DRIFT 里不应再出现 `02_event.lua` / `01_rune_pool.lua`）、`python check_payload_lua4.py` 同口径的 Lua 4.0 体检通过。

> 恢复前先 grep：常见情况是只干跑过清理、代码其实还在。
