-- ============================================================
-- PureDraw: 抽卡核心逻辑
--   - 生产监听（有生产者消耗余额，无生产者拦截箱子结果）
--   - 加权随机抽卡、生成自定义单位
--   - 箱子跟踪与原生结果拦截
--   - AI 单位加入攻击队列
-- ============================================================

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
        end
        return
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
    g_PureDrawCustomSpawnSerial = g_PureDrawCustomSpawnSerial + 1
    local unitName = format("PureDrawCustom_%d", g_PureDrawCustomSpawnSerial)
    local nextObjectId = GetNextObjectId()
    g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", unitName, info.Type,
        format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
    local unit = GetObjectByScriptName(unitName)
    if not ObjectIsAlive(unit) then
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = nil
        return
    end
    local actualId = ObjectGetId(unit)
    if actualId ~= nextObjectId then
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = nil
        g_PureDrawScriptCreatedUnitIds[actualId] = true
    end
    exAddTextToPublicBoardForPlayer(playerName,
        Localization.get("pure_draw.custom_result", info.Tier), 5)
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

-- 玩家碰箱子后，引擎会立即删除箱子并在玩家阵营生成一个原生抽卡单位。
-- 拦截：既监听原生单位创建（本回调），也在 PureDrawOnBuildableUnitBorn 里
-- 用生产者判定处理。匹配一律基于“该玩家刚消失的被跟踪箱子”，不依赖位置。
function PureDrawOnNativeCrateResultBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 then
        return
    end
    -- 已被 buildable 回调拦截处理（它先注册先执行），跳过避免重复。
    if g_PureDrawScriptCreatedUnitIds[createdObjId] then
        return
    end
    -- AI 碰箱子（空投等）：保留单位，但把 AI 单位加入对应阵营的攻击队列。
    if ownerPlayerName == "PlyrCivilian" or ownerPlayerName == "PlyrCreeps" then
        SchedulerModule.delay_call(PureDrawJoinAIAttackTeam, 1,
            { createdObjId })
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
    local currentTeam = ObjectTeamName(unit)
    local attackTeam = actualOwnerPlayerName .. "/ATTACK"
    if currentTeam ~= attackTeam and currentTeam ~= "ATTACK" then
        ExecuteAction("UNIT_SET_TEAM", unit, attackTeam)
    end
end

-- 周期检查两个 AI 阵营的全部战斗单位，补上没有经过普通生产编队流程的单位。
-- 通过实际所有者过滤，玩家单位不会被处理；通过默认待命队伍过滤，只处理未编队单位。
function PureDrawScanAIAttackUnits()
    if g_PureDrawAIAttackUnitFilter == nil then
        g_PureDrawAIAttackUnitFilter = CreateObjectFilter({
            Rule = "ANY",
            Include = "INFANTRY VEHICLE AIRCRAFT",
            Exclude = "STRUCTURE",
        })
    end
    for sideIndex = 7, 8, 1 do
        local units, count = ObjectFindObjects(P[sideIndex], nil,
            g_PureDrawAIAttackUnitFilter)
        for i = 1, count, 1 do
            local unit = units[i]
            if ObjectIsAlive(unit) then
                local ownerPlayerName = ObjectPlayerScriptName(unit)
                if ownerPlayerName == "PlyrCivilian"
                    or ownerPlayerName == "PlyrCreeps" then
                    PureDrawJoinAIAttackTeam(ObjectGetId(unit))
                end
            end
        end
    end
end

SchedulerModule.call_every_x_frame(PureDrawScanAIAttackUnits, 30, nil)
