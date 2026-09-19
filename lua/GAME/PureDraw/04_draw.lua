-- PureDraw: 抽卡核心逻辑
--   - 生产监听（有生产者消耗余额，无生产者拦截箱子结果）
--   - 加权随机抽卡、生成自定义单位
--   - 箱子跟踪与原生结果拦截
--   - 事件驱动并短时扫描空投点附近新生成的 AI 单位，加入攻击队列

function PureDrawRegisterKnownPlayerUnit(unitId, instanceId)
    if unitId == nil then
        return
    end
    local known = g_PureDrawKnownPlayerUnitIds[unitId]
    if known ~= nil then
        if instanceId ~= nil then
            known.InstanceId = instanceId
        end
        return
    end
    g_PureDrawKnownPlayerUnitSerial = g_PureDrawKnownPlayerUnitSerial + 1
    g_PureDrawKnownPlayerUnitIds[unitId] = {
        Serial = g_PureDrawKnownPlayerUnitSerial,
        InstanceId = instanceId,
    }
    g_PureDrawPendingNativeResultIds[unitId] = nil
end

function PureDrawRemoveKnownPlayerUnit(unitId)
    if unitId == nil then
        return
    end
    g_PureDrawKnownPlayerUnitIds[unitId] = nil
    g_PureDrawPendingNativeResultIds[unitId] = nil
    g_PureDrawScriptCreatedUnitIds[unitId] = nil
end

function PureDrawIsKnownPlayerUnit(unitId)
    return g_PureDrawKnownPlayerUnitIds[unitId] ~= nil
end

-- 记录抽卡模式开始时已经存在的玩家单位，避免开局赠送单位或预放置单位被误判。
function PureDrawInitializeKnownPlayerUnits()
    if g_PureDrawKnownPlayerUnitFilter == nil then
        g_PureDrawKnownPlayerUnitFilter = CreateObjectFilter({
            Relationship = "SAME_PLAYER",
            Include = "SELECTABLE",
            Exclude = "STRUCTURE",
            ExcludeThing = { "LuckyUnitCrateSeed", "UnitCrateNew", "UnitCrate" },
        })
    end
    for playerIndex = 1, 6, 1 do
        local units, count = ObjectFindObjects(P[playerIndex], nil,
            g_PureDrawKnownPlayerUnitFilter)
        for i = 1, count, 1 do
            local unitId = ObjectGetId(units[i])
            PureDrawRegisterKnownPlayerUnit(unitId, ObjectGetInstanceId(unitId))
        end
    end
end

-- 玩家碰箱子后生成的原生单位没有生产者。任何已注册模板的玩家新单位都会进入
-- 这里：生产单位、工程师、MCV和脚本生成单位立即登记；其余无生产者单位短暂
-- 观察，等待箱子的存活状态先转为已摧毁。
function PureDrawOnAnyRegisteredUnitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 or g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    if not g_PureDrawObservedPlayerUnitHashes[createdObjInstanceId] then
        return
    end
    local createdUnit = GetObjectById(createdObjId)
    if createdUnit == nil or not ObjectIsAlive(createdUnit) then
        return
    end
    if PureDrawIsKnownPlayerUnit(createdObjId) then
        return
    end
    local isScriptCreated = g_PureDrawScriptCreatedUnitIds[createdObjId]
    local hasProducer = ObjectGetProducerObject(createdObjId) ~= nil
    -- 原版箱子结果若是工程师，不直接登记为已知单位：交给统一观察器匹配箱子，
    -- 强制走自定义抽卡（工程师不允许成为抽卡结果）。自造/赠送工程师仍直接登记。
    if g_PureDrawNativeEngineerHashes[createdObjInstanceId]
        and not isScriptCreated and not hasProducer then
        if not g_PureDrawPendingNativeResultIds[createdObjId] then
            g_PureDrawPendingNativeResultIds[createdObjId] = true
            SchedulerModule.delay_call(PureDrawObserveUnknownPlayerUnit, 1,
                { createdObjId, createdObjInstanceId, ownerPlayerName, 45 })
        end
        return
    end
    if g_PureDrawAlwaysKnownUnitHashes[createdObjInstanceId]
        or isScriptCreated or hasProducer then
        PureDrawRegisterKnownPlayerUnit(createdObjId, createdObjInstanceId)
        return
    end
    if not g_PureDrawPendingNativeResultIds[createdObjId] then
        g_PureDrawPendingNativeResultIds[createdObjId] = true
        SchedulerModule.delay_call(PureDrawObserveUnknownPlayerUnit, 1,
            { createdObjId, createdObjInstanceId, ownerPlayerName, 45 })
    end
end

function PureDrawOnBuildableUnitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
    if g_DrawMode ~= 2 or playerIndex == nil then
        return
    end
    if g_PureDrawScriptCreatedUnitIds[createdObjId] then
        g_PureDrawScriptCreatedUnitIds[createdObjId] = nil
        PureDrawRegisterKnownPlayerUnit(createdObjId, createdObjInstanceId)
        return
    end
    local producer = ObjectGetProducerObject(createdObjId)
    if producer == nil then
        -- 无生产者单位交给统一观察器判断，JapanMechaX 的特殊生产形态仍继续走
        -- 原有配额重试，以兼容其出生首帧暂时拿不到 producer 的情况。
        if createdObjInstanceId ~= FastHash("JapanMechaX")
            and createdObjInstanceId ~= FastHash("JapanKingOniXMecha_Enhanced") then
            return
        end
    end
    PureDrawTryConsumeProductionQuota(createdObjId, createdObjInstanceId,
        playerIndex, ownerPlayerName, 3)
end

-- 只在已经确认摧毁、尚未匹配的玩家技能箱子中按固定出生坐标选择最近者。
function PureDrawFindConsumedTrackedCrate(x, y, z, candidateFrame)
    if x == nil or y == nil then
        return nil
    end

    local nearestId, nearestDistanceSquared = nil, 1e9
    for i = 1, getn(g_PureDrawTrackedCrateList), 1 do
        local tid = g_PureDrawTrackedCrateList[i]
        local state = g_PureDrawTrackedCrates[tid]
        if state ~= nil and state.DestroyedFrame ~= nil and not state.Matched
            and not state.IsSystemAirdrop then
            local dx = x - state.X
            local dy = y - state.Y
            local distanceSquared = dx * dx + dy * dy
            local frameDistance = candidateFrame - state.DestroyedFrame
            if frameDistance >= -3 and frameDistance <= 60
                and distanceSquared < nearestDistanceSquared then
                nearestDistanceSquared = distanceSquared
                nearestId = tid
            end
        end
    end
    -- 原生结果通常在箱子接触点附近生成；220 足以覆盖成组单位的出生散布。
    if nearestDistanceSquared <= 220 * 220 then
        return nearestId, nearestDistanceSquared
    end
    return nil, nil
end

function PureDrawIsSameNativeBatchType(state, instanceId)
    if state.BatchInstanceId == instanceId then
        return true
    end
    local batchInfo = g_PureDrawUnitInfoByHash[state.BatchInstanceId]
    if batchInfo ~= nil and g_PureDrawUnitInfoByHash[instanceId] == batchInfo then
        return true
    end
    if state.BatchUnitIndex ~= nil and g_UnitNameToUnitIndex[instanceId] == state.BatchUnitIndex then
        return true
    end
    return false
end

-- 已匹配箱子的后续同兵种结果仍属于原批次，不能再占用附近的另一个箱子。
function PureDrawFindActiveNativeBatch(x, y, z, playerName, instanceId)
    local nearestId, nearestDistanceSquared = nil, 1e9
    local now = GetFrame()
    for i = 1, getn(g_PureDrawTrackedCrateList), 1 do
        local tid = g_PureDrawTrackedCrateList[i]
        local state = g_PureDrawTrackedCrates[tid]
        if state ~= nil and state.Matched and state.BatchUntilFrame ~= nil
            and now <= state.BatchUntilFrame and state.BatchPlayer == playerName
            and PureDrawIsSameNativeBatchType(state, instanceId) then
            local dx = x - state.X
            local dy = y - state.Y
            local distanceSquared = dx * dx + dy * dy
            if distanceSquared < nearestDistanceSquared then
                nearestDistanceSquared = distanceSquared
                nearestId = tid
            end
        end
    end
    if nearestDistanceSquared <= 260 * 260 then
        return nearestId, nearestDistanceSquared
    end
    return nil, nil
end

for tier = 1, 4, 1 do
    local pool = g_PureDrawBuildableUnitPool[tier]
    for i = 1, getn(pool), 1 do
        local unitHash = FastHash(pool[i].Type)
        g_PureDrawObservedPlayerUnitHashes[unitHash] = true
        if not g_PureDrawRegisteredProductionHashes[unitHash] then
            RegisterUnitCreateCallback(pool[i].Type, PureDrawOnBuildableUnitBorn)
            g_PureDrawRegisteredProductionHashes[unitHash] = true
        end
        local aliases = g_PureDrawProductionAliases[pool[i].Type]
        if aliases ~= nil then
            for aliasIndex = 1, getn(aliases), 1 do
                local aliasHash = FastHash(aliases[aliasIndex])
                g_PureDrawObservedPlayerUnitHashes[aliasHash] = true
                if not g_PureDrawRegisteredProductionHashes[aliasHash] then
                    RegisterUnitCreateCallback(aliases[aliasIndex], PureDrawOnBuildableUnitBorn)
                    g_PureDrawRegisteredProductionHashes[aliasHash] = true
                end
            end
        end
    end
end

function PureDrawChooseWeightedUnit()
    local roll = GetRandomNumber() * 100
    local cumulative = 0
    local selectedTier = 4
    for tier = 1, 4, 1 do
        cumulative = cumulative + g_PureDrawConfig.TierWeights[tier]
        if roll < cumulative then
            selectedTier = tier
            break
        end
    end
    local source = g_PureDrawBuildableUnitPool[selectedTier]
    local eligible = {}
    for i = 1, getn(source), 1 do
        if g_DisableSeaArmy ~= 1 or not source[i].Sea then
            tinsert(eligible, source[i])
        end
    end
    local index = floor(GetRandomNumber() * getn(eligible)) + 1
    if index > getn(eligible) then
        index = getn(eligible)
    end
    return eligible[index]
end

function PureDrawSpawnCustomUnit(playerName, x, y, z)
    local info = PureDrawChooseWeightedUnit()
    if info == nil then
        return
    end
    local spawnCount = info.CustomDrawCount or 1
    for spawnIndex = 1, spawnCount, 1 do
        g_PureDrawCustomSpawnSerial = g_PureDrawCustomSpawnSerial + 1
        local unitName = format("PureDrawCustom_%d", g_PureDrawCustomSpawnSerial)
        local nextObjectId = GetNextObjectId()
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", unitName, info.Type,
            format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
        local unit = GetObjectByScriptName(unitName)
        if ObjectIsAlive(unit) then
            local actualId = ObjectGetId(unit)
            if actualId ~= nextObjectId then
                g_PureDrawScriptCreatedUnitIds[nextObjectId] = nil
                g_PureDrawScriptCreatedUnitIds[actualId] = true
            end
        else
            g_PureDrawScriptCreatedUnitIds[nextObjectId] = nil
        end
    end
end

g_PureDrawCollectorFilter = CreateObjectFilter({
    Include = "SELECTABLE",
    Exclude = "STRUCTURE",
    -- 箱子本身不能作为“拾取者”被检测到（幸运箱子由技能创建时可能属于玩家）。
    ExcludeThing = {
        "LuckyUnitCrateSeed",
        "UnitCrateNew",
        "UnitCrate",
    },
})

function PureDrawFindCollector(x, y, z, radius)
    local units, count = ObjectFindObjects(nil, {
        X = x, Y = y, Z = z, Radius = radius or 80, DistType = "CENTER_2D"
    }, g_PureDrawCollectorFilter)
    for i = 1, count, 1 do
        local playerName = ObjectPlayerScriptName(units[i])
        if g_PlayerNameToIndex[playerName] ~= nil then
            return playerName
        end
    end
    return nil
end

function PureDrawDeleteNativeResultNear(x, y, z, playerName, batchInstanceId, batchUnitIndex)
    if g_PureDrawNativeResultFilter == nil then
        local nativeTypes = {}
        for crateType = 1, 4, 1 do
            local source = g_CrateUnitsTemplate[crateType]
            for i = 1, getn(source), 1 do
                tinsert(nativeTypes, source[i].Type)
            end
        end
        for i = 1, getn(g_GroundCrateUnits), 1 do
            tinsert(nativeTypes, g_GroundCrateUnits[i])
        end
        for i = 1, getn(g_AirCrateUnits), 1 do
            tinsert(nativeTypes, g_AirCrateUnits[i])
        end
        for i = 1, getn(g_SeaCrateUnits), 1 do
            tinsert(nativeTypes, g_SeaCrateUnits[i])
        end
        -- 原版箱子也可能开出工程师；工程师不能作为抽卡结果，进入整批删除过滤器，
        -- 确保拦截自定义抽卡时开出的工程师也会被清理。
        for i = 1, getn(g_PlayerEngineerTypes), 1 do
            tinsert(nativeTypes, g_PlayerEngineerTypes[i])
        end
        -- 原生箱子也会开出常规生产池单位（例如游骑兵）；这些类型必须一起
        -- 进入整批删除过滤器，否则混合结果中只会删掉特殊箱子单位。
        for tier = 1, 4, 1 do
            local source = g_PureDrawBuildableUnitPool[tier]
            for i = 1, getn(source), 1 do
                local unitType = source[i].Type
                tinsert(nativeTypes, unitType)
                local aliases = g_PureDrawProductionAliases[unitType]
                if aliases ~= nil then
                    for aliasIndex = 1, getn(aliases), 1 do
                        tinsert(nativeTypes, aliases[aliasIndex])
                    end
                end
            end
        end
        g_PureDrawNativeResultFilter = CreateObjectFilter({
            Rule = "ANY",
            IncludeThing = nativeTypes,
        })
    end
    local units, count = ObjectFindObjects(nil, {
        X = x, Y = y, Z = z, Radius = 260, DistType = "CENTER_2D"
    }, g_PureDrawNativeResultFilter)
    for i = 1, count, 1 do
        local unit = units[i]
        local matchesPlayer = playerName == nil
            or ObjectPlayerScriptName(unit) == playerName
        local isUnproduced = ObjectGetProducerObject(unit) == nil
        local unitId = ObjectGetId(unit)
        local isUnknown = not PureDrawIsKnownPlayerUnit(unitId)
        local instanceId = ObjectGetInstanceId(unitId)
        local matchesBatchType = instanceId == batchInstanceId
            or (batchUnitIndex ~= nil
                and g_UnitNameToUnitIndex[instanceId] == batchUnitIndex)
            or (g_PureDrawUnitInfoByHash[batchInstanceId] ~= nil
                and g_PureDrawUnitInfoByHash[instanceId]
                    == g_PureDrawUnitInfoByHash[batchInstanceId])
        if matchesPlayer and isUnproduced and isUnknown and matchesBatchType then
            PureDrawRemoveKnownPlayerUnit(unitId)
            ExecuteAction("NAMED_DELETE", unit)
        end
    end
end

function PureDrawRemoveTrackedCrate(id)
    local state = g_PureDrawTrackedCrates[id]
    if state == nil then
        return
    end
    g_PureDrawTrackedCrates[id] = nil
    local listIndex = state.ListIndex
    if listIndex ~= nil and listIndex >= 1
        and listIndex <= getn(g_PureDrawTrackedCrateList) then
        local lastId = g_PureDrawTrackedCrateList[getn(g_PureDrawTrackedCrateList)]
        g_PureDrawTrackedCrateList[listIndex] = lastId
        g_PureDrawTrackedCrateList[getn(g_PureDrawTrackedCrateList)] = nil
        if lastId ~= id and g_PureDrawTrackedCrates[lastId] ~= nil then
            g_PureDrawTrackedCrates[lastId].ListIndex = listIndex
        end
    end
end

-- LuckyUnitCrateSeed 刚落地时 ObjectIsAlive 就可能返回 false，不能拿它判断拾取。
-- 箱子不会移动，因此持续检查固定坐标附近的玩家单位；首次接触即视为箱子已被
-- 摧毁。确认接触前记录永久保留，允许玩家在场上囤积任意数量的箱子。
function PureDrawTrackCustomCrate(id)
    local state = g_PureDrawTrackedCrates[id]
    if state == nil then
        return
    end
    local collectorPlayerName = PureDrawFindCollector(state.X, state.Y, state.Z, 65)
    if collectorPlayerName ~= nil then
        state.DestroyedFrame = GetFrame()
    end
    SchedulerModule.delay_call(PureDrawTrackCustomCrate, 1, { id })
end

-- 空投十连使用固定的十个落点：中心一点，外圈九点。只允许在这些落点小范围内
-- 新生成的 AI 单位进入根 ATTACK，从源头排除远处出生点刷新的无生产者单位。
function PureDrawIsNearAirdropPoint(unitId)
    local x, y, z = ObjectGetPosition(unitId)
    local centerX = 3547.06
    local centerY = 3055.49
    local detectRadius = 220
    for pointIndex = 1, 10, 1 do
        local pointX = centerX
        local pointY = centerY
        if pointIndex > 1 then
            local direction = g_PureDrawAirdropCircle[pointIndex - 1]
            pointX = pointX + direction[1] * 140
            pointY = pointY + direction[2] * 140
        end
        local dx = x - pointX
        local dy = y - pointY
        if dx * dx + dy * dy <= detectRadius * detectRadius then
            return true
        end
    end
    return false
end

-- 原生结果模板的专用回调只负责把事件送入统一观察器；所有判定均由已知单位、
-- producer、箱子销毁状态和固定坐标共同完成。
function PureDrawOnNativeCrateResultBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    PureDrawOnAnyRegisteredUnitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
end

function PureDrawObserveUnknownPlayerUnit(createdObjId, instanceId, playerName, retriesLeft)
    if g_DrawMode ~= 2 or PureDrawIsKnownPlayerUnit(createdObjId) then
        g_PureDrawPendingNativeResultIds[createdObjId] = nil
        return
    end
    local createdUnit = GetObjectById(createdObjId)
    if createdUnit == nil or not ObjectIsAlive(createdUnit) then
        g_PureDrawPendingNativeResultIds[createdObjId] = nil
        return
    end
    if ObjectGetProducerObject(createdObjId) ~= nil
        or g_PureDrawScriptCreatedUnitIds[createdObjId]
        or (g_PureDrawAlwaysKnownUnitHashes[instanceId]
            and not g_PureDrawNativeEngineerHashes[instanceId]) then
        PureDrawRegisterKnownPlayerUnit(createdObjId, instanceId)
        return
    end
    -- 工程师不能作为抽卡结果：无论箱子是否掷出自定义抽卡，一律强制自定义。
    local forceCustomDraw = g_PureDrawNativeEngineerHashes[instanceId] == true
    local x, y, z = ObjectGetPosition(createdObjId)
    local activeBatchId, activeBatchDistance = PureDrawFindActiveNativeBatch(x, y, z,
        playerName, instanceId)
    local consumedCrateId, consumedCrateDistance =
        PureDrawFindConsumedTrackedCrate(x, y, z, GetFrame())
    -- 同兵种活动批次与另一个未消费箱子同时接近时，仍以最近固定坐标为准。
    if activeBatchId ~= nil and (consumedCrateId == nil
        or activeBatchDistance <= consumedCrateDistance) then
        local activeState = g_PureDrawTrackedCrates[activeBatchId]
        if activeState.UseCustomDraw or forceCustomDraw then
            g_PureDrawPendingNativeResultIds[createdObjId] = nil
            PureDrawRemoveKnownPlayerUnit(createdObjId)
            ExecuteAction("NAMED_DELETE", createdUnit)
        else
            PureDrawRegisterKnownPlayerUnit(createdObjId, instanceId)
        end
        return
    end
    if consumedCrateId ~= nil then
        g_PureDrawPendingNativeResultIds[createdObjId] = nil
        local state = g_PureDrawTrackedCrates[consumedCrateId]
        state.Matched = true
        state.BatchPlayer = playerName
        state.BatchInstanceId = instanceId
        state.BatchUnitIndex = g_UnitNameToUnitIndex[instanceId]
        state.BatchUntilFrame = GetFrame() + 18
        if state.UseCustomDraw or forceCustomDraw then
            SchedulerModule.delay_call(PureDrawInterceptNativeResult, 2,
                { createdObjId, playerName, state.X, state.Y, state.Z,
                    consumedCrateId, instanceId, state.BatchUnitIndex, 8 })
        else
            PureDrawRegisterKnownPlayerUnit(createdObjId, instanceId)
            SchedulerModule.delay_call(PureDrawFinishNativePassThrough, 18,
                { consumedCrateId })
        end
        return
    end
    if retriesLeft > 0 then
        SchedulerModule.delay_call(PureDrawObserveUnknownPlayerUnit, 1,
            { createdObjId, instanceId, playerName, retriesLeft - 1 })
        return
    end
    PureDrawRegisterKnownPlayerUnit(createdObjId, instanceId)
end

function PureDrawFinishNativePassThrough(crateId)
    PureDrawRemoveTrackedCrate(crateId)
end

function PureDrawInterceptNativeResult(createdObjId, playerName, x, y, z,
    crateId, batchInstanceId, batchUnitIndex, passesLeft)
    local state = g_PureDrawTrackedCrates[crateId]
    if state == nil then
        return
    end
    PureDrawDeleteNativeResultNear(x, y, z, playerName,
        batchInstanceId, batchUnitIndex)
    if ObjectIsAlive(createdObjId) then
        PureDrawRemoveKnownPlayerUnit(createdObjId)
        ExecuteAction("NAMED_DELETE", GetObjectById(createdObjId))
    end
    if not state.CustomResultSpawned then
        state.CustomResultSpawned = true
        PureDrawSpawnCustomUnit(playerName, x, y, z)
    end
    if passesLeft > 0 and GetFrame() <= state.BatchUntilFrame then
        SchedulerModule.delay_call(PureDrawInterceptNativeResult, 2,
            { createdObjId, playerName, x, y, z, crateId,
                batchInstanceId, batchUnitIndex, passesLeft - 1 })
        return
    end
    PureDrawRemoveTrackedCrate(crateId)
end

-- 把 AI 默认待命队伍中尚未编队的单位加入对应攻击队列。
-- 逐个设置单位队伍，不合并整个源队伍，避免把玩家单位一起带入 AI 阵营。
-- 注意：空投十连的箱子以 PlyrNeutral/teamPlyrNeutral 生成，AI 拾取后生成的
-- 单位所有者已变为 AI（PlyrCivilian/PlyrCreeps），但队伍可能是引擎赋予的
-- 各种名字（teamPlyrNeutral 等）。因此这里放宽判断：只要所有者是 AI 且
-- 当前队伍不是攻击队列，就统一编入对应 AI 阵营的 ATTACK 队列。
function PureDrawJoinAIAttackTeam(unitId)
    if not ObjectIsAlive(unitId) then
        return
    end
    local unit = GetObjectById(unitId)
    local actualOwnerPlayerName = ObjectPlayerScriptName(unit)
    if actualOwnerPlayerName ~= "PlyrCivilian"
        and actualOwnerPlayerName ~= "PlyrCreeps" then
        return
    end
    
    -- 确定阵营索引 (7=PlyrCivilian, 8=PlyrCreeps)
    local sideIndex = 7
    if actualOwnerPlayerName == "PlyrCreeps" then
        sideIndex = 8
    end
    
    local currentTeam = ObjectTeamName(unit)
    local attackTeam = actualOwnerPlayerName .. "/ATTACK"
    if currentTeam ~= attackTeam and currentTeam ~= "ATTACK" then
        ExecuteAction("UNIT_SET_TEAM", unit, attackTeam)
        
        -- 加入队列后，根据LEVELUP变量设置正确的星级
        -- 这样与原版逻辑保持一致：星级由玩家T4升级状态决定
        if LEVELUP and LEVELUP[sideIndex] then
            local levelCount = LEVELUP[sideIndex]
            for i = 1, levelCount, 1 do
                ExecuteAction("UNIT_GAIN_LEVEL", unit, 1)
            end
        end
    end
end

-- UNITLIST 内的常规单位优先走事件驱动；箱子专属等未知模板则由每次空投后的
-- 短时扫描补漏。两个路径共用已入队 ID，事件成功后扫描不会重复处理。
g_PureDrawSeenAIUnitIds = {}
g_PureDrawJoinedAIUnitIds = {}
g_PureDrawAIUnitScanFilter = nil
g_PureDrawAirdropAIScanUntilFrame = 0
g_PureDrawAirdropAIScanActive = nil

function PureDrawTryJoinAirdropAIUnit(unitId)
    if g_PureDrawJoinedAIUnitIds[unitId] or not ObjectIsAlive(unitId) then
        return
    end
    local unit = GetObjectById(unitId)
    local ownerPlayerName = ObjectPlayerScriptName(unit)
    if ownerPlayerName ~= "PlyrCivilian" and ownerPlayerName ~= "PlyrCreeps" then
        return
    end
    if not PureDrawIsNearAirdropPoint(unitId) then
        return
    end
    g_PureDrawJoinedAIUnitIds[unitId] = true
    PureDrawJoinAIAttackTeam(unitId)
end

function PureDrawOnAIUnitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 then
        return
    end
    if ownerPlayerName ~= "PlyrCivilian" and ownerPlayerName ~= "PlyrCreeps" then
        return
    end
    -- 部分模板的创建事件早于最终坐标初始化，延迟两帧再判断空投点位置。
    SchedulerModule.delay_call(PureDrawTryJoinAirdropAIUnit, 2, { createdObjId })
end

function PureDrawInitializeAIUnitScanFilter()
    if g_PureDrawAIUnitScanFilter == nil then
        g_PureDrawAIUnitScanFilter = CreateObjectFilter({
            Relationship = "SAME_PLAYER",
            Include = "SELECTABLE",
            Exclude = "STRUCTURE",
            ExcludeThing = {
                "LuckyUnitCrateSeed",
                "UnitCrateNew",
                "UnitCrate",
            },
        })
    end
end

function PureDrawScanNewAIUnitsNearAirdrops(markOnly)
    PureDrawInitializeAIUnitScanFilter()
    for sideIndex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[sideIndex], nil,
            g_PureDrawAIUnitScanFilter)
        for i = 1, count, 1 do
            local unit = units[i]
            local unitId = ObjectGetId(unit)
            if not g_PureDrawSeenAIUnitIds[unitId] then
                g_PureDrawSeenAIUnitIds[unitId] = true
                if not markOnly and not g_PureDrawJoinedAIUnitIds[unitId] then
                    PureDrawTryJoinAirdropAIUnit(unitId)
                end
            end
        end
    end
end

function PureDrawContinueAirdropAIUnitScan()
    if g_DrawMode ~= 2 or GetFrame() > g_PureDrawAirdropAIScanUntilFrame then
        g_PureDrawAirdropAIScanActive = nil
        return
    end
    PureDrawScanNewAIUnitsNearAirdrops(nil)
    SchedulerModule.delay_call(PureDrawContinueAirdropAIUnitScan,
        g_PureDrawConfig.AirdropUnitScanInterval, {})
end

function PureDrawStartAirdropAIUnitScan()
    g_PureDrawAirdropAIScanUntilFrame = GetFrame()
        + g_PureDrawConfig.AirdropUnitScanFrames
    if g_PureDrawAirdropAIScanActive then
        return
    end
    g_PureDrawAirdropAIScanActive = true
    -- 先记录空投前已经存在的 AI 单位。之后只有扫描窗口内新出现且出生在
    -- 空投点附近的对象才会入队，避免把后来路过中央区域的旧单位误收。
    PureDrawScanNewAIUnitsNearAirdrops(true)
    SchedulerModule.delay_call(PureDrawContinueAirdropAIUnitScan,
        g_PureDrawConfig.AirdropUnitScanInterval, {})
end

-- 事件驱动只注册完整 UNITLIST，不再维护不完整且重复的 AI 箱子单位表。
g_PureDrawRegisteredAIUnitHashes = {}
for unitIndex = 1, unitcountmax, 1 do
    local unitType = UNITLIST[unitIndex]
    local unitHash = FastHash(unitType)
    g_PureDrawObservedPlayerUnitHashes[unitHash] = true
    if not g_PureDrawRegisteredAIUnitHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnAIUnitBorn)
        g_PureDrawRegisteredAIUnitHashes[unitHash] = true
    end
end
