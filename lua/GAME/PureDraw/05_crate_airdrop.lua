-- 讲解见 analysis/地图注释说明文档.md 附录 A.5

function PureDrawOnCrateSeedBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    -- 系统空投在生成前预登记对象 ID，因此不会进入玩家自定义抽卡检测。
    local isAirdrop = g_PureDrawAirdropCrateIds[createdObjId] == true
    local trackCrate = g_DrawMode == 2 and not isAirdrop
    if trackCrate then
        local roll = GetRandomNumber()
        local listIndex = getn(g_PureDrawTrackedCrateList) + 1
        g_PureDrawTrackedCrateList[listIndex] = createdObjId
        g_PureDrawTrackedCrates[createdObjId] = {
            X = x,
            Y = y,
            Z = z,
            Owner = ownerPlayerName,
            ListIndex = listIndex,
            UseCustomDraw = roll < g_PureDrawConfig.CustomDrawChance,
            Matched = false,
        }
    end
    if not isAirdrop then
        -- 保持旧版规则：禁止把玩家箱子投放到中央战场（空投箱子不受此限制）。
        SchedulerModule.delay_call(NoCreatesInCenter, 1, { createdObjId })
    end
    if trackCrate then
        SchedulerModule.delay_call(PureDrawTrackCustomCrate, 2, { createdObjId })
    end
end

-- 兼容备份：若某些途径确实创建了 UnitCrateNew / UnitCrate 物理箱，同样直接跟踪。
function PureDrawOnPhysicalCrateBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    local isAirdrop = g_PureDrawAirdropCrateIds[createdObjId] == true
    local trackCrate = g_DrawMode == 2 and not isAirdrop
    if trackCrate then
        local roll = GetRandomNumber()
        local listIndex = getn(g_PureDrawTrackedCrateList) + 1
        g_PureDrawTrackedCrateList[listIndex] = createdObjId
        g_PureDrawTrackedCrates[createdObjId] = {
            X = x,
            Y = y,
            Z = z,
            Owner = ownerPlayerName,
            ListIndex = listIndex,
            UseCustomDraw = roll < g_PureDrawConfig.CustomDrawChance,
            Matched = false,
        }
    end
    if not isAirdrop then
        SchedulerModule.delay_call(NoCreatesInCenter, 1, { createdObjId })
    end
    if trackCrate then
        SchedulerModule.delay_call(PureDrawTrackCustomCrate, 2, { createdObjId })
    end
end

-- 替换池：g_CrateUnitsTemplate 的四类（步兵/载具/空军/海军）里剔除被禁的兵种。
function PureDrawChooseNativeAllowedUnit()
    local pool = {}
    for crateType = 1, 4, 1 do
        if BanModeRecycleCategoryEnabled(crateType) == 1 then
            local source = g_CrateUnitsTemplate[crateType]
            for i = 1, getn(source), 1 do
                tinsert(pool, source[i])
            end
        end
    end
    if getn(pool) == 0 then
        return nil
    end
    local index = floor(GetRandomNumber() * getn(pool)) + 1
    if index > getn(pool) then
        index = getn(pool)
    end
    return pool[index]
end

-- 原生箱子结果落在被禁兵种上时，换成另一个未被禁的箱子结果（纯抽卡模式专用）。
-- 「要不要换」在同步阶段就判定完，delay_call 只带 id 与玩家名（Lua 4.0 无闭包）。
function PureDrawReplaceNativeBannedResult(createdObjId, createdObjInstanceId, ownerPlayerName, banType)
    if g_DrawMode ~= 2 or g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    if BanModeIsTypeBanned(banType) ~= 1 then
        return
    end
    SchedulerModule.delay_call(PureDrawApplyNativeBannedReplace, 1,
        { createdObjId, ownerPlayerName })
end

function PureDrawReplaceNativeInfantryResult(id, instId, owner)
    PureDrawReplaceNativeBannedResult(id, instId, owner, "infantry")
end

function PureDrawReplaceNativeVehicleResult(id, instId, owner)
    PureDrawReplaceNativeBannedResult(id, instId, owner, "vehicle")
end

function PureDrawReplaceNativeAircraftResult(id, instId, owner)
    PureDrawReplaceNativeBannedResult(id, instId, owner, "aircraft")
end

function PureDrawReplaceNativeNavyResult(id, instId, owner)
    PureDrawReplaceNativeBannedResult(id, instId, owner, "navy")
end

function PureDrawApplyNativeBannedReplace(id, playerName)
    if not ObjectIsAlive(id) or ObjectGetProducerObject(id) ~= nil then
        return
    end
    local unit = GetObjectById(id)
    local x, y, z = ObjectGetPosition(unit)
    local info = PureDrawChooseNativeAllowedUnit()
    if info == nil then
        return
    end
    ExecuteAction("NAMED_DELETE", unit)
    local nextObjectId = GetNextObjectId()
    g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "", info.Type,
        format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
end

-- 三类箱子模板逐个登记；同一模板按双形态登记两次，第二次因对象已被删除自动跳过。
g_PureDrawNativeCrateHandlers = {
    infantry = PureDrawReplaceNativeInfantryResult,
    vehicle = PureDrawReplaceNativeVehicleResult,
    aircraft = PureDrawReplaceNativeAircraftResult,
    navy = PureDrawReplaceNativeNavyResult,
}

function PureDrawRegisterNativeCrateBans(list)
    for i = 1, getn(list), 1 do
        local unitType = list[i]
        local types = BanModeGetNameTypes(unitType)
        if types ~= nil then
            for t = 1, getn(types), 1 do
                RegisterUnitCreateCallback(unitType, g_PureDrawNativeCrateHandlers[types[t]])
            end
        end
    end
end

PureDrawRegisterNativeCrateBans(g_GroundCrateUnits)
PureDrawRegisterNativeCrateBans(g_AirCrateUnits)
PureDrawRegisterNativeCrateBans(g_SeaCrateUnits)

function PureDrawFindAirdropOwnerTeam()
    for playerIndex = 1, 6, 1 do
        local playerName = "Player_" .. playerIndex
        if EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", playerName, "Human") then
            -- 与开局赠送抽卡工程师使用同一支已存在的玩家 crate 队伍。
            return playerName .. "/crate"
        end
    end
    return nil
end

function PureDrawRegisterAirdropPoint(x, y)
    -- 阵型会重复抽中；相同绝对坐标只登记一次，避免长期游戏中检测表无限增长。
    for pointIndex = 1, getn(g_PureDrawActiveAirdropPoints), 1 do
        local point = g_PureDrawActiveAirdropPoints[pointIndex]
        if point[1] == x and point[2] == y then
            return
        end
    end
    tinsert(g_PureDrawActiveAirdropPoints, { x, y })
end

function PureDrawSpawnAirdropCrate(serial, i, ownerTeam,
    centerX, centerY, centerZ, offsetX, offsetY)
    local crateName = format("PureDrawAirdrop_%d_%d", serial, i)
    local nextObjectId = GetNextObjectId()
    g_PureDrawAirdropCrateIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", crateName, "LuckyUnitCrateSeed",
        ownerTeam, {
            X = centerX + offsetX,
            Y = centerY + offsetY,
            Z = centerZ,
        }, 0)
    local crate = GetObjectByScriptName(crateName)
    if ObjectIsAlive(crate) then
        local actualId = ObjectGetId(crate)
        g_PureDrawAirdropCrateIds[actualId] = true
        PureDrawRegisterAirdropPoint(centerX + offsetX, centerY + offsetY)
        ExecuteAction("OBJECT_CREATE_RADAR_EVENT", crate, "Information")
        return true
    end
    return false
end

function PureDrawSpawnAirdrop()
    local leftTower = GetObjectByScriptName("T74")
    local rightTower = GetObjectByScriptName("T84")
    if not ObjectIsAlive(leftTower) or not ObjectIsAlive(rightTower) then
        return
    end
    -- 空投圆心固定为战场中心（玩家从地图编辑器校准：3547.06, 3055.49）。
    -- 不再依赖 T74/T84 中点，避免塔的位置波动导致圆心漂移（曾出现极端偏右的落点）。
    -- Z 仍取两塔平均（地面高度）。
    local lx, ly, lz = ObjectGetPosition(leftTower)
    local rx, ry, rz = ObjectGetPosition(rightTower)
    local centerX = 3547.06
    local centerY = 3055.49
    local centerZ = (lz + rz) / 2
    local ownerTeam = PureDrawFindAirdropOwnerTeam()
    if ownerTeam == nil then
        return
    end
    g_PureDrawAirdropSerial = g_PureDrawAirdropSerial + 1

    -- 概率判定已经在 PureDrawAirdropCheck 完成；命中后再同步随机本次阵型。
    local formationCount = getn(g_PureDrawAirdropFormations)
    local formationIndex = floor(GetRandomNumber() * formationCount) + 1
    if formationIndex > formationCount then
        formationIndex = formationCount
    end
    local formation = g_PureDrawAirdropFormations[formationIndex]
    local spawnedCount = 0
    -- 所有箱子统一挂到有效玩家队伍，保证能够生成，同时避免 AI 主动拾取。
    for i = 1, getn(formation), 1 do
        local offset = formation[i]
        if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, i, ownerTeam,
                centerX, centerY, centerZ, offset[1], offset[2]) then
            spawnedCount = spawnedCount + 1
        end
    end
    if spawnedCount > 0 then
        PureDrawStartAirdropAIUnitScan()
        exAddTextToPublicBoard(Localization.get("pure_draw.airdrop"), 12)
    end
end

function PureDrawAirdropCheck()
    if g_DrawMode == 2 then
        local roll = GetRandomNumber()
        if roll < g_PureDrawConfig.AirdropChance then
            PureDrawSpawnAirdrop()
        end
    end
    SchedulerModule.delay_call(PureDrawAirdropCheck, g_PureDrawConfig.AirdropCheckFrames, {})
end

function PureDrawOnRoundBeginRefreshQuota()
    if g_DrawMode ~= 2 then
        return
    end
    local round = exCounterGetByName("lvc")
    if round == nil or round <= 0 or round == g_PureDrawLastRound then
        return
    end
    g_PureDrawLastRound = round
    if mod(round, g_PureDrawConfig.RefreshRounds) == 0 then
        for playerIndex = 1, 6, 1 do
            PureDrawRefreshQuota(playerIndex)
        end
    end
end

function PureDrawRegisterRoundBeginRefresh()
    if g_PureDrawRoundBeginRefreshRegistered or RoundLuaManager == nil then
        return
    end
    RoundLuaManager.CallOnEveryRoundBegin(PureDrawOnRoundBeginRefreshQuota, {})
    g_PureDrawRoundBeginRefreshRegistered = true
end
