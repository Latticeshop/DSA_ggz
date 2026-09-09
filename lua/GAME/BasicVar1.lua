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


-- 塔摧毁进度  TODO
g_TowerDestroyProgress = 0;

-- 守护者系统必须在开局初始化。塔毁触发器不能依赖延迟启用的回合清场脚本。
g_TowerGuardianUnitIds = g_TowerGuardianUnitIds or {}

local towerGuardianNames = {
    "overlord7",
    "overlord8",
    "t533",
    "t534",
}

function RegisterTowerGuardian(unit)
    if ObjectIsAlive(unit) then
        g_TowerGuardianUnitIds[ObjectGetId(unit)] = 1
    end
end

function IsTowerGuardian(unit)
    return unit ~= nil and g_TowerGuardianUnitIds[ObjectGetId(unit)] ~= nil
end

for i = 1, getn(towerGuardianNames), 1 do
    RegisterTowerGuardian(GetObjectByScriptName(towerGuardianNames[i]))
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

    ExecuteAction("TEAM_MERGE_INTO_TEAM", sourceTeam, attackTeam)
end

function ReplaceTowerGuardian(objectName, objectType, sourceTeam, attackTeam,
    spawnWaypoint, scale, orientation, infoBoxText, isFortress)
    local displayUnit = GetObjectByScriptName(objectName)
    -- 某些模式会主动删除基地展示体，原逻辑在这种情况下也不会释放守护者。
    if not ObjectIsAlive(displayUnit) then
        return
    end
    g_TowerGuardianUnitIds[ObjectGetId(displayUnit)] = nil
    ExecuteAction("NAMED_DELETE", displayUnit)

    -- 延迟一帧，确保同名基地展示体已完全删除后再创建战斗单位。
    SchedulerModule.delay_call(SpawnTowerGuardian, 1, {
        objectName, objectType, sourceTeam, attackTeam,
        spawnWaypoint, scale, orientation, infoBoxText, isFortress
    })
end
