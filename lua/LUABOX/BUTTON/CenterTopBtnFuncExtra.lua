-- 第 6 组技能：九头蛇万岁 + 冰天雪地。

-- 实测口径：达摩剑那套（SELECTABLE + 模板名名单 + Exclude STRUCTURE）才挡得住塔。
-- 只按兵种白名单会漏 —— 天庭建筑带 VEHICLE、塔的另一半还不带 STRUCTURE，KindOf 拦不住；
-- 而单留 SELECTABLE 也挡不住（塔本身就是可选中的，实测会捞出 4 座塔）。新增塔种必须往名单里加名字。
g_ExcludeThingNames = {
    -- 防御塔：本体 + 无核心形态，以及其余四种塔和运兵车。
    "CelestialBaseDefenseAdvanced",
    "CelestialBaseDefenseAdvanced_NoCore",
    "CelestialBaseDefenseAir",
    "CelestialEnergyGatlingTower",
    "AlliedHeavyArtilleryDefenseBase",
    "SovietBaseDefenseAdvanced",
    "JapanBaseDefenseAdvanced",
    "JapanLightTransportVehicle",
}

g_EnemyFieldUnitFilter = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="SELECTABLE",
    Exclude="STRUCTURE",
    ExcludeThing=g_ExcludeThingNames,
})

g_HydraGuardExemptNames = {
    "overlord7", "overlord8", "t533", "t534",
    "Sea3ProtectShip7", "Sea3ProtectShip8",
}

function g_IsPresetGuardianUnit(unit)
    if unit == nil then
        return false
    end
    if IsTowerGuardian ~= nil and IsTowerGuardian(unit) then
        return true
    end
    local objectId = ObjectGetId(unit)
    for i = 1, getn(g_HydraGuardExemptNames), 1 do
        local guard = GetObjectByScriptName(g_HydraGuardExemptNames[i])
        if guard ~= nil and ObjectGetId(guard) == objectId then
            return true
        end
    end
    return false
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
-- sideAIPlayer 是本方阵营 AI。
function g_GetEnemyBattlefieldContext(playerIndex)
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
    local candidates, count = ObjectFindObjects(context.enemyTower, nil, g_EnemyFieldUnitFilter)
    for i = 1, count, 1 do
        local unit = candidates[i]
        if ObjectIsAlive(unit) and not g_IsPresetGuardianUnit(unit) then
            context.total = context.total + 1
            context.units[context.total] = unit
        end
    end
    return context
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
    local context = g_GetEnemyBattlefieldContext(playerIndex)
    if context.total < 1 then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("center_top.error.no_unit_to_control"), 8)
        return false
    end

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
            -- 地编 ATTACK__7/8 的强制满星已删除，这里和出兵队同一口径：按本方「升本」补星。
            if LEVELUP ~= nil then
                for levelindex = 1, LEVELUP[context.sideIndex], 1 do
                    ExecuteAction("UNIT_GAIN_LEVEL", unit, 1)
                end
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

-- 冰天雪地：按盟军三级冷冻卫星协议对敌方单位释放。
-- 施法者用场地中间的 AI 阵营（PlyrCivilian/PlyrCreeps），协议授予也给这一侧，
g_SnowstormPowerName = "SpecialPowerCryoSatelliteLvl3"
g_SnowstormGrantKey = "grant_cryo_satellite"
-- 实测：只有 Command_CryoSatelliteLvl3 会发动卫星；
-- Command_SpecialPowerCryoSatelliteLvl3 是「授予协议」那一档按钮，按下去只给玩家加协议。
g_SnowstormCommandName = "Command_CryoSatelliteLvl3"
g_SnowstormTargetCount = 8
-- 技能实例是延迟创建的（符文侧同一结论：同帧的 Available 可能打空），所以延迟 2 帧再按按钮。
g_SnowstormCastDelayFrames = 2

g_SnowstormSpellbookFilter = CreateObjectFilter({
    Rule = "ANY",
    IncludeThing = { "playerspellbook" },
})

function g_GetSpellbookByOwner(playerName)
    local books, count = ObjectFindObjects(nil, nil, g_SnowstormSpellbookFilter)
    for i = 1, count, 1 do
        if ObjectIsAlive(books[i]) and ObjectPlayerScriptName(books[i]) == playerName then
            return books[i]
        end
    end
    return nil
end

function g_CastSnowstorm(casterRef, targets)
    for i = 1, getn(targets), 1 do
        local entry = targets[i]
        if ObjectIsAlive(entry.Id) then
            -- 每发前清一次冷却，否则一发之后全被卫星自身的冷却挡住。
            ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", casterRef,
                g_SnowstormPowerName, 0)
            ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY_ON_NAMED", casterRef,
                g_SnowstormCommandName, entry.Ref)
        end
    end
end

function RequestSnowstorm(playerIndex)
    local sideName = Localization.get("side.devil")
    if playerIndex >= 4 then
        sideName = Localization.get("side.angel")
    end
    local context = g_GetEnemyBattlefieldContext(playerIndex)
    if context.total < 1 then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("center_top.error.no_unit_to_freeze"), 8)
        return false
    end
    local spellbook = g_GetSpellbookByOwner(context.sideAIPlayer)
    if spellbook == nil then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("center_top.error.no_unit_to_freeze"), 8)
        return false
    end
    local casterRef = "SnowstormCaster_" .. context.sideAIPlayer
    ExecuteAction("SET_UNIT_REFERENCE", casterRef, spellbook)
    HextechRune:GrantProtocolToPlayer(context.sideAIPlayer, g_SnowstormGrantKey)

    local freezeCount = g_SnowstormTargetCount
    if freezeCount > context.total then
        freezeCount = context.total
    end
    local picked = g_PickRandomIndices(context.total, freezeCount)
    local targets = {}
    for k = 1, getn(picked), 1 do
        local unit = context.units[picked[k]]
        if unit ~= nil and ObjectIsAlive(unit) then
            local unitId = ObjectGetId(unit)
            local entry = {
                Id = unitId,
                Ref = "SnowstormTarget_" .. tostring(unitId),
            }
            ExecuteAction("SET_UNIT_REFERENCE", entry.Ref, unit)
            tinsert(targets, entry)
        end
    end
    if getn(targets) < 1 then
        return false
    end
    SchedulerModule.delay_call(g_CastSnowstorm, g_SnowstormCastDelayFrames,
        { casterRef, targets })

    exMessageAppendToMessageArea(Localization.get("center_top.used.snowstorm", sideName))

    if playerIndex <= 3 then
        tinsert(g_evilButtonClickHistory, RequestSnowstorm)
    else
        tinsert(g_angelButtonClickHistory, RequestSnowstorm)
    end
    return true
end
