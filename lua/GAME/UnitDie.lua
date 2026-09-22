g_UnitDieEventFunc = g_UnitDieEventFunc or {}
g_UnitDieRegisteredTypes = g_UnitDieRegisteredTypes or {}

-- 同一种单位可能同时被多个系统监听死亡事件。统一在这里注册，避免后注册的
-- 回调覆盖原有功能，也避免同一模板被重复交给引擎注册。
function RegisterUnitDieCallback(objectTypeName, callback)
    local instanceId = FastHash(objectTypeName)
    local registered = g_UnitDieEventFunc[instanceId]
    if registered == nil then
        g_UnitDieEventFunc[instanceId] = callback
    elseif type(registered) == "function" then
        if registered ~= callback then
            g_UnitDieEventFunc[instanceId] = { registered, callback }
        end
    else
        local found = false
        for i = 1, getn(registered), 1 do
            if registered[i] == callback then
                found = true
                break
            end
        end
        if not found then
            tinsert(registered, callback)
        end
    end

    if not g_UnitDieRegisteredTypes[instanceId] then
        exObjectRegisterDieEvent(objectTypeName)
        g_UnitDieRegisteredTypes[instanceId] = true
    end
end

CELESTIAL_BATTERY_DIE_MONEY = 700
function CelestialBatteryDie(dyingObjId, attackerId, dyingObjInstanceId, attackerInstanceId, ownerPlayerName)
    if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", GetObjectById(dyingObjId), "UNPACKING") then
        local x, y, z = ObjectGetPosition(GetObjectById(dyingObjId))
        SchedulerModule.delay_call(function(playerName, nx,ny,nz)
            local previous = SetWorldBuilderThisPlayer(1);
            ExecuteAction("PLAYER_GIVE_MONEY", playerName, CELESTIAL_BATTERY_DIE_MONEY)
            exShowTextAtPos(Localization.get("unit_die.money_gained", CELESTIAL_BATTERY_DIE_MONEY), nx, ny, nz, 189465)
            SetWorldBuilderThisPlayer(previous)
        end, 5, {ownerPlayerName, x,y,z})
    end

end

RegisterUnitDieCallback("CelestialBattery", CelestialBatteryDie)

function onUnitDieEvent(dyingObjId, attackerId, dyingObjInstanceId, attackerInstanceId, ownerPlayerName)
    local registered = g_UnitDieEventFunc[dyingObjInstanceId]
    if type(registered) == "function" then
        registered(dyingObjId, attackerId, dyingObjInstanceId,
            attackerInstanceId, ownerPlayerName)
    elseif registered ~= nil then
        for i = 1, getn(registered), 1 do
            registered[i](dyingObjId, attackerId, dyingObjInstanceId,
                attackerInstanceId, ownerPlayerName)
        end
    end
end
