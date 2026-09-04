g_CurrentRecycleType = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
};

g_CurrentClickRecycleUnit = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
};

g_RecycleBtnsShowed = {
    [1] = {},
    [2] = {},
    [3] = {},
    [4] = {},
    [5] = {},
    [6] = {},
};

g_RecycleUnitCount = {
    [1] = 1,
    [2] = 5,
    [3] = 10,
    [4] = 20,
}

g_RecycleBtnsIndexStart = 30;
-- 留足索引范围，确保玩家同时拥有多个阵营/抽卡来源的全部单位时也不会截断在第 49 个按钮。
g_RecycleBtnsMaxCount = 200;

--g_Infantry = {
--    {Type = "AlliedScoutInfantry", Image = "Button_AlliedScoutInfantry_on", Name = Localization.recycle('unit.AlliedScoutInfantry'), Money = 200},
--    {Type = "AlliedAntiInfantryInfantry", Image = "Button_AlliedAntiInfantryInfantry_on", Name = Localization.recycle('unit.AlliedAntiInfantryInfantry'), Money = 200},
--    {Type = "AlliedAntiVehicleInfantry", Image = "Button_AlliedAntiVehicleInfantry_on", Name = Localization.recycle('unit.AlliedAntiVehicleInfantry'), Money = 300},
--    {Type = "AlliedCryoLegionnaire", Image = "Button_AlliedCryoLegionnaire", Name = Localization.recycle('unit.AlliedCryoLegionnaire'), Money = 1600},
--    {Type = "SovietScoutInfantry", Image = "Button_SovietScoutInfantry_small", Name = Localization.recycle('unit.SovietScoutInfantry'), Money = 225},
--    {Type = "SovietAntiInfantryInfantry", Image = "Button_SovietAntiInfantryInfantry_small", Name = Localization.recycle('unit.SovietAntiInfantryInfantry'), Money = 100},
--    {Type = "SovietAntiVehicleInfantry", Image = "Button_SovietAntiVehicleInfantry_small", Name = Localization.recycle('unit.SovietAntiVehicleInfantry'), Money = 400},
--    {Type = "SovietMortarCycle", Image = "Button_SovietMortarCycle", Name = Localization.recycle('unit.SovietMortarCycle'), Money = 750},
--    {Type = "SovietHeavyAntiVehicleInfantry", Image = "Button_SovietHeavyAntiVehicleInfantry_small", Name = Localization.recycle('unit.SovietHeavyAntiVehicleInfantry'), Money = 850},
--    {Type = "JapanScoutInfantry", Image = "Button_JapanScoutInfantry", Name = Localization.recycle('unit.JapanScoutInfantry'), Money = 300},
--    {Type = "JapanAntiInfantryInfantry", Image = "Button_JapanAntiInfantryInfantry", Name = Localization.recycle('unit.JapanAntiInfantryInfantry'), Money = 150},
--    {Type = "JapanAntiVehicleInfantry", Image = "Button_JapanAntiVehicleInfantry", Name = Localization.recycle('unit.JapanAntiVehicleInfantry'), Money = 300},
--    {Type = "JapanInfiltrationInfantry", Image = "Button_JapanInfiltrationInfantry", Name = Localization.recycle('unit.JapanInfiltrationInfantry'), Money = 850},
--    {Type = "JapanAntiVehicleInfantryTech3", Image = "Button_JapanAntiVehicleInfantryTech3", Name = Localization.recycle('unit.JapanAntiVehicleInfantryTech3'), Money = 1000},
--    {Type = "CelestialScoutDrone", Image = "Button_CelestialScoutDrone", Name = Localization.recycle('unit.CelestialScoutDrone'), Money = 200},
--    {Type = "CelestialAntiInfantryInfantry", Image = "Button_CelestialAntiInfantryInfantry", Name = Localization.recycle('unit.CelestialAntiInfantryInfantry'), Money = 225},
--    {Type = "CelestialAntiVehicleInfantry", Image = "Button_CelestialAntiVehicleEMCInfantry", Name = Localization.recycle('unit.CelestialAntiVehicleInfantry'), Money = 500},
--    {Type = "CelestialInfiltrationInfantry", Image = "Button_CelestialInfiltrationInfantry", Name = Localization.recycle('unit.CelestialInfiltrationInfantry'), Money = 850},
--    {Type = "CelestialAntiInfantryInfantryAdvanced", Image = "Button_CelestialAntiInfantryInfantryAdvanced", Name = Localization.recycle('unit.CelestialAntiInfantryInfantryAdvanced'), Money = 1400},
--}

g_InfantryAllied = {
    {Type = "AlliedScoutInfantry", Image = "Button_AlliedScoutInfantry_on", Name = Localization.recycle('unit.AlliedScoutInfantry'), Money = 200},
    {Type = "AlliedAntiInfantryInfantry", Image = "Button_AlliedAntiInfantryInfantry_on", Name = Localization.recycle('unit.AlliedAntiInfantryInfantry'), Money = 200},
    {Type = "AlliedAntiVehicleInfantry", Image = "Button_AlliedAntiVehicleInfantry_on", Name = Localization.recycle('unit.AlliedAntiVehicleInfantry'), Money = 300},
    {Type = "AlliedRangerInfantry", Image = "Button_AlliedRangerInfantry", Name = Localization.recycle('unit.AlliedRangerInfantry'), Money = 200},
    {Type = "AlliedCryoLegionnaire", Image = "Button_AlliedCryoLegionnaire", Name = Localization.recycle('unit.AlliedCryoLegionnaire'), Money = 1600},
    {Type = "AlliedCommandoTech1", Image = "Button_AlliedCommandoTech1_on_02", Name = Localization.recycle('unit.AlliedCommandoTech1'), Money = 2000},
}

g_InfantrySoviet = {
    {Type = "SovietScoutInfantry", Image = "Button_SovietScoutInfantry_small", Name = Localization.recycle('unit.SovietScoutInfantry'), Money = 225},
    {Type = "SovietAntiInfantryInfantry", Image = "Button_SovietAntiInfantryInfantry_small", Name = Localization.recycle('unit.SovietAntiInfantryInfantry'), Money = 100},
    {Type = "SovietAntiVehicleInfantry", Image = "Button_SovietAntiVehicleInfantry_small", Name = Localization.recycle('unit.SovietAntiVehicleInfantry'), Money = 400},
    {Type = "SovietMortarCycle", Image = "Button_SovietMortarCycle", Name = Localization.recycle('unit.SovietMortarCycle'), Money = 750},
    {Type = "SovietHeavyAntiVehicleInfantry", Image = "Button_SovietHeavyAntiVehicleInfantry_small", Name = Localization.recycle('unit.SovietHeavyAntiVehicleInfantry'), Money = 850},
    {Type = "SovietCommandoTech1", Image = "Button_SovietCommando_small", Name = Localization.recycle('unit.SovietCommandoTech1'), Money = 2000},
}

g_InfantryJapan = {
    {Type = "JapanScoutInfantry", Image = "Button_JapanScoutInfantry", Name = Localization.recycle('unit.JapanScoutInfantry'), Money = 300},
    {Type = "JapanAntiInfantryInfantry", Image = "Button_JapanAntiInfantryInfantry", Name = Localization.recycle('unit.JapanAntiInfantryInfantry'), Money = 100},
    {Type = "JapanAntiVehicleInfantry", Image = "Button_JapanAntiVehicleInfantry", Name = Localization.recycle('unit.JapanAntiVehicleInfantry'), Money = 300},
    {Type = "JapanArcherInfantry", Image = "Button_JapanArcherMaiden", Name = Localization.recycle('unit.JapanArcherInfantry'), Money = 400},
    {Type = "JapanInfiltrationInfantry", Image = "Button_JapanInfiltrationInfantry", Name = Localization.recycle('unit.JapanInfiltrationInfantry'), Money = 850},
    {Type = "JapanAntiVehicleInfantryTech3", Image = "Button_JapanAntiVehicleInfantryTech3", Name = Localization.recycle('unit.JapanAntiVehicleInfantryTech3'), Money = 1000},
    {Type = "JapanCommandoTech1", Image = "Button_JapanCommandoTech1", Name = Localization.recycle('unit.JapanCommandoTech1'), Money = 2000},
}

g_InfantryCelestial = {
    {Type = "CelestialScoutDrone", Image = "Button_CelestialScoutDrone", Name = Localization.recycle('unit.CelestialScoutDrone'), Money = 200},
    {Type = "CelestialAntiInfantryInfantry", Image = "Button_CelestialAntiInfantryInfantry", Name = Localization.recycle('unit.CelestialAntiInfantryInfantry'), Money = 225},
    {Type = "CelestialAntiVehicleInfantry", Image = "Button_CelestialAntiVehicleEMCInfantry", Name = Localization.recycle('unit.CelestialAntiVehicleInfantry'), Money = 500},
    {Type = "CelestialInfiltrationInfantry", Image = "Button_CelestialInfiltrationInfantry", Name = Localization.recycle('unit.CelestialInfiltrationInfantry'), Money = 850},
    {Type = "CelestialAntiInfantryInfantryAdvanced", Image = "Button_CelestialAntiInfantryInfantryAdvanced", Name = Localization.recycle('unit.CelestialAntiInfantryInfantryAdvanced'), Money = 1400},
}

--g_Vehicle = {
--    --{Type = "AlliedAntiInfantryVehicle", Image = "Button_AlliedAntiInfantryVehicle_on", Name = "ACV"},
--    {Type = "AlliedAntiAirVehicleTech1", Image = "Button_AlliedIFV_B_on", Name = "ifv", Money = 800},
--    {Type = "AlliedAntiVehicleVehicleTech1", Image = "Button_AlliedAntiVehicleVehicleTech1_on", Name = Localization.recycle('unit.AlliedAntiVehicleVehicleTech1'), Money = 950},
--    {Type = "PrismTank", Image = "Button_PrismTank_B", Name = Localization.recycle('unit.PrismTank'), Money = 1400},
--    {Type = "AlliedAntiStructureVehicle", Image = "Button_AlliedAntiStructureVehicle_on", Name = Localization.recycle('unit.AlliedAntiStructureVehicle'), Money = 1800},
--    {Type = "AlliedAntiVehicleVehicleTech3", Image = "Button_AlliedAntiVehicleVehicleTech3_B", Name = Localization.recycle('unit.AlliedAntiVehicleVehicleTech3'), Money = 1600},
--    {Type = "AlliedFutureTank", Image = "Button_AlliedFutureTank", Name = Localization.recycle('unit.AlliedFutureTank'), Money = 3200},
--    {Type = "SovietScoutVehicle", Image = "Button_SovietScoutVehicle_small", Name = Localization.recycle('unit.SovietScoutVehicle'), Money = 600},
--    {Type = "SovietAntiInfantryVehicle", Image = "Button_SovietAntiInfantryVehicle_small", Name = Localization.recycle('unit.SovietAntiInfantryVehicle'), Money = 900},
--    {Type = "SovietAntiAirShip", Image = "Button_SovietAntiAirShip_small", Name = Localization.recycle('unit.SovietAntiAirShip'), Money = 900},
--    {Type = "SovietHeavyAntiVehicleVehicleTech2", Image = "Button_SovietRhinoTank", Name = Localization.recycle('unit.SovietHeavyAntiVehicleVehicleTech2'), Money = 1100},
--    {Type = "SovietSledgehammerSPG", Image = "Button_SovietSledgehammerSPG", Name = Localization.recycle('unit.SovietSledgehammerSPG'), Money = 1500},
--    {Type = "SovietAntiStructureVehicle", Image = "Button_SovietAntiStructureVehicle_small", Name = Localization.recycle('unit.SovietAntiStructureVehicle'), Money = 1600},
--    {Type = "SovietAntiVehicleVehicleTech3", Image = "Button_SovietAntiVehicleVehicleTech3", Name = Localization.recycle('unit.SovietAntiVehicleVehicleTech3'), Money = 2000},
--    {Type = "SovietAntiVehicleVehicleTech4", Image = "Button_SovietAntiVehicleVehicleTech4", Name = Localization.recycle('unit.SovietAntiVehicleVehicleTech4'), Money = 4500},
--    {Type = "JapanAntiInfantryVehicle", Image = "Button_JapanAntiInfantryVehicle_mecha", Name = Localization.recycle('unit.JapanAntiInfantryVehicle'), Money = 800},
--    {Type = "JapanAntiVehicleVehicleTech1", Image = "Button_JapanAntiVehicleVehicleTech1", Name = Localization.recycle('unit.JapanAntiVehicleVehicleTech1'), Money = 1400},
--    {Type = "JapanAntiAirVehicleTech1", Image = "Button_JapanAntiAirVehicleTech1_walker", Name = "vx", Money = 1200},
--    {Type = "JapanSentinelVehicle", Image = "Button_JapanSteelRonin", Name = Localization.recycle('unit.JapanSentinelVehicle'), Money = 1400},
--    {Type = "JapanMissileMechaAdvanced", Image = "Button_JapanMissileMechaAdvanced", Name = Localization.recycle('unit.JapanMissileMechaAdvanced'), Money = 1800},
--    {Type = "JapanAntiVehicleVehicleTech3", Image = "Button_JapanAntiVehicleVehicleTech3", Name = Localization.recycle('unit.JapanAntiVehicleVehicleTech3'), Money = 2200},
--    {Type = "JapanAntiStructureVehicle", Image = "Button_JapanAntiStructureVehicle", Name = Localization.recycle('unit.JapanAntiStructureVehicle'), Money = 1800},
--    {Type = "JapanInterceptorAircraft", Image = "Button_JapanInterceptorAircraft_sea", Name = Localization.recycle('unit.JapanInterceptorAircraft'), Money = 850},
--    {Type = "JapanMechaX", Image = "Button_RedKingOni", Name = Localization.recycle('unit.JapanMechaX'), Money = 4500},
--    {Type = "CelestialAntiInfantryVehicle", Image = "Button_CelestialAntiInfantryVehicle_B", Name = Localization.recycle('unit.CelestialAntiInfantryVehicle'), Money = 850},
--    {Type = "CelestialAntiAirShip", Image = "Button_CelestialAntiAirShip", Name = Localization.recycle('unit.CelestialAntiAirShip'), Money = 900},
--    {Type = "CelestialAntiVehicleVehicleTech1", Image = "Button_CelestialKylinMBT", Name = Localization.recycle('unit.CelestialAntiVehicleVehicleTech1'), Money = 1000},
--    {Type = "CelestialLongRangeMissileVehicle_B", Image = "Button_CelestialLongRangeMissileVehicle_B", Name = Localization.recycle('unit.CelestialLongRangeMissileVehicle_B'), Money = 1400},
--    {Type = "CelestialAntiVehicleVehicleTech3", Image = "Button_CelestialAntiVehicleVehicleTech3", Name = Localization.recycle('unit.CelestialAntiVehicleVehicleTech3'), Money = 2000},
--    {Type = "CelestialHeavyAntiAirVehicleTech3", Image = "Button_CelestialHeavyAntiAirVehicleTech3", Name = Localization.recycle('unit.CelestialHeavyAntiAirVehicleTech3'), Money = 2000},
--    {Type = "CelestialAntiStructureVehicle", Image = "Button_CelestialAntiStructureVehicle", Name = Localization.recycle('unit.CelestialAntiStructureVehicle'), Money = 1800},
--    {Type = "CelestialAntiVehicleVehicleTech4", Image = "Button_CelestialAntiVehicleVehicleTech4", Name = Localization.recycle('unit.CelestialAntiVehicleVehicleTech4'), Money = 4500},
--}

g_VehicleAllied = {
    {Type = "AlliedAntiInfantryVehicle_Ground", Image = "Button_AlliedAntiInfantryVehicle_on", Name = Localization.recycle('unit.AlliedAntiInfantryVehicle'), Money = 750},
    {Type = "AlliedAntiAirVehicleTech1", Image = "Button_AlliedIFV_B_on", Name = Localization.recycle('unit.AlliedAntiAirVehicleTech1'), Money = 800},
    {Type = "AlliedAntiVehicleVehicleTech1", Image = "Button_AlliedAntiVehicleVehicleTech1_on", Name = Localization.recycle('unit.AlliedAntiVehicleVehicleTech1'), Money = 950},
    {Type = "prismtank", Image = "Button_PrismTank_B", Name = Localization.recycle('unit.prismtank'), Money = 1400},
    {Type = "AlliedAntiStructureVehicle", Image = "Button_AlliedAntiStructureVehicle_on", Name = Localization.recycle('unit.AlliedAntiStructureVehicle'), Money = 1800},
    {Type = "AlliedAntiVehicleVehicleTech3", Image = "Button_AlliedAntiVehicleVehicleTech3_B", Name = Localization.recycle('unit.AlliedAntiVehicleVehicleTech3'), Money = 1600},
    {Type = "AlliedFutureTank", Image = "Button_AlliedFutureTank", Name = Localization.recycle('unit.AlliedFutureTank'), Money = 3200},
    {Type = "AlliedBattleFortress", Image = "Button_AlliedBattleFortress", Name = Localization.recycle('unit.AlliedBattleFortress'), Money = 4500},
    {Type = "AlliedAirForceDispatchVehicle", Image = "Button_AlliedAirForceDispatchVehicle", Name = Localization.recycle('unit.AlliedAirForceDispatchVehicle'), Money = 3000},
}

g_VehicleSoviet = {
    {Type = "SovietScoutVehicle", Image = "Button_SovietScoutVehicle_small", Name = Localization.recycle('unit.SovietScoutVehicle'), Money = 600},
    {Type = "SovietAntiInfantryVehicle", Image = "Button_SovietAntiInfantryVehicle_small", Name = Localization.recycle('unit.SovietAntiInfantryVehicle'), Money = 900},
    {Type = "SovietAntiAirShip", Image = "Button_SovietAntiAirShip_small", Name = Localization.recycle('unit.SovietAntiAirShip'), Money = 900},
    {Type = "SovietHeavyAntiVehicleVehicleTech2", Image = "Button_SovietRhinoTank", Name = Localization.recycle('unit.SovietHeavyAntiVehicleVehicleTech2'), Money = 1100},
    {Type = "SovietSledgehammerSPG", Image = "Button_SovietSledgehammerSPG", Name = Localization.recycle('unit.SovietSledgehammerSPG'), Money = 1500},
    {Type = "SovietAntiVehicleVehicleTech2", Image = "Button_SovietTeslaTank_small", Name = Localization.recycle('unit.SovietAntiVehicleVehicleTech2'), Money = 1200},
    {Type = "SovietAntiStructureVehicle", Image = "Button_SovietAntiStructureVehicle_small", Name = Localization.recycle('unit.SovietAntiStructureVehicle'), Money = 1600},
    {Type = "SovietAntiVehicleVehicleTech3", Image = "Button_SovietAntiVehicleVehicleTech3", Name = Localization.recycle('unit.SovietAntiVehicleVehicleTech3'), Money = 2000},
    {Type = "SovietAntiVehicleVehicleTech4", Image = "Button_SovietAntiVehicleVehicleTech4", Name = Localization.recycle('unit.SovietAntiVehicleVehicleTech4'), Money = 4500},
    {Type = "SovietGrinderVehicle", Image = "Button_SovietGrinder", Name = Localization.recycle('unit.SovietGrinderVehicle'), Money = 1600},
    {Type = "Overlordtank", Image = "Button_Overlordtank", Name = Localization.recycle('unit.Overlordtank'), Money = 4500},
    {Type = "SovietElectronicRadarTruck", Image = "Button_SovietElectronicRadarTruck", Name = Localization.recycle('unit.SovietElectronicRadarTruck'), Money = 1800},
}

g_VehicleJapan = {
    {Type = "JapanAntiInfantryVehicle", Image = "Button_JapanAntiInfantryVehicle_mecha", Name = Localization.recycle('unit.JapanAntiInfantryVehicle'), Money = 800},
    {Type = "JapanAntiVehicleVehicleTech1", Image = "Button_JapanAntiVehicleVehicleTech1", Name = Localization.recycle('unit.JapanAntiVehicleVehicleTech1'), Money = 1400},
    {Type = "JapanAntiAirVehicleTech1", Image = "Button_JapanAntiAirVehicleTech1_walker", Name = "vx", Money = 1200},
    {Type = "JapanSentinelVehicle", Image = "Button_JapanSteelRonin", Name = Localization.recycle('unit.JapanSentinelVehicle'), Money = 1400},
    {Type = "JapanMissileMechaAdvanced", Image = "Button_JapanMissileMechaAdvanced", Name = Localization.recycle('unit.JapanMissileMechaAdvanced'), Money = 1800},
    {Type = "JapanAntiVehicleVehicleTech3", Image = "Button_JapanAntiVehicleVehicleTech3", Name = Localization.recycle('unit.JapanAntiVehicleVehicleTech3'), Money = 2200},
    {Type = "JapanAntiStructureVehicle", Image = "Button_JapanAntiStructureVehicle", Name = Localization.recycle('unit.JapanAntiStructureVehicle'), Money = 1800},
    {Type = "JapanInterceptorAircraft", Image = "Button_JapanInterceptorAircraft_sea", Name = Localization.recycle('unit.JapanInterceptorAircraft'), Money = 850},
    {Type = "JapanMechaX", Image = "Button_RedKingOni", Name = Localization.recycle('unit.JapanMechaX'), Money = 4500},
    {Type = "JapanAntiAirVehicleTech3", Image = "Button_JapanAntiAirVehicleTech3", Name = Localization.recycle('unit.JapanAntiAirVehicleTech3'), Money = 2000},
}

g_VehicleCelestial = {
    {Type = "CelestialAntiInfantryVehicle_B", Image = "Button_CelestialAntiInfantryVehicle_B", Name = Localization.recycle('unit.CelestialAntiInfantryVehicle_B'), Money = 850},
    {Type = "CelestialAntiAirShip", Image = "Button_CelestialAntiAirShip", Name = Localization.recycle('unit.CelestialAntiAirShip'), Money = 900},
    {Type = "CelestialAntiVehicleVehicleTech1", Image = "Button_CelestialKylinMBT", Name = Localization.recycle('unit.CelestialAntiVehicleVehicleTech1'), Money = 1000},
    {Type = "CelestialAntiAirVehicle", Image = "Button_CelestialAntiAirVehicle", Name = Localization.recycle('unit.CelestialAntiAirVehicle'), Money = 900},
    {Type = "CelestialLongRangeMissileVehicle", Image = "Button_CelestialHJ-10", Name = Localization.recycle('unit.CelestialLongRangeMissileVehicle'), Money = 1400},
    {Type = "CelestialLongRangeMissileVehicle_B", Image = "Button_CelestialLongRangeMissileVehicle_B", Name = Localization.recycle('unit.CelestialLongRangeMissileVehicle_B'), Money = 1400},
    {Type = "CelestialAntiVehicleVehicleTech3", Image = "Button_CelestialAntiVehicleVehicleTech3", Name = Localization.recycle('unit.CelestialAntiVehicleVehicleTech3'), Money = 2000},
    {Type = "CelestialHeavyAntiAirVehicleTech3", Image = "Button_CelestialHeavyAntiAirVehicleTech3", Name = Localization.recycle('unit.CelestialHeavyAntiAirVehicleTech3'), Money = 2000},
    {Type = "CelestialAntiStructureVehicle", Image = "Button_CelestialAntiStructureVehicle", Name = Localization.recycle('unit.CelestialAntiStructureVehicle'), Money = 1800},
    {Type = "CelestialAntiVehicleVehicleTech4", Image = "Button_CelestialAntiVehicleVehicleTech4", Name = Localization.recycle('unit.CelestialAntiVehicleVehicleTech4'), Money = 4500},
    {Type = "CelestialAntiAirVehicleTech3", Image = "Button_CelestialAntiAirVehicleTech3", Name = Localization.recycle('unit.CelestialAntiAirVehicleTech3'), Money = 2500},
}

--g_AirCraft = {
--    {Type = "AlliedAntiGroundAircraft", Image = "Button_AlliedAntiGroundAircraft_on", Name = Localization.recycle('unit.AlliedAntiGroundAircraft'), Money = 1200},
--    {Type = "AlliedFighterAircraft", Image = "Button_AlliedApolloFighterAircraft", Name = Localization.recycle('unit.AlliedFighterAircraft'), Money = 1000},
--    {Type = "AlliedSupportAircraft", Image = "Button_AlliedSupportAircraft_on", Name = Localization.recycle('unit.AlliedSupportAircraft'), Money = 1600},
--    {Type = "AlliedInterceptorAircraftTech3", Image = "Button_AlliedInterceptorAircraftTech3", Name = Localization.recycle('unit.AlliedInterceptorAircraftTech3'), Money = 1600},
--    {Type = "AlliedAntiStructureBomberAircraft", Image = "Button_AlliedBomberAircraft_on", Name = Localization.recycle('unit.AlliedAntiStructureBomberAircraft'), Money = 2500},
--    {Type = "AlliedGunshipAircraft", Image = "Button_AlliedHarbingerGunship", Name = Localization.recycle('unit.AlliedGunshipAircraft'), Money = 4000},
--    {Type = "SovietAntiGroundAircraft", Image = "Button_SovietAntiGroundAircraft_small", Name = Localization.recycle('unit.SovietAntiGroundAircraft'), Money = 1200},
--    {Type = "SovietFighterAircraft", Image = "Button_SovietMigFighterAircraft", Name = Localization.recycle('unit.SovietFighterAircraft'), Money = 1000},
--    {Type = "SovietInterceptorAircraft", Image = "Button_SovietInterceptorAircraft", Name = Localization.recycle('unit.SovietInterceptorAircraft'), Money = 1800},
--    {Type = "SovietTransportAircraft", Image = "Button_SovietTransportAircraft", Name = Localization.recycle('unit.SovietTransportAircraft'), Money = 2000},
--    {Type = "SovietAntiGroundAttacker", Image = "Button_SovietAntiGroundAttacker", Name = Localization.recycle('unit.SovietAntiGroundAttacker'), Money = 2500},
--    {Type = "SovietBomberAircraft", Image = "Button_SovietBomberAircraft", Name = Localization.recycle('unit.SovietBomberAircraft'), Money = 3600},
--    {Type = "CelestialFighterAircraft", Image = "Button_CelestialFighterAircraft", Name = Localization.recycle('unit.CelestialFighterAircraft'), Money = 1000},
--    {Type = "CelestialSupportAircraft", Image = "Button_CelestialSupportAircraft", Name = Localization.recycle('unit.CelestialSupportAircraft'), Money = 1200},
--    {Type = "CelestialAttackerAircraft", Image = "Button_CelestialAttackerAircraft", Name = Localization.recycle('unit.CelestialAttackerAircraft'), Money = 1400},
--    {Type = "CelestialInterceptorAircraft", Image = "Button_CelestialInterceptorAircraft", Name = Localization.recycle('unit.CelestialInterceptorAircraft'), Money = 1600},
--    {Type = "CelestialBomberAircraft", Image = "Button_CelestialBomberAircraft", Name = Localization.recycle('unit.CelestialBomberAircraft'), Money = 2500},
--    {Type = "CelestialAdvancedAircraftTech4", Image = "Button_CelestialAdvancedAircraftTech4", Name = Localization.recycle('unit.CelestialAdvancedAircraftTech4'), Money = 5000},
--}

g_AirCraftAllied = {
    {Type = "AlliedAntiGroundAircraft", Image = "Button_AlliedAntiGroundAircraft_on", Name = Localization.recycle('unit.AlliedAntiGroundAircraft'), Money = 1200},
    {Type = "AlliedFighterAircraft", Image = "Button_AlliedApolloFighterAircraft", Name = Localization.recycle('unit.AlliedFighterAircraft'), Money = 1000},
    {Type = "AlliedSupportAircraft", Image = "Button_AlliedSupportAircraft_on", Name = Localization.recycle('unit.AlliedSupportAircraft'), Money = 1600},
    {Type = "AlliedInterceptorAircraft", Image = "Button_AlliedInterceptorAircraftTech3", Name = Localization.recycle('unit.AlliedInterceptorAircraft'), Money = 1600},
    {Type = "AlliedAntiStructureBomberAircraft", Image = "Button_AlliedBomberAircraft_on", Name = Localization.recycle('unit.AlliedAntiStructureBomberAircraft'), Money = 2500},
    {Type = "AlliedGunshipAircraft", Image = "Button_AlliedHarbingerGunship", Name = Localization.recycle('unit.AlliedGunshipAircraft'), Money = 4000},
    {Type = "AlliedAC130GunshipAircraft", Image = "Button_AlliedHarbingerGunship", Name = Localization.recycle('unit.AlliedAC130GunshipAircraft'), Money = 4000},
    {Type = "AlliedBomberAircraft", Image = "Button_AlliedBomberAircraft_on", Name = Localization.recycle('unit.AlliedBomberAircraft'), Money = 2500},
}

g_AirCraftSoviet = {
    {Type = "SovietAntiGroundAircraft", Image = "Button_SovietAntiGroundAircraft_small", Name = Localization.recycle('unit.SovietAntiGroundAircraft'), Money = 1200},
    {Type = "SovietFighterAircraft", Image = "Button_SovietMigFighterAircraft", Name = Localization.recycle('unit.SovietFighterAircraft'), Money = 1000},
    {Type = "SovietInterceptorAircraft", Image = "Button_SovietInterceptorAircraft", Name = Localization.recycle('unit.SovietInterceptorAircraft'), Money = 1800},
    {Type = "SovietTransportAircraft", Image = "Button_SovietTransportAircraft", Name = Localization.recycle('unit.SovietTransportAircraft'), Money = 2000},
    {Type = "SovietAntiGroundAttacker", Image = "Button_SovietAntiGroundAttacker", Name = Localization.recycle('unit.SovietAntiGroundAttacker'), Money = 2500},
    {Type = "SovietBomberAircraft", Image = "Button_SovietBomberAircraft", Name = Localization.recycle('unit.SovietBomberAircraft'), Money = 3600},
}

g_AirCraftJapan = {
    -- 超级要塞由独立计数槽管理；水面/大头形态都归到同一枚核心。
    {Type = "JapanGigaFortressShipEgg", CountType = "JapanGigaFortressShipEgg", CountsTowardArmyTotal = false,
        Image = "Button_JapanGigaFortressShip", Name = Localization.recycle('unit.JapanFortressShip'), Money = 6300},
}

g_AirCraftCelestial = {
    {Type = "CelestialFighterAircraft", Image = "Button_CelestialFighterAircraft", Name = Localization.recycle('unit.CelestialFighterAircraft'), Money = 1000},
    {Type = "CelestialSupportAircraft", Image = "Button_CelestialSupportAircraft", Name = Localization.recycle('unit.CelestialSupportAircraft'), Money = 1200},
    {Type = "CelestialAttackerAircraft", Image = "Button_CelestialAttackerAircraft", Name = Localization.recycle('unit.CelestialAttackerAircraft'), Money = 1400},
    {Type = "CelestialInterceptorAircraft", Image = "Button_CelestialInterceptorAircraft", Name = Localization.recycle('unit.CelestialInterceptorAircraft'), Money = 1600},
    {Type = "CelestialBomberAircraft", Image = "Button_CelestialBomberAircraft", Name = Localization.recycle('unit.CelestialBomberAircraft'), Money = 2500},
    {Type = "CelestialAdvanceAircraftTech4", Image = "Button_CelestialAdvancedAircraftTech4", Name = Localization.recycle('unit.CelestialAdvanceAircraftTech4'), Money = 5000},
}

--g_Ship = {
--    {Type = "AlliedAntiNavalScout", Image = "Button_AlliedAntiNavalScout_on", Name = "", Money = 750},
--    {Type = "AlliedAntiAirShip", Image = "Button_AlliedAntiAirShip_on", Name = "", Money = 900},
--    {Type = "AlliedAntiNavyShipTech1", Image = "Button_AlliedAntiNavyShipTech1_on", Name = "", Money = 1600},
--    {Type = "AlliedAntiNavyShipTech3", Image = "Button_AlliedAntiNavyShipTech3", Name = "", Money = 4000},
--    {Type = "AlliedAntiStructureShip", Image = "Button_AlliedAntiStructureShip_on", Name = "", Money = 5500},
--    {Type = "SovietAntiNavyShipTech1", Image = "Button_SovietAntiNavyShipTech1_small", Name = "", Money = 1000},
--    {Type = "SovietAntiNavyShipTech2", Image = "Button_SovietAntiNavyShipTech2_small", Name = "", Money = 2000},
--    {Type = "SovietAntiNavyShipTech3", Image = "Button_SovietAntiNavyShipTech3", Name = "", Money = 4500},
--    {Type = "SovietAntiStructureShip", Image = "Button_SovietAntiStructureShip_small", Name = "", Money = 5000},
--    {Type = "JapanNavyScoutShip", Image = "Button_JapanNavyScoutShip", Name = "", Money = 800},
--    {Type = "JapanAntiAirShip", Image = "Button_JapanAntiShipAircraft_air", Name = "", Money = 1100},
--    {Type = "JapanAntiVehicleShip", Image = "Button_JapanAntiNavyShipTech2", Name = "", Money = 2000},
--    {Type = "JapanAntiNavyShipTech3", Image = "Button_JapanAntiNavyShipTech3", Name = "", Money = 4500},
--    {Type = "JapanAntiStructureShip", Image = "Button_JapanAntiStructureShip", Name = "", Money = 6300},
--    {Type = "CelestialAntiNavyShipTech1", Image = "Button_CelestialAntiNavyShipTech1", Name = "", Money = 800},
--    {Type = "CelestialAlmightlyShip", Image = "Button_CelestialAntiNavyShipTech2", Name = "", Money = 2000},
--    {Type = "CelestialAntiNavyShipTech3", Image = "Button_CelestialAntiNavyShipTech3B", Name = "", Money = 4500},
--    {Type = "CelestialAntiStructureShip", Image = "Button_CelestialAntiStructureShipB", Name = "", Money = 5000},
--}

g_ShipAllied = {
    {Type = "AlliedAntiNavalScout", Image = "Button_AlliedAntiNavalScout_on", Name = Localization.recycle('unit.AlliedAntiNavalScout'), Money = 750},
    {Type = "AlliedAntiInfantryVehicle", Image = "Button_AlliedAntiInfantryVehicle_on", Name = Localization.recycle('unit.AlliedAntiInfantryVehicle'), Money = 750},
    {Type = "AlliedAntiAirShip", Image = "Button_AlliedAntiAirShip_on", Name = Localization.recycle('unit.AlliedAntiAirShip'), Money = 900},
    {Type = "AlliedAntiNavyShipTech1", Image = "Button_AlliedAntiNavyShipTech1_on", Name = Localization.recycle('unit.AlliedAntiNavyShipTech1'), Money = 1600},
    {Type = "AlliedAntiNavyShipTech3", Image = "Button_AlliedAntiNavyShipTech3", Name = Localization.recycle('unit.AlliedAntiNavyShipTech3'), Money = 4000},
    {Type = "AlliedAntiStructureShip", Image = "Button_AlliedAntiStructureShip_on", Name = Localization.recycle('unit.AlliedAntiStructureShip'), Money = 5500},
}

g_ShipSoviet = {
    {Type = "SovietAntiNavyShipTech1", Image = "Button_SovietAntiNavyShipTech1_small", Name = Localization.recycle('unit.SovietAntiNavyShipTech1'), Money = 1000},
    {Type = "SovietAntiNavyShipTech2", Image = "Button_SovietAntiNavyShipTech2_small", Name = Localization.recycle('unit.SovietAntiNavyShipTech2'), Money = 2000},
    {Type = "SovietAntiNavyShipTech3", Image = "Button_SovietAntiNavyShipTech3", Name = Localization.recycle('unit.SovietAntiNavyShipTech3'), Money = 4500},
    {Type = "SovietAntiStructureShip", Image = "Button_SovietAntiStructureShip_small", Name = Localization.recycle('unit.SovietAntiStructureShip'), Money = 5000},
}

g_ShipJapan = {
    {Type = "JapanNavyScoutShip", Image = "Button_JapanNavyScoutShip", Name = Localization.recycle('unit.JapanNavyScoutShip'), Money = 800},
    {Type = "JapanAntiAirShip", Image = "Button_JapanAntiShipAircraft_air", Name = Localization.recycle('unit.JapanAntiAirShip'), Money = 1100},
    {Type = "JapanAntiVehicleShip", Image = "Button_JapanAntiNavyShipTech2", Name = Localization.recycle('unit.JapanAntiVehicleShip'), Money = 2000},
    {Type = "JapanAntiNavyShipTech3", Image = "Button_JapanAntiNavyShipTech3", Name = Localization.recycle('unit.JapanAntiNavyShipTech3'), Money = 4500},
    {Type = "JapanAntiStructureShip", Image = "Button_JapanAntiStructureShip", Name = Localization.recycle('unit.JapanAntiStructureShip'), Money = 6300},
}

g_ShipCelestial = {
    {Type = "CelestialAntiNavyShipTech1", Image = "Button_CelestialAntiNavyShipTech1", Name = Localization.recycle('unit.CelestialAntiNavyShipTech1'), Money = 800},
    {Type = "CelestialAlmightlyShip", Image = "Button_CelestialAntiNavyShipTech2", Name = Localization.recycle('unit.CelestialAlmightlyShip'), Money = 2000},
    {Type = "CelestialAntiNavyShipTech3", Image = "Button_CelestialAntiNavyShipTech3B", Name = Localization.recycle('unit.CelestialAntiNavyShipTech3'), Money = 4500},
    {Type = "CelestialAntiStructureShip", Image = "Button_CelestialAntiStructureShipB", Name = Localization.recycle('unit.CelestialAntiStructureShip'), Money = 5000},
}

g_CrateUnitsTemplate = {
    [1] = {
        { Type = "JapanKamikazeInfantry", Money = 100 },
    },
    [2] = {
        { Type = "CelestialSaluteGun" },
        { Type = "CelestialWheeledAssaultVehicle", Count = 4,
            Name = Localization.recycle('unit.CelestialWheeledAssualtGun'),
            Image = "Button_CelestialWheeledAssualtGun" },
        { Type = "CelestialWaveriderIFV_DragonBreathe", Count = 4 },
        { Type = "CelestialWaveriderIFV_Mortar", Count = 3 },
        { Type = "CelestialWaveriderIFV_ATGM", Count = 2 },
        { Type = "CelestialMBT99A", Count = 4,
            Image = "Button_CelestialMBT99A1" },
        { Type = "CelestialMBT99B", Count = 3,
            Image = "Button_CelestialMBT99B1" },

        { Type = "AlliedHumveeVehicle", Count = 4,
            Image = "Portrait_AlliedIFV" },
        { Type = "AlliedPacifierFAV", Count = 2,
            Image = "Button_AlliedPacifierVehicle" },
        { Type = "AlliedGrizzlyMainBattleTank", Count = 2 },
        { Type = "RheinEntenteNimravusMBT", Count = 2 },
        { Type = "RheinEntentePalaeoloxodonTD", Count = 2 },

        { Type = "SovietAntiAirVehicle", Count = 3 },
        { Type = "SovietHeavyAntiAirVehicleTech2", Count = 3 },
        { Type = "SovietAntiVehicleVehicleTech1", Count = 3,
            Image = "Button_SovietAntiVehicleVehicleTech1_small" },
        { Type = "SovietHeavyGrinder", Count = 2,
            Image = "Button_SovietGrinder" },
        { Type = "SovietHeavyMortarVehicle", Count = 2 },

        { Type = "VUAntiAirVehicleTech1", Count = 3,
            Image = "Button_VDVAntiAirVehicleTech1" },
        { Type = "VUAntiInfantryVehicleTech1", Count = 4,
            Image = "Button_VDVAntiInfantryVehicleTech1" },
        { Type = "VUAntiVehicleVehicleTech1", Count = 3,
            Image = "Button_VDVAntiVehicleVehicleTech1" },
        { Type = "VUMissileAntiVehicleVehicleTech1", Count = 2,
            Image = "Button_VDVMissileAntiVehicleVehicleTech1" },
        { Type = "VUBmptVehicle", Count = 2,
            Image = "Button_VDVBmptVehicle" },

        { Type = "WinterArmyReaperHeavyMecha", Count = 2 },
        
    },
    [3] = {
        { Type = "AlliedAvengerAttackAircraft", Count = 2 },
        { Type = "AlliedNightinaleHelicopter", Count = 2 },
        { Type = "WinterArmyKoelAttackUAV", Count = 6 },
        { Type = "SovietTransportAircraft_HeavyCannon",
            Image = "Button_SovietTransportAircraft" },
    },
    [4] = {
        { Type = "CelestialWaveriderIFV_Water", Count = 4,
            Name = Localization.recycle('unit.CelestialAntiInfantryVehicle') },
        { Type = "AlliedLandingCraftAirCushion", Count = 2 },
        { Type = "AlliedThetisBattleShip" },
        { Type = "JapanYumiAircraftCarrier" },
        { Type = "CelestialSeized_JapanAntiNavyShipTech3" },
        { Type = "AlliedGaintAirCraftCarrier_B",
            Image = "Button_AlliedGaintAircraftCarrier" },
    },
}
function getCrateUnitsInfoFromTemplate(crateType)
    local crateUnitsInfo = g_CrateUnitsTemplate[crateType]
    if crateUnitsInfo == nil then
        return {}
    end
    local result = {}
    for i = 1, getn(crateUnitsInfo) do
        local unitInfo = crateUnitsInfo[i]
        local unitType = unitInfo.Type
        local unitImage = unitInfo.Image or 'Button_' .. unitType
        local unitName = unitInfo.Name or Localization.recycle('unit.' .. unitType)
        local unitMoney = unitInfo.Money
        if unitMoney == nil then
            -- 从箱子单位的最大获取数量中获取价格
            local maxCount = unitInfo.Count or 1
            -- 玩家可以获取(1~maxCount)个单位，期望数量是 (1 + maxCount) / 2
            -- 我们希望玩家在回收“期望数量”的单位时能拿回 1500
            -- 所以依据这个：
            -- 最大数量1： 1500
            -- 最大数量2： 1500 / 1.5 = 1000
            -- 最大数量3： 1500 / 2 = 750
            -- 最大数量4： 1500 / 2.5 = 600
            if maxCount == 1 then
                unitMoney = 1500
            elseif maxCount == 2 then
                unitMoney = 1000
            elseif maxCount == 3 then
                unitMoney = 750
            else
                unitMoney = 600
            end
        end
        tinsert(result, {
            Type = unitType,
            Image = unitImage,
            Name = unitName,
            Money = unitMoney,
        })
    end
    return result
end
g_CrateUnits = {}
for i = 1, 4 do
    g_CrateUnits[i] = getCrateUnitsInfoFromTemplate(i)
end

--g_RecycleBtnsMap = {
--    [1] = g_Infantry,
--    [2] = g_Vehicle,
--    [3] = g_AirCraft,
--    [4] = g_Ship,
--}

g_RecycleBtnsMapByFaction = {
    [1] = {
        [1] = g_InfantryAllied,
        [2] = g_VehicleAllied,
        [3] = g_AirCraftAllied,
        [4] = g_ShipAllied,
    },
    [2] = {
        [1] = g_InfantrySoviet,
        [2] = g_VehicleSoviet,
        [3] = g_AirCraftSoviet,
        [4] = g_ShipSoviet,
    },
    [3] = {
        [1] = g_InfantryJapan,
        [2] = g_VehicleJapan,
        [3] = g_AirCraftJapan,
        [4] = g_ShipJapan,
    },
    [4] = {
        [1] = g_InfantryCelestial,
        [2] = g_VehicleCelestial,
        [3] = g_AirCraftCelestial,
        [4] = g_ShipCelestial,
    },
}
g_RecycleBtnsMapByPlayerIndex = {}

-- 普通对战单位使用 UNITCOUNT；超级要塞等特殊单位可以在配置里指定独立计数槽。
function GetRecycleUnitCount(playerIndex, unitInfo)
    if unitInfo.CountType ~= nil then
        if g_UnitCount == nil then
            return 0
        end
        local countSlot = g_UnitCount[FastHash(unitInfo.CountType)]
        if countSlot == nil then
            return 0
        end
        return countSlot[playerIndex] or 0
    end

    local unitTypeIndex = g_UnitNameToUnitIndex[unitInfo.Type]
    if unitTypeIndex == nil then
        return 0
    end
    return UNITCOUNT[playerIndex][unitTypeIndex] or 0
end

function RemoveRecycleUnitCount(playerIndex, unitInfo, requestedCount)
    local availableCount = GetRecycleUnitCount(playerIndex, unitInfo)
    local removedCount = requestedCount
    if removedCount > availableCount then
        removedCount = availableCount
    end

    local leftCount = availableCount - removedCount
    if unitInfo.CountType ~= nil then
        g_UnitCount[FastHash(unitInfo.CountType)][playerIndex] = leftCount
    else
        local unitTypeIndex = g_UnitNameToUnitIndex[unitInfo.Type]
        UNITCOUNT[playerIndex][unitTypeIndex] = leftCount
    end

    if unitInfo.CountsTowardArmyTotal ~= false then
        ANYUNITCOUNT[playerIndex] = ANYUNITCOUNT[playerIndex] - removedCount
    end
    return removedCount, leftCount
end

function createRecycleBtns()
    -- TODO 挡住顶部技能栏的文字了
    exCreateCustomButton({
        Index = 21,
        TextureName = "Allied_topmenu_infantry",
        Desc = Localization.get('recycle.desc.infantry'),
        X = 5,
        Y = 5,
        GroupIndex = 2,
        AlignX = "left",
        AlignY = "top",
    })

    exCreateCustomButton({
        Index = 22,
        TextureName = "Allied_topmenu_vehicles",
        Desc = Localization.get('recycle.desc.vehicle'),
        X = 55,
        Y = 5,
        GroupIndex = 2,
        AlignX = "left",
        AlignY = "top",
    })

    exCreateCustomButton({
        Index = 23,
        TextureName = "Allied_topmenu_air",
        Desc = Localization.get('recycle.desc.air'),
        X = 105,
        Y = 5,
        GroupIndex = 2,
        AlignX = "left",
        AlignY = "top",
    })

    exCreateCustomButton({
        Index = 24,
        TextureName = "Allied_topmenu_navy",
        Desc = Localization.get('recycle.desc.navy'),
        X = 155,
        Y = 5,
        GroupIndex = 2,
        AlignX = "left",
        AlignY = "top",
    })

    exCreateCustomButton({
        Index = 25,
        TextureName = "Allied_topmenu_groups",
        Desc = Localization.get('recycle.desc.collapse'),
        X = 205,
        Y = 5,
        GroupIndex = 2,
        AlignX = "left",
        AlignY = "top",
    })

end

function updateRecycleBtnsForPlayerName(playerName)
    local playerIndex = g_PlayerNameToIndex[playerName]
    local playerFaction = g_PlayerSide[playerIndex]
    local newMap = {
        [1] = {},
        [2] = {},
        [3] = {},
        [4] = {},
    }
    for i = 1, 4 do
        local references = {}
        -- 优先显示玩家当前阵营的所有该类型单位
        tinsert(references, g_RecycleBtnsMapByFaction[playerFaction][i])
        -- 但是玩家也有可能获得了其他阵营的单位，所以也要显示其他阵营的该类型单位
        for j = 1, 4 do
            if j ~= playerFaction then
                tinsert(references, g_RecycleBtnsMapByFaction[j][i])
            end
        end
        -- 也加入箱子单位的该类型单位
        tinsert(references, g_CrateUnits[i])
        for j = 1, getn(references) do
            local btns = references[j]
            for k = 1, getn(btns) do
                local shouldInsert = false
                if false
                    -- j == 1 
                    -- or j == getn(references) -- 暂时无条件显示箱子单位
                then
                    -- shouldInsert = true -- 玩家本阵营的单位无条件显示
                else
                    -- 其他阵营的单位不显示，只有当玩家拥有该单位时才显示
                    local unitCount = GetRecycleUnitCount(playerIndex, btns[k])
                    if unitCount > 0 then
                        shouldInsert = true
                    end
                end
                if shouldInsert then
                    tinsert(newMap[i], btns[k])
                end
            end
        end
    end
    g_RecycleBtnsMapByPlayerIndex[playerIndex] = newMap
end

function RecycleUnit_Setting()
    createRecycleBtns();
end

function RecycleUnitBtnsClear(playerName)
    --local playerIndex = g_PlayerNameToIndex[playerName];
    --for i = 1, getn(g_RecycleBtnsShowed[playerIndex]) do
    --    exCustomBtnRemove(g_RecycleBtnsShowed[playerIndex][i]);
    --end

    local playerIndex = g_PlayerNameToIndex[playerName]
    local playerButtons = g_RecycleBtnsShowed[playerIndex]
    if not playerButtons then
        for i = 1, g_RecycleBtnsMaxCount do
            local buttonIndex = g_RecycleBtnsIndexStart + i;
            exCustomBtnRemoveForPlayer(playerName, buttonIndex);
        end
        return
    end
    for i = 1, getn(playerButtons) do
        local buttonIndex = g_RecycleBtnsIndexStart + playerButtons[i];
        exCustomBtnRemoveForPlayer(playerName, buttonIndex);
    end
end

function RecycleTypeBtnClick(playerName, index)
    local playerIndex = g_PlayerNameToIndex[playerName];
    g_CurrentRecycleType[playerIndex] = index - 20;
    -- 关闭之前的按钮
    RecycleUnitBtnsClear(playerName);

    g_RecycleBtnsShowed[playerIndex] = {};
    -- 显示按钮  需要延迟一下，要不然会卡住退出界面
    SchedulerModule.delay_call(function(playerName1, index1)
        local playerIndex1 = g_PlayerNameToIndex[playerName1];
        local playerFaction = g_PlayerSide[playerIndex1];
        updateRecycleBtnsForPlayerName(playerName1)
        local btns = g_RecycleBtnsMapByPlayerIndex[playerIndex1][index1 - 20];
        for i = 1, getn(btns) do
            local currentBtn = btns[i];
            exCreateCustomButtonForPlayer(playerName1, {
                Index = g_RecycleBtnsIndexStart + i,
                TextureName = currentBtn.Image,
                Desc = "",
                X = 5 + mod(i - 1, 6) * 50,
                Y = 60 + floor((i - 1) / 6) * 50,
                GroupIndex = 3,
                AlignX = "left",
                AlignY = "top",
            })
            tinsert(g_RecycleBtnsShowed[playerIndex1], i);
        end
    end, 4, {playerName, index})

end

function RecycleUnitBtnsClick(playerName, index)
    local playerIndex = g_PlayerNameToIndex[playerName];
    local playerFaction = g_PlayerSide[playerIndex];
    if g_RecycleBtnsMapByPlayerIndex[playerIndex] == nil then
        _ALERT("g_RecycleBtnsMapByPlayerIndex[playerIndex] == nil, playerName=" .. playerName .. ", index=" .. index);
    end
    local btnMap = g_RecycleBtnsMapByPlayerIndex[playerIndex][g_CurrentRecycleType[playerIndex]];
    g_CurrentClickRecycleUnit[playerIndex] = btnMap[index - g_RecycleBtnsIndexStart];
    BtnChoiceDialogEventFunc_RecycleUnitDialog(playerName);
end

g_RecycleBtnHandlers = {
    [21] = function(playerName, index)
        RecycleTypeBtnClick(playerName, index);
    end,
    [22] = function(playerName, index)
        RecycleTypeBtnClick(playerName, index);
    end,
    [23] = function(playerName, index)
        RecycleTypeBtnClick(playerName, index);
    end,
    [24] = function(playerName, index)
        RecycleTypeBtnClick(playerName, index);
    end,
    [25] = function(playerName, index)
        RecycleUnitBtnsClear(playerName);
    end
}

ButtonManager:RegisterCustomButtonHandler(function(playerName, index)
    local handled = nil
    if g_RecycleBtnHandlers[index] then
        g_RecycleBtnHandlers[index](playerName, index);
        handled = true
    end
    if index > g_RecycleBtnsIndexStart
        and index <= g_RecycleBtnsIndexStart + g_RecycleBtnsMaxCount then
        RecycleUnitBtnsClick(playerName, index);
        handled = true
    end
    return handled
end)

