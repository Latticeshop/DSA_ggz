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
    [7] = {},
    [8] = {},
}
SchedulerModule.call_every_x_frame(function()
    for p = 1, 8, 1 do
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

        -- 大船建造栏自愈：地图的 bigshiplimit__N 是一次性禁造（DeactivateUponSuccess），
        -- 纯抽卡模式与禁海模式的可造性另有完整规则，这里不插手。
        if SetBigShipBuildability ~= nil and bigshiplimitc ~= nil and BIGSHIP_LIMIT ~= nil
            and g_DrawMode ~= 2 and g_DisableSeaArmy ~= 1
            and g_PureDrawT4ShipUnlocked ~= nil and g_PureDrawT4ShipUnlocked[p] == true
            and (bigshiplimitc[p] or 0) < BIGSHIP_LIMIT then
            SetBigShipBuildability(p, 1)
        end
    end
end, 75, nil)

function RescueBlockedProductions_CheckUnitCanBuild(playerIndex, unitType)
    if unitType == 'JapanPowerPlantEgg' then
        local units, count = ObjectFindObjects(P[playerIndex], nil, FilterAnyPowerPlantOrEgg)
        if units ~= nil then
            return count < (g_CachedPlayersPowerPlantLimit[playerIndex] or 0)
        end
        -- FLAGENPOWER 这玩意在 lua\LUABOX\moneysys\MONEYINI_3.lua 里面
        return FLAGENPOWER[playerIndex] == 1
    elseif unitType == 'CelestialDF41' then
        -- 东风上限 = 1 + 东风速递额外额度；继承队友的额度继续累加。
        local extraQuota = 0
        if g_HextechDF41ExtraQuota ~= nil then
            extraQuota = g_HextechDF41ExtraQuota[playerIndex]
            if extraQuota == true then
                extraQuota = 1
            end
            extraQuota = tonumber(extraQuota) or 0
        end
        local maxBuildableCount = extraQuota
        if GetPlayerDF41BuildLimit ~= nil then
            maxBuildableCount = GetPlayerDF41BuildLimit(playerIndex) - 1
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
    if g_IsDevilSeat(g_PlayerNameToIndex[playerName]) then
        enemyPlayer = "PlyrCivilian"
    end

    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", engineerName, "JapanEngineer", format("%s/team%s", enemyPlayer, enemyPlayer), {
        X = x, Y = y, Z = z,
    }, 0)

    return engineerName
end
