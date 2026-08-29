RescueBlockedProductions_UnitList = {
    'JapanPowerPlantEgg',
    'CelestialDF41',
    'CelestialAdvanceAircraftTech4',
    'CelestialAdvanceAircraftTech4_Enhanced',
    'AlliedAntiStructureShip',
    'AlliedAntiStructureShip_Enhanced',
    'CelestialAntiStructureShip',
    'CelestialAntiStructureShip_Enhanced',
    'SovietAntiStructureShip',
    'SovietAntiStructureShip_Enhanced',
    'JapanAntiStructureShip',
    'JapanAntiStructureShip_Enhanced',
}
RescueBlockedProductions_PlayerCanBuildUnitsTables = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
}
-- 自动检测并拯救任意被卡住的建造序列（比如说帝国卡电厂，或者神州卡东风导弹车）
-- 但是，这需要遍历玩家所有建造序列里的所有内容，假如频繁调用，我怕有性能问题。
-- 但是！！！！实际上完全没必要每一帧都去检测建造序列：
-- 首先，假如某个单位一直都是可以造的，那么它不可能卡住生产建筑，我们自然没必要为了它去检测各个建造序列
-- 假如某个单位一直都不允许建造，玩家从来没有造它的机会，那它照样无法卡住生产建筑，我们也没必要为了它去检测各个建造序列
-- 只有一种情况需要检测：有单位刚刚从可建造的状态变成了不可建造的状态，此时假如玩家正在生产该单位，生产建筑就会卡住。
-- 所以，只需要在上述的特定情况发生时，再去检测，就可以了~
SchedulerModule.call_every_x_frame(function()
    for p = 1, 6, 1 do
        local unitHashsNeedUnblock = nil

        local playerCanBuildUnitsTable = RescueBlockedProductions_PlayerCanBuildUnitsTables[p]
        for i = 1, getn(RescueBlockedProductions_UnitList), 1 do
            local unitType = RescueBlockedProductions_UnitList[i]
            local previousCanBuild = playerCanBuildUnitsTable[unitType]
            local nowCanBuild = RescueBlockedProductions_CheckUnitCanBuild(p, unitType)
            if previousCanBuild and not nowCanBuild then
                if unitHashsNeedUnblock == nil then
                    unitHashsNeedUnblock = {}
                end
                unitHashsNeedUnblock[tostring(FastHash(unitType))] = true
                -- exPrintln(format("Player %d unit %s can no longer be built, will try to rescue blocked productions.", p, unitType))
            end

            playerCanBuildUnitsTable[unitType] = nowCanBuild
        end

        if unitHashsNeedUnblock ~= nil then
            RescueBlockedProductions_DoRescue('Player_' .. p, unitHashsNeedUnblock)
        end
    end
end, 75, nil)

-- 关于检测单位是否禁用的代码。。。有点屎山代码，很多关于单位禁止建造的脚本依然在地编脚本里而不是 lua 脚本里
-- 所以这里只能靠这个函数重新检测一下
-- 希望有一天能把下面这个函数 以及其他代码 重新重构成更加优雅的形式
function RescueBlockedProductions_CheckUnitCanBuild(playerIndex, unitType)
    if unitType == 'JapanPowerPlantEgg' then
        local units, count = ObjectFindObjects(P[playerIndex], nil, FilterAnyPowerPlantOrEgg)
        if units ~= nil then
            return count < g_CachedPlayersPowerPlantLimit[playerIndex]
        end
        -- FLAGENPOWER 这玩意在 lua\LUABOX\moneysys\MONEYINI_3.lua 里面
        return FLAGENPOWER[playerIndex] == 1
    elseif unitType == 'CelestialDF41' then
        if EvaluateCondition('PLAYER_HAS_OBJECT_COMPARISON', 'Player_'..playerIndex, '==', 0, 'CelestialDF41') then
            return true
        else
            return false
        end
    elseif unitType == 'CelestialAdvanceAircraftTech4'
        or unitType == 'CelestialAdvanceAircraftTech4_Enhanced' then
        return GetPlayerYaoguangCount(playerIndex) < YAOGUANG_LIMIT
    else -- 大船
        if exCounterGetByName("bigshiplimit"..playerIndex) < 2 then
            return true
        else
            return false
        end
    end
    return true
end

-- 比较耗时的代码，会检测玩家的所有建造序列里面的所有内容。
-- 不过，它并不会被频繁调用（见 RescueBlockedProductions_DetectUnitToUnblock 的注释）
function RescueBlockedProductions_DoRescue(playerName, disallowedUnitHashes)
    -- 获取建造序列信息
    local factories, factoriesCount = CopyPlayerRegisteredObjectSet(playerName, "FACTORIES")
    for m = 1, factoriesCount, 1 do
        local factory = factories[m]
        if ObjectPlayerScriptName(factory) == playerName then
            local productions, count = ObjectGetProductionQueues(factory)
            -- 生产建筑有多个建造序列，遍历所有的建造序列
            for i = 1, count, 1 do
                local production = productions[i]
                for j = 1, production.QueueLength, 1 do
                    local item = production.Queue[j]
                    -- 检查正在建造的单位，是否处于被禁用列表里
                    if disallowedUnitHashes[tostring(item.InstanceId)] then
                        -- exMessageAppendToMessageArea(format("Blocked unit %s detected in factory %s for player %s. Attempting rescue.", tostring(item.InstanceId), tostring(factory), tostring(playerName)))
                        -- 正在建造的单位是被禁用的，序列将会卡住!

                        -- 让敌对工程师占领它，这样就能触发建造取消
                        -- 之后再让它恢复归属
                        -- 必须是先让敌对工程师占领，再重新改成己方归属。
                        -- 假如是先把建筑归属改为敌方、用己方工程师占领回来，那么建筑里取消的单位的资金将会归为敌方。
                        local x, y, z = ObjectGetPosition(factory)
                        local engineerName = RescueBlockedProductions_CreateEnemyEngineer(playerName, x, y, z)
                        -- ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", engineerName, "UNSELECTABLE", true)
                        SchedulerModule.delay_call(function(playerName, factoryId, engineerName)
                            local engineer = GetObjectByScriptName(engineerName)
                            if ObjectIsAlive(factoryId) and ObjectIsAlive(engineer) then
                                local factory = GetObjectById(factoryId)
                                ExecuteAction("UNIT_CONTEXT_SENSITIVE_ATTACK", engineer, factory)
                            end
                        end, 5, {playerName, ObjectGetId(factory), engineerName})
                        
                        SchedulerModule.delay_call(function(playerName, factoryId, engineerName)
                            if ObjectIsAlive(factoryId) then
                                -- 恢复归属
                                local factory = GetObjectById(factoryId)
                                ExecuteAction("NAMED_TRANSFER_OWNERSHIP_PLAYER", factory, playerName)
                            else
                                exMessageAppendToMessageArea(format("ERROR: Factory %s for player %s is no longer alive after rescue attempt.", tostring(factoryId), tostring(playerName)))
                            end
                            local engineer = GetObjectByScriptName(engineerName)
                            if ObjectIsAlive(engineer) then
                                ExecuteAction("NAMED_KILL", engineer)
                            end
                        end, 25, {playerName, ObjectGetId(factory), engineerName})

                        SchedulerModule.delay_call(function(playerName, factoryId, engineerName)
                            if ObjectIsAlive(factoryId) then
                                -- 确保归属恢复过来了
                                local factory = GetObjectById(factoryId)
                                ExecuteAction("NAMED_TRANSFER_OWNERSHIP_PLAYER", factory, playerName)
                            else
                                exMessageAppendToMessageArea(format("ERROR: Factory %s for player %s is no longer alive after rescue attempt.", tostring(factoryId), tostring(playerName)))
                            end
                        end, 75, {playerName, ObjectGetId(factory), engineerName})
                    end
                end
            end
        end
    end
end

function RescueBlockedProductions_CreateEnemyEngineer(playerName, x, y, z)
    local engineerName = format("%sUnblockerEngineer", playerName)
    if GetObjectByScriptName(engineerName) ~= nil then
        -- 玩家有多个生产建筑同时需要拯救？不会吧。。。
        -- 但，还是处理一下
        for e = 1, 100, 1 do
            engineerName = format("%sUnblockerEngineer%d", playerName, e)
            if GetObjectByScriptName(engineerName) == nil then
                -- 代表这个名字还没用过
                break
            end
        end
    end
    -- 获取敌对玩家 id
    local enemyPlayer = "PlyrCreeps"
    if g_PlayerNameToIndex[playerName] >= 4 then
        enemyPlayer = "PlyrCivilian"
    end

    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", engineerName, "JapanEngineer", format("%s/team%s", enemyPlayer, enemyPlayer), {
        X = x, Y = y, Z = z,
    }, 0)

    return engineerName
end
