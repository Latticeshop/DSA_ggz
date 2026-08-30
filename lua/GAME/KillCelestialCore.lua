-- 旧版保留脚本，当前地图中不生效。
-- 原用途：每 4 秒搜索并删除三个区域内的 CelestialCore。
-- 当前地图已不存在 CelestialCore，也不存在对应过滤器逻辑；保留此文件仅供历史参考。

g_CelestialCoreFilter = CreateObjectFilter({
    Rule = "ANY",
    IncludeThing = {
        "CelestialCore"
    },
})

SchedulerModule.call_every_x_frame(function()
    local obj, count = ObjectFindObjects(nil, {
        X=1300, Y=3000, Z=210, Radius=1300, DistType="EXTENTS_3D"
    }, g_CelestialCoreFilter)
    for i = 1 , count , 1 do
        ExecuteAction("NAMED_DELETE", obj[i]);
    end

    obj, count = ObjectFindObjects(nil, {
        X=3000, Y=3000, Z=210, Radius=1300, DistType="EXTENTS_3D"
    }, g_CelestialCoreFilter)
    for i = 1 , count , 1 do
        ExecuteAction("NAMED_DELETE", obj[i]);
    end

    obj, count = ObjectFindObjects(nil, {
        X=5700, Y=3000, Z=210, Radius=1300, DistType="EXTENTS_3D"
    }, g_CelestialCoreFilter)
    for i = 1 , count , 1 do
        ExecuteAction("NAMED_DELETE", obj[i]);
    end

end, 15 * 4, nil)
