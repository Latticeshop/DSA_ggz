-- 讲解见 analysis/地图注释说明文档.md 附录 A.40

-- 第 6 组技能：九头蛇万岁 + 冰天雪地。

g_EnemyFieldUnitFilter = nil

function g_GetEnemyFieldUnitFilter()
    if g_EnemyFieldUnitFilter == nil then
        g_EnemyFieldUnitFilter = CreateObjectFilter({
            Rule="ANY",
            Relationship="SAME_PLAYER",
            Include="SELECTABLE",
            Exclude="STRUCTURE",
            ExcludeThing=g_CollectTargetNames({"DefenseTower", "Transport", "MCV"}),
        })
    end
    return g_EnemyFieldUnitFilter
end

-- 从 1..count 里不重复地随机抽 pickCount 个下标。
function g_PickRandomIndices(count, pickCount)
    local pool = {}
    for i = 1, count, 1 do
        pool[i] = i
    end
    local picked = {}
    local size = count
    for k = 1, pickCount, 1 do
        if size < 1 then
            break
        end
        local index = floor(GetRandomNumber() * size) + 1
        tinsert(picked, pool[index])
        pool[index] = pool[size]
        pool[size] = nil
        size = size - 1
    end
    return picked
end

function g_GetEnemyBattlefieldContext(playerIndex, skipIronCurtain, skipSkillSummoned)
    local context = {
        sideAIPlayer = "PlyrCivilian",
        sideIndex = 7,
        enemyTower = T84,
        units = {},
        total = 0,
    }
    if g_IsAngelSeat(playerIndex) then
        context.sideAIPlayer = "PlyrCreeps"
        context.sideIndex = 8
        context.enemyTower = T74
    end
    if context.enemyTower == nil then
        return context
    end
    local candidates, count = ObjectFindObjects(context.enemyTower, nil, g_GetEnemyFieldUnitFilter())
    for i = 1, count, 1 do
        local unit = candidates[i]
        if ObjectIsAlive(unit) and not g_IsPresetGuardianUnit(unit)
            and not (skipIronCurtain and g_IsIronCurtainActive(unit))
            and not (skipSkillSummoned and IsSkillSummonedUnitId(ObjectGetId(unit))) then
            context.total = context.total + 1
            context.units[context.total] = unit
        end
    end
    return context
end

-- 把一只单位的冷冻条灌满：按「当前最大血量 × 2」灌，符文血量加成（HEALTH_MULT）也算在内。
-- exObjectGetMaxHealth 比 ObjectGetInitialHealth 贵约 5 倍，但一次施放只按单位数调一遍。
function g_FillUnitCryoToFreeze(unit)
    if unit == nil or not ObjectIsAlive(unit) then
        return false
    end
    local objectId = ObjectGetId(unit)
    if objectId == nil then
        return false
    end
    local amount = g_SnowstormCryoFillFallback
    local maxHealth = exObjectGetMaxHealth(objectId)
    if maxHealth ~= nil and maxHealth > 0 then
        -- 桥接给的是浮点，exObjectDealSecondaryDamage 收整数，取整避免精度告警。
        amount = floor(maxHealth * 2)
    end
    exObjectDealSecondaryDamage(objectId, amount)
    return true
end

function g_FreezeAllEnemyFieldUnits(playerIndex)
    local context = g_GetEnemyBattlefieldContext(playerIndex, false, true)
    for i = 1, getn(context.units), 1 do
        g_FillUnitCryoToFreeze(context.units[i])
    end
end

-- ===== 九头蛇万岁：心控比例随回合衰减 =====
-- 技能是第 3 回合才发放的，所以基数取 60%，即**第一次能用到时正好 60%**，
-- 想改衰减速度只动 PercentPerRound；想改首回合数值只动 BasePercent（第 3 回合起算）。
g_HydraControlBasePercent = 66
g_HydraControlPercentPerRound = 2

-- 本回合的心控比例（整数百分比），下限 0：归零之后技能照样能放，只是心控 0 个单位。
function g_GetHydraControlPercent()
    local round = tonumber(exCounterGetByName("lvc")) or 0
    local percent = g_HydraControlBasePercent - round * g_HydraControlPercentPerRound
    if percent < 0 then
        return 0
    end
    return percent
end

-- 心控数量 = 场上敌方单位数 × 比例，**向下取整**：
function g_GetHydraControlCount(total)
    return floor(total * g_GetHydraControlPercent() / 100)
end

-- 所以这里登记句柄，再挂一个「每回合开始」的常驻回调统一重刷文案。
-- 刷新前按 ButtonManager 自己的口径确认这只按钮还在面板上（被换掉/重选技能组后不再复活它）。
g_HydraButtons = {}
function g_RefreshHydraButtonTexts()
    local percent = g_GetHydraControlPercent()
    for playerIndex = 1, 8, 1 do
        local button = g_HydraButtons[playerIndex]
        if button ~= nil
            and ButtonManager:GetButton(button.PlayerName, button.ButtonIndex) == button then
            button.Description = Localization.get("button.hydra.description", percent)
            button:FormatText()
            ButtonManager:SetButton(button)
        end
    end
end

function g_RegisterHydraButton(playerIndex, buttonData)
    if g_HydraButtonsRegistered == nil then
        g_HydraButtonsRegistered = true
        if RoundLuaManager ~= nil and RoundLuaManager.CallOnEveryRoundBegin ~= nil then
            RoundLuaManager.CallOnEveryRoundBegin(function()
                g_RefreshHydraButtonTexts()
            end, {})
        end
    end
    g_HydraButtons[playerIndex] = buttonData
end

function CreateHydraButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'Button_AlliedInfiltrationInfantry_on',
        Title = Localization.get("button.hydra.title"),
        Description = Localization.get("button.hydra.description",
            g_GetHydraControlPercent()),
        IsEnabled = true,
        MaxUseCount = 1,
        CooldownSeconds = 70,
        SharedCooldownId = "hydra",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestHydra(self.PlayerIndex)
        end,
    }
    g_RegisterHydraButton(playerIndex, buttonData)
    return CreateButton(buttonData)
end

function CreateSnowstormButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 2,
        IconId = 'Button_PlayerPower_CryoSatellite3',
        Title = Localization.get("button.snowstorm.title"),
        Description = Localization.get("button.snowstorm.description"),
        IsEnabled = true,
        MaxUseCount = 2,
        CooldownSeconds = 70,
        SharedCooldownId = "snowstorm",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestSnowstorm(self.PlayerIndex)
        end,
    }
    return CreateButton(buttonData)
end

-- 能不能被九头蛇策反：排除对象与转化型符文一致 —— 登神 / 究极生物圈中的单位不参与。
-- 判定直接复用 18_basics_exchange.lua 的 IsConversionRuneBuffTargetUnit（它同时查
-- 究极生物的 UltimateCreatureRegisteredUnits 与登神的 g_NoStructureBuffUnitIds），
-- 免得两边各维护一份名单、以后加符文又漏一个。符文节点万一没加载则放行（保持旧行为）。
function g_IsHydraControllableUnit(unit)
    if unit == nil or not ObjectIsAlive(unit) then
        return false
    end
    if HextechRune ~= nil and HextechRune.IsConversionRuneBuffTargetUnit ~= nil then
        return not HextechRune:IsConversionRuneBuffTargetUnit(unit)
    end
    return true
end

function RequestHydra(playerIndex)
    local sideName = Localization.get("side.devil")
    if g_IsAngelSeat(playerIndex) then
        sideName = Localization.get("side.angel")
    end
    local context = g_GetEnemyBattlefieldContext(playerIndex, true, true)
    -- 登神 / 究极生物圈中的那台不参与策反：那两张符文把加成、体积和信息框都叠在唯一
    -- 一只身上，被换过来等于让对面白练（转化型符文早就是这个口径，见
    -- 18_basics_exchange.lua 的 IsConversionRuneBuffTargetUnit）。这里复用同一份判定，
    -- 不再各自维护名单；候选表按筛完的结果重新计数，心控比例才对得上「可策反的单位数」。
    local candidates = {}
    local candidateCount = 0
    for i = 1, context.total, 1 do
        local unit = context.units[i]
        if g_IsHydraControllableUnit(unit) then
            candidateCount = candidateCount + 1
            candidates[candidateCount] = unit
        end
    end
    -- 心控数量 = 可策反的存活敌方单位数 × 本回合比例（60% 起每回合 -2%，30 回合归 0），向下取整。
    local picked = g_PickRandomIndices(candidateCount,
        g_GetHydraControlCount(candidateCount))
    local attackTeam = context.sideAIPlayer .. "/ATTACK"
    local controlled = 0
    for k = 1, getn(picked), 1 do
        local unit = candidates[picked[k]]
        if unit ~= nil and ObjectIsAlive(unit) then
            -- 只转归属不进进攻队列的话，单位会原地待命，看起来像没生效。
            ExecuteAction("NAMED_TRANSFER_OWNERSHIP_PLAYER", unit, context.sideAIPlayer)
            ExecuteAction("UNIT_SET_TEAM", unit, attackTeam)
            -- 兜底：万一某只登神/究极生物单位没被上面的判定拦住（例如符文节点尚未加载），
            -- 也要把它从微操登记表里注销，否则每帧会被换回原阵营的待命队。
            local objectId = ObjectGetId(unit)
            if g_NoStructureBuffUnitIds ~= nil then
                g_NoStructureBuffUnitIds[objectId] = nil
            end
            controlled = controlled + 1
        end
    end

    exMessageAppendToMessageArea(Localization.get("center_top.used.hydra", sideName, playerIndex))
    exMessageAppendToMessageArea(Localization.get("center_top.hydra.controlled_count", controlled))

    g_PushSkillClickHistory(playerIndex, RequestHydra)
    return true
end

g_SnowstormFieldFreezeDelayFrames = 4
-- 取不到最大血量时的兜底灌值（远大于任何单位最大血量，多灌的部分被 2× 上限钳制）。
g_SnowstormCryoFillFallback = 60000

-- g_SnowstormSpellbookFilter = CreateObjectFilter({
--     Rule = "ANY",
--     IncludeThing = { "playerspellbook" },
-- })
--
-- function g_GetSpellbookByOwner(playerName)
--     local books, count = ObjectFindObjects(nil, nil, g_SnowstormSpellbookFilter)
--     for i = 1, count, 1 do
--         if ObjectIsAlive(books[i]) and ObjectPlayerScriptName(books[i]) == playerName then
--             return books[i]
--         end
--     end
--     return nil
-- end
--
-- function g_CastSnowstorm(casterRef, targets)
--     for i = 1, getn(targets), 1 do
--         local entry = targets[i]
--         if ObjectIsAlive(entry.Id) then
--             -- 每发前清一次冷却，否则一发之后全被卫星自身的冷却挡住。
--             ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", casterRef,
--                 g_SnowstormPowerName, 0)
--             ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY_ON_NAMED", casterRef,
--                 g_SnowstormCommandName, entry.Ref)
--         end
--     end
-- end

function RequestSnowstorm(playerIndex)
    local sideName = Localization.get("side.devil")
    if g_IsAngelSeat(playerIndex) then
        sideName = Localization.get("side.angel")
    end
    local context = g_GetEnemyBattlefieldContext(playerIndex, false, true)
    if context.total < 1 then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("center_top.error.no_unit_to_freeze"), 8)
        return false
    end

    -- 主效果：敌方场上全部单位（不含建筑/防御塔/地编守护神）冷冻条灌满。
    SchedulerModule.delay_call(g_FreezeAllEnemyFieldUnits,
        g_SnowstormFieldFreezeDelayFrames, { playerIndex })


    exMessageAppendToMessageArea(Localization.get("center_top.used.snowstorm", sideName, playerIndex))

    g_PushSkillClickHistory(playerIndex, RequestSnowstorm)
    return true
end

-- ===== 复制技能组：悬浮窗末尾动态展示「(上个技能是：XXX)」 =====
g_CopySkillButtons = g_CopySkillButtons or {}
g_SkillClickDisplayNameKeys = nil

-- 技能函数 → 标题文案键。整张表在第一次用到时才建：本文件可能先于 CenterTopBtnFunc.lua 加载，
-- 加载期把还没定义的 Request 函数当表键会取到 nil，Lua 4 里 t[nil] = ... 直接报错，故逐个判空。
function g_BuildSkillClickDisplayNameKeys()
    local keys = {}
    if RequestDestruction ~= nil then keys[RequestDestruction] = "button.destruction.title" end
    if RequestDamoclesSword ~= nil then keys[RequestDamoclesSword] = "button.damocles.title" end
    if RequestIronCurtain ~= nil then keys[RequestIronCurtain] = "button.iron_curtain.title" end
    if RequestTimeStop ~= nil then keys[RequestTimeStop] = "button.time_stop.title" end
    if RequestDragonShip ~= nil then keys[RequestDragonShip] = "button.dragonship.title" end
    if RequestAirMarshal ~= nil then keys[RequestAirMarshal] = "button.air_marshal.title" end
    if RequestNanoMaintainHive ~= nil then keys[RequestNanoMaintainHive] = "center_top.nano_repair.title" end
    if RequestSpawnArmyImmediately ~= nil then keys[RequestSpawnArmyImmediately] = "center_top.reinforce_army.title" end
    if RequestCashBonus ~= nil then keys[RequestCashBonus] = "center_top.kill_reward.title" end
    if RequestHydra ~= nil then keys[RequestHydra] = "button.hydra.title" end
    if RequestSnowstorm ~= nil then keys[RequestSnowstorm] = "button.snowstorm.title" end
    g_SkillClickDisplayNameKeys = keys
    return keys
end

-- 技能函数 → 本地化名字。没登记过的技能返回 nil，悬浮窗就不加后缀。
function g_GetSkillDisplayName(skillFunc)
    if skillFunc == nil then
        return nil
    end
    local keys = g_SkillClickDisplayNameKeys
    if keys == nil then
        keys = g_BuildSkillClickDisplayNameKeys()
    end
    local titleKey = keys[skillFunc]
    if titleKey == nil then
        return nil
    end
    return Localization.get(titleKey)
end

-- 复制技能实际读的那张历史表：copyKind = "self" 取本边、"enemy" 取对面。
function g_GetSkillClickHistory(playerIndex, copyKind)
    local isAngelSide = g_IsAngelSeat(playerIndex)
    if copyKind == "enemy" then
        isAngelSide = not isAngelSide
    end
    if isAngelSide then
        return g_angelButtonClickHistory
    end
    return g_evilButtonClickHistory
end

-- 从历史末尾往前回溯到最近一次「非复制技能」的释放
function g_FindCopyTargetSkill(history)
    if history == nil then
        return nil
    end
    for i = getn(history), 1, -1 do
        local skillFunc = history[i]
        if skillFunc ~= nil and skillFunc ~= RequestRepeatSelfSpecialPower
            and skillFunc ~= RequestRepeatEnemySpecialPower then
            return skillFunc
        end
    end
    return nil
end

-- 复制按钮的完整描述 = 本地化正文 + 换行 + 「(上个技能是：XXX)」；没有可复制技能就只给正文。
function g_GetCopySkillDescription(playerIndex, copyKind)
    local descriptionKey = "center_top.copy_our_skill.description"
    if copyKind == "enemy" then
        descriptionKey = "center_top.copy_enemy_skill.description"
    end
    local base = Localization.get(descriptionKey)
    local targetName = g_GetSkillDisplayName(
        g_FindCopyTargetSkill(g_GetSkillClickHistory(playerIndex, copyKind)))
    if targetName == nil then
        return base
    end
    return format("%s\n%s", base, Localization.get("center_top.copy_skill.last_skill", targetName))
end

-- 复制按钮登记表：同一玩家同一按钮位只留最新那只（重选技能组会重建按钮）。
function g_RegisterCopySkillButton(buttonData, copyKind)
    buttonData.CopyKind = copyKind
    local list = g_CopySkillButtons
    for i = 1, getn(list), 1 do
        local old = list[i]
        if old.PlayerName == buttonData.PlayerName and old.ButtonIndex == buttonData.ButtonIndex then
            list[i] = buttonData
            return
        end
    end
    tinsert(list, buttonData)
end

-- 历史一变就按登记表重刷文案。只刷还挂在面板上的那只：重选技能组后旧按钮会被别的按钮顶掉，
function g_RefreshCopySkillButtonTexts()
    local list = g_CopySkillButtons
    for i = 1, getn(list), 1 do
        local button = list[i]
        if button.CopyKind ~= nil
            and ButtonManager:GetButton(button.PlayerName, button.ButtonIndex) == button then
            local description = g_GetCopySkillDescription(button.PlayerIndex, button.CopyKind)
            if description ~= button.Description then
                button.Description = description
                button:FormatText()
                ButtonManager:SetButton(button)
            end
        end
    end
end

-- 所有技能释放的末尾都走这里：记一条历史 + 刷新同侧/对侧复制按钮的悬浮文案。
function g_PushSkillClickHistory(playerIndex, skillFunc)
    if g_IsDevilSeat(playerIndex) then
        tinsert(g_evilButtonClickHistory, skillFunc)
    else
        tinsert(g_angelButtonClickHistory, skillFunc)
    end
    g_RefreshCopySkillButtonTexts()
end

Localization.on_language_changed(function()
    g_RefreshCopySkillButtonTexts()
    g_RefreshRoundCooldownButtonTexts()
end, {})

-- ===== 阵营技能按钮：描述里动态显示「剩余冷却时间：X回合」 =====
g_RoundCooldownButtons = g_RoundCooldownButtons or {}
g_RoundCooldownWatcherRegistered = false

-- 描述第二行 = 「剩余冷却时间：X回合」，模板里的 %d 由剩余回合数填（0 = 已就绪）。
function g_ApplyRoundCooldownButtonDescription(button)
    if button.CooldownDescriptionKey == nil then
        return
    end
    button.Description = Localization.get(button.CooldownDescriptionKey, button.CooldownRoundsLeft or 0)
end

-- 第三按钮（阵营技能）解锁后的统一入口：有动态描述的自己重算，其余沿用 UnlockedDescription。
function g_ApplyUnlockedButtonDescription(button)
    if button.RoundCooldownRounds ~= nil then
        g_ApplyRoundCooldownButtonDescription(button)
        return
    end
    button.Description = button.UnlockedDescription
end

function g_RefreshRoundCooldownButtonTexts()
    local list = g_RoundCooldownButtons
    for i = 1, getn(list), 1 do
        local button = list[i]
        -- 只刷还挂在面板上的那只（按钮被重建后旧表留在登记表里，不能把它复活回来）。
        if not button.IsLocked
            and ButtonManager:GetButton(button.PlayerName, button.ButtonIndex) == button then
            g_ApplyRoundCooldownButtonDescription(button)
            button:FormatText()
            ButtonManager:SetButton(button)
        end
    end
end

-- 每次回合开始：剩余回合数 -1，然后重刷文案（未解锁的按钮保持「请建造…」那句）。
function g_TickRoundCooldownButtons()
    local list = g_RoundCooldownButtons
    for i = 1, getn(list), 1 do
        local button = list[i]
        local roundsLeft = button.CooldownRoundsLeft or 0
        if roundsLeft > 0 then
            button.CooldownRoundsLeft = roundsLeft - 1
        end
    end
    g_RefreshRoundCooldownButtonTexts()
end

function g_RegisterRoundCooldownButton(button, totalRounds, descriptionKey)
    button.RoundCooldownRounds = totalRounds
    button.CooldownRoundsLeft = 0
    button.CooldownDescriptionKey = descriptionKey
    if not g_RoundCooldownWatcherRegistered and RoundLuaManager ~= nil
        and RoundLuaManager.CallOnEveryRoundBegin ~= nil then
        g_RoundCooldownWatcherRegistered = true
        RoundLuaManager.CallOnEveryRoundBegin(function()
            g_TickRoundCooldownButtons()
        end, {})
    end
    local list = g_RoundCooldownButtons
    for i = 1, getn(list), 1 do
        local old = list[i]
        if old.PlayerName == button.PlayerName and old.ButtonIndex == button.ButtonIndex then
            list[i] = button
            return
        end
    end
    tinsert(list, button)
end

-- 放成功才把剩余回合数置满，描述由 ButtonManager 紧接着的 FormatText 带进悬浮窗。
function g_ChronoSphereOnClick(button)
    if not RequestChronosphere(button.PlayerIndex) then
        return false
    end
    button.CooldownRoundsLeft = button.RoundCooldownRounds or 0
    g_ApplyRoundCooldownButtonDescription(button)
    return true
end

-- === 交易市场·自动转账（面板开关在 BtnChoiceDialogEventFunc_ShowMarketDialog）===
-- 口径：面板里开启后，玩家**手动转账成功**一次就把那一次的对象记成自动目标；此后每 1 秒
-- （15 帧 = 1 秒）重复一次完全相同的转账（扣款 + 到账 + 个人播报，和手动转账同一套流程）。
-- 中途手动转给别人，目标立刻换成那一个；余额不足就这一拍静默跳过。
--
-- **每个座席完全独立**：状态按座位号分开存（g_AutoTransferState[playerIndex]），表里记着这一位
-- 的完整玩家名（state.PlayerName）；转账的那几个动作全部只带「出钱的自己」和「收钱的目标」两个
-- 显式玩家名，不读也不写任何「当前玩家」上下文，所以 A 开着自动转账绝不会动到 B 的钱。
--
-- **资金不足安全锁**：连续 g_AutoTransferGiveUpTicks 拍（20 拍 = 20 秒）都没能正常转账，就自动
-- 关掉并播报，选项文案同时变回「开启自动转账」。
g_AutoTransferState = g_AutoTransferState or {}
g_AutoTransferAmount = 1000
g_AutoTransferIntervalFrames = 15
g_AutoTransferGiveUpTicks = 20
g_AutoTransferRegistered = g_AutoTransferRegistered or 0

-- 取这一位玩家的完整名字：优先用开关时记下的，兜底才拼 "Player_N"。
function g_AutoTransferPlayerName(playerIndex)
    local state = g_AutoTransferState[playerIndex]
    if state ~= nil and state.PlayerName ~= nil then
        return state.PlayerName
    end
    return "Player_" .. playerIndex
end

-- 转账本体：手动（面板点选项）与自动（周期扫描）共用。成功 true，余额不足 false。
-- 目标越界或等于自己一律放弃，杜绝串号；成功的自动转账顺便清零安全锁计数。
function g_AutoTransferPay(playerIndex, targetIndex, playerName)
    if playerIndex == nil or targetIndex == nil then
        return false
    end
    if targetIndex == playerIndex or targetIndex < 1 or targetIndex > 8 then
        return false
    end
    playerName = playerName or g_AutoTransferPlayerName(playerIndex)
    if exPlayerGetCurrentMoney(playerName) < g_AutoTransferAmount then
        exAddTextToPublicBoardForPlayer(playerName,
            Localization.get("market.transfer.insufficient"), 5)
        return false
    end
    local amountText = "" .. g_AutoTransferAmount
    ExecuteAction("PLAYER_GIVE_MONEY", "Player_" .. targetIndex, amountText)
    ExecuteAction("PLAYER_GIVE_MONEY", playerName, "-" .. amountText)
    exAddTextToPublicBoardForPlayer(playerName,
        Localization.get("market.transfer.success", targetIndex), 5)
    local state = g_AutoTransferState[playerIndex]
    if state ~= nil then
        state.FailTicks = 0
        if state.Enabled == 1 then
            state.Target = targetIndex
        end
    end
    return true
end

-- 面板文案跟着状态变：把这一位正开着的市场对话框按新状态重建一遍。
-- 只在「刚点过面板」的窗口内重建（g_AutoTransferTouchWindowFrames），因为对话框管理器没有
-- 「已关闭」的通知（_activeDialogs 里留着上一次的实例），无脑重建会把玩家已经关掉的面板又弹出来。
g_AutoTransferTouch = g_AutoTransferTouch or {}
g_AutoTransferTouchWindowFrames = 75

function g_AutoTransferRefreshDialog(playerIndex)
    if g_AutoTransferTouch == nil or g_AutoTransferTouch[playerIndex] == nil then
        return
    end
    if GetFrame() - g_AutoTransferTouch[playerIndex] > g_AutoTransferTouchWindowFrames then
        return
    end
    if ButtonChoiceDialogManager == nil or ButtonChoiceDialogManager._activeDialogs == nil
        or MARKET_DIALOG_ID_OFFSET == nil then
        return
    end
    local dialog = ButtonChoiceDialogManager._activeDialogs[MARKET_DIALOG_ID_OFFSET + playerIndex]
    if dialog == nil or dialog.PlayerName == nil then
        return
    end
    if type(dialog.RefreshData) == "function" then
        dialog:RefreshData()
        ButtonChoiceDialogManager:ShowDialog(dialog)
    end
end

-- 关掉某一位的自动转账（手动关 / 资金不足自动关共用）。reason 决定播报哪一条。
function g_AutoTransferOff(playerIndex, reason)
    local state = g_AutoTransferState[playerIndex]
    if state == nil then
        return
    end
    state.Enabled = 0
    state.Target = nil
    state.FailTicks = 0
    local playerName = g_AutoTransferPlayerName(playerIndex)
    if reason == "insufficient" then
        exAddTextToPublicBoardForPlayer(playerName,
            Localization.get("market.auto_transfer.auto_off", g_AutoTransferGiveUpTicks), 8)
    else
        exAddTextToPublicBoardForPlayer(playerName,
            Localization.get("market.auto_transfer.disabled"), 5)
    end
    -- 手动关不用重建：OnChoice 走完开关后本来就会 RefreshData + ShowDialog（避免同帧弹两次）。
    if reason ~= "manual" then
        g_AutoTransferRefreshDialog(playerIndex)
    end
end

-- 每 1 秒扫一遍：只处理「自己开着 + 自己有目标」的那一位；这一拍没转出去就记一次失败
-- （钱不够是主因，目标非法也会被算进来；钱够时由 Pay 自己清零）。
function g_AutoTransferSweep()
    for playerIndex = 1, 8, 1 do
        local state = g_AutoTransferState[playerIndex]
        if state ~= nil and state.Enabled == 1 and state.Target ~= nil then
            local playerName = g_AutoTransferPlayerName(playerIndex)
            local ok = false
            -- 钱不够就不调 Pay（Pay 会播「余额不足」，自动那一侧要保持静默）。
            if exPlayerGetCurrentMoney(playerName) >= g_AutoTransferAmount then
                ok = g_AutoTransferPay(playerIndex, state.Target, playerName)
            end
            if not ok then
                state.FailTicks = (state.FailTicks or 0) + 1
                if state.FailTicks >= g_AutoTransferGiveUpTicks then
                    g_AutoTransferOff(playerIndex, "insufficient")
                end
            end
        end
    end
end

-- 周期扫描只注册一次。SchedulerModule 在 baselib，本节点加载期可能还没就绪，
-- 所以不放在加载期，而是等玩家第一次点「开启自动转账」时再注册。
function g_AutoTransferEnsureLoop()
    if g_AutoTransferRegistered == 1 then
        return
    end
    if SchedulerModule == nil or SchedulerModule.call_every_x_frame == nil then
        return
    end
    g_AutoTransferRegistered = 1
    SchedulerModule.call_every_x_frame(g_AutoTransferSweep, g_AutoTransferIntervalFrames, nil)
end

-- 面板开关：开 → 记下这一位的名字、播报「已开启…」并等一次手动转账上膛；
-- 关 → 走 g_AutoTransferOff（清目标 + 播报 + 刷新文案）。
function g_AutoTransferToggle(playerIndex, playerName)
    local state = g_AutoTransferState[playerIndex]
    if state == nil then
        state = { Enabled = 0, Target = nil, FailTicks = 0 }
        g_AutoTransferState[playerIndex] = state
    end
    if playerName ~= nil then
        state.PlayerName = playerName
    end
    if state.Enabled == 1 then
        g_AutoTransferOff(playerIndex, "manual")
        return
    end
    state.Enabled = 1
    state.FailTicks = 0
    exAddTextToPublicBoardForPlayer(g_AutoTransferPlayerName(playerIndex),
        Localization.get("market.auto_transfer.enabled"), 5)
    g_AutoTransferEnsureLoop()
end

-- === 海克斯符文赠送的顶部技能组（从 lua/GAME/HextechRune/04_buff.lua 迁出）===
-- 为什么在这：04_buff 是全树最紧的 payload（去注释后 65,483 B，只剩 53 B），而这一组
-- 「拿符文 → 授予原生技能按钮」的实现和本节点原有的九头蛇万岁 / 冰天雪地属于同一类，
-- 放这里既能给 04 腾出 ~6.9KB，也不用新开节点（新节点还要地编再建一次同名 Script 节点）。
-- 搬迁是透明的：这些函数只被 HextechRune:OnRuneChosen 的运行时分支调用，
-- 函数名是全局方法（HextechRune:XXX），后加载的节点定义完照样能调到。

function HextechRune:SetFiveThunderAvailability(playerIndex, availability)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    -- 首发与 0cd 属于同一套原生技能流程，开放和冷却必须同步控制。
    -- 触发检测会检查两段，但命中后也同步禁用两段，避免 0cd 持续运行。
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.FiveThunderFirstPower, availability)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.FiveThunderRepeatPower, availability)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:SetFiveThunderFirstAvailability(playerIndex, availability)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.FiveThunderFirstPower, availability)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:GrantFiveThunderPowers(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.FiveThunderFirstPower, playerName)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.FiveThunderRepeatPower, playerName)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:SetFiveThunderCountdown(playerIndex, seconds)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        self.FiveThunderFirstPower, seconds)
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        self.FiveThunderRepeatPower, seconds)
    SetWorldBuilderThisPlayer(previous)
end


function HextechRune:GrantFiveThunder(playerIndex)
    if self.FiveThunderState[playerIndex] == nil then
        self.FiveThunderState[playerIndex] = {}
    end
    local state = self.FiveThunderState[playerIndex]
    state.Owned = true
    state.Ready = true
    state.ReadyRound = nil
    state.WaitingForTriggerClear = false

    -- 两段都显式授予并同步开放：首发负责玩家选点，0cd 完成原生连发。
    self:GrantFiveThunderPowers(playerIndex)
    self:SetFiveThunderCountdown(playerIndex, 0)
    self:SetFiveThunderAvailability(playerIndex, "Available")
    self:EnsureFiveThunderMonitor()
end

function HextechRune:CheckFiveThunderTriggered()
    for playerIndex = 1, 8, 1 do
        local state = self.FiveThunderState[playerIndex]
        if state ~= nil and state.Owned then
            local playerName = "Player_" .. playerIndex
            local firstTriggered = EvaluateCondition("PLAYER_TRIGGERED_SPECIAL_POWER",
                playerName, self.FiveThunderFirstPower)
            local repeatTriggered = EvaluateCondition("PLAYER_TRIGGERED_SPECIAL_POWER",
                playerName, self.FiveThunderRepeatPower)
            if state.WaitingForTriggerClear then
                if not firstTriggered and not repeatTriggered then
                    self:SetFiveThunderCountdown(playerIndex, 0)
                    self:SetFiveThunderAvailability(playerIndex, "Available")
                    state.WaitingForTriggerClear = false
                    state.Ready = true
                    state.ReadyRound = nil
                end
            elseif state.Ready and (firstTriggered or repeatTriggered) then
                state.Ready = false
                state.ReadyRound = exCounterGetByName("lvc")
                    + self.FiveThunderCooldownRounds
                -- 首发只负责开启本次原生五连发；检测到输出段后只关闭
                -- 首发入口，保留 0cd 连发段，让引擎完整走完后续四次落雷。
                self:SetFiveThunderFirstAvailability(playerIndex, "Disabled")
            end
        end
    end
end


function HextechRune:EnsureFiveThunderMonitor()
    if self.FiveThunderMonitorSchedulerId ~= nil then
        return
    end
    self.FiveThunderMonitorSchedulerId = SchedulerModule.call_every_x_frame(function()
        HextechRune:CheckFiveThunderTriggered()
    end, 1, nil, {})
end

function HextechRune:OnFiveThunderRoundBegin(round)
    for playerIndex = 1, 8, 1 do
        local state = self.FiveThunderState[playerIndex]
        if state ~= nil and state.Owned and not state.Ready
            and not state.WaitingForTriggerClear and state.ReadyRound ~= nil
            and round >= state.ReadyRound then
            state.WaitingForTriggerClear = true
        end
    end
end

function HextechRune:GrantCashRewardProtocol(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_LOCK_PLAYER_TECH", playerName,
        self.CashRewardPlayerTech, 0)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.CashRewardSpecialPower, playerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.CashRewardSpecialPower, "Available")
    ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", playerName,
        self.CashRewardSpecialPower, 0)
    SetWorldBuilderThisPlayer(previous)
    -- 技能实例由 PLAYER_GRANT_SPECIAL_POWER 延迟创建；同帧的 Available 可能只
    -- 改到全局禁用记录而没有改到新按钮，因此下一帧再对持有者单独解禁一次。
    SchedulerModule.delay_call(function(index)
        local delayedPlayerName = "Player_" .. index
        local delayedPrevious = SetWorldBuilderThisPlayer(1)
        ExecuteAction("PLAYER_LOCK_PLAYER_TECH", delayedPlayerName,
            HextechRune.CashRewardPlayerTech, 0)
        ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", delayedPlayerName,
            HextechRune.CashRewardSpecialPower, "Available")
        ExecuteAction("PLAYER_SET_SPECIAL_POWER_COUNTDOWN", delayedPlayerName,
            HextechRune.CashRewardSpecialPower, 0)
        SetWorldBuilderThisPlayer(delayedPrevious)
    end, 1, {playerIndex})
end

-- 磁暴突袭符文：暂不启用（实测直接赋予该协议会有0cd问题），代码保留待后续开发。
-- 取得符文只做两件事：授予协议、解禁按钮；冷却与释放节奏全部交给原版。
function HextechRune:GrantTeslaAirAssault(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", self.TeslaAirAssaultPower, playerName)
    ExecuteAction("PLAYER_SPECIAL_POWER_AVAILABILITY", playerName,
        self.TeslaAirAssaultPower, "Available")
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:GrantYaoguang(playerIndex)
    -- 赠送的摇光不占生产限造，但要同步多开一个单位池位（见 MONEYINI_3 的池上限口径）。
    if RecordPlayerGrantedYaoguang ~= nil then
        RecordPlayerGrantedYaoguang(playerIndex, 1)
    end
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "CelestialAdvanceAircraftTech4",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 80), 0)
end

function HextechRune:GrantOlympusCarrier(playerIndex)
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "AlliedGaintAirCraftCarrier_B",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, -80), 0)
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "JapanYumiAircraftCarrier",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 80), 0)
end
