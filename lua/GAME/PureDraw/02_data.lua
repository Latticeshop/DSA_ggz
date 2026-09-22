-- PureDraw: 抽卡模式数据定义
--   - g_PureDrawConfig 抽卡配置（Tier 权重合计必须为 100）
--   - g_PureDrawBuildableUnitPool 显式生产池（按科技 1-4 层）
--   - g_PureDrawProductionAliases 生产别名（强化/水陆形态共用额度）
--   - 状态变量、空投阵型、池索引构建

-- 纯抽卡模式配置。Tier 权重合计必须为 100。
g_PureDrawConfig = {
    ProductionQuota = 5,
    RefreshRounds = 3,
    CustomDrawChance = 0.50,
    AirdropCheckFrames = 15 * 60,
    AirdropUnitScanFrames = 15 * 5,
    AirdropUnitScanInterval = 2,
    -- 每次空投检查有 5% 概率触发十连。
    AirdropChance = 0.05,
    TierWeights = { 37, 50, 10, 3 },
}

-- 显式生产池：只收录玩家实际生产的战斗单位，排除塔卫、赠送单位和运行时变形别名。
-- Sea 标记供禁海组合使用；IsBigShip 标记用于保留地图原有的大船数量限制。
g_PureDrawBuildableUnitPool = {
    [1] = {
        { Type = "AlliedScoutInfantry", CustomDrawCount = 5 },
        { Type = "AlliedAntiInfantryInfantry", CustomDrawCount = 5 },
        { Type = "AlliedAntiVehicleInfantry", CustomDrawCount = 5 },
        { Type = "AlliedRangerInfantry", CustomDrawCount = 5 },
        { Type = "SovietScoutInfantry", CustomDrawCount = 5 },
        { Type = "SovietAntiInfantryInfantry", CustomDrawCount = 5 },
        { Type = "SovietAntiVehicleInfantry", CustomDrawCount = 5 },
        { Type = "JapanScoutInfantry", CustomDrawCount = 5 },
        { Type = "JapanAntiInfantryInfantry", CustomDrawCount = 5 },
        { Type = "JapanAntiVehicleInfantry", CustomDrawCount = 5 },
        { Type = "JapanArcherInfantry", CustomDrawCount = 5 },
        { Type = "CelestialScoutDrone", CustomDrawCount = 5 },
        { Type = "CelestialAntiInfantryInfantry", CustomDrawCount = 5 },
        { Type = "CelestialAntiVehicleInfantry", CustomDrawCount = 5 },
        { Type = "AlliedAntiInfantryVehicle_Ground", CustomDrawCount = 4 },
        { Type = "AlliedAntiAirVehicleTech1", CustomDrawCount = 4 },
        { Type = "AlliedAntiVehicleVehicleTech1", CustomDrawCount = 3 },
        { Type = "SovietScoutVehicle", CustomDrawCount = 5 },
        { Type = "SovietAntiInfantryVehicle", CustomDrawCount = 3 },
        { Type = "SovietAntiAirShip", CustomDrawCount = 3 }, -- 禁海模式使用的陆地形态仍合法
        { Type = "JapanAntiInfantryVehicle", CustomDrawCount = 4 },
        { Type = "JapanAntiVehicleVehicleTech1", CustomDrawCount = 2 },
        { Type = "JapanAntiAirVehicleTech1", CustomDrawCount = 2 },
        { Type = "CelestialAntiInfantryVehicle_B", CustomDrawCount = 3 },
        { Type = "CelestialAntiAirShip", CustomDrawCount = 3 }, -- 禁海模式使用的陆地形态仍合法
        { Type = "CelestialAntiVehicleVehicleTech1", CustomDrawCount = 3 },
        { Type = "CelestialAntiAirVehicle", CustomDrawCount = 3 },
        { Type = "AlliedAntiGroundAircraft", CustomDrawCount = 2 },
        { Type = "AlliedFighterAircraft", CustomDrawCount = 3 },
        { Type = "SovietAntiGroundAircraft", CustomDrawCount = 2 },
        { Type = "SovietFighterAircraft", CustomDrawCount = 3 },
        { Type = "CelestialFighterAircraft", CustomDrawCount = 3 },
        { Type = "AlliedAntiNavalScout", CustomDrawCount = 4, Sea = true },
        { Type = "AlliedAntiInfantryVehicle", CustomDrawCount = 4, Sea = true },
        { Type = "AlliedAntiAirShip", CustomDrawCount = 3, Sea = true },
        -- 禁海规则下以陆地形态保留，但沿用现有第3回合解锁限制。
        { Type = "SovietAntiNavyShipTech1", CustomDrawCount = 3, NoNavyProductionUnlockRound = 3 },
        { Type = "JapanNavyScoutShip", CustomDrawCount = 4, Sea = true },
        { Type = "JapanAntiAirShip", CustomDrawCount = 2, Sea = true },
        { Type = "CelestialAntiNavyShipTech1", CustomDrawCount = 4, Sea = true },
    },
    [2] = {
        { Type = "AlliedCryoLegionnaire", CustomDrawCount = 2 },
        { Type = "SovietMortarCycle", CustomDrawCount = 4, ProductionUnlockRound = 1 },
        { Type = "SovietHeavyAntiVehicleInfantry", CustomDrawCount = 3 },
        { Type = "JapanInfiltrationInfantry", CustomDrawCount = 3 },
        { Type = "CelestialInfiltrationInfantry", CustomDrawCount = 3 },
        { Type = "CelestialAntiInfantryInfantryAdvanced", CustomDrawCount = 2 },
        { Type = "prismtank", CustomDrawCount = 2 },
        { Type = "SovietHeavyAntiVehicleVehicleTech2", CustomDrawCount = 2 },
        { Type = "SovietSledgehammerSPG", CustomDrawCount = 2 },
        { Type = "SovietAntiVehicleVehicleTech2", CustomDrawCount = 2 },
        { Type = "JapanSentinelVehicle", CustomDrawCount = 2 },
        { Type = "JapanMissileMechaAdvanced", CustomDrawCount = 2 },
        { Type = "JapanInterceptorAircraft", CustomDrawCount = 3 },
        { Type = "CelestialLongRangeMissileVehicle_B", CustomDrawCount = 2 },
        { Type = "AlliedSupportAircraft", CustomDrawCount = 2 },
        { Type = "SovietTransportAircraft" },
        { Type = "CelestialSupportAircraft", CustomDrawCount = 2 },
        { Type = "CelestialAttackerAircraft", CustomDrawCount = 2 },
        { Type = "AlliedAntiNavyShipTech1", Sea = true },
        { Type = "SovietAntiNavyShipTech2", Sea = true },
        { Type = "JapanAntiVehicleShip", Sea = true },
        { Type = "CelestialAlmightlyShip", Sea = true },
    },
    [3] = {
        { Type = "AlliedCommandoTech1" },
        { Type = "SovietCommandoTech1" },
        { Type = "JapanAntiVehicleInfantryTech3", CustomDrawCount = 3 },
        { Type = "JapanCommandoTech1" },
        { Type = "AlliedAntiStructureVehicle" },
        { Type = "AlliedAntiVehicleVehicleTech3", CustomDrawCount = 2 },
        { Type = "SovietAntiStructureVehicle" },
        { Type = "SovietAntiVehicleVehicleTech3" },
        { Type = "JapanAntiVehicleVehicleTech3" },
        { Type = "JapanAntiStructureVehicle" },
        { Type = "CelestialAntiVehicleVehicleTech3" },
        { Type = "CelestialHeavyAntiAirVehicleTech3" },
        { Type = "CelestialAntiStructureVehicle" },
        { Type = "AlliedInterceptorAircraft", CustomDrawCount = 2 },
        { Type = "AlliedAntiStructureBomberAircraft" },
        { Type = "AlliedBomberAircraft" },
        { Type = "SovietInterceptorAircraft", CustomDrawCount = 2 },
        { Type = "SovietAntiGroundAttacker" },
        { Type = "CelestialInterceptorAircraft", CustomDrawCount = 2 },
        { Type = "CelestialBomberAircraft" },
        { Type = "AlliedAntiNavyShipTech3", Sea = true },
        { Type = "SovietAntiNavyShipTech3", Sea = true },
        { Type = "JapanAntiNavyShipTech3", Sea = true },
        { Type = "CelestialAntiNavyShipTech3", Sea = true },
    },
    [4] = {
        { Type = "AlliedFutureTank" },
        { Type = "AlliedBattleFortress" },
        { Type = "SovietAntiVehicleVehicleTech4" },
        { Type = "JapanMechaX" },
        { Type = "CelestialAntiVehicleVehicleTech4" },
        { Type = "AlliedGunshipAircraft" },
        { Type = "SovietBomberAircraft" },
        { Type = "CelestialAdvanceAircraftTech4", IsYaoguang = true,
            LockPlayerProduction = true },
        { Type = "JapanGigaFortressShipEgg", Sea = true, IsBigShip = true,
            LockPlayerProduction = true },
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
    ["JapanMechaX"] = { "JapanKingOniXMecha_Enhanced" },
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
-- 本局实际成功生成过的空投落点。AI 箱子结果的入队识别只检查这里，避免把
-- 尚未抽中的阵型点也算作有效空投区域。
g_PureDrawActiveAirdropPoints = {}
g_PureDrawScriptCreatedUnitIds = {}
-- 玩家单位登记：值为本模式分配的独立流水号。无生产者的新单位先进入观察队列，
-- 只有确认不是某个已摧毁箱子的原生结果后才会登记。
g_PureDrawKnownPlayerUnitIds = {}
g_PureDrawKnownPlayerUnitSerial = 0
g_PureDrawPendingNativeResultIds = {}
-- 已确认由玩家生产且成功消耗余额的单位。周期回收时据此排除 producer 异常为空的生产单位。
g_PureDrawProducedUnitIds = {}
g_PureDrawLastRound = -1
g_PureDrawT4ShipUnlocked = { false, false, false, false, false, false }
g_PureDrawRegisteredProductionHashes = {}
g_PureDrawAirdropSerial = 0
g_PureDrawCustomSpawnSerial = 0

-- 这些单位不会进入常规战斗单位回收，但仍必须登记，避免被当成箱子结果。
g_PureDrawAlwaysKnownUnitHashes = {}
g_PureDrawObservedPlayerUnitHashes = {}
g_PureDrawAlwaysKnownUnitTypes = {
    "AlliedEngineer", "SovietEngineer", "JapanEngineer", "CelestialEngineer",
    "AlliedMCV", "AlliedMCV_Enhanced", "AlliedMCV_Naval", "AlliedMCV_Enhanced_Naval",
    "SovietMCV", "SovietMCV_Enhanced", "SovietMCV_Naval", "SovietMCV_Enhanced_Naval",
    "JapanMCV", "JapanMCV_Enhanced", "JapanMCV_Naval", "JapanMCV_Enhanced_Naval",
    "CelestialMCV", "CelestialMCV_Enhanced", "CelestialMCV_Ground", "CelestialMCV_Naval",
    "CelestialMCV_Air", "CelestialMCV_Enhanced_Ground", "CelestialMCV_Enhanced_Naval",
    "CelestialMCV_Enhanced_Air",
}
for i = 1, getn(g_PureDrawAlwaysKnownUnitTypes), 1 do
    local unitHash = FastHash(g_PureDrawAlwaysKnownUnitTypes[i])
    g_PureDrawAlwaysKnownUnitHashes[unitHash] = true
    g_PureDrawObservedPlayerUnitHashes[unitHash] = true
end

-- 工程师不允许作为抽卡结果：若原版箱子开出工程师，一律强制转成自定义抽卡。
-- 玩家自造工程师仍按常规 AlwaysKnown 处理（有生产者，登记为已知单位）。
g_PureDrawNativeEngineerHashes = {
    [FastHash("AlliedEngineer")] = true,
    [FastHash("SovietEngineer")] = true,
    [FastHash("JapanEngineer")] = true,
    [FastHash("CelestialEngineer")] = true,
}

-- 空投十连阵型。每个阵型都直接保存相对战场中心的 {X, Y} 偏移；生成箱子和
-- 后续空投单位检测共用这份数据，避免增加阵型后两处坐标不同步。
g_PureDrawAirdropFormations = {
    -- 圆圈：圆心 1 个，半径 140 的圆周上均匀分布 9 个。
    {
        { 0, 0 },
        { 140, 0 },
        { 107.24, 89.99 },
        { 24.30, 137.87 },
        { -70, 121.24 },
        { -131.56, 47.88 },
        { -131.56, -47.88 },
        { -70, -121.24 },
        { 24.30, -137.87 },
        { 107.24, -89.99 },
    },
    -- 两边各 5 个：左右两列对称排列，中间留出争夺空间。
    {
        { -180, -160 }, { -180, -80 }, { -180, 0 }, { -180, 80 }, { -180, 160 },
        { 180, -160 }, { 180, -80 }, { 180, 0 }, { 180, 80 }, { 180, 160 },
    },
    -- 对称棱形：十个点沿棱形外框左右、上下完全对称。
    {
        { 0, -210 },
        { -70, -140 }, { 70, -140 },
        { -140, -70 }, { 140, -70 },
        { -140, 70 }, { 140, 70 },
        { -70, 140 }, { 70, 140 },
        { 0, 210 },
    },
    -- 五角星：外圈五点、内圈五点，内外顶点交错。
    {
        { 0, -210 },
        { 52.90, -72.81 },
        { 199.72, -64.89 },
        { 85.60, 27.81 },
        { 123.43, 169.89 },
        { 0, 90 },
        { -123.43, 169.89 },
        { -85.60, 27.81 },
        { -199.72, -64.89 },
        { -52.90, -72.81 },
    },
    -- X 形：四条斜向臂各两点，中央再放一对近心点，避免箱子重叠。
    {
        { -200, -200 }, { -100, -100 },
        { 100, 100 }, { 200, 200 },
        { -200, 200 }, { -100, 100 },
        { 100, -100 }, { 200, -200 },
        { -35, 0 }, { 35, 0 },
    },
    -- 同心图形：外六边形六点、内菱形四点。
    {
        { 210, 0 }, { 105, 181.87 }, { -105, 181.87 },
        { -210, 0 }, { -105, -181.87 }, { 105, -181.87 },
        { 0, -85 }, { 85, 0 }, { 0, 85 }, { -85, 0 },
    },
    -- 正十边形：十个点均匀分布在半径 210 的圆周上，无中心箱。
    {
        { 0, -210 }, { 123.43, -169.89 },
        { 199.72, -64.89 }, { 199.72, 64.89 },
        { 123.43, 169.89 }, { 0, 210 },
        { -123.43, 169.89 }, { -199.72, 64.89 },
        { -199.72, -64.89 }, { -123.43, -169.89 },
    },
    -- 螺旋对称：外圈五点和内圈五点错开 36 度，内圈半径更大于五角星。
    {
        { 0, -210 }, { 199.72, -64.89 }, { 123.43, 169.89 },
        { -123.43, 169.89 }, { -199.72, -64.89 },
        { 79.03, -108.92 }, { 128.39, 41.72 }, { 0, 135 },
        { -128.39, 41.72 }, { -79.03, -108.92 },
    },
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
