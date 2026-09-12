-- ============================================================
-- PureDraw: 箱子种子/物理箱与空投
--   - 跟踪 LuckyUnitCrateSeed / 物理箱
--   - 禁海时把海里抽卡结果替换为陆地单位
--   - 空投十连（5% 概率，圆形布局）
--   - 每 3 回合刷新生产配额
-- ============================================================

-- 日冕引擎的“幸运单位箱子”技能直接创建可拾取的 LuckyUnitCrateSeed 对象，
-- 而不会再有第二段 UnitCrateNew 物理箱（原版可正常工作的实现就是直接跟踪
-- LuckyUnitCrateSeed）。因此拦截逻辑直接跟踪种子对象本身；
-- UnitCrateNew / UnitCrate 的创建回调仅作兼容备份，以防某些途径确实生成物理箱。
function PureDrawOnCrateSeedBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    local roll = GetRandomNumber()
    local useCustomDraw = g_DrawMode == 2
        and roll < g_PureDrawConfig.CustomDrawChance
    local isAirdrop = g_PureDrawAirdropCrateIds[createdObjId] == true
    if useCustomDraw then
        local listIndex = getn(g_PureDrawTrackedCrateList) + 1
        g_PureDrawTrackedCrateList[listIndex] = createdObjId
        g_PureDrawTrackedCrates[createdObjId] = {
            X = x,
            Y = y,
            Z = z,
            Owner = ownerPlayerName,
            ListIndex = listIndex,
        }
    end
    if not isAirdrop then
        -- 保持旧版规则：禁止把玩家箱子投放到中央战场（空投箱子不受此限制）。
        SchedulerModule.delay_call(NoCreatesInCenter, 1, { createdObjId })
    end
    if useCustomDraw then
        SchedulerModule.delay_call(PureDrawTrackCustomCrate, 2, { createdObjId })
    end
end

-- 兼容备份：若某些途径确实创建了 UnitCrateNew / UnitCrate 物理箱，同样直接跟踪。
function PureDrawOnPhysicalCrateBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    local roll = GetRandomNumber()
    local useCustomDraw = g_DrawMode == 2
        and roll < g_PureDrawConfig.CustomDrawChance
    local isAirdrop = g_PureDrawAirdropCrateIds[createdObjId] == true
    if useCustomDraw then
        local listIndex = getn(g_PureDrawTrackedCrateList) + 1
        g_PureDrawTrackedCrateList[listIndex] = createdObjId
        g_PureDrawTrackedCrates[createdObjId] = {
            X = x,
            Y = y,
            Z = z,
            Owner = ownerPlayerName,
            ListIndex = listIndex,
        }
        PureDrawTrackCustomCrate(createdObjId)
    elseif not isAirdrop then
        SchedulerModule.delay_call(NoCreatesInCenter, 1, { createdObjId })
    end
end

function PureDrawChooseNativeNonSeaUnit()
    local pool = {}
    for crateType = 1, 3, 1 do
        local source = g_CrateUnitsTemplate[crateType]
        for i = 1, getn(source), 1 do
            tinsert(pool, source[i])
        end
    end
    local index = floor(GetRandomNumber() * getn(pool)) + 1
    if index > getn(pool) then
        index = getn(pool)
    end
    return pool[index]
end

function PureDrawReplaceNativeSeaResult(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 or g_DisableSeaArmy ~= 1
        or g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    SchedulerModule.delay_call(function(id, playerName)
        if not ObjectIsAlive(id) or ObjectGetProducerObject(id) ~= nil then
            return
        end
        local unit = GetObjectById(id)
        local x, y, z = ObjectGetPosition(unit)
        local info = PureDrawChooseNativeNonSeaUnit()
        ExecuteAction("NAMED_DELETE", unit)
        local nextObjectId = GetNextObjectId()
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "", info.Type,
            format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
    end, 1, { createdObjId, ownerPlayerName })
end

for i = 1, getn(g_SeaCrateUnits), 1 do
    RegisterUnitCreateCallback(g_SeaCrateUnits[i], PureDrawReplaceNativeSeaResult)
end

-- 生成一个空投箱子。箱子使用引擎同款 LuckyUnitCrateSeed 类型（技能创建的
-- 可拾取箱子就是它，而不是 UnitCrateNew）。成功时记录实际对象 ID 并返回 true。
-- 注意：RA3LuaBridge 方言（Lua 4.0）不支持闭包访问外层局部变量，因此
-- 序列号、中心坐标等全部通过参数显式传入，函数体内不使用任何外层局部变量。
function PureDrawSpawnAirdropCrate(serial, i, team, centerX, centerY, centerZ)
    local crateName = format("PureDrawAirdrop_%d_%d", serial, i)
    -- 圆形布局：i=1 在圆心，i=2..10 均匀分布在圆周上（半径 140）。
    local column, row
    if i == 1 then
        column = 0
        row = 0
    else
        local dir = g_PureDrawAirdropCircle[mod(i - 2, 9) + 1]
        column = dir[1] * 140
        row = dir[2] * 140
    end
    local nextObjectId = GetNextObjectId()
    g_PureDrawAirdropCrateIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", crateName, "LuckyUnitCrateSeed",
        team, {
            X = centerX + column,
            Y = centerY + row,
            Z = centerZ,
        }, 0)
    local crate = GetObjectByScriptName(crateName)
    if ObjectIsAlive(crate) then
        local actualId = ObjectGetId(crate)
        g_PureDrawAirdropCrateIds[actualId] = true
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
    g_PureDrawAirdropSerial = g_PureDrawAirdropSerial + 1

    local spawnedCount = 0
    -- 先探测中立阵营是否可生成箱子；若中立阵营不可用，则改用双方电脑阵营，
    -- 保证空投箱子必定能实际落地（两侧玩家与双方电脑均为友军，均可拾取）。
    if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, 1,
            "PlyrNeutral/teamPlyrNeutral", centerX, centerY, centerZ) then
        spawnedCount = 1
        for i = 2, 10, 1 do
            if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, i,
                    "PlyrNeutral/teamPlyrNeutral", centerX, centerY, centerZ) then
                spawnedCount = spawnedCount + 1
            end
        end
    else
        for i = 1, 10, 1 do
            local team = "PlyrCivilian/teamPlyrCivilian"
            if i > 5 then
                team = "PlyrCreeps/teamPlyrCreeps"
            end
            if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, i, team,
                    centerX, centerY, centerZ) then
                spawnedCount = spawnedCount + 1
            end
        end
    end
    if spawnedCount > 0 then
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

function PureDrawRoundCheck()
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
SchedulerModule.call_every_x_frame(PureDrawRoundCheck, 15, nil)
