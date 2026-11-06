# AICOMP（电脑席位）出兵策略优化方案

> 目标地图：`DSA_ggz/DSA_XXX%COR_44/ScriptsData.json`（4v4 现行地图）
> 术语：**电脑** = 玩家席位上的遭遇战 AI（`AI[seat]==1` 且 `P[seat]~=nil`）；**AI** = 场地中间的两个电脑营地 `PlyrCivilian`(7) / `PlyrCreeps`(8)，所有战场单位都归它们。
> 本文第 1、2 章的行号是改动前的现状行号；**第 5 章是实现记录**（7 项全部已落盘、已同步、已过校验）。

---

## 0. 结论摘要

| # | 需求 | 落点 | 状态 |
|---|---|---|---|
| 1 | 池子写入要触发海克斯符文（买二送一 / 登神等） | 新增 `HextechRune:CollectPoolUnits`；`AICOMP.AddRandomUnits` 改走它 | ✅ 已实现 |
| 2 | 参照对象均衡分配 + 掉线重挑 | 重写 `AICOMP.GetReference` → `AICOMP.AssignReferences` | ✅ 已实现 |
| 3 | 模仿参考玩家的出兵等级（快照式） | 新增 `AICOMP.TierShown` + `SnapshotTiers`，取阶级时读快照 | ✅ 已实现 |
| 4 | 摇光 3 / T4 大船 2 上限对电脑生效 | 新增 `AICOMP.CapCount` / `CapGroups` + 候选池过滤 | ✅ 已实现 |
| 5 | 电脑科技到 T4 自动视为「+1 星」 | 新增 `AICOMP.ApplyT4Reward` | ✅ 已实现 |
| 6 | 纯抽卡模式（`g_DrawMode == 2`）下只对总数量 | 新增 `AICOMP.ApplyDrawModeSeat` + `AddAnyTierUnits` + 谓词 `IsPureDrawMode` | ✅ 已实现 |
| 7 | 电脑模仿对方技能释放（每跳一台、逐跳对拼、CD 各自独立；自选技能组模式下电脑先对着一组；阵营技能也镜像） | `ButtonManager` 两处共享冷却判断 + `CenterTopBtnFunc` 打标/回调 + `AICOMP.MirrorSkillCast` / `EnsureSeatButton` / `OnSkillGroupAssigned` | ✅ 已实现 |

**改动文件（4 个，全部已有 `sync_scriptsdata.py` 的 TARGETS 条目，不需要新建 payload 节点）**

| 文件 | 改动前 payload | 改动后 payload | 余量 |
|---|---|---|---|
| `lua/LUABOX/AI/AIINI_1.lua` | 16653 B（无需去注释） | 35029 B | 30507 B |
| `lua/LUABOX/BUTTON/ButtonManager.lua` | 11278 B | 11646 B | 53890 B |
| `lua/LUABOX/BUTTON/CenterTopBtnFunc.lua` | 67068 B → 去注释 60293 B | 67068 B → 去注释 62007 B | 3529 B |
| `lua/GAME/HextechRune/06_ascension.lua` | 15402 B | 17379 B | 48157 B |

> 特别说明：**不要**往 `04_buff.lua` 里加东西。它去注释后已经 63648 B，距 65536 B 硬上限只剩 1888 B。这也是 `CollectPoolUnits` 没有放进 `04_buff.lua` 的原因。

---

## 1. 现状实测

### 1.1 调用链

```
huihe/spawn            lvc++  → RoundLuaManager._begin() → ENABLE_SCRIPT(AIUNITBUILDACT)
AIUNITBUILDACT__0      （EVERY=35 帧，无 IsActive 键 ⇒ 默认启用）→ spinfantlv1() 等 4 个入口
                       ↓ 全部幂等收敛到
LandArmySpawn()        ← ACTSPUNIT / AIADDDELAY(1s)
  └─ AICOMP.EnsureRound()        ← 唯一真正干活的地方（按 lvc 去重）
  └─ UNITSPST(...)               ← 按波段刷兵，读 UNITCOUNT[seat][idx]
```

### 1.2 唯一写池出口

`AICOMP.AddRandomUnits`（`AIINI_1.lua:408-427`）：

```lua
for i = 1, amount, 1 do
    local unitIndex = pool[RANDOMGENERATE(total, 1)]
    UNITCOUNT[seat][unitIndex] = (tonumber(UNITCOUNT[seat][unitIndex]) or 0) + 1
    added = added + 1
end
if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[seat] ~= nil then
    ANYUNITCOUNT[seat] = (tonumber(ANYUNITCOUNT[seat]) or 0) + added
end
```

**它绕过了真人的全部入池管线。** 真人的管线在 `UNITCOUNTERINI_0.lua:640 unitgetcountanddelet`：

| 步骤 | 函数 | 作用 | 电脑现状 |
|---|---|---|---|
| 1 | `HextechRune:FilterAscensionUnits`（`06_ascension.lua:260`） | 登神：池内已有种子时本批单位不进池，转层数 | ❌ 缺失 |
| 2 | `HextechRune:ResolveCollectedUnitIndex`（`18_basics_exchange.lua:237`） | 替换型符文（银·双管齐下、狂热武士 50%）改槽位 | ❌ 缺失 |
| 3 | `UNITCOUNT++ / ANYUNITCOUNT++` | 计数 | ✅（自己实现） |
| 4 | `HextechRune:OnPlayerUnitCollected`（`04_buff.lua:870`） | 买二送一：每 2 个赠 1 | ❌ 缺失 |
| 5 | `HextechRune:TrimAscensionPoolSurplus`（`06_ascension.lua:241`） | 登神超种子裁剪到 1 | ❌ 缺失 |

### 1.3 参照对象

`AICOMP.GetReference`（`AIINI_1.lua:42-74`）：优先对面真人，否则任一真人，**随机挑一个**并缓存；只在「缓存席位不再是真人」时重挑。

- ❌ 无均衡：4 真人 + 4 电脑时可能出现 4 台电脑全模仿同一个真人。
- ❌ 掉线无感知：`AI[]` 在 `AID_0.lua` 里只在开局算一次，真人掉线后 `IsHumanSeat` 仍返回 `true`。

### 1.4 阶级

`CollectCategoryState`（`AIINI_1.lua:274`）每回合现算「该段最高阶级」`MaxTier`，`ResolveCategoryTier`（`:299`）取 `min(MaxTier, 本方科技等级)`。

- ❌ 实时值：参考玩家只是这一回合没造 T3，电脑立刻掉回 T2；需求要的是「参考展示过的最高等级」记忆。

### 1.5 上限

| 上限 | 常量 | 位置 | 电脑现状 |
|---|---|---|---|
| 摇光 3 | `YAOGUANG_LIMIT = 3` | `MONEYINI_3.lua:21`，`LIMITYAOGUANG()` 关建造按钮 | ❌ 只关真人建造按钮，电脑池子照加 |
| T4 大船 2 | `BIGSHIP_LIMIT = 2` | `UNITCOUNTERINI_0.lua`，`LIMITBIGSHIP()` 关建造按钮 | ❌ 同上 |

### 1.6 T4 星级

真人拿到「+1 星」的真实条件是地编节点 `Player_N/LEVELUP`：

```
IF PLAYER_HAS_NUMBER_OBJECTS_WITH_MODELCONDITION(<This Player>, 2, 0, STRUCTURE_UNPACKING)
   AND PLAYER_HAS_OBJECT_COMPARISON(<This Player>, 4, 0, htech)
   AND PLAYER_HAS_OBJECT_COMPARISON(<This Player>, 4, 0, tech)
THEN ENABLE_SCRIPT(/LEVELUP7)  ; DISABLE_SCRIPT(LEVELUP)
```

→ `LEVELUP7_0.lua` 里 `LEVELUP[7] = LEVELUP[7] + 1` → 出兵时 `TEAM_GAIN_LEVEL(UNITTEAM[side][n], LEVELUP[side])`。

**关键结论**：星级是**按边（side）生效**的，不是按席位。一个席位满足条件，全边 4 人的出兵队伍都升星。所以电脑侧的特例可以完全对齐这个口径：只要某个电脑席位达到 T4，就给它的边 `LEVELUP[side] + 1`（每个席位每边各一次，最多 +4，与真人 4 个 `LEVELUP` 节点对称）。

另外 `Player_N/UNLOCK3__N` 还会置 `g_PlayerT4TechUnlocked[N] = true`（`UnitCreate.lua` 的 `IsYaoguangBattleSideT4Unlocked` 用它判断摇光是否只活 1 回合），电脑也一并补上。

### 1.7 技能

- 技能组：6 组 × 2 个，`CenterTopBtnFunc_CreatePlayerSkillButtons(playerIndex, kind)`（`CenterTopBtnFunc.lua:391`），全部用 `ButtonIndex = 1` 和 `2`。
- **电脑席位也有按钮**：`BUTTON_0.lua:21-22` 对 `i = 1..8` 无条件调用 `CenterTopBtnFunc_CreateInitialButtons(i)`；技能组序号由 `BtnChoiceDialogEventFunc_GetSkillIndexForPlayer` 给，注释里明确写「真人、电脑都算（电脑也吃技能组）」。
- 所有点击都收敛到 `ButtonManager.lua:190` 的包装函数 `buttonData.OnClick`：

```lua
buttonData.OnClick = function(self)
    if not self.IsEnabled then return end
    if not self:_multipleUseOnClick() then return end   -- 真技能函数
    if self.SharedCooldownId then ButtonManager:SharedCooldown(self) end
    self._usedCount = self._usedCount + 1
    ...
```

→ **只要在这一个函数里加钩子，人类的所有技能释放都能被感知，且能原样借用次数/冷却/共享冷却机制。**

技能组对照表：

| kind | ButtonIndex=1 | ButtonIndex=2 |
|---|---|---|
| 1 | 局部毁灭 `RequestDestruction`（全局 1 次） | 达摩克利斯之剑 `RequestDamoclesSword`（2 次） |
| 2 | 铁幕演说 `RequestIronCurtain`（2 次） | 时空管理局 `RequestTimeStop`（2 次） |
| 3 | 龙行天下 `RequestDragonShip`（2 次，第 5 回合解锁） | 空军元帅 `RequestAirMarshal` |
| 4 | 立即出兵 `RequestSpawnArmyImmediately` | 纳米虫巢 `RequestNanoMaintainHive` |
| 5 | 九头蛇万岁 `RequestHydra`（全局 1 次） | 冰天雪地 `RequestSnowstorm`（2 次） |
| 6 | 复制敌方特殊能力 `RequestRepeatEnemySpecialPower` | 复制本方特殊能力 `RequestRepeatSelfSpecialPower` |

---

## 2. 七项需求逐条设计

### 需求 1：池子写入触发海克斯符文

#### 设计

新增一个「单批次入池」函数，逻辑与 `unitgetcountanddelet` 对真人单位做的处理**逐步对齐**，放在 `06_ascension.lua` 尾部（它去注释后只有 12824 B，空间充足，而且登神相关的两个 helper 就在这个文件里）：

```lua
-- 电脑（AICOMP）直接写 UNITCOUNT 时走这一条，口径对齐 unitgetcountanddelet：
--   1) 替换型符文改槽位（银·双管齐下 / 狂热武士 50%）
--   2) 登神：池内已有种子时这只不占池，直接转层数
--   3) 入池计数
--   4) 买二送一进度
--   5) 登神超种子裁剪到 1
-- 返回实际进池数量（转层数的不算）。
function HextechRune:CollectPoolUnits(playerIndex, unitIndex, amount)
    if unitIndex == nil or UNITCOUNT == nil or UNITCOUNT[playerIndex] == nil then
        return 0
    end
    local added = 0
    for i = 1, amount, 1 do
        local targetIndex = self:ResolveCollectedUnitIndex(playerIndex, unitIndex)
        if targetIndex ~= nil then
            if self:AbsorbBuyTwoGetOneBonus(playerIndex, targetIndex) then
                -- 登神：池内已有种子 ⇒ 转层数，不占池。
                self:OnPlayerUnitCollected(playerIndex, targetIndex)
            else
                UNITCOUNT[playerIndex][targetIndex] =
                    (tonumber(UNITCOUNT[playerIndex][targetIndex]) or 0) + 1
                if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[playerIndex] ~= nil then
                    ANYUNITCOUNT[playerIndex] = (tonumber(ANYUNITCOUNT[playerIndex]) or 0) + 1
                end
                added = added + 1
                self:OnPlayerUnitCollected(playerIndex, targetIndex)
            end
        end
    end
    self:TrimAscensionPoolSurplus(playerIndex)
    return added
end
```

`AbsorbBuyTwoGetOneBonus`（`06_ascension.lua:227`）的语义正好就是「登神目标 + 池内已有 ≥1 → +1 层，返回 true」，直接复用，不新增判定。

#### 完整性核对：`unitgetcountanddelet` 里的**全部**外部钩子（第 640-753 行逐一列出）

| 行 | 钩子 | 电脑侧处理 |
|---|---|---|
| 671 | `HextechRune:FilterAscensionUnits`（登神：把**实体**单位转层数） | 电脑没有实体单位，等价语义由 `AbsorbBuyTwoGetOneBonus`（登神目标 + 池内已有种子 → 转层数）覆盖 ✅ |
| 692 | `HextechRune:ResolveCollectedUnitIndex`（替换型符文改槽位） | 直接调用 ✅ |
| 700/709 | `g_PureDrawProducedUnitIds`「哪些单位是真人造的」记账 | 电脑单位没有实体，无需登记；且电脑不显示生产配额（`PureDrawSpawnQuotaWall` 对电脑直接 return）— 不适用 ⚪ |
| 725 | `HextechRune:OnPlayerUnitCollected`（买二送一进度） | 直接调用 ✅ |
| 740 | `HextechRune:TrimAscensionPoolSurplus`（登神超种子裁到 1） | 每批结束时调用 ✅ |
| 769/785 | `PureDrawReapplyPlayerQuota`（重算抽卡生产额度） | 电脑没有额度墙 — 不适用 ⚪ |

结论：所有会改变「单位池内容/符文进度」的钩子都已覆盖；未覆盖的两个是纯真人生产配额相关，电脑本来就不参与。

`AddRandomUnits` 改成：

```lua
function AICOMP.AddRandomUnits(seat, band, tier, amount)
    ...
    local pool = AICOMP.GetCandidatePool(seat, tier, band)
    ...  -- 选单位仍在这里做
    for i = 1, amount, 1 do
        local unitIndex = ...
        AICOMP.CollectUnit(seat, unitIndex)
    end
end

-- 统一入池出口：有符文系统就走符文管线，没有就纯计数（保持可单独运行）。
function AICOMP.CollectUnit(seat, unitIndex)
    if HextechRune ~= nil and HextechRune.CollectPoolUnits ~= nil then
        return HextechRune:CollectPoolUnits(seat, unitIndex, 1)
    end
    if UNITCOUNT == nil or UNITCOUNT[seat] == nil or unitIndex == nil then
        return 0
    end
    UNITCOUNT[seat][unitIndex] = (tonumber(UNITCOUNT[seat][unitIndex]) or 0) + 1
    if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[seat] ~= nil then
        ANYUNITCOUNT[seat] = (tonumber(ANYUNITCOUNT[seat]) or 0) + 1
    end
    return 1
end
```

#### 为什么不调 `unitgetcountanddelet` 本体

那条路要求场上有真实单位实体可数，电脑没有实体。所以是「复用同一批符文钩子」，不是「复用同一个函数」。

#### 时机

`EnsureRound` 在 `LandArmySpawn()` 第一行，早于 `UNITSPST` 刷兵 —— 买二送一的赠品会被当回合刷出来，与真人同步。**符文侧时序不需要改。**

#### 副作用与风险

- 买二送一：电脑池子会多出约 50% 的赠品，总量会略超模仿对象。这是「与真人一致」的必然结果，`need = refTotal - ownTotal` 的差值算法天然会在下一回合少补。**不做特殊抑制。**
- 登神：电脑池内同一槽位最多 1 个种子 + N 层，与真人一致。
- `01_rune_pool.lua` 的 `PickBuyTwoGetOneTarget` 只对**真人**挑目标吗？→ 需在实现时确认；若它只给真人挑，电脑的 `PlayerBuyTwoGetOneProgress` 为空表，`OnPlayerUnitCollected` 直接 return，无副作用（安全）。

### 需求 2：参照对象均衡分配 + 掉线重挑

#### 数据

```lua
AICOMP.Reference = AICOMP.Reference or {}   -- aiSeat -> humanSeat（保留字段，语义不变）
```

不再每回合随机，改成「先到先得 + 缺失时按最少引用补位」。

#### 可用真人判定（新增）

```lua
-- 可作为模仿对象：真人席位 + 没退出（资产已被队友继承、池子已清零）+ 没被推平。
function AICOMP.IsReferenceEligible(seat)
    if not AICOMP.IsHumanSeat(seat) then
        return false
    end
    -- 掉线/阵亡：MONEYINI_3 的 TransferPlayerAssets / LosePlayerAssets 会先置该标记，
    -- 再把他名下 UNITCOUNT / ANYUNITCOUNT 清零或转给继承者。
    if g_PowerSlotVacated ~= nil and g_PowerSlotVacated[seat] == 1 then
        return false
    end
    if g_AutoSurrender ~= nil and g_AutoSurrender.PlayerNowDied ~= nil
        and g_AutoSurrender.PlayerNowDied[seat] == 1 then
        return false
    end
    return true
end
```

两个信号，主用第一个：

| 信号 | 谁维护 | 时机 | 说明 |
|---|---|---|---|
| `g_PowerSlotVacated[seat] == 1` | `MONEYINI_3.lua` 的 `TransferPlayerAssets` / `LosePlayerAssets` | **掉线当帧**（引擎转交可能延后几秒复查） | 一置位紧接着就 `TransferPlayerUnitPools` / `ZeroPlayerUnitPools`，把 `UNITCOUNT` / `CRATEUNITCOUNT` / `ANYUNITCOUNT` 全部清零（有继承者时先加给队友） |
| `g_AutoSurrender.PlayerNowDied[seat] == 1` | `CenterTopBtnFunc_InitializeAutoSurrender` 每 X 帧 | 建筑寄存器数量归零时 | 兜底，覆盖「没经过法术书死亡流程」的情况 |

**为什么必须换人**：掉线者的 `UNITCOUNT` 被清零后，`ApplySeat` 算出来每段都是 `need = 0 - 自己 <= 0`，
直接 return——电脑不是「少出兵」，而是**彻底停止出兵**，而且是永久性的（每回合都一样）。
所以资格判定必须每回合重跑一遍，不能只在开局算。

#### 分配算法（新增 `AICOMP.AssignReferences`）

```
1. 扫 1..8：收集 eligibleHumans[]，并按边分 bySide[7] / bySide[8]。
2. 扫 1..8 的电脑席位 aiSeat：
     a. 若 Reference[aiSeat] 仍 eligible ⇒ 保留（不打扰已稳定的对应关系）。
     b. 否则记进 needs[]。
3. needs 为空 ⇒ 返回（绝大多数回合走这条，零开销）。
4. 对 needs 里的每个 aiSeat（按席位号顺序）：
     - 候选池 = bySide[对边]（非空），否则 = eligibleHumans。
     - 统计当前「被引用次数」：遍历所有电脑席位，Reference[s] 属于候选池则 +1。
     - 取引用次数最少的候选；并列时取第一个，但**并列集合内部随机**（RANDOMGENERATE）。
     - Reference[aiSeat] = 选中项。
```

效果对照需求给的例子：

- 4 真人（1,2,3,4）+ 4 电脑（A,B,C,D），电脑全在对面：
  第 1 个电脑看到 4 人引用次数都是 0 → 随机取一个（比如 2）；第 2 个看到 2 号已是 1 次、其余 0 → 只能在 0 次里取；……自动铺成 4 对 1。
- 3 真人（1,2,3）+ 5 电脑：前 3 台铺满一人一个，第 4 台看到三人各 1 次 → 随机取一个，第 5 台同理。即 `D-?`、`E-?` 随机落在 1/2/3 上。
- 中途 2 号掉线：3、4 号电脑的 Reference 失效 → 进 needs；此时 1、3 各被引用 1~2 次，按最少引用补位，最终重新摊平。

**注意**：`needs` 里的席位在处理时会依次把引用次数写进 `Reference`，后续席位立刻能看到前者的选择，所以顺序处理天然是贪心铺平，不需要两轮。

#### 一个真人都没有时

`eligibleHumans` 为空（真人全掉线 / 全被推平）时，**把所有电脑席位的 `Reference` 和 `TierShown` 清空**，
退回「每段各 +1 个 T1」的老行为。不清就会永远照着池子已清零的死人算 `need <= 0`，电脑从此挂机到结束。

#### 与 `GetReference` 的关系

`ApplySeat` 直接读 `AICOMP.Reference[aiSeat]`。原来的 `AICOMP.GetReference` 兼容包装已删除
（没有调用者，而且它会意外触发一次全局重排）。

### 需求 3：模仿参考玩家的出兵等级（快照式，单调只升）

#### 数据

```lua
-- aiSeat -> { [band] = tier }：模仿对象"展示过"的最高阶级，只升不降。
AICOMP.TierShown = AICOMP.TierShown or {}
```

#### 流程

`EnsureRound` 每个电脑席位每回合先做一次快照（`AICOMP.SnapshotTiers(aiSeat, refSeat)`）：

```lua
function AICOMP.SnapshotTiers(aiSeat, refSeat)
    local shown = AICOMP.TierShown[aiSeat]
    if shown == nil then
        shown = {}
        AICOMP.TierShown[aiSeat] = shown
    end
    local refState = AICOMP.CollectCategoryState(refSeat)
    for band = 1, AICOMP.CategoryCount, 1 do
        local tier = refState.MaxTier[band]
        if tier > 0 and (shown[band] == nil or tier > shown[band]) then
            shown[band] = tier
        end
    end
end
```

`ResolveCategoryTier` 的入参 `refTier` 改传 `shown[band]`：

```lua
local refTier = shown[category]
if refTier == nil then
    refTier = refState.MaxTier[category]   -- 还没快照到时用现算值
end
```

#### 语义

- 参考玩家科技到 T3、电脑科技只有 T2 → `min(T3, 2) = 2`，电脑出 T2（与需求一致）。
- 参考玩家这一回合没造 T3，但只要**曾经**造过，`shown` 仍是 3 → 电脑继续出 T3。这就是「多一个科技模仿」的记忆。
- 参考玩家换人（掉线重挑）时，`TierShown[aiSeat]` 应当**清空**重置，否则会带着上一个人的记忆。→ 在 `AssignReferences` 里发现 Reference 变化时 `AICOMP.TierShown[aiSeat] = nil`。

### 需求 4：摇光 3 / T4 大船 2 上限对电脑生效

#### 计数口径

需求写的是「符文给的不算计数」，因此**不能**直接数 `UNITCOUNT`（那是实有数，含符文赠送），要单独记「电脑自己塞了多少」：

```lua
-- seat -> { [groupIndex] = 已由 AICOMP 投放的数量 }
AICOMP.CapCount = AICOMP.CapCount or {}
```

#### 上限组定义

```lua
-- 建成一次的表：[{ Indexes = {槽位...}, Limit = N }]
AICOMP.CapGroups = nil

function AICOMP.EnsureCapGroups()
    if AICOMP.CapGroups ~= nil then
        return AICOMP.CapGroups
    end
    local groups = {}
    if g_UnitNameToUnitIndex ~= nil then
        -- 1) 摇光 3：普通型与加强型共用一个单位池槽位（LIMITYAOGUANG 同时关这两个建造项），
        --    计数走 g_PlayerProducedYaoguangCount，槽位只有一个。
        local yaoguang = g_UnitNameToUnitIndex["CelestialAdvanceAircraftTech4"]
        if yaoguang ~= nil then
            tinsert(groups, { Limit = 3, Indexes = { yaoguang } })
        end
    end
    -- 2) T4 大船 2：step35+1 .. step35+4 四艘反建筑船共享 2 个名额
    --    （UNITCOUNTERINI_0.lua:865 的 bigshiplimitc 就是把这四个槽位加起来比的）。
    if step35 ~= nil then
        local ships = {}
        for unitIndex = step35 + 1, step35 + 4, 1 do
            if UNITLIST == nil or UNITLIST[unitIndex] ~= nil then
                tinsert(ships, unitIndex)
            end
        end
        if getn(ships) > 0 then
            tinsert(groups, { Limit = 2, Indexes = ships })
        end
    end
    AICOMP.CapGroups = groups
    return groups
end
```

> `step35` 是 `SPUNITINI_0.lua` 里现成的分段常量（实测 `step35 = 107`，即空军段止于 107）。`step35+1 .. step35+4` 就是 `JapanAntiStructureShip` / `SovietAntiStructureShip` / `AlliedAntiStructureShip` / `CelestialAntiStructureShip` 四艘反建筑大船，槽号 **108/109/110/111**；`UNITCOUNTERINI_0.lua:865` 的 `bigshiplimitc` 正是把这四个槽位相加后与 `BIGSHIP_LIMIT` 比较——范围已核实。`_Enhanced` 船没有独立槽位、也不在 `UNITLIST` 里（`g_UnitNameToUnitIndex["…_Enhanced"]` 为 nil，只存在于 `g_PureDrawProductionAliases`），因此它们根本进不了电脑候选池，上限组只需要这 4 个基础槽。`JapanGigaFortressShipEgg` 虽然也是 `IsBigShip`，但不在真人的 4 个计数槽内（`03_quota.lua:91-94` 对它单列例外），故同样不进本上限组——两边口径保持一致。
> 摇光 `CelestialAdvanceAircraftTech4` 的槽号是 **103**，`CelestialAdvanceAircraftTech4_Enhanced` 由 `g_UnitNameToUnitIndex` 映射到**同一个** 103（`UNITCOUNTERINI_0.lua:340-353` 显式别名 + 扩 `FilterLIST.IncludeThing`），所以上限组里只放一个下标即可（与 `g_PlayerProducedYaoguangCount` 只认实际生产的口径一致）。
> 另一个口径印证：真人的两个上限都**只算玩家自己生产的**（摇光判定 `ObjectGetProducerObject(unitId) ~= nil`，见 `UNITCOUNTERINI_0.lua:698-721`；箱子/符文赠送无生产者，只进 `UNITCOUNT` 不占额），所以电脑侧「只统计 AICOMP 自己投放的」不是新发明的口径，而是照抄。

#### 候选池过滤

`GetCandidatePool` 的结果是**跨席位共享的缓存**（`PoolKey` 不含 seat），不能在里面按席位过滤。改为在 `AddRandomUnits` 里做一次性过滤：

```lua
function AICOMP.FilterCappedIndexes(seat, pool)
    local groups = AICOMP.EnsureCapGroups()
    local caps = AICOMP.CapCount[seat]
    if caps == nil then
        return pool
    end
    local filtered = {}
    for i = 1, getn(pool), 1 do
        local unitIndex = pool[i]
        local blocked = false
        for g = 1, getn(groups), 1 do
            if (caps[g] or 0) >= groups[g].Limit
                and AICOMP.IndexOfUnit(groups[g].Indexes, unitIndex) then
                blocked = true
                break
            end
        end
        if not blocked then
            tinsert(filtered, unitIndex)
        end
    end
    return filtered
end
```

投放成功后 `AICOMP.CapCount[seat][g] = (… or 0) + 1`（在 `AddRandomUnits` 里，与 `CollectUnit` 同步）。

#### 行为

- 摇光投放满 3 个后，摇光从该电脑的候选池里彻底消失（该段还有别的 T4 空军可用，不会空转）。
- 大船共享 2 个名额：投满 2 艘后四艘大船一起出局。
- 符文送的摇光/大船不进 `CapCount`，因此电脑实有数量可以超过 3 / 2 —— 与真人（符文送的可以堆到 4 艘）一致。

### 需求 5：电脑科技到 T4 自动「+1 星」

```lua
AICOMP.T4Rewarded = AICOMP.T4Rewarded or {}   -- seat -> 1

function AICOMP.ApplyT4Reward(seat, techLevel)
    if techLevel < 4 or AICOMP.T4Rewarded[seat] == 1 then
        return
    end
    AICOMP.T4Rewarded[seat] = 1
    -- 1) 对齐 Player_N/UNLOCK3__N：摇光不再「只活 1 回合」。
    g_PlayerT4TechUnlocked = g_PlayerT4TechUnlocked
        or { false, false, false, false, false, false, false, false }
    g_PlayerT4TechUnlocked[seat] = true
    -- 2) 对齐 Player_N/LEVELUP：整边 +1 星（与真人建 htech+tech 的效果同口径）。
    if LEVELUP ~= nil then
        local side = g_SeatToSide(seat)
        if side ~= nil then
            LEVELUP[side] = (tonumber(LEVELUP[side]) or 0) + 1
        end
    end
end
```

在 `EnsureRound` 里，`techLevel` 算出来后先调一次 `ApplyT4Reward(seat, techLevel)`，再 `ApplySeat`（保证本回合刷出来的队伍就吃到星级）。

- 每个电脑席位只吃一次，每边最多 +4，与真人侧 4 个 `LEVELUP` 节点对称。**（已确认为最终口径：「和真人对齐，一台电脑 +1 星」）**
- 真人不变：真人仍然必须自己造出 `htech` + `tech` 才吃 `LEVELUP`。
- **不看模式**（已确认）：`ApplyT4Reward` 只在 `techLevel >= 4` 时触发，不加任何模式判断。死亡模式/缩小模式下 `GetSideTechLevel` 直接返回 4 ⇒ 第一回合就给星，与「科技全开」语义一致（真人侧在死亡模式下本来也只要建这两座建筑）。
- 于是每一侧 4 个席位（不论真人还是电脑）各能贡献 +1 星，上限恒为 +4，与席位的真人/电脑配比无关 —— 这就是「和真人对齐」。
- **配套修正的地编 bug**：`Player_8` 属恶魔边（`g_Seat7={1,2,8,3}`），原有 `Player_8/LEVELUP` 节点却启 `/LEVELUP8`，会把这一星加到**天使**那边；已改成 `/LEVELUP7`（见第 6 章）。改之前恶魔侧只有 3 个真人星级来源、天使侧 5 个；改之后两边各 4 个。`AICOMP.ApplyT4Reward` 一直用 `g_SeatToSide`，不受该 bug 影响。

### 需求 6：纯抽卡模式下只对总数量

> **口径修正（2026-11 实测反馈）**：`g_DrawMode` 的三个取值要分两种含义，不能混为一谈：
>
> | `g_DrawMode` | 房主选项 | 卡池范围 | 阶级上限 |
> |---|---|---|---|
> | 0 | 关闭 | 只认可生产池 | 受模仿对象 + 自身科技限制 |
> | 1 | **出兵 + 抽卡**（原版幸运箱） | 放开到全部战斗单位（含箱子专属） | **仍受**模仿对象 + 自身科技限制 |
> | 2 | **纯抽卡模式** | 放开到全部战斗单位 | **不看科技**，只对总数量 |
>
> 所以「只看总数量」这条只对 `g_DrawMode == 2` 生效；`== 1` 只扩展卡池，出兵逻辑与关闭时完全一样。
> 代码里用两个谓词分开：`AICOMP.IsDrawModeOn()`（`~= 0`，管卡池）与 `AICOMP.IsPureDrawMode()`（`== 2`，管阶级）。

`ApplySeat` 增加分支：

```lua
-- 纯抽卡模式：不看科技、不看兵种构成，只把总数量追平（逻辑有意简化）。
-- 出兵 + 抽卡模式（g_DrawMode == 1）走正常分支：阶级仍受模仿对象与自身科技限制。
if AICOMP.IsPureDrawMode() then
    AICOMP.ApplyDrawModeSeat(aiSeat, refState, ownState)
    return
end
```

```lua
-- 纯抽卡模式（g_DrawMode == 2）：不管自身科技、不管模仿对象的兵种构成，只把总数量追平。
-- 顺序仍是 1..5 优先补缺口（避免全堆在步兵段），但阶级不限。
function AICOMP.ApplyDrawModeSeat(seat, refState, ownState)
    local need = refState.Total - ownState.Total
    if need <= 0 then
        return
    end
    for band = 1, AICOMP.CategoryCount, 1 do
        if need <= 0 then
            break
        end
        local deficit = refState.Cat[band] - ownState.Cat[band]
        if deficit > 0 then
            local take = deficit
            if take > need then
                take = need
            end
            local added = AICOMP.AddAnyTierUnits(seat, band, take)
            need = need - added
        end
    end
    -- 各段都已追平但总量还差（模仿对象把兵堆在 band 0 等不统计段）：随便补。
    if need > 0 then
        for band = 1, AICOMP.CategoryCount, 1 do
            if need <= 0 then
                break
            end
            need = need - AICOMP.AddAnyTierUnits(seat, band, need)
        end
    end
end
```

`AddAnyTierUnits` = 把 `BuildAllFactionPool(tier, band)` 对 `tier = 1..4` 并起来（去重、过上限过滤），再随机取。它不受 `GetSideTechLevel` 限制，正是需求要的「不再受限于自身科技和模仿对象的兵种」。

### 需求 7：电脑模仿对方的技能释放

#### 打标（`CenterTopBtnFunc.lua`）

`CenterTopBtnFunc_CreatePlayerSkillButtons` 里，`ButtonManager:SetButton(buttons[1])` 之前插入：

```lua
    -- 技能组按钮打标：ButtonManager 的成功释放钩子靠它区分「技能」和「市场/面板/投降」。
    for j = 1, 2, 1 do
        if buttons[j] ~= nil then
            buttons[j].SkillKind = kind
        end
    end
```

#### 钩子（`ButtonManager.lua`，1 处）

`buttonData.OnClick` 包装里，`self._usedCount = self._usedCount + 1` 之后插入：

```lua
        -- 电脑模仿释放：技能组按钮（带 SkillKind 标记）成功释放后通知一次。
        if self.SkillKind ~= nil and g_OnPlayerSkillCast ~= nil then
            g_OnPlayerSkillCast(self.PlayerIndex, self.ButtonIndex, self.SkillKind)
        end
```

- 位置保证：`_multipleUseOnClick()` 返回 false 的（条件不满足/次数用完）**不会**触发，符合「真正放出来了才算」。
- 只对带 `SkillKind` 的按钮生效，市场（4）、海克斯面板（5）、投降（6）不会误触发。

#### 镜像派发（`AIINI_1.lua`）

```lua
AICOMP.SkillMirrorDepth = AICOMP.SkillMirrorDepth or 0
AICOMP.SkillMirrorChain = AICOMP.SkillMirrorChain or {}

-- 全局入口：ButtonManager 里按需调用（不存在时静默跳过，互不依赖加载顺序）。
function g_OnPlayerSkillCast(playerIndex, buttonIndex, skillKind)
    AICOMP.MirrorSkillCast(playerIndex, buttonIndex, skillKind)
end

-- 能不能放：次数没满、不在冷却、已解锁。
function AICOMP.CanUseSkillButton(button)
    if button == nil then
        return false
    end
    if button.IsEnabled == nil or button.IsEnabled == false or button.IsEnabled == 0 then
        return false
    end
    if button._cooldownCount ~= nil and button._cooldownCount > 0 then
        return false
    end
    if button.MaxUseCount ~= nil
        and (tonumber(button._usedCount) or 0) >= button.MaxUseCount then
        return false
    end
    return true
end

function AICOMP.MirrorSkillCast(casterIndex, buttonIndex, skillKind)
    if ButtonManager == nil or g_SeatToSide == nil or g_SideSeatsOf == nil
        or AI == nil or P == nil or skillKind == nil then
        return
    end
    local oldDepth = AICOMP.SkillMirrorDepth or 0
    -- 兜底上限：正常情况下每台电脑放完就进它自己的 CD，链长不会超过「会这个技能的电脑数」。
    if oldDepth >= 16 then
        return
    end
    local casterSide = g_SeatToSide(casterIndex)
    if casterSide == nil then
        return
    end
    if oldDepth == 0 then
        AICOMP.SkillMirrorChain = {}
    end
    local chain = AICOMP.SkillMirrorChain
    -- 本次对拼里已经出过手的席位不再参与（按钮的冷却在 OnClick 尾段才落上去，
    -- 这一跳正嵌在它中间，光看按钮状态会把同一台又选中一次）。
    chain[casterIndex] = 1
    local seats = g_SideSeatsOf(AICOMP.OppositeSide(casterSide))
    local candidates = {}
    for i = 1, getn(seats), 1 do
        local seat = seats[i]
        if seat ~= nil and AICOMP.IsComputerSeat(seat) and chain[seat] == nil then
            local button = ButtonManager:GetButton("Player_" .. seat, buttonIndex)
            -- SkillKind 必须相同 = 「拥有一样的技能」；buttonIndex 相同 = 同一组里的同一个技能。
            if button ~= nil and button.SkillKind == skillKind
                and AICOMP.CanUseSkillButton(button) then
                tinsert(candidates, button)
            end
        end
    end
    AICOMP.SkillMirrorDepth = oldDepth + 1
    local total = getn(candidates)
    while total >= 1 do
        local pickPos = RANDOMGENERATE(total, 1)
        local button = candidates[pickPos]
        candidates[pickPos] = candidates[total]
        candidates[total] = nil
        total = total - 1
        local before = tonumber(button._usedCount) or 0
        chain[button.PlayerIndex] = 1
        button:OnClick()          -- 这一放又会触发下一跳（对面再回一手）
        if (tonumber(button._usedCount) or 0) > before then
            break
        end
    end
    AICOMP.SkillMirrorDepth = oldDepth
end
```

#### 7.1 对拼链（一次施放 → 逐跳对拼，直到都进 CD）+ 每台电脑 CD 独立

需求原文的例子：
> 恶魔方放冰天雪地 → 天使电脑A放 → 恶魔电脑C放 → 天使A已在 CD 不能放 → 若天使电脑B也有冰天雪地就继续跟着放 → 直到都 CD 或没有技能。

三件事一起才能实现：

1. **链式**：不能再用「一次性 busy 标志」把递归掐死。改成**深度计数 + 本轮已出手席位表**：
   - `SkillMirrorDepth` 只做 16 层兜底（自然上限是「会这个技能的电脑数」≤ 8）；
   - `depth == 0` 时清空 `SkillMirrorChain`，每一跳把出手席位记进去。
   - **为什么必须有这张表**：`_cooldownCount`（以及 `IsEnabled = false`）是在 `OnClick` 的**尾段**才写上去的，而我们正嵌在它中间调用下一跳。此时 A 的按钮看起来还是「可放」，只看按钮状态会让 A、C 无限对轰。`CanUseSkillButton` 里的 `_usedCount >= MaxUseCount` 能挡住有次数上限的技能（九头蛇就是这样），但像冰天雪地（2 次 / 70 秒 CD）挡不住 —— `SkillMirrorChain` 才是通用解。
2. **每一跳只让一台电脑放**：仍然是「一次施放 → 对面一台」，不会出现两台同时放（这是原始需求里「不要出现恶魔放一个九头蛇，天使2个电脑一块放」的口径；对拼是**逐跳串行**的，不是并发）。
3. **每台电脑 CD 独立**：`ButtonManager` 的「共享冷却」原本是**同侧、同一技能、所有玩家**共用一个桶（`ButtonManager.lua:152-163` 把 Id 改写成 `devil_hydra` / `angel_hydra`），会连带把同侧其它电脑一起锁 10 秒 —— 那样 A 一放，B 立刻也进 CD，对拼链直接断掉。所以对电脑席位双向屏蔽：

```lua
-- ButtonManager.buttonData.OnClick：电脑放技能不再给同侧刷共享冷却
if self.SharedCooldownId then
    if g_IsAutoChessComputerSeat == nil or not g_IsAutoChessComputerSeat(self.PlayerIndex) then
        ButtonManager:SharedCooldown(self)
    end
end

-- ButtonManager:SharedCooldown：电脑席位也不接收别人刷过来的共享冷却
for i = 1, getn(list) do
    local currentButton = list[i]
    if currentButton ~= buttonData then
        if g_IsAutoChessComputerSeat == nil or not g_IsAutoChessComputerSeat(currentButton.PlayerIndex) then
            currentButton:SharedCooldown()
        end
    end
end
```

> 两点设计取舍：① 只屏蔽「共享冷却」，电脑自己那份 `CooldownSeconds`（冰天雪地 70 秒、九头蛇 70 秒）照常生效，所以「也受限于技能 CD」成立；② 真人与真人之间的 10 秒共享冷却规则**完全没动**，电脑的镜像释放也不会让同侧真人替它吃冷却。判定函数是 `g_IsAutoChessComputerSeat(seat)`（`AIINI_1.lua`，`AI[seat]==1 且 P[seat]~=nil`），`ButtonManager` 侧用 nil 判断调用，不依赖加载顺序。

#### 7.2 自选技能组模式：电脑先"对着"挑一组

房主把技能组设成「让玩家自行选择」时，`g_PreselectedSkillIndices` 保持为空，8 个席位都拿到「请选择你的技能组」按钮；电脑不会点，于是永远没有技能槽。所以在真人选定一组时给**对面板**的电脑补上同一组：

```lua
-- CenterTopBtnFunc_CreatePlayerSkillButtons 末尾
if g_OnPlayerSkillGroupAssigned ~= nil then
    g_OnPlayerSkillGroupAssigned(playerIndex, kind)
end

-- AIINI_1.lua
function AICOMP.OnSkillGroupAssigned(playerIndex, kind)
    if playerIndex == nil or kind == nil then return end
    if AICOMP.SkillGroupOf[playerIndex] ~= nil then return end   -- 选了不能改
    AICOMP.SkillGroupOf[playerIndex] = kind
    -- 预选 / 随机 / 对称模式：8 席开局已有组，不补课（行为完全不变）
    if g_PreselectedSkillIndices == nil or getn(g_PreselectedSkillIndices) > 0 then return end
    if AICOMP.IsComputerSeat(playerIndex) or AICOMP.SkillGroupBusy == 1 then return end
    local oppSide = AICOMP.OppositeSide(g_SeatToSide(playerIndex))
    -- 对面板已经有人拿这一组就不再重复发，4 台电脑尽量覆盖不同的组
    for seat = 1, 8, 1 do
        if AICOMP.IsComputerSeat(seat) and g_SeatToSide(seat) == oppSide
            and AICOMP.SkillGroupOf[seat] == kind then return end
    end
    for seat = 1, 8, 1 do
        if AICOMP.IsComputerSeat(seat) and g_SeatToSide(seat) == oppSide
            and AICOMP.SkillGroupOf[seat] == nil then
            AICOMP.SkillGroupOf[seat] = kind       -- 先记下再建按钮，里面的回调靠这行判重
            AICOMP.SkillGroupBusy = 1
            CenterTopBtnFunc_CreatePlayerSkillButtons(seat, kind)
            AICOMP.SkillGroupBusy = 0
            return
        end
    end
end
```

效果：4 个天使各选了 1/2/3/4 组 → 4 台恶魔电脑分别补上 1/2/3/4 组，各自都能对着放；若几个人选的是同一组，对面板只补一台电脑拿这一组，其余空着（对应「没有技能」的终止条件）。补课时会走原来的 `CreatePlayerSkillButtons`，所以 `SkillKind` 打标、公共面板播报（"Player_N选择了X"）、终极刷新补次数全都自动生效，镜像逻辑不需要任何改动。

#### 7.3 阵营技能（ButtonIndex 3）也镜像

三个阵营技能（`CenterTopBtnFunc.lua:729/750/771`）用 `SkillKind` 打标，编号从 101 起，避开技能组的 1..6：

| SkillKind | 技能 | 要求阵营 | 解锁标志 | 释放函数 | 限制 |
|---|---|---|---|---|---|
| 101 | 超时空突袭 | 盟军 (1) | `g_AlliedSuperWeaponBuilt` | `RequestChronosphere` | 无次数上限 / `CooldownRounds = 3` |
| 102 | 全体护盾 | 帝国 (3) | `g_ProductionBonus_JapanGet` | `RequestJapanShield` | 无次数上限 / 200 秒 CD |
| 103 | 士气提升 | 神州 (4) | `g_CelestialSuperWeapon_Get` | `RequestCelestialMorale` | 无次数上限 / 220 秒 CD |
| — | （苏联 2 没有阵营技能） | — | — | — | — |

**关键障碍**：电脑侧这三个标志永远是 0 —— 它们是真人「造出对应超级武器/协议」时才置 1 的（`CenterTopBtnFunc_UnlockChronosphere`、`Upgrade.lua:92`、`CelestialSuperWeapon_Button.lua:14`），而电脑不造建筑，于是 `CenterTopBtnFunc_CreateFactionSkillButton` 对电脑直接返回 `nil`，**电脑根本没有按钮 3**，镜像无从谈起。

**解法（按需补建，与 `ApplyT4Reward` 同一思路）**：把候选扫描里的 `ButtonManager:GetButton` 换成 `AICOMP.EnsureSeatButton` —— 拿不到同技能的按钮时，如果这是按钮 3、且该电脑的阵营正好对得上，就补上解锁标志 + 调 `CenterTopBtnFunc_UpdatePlayer3rdButton` 建出按钮，然后走正常的 `OnClick`（次数/冷却/回合限制全沿用）。

```lua
AICOMP.FactionSkillFaction = { [101] = 1, [102] = 3, [103] = 4 }

function AICOMP.GrantFactionSkill(seat, skillKind)
    if skillKind == 101 then
        g_AlliedSuperWeaponBuilt = g_AlliedSuperWeaponBuilt or {}
        g_AlliedSuperWeaponBuilt[seat] = 1
    elseif skillKind == 102 then
        g_ProductionBonus_JapanGet = g_ProductionBonus_JapanGet or {}
        g_ProductionBonus_JapanGet[seat] = 1
    elseif skillKind == 103 then
        g_CelestialSuperWeapon_Get = g_CelestialSuperWeapon_Get or {}
        g_CelestialSuperWeapon_Get[seat] = 1
    end
end

function AICOMP.EnsureSeatButton(seat, buttonIndex, skillKind)
    local button = ButtonManager:GetButton("Player_" .. seat, buttonIndex)
    if button ~= nil and button.SkillKind == skillKind then
        return button
    end
    if buttonIndex ~= 3 or CenterTopBtnFunc_UpdatePlayer3rdButton == nil then
        return nil
    end
    local faction = AICOMP.FactionSkillFaction[skillKind]
    if faction == nil or AICOMP.GetSeatFaction(seat) ~= faction then
        return nil
    end
    AICOMP.GrantFactionSkill(seat, skillKind)
    CenterTopBtnFunc_UpdatePlayer3rdButton(seat)
    button = ButtonManager:GetButton("Player_" .. seat, buttonIndex)
    if button ~= nil and button.SkillKind == skillKind then
        return button
    end
    return nil
end
```

于是行为就是「对面放哪个阵营技能，本边同阵营的电脑就跟着放」：
- 恶魔盟军席放超时空突袭 → 天使的**盟军**电脑跟着放（天使没有盟军电脑就不放）；
- 对拼链、每跳一台、CD 各自独立、以及真人之间的共享冷却规则，全部与 7.1 一致，一行代码都不用再写；
- `SharedCooldownId` 是 `alliedsuperweapon` / `japanshield` / `celestialmorale`，电脑席位已按 7.1 双向屏蔽共享冷却，所以不会互相锁。
- 说明：阵营技能的效果本来就是整侧生效（`ObjectFindObjects(T74/T84, …)`），所以给对位阵营的电脑补这一个标志不会凭空多出一个「只有它能享受」的能力；它只是把「本侧这个阵营技能」交给电脑去放。如果希望电脑**开局就自带**阵营技能，把 `EnsureSeatButton` 里的阵营判断去掉、改在 `EnsureRound` 里预先 grant 即可。

**CD 是唯一闸门（已确认口径）**：三个阵营技能都是 `MaxUseCount = nil`（无次数上限）+ 各自 CD，所以「一次真人施放 → 链式把双方会这个技能的电脑全部放一遍」是最坏情况，**属预期、可接受**；阵营不对称（对面有盟军、这边没有盟军电脑）时就直接不放，也是预期。实现上 CD 完全由按钮自身的 `OnClick` 兜住，没有另写判断：

| 技能 | `CooldownSeconds` | `CooldownRounds` | 放完后的状态 |
|---|---|---|---|
| 超时空突袭 | 0 | **3** | `_cooldownCount = 1`、`IsEnabled = false`，3 个回合后 `_reActivate` 才重新点亮 |
| 全体护盾 | **200** | 0 | `_cooldownCount = 1`、`IsEnabled = false`，200 秒后重新点亮 |
| 士气提升 | **220** | 0 | 同上，220 秒 |

`CanUseSkillButton` 里 `_cooldownCount > 0` 直接判不可放，加上 `SkillMirrorChain` 排除本链已出手的席位（因为冷却是在 `OnClick` 尾段才落上去的，这一跳正嵌在它中间），所以同一回合内一台电脑不会连放两次；CD 期间对面再放也带不动它。共享冷却对电脑双向屏蔽（见 7.1），所以一台电脑放不会连累同侧其它电脑——「每个人有 CD、但互相独立」。

#### 行为核对需求给的例子

> 恶魔放九头蛇万岁 → 天使方电脑里找 kind == 5 且 ButtonIndex == 1 的 → 有就随机挑**一台**放，不会两台一起放。

> 恶魔放空军元帅（kind 3 / ButtonIndex 2）→ 天使方 kind == 3 的电脑放空军元帅。

> 恶魔盟军席放超时空突袭（SkillKind 101 / ButtonIndex 3）→ 天使的盟军电脑跟着放。

- 借用 `OnClick` 包装 ⇒ 次数、冷却、共享冷却、解锁回合（龙行天下第 5 回合）全部沿用真人逻辑，不会超放。
- `RequestXxx` 内部用 `g_IsAngelSeat(playerIndex)` 判断该打谁，传电脑自己的席位号，目标自动指向施放方那一侧，不需要额外处理。
- 施放的播报（`exMessageAppendToMessageArea` / 公共面板）会以电脑的名义发出，属预期。

---

## 3. 改动清单

### 3.1 `lua/LUABOX/AI/AIINI_1.lua`（主体）

| 位置 | 动作 |
|---|---|
| 文件头 `AICOMP.*` 初始化 | 新增 `TierShown` / `CapCount` / `CapGroups` / `T4Rewarded` / `SkillMirrorDepth` / `SkillMirrorChain` / `SkillGroupOf` / `SkillGroupBusy` |
| `AICOMP.IsHumanSeat` 后 | 新增 `AICOMP.IsComputerSeat` + 全局 `g_IsAutoChessComputerSeat` |
| `AICOMP.IsHumanSeat` 后 | 新增 `AICOMP.IsReferenceEligible` / `GetReferenceCandidates` / `AssignReferences` |
| `AICOMP.GetReference`（42-74） | 重写为 `AssignReferences` + 保留兼容包装 |
| `AICOMP.CollectCategoryState` 后 | 新增 `AICOMP.SnapshotTiers` / `GetShownTier` |
| `AICOMP.ResolveCategoryTier`（299-321） | 入参改为快照值；内部按上限过滤后的池子判断该档还能不能投 |
| `AICOMP.GetCandidatePool` 后 | 新增 `EnsureCapGroups` / `IndexOfUnitIndex` / `FindCapGroupIndex` / `IsCapGroupFull` / `FilterCappedPool` / `MarkCapUsed` / `CollectUnit` / `GetAnyTierPool` |
| `AICOMP.AddRandomUnits`（408-427） | 改为走 `AICOMP.CollectUnit`，并在每次抽取前按上限过滤，投放后 `MarkCapUsed` |
| `AICOMP.AddRandomUnits` 后 | 新增 `AddAnyTierUnits`（抽卡模式投放） |
| `AICOMP.ApplySeat`（429-469） | 抽卡模式分支；`refTier` 用快照值；进入时先 `ApplyT4Reward` |
| 新增 `AICOMP.ApplyDrawModeSeat` / `AICOMP.ApplyT4Reward` | 见需求 6 / 需求 5 |
| `AICOMP.EnsureRound`（472-486） | 先 `AssignReferences`，再逐席位 `ApplySeat`（快照与 T4 奖励都在 `ApplySeat` 内）；另外每回合把 `SkillMirrorDepth` / `SkillMirrorChain` 清零当自愈 |
| 文件尾 | 新增 `g_OnPlayerSkillCast` / `CanUseSkillButton` / `MirrorSkillCast` / `g_OnPlayerSkillGroupAssigned` / `OnSkillGroupAssigned` |

### 3.2 `lua/LUABOX/BUTTON/ButtonManager.lua`

两处，都在「共享冷却」上（见 7.1）：`buttonData.OnClick` 里给 `ButtonManager:SharedCooldown(self)` 加电脑席位判断；`ButtonManager:SharedCooldown` 的桶遍历里跳过电脑席位。

### 3.3 `lua/LUABOX/BUTTON/CenterTopBtnFunc.lua`

`CenterTopBtnFunc_CreatePlayerSkillButtons`：给 `buttons[1..2]` 打 `SkillKind`；末尾调 `g_OnPlayerSkillGroupAssigned`（见 7.2）。另外三个阵营技能工厂 `CreateChronosphereButton` / `CreateJapanShieldButton` / `CreateCelestialMoraleButton` 各加 `SkillKind = 101/102/103`（见 7.3）。

### 3.4 `lua/GAME/HextechRune/06_ascension.lua`

文件尾新增 `HextechRune:CollectPoolUnits`（约 25 行）。

### 3.5 同步与校验（已按此流程跑通）

所有工具都用 `lua_payload.find_repo_root()` 找「同时含 `lua/` 与 `analysis/` 的目录」= `DSA_ggz`，
因此它们默认读的 JSON 是 `DSA_ggz/ScriptsData.json`；**这个文件当前不存在**，正式地图 JSON 在
`DSA_ggz/DSA_XXX%COR_44/ScriptsData.json`。用下面的方式把 `JSON_PATH` 顶掉即可（`REPO_ROOT`
仍是 `DSA_ggz`，源文件路径照旧）：

```powershell
$env:PYTHONIOENCODING='utf-8'
$env:DSA_JSON='DSA_ggz\DSA_XXX%COR_44\ScriptsData.json'

# 1) 只看差异，不写盘
python -c "import sys,os; sys.path.insert(0,r'DSA_ggz\analysis\tools'); import sync_scriptsdata as S; S.JSON_PATH=os.path.abspath(os.environ['DSA_JSON']); sys.argv=['x','--check-only']; S.main()"

# 2) 真正回填
python -c "import sys,os; sys.path.insert(0,r'DSA_ggz\analysis\tools'); import sync_scriptsdata as S; S.JSON_PATH=os.path.abspath(os.environ['DSA_JSON']); sys.argv=['x']; S.main()"

# 3) Lua 4.0 静态体检（含 #!ra3luabridge 前缀检查，255 个 payload 全过）
python -c "import sys,os; sys.path.insert(0,r'DSA_ggz\analysis\tools'); sys.path.insert(0,r'DSA_ggz\analysis'); import check_payload_lua4 as C; C.JSON_PATH=os.path.abspath(os.environ['DSA_JSON']); sys.argv=['x']; sys.exit(C.main())"

# 4) 源文件侧括号/关键字平衡 + 全库泛型 for 语法
python DSA_ggz\analysis\check_lua_balance.py

# 5) 源文件 ↔ JSON 漂移
python -c "import sys,os; sys.path.insert(0,r'DSA_ggz\analysis\tools'); sys.path.insert(0,r'DSA_ggz\analysis'); import audit_lua_json as A; A.JSON_PATH=os.path.abspath(os.environ['DSA_JSON']); sys.argv=['x']; A.main()"
```

> `check_payload_integrity.py` 只在模块导入期跑、且只盯单个 payload，需要临时把 JSON 复制成
> `DSA_ggz/ScriptsData.json` 才能用；本次改动的权威校验以第 3、4、5 步为准。
>
> **注意**：`sync_scriptsdata.py` 会把全部 90 个 target 重写一遍。`lua/GAME/mainloop.lua` 与
> JSON 只差一行注释（audit 归为 COSMETIC），同步会抹掉 JSON 里那行注释——本次改动与该节点无关，
> 已单独还原，最终 JSON diff 只含下列 5 个节点（4 个 Lua payload + 1 个地编节点修正）：
> `/LUABOX/AI/AIINI|Then[1]`、`/LUABOX/BUTTON/ButtonManager|Then[0]`、
> `/LUABOX/BUTTON/CenterTopBtnFunc|Then[0]`、`/LUABOX/BUTTON/HextechRuneAscension|Then[0]`、
> `Player_8/LEVELUP|Then[0]`（`/LEVELUP8` → `/LEVELUP7`，见第 6 章）。

---

## 4. 验证清单（进游戏逐项验）

1. **符文（需求 1）**：给电脑抽「买二送一」+ 指定目标，观察电脑池子每 2 个多 1 个；给电脑抽「登神」，观察池内目标单位始终只有 1 个且层数上涨。
2. **参照均衡（需求 2）**：8 人局 4 真人 4 电脑开局，观察 4 台电脑的参照席位互不相同（临时打开一行 `exMessageAppendToMessageArea` 打印，验完删掉）。
3. **掉线重挑（需求 2）**：让某个真人退出（或在 WB 里摧毁他的全部建筑触发 `PlayerNowDied`），确认
   ① 他的资产转移给队友、`UNITCOUNT` 归零；② 原本模仿他的电脑**下一回合**换到存活真人上；
   ③ 这些电脑**没有出现停止出兵**的一回合以上；④ 接手的队友总量变大后，模仿他的电脑也跟着补上去；
   ⑤ 真人全部退出后电脑回到「每段各 +1 个 T1」，不挂机。
4. **阶级模仿（需求 3）**：真人先造 T3 再改回只造 T2，确认电脑继续出 T3（记忆生效）。
5. **上限（需求 4）**：让电脑所在边科技到 T4，连续跑 10 回合，确认该电脑摇光不超过 3、大船不超过 2；再用符文送摇光，确认能超过 3。
6. **星级（需求 5）**：电脑科技到 T4 的那一回合起，该边出兵队伍的等级 +1；同时确认真人自己不建 htech/tech 时不变。
7. **抽卡模式（需求 6）**：分两档验。①房主选「出兵 + 抽卡」（`g_DrawMode == 1`）：确认电脑的**阶级仍跟着模仿对象和自身科技走**（参照只出 T2 时电脑不出 T3），只是候选池里出现了箱子专属单位；②房主选「纯抽卡模式」（`== 2`）：确认电脑与参照总数量一致，且完全不受科技限制。
8. **技能镜像（需求 7）**：单人测试时用「恶魔」席放冰天雪地，确认天使方**同一时刻只有一台**电脑放；然后观察对拼链——天使那台放完，恶魔电脑该回一手，回来之后天使 A 已在 CD、由天使 B 接手，直到两边会这个技能的电脑都进 CD。再放一次确认次数/冷却生效。
9. **电脑 CD 独立（需求 7 补充）**：同侧两台电脑都有冰天雪地时，确认 A 放完之后 B 的按钮**没有**跟着进 10 秒公共冷却（B 可以被下一跳选中）；而真人自己点，同侧真人之间的 10 秒共享冷却照旧。
10. **自选技能组（需求 7 补充）**：房主把技能组设成「让玩家自行选择」，进游戏后先不选，确认电脑没有任何技能按钮；选完一组后，确认对面板电脑自动拿到同一组（公共面板出现 "Player_N选择了X"），并且能对着放；再让另一名同侧真人也选一组，确认对面板另一台电脑补上那一组。确认已选过的电脑不会因为后续别人的选择而改组。
11. **阵营技能镜像（需求 7 补充）**：让恶魔的**盟军**席造出超级武器拿到「超时空突袭」（或直接用调试脚本置 `g_AlliedSuperWeaponBuilt[i]=1` + `CenterTopBtnFunc_UpdatePlayer3rdButton(i)`），点它；确认天使方**同阵营（盟军）的电脑**跟着放一次，天使方非盟军电脑不动。若天使没有盟军电脑，则什么都不发生。之后确认那台电脑的按钮 3 进入 `CooldownRounds = 3` 的冷却，3 回合内不再放。帝国（全体护盾）/神州（士气提升）同理；苏联席没有阵营技能，不参与。

---

## 5. 实现记录（已落盘）

| 文件 | 实际改动 |
|---|---|
| `lua/LUABOX/AI/AIINI_1.lua` | 505 → 1025 行；payload 16653 → 35938 B（余 29598 B）。新增 `IsReferenceEligible` / `GetReferenceCandidates` / `AssignReferences` / `SnapshotTiers` / `GetShownTier` / 上限五件套（`EnsureCapGroups` / `FindCapGroupIndex` / `IsCapGroupFull` / `FilterCappedPool` / `MarkCapUsed`）/ `CollectUnit` / `AddAnyTierUnits` / `GetAnyTierPool` / `ApplyDrawModeSeat` / `ApplyT4Reward` / `IsComputerSeat` / `g_IsAutoChessComputerSeat` / `CanUseSkillButton` / `MirrorSkillCast` / `g_OnPlayerSkillCast` / `FactionSkillFaction` / `GrantFactionSkill` / `EnsureSeatButton` / `OnSkillGroupAssigned` / `g_OnPlayerSkillGroupAssigned`；`AddRandomUnits`、`ApplySeat`、`EnsureRound`、`ResolveCategoryTier` 改写 |
| `lua/LUABOX/BUTTON/ButtonManager.lua` | `buttonData.OnClick` 里 `_usedCount` 自增后插钩子；`SharedCooldown` 的桶遍历与发射两处加电脑席位判断；payload 11278 → 11968 B |
| `lua/LUABOX/BUTTON/CenterTopBtnFunc.lua` | 给 `buttons[1..2]` 打 `SkillKind`；末尾调 `g_OnPlayerSkillGroupAssigned`；三个阵营技能工厂各加 `SkillKind = 101/102/103`；payload 自动去注释后 62210 B（余 3326 B） |
| `lua/GAME/HextechRune/06_ascension.lua` | 文件尾新增 `HextechRune:CollectPoolUnits`；payload 15402 → 16711 B |
| `DSA_XXX%COR_44/ScriptsData.json` 地编节点 | `Player_8/LEVELUP` 节点的 `ENABLE_SCRIPT` 参数由 `/LEVELUP8` 改为 `/LEVELUP7`（恶魔边），修正后 8 席与 `g_Seat7`/`g_Seat8`、`Upgrade.lua` 的 `g_IsDevilSeat` 完全一致 |
| `analysis/地图注释说明文档.md` | 新增 **附录 D. 电脑策略优化（2026-11：需求 1-7）从 lua 移出的讲解**，共 9 段（D.1 参照均衡 / D.2 科技模仿快照 / D.3 建造上限 / D.4 符文入池 / D.5 T4 奖励 / D.6 抽卡模式 / D.7 技能对拼链 + CD 独立 / D.8 自选技能组 / D.9 阵营技能）。四个 lua 文件里本次新增的大段讲解全部搬到这里，源码只留一行指路 `见附录 D.x` |

校验结果：

- `sync_scriptsdata.py`：90 个 target 全部匹配，`ScriptsData.json updated and validated OK`；
- `check_payload_lua4.py`：255 个 payload（全部带 `#!ra3luabridge`）**全部通过 Lua 4.0 静态体检**；
- `check_lua_balance.py`：无 FAIL；
- `audit_lua_json.py`：`DRIFT = 3`，全部是本次改动之前就存在的既有漂移
  （`CelestialCenturionUpgradeCD.lua` / `LUABOX/boardini_0.lua` / `text/Human_0.lua`），与本次无关。

---

## 6. 需求确认结论 / 待实测

> 2026-11 追加确认（三项全部按「最简」口径定案，代码已是该口径，无需再改）：
> 1. **星级不看模式**：只要电脑科技上限到 T4 就自动升星。
> 2. **和真人对齐**：一台电脑 +1 星（每边最多 4，对应真人侧 4 个 `Player_N/LEVELUP` 节点）。
> 3. **`Player_8/LEVELUP` 的地编 bug 已修正**：恶魔边 `g_Seat7={1,2,8,3}`、天使边 `g_Seat8={4,5,7,6}`，加星按席位→边走，所以 P8 启 `/LEVELUP7`。改完 8 席全部一致。

| 项 | 说明 |
|---|---|
| `PickBuyTwoGetOneTarget` | 是否只对真人挑目标；若只给真人挑，电脑 `OnPlayerUnitCollected` 无副作用 |
| 护卫坦克 | `GUARDIAN_TANK_LIMIT = 3` 同样只关真人按钮；需求没提，本次不加，`AICOMP.CapGroups` 结构已预留扩展位 |
| 阵营技能按钮（ButtonIndex 3：超时空传送/日本护盾/神州士气） | **已纳入镜像**（见 7.3）：`SkillKind` 101/102/103 打标；电脑不造超级武器、永远拿不到解锁标志，所以在对面放这个阵营技能时按需给对位阵营的电脑补标志 + 建按钮，再走正常的次数/冷却/回合限制 |
| 自选技能模式下电脑 | 房主选「让玩家自行选择」时，电脑先没人点选，直到对面板有真人选定一组才自动补上同一组（见 7.2）；若对面所有真人一直不选，电脑就一直没有技能槽，也就无从镜像 |
| **「同组两技能共享 10 秒公共冷却」其实没实现** | 更新日志（`text/Update_0.lua:5`）这么写，但代码里九头蛇用 `SharedCooldownId="hydra"`、冰天雪地用 `"snowstorm"`（`CenterTopBtnFuncExtra.lua:108` / `:128`），两个 Id 不同 ⇒ **同组两技能之间并不互锁**；真正共享的是「同侧、同一个技能、4 名玩家」的桶（`ButtonManager.lua:152-163` 会把 Id 改写成 `devil_hydra` / `angel_hydra`）。镜像不依赖这一点（跨侧前缀不同，天然不会互锁），但若要按更新日志修，得把同组两个 Id 统一——那会让同侧 4 人的两个技能全部互相锁，比日志描述的更强，故本次未动 |
| ~~死亡模式/缩小模式的星级时点~~ | **已定：不用管模式。**需求原话「不用管什么模式，只要电脑科技上限达到 T4 就自动升星，最简单」，所以 `ApplyT4Reward` 只看 `techLevel >= 4`，不加任何模式判断。死亡模式/缩小模式开局即 4 ⇒ 电脑第一回合就吃满每席位 +1 星（一边最多 +4），这与「科技到 T4 就给星」的字面口径一致 |
| ~~每边最多 +4 还是 +1~~ | **已定：与真人对齐，一台电脑 +1 星。**即「每个电脑席位各 +1、每边最多 +4」，对应真人侧 4 个 `Player_N/LEVELUP` 节点。实现就是现在这样，不需要改 |
| ~~地编 bug：`Player_8/LEVELUP`~~ | **已修正。**恶魔边是 `g_Seat7={1,2,8,3}`、天使边是 `g_Seat8={4,5,7,6}`，加星按「席位→边」走，所以 `Player_8`（恶魔）的 `LEVELUP` 节点应启 `/LEVELUP7`。原节点启的是 `/LEVELUP8`（天使），已把该节点的参数改成 `/LEVELUP7`（`ScriptsData.json`，一行）。现在 8 个席位全部一致：P1/P2/P3/P8 → `/LEVELUP7`，P4/P5/P7/P6 → `/LEVELUP8`，与 `Upgrade.lua:164-176` 的 `g_IsDevilSeat` 判断完全对齐 |

---

## 7. 发版前链路核查（2026-11，真人联机前）

### 7.1 完整链路（逐环已核对，无断点）

| # | 环节 | 位置 | 结论 |
|---|---|---|---|
| 1 | 谁是电脑 | `LUABOX/AI/AID_0.lua`（JSON `/LUABOX/AI/AID\|Then[0]`） | `AI[seat]=1`（非人 + `P[seat]` 存在），**全图唯一写 `AI[]` 的地方**，开局算一次 |
| 2 | 席位→边 | `GAME/BasicVar1.lua:9-10` `g_Seat7/g_Seat8` + `g_SeatToSide`/`g_SideSeatsOf` | 恶魔 `{1,2,8,3}`、天使 `{4,5,7,6}` |
| 3 | 触发 | 地编 `/LUABOX/AI/AIUNITBUILDACT__0..3` → `spinfantlv1/spinlightvehlv1/spinheavyvehlv1/spaircraftlv1`；兜底 `LUABOX/LandArmySpawn.lua:118` 的 `LandArmySpawn()` 首行 | 四个入口都在 JSON 里对得上；`LandArmySpawn` 的调用在**所有兵种批次之前**，当回合刷得出来 |
| 4 | 每回合去重 | `AICOMP.EnsureRound`（按 `lvc`） | 地编 4 入口 + 出兵钩子共 5 处调用只生效一次 |
| 5 | 均分参照 | `AICOMP.AssignReferences` | 贪心「最少被引用 + 并列随机」；见 7.2 实测分布 |
| 6 | 参照失效重挑 | 同上 | `g_PowerSlotVacated[i]==1`（掉线当帧）/ `PlayerNowDied[i]==1`（兜底）触发重挑并**清空 `TierShown`**；真人全没了则清空参照回老行为 |
| 7 | 逐席位补兵 | `AICOMP.ApplySeat` | T4 奖励 → 参照状态 → 自身状态 → 按 1..5 补缺口 |
| 8 | 阶级 | `SnapshotTiers` / `GetShownTier` / `ResolveCategoryTier` | min(参照已展示最高阶级, 本方科技)，投不出来往下退 |
| 9 | 候选池 | `GetCandidatePool` → `BuildFactionPool` → `FilterCappedPool` | 缓存跨席位共享，过滤每次新建表 |
| 10 | 入池 | `AddRandomUnits`/`AddAnyTierUnits` → `CollectUnit` → `HextechRune:CollectPoolUnits` | 符文钩子（替换型/登神/买二送一）+ `MarkCapUsed` 计数 |
| 11 | 上战场 | `UNITSPST`/`UNITSPSHIP`/`UNITSPAIRST` | 与 `UNITLIST` 分段一一对应 |
| 12 | 技能镜像 | `ButtonManager` 钩子 → `g_OnPlayerSkillCast` → `MirrorSkillCast` → `EnsureSeatButton` → `OnClick` | 全部 15 个 `Request*` 都在 `CreateButton` 的 `OnClick` 闭包里，无热键/脚本旁路 |
| 13 | 自选技能组 | `CenterTopBtnFunc_CreatePlayerSkillButtons` 末尾 → `g_OnPlayerSkillGroupAssigned` | `SkillGroupOf` 判重 + `SkillGroupBusy` 防递归 |

顺带清掉一处死代码：`AICOMP.GetReference`（原「兼容旧入口」，已无调用者，且它会意外触发一次全局重排）。

### 7.2 均分模仿实测（按 lua 逻辑逐行复刻，各跑 200 次随机）

| 局型 | 引用分布（真人 → 被几台电脑模仿） | 结论 |
|---|---|---|
| 4 真人 `1234` / 4 电脑 `5678` | 恒为 (1,1,1,1) 的某种排列 | 一一对应 ✔ |
| 3 真人 `123` / 5 电脑 `45678` | 恒为 2/2/1 的某种排列 | 多出的 2 台摊到「最少被引用」的两个真人 ✔ |
| 2 真人 `12` / 6 电脑 | 恒为 3/3 | ✔ |
| 1 真人 `1` / 7 电脑 | 7 台全参照他 | ✔ |
| 4 真人全在天使 `4576` / 4 电脑全在恶魔 `1283` | 恒为 (1,1,1,1) | 对称局同样均分 ✔ |
| 0 真人 / 8 电脑 | 无参照 → 老行为（每段各 1 个 T1） | ✔ 与附录 C 一致 |

### 7.3 发版前需要知道的既有边界（不是本次引入的 bug）

1. **掉线席位的两件事分开看**：
   - **参照会换人**（已实现）：`g_PowerSlotVacated` / `PlayerNowDied` 一置位，该席位立刻失去参照资格，
     被他引用的电脑下一回合按「最少引用」重新摊平，并清空 `TierShown`。真人全没了就清空参照回到老行为。
   - **掉线席位的电脑补兵不会接管**（老结构，本次不动）：`AI[]` 只在开局由 `AID_0` 算一次，
     所以掉线真人自己的席位不会被 AICOMP 补兵——但那本来就不需要，他的资产已经全给队友了。
2. **参照优先对面阵营**：同侧电脑不会模仿同侧真人；只有当对面一个真人都没有时，才退回「全部真人」兜底（否则那台电脑会没兵可出）。
3. **电脑自动补技能组会在公共面板播报**：`CreatePlayerSkillButtons` 本来就会给 4 个队友发「Player_N 选择了 X」，电脑被自动补课时也会有这几条，属预期噪音。
4. **`Player_8` 的 `LEVELUP` 已修**：现在 8 席与 `g_Seat7`/`g_Seat8` 完全一致（P1/P2/P3/P8 → `/LEVELUP7`，P4/P5/P7/P6 → `/LEVELUP8`）。
5. **payload 余量**：`CenterTopBtnFunc.lua` 只剩 3326 B（自动去注释后 62210 B），**后续不要往这个文件加代码**；`AIINI_1.lua` 36002 B（余 29534 B）还很宽松。

---

## 8. 联机实测回归修正（2026-11-06）

### 8.1 电脑跨阵营出兵（已修）

**现象**：电脑出兵的单位跨阵营（科技等级、数量都正常，只有阵营不对）。

**原因**：`GetCandidatePool` 里有一条跨阵营兜底：

```lua
if pool == nil or getn(pool) == 0 then
    pool = AICOMP.BuildAllFactionPool(tier, band)   -- 把 4 个阵营的同档单位合并
end
```

它的触发条件不是「稀有情况」而是「本阵营这一档恰好没有单位」——按 (阵营 × 阶级 × 类别) 切分后
这种空格非常多，于是绝大多数电脑都在用合并池，看起来就是「任何阵营都会出」。
`GetAnyTierPool`（抽卡模式）里也有同一条兜底。

**修正**：删除 `AICOMP.BuildAllFactionPool` 与两处调用；两个取池函数现在只返回本阵营的列表。
本阵营这一档没有可投单位时，`ResolveCategoryTier` 会按 T4→T3→T2→T1 往下退，
全都没有就跳过这一段（宁可这段少兵，也不出别的阵营的兵）。

**代价**：槽位 133/134（`SovietBomberAircraft` 基洛夫飞艇 / `CelestialAntiAirVehicleTech3` 神州 T3 磁弩形态）
只有苏联与神州有，所以盟军 / 帝国的电脑第 5 段恒为 0，总量会和参照玩家差这几只。这是「只投本阵营」的唯一遗留代价。

**帝国 T1 载具已补齐**：帝国没有独立的 T1 载具槽，但天狗机器人 `JapanAntiInfantryVehicle`
是载具 & 空军双形态（槽位 77 在空军段）。`BuildFactionPool` 改为两遍收集：
第一遍只认槽位分段，为空时第二遍按 `BanModeGetNameTypes` 登记的兵种再收一遍。
无禁用时只有两格会用到——(帝国 × 载具 × T1)←天狗机器人、(苏联 × 空军 × T4)←基洛夫飞艇。详见附录 D.11。

改动对照：

| 位置 | 改前 | 改后 |
|---|---|---|
| `AICOMP.BuildAllFactionPool` | 4 阵营合并 | 删除 |
| `AICOMP.GetCandidatePool` | 本阵营空 → 合并池 | 本阵营空 → 空表（由 `ResolveCategoryTier` 降档） |
| `AICOMP.GetAnyTierPool` | 本阵营空 → 合并池 | 本阵营空 → 空表 |

### 8.2 登神符文的目标单位核查（只查，未改动）

登神的目标候选来源 = `PickBuyTwoGetOneTarget`（与买二送一共用）：

```
本阵营四类回收表 g_RecycleBtnsMapByFaction[faction]
  ∩ g_UnitNameToUnitIndex 里有（必须在 UNITLIST 里占一个槽位）
  ∩ g_PureDrawBuildableUnitPool 可生产（BuildBuyTwoGetOneTargetFilter）
  ∩ 不是 LockPlayerProduction
  ∩ 不在 HextechRune.RuneTargetExcludedTypes 黑名单
  ∩ BanModeRecycleCategoryEnabled(类别) == 1
```

逐项核查结果：

| 单位 | 回收表 | UNITLIST 槽位 | 可生产 | 黑名单 | 结论 |
|---|---|---|---|---|---|
| `AlliedAntiGroundAircraft`（维护者轰炸机） | `g_AirCraftAllied` 第 1 项 | 有（空军段） | T1 池 | **已加入** | **已按策划要求排除**（轰炸机不进登神/究极生物） |
| `AlliedChronoBeacon_Vindicator` | — | — | — | **已加入** | 全项目搜不到这个单位名，条目先按防御性写好 |
| `CelestialHeavyAntiAirVehicleTech3`（祝融雷铳战车） | `g_VehicleCelestial` | 有（载具段） | T3 池 | 不在 | **可当登神目标**，按策划要求保持不变 |
| `CelestialAntiVehicleVehicleTech3_EMC` | 不在表内 | 不在 UNITLIST | — | — | 是 `CelestialAntiVehicleVehicleTech3` 的**生产别名**（基础型在 `g_VehicleCelestial`，可选），候选按基础型出 |

**已落地的改动**：`HextechRune.RuneTargetExcludedTypes` 增加两条（该黑名单只作用于**登神**与**究极生物**，
买二送一仍可圈维护者）：

```lua
AlliedAntiGroundAircraft = true,                -- 维护者轰炸机
AlliedChronoBeacon_Vindicator = true,           -- 维护者轰炸机（信标形态，防御性条目）
```

究极生物本来就只从 T3/T4 独立名单里抽（维护者是 T1，本来也抽不到），这一条把口径写明。

- 四阵营完整单位 / 分段 / 阶级表见 **`analysis/4阵营单位与阶级表.md`**（从源码复刻生成）；
  4 阵营 × 5 分段 × 4 阶级共 80 格，其中 **23 格为空**——这就是改前跨阵营兜底的触发来源。
- `AlliedChronoBeacon_Vindicator` 在整个 `lua/` 与 `ScriptsData.json` 里都搜不到；唯一的
  `AlliedChronoBeacon_*` 是 `AlliedChronoBeacon_Harbinger`（先锋炮艇机的信标形态），
  而它只出现在 `BUFF_1.lua` 的索敌滤镜里，不在回收表、不在抽卡池、也不在 `UNITLIST`，
  所以它也当不了登神目标。如果策划想要这个单位，需要先把模板名确认下来。
- `CelestialAntiVehicleVehicleTech3_EMC` 在 `g_PureDrawProductionAliases` 里挂在
  `CelestialAntiVehicleVehicleTech3` 名下（`02_data.lua:165`），属于「升级形态」而不是独立兵种；
  `CollectBuyTwoGetOneCandidates` 用 `info.CountType or info.Type` 取类型，所以候选里出现的是
  基础型 `CelestialAntiVehicleVehicleTech3`（本身在 `g_VehicleCelestial` 与 `UNITLIST` 里，可选）。
  登神的 Buff 是按槽位号匹配的（`ApplyAscensionUnits` 里 `assignment.UnitIndex == rune.TargetUnitIndex`），
  基础型占的槽位固定，所以 EMC 形态的单位同样吃得到这份 Buff，不需要单独加一条。

### 8.3 计数口径与禁用模式兼容（已核实，无需改动）

**计数口径**：双形态单位只按**槽位**计一次（`CollectCategoryState` 不变）。
理由：① 参照侧（真人）与电脑侧必须用同一套口径，否则数量永远对不齐；
② 跨段补位受 `ApplySeat` 的 `need`（总数差）硬性封顶，偏差不会滚雪球；
③ 全矩阵只有一格真的用到（帝国×2 载具×T1），为它改统计口径不划算。
副作用举例：参照玩家出 4 个 T1 载具、0 空军，帝国用 4 个天狗补，天狗记在第 3 段，
于是第 3 段变成 4、第 2 段仍是 0——总数吻合，构成偏向空军，下一回合 `need = 0` 后不再追加。

**禁用模式**：`BuildFactionPool` / `CollectFactionPool` 全程用 `BanModeIsSlotBanned(unitIndex) == 0` 过滤，
与出兵批次、抽卡池用的是同一个判定，因此「登记兵种全被禁才算禁用」的双形态规则自动生效。
逐配置模拟见 `analysis/4阵营单位与阶级表.md` 的 E 节。禁用模式下真人自己也出不了被禁的兵，
`refState.Cat[band]` 同样为 0，所以对应分段本来就没有缺口。

**超级要塞**：不在 `UNITLIST` + 带 `CountType`，AICOMP 永远投不出，双形态登记对它无影响。

### 8.4 T5 单位一律按 T4 算

四阵营的 T5 不对称（青龙 / 东风是神州，奥林匹斯是盟军，千鸟 / 超级要塞是帝国），凑不齐一张 T5 表。
`AICOMP.GetUnitTier` 新增 `g_UnitTierAtLeastFour` 名单，命中即返回 4：

青龙八形态、`CelestialDF41` 东风、`AlliedGaintAirCraftCarrier_B` 奥林匹斯、
`JapanYumiAircraftCarrier` 千鸟、`JapanGigaFortressShip` / `JapanGigaFortressShipEgg` /
`JapanFortressShip` / `JapanGigaFortress_Land` 超级要塞四形态。

改前这批单位会被判成 **T1**（不在抽卡池、名字无 `TechN`、不在回收表所以没有回收价，掉到最后一句 `return 1`），
参照玩家带着千鸟 / 奥林匹斯时 `MaxTier` 被拉低，电脑会照着 T1 出最便宜的兵。
`UNITLIST` 里「三样都查不到」的共 27 个，只用显式名单收 T5，其余（郁金香、守护神、夜莺、箱子坦克等）不动。

至此三层兜底完整：阶级自动降级 → 双形态补位 → T5 按 T4。仍为空且无法降级的只有
盟军 / 帝国的第 5 段（该段只有基洛夫飞艇与神州 T3 磁弩形态）。

### 8.5 内测单位剔除与退档阶梯确认

「`日冕单位信息汇总.txt` 里查不到中文名」= 未发布的内测单位，新增 `g_AICOMPBetaOnlyUnitTypes`
把它们挡在电脑卡池外：`AlliedAirForceDispatchVehicle`、`SovietPineElectronicRadarTruck`、
`JapanAntiAirVehicleTech3`（三个都在 UNITLIST 杂项段，本来就不出兵）与
`CelestialAntiAirVehicleTech3`（槽 134，额外段，T3，剔除后「神州 × 5 额外」整段为空）。

退档阶梯确认与需求一致：目标阶级 = `min(参照玩家该分段最高阶级, 本方科技)`，**从 T4 一路下退到 T1**，
T5 不存在（按 T4 处理）。整条阶梯都空才返回 0 并跳过该分段。

# 4 阵营单位与阶级表（源码解析生成，勿手改）

中文名取自 `日冕地图lua例子/日冕单位信息汇总.txt`（421 条单位条目，按单位 ID / 按钮代码匹配）；分段、阶级、双形态补位、内测单位、禁用模式池子由 `UNITCOUNTERINI_0.lua` / `RecycleUnit.lua` / `02_data.lua` / `AICOMP.*` 复刻计算。

阶级判定优先级：T5 超武名单（青龙 / 东风 / 奥林匹斯 / 千鸟 / 超级要塞，一律算 T4）→ 抽卡生产池 `g_PureDrawBuildableUnitPool` 的 Tier → 名字里的 `TechN` → 回收价（>3000=T4，>1800=T3，>1000=T2，其余 T1）。

| 分段 | 槽位 | 出兵批次 |
|---|---|---|
| 1 步兵 | 1..20 | `UNITSPST(1, step1, INFANT*)` |
| 2 载具 | 21..76 | `UNITSPST(step1+1, step3, LIGHTVEH*)` |
| 3 空军 | 77..107 | 空军批次 |
| 4 海军 | 108..132 | `UNITSPSHIP(step35+1, step4, AIRSP*)` |
| 5 额外 | 133..134 | `UNITSPAIRST(step4+1, step5, INFANTSP, AIR*)` |

## A. 矩阵：阵营 × 出兵分段 × 阶级（中文名）

标 **（双）** 的是靠双形态跨兵种补进来的（自己槽位在别的分段）；**内测单位已剔除**，不参与任何一格。

| 阵营 | 分段 | T1 | T2 | T3 | T4 |
|---|---|---|---|---|---|
| 盟军 | 1 步兵 | 标枪兵`AlliedAntiVehicleInfantry`<br>游骑兵`AlliedRangerInfantry`<br>维和步兵`AlliedAntiInfantryInfantry`<br>警犬`AlliedScoutInfantry` | **—** | 冰冻军团`AlliedCryoLegionnaire`<br>谭雅`AlliedCommandoTech1` | **—** |
| 盟军 | 2 载具 | 激流`AlliedAntiInfantryVehicle_Ground` | 光棱坦克`prismtank`<br>守护者坦克`AlliedAntiVehicleVehicleTech1` | 幻影坦克`AlliedAntiVehicleVehicleTech3`<br>雅典娜炮`AlliedAntiStructureVehicle` | 未来坦克X-1`AlliedFutureTank`<br>特洛伊突击要塞`AlliedBattleFortress` |
| 盟军 | 3 空军 | 维护者轰炸机`AlliedAntiGroundAircraft`<br>阿波罗战斗机`AlliedFighterAircraft` | 冰冻直升机`AlliedSupportAircraft` | 世纪轰炸机`AlliedAntiStructureBomberAircraft`<br>世纪轰炸机`AlliedBomberAircraft`<br>阿瑞斯截击机`AlliedInterceptorAircraft` | 先锋武装炮艇机`AlliedAC130GunshipAircraft`<br>先锋武装炮艇机`AlliedGunshipAircraft` |
| 盟军 | 4 海军 | 水翼船`AlliedAntiAirShip`<br>海豚`AlliedAntiNavalScout`<br>激流`AlliedAntiInfantryVehicle` | 突袭驱逐舰`AlliedAntiNavyShipTech1` | 波塞冬巡洋舰`AlliedAntiNavyShipTech3` | 航空母舰`AlliedAntiStructureShip` |
| 盟军 | 5 额外 | **—** | **—** | **—** | **—** |
| 苏联 | 1 步兵 | 征召兵`SovietAntiInfantryInfantry`<br>战熊`SovietScoutInfantry`<br>防空部队`SovietAntiVehicleInfantry` | 磁爆部队`SovietHeavyAntiVehicleInfantry` | 娜塔莎`SovietCommandoTech1` | **—** |
| 苏联 | 2 载具 | 恐怖机器人`SovietScoutVehicle`<br>火炮机车`SovietMortarCycle`<br>镰刀机甲`SovietAntiInfantryVehicle` | 犀牛坦克`SovietHeavyAntiVehicleVehicleTech2`<br>磁爆坦克`SovietAntiVehicleVehicleTech2`<br>重锤突击炮`SovietSledgehammerSPG` | V4`SovietAntiStructureVehicle`<br>天启坦克`SovietAntiVehicleVehicleTech3` | 联盟重型坦克`SovietAntiVehicleVehicleTech4` |
| 苏联 | 3 空军 | 双刃直升机`SovietAntiGroundAircraft`<br>米格战斗机`SovietFighterAircraft` | **—** | 伊尔攻击机`SovietAntiGroundAttacker`<br>纤夫运输直升机`SovietTransportAircraft`<br>苏霍伊截击机`SovietInterceptorAircraft` | 基洛夫飞艇`SovietBomberAircraft`**（双）** |
| 苏联 | 4 海军 | 磁爆快艇`SovietAntiNavyShipTech1` | 阿库拉攻击潜艇`SovietAntiNavyShipTech2` | 光荣级导弹巡洋舰`SovietAntiNavyShipTech3` | 无畏级武库舰`SovietAntiStructureShip` |
| 苏联 | 5 额外 | **—** | **—** | **—** | 基洛夫飞艇`SovietBomberAircraft` |
| 帝国 | 1 步兵 | 坦克杀手`JapanAntiVehicleInfantry`<br>帝国武士`JapanAntiInfantryInfantry`<br>弓箭少女`JapanArcherInfantry` | 忍者`JapanInfiltrationInfantry` | 欧米伽百合子`JapanCommandoTech1` | **—** |
| 帝国 | 2 载具 | 天狗机器人`JapanAntiInfantryVehicle`**（双）** | 海啸坦克`JapanAntiVehicleVehicleTech1`<br>钢铁浪人`JapanSentinelVehicle` | 波能坦克`JapanAntiStructureVehicle`<br>鬼王`JapanAntiVehicleVehicleTech3` | 鬼王X`JapanMechaX` |
| 帝国 | 3 空军 | 天狗机器人`JapanAntiInfantryVehicle`<br>爆裂机器人`JapanScoutInfantry`<br>鬼樱特攻机`JapanSakuraAttackRocket` | 打击者-VX`JapanAntiAirVehicleTech1` | 心神机甲`JapanMissileMechaAdvanced`<br>樱花回天雷`JapanInterceptorAircraft`<br>火箭天使`JapanAntiVehicleInfantryTech3` | **—** |
| 帝国 | 4 海军 | 长枪迷你潜艇`JapanNavyScoutShip` | 海翼`JapanAntiAirShip`<br>薙刀驱逐舰`JapanAntiVehicleShip` | 太刀重巡洋舰`JapanAntiNavyShipTech3` | 将军战列舰`JapanAntiStructureShip` |
| 帝国 | 5 额外 | **—** | **—** | **—** | **—** |
| 神州 | 1 步兵 | 破甲铁卫`CelestialAntiVehicleInfantry`<br>龙炎军`CelestialAntiInfantryInfantry` | 岚影刺`CelestialInfiltrationInfantry` | 迅雷天罡`CelestialAntiInfantryInfantryAdvanced` | **—** |
| 神州 | 2 载具 | 凌波护卫战车`CelestialAntiInfantryVehicle_B`<br>磁弩防空系统`CelestialAntiAirShip`<br>磁弩高射炮`CelestialAntiAirVehicle` | 青锋导弹车`CelestialLongRangeMissileVehicle`<br>青锋导弹车`CelestialLongRangeMissileVehicle_B`<br>麒麟破阵战车`CelestialAntiVehicleVehicleTech1` | 白虎量子重炮运载车`CelestialAntiStructureVehicle`<br>祝融攻坚战车`CelestialAntiVehicleVehicleTech3`<br>祝融雷铳战车`CelestialHeavyAntiAirVehicleTech3` | 破军金甲`CelestialAntiVehicleVehicleTech4` |
| 神州 | 3 空军 | 凤凰战机`CelestialFighterAircraft`<br>天眼哨机`CelestialScoutDrone`<br>毕方支援机`CelestialSupportAircraft` | 朱雀攻击机`CelestialAttackerAircraft` | 重明截击机`CelestialInterceptorAircraft`<br>金乌轰炸机`CelestialBomberAircraft` | 摇光巡天炮`CelestialAdvanceAircraftTech4` |
| 神州 | 4 海军 | 乌篷猎船`CelestialAntiNavyShipTech1` | 计蒙驱逐舰`CelestialAlmightlyShip` | 玄冥级战列巡洋舰`CelestialAntiNavyShipTech3` | 玄武级攻击潜艇`CelestialAntiStructureShip` |
| 神州 | 5 额外 | **—** | **—** | **—** | **—** |

## B. 逐单位明细

| 阵营 | 回收类别 | 中文名 | 模板名 | 槽 | 槽位分段 | 登记兵种 | 阶级 | 回收价 | 备注 |
|---|---|---|---|---|---|---|---|---|---|
| 盟军 | 步兵 | 谭雅 | `AlliedCommandoTech1` | 3 | 1 步兵 | infantry | T3 | 2000 |  |
| 盟军 | 步兵 | 冰冻军团 | `AlliedCryoLegionnaire` | 4 | 1 步兵 | infantry | T3 | 1600 |  |
| 盟军 | 步兵 | 维和步兵 | `AlliedAntiInfantryInfantry` | 5 | 1 步兵 | infantry | T1 | 200 |  |
| 盟军 | 步兵 | 警犬 | `AlliedScoutInfantry` | 9 | 1 步兵 | infantry | T1 | 200 |  |
| 盟军 | 步兵 | 游骑兵 | `AlliedRangerInfantry` | 11 | 1 步兵 | infantry | T1 | 200 |  |
| 盟军 | 步兵 | 标枪兵 | `AlliedAntiVehicleInfantry` | 20 | 1 步兵 | infantry | T1 | 300 |  |
| 盟军 | 载具 | 激流 | `AlliedAntiInfantryVehicle_Ground` | 21 | 2 载具 | vehicle | T1 | 750 |  |
| 盟军 | 载具 | 守护者坦克 | `AlliedAntiVehicleVehicleTech1` | 22 | 2 载具 | vehicle | T2 | 950 |  |
| 盟军 | 载具 | 幻影坦克 | `AlliedAntiVehicleVehicleTech3` | 23 | 2 载具 | vehicle | T3 | 1600 |  |
| 盟军 | 载具 | 雅典娜炮 | `AlliedAntiStructureVehicle` | 43 | 2 载具 | vehicle | T3 | 1800 |  |
| 盟军 | 载具 | 光棱坦克 | `prismtank` | 44 | 2 载具 | vehicle | T2 | 1400 |  |
| 盟军 | 载具 | 未来坦克X-1 | `AlliedFutureTank` | 45 | 2 载具 | vehicle | T4 | 3200 |  |
| 盟军 | 载具 | 特洛伊突击要塞 | `AlliedBattleFortress` | 54 | 2 载具 | vehicle | T4 | 4500 |  |
| 盟军 | 空军 | 维护者轰炸机 | `AlliedAntiGroundAircraft` | 82 | 3 空军 | aircraft | T1 | 1200 |  |
| 盟军 | 空军 | 先锋武装炮艇机 | `AlliedAC130GunshipAircraft` | 83 | 3 空军 | aircraft | T4 | 4000 |  |
| 盟军 | 空军 | 世纪轰炸机 | `AlliedAntiStructureBomberAircraft` | 84 | 3 空军 | aircraft | T3 | 2500 |  |
| 盟军 | 空军 | 世纪轰炸机 | `AlliedBomberAircraft` | 85 | 3 空军 | aircraft | T3 | 2500 |  |
| 盟军 | 空军 | 先锋武装炮艇机 | `AlliedGunshipAircraft` | 86 | 3 空军 | aircraft | T4 | 4000 |  |
| 盟军 | 空军 | 阿瑞斯截击机 | `AlliedInterceptorAircraft` | 87 | 3 空军 | aircraft | T3 | 1600 |  |
| 盟军 | 空军 | 冰冻直升机 | `AlliedSupportAircraft` | 89 | 3 空军 | aircraft | T2 | 1600 |  |
| 盟军 | 空军 | 阿波罗战斗机 | `AlliedFighterAircraft` | 90 | 3 空军 | aircraft | T1 | 1000 |  |
| 盟军 | 海军 | 航空母舰 | `AlliedAntiStructureShip` | 110 | 4 海军 | navy | T4 | 5500 |  |
| 盟军 | 海军 | 激流 | `AlliedAntiInfantryVehicle` | 112 | 4 海军 | navy | T1 | 750 |  |
| 盟军 | 海军 | 水翼船 | `AlliedAntiAirShip` | 113 | 4 海军 | navy | T1 | 900 |  |
| 盟军 | 海军 | 海豚 | `AlliedAntiNavalScout` | 114 | 4 海军 | navy | T1 | 750 |  |
| 盟军 | 海军 | 波塞冬巡洋舰 | `AlliedAntiNavyShipTech3` | 115 | 4 海军 | navy | T3 | 4000 |  |
| 盟军 | 海军 | 突袭驱逐舰 | `AlliedAntiNavyShipTech1` | 125 | 4 海军 | navy | T2 | 1600 |  |
| 盟军 | 载具 | 多功能步兵战车 | `AlliedAntiAirVehicleTech1` | 136 | 杂项 | vehicle | T1 | 800 |  |
| 盟军 | 载具 | **缺中文名** | `AlliedAirForceDispatchVehicle` | 137 | 杂项 | vehicle | T3 | 2500 | **内测** |
| 苏联 | 步兵 | 娜塔莎 | `SovietCommandoTech1` | 1 | 1 步兵 | infantry | T3 | 2000 |  |
| 苏联 | 步兵 | 征召兵 | `SovietAntiInfantryInfantry` | 15 | 1 步兵 | infantry | T1 | 100 |  |
| 苏联 | 步兵 | 防空部队 | `SovietAntiVehicleInfantry` | 16 | 1 步兵 | infantry | T1 | 400 |  |
| 苏联 | 步兵 | 磁爆部队 | `SovietHeavyAntiVehicleInfantry` | 17 | 1 步兵 | infantry | T2 | 850 |  |
| 苏联 | 步兵 | 战熊 | `SovietScoutInfantry` | 19 | 1 步兵 | infantry | T1 | 225 |  |
| 苏联 | 载具 | 镰刀机甲 | `SovietAntiInfantryVehicle` | 31 | 2 载具 | vehicle | T1 | 900 |  |
| 苏联 | 载具 | 磁爆坦克 | `SovietAntiVehicleVehicleTech2` | 33 | 2 载具 | vehicle | T2 | 1200 |  |
| 苏联 | 载具 | 犀牛坦克 | `SovietHeavyAntiVehicleVehicleTech2` | 34 | 2 载具 | vehicle | T2 | 1100 |  |
| 苏联 | 载具 | 重锤突击炮 | `SovietSledgehammerSPG` | 35 | 2 载具 | vehicle | T2 | 1500 |  |
| 苏联 | 载具 | 恐怖机器人 | `SovietScoutVehicle` | 36 | 2 载具 | vehicle | T1 | 600 |  |
| 苏联 | 载具 | V4 | `SovietAntiStructureVehicle` | 37 | 2 载具 | vehicle | T3 | 1600 |  |
| 苏联 | 步兵 | 火炮机车 | `SovietMortarCycle` | 42 | 2 载具 | infantry | T1 | 750 |  |
| 苏联 | 载具 | 天启坦克 | `SovietAntiVehicleVehicleTech3` | 51 | 2 载具 | vehicle | T3 | 2000 |  |
| 苏联 | 载具 | 联盟重型坦克 | `SovietAntiVehicleVehicleTech4` | 52 | 2 载具 | vehicle | T4 | 4500 |  |
| 苏联 | 空军 | 双刃直升机 | `SovietAntiGroundAircraft` | 97 | 3 空军 | aircraft | T1 | 1200 |  |
| 苏联 | 空军 | 伊尔攻击机 | `SovietAntiGroundAttacker` | 98 | 3 空军 | aircraft | T3 | 2500 |  |
| 苏联 | 空军 | 米格战斗机 | `SovietFighterAircraft` | 99 | 3 空军 | aircraft | T1 | 1000 |  |
| 苏联 | 空军 | 纤夫运输直升机 | `SovietTransportAircraft` | 100 | 3 空军 | aircraft | T3 | 2000 |  |
| 苏联 | 空军 | 苏霍伊截击机 | `SovietInterceptorAircraft` | 101 | 3 空军 | aircraft | T3 | 1800 |  |
| 苏联 | 海军 | 无畏级武库舰 | `SovietAntiStructureShip` | 109 | 4 海军 | navy | T4 | 5000 |  |
| 苏联 | 海军 | 阿库拉攻击潜艇 | `SovietAntiNavyShipTech2` | 123 | 4 海军 | navy | T2 | 2000 |  |
| 苏联 | 海军 | 光荣级导弹巡洋舰 | `SovietAntiNavyShipTech3` | 124 | 4 海军 | navy | T3 | 4500 |  |
| 苏联 | 海军 | 磁爆快艇 | `SovietAntiNavyShipTech1` | 126 | 4 海军 | navy | T1 | 1000 |  |
| 苏联 | 空军 | 基洛夫飞艇 | `SovietBomberAircraft` | 133 | 5 额外 | aircraft | T4 | 3600 |  |
| 苏联 | 载具 | 牛蛙战车 | `SovietAntiAirShip` | 135 | 杂项 | vehicle | T1 | 900 |  |
| 苏联 | 载具 | **缺中文名** | `SovietPineElectronicRadarTruck` | 139 | 杂项 | vehicle | T3 | 2500 | **内测** |
| 帝国 | 步兵 | 欧米伽百合子 | `JapanCommandoTech1` | 2 | 1 步兵 | infantry | T3 | 2000 |  |
| 帝国 | 步兵 | 帝国武士 | `JapanAntiInfantryInfantry` | 12 | 1 步兵 | infantry | T1 | 100 |  |
| 帝国 | 步兵 | 坦克杀手 | `JapanAntiVehicleInfantry` | 13 | 1 步兵 | infantry | T1 | 300 |  |
| 帝国 | 步兵 | 弓箭少女 | `JapanArcherInfantry` | 14 | 1 步兵 | infantry | T1 | 400 |  |
| 帝国 | 步兵 | 忍者 | `JapanInfiltrationInfantry` | 18 | 1 步兵 | infantry | T2 | 850 |  |
| 帝国 | 载具 | 海啸坦克 | `JapanAntiVehicleVehicleTech1` | 29 | 2 载具 | vehicle | T2 | 1400 |  |
| 帝国 | 载具 | 钢铁浪人 | `JapanSentinelVehicle` | 30 | 2 载具 | vehicle | T2 | 1400 |  |
| 帝国 | 载具 | 波能坦克 | `JapanAntiStructureVehicle` | 39 | 2 载具 | vehicle | T3 | 1800 |  |
| 帝国 | 载具 | 鬼王 | `JapanAntiVehicleVehicleTech3` | 49 | 2 载具 | vehicle | T3 | 2200 |  |
| 帝国 | 载具 | 鬼王X | `JapanMechaX` | 50 | 2 载具 | vehicle | T4 | 4500 |  |
| 帝国 | 载具 | 天狗机器人 | `JapanAntiInfantryVehicle` | 77 | 3 空军 | vehicle、aircraft | T1 | 800 |  |
| 帝国 | 载具 | 心神机甲 | `JapanMissileMechaAdvanced` | 78 | 3 空军 | vehicle、aircraft | T3 | 1800 |  |
| 帝国 | 载具 | 打击者-VX | `JapanAntiAirVehicleTech1` | 79 | 3 空军 | vehicle、aircraft | T2 | 1200 |  |
| 帝国 | 步兵 | 爆裂机器人 | `JapanScoutInfantry` | 80 | 3 空军 | infantry | T1 | 300 |  |
| 帝国 | 步兵 | 火箭天使 | `JapanAntiVehicleInfantryTech3` | 95 | 3 空军 | infantry、aircraft | T3 | 1000 |  |
| 帝国 | 载具 | 樱花回天雷 | `JapanInterceptorAircraft` | 96 | 3 空军 | aircraft | T3 | 850 |  |
| 帝国 | 空军 | 鬼樱特攻机 | `JapanSakuraAttackRocket` | 104 | 3 空军 | aircraft | T1 |  |  |
| 帝国 | 海军 | 将军战列舰 | `JapanAntiStructureShip` | 108 | 4 海军 | navy | T4 | 6300 |  |
| 帝国 | 海军 | 薙刀驱逐舰 | `JapanAntiVehicleShip` | 119 | 4 海军 | navy | T2 | 2000 |  |
| 帝国 | 海军 | 长枪迷你潜艇 | `JapanNavyScoutShip` | 120 | 4 海军 | navy | T1 | 800 |  |
| 帝国 | 海军 | 海翼 | `JapanAntiAirShip` | 121 | 4 海军 | aircraft、navy | T2 | 1100 |  |
| 帝国 | 海军 | 太刀重巡洋舰 | `JapanAntiNavyShipTech3` | 122 | 4 海军 | navy | T3 | 4500 |  |
| 帝国 | 载具 | **缺中文名** | `JapanAntiAirVehicleTech3` | 138 | 杂项 | vehicle | T3 | 2500 | **内测** |
| 神州 | 步兵 | 迅雷天罡 | `CelestialAntiInfantryInfantryAdvanced` | 6 | 1 步兵 | infantry | T3 | 1400 |  |
| 神州 | 步兵 | 龙炎军 | `CelestialAntiInfantryInfantry` | 7 | 1 步兵 | infantry | T1 | 225 |  |
| 神州 | 步兵 | 破甲铁卫 | `CelestialAntiVehicleInfantry` | 8 | 1 步兵 | infantry | T1 | 500 |  |
| 神州 | 步兵 | 岚影刺 | `CelestialInfiltrationInfantry` | 10 | 1 步兵 | infantry | T2 | 850 |  |
| 神州 | 载具 | 磁弩防空系统 | `CelestialAntiAirShip` | 24 | 2 载具 | vehicle | T1 | 900 |  |
| 神州 | 载具 | 磁弩高射炮 | `CelestialAntiAirVehicle` | 25 | 2 载具 | vehicle | T1 | 900 |  |
| 神州 | 载具 | 凌波护卫战车 | `CelestialAntiInfantryVehicle_B` | 26 | 2 载具 | vehicle | T1 | 850 |  |
| 神州 | 载具 | 麒麟破阵战车 | `CelestialAntiVehicleVehicleTech1` | 27 | 2 载具 | vehicle | T2 | 1000 |  |
| 神州 | 载具 | 青锋导弹车 | `CelestialLongRangeMissileVehicle` | 28 | 2 载具 | vehicle | T2 | 1400 |  |
| 神州 | 载具 | 白虎量子重炮运载车 | `CelestialAntiStructureVehicle` | 40 | 2 载具 | vehicle | T3 | 1800 |  |
| 神州 | 载具 | 青锋导弹车 | `CelestialLongRangeMissileVehicle_B` | 41 | 2 载具 | vehicle | T2 | 1400 |  |
| 神州 | 载具 | 祝融攻坚战车 | `CelestialAntiVehicleVehicleTech3` | 46 | 2 载具 | vehicle | T3 | 2000 |  |
| 神州 | 载具 | 破军金甲 | `CelestialAntiVehicleVehicleTech4` | 47 | 2 载具 | vehicle | T4 | 4500 |  |
| 神州 | 载具 | 祝融雷铳战车 | `CelestialHeavyAntiAirVehicleTech3` | 48 | 2 载具 | vehicle | T3 | 2000 |  |
| 神州 | 步兵 | 天眼哨机 | `CelestialScoutDrone` | 81 | 3 空军 | infantry | T1 | 200 |  |
| 神州 | 空军 | 金乌轰炸机 | `CelestialBomberAircraft` | 91 | 3 空军 | aircraft | T3 | 2500 |  |
| 神州 | 空军 | 凤凰战机 | `CelestialFighterAircraft` | 92 | 3 空军 | aircraft | T1 | 1000 |  |
| 神州 | 空军 | 朱雀攻击机 | `CelestialAttackerAircraft` | 93 | 3 空军 | aircraft | T2 | 1400 |  |
| 神州 | 空军 | 重明截击机 | `CelestialInterceptorAircraft` | 94 | 3 空军 | aircraft | T3 | 1600 |  |
| 神州 | 空军 | 毕方支援机 | `CelestialSupportAircraft` | 102 | 3 空军 | aircraft | T1 | 1200 |  |
| 神州 | 空军 | 摇光巡天炮 | `CelestialAdvanceAircraftTech4` | 103 | 3 空军 | aircraft | T4 | 5000 |  |
| 神州 | 海军 | 玄武级攻击潜艇 | `CelestialAntiStructureShip` | 111 | 4 海军 | navy | T4 | 5000 |  |
| 神州 | 海军 | 计蒙驱逐舰 | `CelestialAlmightlyShip` | 116 | 4 海军 | navy | T2 | 2000 |  |
| 神州 | 海军 | 乌篷猎船 | `CelestialAntiNavyShipTech1` | 117 | 4 海军 | navy | T1 | 800 |  |
| 神州 | 海军 | 玄冥级战列巡洋舰 | `CelestialAntiNavyShipTech3` | 118 | 4 海军 | navy | T3 | 4500 |  |
| 神州 | 载具 | **缺中文名** | `CelestialAntiAirVehicleTech3` | 134 | 5 额外 | vehicle | T3 | 2500 | **内测** |

## C. 内测单位（不进电脑卡池）

「`日冕单位信息汇总.txt` 里查不到中文名」= 还没发布的内测内容，统一登记在 `AIINI_1.lua` 的 `g_AICOMPBetaOnlyUnitTypes`，`CollectFactionPool` 直接跳过。

| 模板 | 阵营 | 槽 | 槽位分段 | 阶级 | 说明 |
|---|---|---|---|---|---|
| `AlliedAirForceDispatchVehicle` | 盟军 | 137 | 杂项 | T3 | 在 UNITLIST 杂项段（137），本来就不会出兵 |
| `SovietPineElectronicRadarTruck` | 苏联 | 139 | 杂项 | T3 | 在 UNITLIST 杂项段（139），本来就不会出兵 |
| `JapanAntiAirVehicleTech3` | 帝国 | 138 | 杂项 | T3 | 在 UNITLIST 杂项段（138），本来就不会出兵 |
| `CelestialAntiAirVehicleTech3` | 神州 | 134 | 5 额外 | T3 | 在额外段（134），是唯一一个会出兵的，已剔除 |

## D. 三层兜底与退档

`AICOMP.ResolveCategoryTier`：目标阶级 = `min(参照玩家该分段最高阶级, 本方科技等级)`，本阵营该阶级投不出来就**逐级往下退到 T1**，全空返回 0 → 跳过该分段。**不会往上退。**

三层兜底的顺序：① 阶级自动降级 T4→T3→T2→T1 → ② 双形态跨兵种补位 → ③ T5 单位一律按 T4。

| 情况 | 空格 | 后果 |
|---|---|---|
| 有更低阶级可退 | 盟军步兵 T2、苏联步兵 T4、苏联空军 T2、帝国步兵 T4、帝国空军 T4、神州步兵 T4、盟军步兵 T4 | 无影响，自动退到本阵营更低阶 |
| 第 2 遍命中双形态 | 苏联空军 T4←基洛夫、帝国载具 T1←天狗 | 数量补齐，构成略偏向双形态登记的兵种 |
| 该分段本阵营整体没有 | 盟军 × 5 额外、帝国 × 5 额外、神州 × 5 额外 | 跳过这一段，数量少几只 |

无禁用时双形态补位：苏联 × 3 空军 × T4 ← 基洛夫飞艇；帝国 × 2 载具 × T1 ← 天狗机器人。


## E. 禁用模式 × 双形态（模拟）

| 禁用 | 整段为空 | 双形态补位仍生效 |
|---|---|---|
| 无 | 盟军×5 额外、帝国×5 额外、神州×5 额外 | 苏联×3 空军 T4←基洛夫飞艇；帝国×2 载具 T1←天狗机器人 |
| 禁aircraft | 盟军×3 空军、盟军×5 额外、苏联×3 空军、苏联×5 额外、帝国×5 额外、神州×5 额外 | 帝国×2 载具 T1←天狗机器人 |
| 禁vehicle | 盟军×2 载具、盟军×5 额外、帝国×5 额外、神州×2 载具、神州×5 额外 | 苏联×3 空军 T4←基洛夫飞艇；帝国×2 载具 T1←天狗机器人；帝国×2 载具 T2←打击者-VX；帝国×2 载具 T3←心神机甲 |
| 禁navy | 盟军×4 海军、盟军×5 额外、苏联×4 海军、帝国×5 额外、神州×4 海军、神州×5 额外 | 苏联×3 空军 T4←基洛夫飞艇；帝国×2 载具 T1←天狗机器人 |
| 禁infantry | 盟军×1 步兵、盟军×5 额外、苏联×1 步兵、帝国×5 额外、神州×1 步兵、神州×5 额外 | 苏联×3 空军 T4←基洛夫飞艇；帝国×1 步兵 T3←火箭天使；帝国×2 载具 T1←天狗机器人 |
| 禁aircraft+vehicle | 盟军×2 载具、盟军×3 空军、盟军×5 额外、苏联×3 空军、苏联×5 额外、帝国×2 载具、帝国×5 额外、神州×2 载具、神州×5 额外 | 帝国×3 空军 T2←海翼 |
| 禁aircraft+navy | 盟军×3 空军、盟军×4 海军、盟军×5 额外、苏联×3 空军、苏联×4 海军、苏联×5 额外、帝国×4 海军、帝国×5 额外、神州×4 海军、神州×5 额外 | 帝国×2 载具 T1←天狗机器人 |
| 禁navy+vehicle | 盟军×2 载具、盟军×4 海军、盟军×5 额外、苏联×4 海军、帝国×5 额外、神州×2 载具、神州×4 海军、神州×5 额外 | 苏联×3 空军 T4←基洛夫飞艇；帝国×2 载具 T1←天狗机器人；帝国×2 载具 T2←打击者-VX；帝国×2 载具 T3←心神机甲 |

注：第二列只是「池子空了」。禁用模式下真人自己也出不了被禁的兵，`refState.Cat[band]` 同样是 0，对应分段本来就没有缺口。

### 8.6 回归：Lua 4.0 outer-scope

`g_UnitTierAtLeastFour` / `g_AICOMPBandOfCategory` 原来写成了 `local`，
被 `AICOMP.GetUnitTier` / `AICOMP.UnitExtraBands` 引用 → Lua 4.0 解析期直接报
`cannot access a variable in outer scope`，游戏进不去。已改为全局变量。

新增 `analysis/tools/check_lua4_scope.py` 做静态检查（全库 170 个文件当前 0 违规），
以后改 lua 要跟 `check_lua_balance.py` 一起跑。

### 8.7 联机实测回归：基洛夫/超级要塞不可见导致空军不出、总数追不平

`CollectCategoryState` 由「槽位分段单口径」改为「槽位分段 ∪ 登记兵种段」：
基洛夫的槽位在 5 额外段但登记为空军，现在同时计入空军段，盟军电脑因此能看到「对面有 T4 空军」
并出先锋武装炮艇机。`Total` 仍每单位只算一次。

`ApplySeat` 增加第二轮总量兜底：第一轮逐段补完后 `need` 仍 > 0 时，轮转用本阵营投得出来的段
继续补，阶级取 `max(该段快照, 参照整体最高阶级)` 再受自身科技封顶——低科技电脑不会被硬拉上去。

超级要塞不在 `UNITLIST`，不进 `UNITCOUNT`，电脑侧看不到，无法针对性反应。

### 8.8 超级要塞可见化（CountType 独立计数槽）

超级要塞在 `g_AirCraftJapan` 空军页，但用独立计数槽 `g_UnitCount[FastHash("JapanGigaFortressShipEgg")]`，
不进 `UNITCOUNT`，因此 AICOMP 之前完全看不见它。新增 `AICOMP.AddCountTypeState`，
在 `CollectCategoryState` 末尾用 `GetRecycleUnitCount` 把本阵营回收表里 `CountType` 条目的数量
归到它在回收页所在的段（超级要塞 → 空军段），阶级按 T5→T4。

只处理没有 `UNITLIST` 槽的条目，避免和 `UNITCOUNT` 重复计数。
`CountsTowardArmyTotal = false` 与「计入 Total」的取舍见附录 D.17。

### 8.9 超级要塞统一进兵表（临时方案的退役）

8.8 的 `AICOMP.AddCountTypeState` 是**临时方案**，现已删除：超级要塞正式进 `UNITLIST` 第 135 格，
`CollectCategoryState` 直接通过 `UNITCOUNT` 就能看到它（`GetBandOfUnitIndex(135)=5`、
`GetUnitTier=4`、`UnitExtraBands` 声明 `aircraft` → 同时计入空军段）。

连带效果：`CollectFactionPool` 里 `info.CountType == nil` 的过滤因为回收表删掉了 `CountType` 而自然失效，
电脑可以投超级要塞了。加槽后帝国「3 空军 T4」这一格由跨段补位填成超级要塞，所以：

* 帝国电脑 vs 帝国真人 N 个超级要塞 → 出 N 个超级要塞
* 帝国电脑 vs 任何 T4 空军缺口（基洛夫 / 摇光 / 炮艇机）→ 也出超级要塞（已在预期内）

考古与完整改动清单见附录 D.17 / D.18。

### 8.10 限额单位的退让（摇光 3 / T4 大船 2）

* 上限值改读 `YAOGUANG_LIMIT` / `BIGSHIP_LIMIT`，不再写死 3 / 2。
* 上限判定改看**池内实际持有**（`AICOMP.CountCapGroup` 累加该组槽位的 `UNITCOUNT`），
  删掉只增不减的 `AICOMP.CapCount` / `MarkCapUsed`——否则摇光卖掉后电脑永远不再补。
* `ApplySeat` 逐段补兵改成 `while` 循环重解析阶级：摇光满 3 个后同一段自动退到 T3 空军，
  缺口不会掉到别的兵种段。

细节与验证表见附录 D.19。
