
-- 达摩剑的常规随机目标池：只允许非建筑单位。
-- 最前方防御塔仅由达摩剑首轮逻辑单独指定一次，不进入本过滤器。
unitall = CreateObjectFilter({
  Rule="ANY",
  Relationship="SAME_PLAYER",
  ExcludeThing={
    "JapanFortressShip",
    "Overlordtank",
    "JapanLightTransportVehicle",
    "AlliedNightinaleHelicopter",
    "AlliedMCV",
    -- 青龙战斗核心舰的普通、强化以及陆海空全部形态。
    "CelestialMCV",
    "CelestialMCV_Ground",
    "CelestialMCV_Naval",
    "CelestialMCV_Air",
    "CelestialMCV_Enhanced",
    "CelestialMCV_Enhanced_Ground",
    "CelestialMCV_Enhanced_Naval",
    "CelestialMCV_Enhanced_Air",
  },
  Include="SELECTABLE",
  -- 所有防御塔和其他建筑都排除，单位不足时也不会拿塔补位。
  Exclude="STRUCTURE",
})
