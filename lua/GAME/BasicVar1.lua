-- 讲解见 analysis/地图注释说明文档.md 附录 A.72、A.91

g_PlayerDebtCount = {
    ["Player_1"] = 0,
    ["Player_2"] = 0,
    ["Player_3"] = 0,
    ["Player_4"] = 0,
    ["Player_5"] = 0,
    ["Player_6"] = 0,
}

g_PlayerInDebt = {
    ["Player_1"] = 0,
    ["Player_2"] = 0,
    ["Player_3"] = 0,
    ["Player_4"] = 0,
    ["Player_5"] = 0,
    ["Player_6"] = 0,
}

g_PlayerNameToIndex = {
    ["Player_1"] = 1,
    ["Player_2"] = 2,
    ["Player_3"] = 3,
    ["Player_4"] = 4,
    ["Player_5"] = 5,
    ["Player_6"] = 6,
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
