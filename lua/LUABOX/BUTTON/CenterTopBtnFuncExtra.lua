-- 讲解见 analysis/地图注释说明文档.md 附录 A.77

-- 第 6 组技能：九头蛇万岁 + 冰天雪地。

-- 敌方场上单位过滤：建筑/防御塔、运兵车、MCV 不进技能目标池。
-- 守护神不在这里按模板排除，由 g_GetEnemyBattlefieldContext 逐个剔除
-- （普通 Overlordtank/JapanFortressShip 不因此豁免）。群体名单见 BasicVar 登记表。
-- 本节点早于 GAME/BasicVar 加载，过滤器必须首次使用时再建。
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

-- 以对面主炮塔为参考对象取敌方场上单位，再剔掉地图预设的守护神。
-- sideAIPlayer 是本方阵营 AI。skipIronCurtain 供改归属类效果使用：
-- 铁幕免疫心控是设定，但这里是代码切阵营，引擎不会自动挡，得自己剔除。
-- skipSkillSummoned 同样只给改归属用：技能召唤单位（空军元帅苏霍伊、龙船）自带
-- 无限血攻弹药类作弊加成，不能被心控；与符文转化口径一致（18_basics_exchange）。
function g_GetEnemyBattlefieldContext(playerIndex, skipIronCurtain, skipSkillSummoned)
    local context = {
        sideAIPlayer = "PlyrCivilian",
        sideIndex = 7,
        enemyTower = T84,
        units = {},
        total = 0,
    }
    if playerIndex >= 4 then
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

-- 冻结敌方场上全部单位：名单与冰柱同源（g_GetEnemyBattlefieldContext），
-- 因此建筑、防御塔、地编预设守护神、技能召唤单位（空军元帅苏霍伊）都不会被冻。
-- 解冻交给引擎自然衰减。
function g_FreezeAllEnemyFieldUnits(playerIndex)
    local context = g_GetEnemyBattlefieldContext(playerIndex, false, true)
    for i = 1, getn(context.units), 1 do
        g_FillUnitCryoToFreeze(context.units[i])
    end
end

function CreateHydraButton(playerIndex)
    local buttonData = {
        PlayerName = "Player_" .. playerIndex,
        PlayerIndex = playerIndex,
        ButtonIndex = 1,
        IconId = 'Button_AlliedInfiltrationInfantry_on',
        Title = Localization.get("button.hydra.title"),
        Description = Localization.get("button.hydra.description"),
        IsEnabled = true,
        MaxUseCount = 1,
        CooldownSeconds = 70,
        SharedCooldownId = "hydra",
        SharedCooldownSeconds = 10,
        OnClick = function(self)
            return RequestHydra(self.PlayerIndex)
        end,
    }
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

function RequestHydra(playerIndex)
    local sideName = Localization.get("side.devil")
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
    end
    local context = g_GetEnemyBattlefieldContext(playerIndex, true, true)
    -- 存活单位的一半，向上取整（5 个心控 3 个）。
    local picked = g_PickRandomIndices(context.total, floor((context.total + 1) / 2))
    local attackTeam = context.sideAIPlayer .. "/ATTACK"
    local controlled = 0
    for k = 1, getn(picked), 1 do
        local unit = context.units[picked[k]]
        if unit ~= nil and ObjectIsAlive(unit) then
            -- 只转归属不进进攻队列的话，单位会原地待命，看起来像没生效。
            ExecuteAction("NAMED_TRANSFER_OWNERSHIP_PLAYER", unit, context.sideAIPlayer)
            ExecuteAction("UNIT_SET_TEAM", unit, attackTeam)
            -- 登神/究极生物的微操队列按 g_NoStructureBuffUnitIds 里的阵营每帧把单位换回
            -- 待命队，转换后必须把它从这张表里注销，否则会被拉回原阵营。
            local objectId = ObjectGetId(unit)
            if g_NoStructureBuffUnitIds ~= nil then
                g_NoStructureBuffUnitIds[objectId] = nil
            end
            controlled = controlled + 1
        end
    end

    exMessageAppendToMessageArea(Localization.get("center_top.used.hydra", sideName))
    exMessageAppendToMessageArea(Localization.get("center_top.hydra.controlled_count", controlled))

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestHydra)
    else
        tinsert(g_angelButtonClickHistory, RequestHydra)
    end
    return true
end

-- 冰天雪地：把敌方场上全部单位的冷冻条灌满（不含建筑/防御塔/地编守护神）。
-- 附带的冷冻卫星冰柱已整套注释（实测超模），恢复时取消下面的注释即可。
-- g_SnowstormPowerName = "SpecialPowerCryoSatelliteLvl3"
-- g_SnowstormGrantKey = "grant_cryo_satellite"
-- 实测：只有 Command_CryoSatelliteLvl3 会发动卫星；
-- Command_SpecialPowerCryoSatelliteLvl3 是「授予协议」那一档按钮，按下去只给玩家加协议。
-- g_SnowstormCommandName = "Command_CryoSatelliteLvl3"
-- 冰柱数量：4。全场冷冻条灌满之后冰柱只负责视觉与点名冻结。
-- g_SnowstormTargetCount = 4
-- 技能实例是延迟创建的（符文侧同一结论：同帧的 Available 可能打空），所以延迟 2 帧再按按钮。
-- g_SnowstormCastDelayFrames = 2
-- 主效果的延迟结算，沿用冰柱时期的时序（冰柱先落地、2 帧后再灌冷冻值）。
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
    if playerIndex >= 4 then
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

    -- 附带的冷冻卫星冰柱（已注释，实测超模）：
    -- 拿不到 AI 方技能书就整段跳过，主效果照常生效（技能一样消耗次数、进冷却）。
    -- local spellbook = g_GetSpellbookByOwner(context.sideAIPlayer)
    -- if spellbook ~= nil then
    --     local casterRef = "SnowstormCaster_" .. context.sideAIPlayer
    --     ExecuteAction("SET_UNIT_REFERENCE", casterRef, spellbook)
    --     HextechRune:GrantProtocolToPlayer(context.sideAIPlayer, g_SnowstormGrantKey)
    --
    --     local freezeCount = g_SnowstormTargetCount
    --     if freezeCount > context.total then
    --         freezeCount = context.total
    --     end
    --     local picked = g_PickRandomIndices(context.total, freezeCount)
    --     local targets = {}
    --     for k = 1, getn(picked), 1 do
    --         local unit = context.units[picked[k]]
    --         if unit ~= nil and ObjectIsAlive(unit) then
    --             local unitId = ObjectGetId(unit)
    --             local entry = {
    --                 Id = unitId,
    --                 Ref = "SnowstormTarget_" .. tostring(unitId),
    --             }
    --             ExecuteAction("SET_UNIT_REFERENCE", entry.Ref, unit)
    --             tinsert(targets, entry)
    --         end
    --     end
    --     if getn(targets) > 0 then
    --         SchedulerModule.delay_call(g_CastSnowstorm, g_SnowstormCastDelayFrames,
    --             { casterRef, targets })
    --     end
    -- end

    exMessageAppendToMessageArea(Localization.get("center_top.used.snowstorm", sideName))

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestSnowstorm)
    else
        tinsert(g_angelButtonClickHistory, RequestSnowstorm)
    end
    return true
end
