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

    exMessageAppendToMessageArea(Localization.get("center_top.used.hydra", sideName))
    exMessageAppendToMessageArea(Localization.get("center_top.hydra.controlled_count", controlled))

    if g_IsDevilSeat(playerIndex) then
        tinsert(g_evilButtonClickHistory, RequestHydra)
    else
        tinsert(g_angelButtonClickHistory, RequestHydra)
    end
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


    exMessageAppendToMessageArea(Localization.get("center_top.used.snowstorm", sideName))

    if g_IsDevilSeat(playerIndex) then
        tinsert(g_evilButtonClickHistory, RequestSnowstorm)
    else
        tinsert(g_angelButtonClickHistory, RequestSnowstorm)
    end
    return true
end
