-- 讲解见 analysis/地图注释说明文档.md 附录 A.2

RescueBlockedProductions_UnitList = {
    'JapanPowerPlantEgg',
    'CelestialDF41',
    'CelestialAdvanceAircraftTech4',
    'CelestialAdvanceAircraftTech4_Enhanced',
    -- 保留守护者坦克限造配套的生产队列解卡项，当前版本取消数量限制；恢复限造时取消注释。
    -- 'AlliedAntiVehicleVehicleTech1',
    -- 'AlliedAntiVehicleVehicleTech1_Enhanced',
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
        -- 东风速递符文赠送的那辆不占建造额度：上限从 1 提高到 2。
        local maxBuildableCount = 0
        if g_HextechDF41ExtraQuota ~= nil and g_HextechDF41ExtraQuota[playerIndex] then
            maxBuildableCount = 1
        end
        for ownedCount = 0, maxBuildableCount, 1 do
            if EvaluateCondition('PLAYER_HAS_OBJECT_COMPARISON',
                'Player_'..playerIndex, '==', ownedCount, 'CelestialDF41') then
                return true
            end
        end
        return false
    elseif unitType == 'CelestialAdvanceAircraftTech4'
        or unitType == 'CelestialAdvanceAircraftTech4_Enhanced' then
        return GetPlayerYaoguangRemainingProductionQuota(playerIndex) > 0
    elseif unitType == 'AlliedAntiVehicleVehicleTech1'
        or unitType == 'AlliedAntiVehicleVehicleTech1_Enhanced' then
        return GetPlayerGuardianTankCount(playerIndex) < GUARDIAN_TANK_LIMIT
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
