-- 讲解见 analysis/地图注释说明文档.md 附录 A.16；神州前哨站的生成与落点见附录 A.51

-- 科技、海三塔等外部脚本可能重新开放生产按钮；开放后立即重新套用余额状态。
function PureDrawReapplyPlayerQuota(playerIndex)
    if g_DrawMode ~= 2 then
        return
    end
    PureDrawSetPlayerBuildability(playerIndex, (g_PureDrawQuota[playerIndex] or 0) > 0)
end

function PureLuckyCrateMode_Setting()
    if g_PureDrawInitialized then
        return
    end
    g_PureDrawInitialized = true
    PureDrawRegisterRoundBeginRefresh()
    PureDrawInitializeKnownPlayerUnits()
    TryEnableLuckyCrateIfAllowed()
    -- 问题4：清除玩家开局自带的船厂（地图初始建筑），只保留玩家自己建造的
    -- 生产建筑，确保生产余额只由玩家自造建筑的生产序列消耗。
    if g_PureDrawNavalYardFilter == nil then
        g_PureDrawNavalYardFilter = CreateObjectFilter({
            Rule = "ANY",
            IncludeThing = {
                "AlliedNavalYard", "SovietNavalYard", "JapanNavalYard", "CelestialNavalYard"
            }
        })
    end
    local yards, yardCount = ObjectFindObjects(nil, nil, g_PureDrawNavalYardFilter)
    for yardIndex = 1, yardCount, 1 do
        local yardOwner = ObjectPlayerScriptName(yards[yardIndex])
        if g_PlayerNameToIndex[yardOwner] ~= nil then
            ExecuteAction("NAMED_DELETE", yards[yardIndex])
        end
    end
    for playerIndex = 1, 8, 1 do
        PureDrawRefreshQuota(playerIndex)
    end
    SchedulerModule.delay_call(PureDrawBackupSpawnTransports, 5, {})
    SchedulerModule.delay_call(PureDrawAirdropCheck, g_PureDrawConfig.AirdropCheckFrames, {})
end

SchedulerModule.delay_call(function()
    local crateFilter = CreateObjectFilter({ IncludeThing = { "GenericCrateSpawner" } })
    local units, count = ObjectFindObjects(nil, nil, crateFilter)
    if count <= 0 then
        -- 未检测到随机箱子：抽卡与海克斯都保留初始化的“不启用”。
        return
    end
    for j = 1, count, 1 do
        -- 先禁用抽卡技能（后面可以启用）
        ExecuteAction("NAMED_DELETE", units[j])
    end
    -- 此外假如检测到随机宝箱，就默认启用旧抽卡模式。
    if g_DrawMode == nil or g_DrawMode == 0 then
        g_DrawMode = 1
        g_LuckyCrateMode = 1
    end
    if not g_HextechCountManuallySet then
        g_HextechCount = 3
        if BtnChoiceDialogEventFunc_ApplyHostHextechSetting ~= nil then
            BtnChoiceDialogEventFunc_ApplyHostHextechSetting()
        end
    end
end, 1, {})
SchedulerModule.delay_call(function()
    local crateFilter = CreateObjectFilter({
        IncludeThing = {
            "GenericCrateSpawner",
            "UnitCrateNew",
            "ShroudCrate",
            "MoneyCrateMP",
        }
    })
    local units, count = ObjectFindObjects(nil, nil, crateFilter)
    for j = 1, count, 1 do
        ExecuteAction("NAMED_DELETE", units[j])
    end
end, 45, {})

-- ===== 神州前哨站：开局按 waypoint 生成（归玩家 + 无敌），落点也按 waypoint 算 =====
-- 开局（任何模式）每点生成一座归玩家的无敌前哨站；落点直接读点位坐标，建筑没了也不影响。
g_CelestialOutpostAnchors = {
    [7] = { "outpost71", "outpost72" },
    [8] = { "outpost81", "outpost82" },
}
-- 点位 → 半场（7 恶魔 / 8 天使），决定落点 Y 偏移往哪边加，别把单位顶出地图边。
g_CelestialOutpostAnchorSide = {
    outpost71 = 7, outpost72 = 7,
    outpost81 = 8, outpost82 = 8,
}
-- 点位归属者座位号
g_CelestialOutpostOwnerSeat = g_CelestialOutpostOwnerSeat or {}
g_CelestialOutpostSpawned = false
g_CelestialOutpostSpawnAttempts = 0

function PureDrawOutpostSideIndex(sideName)
    if sideName == "PlyrCivilian" then
        return 7
    end
    if sideName == "PlyrCreeps" then
        return 8
    end
    return nil
end

function PureDrawRandomIndex(total)
    if total <= 1 then
        return 1
    end
    local index = ceil(GetRandomNumber() * total)
    if index < 1 then
        index = 1
    end
    if index > total then
        index = total
    end
    return index
end

-- 半场 → 该侧随机一名还活着的座位（P[] 是地图上的 P1..P8 锚点，空槽为 nil，见 UNITCOUNTERINI_0.lua）。
function PureDrawPickAliveSideSeat(sideIndex)
    local seats = nil
    if g_SideSeatsOf ~= nil then
        seats = g_SideSeatsOf(sideIndex)
    end
    if seats == nil then
        return nil
    end
    local alive = {}
    for i = 1, getn(seats), 1 do
        local seat = seats[i]
        if seat ~= nil and P ~= nil and P[seat] ~= nil
            and ObjectIsAlive(P[seat]) then
            tinsert(alive, seat)
        end
    end
    if getn(alive) == 0 then
        return nil
    end
    return alive[PureDrawRandomIndex(getn(alive))]
end

-- 在点位生成一座归该座位的前哨站并挂无敌。名字带点位名，重复执行不会叠建筑。
function PureDrawSpawnCelestialOutpost(anchorName, seat)
    local name = "CelestialOutpost_" .. anchorName
    local teamName = format("Player_%d/teamPlayer_%d", seat, seat)
    ExecuteAction("NAMED_DELETE", name)
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", name, "CelestialOutpost",
        teamName, anchorName)
    local outpost = GetObjectByScriptName(name)
    if outpost == nil then
        return nil
    end
    ExecuteAction("UNIT_AFFECT_OBJECT_PANEL_FLAGS", outpost, "Indestructible", true)
    g_CelestialOutpostOwnerSeat[anchorName] = seat
    return outpost
end

function PureDrawSpawnSideCelestialOutposts(sideIndex, seat)
    local anchors = g_CelestialOutpostAnchors[sideIndex]
    if anchors == nil or seat == nil then
        return
    end
    for i = 1, getn(anchors), 1 do
        PureDrawSpawnCelestialOutpost(anchors[i], seat)
    end
end

-- 开局探一次：P[] / 阵营表没就绪就下一拍再来（最多 60 次 × 15 帧 = 60 秒）。
function PureDrawCelestialOutpostBootstrap()
    if g_CelestialOutpostSpawned then
        return
    end
    g_CelestialOutpostSpawnAttempts = g_CelestialOutpostSpawnAttempts + 1
    PureDrawUpdateMapCenterY()
    local demonSeat = PureDrawPickAliveSideSeat(7)
    local angelSeat = PureDrawPickAliveSideSeat(8)
    if demonSeat ~= nil or angelSeat ~= nil then
        g_CelestialOutpostSpawned = true
        PureDrawSpawnSideCelestialOutposts(7, demonSeat)
        PureDrawSpawnSideCelestialOutposts(8, angelSeat)
        return
    end
    if g_CelestialOutpostSpawnAttempts < 60 then
        SchedulerModule.delay_call(PureDrawCelestialOutpostBootstrap, 15, {})
    end
end

SchedulerModule.delay_call(PureDrawCelestialOutpostBootstrap, 15, {})

-- 全场席位的平均 Y ≈ 地图中心那条横线；落点用它决定 Y 偏移往哪边加（地图上下是窄边）。
g_CelestialOutpostCenterY = g_CelestialOutpostCenterY or false

function PureDrawUpdateMapCenterY()
    if g_CelestialOutpostCenterY ~= false or P == nil then
        return
    end
    local total, sum = 0, 0
    for seat = 1, 8, 1 do
        if P[seat] ~= nil and ObjectIsAlive(P[seat]) then
            local px, py, pz = ObjectGetPosition(P[seat])
            if py ~= nil then
                sum = sum + py
                total = total + 1
            end
        end
    end
    if total > 0 then
        g_CelestialOutpostCenterY = sum / total
    end
end

-- 中央战场外围落点（MCV 符文 + 箱子被扔进中央战场的惩罚共用）：
function PureDrawGetOutpostDropPosition(sideName, playerIndex)
    local sideIndex = PureDrawOutpostSideIndex(sideName)
    local anchors = {}
    for anchorSide = 7, 8, 1 do
        if sideIndex == nil or anchorSide == sideIndex then
            local list = g_CelestialOutpostAnchors[anchorSide]
            if list ~= nil then
                for i = 1, getn(list), 1 do
                    tinsert(anchors, list[i])
                end
            end
        end
    end
    if getn(anchors) == 0 then
        return nil
    end
    -- 随机起点，点位名写错 / 该点位取不到坐标时顺次换下一个，全都不行才返回 nil。
    local total = getn(anchors)
    local index = PureDrawRandomIndex(total)
    local position = nil
    for i = 1, total, 1 do
        if index > total then
            index = 1
        end
        position = exWaypointGetPos(anchors[index])
        if position ~= nil then
            break
        end
        index = index + 1
    end
    if position == nil then
        return nil
    end
    local anchorName = anchors[index]
    local RandomInRange = function(min, max)
        local sign = 1
        if GetRandomNumber() < 0.5 then
            sign = -1
        end
        return (min + (GetRandomNumber() * (max - min))) * sign
    end
    local offsetX = RandomInRange(50, 200)
    local offsetY = RandomInRange(50, 150)
    -- 偏移一律朝地图内侧加：点位贴边时往边界方向加会把单位顶出地图。
    -- 中心 Y 由席位平均 Y 估（见 PureDrawUpdateMapCenterY），估不出来就按半场老规则。
    local centerY = g_CelestialOutpostCenterY
    if centerY ~= false then
        if position[2] > centerY then
            offsetY = offsetY < 0 and offsetY or -offsetY
        else
            offsetY = offsetY > 0 and offsetY or -offsetY
        end
    else
        local anchorSideIndex = g_CelestialOutpostAnchorSide[anchorName]
        if anchorSideIndex == 8 then
            offsetY = offsetY < 0 and -offsetY or offsetY
        elseif anchorSideIndex == 7 then
            offsetY = offsetY > 0 and -offsetY or offsetY
        end
    end
    return { X = position[1] + offsetX, Y = position[2] + offsetY,
        Z = position[3] }
end

-- 检测箱子是否被扔到中央战场
function NoCreatesInCenter(id)
    if not ObjectIsAlive(id) then
        return
    end
    if g_PureDrawAirdropCrateIds[id] then
        return
    end
    local crate = GetObjectById(id)
    local isCrateInCenter = false
    if EvaluateCondition("NAMED_INSIDE_AREA", crate, "SHOW7")
        and EvaluateCondition("NAMED_INSIDE_AREA", crate, "SHOW8") then
        -- SHOW7 SHOW8 这两个区域都包含中央战场
        -- 所以假如单位处于中央战场，就会同时处于这两个区域内
        isCrateInCenter = true
    end
    if not isCrateInCenter then
        -- 不在中间就没事
        return
    end
    -- 寻找一个合法的位置（与 MCV 符文共用同一套前哨站落点口径）
    local position = PureDrawGetOutpostDropPosition()
    if position == nil then
        return
    end
    ObjectSetPosition(crate, position.X, position.Y, position.Z)
    -- 玩家箱子被中央战场规则搬移后，立即同步其固定匹配坐标。
    local trackedState = g_PureDrawTrackedCrates[id]
    if trackedState ~= nil then
        trackedState.X = position.X
        trackedState.Y = position.Y
        trackedState.Z = position.Z
    end
    -- 发送警告
    ExecuteAction("OBJECT_CREATE_RADAR_EVENT", crate, "Information")
    if g_LastWarningFrame ~= nil and g_LastWarningFrame + 30 > GetFrame() then
        -- 一段时间内只提示一次
    else
        g_LastWarningFrame = GetFrame()
        exMessageAppendToMessageArea(Localization.get("error.crate_in_battlefield"))
    end
end

g_AIBannedTypes = {
    "CelestialTransportUAV", -- 迅雷运输艇
}
g_AppendTargetNames(g_AIBannedTypes, "Transport")
g_PureDrawReservedTransportIds = {}
g_PureDrawReservedTransportFilter = nil
g_PureDrawReservedTransportType = "JapanLightTransportVehicle"

function PureDrawBackupSpawnTransports()
    -- 等待开局动画结束（cam4 设置 start 计时器 = 玩家可操作），此时出生点占位单位已创建。
    local start = exCounterGetByName("start")
    if start == nil or start <= 0 then
        SchedulerModule.delay_call(PureDrawBackupSpawnTransports, 30, {})
        return
    end
    if g_PureDrawReservedTransportFilter == nil then
        g_PureDrawReservedTransportFilter = CreateObjectFilter({
            Rule = "ANY",
            IncludeThing = { g_PureDrawReservedTransportType }
        })
    end
    local units, count = ObjectFindObjects(nil, nil, g_PureDrawReservedTransportFilter)
    for i = 1, count, 1 do
        local unit = units[i]
        if ObjectIsAlive(unit) then
            g_PureDrawReservedTransportIds[ObjectGetId(unit)] = true
        end
    end
    SchedulerModule.delay_call(NoMCVInCenter, 30, {})
end

function IsPureDrawReservedTransport(unit)
    if unit == nil then
        return false
    end
    return g_PureDrawReservedTransportIds[ObjectGetId(unit)] == true
end

g_DragonShipSkillTeamNames = {
    ["PlyrCivilian/ATTACK"] = true,
    ["PlyrCreeps/ATTACK"] = true,
    ["ATTACK"] = true,
}

function IsSkillDragonShip(unit)
    if unit == nil then
        return false
    end
    local teamName = ObjectTeamName(unit)
    return g_DragonShipSkillTeamNames[teamName] == true
end

function NoMCVInCenter()
    -- 检测 MCV（包括青龙核心舰）
    local mcvFilter = CreateObjectFilter({
        Rule = "ANY",
        IncludeThing = g_MCVTypes
    })
    local mcvs, mcvCount = ObjectFindObjects(nil, nil, mcvFilter)
    for i = 1, mcvCount, 1 do
        local mcv = mcvs[i]
        if ObjectIsAlive(mcv) then
            local isMCVInCenter = false
            if EvaluateCondition("NAMED_INSIDE_AREA", mcv, "SHOW7")
                and EvaluateCondition("NAMED_INSIDE_AREA", mcv, "SHOW8") then
                isMCVInCenter = true
            end
            if isMCVInCenter then
                local ownerPlayerName = ObjectPlayerScriptName(mcv)
                local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
                if playerIndex == nil and not IsSkillDragonShip(mcv) then
                    -- 非技能召唤的 AI MCV → 击杀
                    ExecuteAction("NAMED_KILL", mcv)
                end
            end
        end
    end
    
    -- 检测 AI 的迅雷运输艇等禁用单位（任何位置都击杀）。
    -- 排除开局备份的出生点占位迅雷车（用于模拟出兵，见 PureDrawBackupSpawnTransports）。
    local bannedFilter = CreateObjectFilter({
        Rule = "ANY",
        IncludeThing = g_AIBannedTypes
    })
    local bannedUnits, bannedCount = ObjectFindObjects(nil, nil, bannedFilter)
    for i = 1, bannedCount, 1 do
        local unit = bannedUnits[i]
        if ObjectIsAlive(unit) then
            if IsPureDrawReservedTransport(unit) then
                -- 出生点占位迅雷车：保留，用于模拟出兵
            else
                local ownerPlayerName = ObjectPlayerScriptName(unit)
                local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
                if playerIndex == nil then
                    -- AI 的禁用单位（空投/抽卡开出的多余迅雷车等）：直接击杀
                    ExecuteAction("NAMED_KILL", unit)
                end
            end
        end
    end
    
    SchedulerModule.delay_call(NoMCVInCenter, 30, {})
end

RegisterUnitCreateCallback("LuckyUnitCrateSeed", PureDrawOnCrateSeedBorn)
RegisterUnitCreateCallback("UnitCrateNew", PureDrawOnPhysicalCrateBorn)
RegisterUnitCreateCallback("UnitCrate", PureDrawOnPhysicalCrateBorn)

-- 监听玩家碰箱子后生成的已知原生单位，用于替换为自定义抽卡单位。
-- AI 空投入队不使用这些类型表，由 04_draw 的事件与短时扫描独立处理。
g_PureDrawRegisteredNativeCrateHashes = {}
for crateType = 1, 4, 1 do
    local source = g_CrateUnitsTemplate[crateType]
    for i = 1, getn(source), 1 do
        local unitType = source[i].Type
        local unitHash = FastHash(unitType)
        g_PureDrawObservedPlayerUnitHashes[unitHash] = true
        if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
            RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
            g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
        end
    end
end
for i = 1, getn(g_GroundCrateUnits), 1 do
    local unitType = g_GroundCrateUnits[i]
    local unitHash = FastHash(unitType)
    g_PureDrawObservedPlayerUnitHashes[unitHash] = true
    if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
        g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
    end
end
for i = 1, getn(g_AirCrateUnits), 1 do
    local unitType = g_AirCrateUnits[i]
    local unitHash = FastHash(unitType)
    g_PureDrawObservedPlayerUnitHashes[unitHash] = true
    if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
        g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
    end
end
for i = 1, getn(g_SeaCrateUnits), 1 do
    local unitType = g_SeaCrateUnits[i]
    local unitHash = FastHash(unitType)
    g_PureDrawObservedPlayerUnitHashes[unitHash] = true
    if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
        g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
    end
end
