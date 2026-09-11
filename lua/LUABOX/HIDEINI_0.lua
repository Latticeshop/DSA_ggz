FilterJapanLightTransportVehicle=CreateObjectFilter({
  Rule="ANY",
  IncludeThing = {
    "JapanLightTransportVehicle",
  }
})
FilterAlliedNightinaleHelicopter=CreateObjectFilter({
  Rule="ANY",
  IncludeThing = {
    "AlliedNightinaleHelicopter",
  }
})


function HIDEOBJ ()
  local SELF, count = ObjectFindObjects(nil, nil, FilterJapanLightTransportVehicle)
  for i = 1 , count , 1 do
    local transport = SELF[i]
    ExecuteAction("UNIT_SET_MODELCONDITION_GENERIC", transport, "HIDDEN", 0) -- 这个 0 代表永久持续
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", transport, "STEALTHED", 1)
    ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", transport, "UNDER_IRON_CURTAIN", 1)
  end
end

HIDEOBJ ()
-- 只对地图上已有的夜莺生效，后续生产的夜莺不受影响
local initialNightinales, countNightinales = ObjectFindObjects(nil, nil, FilterAlliedNightinaleHelicopter)
for i = 1 , countNightinales , 1 do
  local nightinale = initialNightinales[i]
  ExecuteAction("UNIT_SET_MODELCONDITION_GENERIC", nightinale, "HIDDEN", 0) -- 这个 0 代表永久持续
  ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", nightinale, "STEALTHED", 1)
  ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", nightinale, "UNDER_IRON_CURTAIN", 1)
end
