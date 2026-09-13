-- PureDraw: 抽卡核心逻辑
--   - 生产监听（有生产者消耗余额，无生产者拦截箱子结果）
--   - 加权随机抽卡、生成自定义单位
--   - 箱子跟踪与原生结果拦截
--   - 事件驱动并短时扫描空投点附近新生成的 AI 单位，加入攻击队列

-- 玩家碰箱子后引擎生成的原生单位没有生产者（ObjectGetProducerObject 返回 nil），
-- 而正常从生产建筑序列产出的单位一定有生产者。因此：
-- 有生产者 -> 玩家生产 -> 消耗生产余额；
-- 无生产者（凭空出现：箱子结果、赠送单位）-> 不消耗余额；
-- 若该凭空单位匹配到“刚消失的被跟踪箱子”，则拦截并换成自定义抽卡单位。
function PureDrawOnBuildableUnitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
    if g_DrawMode ~= 2 or playerIndex == nil then
        return
    end
    if g_PureDrawScriptCreatedUnitIds[createdObjId] then
        g_PureDrawScriptCreatedUnitIds[createdObjId] = nil
        return
    end
    local producer = ObjectGetProducerObject(createdObjId)
    if producer == nil then
        -- 凭空出现的玩家单位：不消耗余额。若匹配到刚消失的被跟踪箱子，则拦截。
        local consumedCrateId = PureDrawFindConsumedTrackedCrate()
        if consumedCrateId ~= nil then
            local x, y, z = ObjectGetPosition(createdObjId)
            PureDrawRemoveTrackedCrate(consumedCrateId)
            g_PureDrawScriptCreatedUnitIds[createdObjId] = true
            SchedulerModule.delay_call(PureDrawInterceptNativeResult, 1,
                { createdObjId, ownerPlayerName, x, y, z })
            return
        end
        if createdObjInstanceId ~= FastHash("JapanMechaX")
            and createdObjInstanceId ~= FastHash("JapanKingOniXMecha_Enhanced") then
            return
        end
    end
    PureDrawTryConsumeProductionQuota(createdObjId, createdObjInstanceId,
        playerIndex, ownerPlayerName, 3)
end

-- 查找该玩家“刚消失（被碰/消耗）”的跟踪箱子。只按箱子是否已死匹配，
-- 不依赖生成位置（引擎可能在玩家基地等位置生成箱子结果单位）。
-- DiedFrame 尚未记录时（原生结果单位先于下一帧的跟踪回调创建）按“刚消失”处理，
-- 优先返回。超过 60 帧未清理的过期箱子会由 CleanupTrackedCrate 移除，因此
-- 列表里“已死”的箱子都是近期消失的。
function PureDrawFindConsumedTrackedCrate()
    local now = GetFrame()
    local bestId, bestAge = nil, 1e9
    for i = 1, getn(g_PureDrawTrackedCrateList), 1 do
        local tid = g_PureDrawTrackedCrateList[i]
        local state = g_PureDrawTrackedCrates[tid]
        if state ~= nil and not ObjectIsAlive(tid) then
            local age
            if state.DiedFrame ~= nil then
                age = now - state.DiedFrame
            else
                age = 0
            end
            if age < bestAge then
                bestAge = age
                bestId = tid
            end
        end
    end
    return bestId
end

for tier = 1, 4, 1 do
    local pool = g_PureDrawBuildableUnitPool[tier]
    for i = 1, getn(pool), 1 do
        local unitHash = FastHash(pool[i].Type)
        if not g_PureDrawRegisteredProductionHashes[unitHash] then
            RegisterUnitCreateCallback(pool[i].Type, PureDrawOnBuildableUnitBorn)
            g_PureDrawRegisteredProductionHashes[unitHash] = true
        end
        local aliases = g_PureDrawProductionAliases[pool[i].Type]
        if aliases ~= nil then
            for aliasIndex = 1, getn(aliases), 1 do
                local aliasHash = FastHash(aliases[aliasIndex])
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

function PureDrawDeleteNativeResultNear(x, y, z)
    if g_PureDrawNativeResultFilter == nil then
        local nativeTypes = {}
        for crateType = 1, 4, 1 do
            local source = g_CrateUnitsTemplate[crateType]
            for i = 1, getn(source), 1 do
                tinsert(nativeTypes, source[i].Type)
            end
        end
        g_PureDrawNativeResultFilter = CreateObjectFilter({
            Rule = "ANY",
            IncludeThing = nativeTypes,
        })
    end
    local units, count = ObjectFindObjects(nil, {
        X = x, Y = y, Z = z, Radius = 180, DistType = "CENTER_2D"
    }, g_PureDrawNativeResultFilter)
    for i = 1, count, 1 do
        ExecuteAction("NAMED_DELETE", units[i])
    end
end

function PureDrawFinishCustomCrate(playerName, x, y, z, removeNativeResult)
    if g_PlayerNameToIndex[playerName] == nil then
        return
    end
    if removeNativeResult then
        PureDrawDeleteNativeResultNear(x, y, z)
    end
    PureDrawSpawnCustomUnit(playerName, x, y, z)
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

-- 判断某个单位是否位于任一被跟踪箱子附近（即它是玩家碰该箱子生成的原生抽卡单位，
-- 会被 PureDrawOnNativeCrateResultBorn 拦截）。生产余额监听用它跳过这些单位。
function PureDrawIsNearTrackedCrate(unitId)
    if getn(g_PureDrawTrackedCrateList) <= 0 then
        return false
    end
    local x, y, z = ObjectGetPosition(unitId)
    for i = 1, getn(g_PureDrawTrackedCrateList), 1 do
        local tid = g_PureDrawTrackedCrateList[i]
        local state = g_PureDrawTrackedCrates[tid]
        if state ~= nil then
            local dx = x - state.X
            local dy = y - state.Y
            if dx * dx + dy * dy < 160 * 160 then
                return true
            end
        end
    end
    return false
end

-- 轻量跟踪：箱子活着时持续刷新位置（NoCreatesInCenter 可能移动箱子）。
-- 箱子消失后保留 30 帧，等待“碰箱子生成的原生单位”创建回调来拦截；
-- 若超时无人拦截（例如箱子过期消失），则清理跟踪记录。
function PureDrawTrackCustomCrate(id)
    local state = g_PureDrawTrackedCrates[id]
    if state == nil then
        return
    end
    if ObjectIsAlive(id) then
        local x, y, z = ObjectGetPosition(GetObjectById(id))
        state.X, state.Y, state.Z = x, y, z
        SchedulerModule.delay_call(PureDrawTrackCustomCrate, 1, { id })
        return
    end
    -- 箱子已消失（被碰或过期）：记录消失帧，供拦截逻辑匹配；稍后清理。
    if state.DiedFrame == nil then
        state.DiedFrame = GetFrame()
    end
    SchedulerModule.delay_call(PureDrawCleanupTrackedCrate, 60, { id })
end

function PureDrawCleanupTrackedCrate(id)
    if g_PureDrawTrackedCrates[id] ~= nil then
        PureDrawRemoveTrackedCrate(id)
    end
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

-- 玩家碰箱子后，引擎会立即删除箱子并在玩家阵营生成一个原生抽卡单位。
-- 拦截：既监听原生单位创建（本回调），也在 PureDrawOnBuildableUnitBorn 里
-- 用生产者判定处理。匹配一律基于“该玩家刚消失的被跟踪箱子”，不依赖位置。
-- AI 空投单位由下方独立的事件回调与短时空间扫描处理。
function PureDrawOnNativeCrateResultBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 then
        return
    end
    -- 已被 buildable 回调拦截处理（它先注册先执行），跳过避免重复。
    if g_PureDrawScriptCreatedUnitIds[createdObjId] then
        return
    end
    -- 只有玩家碰箱子生成的原生单位才拦截
    if g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    local consumedCrateId = PureDrawFindConsumedTrackedCrate()
    if consumedCrateId ~= nil then
        local x, y, z = ObjectGetPosition(createdObjId)
        PureDrawRemoveTrackedCrate(consumedCrateId)
        g_PureDrawScriptCreatedUnitIds[createdObjId] = true
        SchedulerModule.delay_call(PureDrawInterceptNativeResult, 1,
            { createdObjId, ownerPlayerName, x, y, z })
    end
end

function PureDrawInterceptNativeResult(createdObjId, playerName, x, y, z)
    if ObjectIsAlive(createdObjId) then
        ExecuteAction("NAMED_DELETE", GetObjectById(createdObjId))
    end
    PureDrawSpawnCustomUnit(playerName, x, y, z)
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
    if not g_PureDrawRegisteredAIUnitHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnAIUnitBorn)
        g_PureDrawRegisteredAIUnitHashes[unitHash] = true
    end
end
