-- ============================================================
-- PureDraw: 抽卡模式数据定义
--   - g_PureDrawConfig 抽卡配置（Tier 权重合计必须为 100）
--   - g_PureDrawBuildableUnitPool 显式生产池（按科技 1-4 层）
--   - g_PureDrawProductionAliases 生产别名（强化/水陆形态共用额度）
--   - 状态变量、空投圆形布局、池索引构建
-- ============================================================

-- 纯抽卡模式配置。Tier 权重合计必须为 100。
g_PureDrawConfig = {
    ProductionQuota = 5,
    RefreshRounds = 3,
    CustomDrawChance = 0.50,
    AirdropCheckFrames = 15 * 60,
    -- 空投十连概率：5%。
    AirdropChance = 0.05,
    TierWeights = { 37, 50, 10, 3 },
}

-- 显式生产池：只收录玩家实际生产的战斗单位，排除塔卫、赠送单位和运行时变形别名。
-- Sea 标记供禁海组合使用；IsBigShip 标记用于保留地图原有的大船数量限制。
g_PureDrawBuildableUnitPool = {
    [1] = {
        { Type = "AlliedScoutInfantry" },
        { Type = "AlliedAntiInfantryInfantry" },
        { Type = "AlliedAntiVehicleInfantry" },
        { Type = "AlliedRangerInfantry" },
        { Type = "SovietScoutInfantry" },
        { Type = "SovietAntiInfantryInfantry" },
        { Type = "SovietAntiVehicleInfantry" },
        { Type = "JapanScoutInfantry" },
        { Type = "JapanAntiInfantryInfantry" },
        { Type = "JapanAntiVehicleInfantry" },
        { Type = "JapanArcherInfantry" },
        { Type = "CelestialScoutDrone" },
        { Type = "CelestialAntiInfantryInfantry" },
        { Type = "CelestialAntiVehicleInfantry" },
        { Type = "AlliedAntiInfantryVehicle_Ground" },
        { Type = "AlliedAntiAirVehicleTech1" },
        { Type = "AlliedAntiVehicleVehicleTech1" },
        { Type = "SovietScoutVehicle" },
        { Type = "SovietAntiInfantryVehicle" },
        { Type = "SovietAntiAirShip" }, -- 禁海模式使用的陆地形态仍合法
        { Type = "JapanAntiInfantryVehicle" },
        { Type = "JapanAntiVehicleVehicleTech1" },
        { Type = "JapanAntiAirVehicleTech1" },
        { Type = "CelestialAntiInfantryVehicle_B" },
        { Type = "CelestialAntiAirShip" }, -- 禁海模式使用的陆地形态仍合法
        { Type = "CelestialAntiVehicleVehicleTech1" },
        { Type = "CelestialAntiAirVehicle" },
        { Type = "AlliedAntiGroundAircraft" },
        { Type = "AlliedFighterAircraft" },
        { Type = "SovietAntiGroundAircraft" },
        { Type = "SovietFighterAircraft" },
        { Type = "CelestialFighterAircraft" },
        { Type = "AlliedAntiNavalScout", Sea = true },
        { Type = "AlliedAntiInfantryVehicle", Sea = true },
        { Type = "AlliedAntiAirShip", Sea = true },
        -- 禁海规则下以陆地形态保留，但沿用现有第3回合解锁限制。
        { Type = "SovietAntiNavyShipTech1", NoNavyProductionUnlockRound = 3 },
        { Type = "JapanNavyScoutShip", Sea = true },
        { Type = "JapanAntiAirShip", Sea = true },
        { Type = "CelestialAntiNavyShipTech1", Sea = true },
    },
    [2] = {
        { Type = "AlliedCryoLegionnaire" },
        { Type = "SovietMortarCycle", ProductionUnlockRound = 1 },
        { Type = "SovietHeavyAntiVehicleInfantry" },
        { Type = "JapanInfiltrationInfantry" },
        { Type = "CelestialInfiltrationInfantry" },
        { Type = "CelestialAntiInfantryInfantryAdvanced" },
        { Type = "prismtank" },
        { Type = "SovietHeavyAntiVehicleVehicleTech2" },
        { Type = "SovietSledgehammerSPG" },
        { Type = "SovietAntiVehicleVehicleTech2" },
        { Type = "JapanSentinelVehicle" },
        { Type = "JapanMissileMechaAdvanced" },
        { Type = "JapanInterceptorAircraft" },
        { Type = "CelestialLongRangeMissileVehicle_B" },
        { Type = "AlliedSupportAircraft" },
        { Type = "SovietTransportAircraft" },
        { Type = "CelestialSupportAircraft" },
        { Type = "CelestialAttackerAircraft" },
        { Type = "AlliedAntiNavyShipTech1", Sea = true },
        { Type = "SovietAntiNavyShipTech2", Sea = true },
        { Type = "JapanAntiVehicleShip", Sea = true },
        { Type = "CelestialAlmightlyShip", Sea = true },
    },
    [3] = {
        { Type = "AlliedCommandoTech1" },
        { Type = "SovietCommandoTech1" },
        { Type = "JapanAntiVehicleInfantryTech3" },
        { Type = "JapanCommandoTech1" },
        { Type = "AlliedAntiStructureVehicle" },
        { Type = "AlliedAntiVehicleVehicleTech3" },
        { Type = "SovietAntiStructureVehicle" },
        { Type = "SovietAntiVehicleVehicleTech3" },
        -- SovietGrinderVehicle 未实装。
        { Type = "SovietPineElectronicRadarTruck" },
        { Type = "JapanAntiVehicleVehicleTech3" },
        { Type = "JapanAntiStructureVehicle" },
        { Type = "JapanAntiAirVehicleTech3" },
        { Type = "CelestialAntiVehicleVehicleTech3" },
        { Type = "CelestialHeavyAntiAirVehicleTech3" },
        { Type = "CelestialAntiStructureVehicle" },
        { Type = "CelestialAntiAirVehicleTech3" },
        { Type = "AlliedInterceptorAircraft" },
        { Type = "AlliedAntiStructureBomberAircraft" },
        { Type = "AlliedBomberAircraft" },
        { Type = "SovietInterceptorAircraft" },
        { Type = "SovietAntiGroundAttacker" },
        { Type = "CelestialInterceptorAircraft" },
        { Type = "CelestialBomberAircraft" },
        { Type = "AlliedAntiNavyShipTech3", Sea = true },
        { Type = "SovietAntiNavyShipTech3", Sea = true },
        { Type = "JapanAntiNavyShipTech3", Sea = true },
        { Type = "CelestialAntiNavyShipTech3", Sea = true },
    },
    [4] = {
        { Type = "AlliedFutureTank" },
        { Type = "AlliedBattleFortress" },
        { Type = "AlliedAirForceDispatchVehicle" },
        { Type = "SovietAntiVehicleVehicleTech4" },
        { Type = "JapanMechaX" },
        { Type = "CelestialAntiVehicleVehicleTech4" },
        { Type = "AlliedGunshipAircraft" },
        { Type = "SovietBomberAircraft" },
        { Type = "CelestialAdvanceAircraftTech4", IsYaoguang = true },
        { Type = "JapanGigaFortressShipEgg", Sea = true, IsBigShip = true },
        { Type = "AlliedAntiStructureShip", Sea = true, IsBigShip = true },
        { Type = "SovietAntiStructureShip", Sea = true, IsBigShip = true },
        { Type = "JapanAntiStructureShip", Sea = true, IsBigShip = true },
        { Type = "CelestialAntiStructureShip", Sea = true, IsBigShip = true },
    },
}

-- 这些模板是同一生产按钮产生的强化/环境形态。它们不重复进入抽取池，
-- 但必须共用生产额度，防止协议强化或水陆形态绕过限制。
g_PureDrawProductionAliases = {
    ["AlliedAntiAirShip"] = { "AlliedAntiAirShip_Enhanced" },
    ["AlliedAntiInfantryVehicle"] = { "AlliedAntiInfantryVehicle_Ground", "AlliedAntiInfantryVehicle_Transport" },
    ["AlliedAntiInfantryVehicle_Ground"] = { "AlliedAntiInfantryVehicle" },
    ["AlliedAntiNavyShipTech1"] = { "AlliedAntiNavyShipTech1_Enhanced" },
    ["AlliedAntiNavyShipTech3"] = { "AlliedAntiNavyShipTech3_Enhanced" },
    ["AlliedAntiStructureBomberAircraft"] = { "AlliedAntiStructureBomberAircraft_Enhanced" },
    ["AlliedAntiStructureShip"] = { "AlliedAntiStructureShip_Enhanced" },
    ["AlliedAntiStructureVehicle"] = { "AlliedAntiStructureVehicle_Enhanced" },
    ["AlliedAntiVehicleVehicleTech1"] = { "AlliedAntiVehicleVehicleTech1_Enhanced" },
    ["AlliedAntiVehicleVehicleTech3"] = { "AlliedAntiVehicleVehicleTech3_Enhanced" },
    ["AlliedFighterAircraft"] = { "AlliedFighterAircraft_Enhanced", "AlliedFighterAircraft_WithTrailSomke" },
    ["AlliedGunshipAircraft"] = { "AlliedAC130GunshipAircraft", "AlliedGunshipAircraft_Enhanced" },
    ["AlliedInterceptorAircraft"] = { "AlliedInterceptorAircraft_Enhanced" },
    ["AlliedRangerInfantry"] = { "AlliedRangerInfantry_AirAssault" },
    ["AlliedSupportAircraft"] = { "AlliedSupportAircraft_Enhanced" },
    ["CelestialAdvanceAircraftTech4"] = { "CelestialAdvanceAircraftTech4_Enhanced" },
    ["CelestialAlmightlyShip"] = { "CelestialAlmightlyShip_AA", "CelestialAlmightlyShip_Enhanced", "CelestialAlmightlyShip_FireWork", "CelestialAlmightlyShip_Old" },
    ["CelestialAntiAirShip"] = { "CelestialAntiAirShip_Enhanced", "CelestialAntiAirShip_Enhanced_Water", "CelestialAntiAirShip_Water" },
    ["CelestialAntiInfantryVehicle_B"] = { "CelestialAntiInfantryVehicle" },
    ["CelestialAntiNavyShipTech3"] = { "CelestialAntiNavyShipTech3_EMC", "CelestialAntiNavyShipTech3_Enhanced", "CelestialAntiNavyShipTech3_Firework", "CelestialAntiNavyShipTech3_Old" },
    ["CelestialAntiStructureShip"] = { "CelestialAntiStructureShip_Enhanced", "CelestialAntiStructureShip_Firework", "CelestialAntiStructureShip_Firework_2024A", "CelestialAntiStructureShip_Firework_2024B", "CelestialAntiStructureShip_Firework_2024C", "CelestialAntiStructureShip_Firework_2024D", "CelestialAntiStructureShip_Old" },
    ["CelestialAntiStructureVehicle"] = { "CelestialAntiStructureVehicle_Enhanced" },
    ["CelestialAntiVehicleInfantry"] = { "CelestialAntiVehicleInfantry_EMC" },
    ["CelestialAntiVehicleVehicleTech1"] = { "CelestialAntiVehicleVehicleTech1_EMC" },
    ["CelestialAntiVehicleVehicleTech3"] = { "CelestialAntiVehicleVehicleTech3_EMC" },
    ["CelestialAntiVehicleVehicleTech4"] = { "CelestialAntiVehicleVehicleTech4_Enhanced", "CelestialAntiVehicleVehicleTech4_S01" },
    ["CelestialBomberAircraft"] = { "CelestialBomberAircraft_Enhanced" },
    ["CelestialFighterAircraft"] = { "CelestialFighterAircraft_WithBlueTrailSomke", "CelestialFighterAircraft_WithRedTrailSomke", "CelestialFighterAircraft_WithTrailSomke", "CelestialFighterAircraft_WithWhiteTrailSomke" },
    ["CelestialInfiltrationInfantry"] = { "CelestialInfiltrationInfantry_02", "CelestialInfiltrationInfantry_03", "CelestialInfiltrationInfantry_EMC" },
    ["CelestialInterceptorAircraft"] = { "CelestialInterceptorAircraft_Enhanced" },
    ["CelestialLongRangeMissileVehicle_B"] = { "CelestialLongRangeMissileVehicle" },
    ["JapanAntiAirShip"] = { "JapanAntiAirShip_Enhanced" },
    ["JapanAntiAirVehicleTech1"] = { "JapanAntiAirVehicleTech1_Enhanced", "JapanAntiAirVehicleTech1_Enhanced_Water" },
    ["JapanAntiInfantryVehicle"] = { "JapanAntiInfantryVehicle_Enhanced", "JapanAntiInfantryVehicle_Enhanced_Water" },
    ["JapanAntiNavyShipTech3"] = { "JapanAntiNavyShipTech3_Enhanced" },
    ["JapanAntiStructureShip"] = { "JapanAntiStructureShip_Enhanced" },
    ["JapanAntiStructureVehicle"] = { "JapanAntiStructureVehicle_Enhanced" },
    ["JapanAntiVehicleInfantry"] = { "JapanAntiVehicleInfantry_Ambush" },
    ["JapanAntiVehicleShip"] = { "JapanAntiVehicleShip_Enhanced" },
    ["JapanAntiVehicleVehicleTech1"] = { "JapanAntiVehicleVehicleTech1_Naval" },
    ["JapanAntiVehicleVehicleTech3"] = { "JapanAntiVehicleVehicleTech3_Movie" },
    ["JapanInterceptorAircraft"] = { "JapanInterceptorAircraft_Ground", "JapanInterceptorAircraft_WarfactoryWater" },
    ["JapanMissileMechaAdvanced"] = { "JapanMissileMechaAdvanced_Enhanced", "JapanMissileMechaAdvanced_Enhanced_Water" },
    ["SovietAntiAirShip"] = { "SovietAntiAirShip_Ground" },
    ["SovietAntiGroundAircraft"] = { "SovietAntiGroundAircraft_Enhanced" },
    ["SovietAntiGroundAttacker"] = { "SovietAntiGroundAttacker_Enhanced" },
    ["SovietAntiNavyShipTech1"] = { "SovietAntiNavyShipTech1_AirAssault", "SovietAntiNavyShipTech1_Enhanced" },
    ["SovietAntiNavyShipTech2"] = { "SovietAntiNavyShipTech2_Enhanced" },
    ["SovietAntiStructureShip"] = { "SovietAntiStructureShip_Enhanced" },
    ["SovietAntiStructureVehicle"] = { "SovietAntiStructureVehicle_Enhanced" },
    ["SovietAntiVehicleVehicleTech2"] = { "SovietAntiVehicleVehicleTech2_AirAssault", "SovietAntiVehicleVehicleTech2_Enhanced" },
    ["SovietAntiVehicleVehicleTech3"] = { "SovietAntiVehicleVehicleTech3_Enhanced", "SovietAntiVehicleVehicleTech3_WOT" },
    ["SovietAntiVehicleVehicleTech4"] = { "SovietAntiVehicleVehicleTech4_Enhanced" },
    ["SovietBomberAircraft"] = { "SovietBomberAircraft_Movie" },
    ["SovietFighterAircraft"] = { "SovietFighterAircraft_Enhanced" },
    ["SovietHeavyAntiVehicleInfantry"] = { "SovietHeavyAntiVehicleInfantry_Enhanced" },
    ["SovietHeavyAntiVehicleVehicleTech2"] = { "SovietHeavyAntiVehicleVehicleTech2_Enhanced" },
    ["SovietInterceptorAircraft"] = { "SovietInterceptorAircraft_Enhanced" },
    ["SovietSledgehammerSPG"] = { "SovietSledgehammerSPG_Enhanced" },
    ["SovietTransportAircraft"] = { "SovietTransportAircraft_HeavyCannon" },
    ["prismtank"] = { "AlliedPrismTank_Enhanced" },
}

g_PureDrawBuildableUnitSet = {}
g_PureDrawUnitInfoByHash = {}
g_PureDrawQuota = { 0, 0, 0, 0, 0, 0 }
g_PureDrawTrackedCrates = {}
g_PureDrawTrackedCrateList = {}
g_PureDrawAirdropCrateIds = {}
g_PureDrawScriptCreatedUnitIds = {}
g_PureDrawLastRound = -1
g_PureDrawT4ShipUnlocked = { false, false, false, false, false, false }
g_PureDrawRegisteredProductionHashes = {}
g_PureDrawAirdropSerial = 0
g_PureDrawCustomSpawnSerial = 0

-- 空投十连的圆形布局：i=1 在圆心，其余 9 个均匀分布在圆周上。
-- RA3LuaBridge 方言不保证提供 cos/sin，因此这里直接用预计算的圆上点坐标。
-- 每个元素是 {cos(角度), sin(角度)}，角度从 0 度起每 40 度一个，共 9 个点。
g_PureDrawAirdropCircle = {
    { 1.0, 0.0 },
    { 0.766, 0.6428 },
    { 0.1736, 0.9848 },
    { -0.5, 0.866 },
    { -0.9397, 0.342 },
    { -0.9397, -0.342 },
    { -0.5, -0.866 },
    { 0.1736, -0.9848 },
    { 0.766, -0.6428 },
}

for tier = 1, 4, 1 do
    local pool = g_PureDrawBuildableUnitPool[tier]
    for i = 1, getn(pool), 1 do
        local info = pool[i]
        info.Tier = tier
        g_PureDrawBuildableUnitSet[info.Type] = true
        g_PureDrawBuildableUnitSet[FastHash(info.Type)] = true
        g_PureDrawUnitInfoByHash[FastHash(info.Type)] = info
        local aliases = g_PureDrawProductionAliases[info.Type]
        if aliases ~= nil then
            for aliasIndex = 1, getn(aliases), 1 do
                local aliasType = aliases[aliasIndex]
                g_PureDrawBuildableUnitSet[aliasType] = true
                g_PureDrawBuildableUnitSet[FastHash(aliasType)] = true
                g_PureDrawUnitInfoByHash[FastHash(aliasType)] = info
            end
        end
    end
end
