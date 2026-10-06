# 海克斯符文：开发/测试用代码备份

发版前已从 `lua/` 与 `ScriptsData.json` 中移除下列测试代码，全部内容备份在此，需要复测时按说明原样贴回即可。

> **当前状态（2026-09-29 深夜，第四次删除，准备发版）**：本轮改动实测全部通过（面板座位改为**按出生点坐标自动排序**、买二送一/登神排除 `LockPlayerProduction`、登神 5/3/2/1 + 每回合播报、以战养战改玩家独立可重复、彩卡概率上调、赌怪概率改为首轮口径），第 1 节的开局三选一测试事件**已整段删除**：`lua/` 与 `ScriptsData.json` 里 `EnableOpeningRealTest` / `OpeningTestTriggered` / `ShowOpeningTestEvent` / `testRuneIds` 计数均为 0，`02_event.lua` payload 回落到 45729 B（余 19807 B）。需要再复测时按本节贴回，**改完记得重跑 sync**。
>
> **2026-10-03 更新**：本节代码**目前又在 `lua/` 里并且已启用**（`HextechRune.EnableOpeningRealTest = true`、`OpeningTestTriggered = false`，见 `lua/GAME/HextechRune/02_event.lua` 顶部与 `OnRoundBegin`），当前组合为「神圣干预 / 时间裂隙 / 登神」，`02_event.lua` payload 48420 B（余 17113 B）。发版前仍按上文说明整段删除。
>
> 本轮实测用的组合：`{ "prismatic_divine_intervention", "prismatic_time_rift", "gold_ascension" }`（神圣干预 / 时间裂隙 / 登神，2026-10-03 第二次调整起；上一轮为 登神 / 时间裂隙 / 升级重组器，再上一轮为 登神 / 以战养战 / 升级重组器；登神与买二送一同属“选目标单位”型，需要 §1 里那个 `buy_two_get_one` / `ascension` 专属分支）。上一轮（重组器第三次调整）用的是 `{ "gold_ragnarok", "silver_recombobulator", "prismatic_upgrade_recombobulator" }`，当时 `02_event.lua` 曾回落到 43861 B。
>
> **2026-10-04（第五次删除，发版）**：本轮新增符文为「金·挖角 / 银·投资 / 棱彩·十连 / 棱彩·致命节奏 / 棱彩·吸星大法」（吸星大法按玩家符文保留赠予单位、十连按需升为棱彩级），第 1 节的开局三选一测试事件**已整段删除**：`lua/` 与 `ScriptsData.json` 里 `EnableOpeningRealTest` / `OpeningTestTriggered` / `ShowOpeningTestEvent` / `testRuneIds` 计数均为 0（自检脚本 `analysis/_check_release_clean.py`），`02_event.lua` payload 回落到 45127 B（余 20409 B）。§1 的三段备份已同步为本次删除的原文，贴回即可复测。
>
> 本轮实测组合：`{ "gold_drain", "prismatic_lethal_tempo", "gold_ten_pull" }`（吸星大法 / 致命节奏 / 十连，三个都无 `NeedsUnitType`，走 `CopyRuneForCandidate` 普通路径）。
>
> **2026-10-05 更新**：为复测「变形重组器降金 / 吸星大法降金且 10→7 / 塔防专家的埃奎斯槽位动态展开」，三段测试代码**已按本节重新贴回并启用**，`02_event.lua` payload 48417 B。同日第二轮把第三张卡换成新符文：当前组合为 `{ "prismatic_tower_defense_expert", "gold_drain", "gold_railgun_duel" }`（塔防专家 / 吸星大法 / 中门对狙），`02_event.lua` payload 48543 B（余 16993 B）。发版前仍按上文说明整段删除三段。
>
> **2026-10-06 更新**：当前组合为 `{ "prismatic_tower_defense_expert", "gold_drain", "gold_cryo_satellite" }`（塔防专家 / 吸星大法 / **冷冻卫星**，本轮新符文），`02_event.lua` payload 48770 B。第三张卡由中门对狙让位（其 2026-10-05 实测结论已回填设计文档 §7）。注意测试路径走 `FindRuneById` + `CopyRuneForCandidate`，**不经 `BuildFilteredPool`**，所以冷冻卫星的 `RequiredFaction = 1` 在这张测试卡上不生效——任何阵营的玩家都能点到它，正好用来验协议能否跨阵营释放；正式事件的阵营过滤另测。
>
> **2026-10-06 更新（二）**：组合改为 `{ "prismatic_tower_defense_expert", "gold_cryo_satellite", "gold_divine_might" }`（塔防专家 / 冷冻卫星 / **神威**），`02_event.lua` payload 48777 B（余 16759 B）。吸星大法让位（它 2026-10-05 已实测），换进本轮新符文神威；测试事件写死 3 张，加卡必须减卡。两张协议卡的赋予逻辑已合并到 `16_cryo_satellite.lua` 的 `ProtocolGrants` 表，冷冻卫星侧因此需要回归一次。
>
> **2026-10-06 更新（三）**：组合改为 `{ "silver_dragon_breathe", "gold_cryo_satellite", "gold_divine_might" }`（**龙息凌波** / 冷冻卫星 / 神威），`02_event.lua` 48777 → **48768 B（余 16768 B）**。塔防专家让位（2026-10-05 已实测），换进龙息凌波补一张银色形态替换卡。注意测试事件不经 `BuildFilteredPool`，`RequiredFaction = 4`（神州限定）在测试卡上不生效——非神州玩家选到它只登记持有，回收凌波护卫战车时不会替换形态，要用神州座位才测得出效果。
>
> **2026-10-06 更新（四）**：组合改为 `{ "silver_dragon_breathe", "prismatic_time_rift", "prismatic_shrink_ray" }`（龙息凌波 / **The World** / **天堂制造**），`02_event.lua` 48768 → **48771 B（余 16765 B）**。两张协议卡按用户要求先不上线：`01_rune_pool.lua` 条目 + `NonRepeatableRuneIds` 两个键 + `04_buff.lua` 派发分支三处一起注释，`16_cryo_satellite.lua` 整段保留（机制已实测通过，只是本轮不发）。另把彩色两张改了显示名：时间裂隙→The World、缩小射线→天堂制造（仅 `03_text.lua` 两行，Id/Effect/NameKey 不动）。
>
> **2026-10-06 更新（五）**：组合改为 `{ "prismatic_ultimate_creature", "prismatic_time_rift", "prismatic_shrink_ray" }`（**究极生物** / The World / 天堂制造），`02_event.lua` 48771 → **49511 B（余 16025 B）**。龙息凌波让位（2026-10-05 已实测），换进本轮改动的究极生物。该符文现在属「随机圈目标单位」型，因此测试事件里那段 `buy_two_get_one` / `ascension` 专属分支**已加进 `ultimate_creature`**（上面第 1 节的备份本体已同步为最新写法，贴回时不要漏）。`prismatic_ultimate_creature` 无 `NeedsUnitType`，目标完全由 `PickUltimateCreatureTarget` 从独立名单 `UltimateCreatureTargetTypes` 随机（禁海模式会先滤掉舰船条目）。
>
> **2026-10-07 实测结论**：这三张卡**实测功能正常**，用户确认；同时要求究极生物的目标**取消阵营限制**（它是一次性转化，不像登神需要长期回收累计），名单由按阵营分组改为一张扁平表，`PickUltimateCreatureTarget` 去掉 `playerIndex` 参数。
>
> **2026-10-07 更新（六）**：组合改为 `{ "prismatic_ultimate_creature", "prismatic_time_rift", "prismatic_tower_defense_expert" }`（究极生物 / The World / **塔防专家**），`02_event.lua` 49511 → **49521 B（余 16015 B）**。天堂制造让位，换进塔防专家是为了实测天门神弓的「秒建成」改造（见设计文档 §7 同日条目）：专家状态下天门神弓半价 10000 且无视数量限制，可以连续买多座，正好逐座验证神州建筑的建成收尾（`POINT_DEFENSE_DRONE_ATTACHED` + 3 帧后清核心阴影）是否每次都生效、有无残留阴影。究极生物与 The World 两张留下继续回归。

> **2026-10-07 更新（七）**：究极生物同日再改两处（见设计文档 §7「究极生物纳入超级要塞本体」与其后的「撤回超级要塞特例」条目）：①名单由 45 条变 **46 条**（补入旧联盟箱子单位 `Overlordtank`，它与新联盟 `SovietAntiVehicleVehicleTech4` 显示名同为「联盟重型坦克」但各有槽位）；②**超级要塞一律不圈**（用户裁决：太贵且牵连问题多，特例通道整段删除，登神/买二送一本来就圈不到）；③施加入口按脚本名剔除地编 T3 塔守护者 `overlord7` / `overlord8`（旧联盟坦克模板被地编摆成守卫单位，圈中就把整层收益花在地图单位上）。**测试提示**：目标仍由 `PickUltimateCreatureTarget` 从名单里随机，想专门验证旧联盟那一档，可临时把 `UltimateCreatureTargetTypes` 里除 `"Overlordtank"` 外的条目整段注释掉（测完还原）；要验证要塞确实不出现，就反复开局看卡面单位名里有没有「超级要塞」。**2026-10-07 用户实测以上四项全部正常**，同日又按表现剔掉四型空军并改了数值档（名单 46 → **42**，攻速 3%→5%、射程 10%→7%），见下一条「更新（八）」。

> **2026-10-07 更新（八）**：实测通过后的数值回调（设计文档 §7「究极生物实测回调」条目）：①从 `UltimateCreatureTargetTypes` 删掉 `AlliedBomberAircraft` 世纪轰炸机、`AlliedAntiStructureBomberAircraft` 世纪轰炸机（对建筑）、`SovietAntiGroundAttacker` 伊尔攻击机、`CelestialBomberAircraft` 金乌轰炸机，名单 46 → **42 条**（按条目删，不是「空军整类排除」：基洛夫飞艇、两型截击机、先锋炮艇机、纤夫运输直升机、摇光巡天炮都还留在池里）；②`UltimateCreatureTierPercent` `{5, 5, 3, 10}` → **`{5, 5, 5, 7}`**，卡面描述里写死的「3%攻速/10%射程」中英文一起改成「5%攻速/7%射程」。

> **2026-10-07 更新（八）**：上面的手法实测有效，用户据此再改两处（设计文档 §7「究极生物实测回调」条目）：①名单 46 → **42 条**，剔掉 `AlliedBomberAircraft` 世纪轰炸机、`AlliedAntiStructureBomberAircraft` 世纪轰炸机（对建筑）、`SovietAntiGroundAttacker` 伊尔攻击机、`CelestialBomberAircraft` 金乌轰炸机（按条目删，没有做「空军整类排除」——基洛夫飞艇、两型截击机、炮艇机、纤夫、摇光都还留着）；②`UltimateCreatureTierPercent` `{5, 5, 3, 10}` → **`{5, 5, 5, 7}`**（T3 攻速 3%→5%、T4 射程 10%→7%），卡面描述的中英文百分比是写死的，已同步改。想验证某一档只剩特定单位，仍按「临时注释掉其余条目」的做法（测完还原）。
>
> **还原时注意保留 `tools/sync_scriptsdata.py` 的 needle**：`02_event.lua` 的定位关键字是 `function HextechRune:ShowFormalEvent` + `function HextechRune:OnRoundBegin`，删测试代码不影响（两个函数都在）；`10_recombobulator` 的定位关键字现为 `RecombobulatorRareChance` + `RollRecombobulatorTargetIndex`（历史值 `RecombobulatorHighTierChance` → `RecombobulatorCarrierChance` 都已不存在）；`07_war_efficiency.lua` 的定位关键字因 2026-09-29 玩家独立化删掉了旧符号 `GetSideWarEfficiencyCopies`，已改为 `WarEfficiencyBonusPerDeath` + `ExpireWarEfficiencyBuffs`（needle 必须同时存在于 JSON 的旧内容与 lua 新内容里，否则 sync 报 found 0）。`16_cryo_satellite.lua` 的定位关键字自 2026-10-06（二）起改为 `PlayerTech_Allied_CryoSatellite_Rank3` + `SpecialPowerCryoSatelliteLvl3`（旧值 `CryoSatellitePlayerTech` / `GrantCryoSatelliteProtocol` 随合并已不存在）。needle 未提交，`git restore .` 会一并还原掉。

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
        "prismatic_ultimate_creature",
        "prismatic_time_rift",
        "prismatic_tower_defense_expert",
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

**复测用的固定三选一**：改 `testRuneIds` 即可。买二送一用 `"gold_buy_two_get_one"`、登神用 `"gold_ascension"`、究极生物用 `"prismatic_ultimate_creature"`（三张都是「随机圈一个目标单位」型，目标由 `CreateRuneCandidateForPlayer` 随机固定，悬浮详情会显示具体单位；究极生物的目标取自本阵营独立名单 `UltimateCreatureTargetTypes`，禁海模式会先滤掉舰船条目）；固若金汤用 `"gold_fortified"`；时间裂隙用 `"prismatic_time_rift"`、神圣干预用 `"prismatic_divine_intervention"`（均无 `NeedsUnitType`，走 `CopyRuneForCandidate` 普通路径）；吸星大法用 `"gold_drain"`、变形重组器用 `"gold_recombobulator"`、中门对狙用 `"gold_railgun_duel"`（赠送天门神弓，与安全感同族）、塔防专家用 `"prismatic_tower_defense_expert"`、致命节奏用 `"prismatic_lethal_tempo"`、十连用 `"gold_ten_pull"`、挖角用 `"gold_poach"`、投资用 `"silver_investment"`。

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


