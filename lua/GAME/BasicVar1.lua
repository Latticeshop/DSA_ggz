-- 讲解见 analysis/地图注释说明文档.md 附录 A.72、A.91

-- ===== 4v4（8 席）人数口径：6 人时代散落各处的硬编码，集中记在这里 =====
-- 座位号 seatIndex = 1..8；阵营号 sideIndex 沿用地图两方 AI 队：
--   7 = PlyrCivilian（恶魔，下方）/ 8 = PlyrCreeps（天使，上方）。
-- 44 图实际编队（按地图坐标从左到右核对过）：
--   下方恶魔 = Player_1, Player_2, Player_8, Player_3
--   上方天使 = Player_4, Player_5, Player_7, Player_6
-- 这样 6 人局（1/2/3 vs 4/5/6）自动退化成旧 3v3，7/8 号进局才变成 4v4。
-- 关键：座位号不再连续，判侧必须查表，禁止再用 seatIndex > g_SideSize 之类的区间比较。
g_PlayerCount = 8
g_SideSize = 4
g_SideSeats = {
    [7] = { 1, 2, 8, 3 },
    [8] = { 4, 5, 7, 6 },
}
g_Seat7 = { 1, 2, 8, 3 }
g_Seat8 = { 4, 5, 7, 6 }

g_SeatSideTable = {
    [1] = 7,
    [2] = 7,
    [3] = 7,
    [8] = 7,
    [4] = 8,
    [5] = 8,
    [6] = 8,
    [7] = 8,
}

-- 座位 → 阵营号（7 恶魔 / 8 天使）
function g_SeatToSide(seatIndex)
    if seatIndex == nil then
        return nil
    end
    return g_SeatSideTable[seatIndex]
end

-- 判侧便捷函数（替代 g_IsDevilSeat(playerIndex) / >= 5 这类区间比较）
function g_IsDevilSeat(seatIndex)
    return g_SeatSideTable[seatIndex] == 7
end

function g_IsAngelSeat(seatIndex)
    return g_SeatSideTable[seatIndex] == 8
end

-- 阵营号 → 该边座位列表（按左→右顺序）
function g_SideSeatsOf(sideIndex)
    return g_SideSeats[sideIndex]
end

-- 阵营号 → 本边第一个座位号（7 → 1，8 → 4）
function g_SideFirstSeat(sideIndex)
    local seats = g_SideSeats[sideIndex]
    if seats == nil then
        return nil
    end
    return seats[1]
end

-- 同侧第 n 人 ↔ 对面第 n 人（按各自阵营内的序号对齐）
function g_OpponentSeat(seatIndex)
    local side = g_SeatSideTable[seatIndex]
    if side == nil then
        return nil
    end
    local mine = g_SideSeats[side]
    local other = g_SideSeats[8]
    if side == 8 then
        other = g_SideSeats[7]
    end
    for n = 1, g_SideSize, 1 do
        if mine[n] == seatIndex then
            return other[n]
        end
    end
    return nil
end

-- 席位锚点（P1..P8 就是各席 MCV，7/8 号也已由地图补好）
function g_GetSeatAnchor(seatIndex)
    return GetObjectByScriptName("P" .. seatIndex)
end

-- 数据源是房间里玩家自选的队色：exPlayerGetColor("Player_N") → {0~255 的 R, G, B}。
-- 解析成几何量；取不到返回 nil。
function g_PlayerColorInfo(seatIndex)
    local color = exPlayerGetColor("Player_" .. seatIndex)
    if color == nil or type(color[1]) ~= "number" or type(color[2]) ~= "number" or type(color[3]) ~= "number" then
        return nil
    end
    local red = color[1] / 255
    local green = color[2] / 255
    local blue = color[3] / 255
    local maxValue = max(red, green, blue)
    local minValue = min(red, green, blue)
    local info = {
        Max = maxValue,
        Min = minValue,
        Light = (maxValue + minValue) / 2,
        Span = maxValue - minValue,
        Hue = 0,
    }
    local span = info.Span
    if span > 0 then
        local hue = 0
        if maxValue == red then
            hue = (green - blue) / span
        elseif maxValue == green then
            hue = (blue - red) / span + 2
        else
            hue = (red - green) / span + 4
        end
        if hue < 0 then
            hue = hue + 6
        end
        info.Hue = hue * 60
    end
    return info
end

-- 分档键（绿不细分，绿/浅绿由 g_PlayerColorName 按同场比较决定）
function g_PlayerColorBucket(info)
    if info == nil then
        return nil
    end
    if info.Light < 0.1 then
        return "color.black"
    elseif info.Light > 0.95 then
        return "color.white"
    elseif info.Span == 0 then
        return "color.gray"
    end
    local saturation = 0
    if info.Light > 0.5 then
        saturation = info.Span / (2 - info.Max - info.Min)
    else
        saturation = info.Span / (info.Max + info.Min)
    end
    if saturation < 0.1 then
        return "color.gray"
    end
    local hue = info.Hue
    if hue < 12 or hue >= 345 then
        return "color.red"
    elseif hue < 42 then
        return "color.orange"
    elseif hue < 70 then
        return "color.yellow"
    elseif hue < 160 then
        return "color.green"
    elseif hue < 200 then
        return "color.cyan"
    elseif hue < 260 then
        return "color.blue"
    elseif hue < 300 then
        return "color.purple"
    end
    return "color.pink"
end

-- 绿 / 浅绿：用实测到的引擎真实 RGB 定标（不是截图取样值）。
-- 实测 8 人：绿色 (20,105,60) → max 0.412、浅绿 (144,186,106) → max 0.729；
-- 两者彩度几乎一样（0.333 / 0.314），所以只能按「最亮通道」分：界线 0.57，两侧各余 0.158。
-- 其余颜色实测：(225,115,20) 橙 / (232,120,173) 粉 / (50,75,200) 蓝 / (102,207,248) 青 /
-- (230,20,20) 红 / (237,231,47) 黄，全部落在对应色相档里。
function g_PlayerColorName(seatIndex)
    local info = g_PlayerColorInfo(seatIndex)
    local bucket = g_PlayerColorBucket(info)
    if bucket == nil then
        return nil
    end
    if bucket == "color.green" and info.Max >= 0.57 then
        return Localization.get("color.light_green")
    end
    return Localization.get(bucket)
end

-- ===== 4v4：中间 AI 阵营（7=PlyrCivilian / 8=PlyrCreeps）的扫描锚点 =====
-- 注意：P[1..8] 是「座位」的 MCV 锚点，绝不能再拿 P[7]/P[8] 当阵营锚点用，
-- 否则 SAME_PLAYER 过滤会扫到 Player_7 / Player_8 自己的部队。
g_SideAnchorName = {
    [7] = "PlyrCivilian",
    [8] = "PlyrCreeps"
}
g_SideScanAnchor = {}
g_FilterSideAnchor = CreateObjectFilter({
    Rule = "ANY",
    Include = "SELECTABLE"
})

function g_GetSideScanAnchor(sideIndex)
    local anchor = g_SideScanAnchor[sideIndex]
    if anchor ~= nil and ObjectIsAlive(anchor) then
        return anchor
    end
    if sideIndex == 8 then
        anchor = GetObjectByScriptName("T84")
    else
        anchor = GetObjectByScriptName("T74")
    end
    if anchor ~= nil and ObjectIsAlive(anchor)
        and ObjectPlayerScriptName(anchor) == g_SideAnchorName[sideIndex] then
        g_SideScanAnchor[sideIndex] = anchor
        return anchor
    end
    local list, count = ObjectFindObjects(nil, nil, g_FilterSideAnchor)
    if list ~= nil then
        for i = 1, count, 1 do
            if ObjectIsAlive(list[i])
                and ObjectPlayerScriptName(list[i]) == g_SideAnchorName[sideIndex] then
                g_SideScanAnchor[sideIndex] = list[i]
                return list[i]
            end
        end
    end
    return nil
end

-- 阵营号安全的 ObjectFindObjects：7/8 走阵营锚点；其余编号沿用原 P[n] 座位锚点。
-- 阵营锚点缺失（塔被清、中间 AI 名下暂时没有任何可选对象）时，退到本方 4 个座位锚点
-- 逐个扫描并合并，避免整片阵营扫描直接返回空导致符文静默失效。
function g_SideFindObjectsAppend(result, seen, list, count)
    if list == nil then
        return
    end
    if type(count) ~= "number" then
        count = getn(list)
    end
    for i = 1, count, 1 do
        local object = list[i]
        if object ~= nil then
            local objectId = ObjectGetId(object)
            if objectId ~= nil and seen[objectId] == nil then
                seen[objectId] = true
                tinsert(result, object)
            end
        end
    end
end

function g_SideFindObjects(sideIndex, pos, filter)
    local anchor = nil
    if sideIndex == 7 or sideIndex == 8 then
        anchor = g_GetSideScanAnchor(sideIndex)
        if anchor ~= nil then
            local list, count = ObjectFindObjects(anchor, pos, filter)
            if list == nil then
                list = {}
            end
            if type(count) ~= "number" then
                count = getn(list)
            end
            return list, count
        end
        local seats = g_Seat7
        if sideIndex == 8 then
            seats = g_Seat8
        end
        local result = {}
        local seen = {}
        for i = 1, getn(seats), 1 do
            local seatAnchor = g_GetSeatAnchor(seats[i])
            if seatAnchor ~= nil and ObjectIsAlive(seatAnchor) then
                local list, count = ObjectFindObjects(seatAnchor, pos, filter)
                g_SideFindObjectsAppend(result, seen, list, count)
            end
        end
        return result, getn(result)
    end
    anchor = P[sideIndex]
    if anchor == nil then
        return {}, 0
    end
    local list, count = ObjectFindObjects(anchor, pos, filter)
    if list == nil then
        list = {}
    end
    if type(count) ~= "number" then
        count = getn(list)
    end
    return list, count
end

function g_IsAISideUnit(unit)
    if unit == nil then
        return 0
    end
    local ownerName = ObjectPlayerScriptName(unit)
    if ownerName == "PlyrCivilian" or ownerName == "PlyrCreeps" then
        return 1
    end
    return 0
end

-- 兜底防线：只允许把中间 AI 阵营自己的单位换进 AI 队伍，玩家单位一律不动。
function g_SetSideTeam(unit, teamName)
    if teamName ~= nil and g_IsAISideUnit(unit) == 1 then
        ExecuteAction("UNIT_SET_TEAM", unit, teamName)
    end
end

g_PlayerDebtCount = {
    ["Player_1"] = 0,
    ["Player_2"] = 0,
    ["Player_3"] = 0,
    ["Player_4"] = 0,
    ["Player_5"] = 0,
    ["Player_6"] = 0,
    ["Player_7"] = 0,
    ["Player_8"] = 0,
}

g_PlayerInDebt = {
    ["Player_1"] = 0,
    ["Player_2"] = 0,
    ["Player_3"] = 0,
    ["Player_4"] = 0,
    ["Player_5"] = 0,
    ["Player_6"] = 0,
    ["Player_7"] = 0,
    ["Player_8"] = 0,
}

g_PlayerNameToIndex = {
    ["Player_1"] = 1,
    ["Player_2"] = 2,
    ["Player_3"] = 3,
    ["Player_4"] = 4,
    ["Player_5"] = 5,
    ["Player_6"] = 6,
    ["Player_7"] = 7,
    ["Player_8"] = 8,
}

g_TargetGroupNames = g_TargetGroupNames or {}

-- 防御塔本体七种（九头蛇/冰天雪地/超时空传送落点的排除口径）。
g_TargetGroupNames.DefenseTower = {
    "CelestialBaseDefenseAdvanced",
    "CelestialBaseDefenseAdvanced_NoCore",
    "CelestialBaseDefenseAir",
    "CelestialEnergyGatlingTower",
    "AlliedHeavyArtilleryDefenseBase",
    "SovietBaseDefenseAdvanced",
    "JapanBaseDefenseAdvanced",
}

-- 帝国轻运兵车三形态（载员、清场、转化的排除口径）。
g_TargetGroupNames.Transport = {
    "JapanLightTransportVehicle",
    "JapanLightTransportVehicle_AntiTank",
    "JapanLightTransportVehicle_Kamikaze",
}

-- 三阵营各四形态 + 青龙战斗核心舰（龙船）八形态，共 20。
g_TargetGroupNames.MCV = {
    "AlliedMCV", "AlliedMCV_Enhanced", "AlliedMCV_Naval", "AlliedMCV_Enhanced_Naval",
    "SovietMCV", "SovietMCV_Enhanced", "SovietMCV_Naval", "SovietMCV_Enhanced_Naval",
    "JapanMCV", "JapanMCV_Enhanced", "JapanMCV_Naval", "JapanMCV_Enhanced_Naval",
    "CelestialMCV", "CelestialMCV_Enhanced", "CelestialMCV_Ground", "CelestialMCV_Naval",
    "CelestialMCV_Air", "CelestialMCV_Enhanced_Ground", "CelestialMCV_Enhanced_Naval",
    "CelestialMCV_Enhanced_Air",
}

-- 青龙战斗核心舰（MCV 的青龙子集；龙行天下技能召唤的也是这一族）。
g_TargetGroupNames.DragonShip = {
    "CelestialMCV", "CelestialMCV_Enhanced", "CelestialMCV_Ground", "CelestialMCV_Naval",
    "CelestialMCV_Air", "CelestialMCV_Enhanced_Ground", "CelestialMCV_Enhanced_Naval",
    "CelestialMCV_Enhanced_Air",
}

-- 地编直接摆放在双方基地的 AI 阵营锚点 MCV（其它阵营的 MCV 不在此列）。
g_TargetGroupNames.AIAnchorMCV = { "AlliedMCV" }

-- 夜莺：旧代码按特殊释放载体特例排除，保持原口径。
g_TargetGroupNames.Nightingale = { "AlliedNightinaleHelicopter" }

-- 六个预设守护神：塔掉落后召唤，脚本名固定（4 个塔守护者 + 2 个海塔守卫）。
g_TargetGroupNames.PresetGuardian = {
    "overlord7", "overlord8", "t533", "t534",
    "Sea3ProtectShip7", "Sea3ProtectShip8",
}

-- 守护神的旧模板名口径：仅超时空传送落点仍按模板排除；
-- 达摩剑已改为抽取时按 g_IsPresetGuardianUnit 判定，普通 Overlordtank /
-- JapanFortressShip 重新成为合法目标。
g_TargetGroupNames.GuardianFormTemplate = {
    "Overlordtank", "JapanFortressShip", "JapanigaFortressShip",
}

-- 兵种双形态：转化符文按出生点归兵种（天狗/VX/心神/火箭天使算空军）。
g_TargetGroupNames.DualFormVehicleAir = {
    "JapanAntiInfantryVehicle",
    "JapanAntiInfantryVehicle_Enhanced",
    "JapanAntiInfantryVehicle_Enhanced_Water",
    "JapanAntiAirVehicleTech1",
    "JapanAntiAirVehicleTech1_Enhanced",
    "JapanAntiAirVehicleTech1_Enhanced_Water",
    "JapanMissileMechaAdvanced",
    "JapanMissileMechaAdvanced_Enhanced",
    "JapanMissileMechaAdvanced_Enhanced_Water",
}
g_TargetGroupNames.DualFormAirNavy = {
    "JapanAntiAirShip", "JapanAntiAirShip_Enhanced",
    "JapanFortressShip", "JapanGigaFortress_Land",
}
g_TargetGroupNames.DualFormInfantryAir = {
    "JapanAntiVehicleInfantryTech3",
}

-- 无限火力开放的六族对空战斗机（基础型）及其全部形态。
g_TargetGroupNames.AmmoAircraftFamily = {
    "AlliedFighterAircraft", "AlliedInterceptorAircraft",
    "CelestialFighterAircraft", "CelestialInterceptorAircraft",
    "SovietFighterAircraft", "SovietInterceptorAircraft",
}
g_TargetGroupNames.InfiniteAmmoAircraft = {
    "AlliedFighterAircraft", "AlliedFighterAircraft_Enhanced",
    "AlliedFighterAircraft_WithTrailSomke",
    "AlliedInterceptorAircraft", "AlliedInterceptorAircraft_Enhanced",
    "CelestialFighterAircraft",
    "CelestialFighterAircraft_WithBlueTrailSomke",
    "CelestialFighterAircraft_WithRedTrailSomke",
    "CelestialFighterAircraft_WithTrailSomke",
    "CelestialFighterAircraft_WithWhiteTrailSomke",
    "CelestialInterceptorAircraft", "CelestialInterceptorAircraft_Enhanced",
    "SovietFighterAircraft", "SovietFighterAircraft_Enhanced",
    "SovietInterceptorAircraft", "SovietInterceptorAircraft_Enhanced",
}

function g_AppendTargetNames(dest, groupName)
    local names = g_TargetGroupNames[groupName]
    if names == nil then
        return dest
    end
    for i = 1, getn(names), 1 do
        tinsert(dest, names[i])
    end
    return dest
end

function g_CollectTargetNames(groupNames)
    local result = {}
    for i = 1, getn(groupNames), 1 do
        local names = g_TargetGroupNames[groupNames[i]]
        if names ~= nil then
            for j = 1, getn(names), 1 do
                tinsert(result, names[j])
            end
        end
    end
    return result
end

-- PureDraw 的 MCV 检测与其他排除口径统一读这张表。
g_MCVTypes = g_TargetGroupNames.MCV

-- 空军元帅苏霍伊的专用飞行编队。主口径是技能召唤登记（地编脚本生成时登记），
-- BASE 编队与 angel1..8/devil1..8 脚本名是出生回调早于登记时的后备判定。
g_AirMarshalTeamNames = {
    ["BASE"] = true,
    ["PlyrCivilian/BASE"] = true,
    ["PlyrCreeps/BASE"] = true,
}

function IsAirMarshalAircraft(unit)
    if unit == nil then
        return false
    end
    if IsSkillSummonedUnitId ~= nil and IsSkillSummonedUnitId(ObjectGetId(unit)) then
        return true
    end
    if g_AirMarshalTeamNames[ObjectTeamName(unit)] then
        return true
    end
    local unitId = ObjectGetId(unit)
    for i = 1, 8, 1 do
        local angelUnit = GetObjectByScriptName("angel" .. i)
        if angelUnit ~= nil and ObjectGetId(angelUnit) == unitId then
            return true
        end
        local devilUnit = GetObjectByScriptName("devil" .. i)
        if devilUnit ~= nil and ObjectGetId(devilUnit) == unitId then
            return true
        end
    end
    return false
end


g_SkillSummonedUnits = g_SkillSummonedUnits or {}

function RegisterSkillSummonedUnit(unit)
    if unit ~= nil and ObjectIsAlive(unit) then
        g_SkillSummonedUnits[ObjectGetId(unit)] = unit
    end
end

function IsSkillSummonedUnitId(objectId)
    local unit = g_SkillSummonedUnits[objectId]
    if unit == nil then
        return false
    end
    if not ObjectIsAlive(unit) or ObjectGetId(unit) ~= objectId then
        g_SkillSummonedUnits[objectId] = nil
        return false
    end
    return true
end

-- 塔摧毁进度  TODO
g_TowerDestroyProgress = 0;

-- 守护者系统必须在开局初始化。塔毁触发器不能依赖延迟启用的回合清场脚本。
g_TowerGuardianUnitIds = g_TowerGuardianUnitIds or {}

function RegisterTowerGuardian(unit)
    if ObjectIsAlive(unit) then
        g_TowerGuardianUnitIds[ObjectGetId(unit)] = 1
    end
end

function IsTowerGuardian(unit)
    return unit ~= nil and g_TowerGuardianUnitIds[ObjectGetId(unit)] ~= nil
end

-- 删掉/换掉守护者前必须解除登记：引擎会复用对象 id，留下的 id 会让新单位被当成守护者，
function UnregisterTowerGuardian(unit)
    if unit ~= nil and g_TowerGuardianUnitIds ~= nil then
        g_TowerGuardianUnitIds[ObjectGetId(unit)] = nil
    end
end

-- 六个预设守护神统一判定：先查动态登记（塔毁后召唤的），再按固定脚本名兜底
-- （塔未毁时的展示体，以及引擎回收 id 后仍按名字命中的同名单位）。
function g_IsPresetGuardianUnitId(objectId)
    if objectId == nil then
        return false
    end
    if g_TowerGuardianUnitIds ~= nil and g_TowerGuardianUnitIds[objectId] ~= nil then
        return true
    end
    if GetObjectByScriptName == nil then
        return false
    end
    for i = 1, getn(g_TargetGroupNames.PresetGuardian), 1 do
        local preset = GetObjectByScriptName(g_TargetGroupNames.PresetGuardian[i])
        if preset ~= nil and ObjectGetId(preset) == objectId then
            return true
        end
    end
    return false
end

function g_IsPresetGuardianUnit(unit)
    if unit == nil then
        return false
    end
    return g_IsPresetGuardianUnitId(ObjectGetId(unit))
end

-- 海塔守卫要到解锁 T4 舰后才由脚本创建，加载期按名字取不到，只登记已存在的展示体。
for i = 1, getn(g_TargetGroupNames.PresetGuardian), 1 do
    local preset = GetObjectByScriptName(g_TargetGroupNames.PresetGuardian[i])
    if preset ~= nil then
        RegisterTowerGuardian(preset)
    end
end

-- LuaBridge 的全局函数不能捕获外层 local，过滤器也必须放在全局作用域。
g_TowerAreaKillFilter = CreateObjectFilter({
    Relationship="SAME_PLAYER",
    Include="SELECTABLE",
    Exclude="STRUCTURE",
})

function KillPlayerUnitsInAreaExceptTowerGuardians(playerReference, areaName)
    local units, count = ObjectFindObjects(playerReference, nil, g_TowerAreaKillFilter)
    for i = 1, count, 1 do
        if not IsTowerGuardian(units[i])
            and EvaluateCondition("NAMED_INSIDE_AREA", units[i], areaName) then
            ExecuteAction("NAMED_KILL", units[i])
        end
    end
end

function ToggleTowerGuardianFortress(objectName, objectId, state)
    local fortress = GetObjectByScriptName(objectName)
    if ObjectIsAlive(fortress)
        and ObjectGetId(fortress) == objectId
        and IsTowerGuardian(fortress) then
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", objectName,
            "TRANSFORMATION_TOGGLE_STATE", state)
        SchedulerModule.delay_call(ToggleTowerGuardianFortress, 75,
            { objectName, objectId, 1 - state })
    end
end


function SpawnTowerGuardian(objectName, objectType, sourceTeam, attackTeam,
    spawnWaypoint, scale, orientation, infoBoxText, isFortress)
    local position = exWaypointGetPos(spawnWaypoint)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", objectName,
        objectType, sourceTeam,
        { X=position[1], Y=position[2], Z=position[3] + 5 }, orientation)

    local guardian = GetObjectByScriptName(objectName)
    if not ObjectIsAlive(guardian) then
        return
    end

    local guardianId = ObjectGetId(guardian)
    RegisterTowerGuardian(guardian)
    exObjectSetFixedScale(guardianId, scale)
    TextDoActionLocalized("NAMED_SHOW_INFOBOX", objectName, infoBoxText, "0", "")

    if isFortress then
        ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", objectName,
            "Command_ToggleJapanFortressShipTransformMode")
        ExecuteAction("UNIT_CLEAR_MODELCONDITION", objectName, "USER_1")
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", objectName,
            "TRANSFORMATION_TOGGLE_STATE", 0)
        SchedulerModule.delay_call(ToggleTowerGuardianFortress, 75,
            { objectName, guardianId, 1 })
    end

    -- 原本靠地编 ATTACK__7/8 的 TEAM_SET_EXPERIENCE_POINTS("ATTACK", 99999) 满星，
    -- 那条会连带给一切进 ATTACK 队的新单位强行升星，已删除；守护神改为 lua 直接指定 5 星。
    for levelindex = 1, 5, 1 do
        ExecuteAction("UNIT_GAIN_LEVEL", guardian, 1)
    end

    ExecuteAction("TEAM_MERGE_INTO_TEAM", sourceTeam, attackTeam)
end

function ReplaceTowerGuardian(objectName, objectType, sourceTeam, attackTeam,
    spawnWaypoint, scale, orientation, infoBoxText, isFortress)
    local displayUnit = GetObjectByScriptName(objectName)
    -- 某些模式会主动删除基地展示体，原逻辑在这种情况下也不会释放守护者。
    if not ObjectIsAlive(displayUnit) then
        return
    end
    UnregisterTowerGuardian(displayUnit)
    ExecuteAction("NAMED_DELETE", displayUnit)

    -- 延迟一帧，确保同名基地展示体已完全删除后再创建战斗单位。
    SchedulerModule.delay_call(SpawnTowerGuardian, 1, {
        objectName, objectType, sourceTeam, attackTeam,
        spawnWaypoint, scale, orientation, infoBoxText, isFortress
    })
end
