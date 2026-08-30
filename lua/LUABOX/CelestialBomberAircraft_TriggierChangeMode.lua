-- 旧版保留脚本，当前地图中不执行这里的延迟调度。
-- 本地旧逻辑会延迟 5 帧调用 CelestialBomberAircraft_RandomChangeMode()。
-- 当前地图只保留函数定义，没有这次调度调用；保留此文件仅供历史参考。

SchedulerModule.delay_call(function()
    CelestialBomberAircraft_RandomChangeMode()
end, 5)
