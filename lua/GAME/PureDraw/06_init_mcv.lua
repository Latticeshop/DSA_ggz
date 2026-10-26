-- 讲解见 analysis/地图注释说明文档.md 附录 A.16、A.29、A.43、A.48

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
    for playerIndex = 1, 6, 1 do
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

-- 一座前哨站属于哪一侧：ObjectPlayerScriptName 直接给出 PlyrCivilian / PlyrCreeps 时最省事，
function PureDrawGetOutpostSideName(outpost)
    local ownerName = ObjectPlayerScriptName(outpost)
    if ownerName == "PlyrCivilian" or ownerName == "PlyrCreeps" then
        return ownerName
    end
    local teamName = ObjectTeamName(outpost)
    if teamName ~= nil then
        if strfind(teamName, "PlyrCivilian") ~= nil then
            return "PlyrCivilian"
        end
        if strfind(teamName, "PlyrCreeps") ~= nil then
            return "PlyrCreeps"
        end
    end
    return nil
end

-- 中央战场外围落点：随机一座神州前哨站 + 随机偏移。
function PureDrawGetOutpostDropPosition(sideName, playerIndex)
    if not g_CelestialOutpostsFilter then
        g_CelestialOutpostsFilter = CreateObjectFilter({ IncludeThing = { "CelestialOutpost" } })
    end
    local outposts, count = ObjectFindObjects(nil, nil, g_CelestialOutpostsFilter)
    if count <= 0 then
        return nil
    end
    local candidates = {}
    for i = 1, count, 1 do
        local ownerSide = PureDrawGetOutpostSideName(outposts[i])
        -- 归属认不出的前哨站（玩家槽预设的那些）一律不当落点：它们的坐标不受半场裁剪约束。
        if ownerSide ~= nil and (sideName == nil or ownerSide == sideName) then
            tinsert(candidates, outposts[i])
        end
    end
    if getn(candidates) == 0 then
        if sideName == nil then
            return nil
        end
        local start = exWaypointGetPos(format("Player_%d_Start", playerIndex))
        local bestDistance = nil
        for i = 1, count, 1 do
            local ox, oy = ObjectGetPosition(outposts[i])
            local dx = ox - start[1]
            local dy = oy - start[2]
            local distance = dx * dx + dy * dy
            if bestDistance == nil or distance < bestDistance then
                bestDistance = distance
                candidates[1] = outposts[i]
            end
        end
    end
    local total = getn(candidates)
    if total == 0 then
        return nil
    end
    local index = ceil(GetRandomNumber() * total)
    if index < 1 then
        index = 1
    end
    if index > total then
        index = total
    end
    local outpost = candidates[index]
    local dropSide = sideName
    if dropSide == nil then
        dropSide = PureDrawGetOutpostSideName(outpost)
    end
    local RandomInRange = function(min, max)
        local sign = 1
        if GetRandomNumber() < 0.5 then
            sign = -1
        end
        return (min + (GetRandomNumber() * (max - min))) * sign
    end
    local offsetX = RandomInRange(50, 200)
    local offsetY = RandomInRange(50, 150)
    -- Y 增为上。前哨站太贴地图边角，往一个方向加偏移就会出界，所以按半场各留一个方向：
    if dropSide == "PlyrCreeps" and offsetY < 0 then
        offsetY = -offsetY
    elseif dropSide == "PlyrCivilian" and offsetY > 0 then
        offsetY = -offsetY
    end
    local x, y, z = ObjectGetPosition(outpost)
    return { X = x + offsetX, Y = y + offsetY, Z = z }
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

-- 检测 AI 的 MCV（包括青龙战斗核心舰）是否在中央战场。
-- 玩家青龙核心舰已由生成事件转换为伏龙殿或自动回收；这里仅处理 AI 单位。
-- 模板名单统一取自 BasicVar 的 MCV 群体（g_MCVTypes 也在那里指向同一张表）。
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
    if not g_CelestialOutpostsFilter then
        g_CelestialOutpostsFilter = CreateObjectFilter({ IncludeThing = { "CelestialOutpost" } })
    end
    
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
