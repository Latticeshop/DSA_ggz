if g_EnableShrinkMode == 1 then
    ShrinkMode_Apply()
end

-- LandArmySpawn 生成并混编完本回合单位后，在与缩小模式相同的时机按玩家单位池配额施加符文。
if g_EnableHextechRune == 1 and HextechRune ~= nil then
    HextechRune:ApplyRoundEffects(exCounterGetByName("lvc"))
end

-- 载具装填：与上面两者同属"混编完成之后"的统一处理点。机制、时序与约束见
-- DSA_ggz/analysis/地图注释说明文档.md §1.1。改完 PassengerLoadSpawn.lua 或本文件要跑
-- analysis/merge_passenger_spawn_payload.py 重新合并，别用 sync_lua_to_json.py。
if g_PLSpawnExecute ~= nil then
    local loadRound = exCounterGetByName("lvc")
    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(g_PLSpawnExecute, 30, { loadRound })
    else
        g_PLSpawnExecute(loadRound)
    end
end
