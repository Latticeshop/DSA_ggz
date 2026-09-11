-- 启用箱子模式：确保箱子技能可用，每个玩家送一个迅雷
-- 目前由 GiveFreeStructure__2 启用
if not g_SuperSpeedModifier then
    g_SuperSpeedModifier = exAttributeModifierCreate({ SPEED = 8.0 }, 1)
end

-- 工程师保留在玩家家中，不进入 UNITLIST/自走棋对战池；四阵营工程师统一获得抽卡工程师的加速。
function PlayerEngineerBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    SchedulerModule.delay_call(function(id)
        if ObjectIsAlive(id) then
            ObjectLoadAttributeModifier(GetObjectById(id), g_SuperSpeedModifier)
        end
    end, 1, {createdObjId})
end

g_PlayerEngineerTypes = {
    "AlliedEngineer",
    "SovietEngineer",
    "JapanEngineer",
    "CelestialEngineer",
}
for i = 1, getn(g_PlayerEngineerTypes), 1 do
    local engineerType = g_PlayerEngineerTypes[i]
    exObjectRegisterCreateEvent(engineerType)
    g_UnitCreateEventFunc[FastHash(engineerType)] = PlayerEngineerBorn
end

-- 只有抽卡模式允许玩家从生产栏建造工程师；其他模式保持按钮禁用。
function SetPlayerEngineerProductionAvailability(enable)
    local availability = 0
    if enable and enable ~= 0 then
        availability = 1
    end
    for i = 1, 6, 1 do
        local playerName = "Player_" .. i
        for j = 1, getn(g_PlayerEngineerTypes), 1 do
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, g_PlayerEngineerTypes[j], availability)
        end
    end
end

function TryEnableLuckyCrateIfAllowed()
    local previous = SetWorldBuilderThisPlayer(1)
    SetPlayerEngineerProductionAvailability(g_LuckyCrateMode)
    local EnableLuckyCrateImplementation = function(enable)
        if not enable or enable == 0 then
            return
        end
        if g_LuckyCreateEnableComplete then
            return
        end
        g_LuckyCreateEnableComplete = 1
        ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", "SpecialPower_LuckyUnitCrate", "<All Human Players>")
        ExecuteAction("PLAYER_GRANT_SPECIAL_POWER", "SpecialPower_LuckyUnitCrateX10", "<All Human Players>")
        for i = 1, 6, 1 do
            local playerName = "Player_" .. i
            local isHuman = EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", playerName, "Human")
            if isHuman then
                local p = exWaypointGetPos(format("Player_%d_Start", i))
                local offsetX = 200
                local position = { X = p[1] + offsetX, Y = p[2], Z = p[3] }
                local nextObjectId = GetNextObjectId()
                ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
                    "",
                    "JapanEngineer",
                    format("%s/crate", playerName),
                    position, 
                    0
                )
                TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", GetObjectById(nextObjectId), "SCRIPT:CrateEnabled", 120, "")
            end
        end
    end
    EnableLuckyCrateImplementation(g_LuckyCrateMode)
    SetWorldBuilderThisPlayer(previous)
end

-- 箱子里开出来的要塞也和要塞核心一起计算
exObjectRegisterCreateEvent("JapanFortressShip")
exObjectRegisterCreateEvent("JapanGigaFortress_Land")
function CountAsFortressShipEgg(createdObjId, createdObjInstanceId, ownerPlayerName)
    return UnitCountFunc(createdObjId, FastHash("JapanGigaFortressShipEgg"), ownerPlayerName)
end
g_UnitCreateEventFunc[FastHash("JapanFortressShip")] = CountAsFortressShipEgg
g_UnitCreateEventFunc[FastHash("JapanGigaFortress_Land")] = CountAsFortressShipEgg

-- 箱子里开出来的航母 / 战列舰有存活时间
exObjectRegisterCreateEvent("AlliedGaintAirCraftCarrier_B")
exObjectRegisterCreateEvent("AlliedThetisBattleShip")
exObjectRegisterCreateEvent("JapanYumiAircraftCarrier")
function SetCrateShipLifetime(createdObjId, createdObjInstanceId, ownerPlayerName)
    if ownerPlayerName ~= "PlyrCreeps"
        and ownerPlayerName ~= "PlyrCivilian" then
        return
    end
    local lifetime = 2
    if createdObjInstanceId == FastHash("AlliedGaintAirCraftCarrier_B") then
        lifetime = 1
    end
    RoundLuaManager.DelayCallOnRoundBegin(function(id)
        if not ObjectIsAlive(id) then
            return
        end
        ExecuteAction("NAMED_KILL", GetObjectById(id))
    end, { createdObjId }, lifetime)
end
g_UnitCreateEventFunc[FastHash("AlliedGaintAirCraftCarrier_B")] = SetCrateShipLifetime
g_UnitCreateEventFunc[FastHash("AlliedThetisBattleShip")] = SetCrateShipLifetime
g_UnitCreateEventFunc[FastHash("JapanYumiAircraftCarrier")] = SetCrateShipLifetime

-- 箱子里开出来的龙船禁止攻击
exObjectRegisterCreateEvent("CelestialMCV")
function DisableCrateDragonAttack(createdObjId, createdObjInstanceId, ownerPlayerName)
    Scheduler.delay_call(function(id)
        if not ObjectIsAlive(id) then
            return
        end
        ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", GetObjectById(id), "NO_ATTACK", 1)
    end, 1, { createdObjId })
end
g_UnitCreateEventFunc[FastHash("CelestialMCV")] = DisableCrateDragonAttack

-- 纯抽卡模式配置。Tier 权重合计必须为 100。
g_PureDrawConfig = {
    ProductionQuota = 5,
    RefreshRounds = 3,
    CustomDrawChance = 0.50,
    AirdropCheckFrames = 15 * 60,
    -- 测试阶段暂设为二分之一，功能稳定后再恢复正式概率。
    AirdropChance = 0.50,
    TierWeights = { 37, 50, 10, 3 },
    DebugAlerts = true,
}

function PureDrawDebug(message)
    if g_PureDrawConfig.DebugAlerts then
        _ALERT("[PureDraw] " .. tostring(message))
    end
end

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
        { Type = "SovietGrinderVehicle" },
        { Type = "SovietElectronicRadarTruck" },
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

function PureDrawIsHumanPlayer(playerIndex)
    return EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", "Player_" .. playerIndex, "Human")
end

function PureDrawGetQuotaDisplayDirection(playerIndex)
    local playerPosition = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local startXTotal = 0
    for i = 1, 6, 1 do
        local startPosition = exWaypointGetPos(format("Player_%d_Start", i))
        startXTotal = startXTotal + startPosition[1]
    end
    -- 左侧出生点的海岸在基地左边，因此余额展示统一放到基地右侧。
    if playerPosition[1] < startXTotal / 6 then
        return 1
    end
    return -1
end

function PureDrawSpawnQuotaWall(playerIndex, slot)
    if not PureDrawIsHumanPlayer(playerIndex) then
        return
    end
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = PureDrawGetQuotaDisplayDirection(playerIndex)
    local name = format("PureDrawQuota_%d_%d", playerIndex, slot)
    ExecuteAction("NAMED_DELETE", name)
    -- AlliedWallPiece 使用公告等待阶段已经验证过的生成通道：先在现有投票路径点创建，
    -- 再移动到基地旁。不要占用 Player_N 名称，否则会破坏原有的阅读完成判定。
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", name, "AlliedWallPiece",
        "PlyrCreeps/teamPlyrCreeps", "toupiaodian" .. playerIndex)
    local wall = GetObjectByScriptName(name)
    if wall ~= nil then
        ObjectSetPosition(wall,
            p[1] + direction * 260,
            p[2] + (slot - 3) * 38,
            p[3])
        ExecuteAction("UNIT_AFFECT_OBJECT_PANEL_FLAGS", wall, "Indestructible", true)
        PureDrawDebug("quota wall created: " .. name)
    else
        PureDrawDebug("ERROR quota wall was not created: " .. name)
    end
end

function PureDrawCreateQuotaDisplay(playerIndex)
    for slot = 1, g_PureDrawConfig.ProductionQuota, 1 do
        ExecuteAction("NAMED_DELETE", format("PureDrawQuota_%d_%d", playerIndex, slot))
        if slot <= g_PureDrawQuota[playerIndex] then
            PureDrawSpawnQuotaWall(playerIndex, slot)
        end
    end
    if not PureDrawIsHumanPlayer(playerIndex) then
        return
    end
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = PureDrawGetQuotaDisplayDirection(playerIndex)
    local labelName = format("PureDrawQuotaLabel_%d", playerIndex)
    ExecuteAction("NAMED_DELETE", labelName)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", labelName, "MultiplayerBeacon",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex), {
            X = p[1] + direction * 320,
            Y = p[2],
            Z = p[3],
        }, 0)
    TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", labelName, "SCRIPT:PureDrawQuota", 0, "")
end

function PureDrawCanEnableUnit(playerIndex, info)
    if g_DisableSeaArmy == 1 and info.Sea then
        return false
    end
    local round = exCounterGetByName("lvc") or 0
    if info.ProductionUnlockRound ~= nil and round < info.ProductionUnlockRound then
        return false
    end
    if g_DisableSeaArmy == 1 and info.NoNavyProductionUnlockRound ~= nil
        and round < info.NoNavyProductionUnlockRound then
        return false
    end
    if info.IsBigShip then
        if not g_PureDrawT4ShipUnlocked[playerIndex] then
            return false
        end
        if info.Type ~= "JapanGigaFortressShipEgg"
            and exCounterGetByName("bigshiplimit" .. playerIndex) >= 2 then
            return false
        end
    end
    if info.IsYaoguang and GetPlayerYaoguangCount ~= nil and YAOGUANG_LIMIT ~= nil
        and GetPlayerYaoguangCount(playerIndex) >= YAOGUANG_LIMIT then
        return false
    end
    return true
end

function PureDrawSetPlayerBuildability(playerIndex, enable)
    local playerName = "Player_" .. playerIndex
    local disallowedHashes = {}
    for tier = 1, 4, 1 do
        local pool = g_PureDrawBuildableUnitPool[tier]
        for i = 1, getn(pool), 1 do
            local info = pool[i]
            local availability = false
            if enable and PureDrawCanEnableUnit(playerIndex, info) then
                availability = true
            end
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, info.Type, availability)
            local aliases = g_PureDrawProductionAliases[info.Type]
            if aliases ~= nil then
                for aliasIndex = 1, getn(aliases), 1 do
                    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, aliases[aliasIndex], availability)
                end
            end
            if not availability then
                disallowedHashes[tostring(FastHash(info.Type))] = true
                if aliases ~= nil then
                    for aliasIndex = 1, getn(aliases), 1 do
                        disallowedHashes[tostring(FastHash(aliases[aliasIndex]))] = true
                    end
                end
            end
        end
    end
    if not enable and RescueBlockedProductions_DoRescue ~= nil then
        RescueBlockedProductions_DoRescue(playerName, disallowedHashes)
    end
end

function PureDrawRefreshQuota(playerIndex)
    g_PureDrawQuota[playerIndex] = g_PureDrawConfig.ProductionQuota
    PureDrawSetPlayerBuildability(playerIndex, true)
    PureDrawCreateQuotaDisplay(playerIndex)
    if PureDrawIsHumanPlayer(playerIndex) then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("pure_draw.quota.refreshed", g_PureDrawQuota[playerIndex]), 8)
    end
end

function PureDrawGetBuildCost(createdObjInstanceId)
    local info = g_PureDrawUnitInfoByHash[createdObjInstanceId]
    if info == nil then
        return 0
    end
    for faction = 1, 4, 1 do
        for category = 1, 4, 1 do
            local units = g_RecycleBtnsMapByFaction[faction][category]
            for i = 1, getn(units), 1 do
                if units[i].Type == info.Type then
                    return units[i].Money or 0
                end
            end
        end
    end
    return 0
end

function PureDrawTryConsumeProductionQuota(createdObjId, createdObjInstanceId,
    playerIndex, ownerPlayerName, retriesLeft)
    if not ObjectIsAlive(createdObjId) or g_DrawMode ~= 2 then
        return
    end
    local producer = ObjectGetProducerObject(createdObjId)
    if producer == nil then
        -- 无生产者的单位（箱子结果/赠送/凭空出现）不消耗生产余额。
        if retriesLeft > 0 then
            SchedulerModule.delay_call(PureDrawTryConsumeProductionQuota, 1, {
                createdObjId, createdObjInstanceId, playerIndex, ownerPlayerName, retriesLeft - 1
            })
            return
        end
        PureDrawDebug("orphan unit skip quota id=" .. tostring(createdObjId)
            .. ", typeHash=" .. tostring(createdObjInstanceId)
            .. ", owner=" .. tostring(ownerPlayerName))
        return
    end
    local oldQuota = g_PureDrawQuota[playerIndex] or 0
    PureDrawDebug("produced unit detected id=" .. tostring(createdObjId)
        .. ", typeHash=" .. tostring(createdObjInstanceId)
        .. ", owner=" .. tostring(ownerPlayerName)
        .. ", oldQuota=" .. tostring(oldQuota))
    if oldQuota <= 0 then
        local refund = PureDrawGetBuildCost(createdObjInstanceId)
        ExecuteAction("NAMED_DELETE", GetObjectById(createdObjId))
        if refund > 0 then
            ExecuteAction("PLAYER_GIVE_MONEY", ownerPlayerName, refund)
        end
        exAddTextToPublicBoardForPlayer(ownerPlayerName,
            Localization.get("pure_draw.quota.exceeded", refund), 6)
        return
    end
    g_PureDrawQuota[playerIndex] = oldQuota - 1
    ExecuteAction("NAMED_DELETE", format("PureDrawQuota_%d_%d", playerIndex, oldQuota))
    exAddTextToPublicBoardForPlayer(ownerPlayerName,
        Localization.get("pure_draw.quota.remaining", g_PureDrawQuota[playerIndex]), 5)
    if g_PureDrawQuota[playerIndex] <= 0 then
        PureDrawSetPlayerBuildability(playerIndex, false)
    end
end

-- 玩家碰箱子后引擎生成的原生单位没有生产者（ObjectGetProducerObject 返回 nil），
-- 而正常从生产建筑序列产出的单位一定有生产者。因此：
-- 有生产者 -> 玩家生产 -> 消耗生产余额；
-- 无生产者（凭空出现：箱子结果、赠送单位）-> 不消耗余额；
-- 若该凭空单位匹配到“刚消失的被跟踪箱子”，则拦截并换成自定义抽卡单位。
function PureDrawOnBuildableUnitBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
    if g_DrawMode ~= 2 or playerIndex == nil then
        return
    end
    if g_PureDrawScriptCreatedUnitIds[createdObjId] then
        g_PureDrawScriptCreatedUnitIds[createdObjId] = nil
        PureDrawDebug("script-created draw unit bypassed quota id=" .. tostring(createdObjId))
        return
    end
    local producer = ObjectGetProducerObject(createdObjId)
    if producer == nil then
        -- 凭空出现的玩家单位：不消耗余额。若匹配到刚消失的被跟踪箱子，则拦截。
        PureDrawDebug("orphan player unit id=" .. tostring(createdObjId)
            .. ", typeHash=" .. tostring(createdObjInstanceId)
            .. ", owner=" .. tostring(ownerPlayerName))
        local consumedCrateId = PureDrawFindConsumedTrackedCrate()
        if consumedCrateId ~= nil then
            local x, y, z = ObjectGetPosition(createdObjId)
            PureDrawRemoveTrackedCrate(consumedCrateId)
            g_PureDrawScriptCreatedUnitIds[createdObjId] = true
            PureDrawDebug("custom draw intercepted: player=" .. tostring(ownerPlayerName))
            SchedulerModule.delay_call(PureDrawInterceptNativeResult, 1,
                { createdObjId, ownerPlayerName, x, y, z })
        end
        return
    end
    PureDrawDebug("buildable unit birth event id=" .. tostring(createdObjId)
        .. ", typeHash=" .. tostring(createdObjInstanceId)
        .. ", owner=" .. tostring(ownerPlayerName))
    PureDrawTryConsumeProductionQuota(createdObjId, createdObjInstanceId,
        playerIndex, ownerPlayerName, 3)
end

-- 查找该玩家“刚消失（被碰/消耗）”的跟踪箱子。只按箱子是否已死匹配，
-- 不依赖生成位置（引擎可能在玩家基地等位置生成箱子结果单位）。
-- DiedFrame 尚未记录时（原生结果单位先于下一帧的跟踪回调创建）按“刚消失”处理，
-- 优先返回。超过 60 帧未清理的过期箱子会由 CleanupTrackedCrate 移除，因此
-- 列表里“已死”的箱子都是近期消失的。
function PureDrawFindConsumedTrackedCrate()
    local now = GetFrame()
    local bestId, bestAge = nil, 1e9
    for i = 1, getn(g_PureDrawTrackedCrateList), 1 do
        local tid = g_PureDrawTrackedCrateList[i]
        local state = g_PureDrawTrackedCrates[tid]
        if state ~= nil and not ObjectIsAlive(tid) then
            local age
            if state.DiedFrame ~= nil then
                age = now - state.DiedFrame
            else
                age = 0
            end
            if age < bestAge then
                bestAge = age
                bestId = tid
            end
        end
    end
    return bestId
end

for tier = 1, 4, 1 do
    local pool = g_PureDrawBuildableUnitPool[tier]
    for i = 1, getn(pool), 1 do
        local unitHash = FastHash(pool[i].Type)
        if not g_PureDrawRegisteredProductionHashes[unitHash] then
            RegisterUnitCreateCallback(pool[i].Type, PureDrawOnBuildableUnitBorn)
            g_PureDrawRegisteredProductionHashes[unitHash] = true
        end
        local aliases = g_PureDrawProductionAliases[pool[i].Type]
        if aliases ~= nil then
            for aliasIndex = 1, getn(aliases), 1 do
                local aliasHash = FastHash(aliases[aliasIndex])
                if not g_PureDrawRegisteredProductionHashes[aliasHash] then
                    RegisterUnitCreateCallback(aliases[aliasIndex], PureDrawOnBuildableUnitBorn)
                    g_PureDrawRegisteredProductionHashes[aliasHash] = true
                end
            end
        end
    end
end

function PureDrawChooseWeightedUnit()
    local roll = GetRandomNumber() * 100
    local cumulative = 0
    local selectedTier = 4
    for tier = 1, 4, 1 do
        cumulative = cumulative + g_PureDrawConfig.TierWeights[tier]
        if roll < cumulative then
            selectedTier = tier
            break
        end
    end
    local source = g_PureDrawBuildableUnitPool[selectedTier]
    local eligible = {}
    for i = 1, getn(source), 1 do
        if g_DisableSeaArmy ~= 1 or not source[i].Sea then
            tinsert(eligible, source[i])
        end
    end
    local index = floor(GetRandomNumber() * getn(eligible)) + 1
    if index > getn(eligible) then
        index = getn(eligible)
    end
    return eligible[index]
end

function PureDrawSpawnCustomUnit(playerName, x, y, z)
    local info = PureDrawChooseWeightedUnit()
    if info == nil then
        return
    end
    g_PureDrawCustomSpawnSerial = g_PureDrawCustomSpawnSerial + 1
    local unitName = format("PureDrawCustom_%d", g_PureDrawCustomSpawnSerial)
    local nextObjectId = GetNextObjectId()
    g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", unitName, info.Type,
        format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
    local unit = GetObjectByScriptName(unitName)
    if not ObjectIsAlive(unit) then
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = nil
        PureDrawDebug("ERROR custom draw unit failed to spawn: " .. info.Type)
        return
    end
    local actualId = ObjectGetId(unit)
    if actualId ~= nextObjectId then
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = nil
        g_PureDrawScriptCreatedUnitIds[actualId] = true
    end
    PureDrawDebug("custom draw spawned " .. info.Type .. " for " .. playerName
        .. ", tier=" .. tostring(info.Tier)
        .. ", id=" .. tostring(actualId))
    exAddTextToPublicBoardForPlayer(playerName,
        Localization.get("pure_draw.custom_result", info.Tier), 5)
end

g_PureDrawCollectorFilter = CreateObjectFilter({
    Include = "SELECTABLE",
    Exclude = "STRUCTURE",
    -- 箱子本身不能作为“拾取者”被检测到（幸运箱子由技能创建时可能属于玩家）。
    ExcludeThing = {
        "LuckyUnitCrateSeed",
        "UnitCrateNew",
        "UnitCrate",
    },
})

function PureDrawFindCollector(x, y, z, radius)
    local units, count = ObjectFindObjects(nil, {
        X = x, Y = y, Z = z, Radius = radius or 80, DistType = "CENTER_2D"
    }, g_PureDrawCollectorFilter)
    for i = 1, count, 1 do
        local playerName = ObjectPlayerScriptName(units[i])
        if g_PlayerNameToIndex[playerName] ~= nil then
            return playerName
        end
    end
    return nil
end

function PureDrawDeleteNativeResultNear(x, y, z)
    if g_PureDrawNativeResultFilter == nil then
        local nativeTypes = {}
        for crateType = 1, 4, 1 do
            local source = g_CrateUnitsTemplate[crateType]
            for i = 1, getn(source), 1 do
                tinsert(nativeTypes, source[i].Type)
            end
        end
        g_PureDrawNativeResultFilter = CreateObjectFilter({
            Rule = "ANY",
            IncludeThing = nativeTypes,
        })
    end
    local units, count = ObjectFindObjects(nil, {
        X = x, Y = y, Z = z, Radius = 180, DistType = "CENTER_2D"
    }, g_PureDrawNativeResultFilter)
    for i = 1, count, 1 do
        ExecuteAction("NAMED_DELETE", units[i])
    end
    PureDrawDebug("removed " .. tostring(count)
        .. " native result objects near consumed custom crate")
end

function PureDrawFinishCustomCrate(playerName, x, y, z, removeNativeResult)
    if g_PlayerNameToIndex[playerName] == nil then
        PureDrawDebug("ERROR custom crate has no valid player collector")
        return
    end
    if removeNativeResult then
        PureDrawDeleteNativeResultNear(x, y, z)
    end
    PureDrawSpawnCustomUnit(playerName, x, y, z)
end

function PureDrawRemoveTrackedCrate(id)
    local state = g_PureDrawTrackedCrates[id]
    if state == nil then
        return
    end
    g_PureDrawTrackedCrates[id] = nil
    local listIndex = state.ListIndex
    if listIndex ~= nil and listIndex >= 1
        and listIndex <= getn(g_PureDrawTrackedCrateList) then
        local lastId = g_PureDrawTrackedCrateList[getn(g_PureDrawTrackedCrateList)]
        g_PureDrawTrackedCrateList[listIndex] = lastId
        g_PureDrawTrackedCrateList[getn(g_PureDrawTrackedCrateList)] = nil
        if lastId ~= id and g_PureDrawTrackedCrates[lastId] ~= nil then
            g_PureDrawTrackedCrates[lastId].ListIndex = listIndex
        end
    end
end

-- 判断某个单位是否位于任一被跟踪箱子附近（即它是玩家碰该箱子生成的原生抽卡单位，
-- 会被 PureDrawOnNativeCrateResultBorn 拦截）。生产余额监听用它跳过这些单位。
function PureDrawIsNearTrackedCrate(unitId)
    if getn(g_PureDrawTrackedCrateList) <= 0 then
        return false
    end
    local x, y, z = ObjectGetPosition(unitId)
    for i = 1, getn(g_PureDrawTrackedCrateList), 1 do
        local tid = g_PureDrawTrackedCrateList[i]
        local state = g_PureDrawTrackedCrates[tid]
        if state ~= nil then
            local dx = x - state.X
            local dy = y - state.Y
            if dx * dx + dy * dy < 160 * 160 then
                return true
            end
        end
    end
    return false
end

-- 轻量跟踪：箱子活着时持续刷新位置（NoCreatesInCenter 可能移动箱子）。
-- 箱子消失后保留 30 帧，等待“碰箱子生成的原生单位”创建回调来拦截；
-- 若超时无人拦截（例如箱子过期消失），则清理跟踪记录。
function PureDrawTrackCustomCrate(id)
    local state = g_PureDrawTrackedCrates[id]
    if state == nil then
        return
    end
    if ObjectIsAlive(id) then
        local x, y, z = ObjectGetPosition(GetObjectById(id))
        state.X, state.Y, state.Z = x, y, z
        SchedulerModule.delay_call(PureDrawTrackCustomCrate, 1, { id })
        return
    end
    -- 箱子已消失（被碰或过期）：记录消失帧，供拦截逻辑匹配；稍后清理。
    if state.DiedFrame == nil then
        state.DiedFrame = GetFrame()
    end
    SchedulerModule.delay_call(PureDrawCleanupTrackedCrate, 60, { id })
end

function PureDrawCleanupTrackedCrate(id)
    if g_PureDrawTrackedCrates[id] ~= nil then
        PureDrawRemoveTrackedCrate(id)
    end
end

-- 玩家碰箱子后，引擎会立即删除箱子并在玩家阵营生成一个原生抽卡单位。
-- 拦截：既监听原生单位创建（本回调），也在 PureDrawOnBuildableUnitBorn 里
-- 用生产者判定处理。匹配一律基于“该玩家刚消失的被跟踪箱子”，不依赖位置。
function PureDrawOnNativeCrateResultBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 then
        return
    end
    -- 已被 buildable 回调拦截处理（它先注册先执行），跳过避免重复。
    if g_PureDrawScriptCreatedUnitIds[createdObjId] then
        return
    end
    -- AI 碰箱子（空投等）：保留单位，但把 AI 单位加入对应阵营的攻击队列。
    if ownerPlayerName == "PlyrCivilian" or ownerPlayerName == "PlyrCreeps" then
        SchedulerModule.delay_call(PureDrawJoinAIAttackTeam, 1,
            { createdObjId, ownerPlayerName })
        return
    end
    -- 只有玩家碰箱子生成的原生单位才拦截
    if g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    local consumedCrateId = PureDrawFindConsumedTrackedCrate()
    if consumedCrateId ~= nil then
        local x, y, z = ObjectGetPosition(createdObjId)
        PureDrawRemoveTrackedCrate(consumedCrateId)
        g_PureDrawScriptCreatedUnitIds[createdObjId] = true
        PureDrawDebug("native crate intercepted: player=" .. tostring(ownerPlayerName))
        SchedulerModule.delay_call(PureDrawInterceptNativeResult, 1,
            { createdObjId, ownerPlayerName, x, y, z })
    end
end

function PureDrawInterceptNativeResult(createdObjId, playerName, x, y, z)
    if ObjectIsAlive(createdObjId) then
        ExecuteAction("NAMED_DELETE", GetObjectById(createdObjId))
    end
    PureDrawSpawnCustomUnit(playerName, x, y, z)
end

-- 问题3：把 AI 阵营的空投/箱子单位加入对应攻击队列，让它们主动进攻。
function PureDrawJoinAIAttackTeam(unitId, ownerPlayerName)
    if not ObjectIsAlive(unitId) then
        return
    end
    local unit = GetObjectById(unitId)
    if ownerPlayerName == "PlyrCivilian" then
        ExecuteAction("UNIT_SET_TEAM", unit, "PlyrCivilian/ATTACK")
    elseif ownerPlayerName == "PlyrCreeps" then
        ExecuteAction("UNIT_SET_TEAM", unit, "PlyrCreeps/ATTACK")
    end
end

-- 日冕引擎的“幸运单位箱子”技能直接创建可拾取的 LuckyUnitCrateSeed 对象，
-- 而不会再有第二段 UnitCrateNew 物理箱（原版可正常工作的实现就是直接跟踪
-- LuckyUnitCrateSeed）。因此拦截逻辑直接跟踪种子对象本身；
-- UnitCrateNew / UnitCrate 的创建回调仅作兼容备份，以防某些途径确实生成物理箱。
function PureDrawOnCrateSeedBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    local roll = GetRandomNumber()
    local useCustomDraw = g_DrawMode == 2
        and roll < g_PureDrawConfig.CustomDrawChance
    local isAirdrop = g_PureDrawAirdropCrateIds[createdObjId] == true
    if useCustomDraw then
        local listIndex = getn(g_PureDrawTrackedCrateList) + 1
        g_PureDrawTrackedCrateList[listIndex] = createdObjId
        g_PureDrawTrackedCrates[createdObjId] = {
            X = x,
            Y = y,
            Z = z,
            Owner = ownerPlayerName,
            ListIndex = listIndex,
        }
    end
    if not isAirdrop then
        -- 保持旧版规则：禁止把玩家箱子投放到中央战场（空投箱子不受此限制）。
        SchedulerModule.delay_call(NoCreatesInCenter, 1, { createdObjId })
    end
    if useCustomDraw then
        SchedulerModule.delay_call(PureDrawTrackCustomCrate, 2, { createdObjId })
    end
end

-- 兼容备份：若某些途径确实创建了 UnitCrateNew / UnitCrate 物理箱，同样直接跟踪。
function PureDrawOnPhysicalCrateBorn(createdObjId, createdObjInstanceId, ownerPlayerName)
    local x, y, z = ObjectGetPosition(createdObjId)
    local roll = GetRandomNumber()
    local useCustomDraw = g_DrawMode == 2
        and roll < g_PureDrawConfig.CustomDrawChance
    local isAirdrop = g_PureDrawAirdropCrateIds[createdObjId] == true
    if useCustomDraw then
        local listIndex = getn(g_PureDrawTrackedCrateList) + 1
        g_PureDrawTrackedCrateList[listIndex] = createdObjId
        g_PureDrawTrackedCrates[createdObjId] = {
            X = x,
            Y = y,
            Z = z,
            Owner = ownerPlayerName,
            ListIndex = listIndex,
        }
        PureDrawTrackCustomCrate(createdObjId)
    elseif not isAirdrop then
        SchedulerModule.delay_call(NoCreatesInCenter, 1, { createdObjId })
    end
end

function PureDrawChooseNativeNonSeaUnit()
    local pool = {}
    for crateType = 1, 3, 1 do
        local source = g_CrateUnitsTemplate[crateType]
        for i = 1, getn(source), 1 do
            tinsert(pool, source[i])
        end
    end
    local index = floor(GetRandomNumber() * getn(pool)) + 1
    if index > getn(pool) then
        index = getn(pool)
    end
    return pool[index]
end

function PureDrawReplaceNativeSeaResult(createdObjId, createdObjInstanceId, ownerPlayerName)
    if g_DrawMode ~= 2 or g_DisableSeaArmy ~= 1
        or g_PlayerNameToIndex[ownerPlayerName] == nil then
        return
    end
    SchedulerModule.delay_call(function(id, playerName)
        if not ObjectIsAlive(id) or ObjectGetProducerObject(id) ~= nil then
            return
        end
        local unit = GetObjectById(id)
        local x, y, z = ObjectGetPosition(unit)
        local info = PureDrawChooseNativeNonSeaUnit()
        ExecuteAction("NAMED_DELETE", unit)
        local nextObjectId = GetNextObjectId()
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "", info.Type,
            format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
    end, 1, { createdObjId, ownerPlayerName })
end

for i = 1, getn(g_SeaCrateUnits), 1 do
    RegisterUnitCreateCallback(g_SeaCrateUnits[i], PureDrawReplaceNativeSeaResult)
end

-- 生成一个空投箱子。箱子使用引擎同款 LuckyUnitCrateSeed 类型（技能创建的
-- 可拾取箱子就是它，而不是 UnitCrateNew）。成功时记录实际对象 ID 并返回 true。
-- 注意：RA3LuaBridge 方言（Lua 4.0）不支持闭包访问外层局部变量，因此
-- 序列号、中心坐标等全部通过参数显式传入，函数体内不使用任何外层局部变量。
function PureDrawSpawnAirdropCrate(serial, i, team, centerX, centerY, centerZ)
    local crateName = format("PureDrawAirdrop_%d_%d", serial, i)
    -- 圆形布局：i=1 在圆心，i=2..10 均匀分布在圆周上（半径 140）。
    local column, row
    if i == 1 then
        column = 0
        row = 0
    else
        local dir = g_PureDrawAirdropCircle[mod(i - 2, 9) + 1]
        column = dir[1] * 140
        row = dir[2] * 140
    end
    local nextObjectId = GetNextObjectId()
    g_PureDrawAirdropCrateIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", crateName, "LuckyUnitCrateSeed",
        team, {
            X = centerX + column,
            Y = centerY + row,
            Z = centerZ,
        }, 0)
    local crate = GetObjectByScriptName(crateName)
    if ObjectIsAlive(crate) then
        local actualId = ObjectGetId(crate)
        g_PureDrawAirdropCrateIds[actualId] = true
        ExecuteAction("OBJECT_CREATE_RADAR_EVENT", crate, "Information")
        return true
    end
    return false
end

function PureDrawSpawnAirdrop()
    local leftTower = GetObjectByScriptName("T74")
    local rightTower = GetObjectByScriptName("T84")
    if not ObjectIsAlive(leftTower) or not ObjectIsAlive(rightTower) then
        return
    end
    -- 空投圆心固定为战场中心（玩家从地图编辑器校准：3547.06, 3055.49）。
    -- 不再依赖 T74/T84 中点，避免塔的位置波动导致圆心漂移（曾出现极端偏右的落点）。
    -- Z 仍取两塔平均（地面高度）。
    local lx, ly, lz = ObjectGetPosition(leftTower)
    local rx, ry, rz = ObjectGetPosition(rightTower)
    local centerX = 3547.06
    local centerY = 3055.49
    local centerZ = (lz + rz) / 2
    g_PureDrawAirdropSerial = g_PureDrawAirdropSerial + 1

    local spawnedCount = 0
    -- 先探测中立阵营是否可生成箱子；若中立阵营不可用，则改用双方电脑阵营，
    -- 保证空投箱子必定能实际落地（两侧玩家与双方电脑均为友军，均可拾取）。
    if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, 1,
            "PlyrNeutral/teamPlyrNeutral", centerX, centerY, centerZ) then
        spawnedCount = 1
        for i = 2, 10, 1 do
            if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, i,
                    "PlyrNeutral/teamPlyrNeutral", centerX, centerY, centerZ) then
                spawnedCount = spawnedCount + 1
            end
        end
    else
        for i = 1, 10, 1 do
            local team = "PlyrCivilian/teamPlyrCivilian"
            if i > 5 then
                team = "PlyrCreeps/teamPlyrCreeps"
            end
            if PureDrawSpawnAirdropCrate(g_PureDrawAirdropSerial, i, team,
                    centerX, centerY, centerZ) then
                spawnedCount = spawnedCount + 1
            end
        end
    end
    if spawnedCount > 0 then
        exAddTextToPublicBoard(Localization.get("pure_draw.airdrop"), 12)
    end
end

function PureDrawAirdropCheck()
    if g_DrawMode == 2 then
        local roll = GetRandomNumber()
        if roll < g_PureDrawConfig.AirdropChance then
            PureDrawSpawnAirdrop()
        end
    end
    SchedulerModule.delay_call(PureDrawAirdropCheck, g_PureDrawConfig.AirdropCheckFrames, {})
end

function PureDrawRoundCheck()
    if g_DrawMode ~= 2 then
        return
    end
    local round = exCounterGetByName("lvc")
    if round == nil or round <= 0 or round == g_PureDrawLastRound then
        return
    end
    g_PureDrawLastRound = round
    if mod(round, g_PureDrawConfig.RefreshRounds) == 0 then
        for playerIndex = 1, 6, 1 do
            PureDrawRefreshQuota(playerIndex)
        end
    end
end
SchedulerModule.call_every_x_frame(PureDrawRoundCheck, 15, nil)

-- 科技、海三塔等外部脚本可能重新开放生产按钮；开放后立即重新套用余额状态。
function PureDrawReapplyPlayerQuota(playerIndex)
    if g_DrawMode ~= 2 then
        return
    end
    PureDrawSetPlayerBuildability(playerIndex, (g_PureDrawQuota[playerIndex] or 0) > 0)
end

function PureLuckyCrateMode_Setting()
    if g_PureDrawInitialized then
        return
    end
    g_PureDrawInitialized = true
    PureDrawDebug("pure draw mode initializing")
    TryEnableLuckyCrateIfAllowed()
    -- 问题4：清除玩家开局自带的船厂（地图初始建筑），只保留玩家自己建造的
    -- 生产建筑，确保生产余额只由玩家自造建筑的生产序列消耗。
    if g_PureDrawNavalYardFilter == nil then
        g_PureDrawNavalYardFilter = CreateObjectFilter({
            Rule = "ANY",
            IncludeThing = {
                "AlliedNavalYard", "SovietNavalYard", "JapanNavalYard", "CelestialNavalYard"
            }
        })
    end
    local yards, yardCount = ObjectFindObjects(nil, nil, g_PureDrawNavalYardFilter)
    for yardIndex = 1, yardCount, 1 do
        local yardOwner = ObjectPlayerScriptName(yards[yardIndex])
        if g_PlayerNameToIndex[yardOwner] ~= nil then
            ExecuteAction("NAMED_DELETE", yards[yardIndex])
            PureDrawDebug("removed starting naval yard for " .. tostring(yardOwner))
        end
    end
    for playerIndex = 1, 6, 1 do
        PureDrawRefreshQuota(playerIndex)
    end
    SchedulerModule.delay_call(PureDrawAirdropCheck, g_PureDrawConfig.AirdropCheckFrames, {})
    SchedulerModule.delay_call(NoMCVInCenter, 30, {})
end

-- 箱子模式：只允许抽卡，不允许在地图上刷随机箱子（万一被 AI 捡了太麻烦）
SchedulerModule.delay_call(function()
    local crateFilter = CreateObjectFilter({ IncludeThing = { "GenericCrateSpawner" } })
    local units, count = ObjectFindObjects(nil, nil, crateFilter)
    for j = 1, count, 1 do
        -- 先禁用抽卡技能（后面可以启用）
        ExecuteAction("NAMED_DELETE", units[j])
        -- 此外假如检测到随机宝箱，就默认启用旧抽卡模式。
        if g_DrawMode == nil or g_DrawMode == 0 then
            g_DrawMode = 1
            g_LuckyCrateMode = 1
        end
    end
end, 1, {})
SchedulerModule.delay_call(function()
    local crateFilter = CreateObjectFilter({
        IncludeThing = {
            "GenericCrateSpawner",
            "UnitCrateNew",
            "ShroudCrate",
            "MoneyCrateMP",
        }
    })
    local units, count = ObjectFindObjects(nil, nil, crateFilter)
    for j = 1, count, 1 do
        ExecuteAction("NAMED_DELETE", units[j])
    end
end, 45, {})

-- 检测箱子是否被扔到中央战场
function NoCreatesInCenter(id)
    if not ObjectIsAlive(id) then
        return
    end
    if g_PureDrawAirdropCrateIds[id] then
        return
    end
    local crate = GetObjectById(id)
    local isCrateInCenter = false
    if EvaluateCondition("NAMED_INSIDE_AREA", crate, "SHOW7")
        and EvaluateCondition("NAMED_INSIDE_AREA", crate, "SHOW8") then
        -- SHOW7 SHOW8 这两个区域都包含中央战场
        -- 所以假如单位处于中央战场，就会同时处于这两个区域内
        isCrateInCenter = true
    end
    if not isCrateInCenter then
        -- 不在中间就没事
        return
    end
    -- 寻找一个合法的位置
    if not g_CelestialOutpostsFilter then
        g_CelestialOutpostsFilter = CreateObjectFilter({ IncludeThing = { "CelestialOutpost" } })
    end
    local outposts, count = ObjectFindObjects(nil, nil, g_CelestialOutpostsFilter)
    if count <= 0 then
        return
    end
    local index = ceil(GetRandomNumber() * count)
    if index < 1 then
        index = 1
    end
    if index > count then
        index = count
    end
    local outpost = outposts[index]
    local RandomInRange = function(min, max)
        local sign = 1
        if GetRandomNumber() < 0.5 then
            sign = -1
        end
        return (min + (GetRandomNumber() * (max - min))) * sign
    end
    local offsetX = RandomInRange(50, 200)
    local offsetY = RandomInRange(50, 150)
    local x, y, z = ObjectGetPosition(outpost)
    ObjectSetPosition(crate, x + offsetX, y + offsetY, z)
    -- 发送警告
    ExecuteAction("OBJECT_CREATE_RADAR_EVENT", crate, "Information")
    if g_LastWarningFrame ~= nil and g_LastWarningFrame + 30 > GetFrame() then
        -- 一段时间内只提示一次
    else
        g_LastWarningFrame = GetFrame()
        exMessageAppendToMessageArea(Localization.get("error.crate_in_battlefield"))
    end
end

-- 检测 MCV（包括青龙战斗核心舰）是否在中央战场，禁止 MCV 参与战斗。
-- 玩家的 MCV → 传送回基地 + 警告；AI 的 MCV（非技能召唤）/迅雷运输艇 → 直接击杀。
g_LastMCVWarningFrame = nil
g_MCVTypes = {
    "AlliedMCV", "AlliedMCV_Enhanced", "AlliedMCV_Naval", "AlliedMCV_Enhanced_Naval",
    "SovietMCV", "SovietMCV_Enhanced", "SovietMCV_Naval", "SovietMCV_Enhanced_Naval",
    "JapanMCV", "JapanMCV_Enhanced", "JapanMCV_Naval", "JapanMCV_Enhanced_Naval",
    "CelestialMCV", "CelestialMCV_Enhanced", "CelestialMCV_Ground", "CelestialMCV_Naval",
    "CelestialMCV_Air", "CelestialMCV_Enhanced_Ground", "CelestialMCV_Enhanced_Naval",
    "CelestialMCV_Enhanced_Air",
}
g_AIBannedTypes = {
    "CelestialTransportUAV", -- 迅雷运输艇
}
-- 技能召唤的龙船所属队伍（保留，不击杀）
g_DragonShipSkillTeamNames = {
    ["PlyrCivilian/ATTACK"] = true,
    ["PlyrCreeps/ATTACK"] = true,
}

function IsSkillDragonShip(unit)
    if unit == nil then
        return false
    end
    local teamName = ObjectTeamName(unit)
    return g_DragonShipSkillTeamNames[teamName] == true
end

function NoMCVInCenter()
    if not g_CelestialOutpostsFilter then
        g_CelestialOutpostsFilter = CreateObjectFilter({ IncludeThing = { "CelestialOutpost" } })
    end
    
    -- 检测 MCV（包括青龙核心舰）
    local mcvFilter = CreateObjectFilter({
        Rule = "ANY",
        IncludeThing = g_MCVTypes
    })
    local mcvs, mcvCount = ObjectFindObjects(nil, nil, mcvFilter)
    for i = 1, mcvCount, 1 do
        local mcv = mcvs[i]
        if ObjectIsAlive(mcv) then
            local isMCVInCenter = false
            if EvaluateCondition("NAMED_INSIDE_AREA", mcv, "SHOW7")
                and EvaluateCondition("NAMED_INSIDE_AREA", mcv, "SHOW8") then
                isMCVInCenter = true
            end
            if isMCVInCenter then
                local ownerPlayerName = ObjectPlayerScriptName(mcv)
                local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
                if playerIndex ~= nil then
                    -- 玩家的 MCV：传送回基地（根据阵营选择哨站）
                    local outposts, outpostCount = ObjectFindObjects(nil, nil, g_CelestialOutpostsFilter)
                    if outpostCount > 0 then
                        -- 根据玩家阵营筛选哨站：1-3 在下方（Y 小），4-6 在上方（Y 大）
                        local validOutposts = {}
                        for j = 1, outpostCount, 1 do
                            local ox, oy, oz = ObjectGetPosition(outposts[j])
                            if playerIndex <= 3 then
                                -- 下方玩家（1-3）→ 传送到下方哨站（Y < 3000）
                                if oy < 3000 then
                                    tinsert(validOutposts, outposts[j])
                                end
                            else
                                -- 上方玩家（4-6）→ 传送到上方哨站（Y > 3000）
                                if oy > 3000 then
                                    tinsert(validOutposts, outposts[j])
                                end
                            end
                        end
                        if getn(validOutposts) > 0 then
                            local index = ceil(GetRandomNumber() * getn(validOutposts))
                            if index < 1 then index = 1 end
                            if index > getn(validOutposts) then index = getn(validOutposts) end
                            local outpost = validOutposts[index]
                            local RandomInRange = function(min, max)
                                local sign = 1
                                if GetRandomNumber() < 0.5 then sign = -1 end
                                return (min + (GetRandomNumber() * (max - min))) * sign
                            end
                            local offsetX = RandomInRange(100, 300)
                            local offsetY = RandomInRange(100, 250)
                            local x, y, z = ObjectGetPosition(outpost)
                            ObjectSetPosition(mcv, x + offsetX, y + offsetY, z)
                            -- 雷达事件 + 警告（30帧内限制一次）
                            ExecuteAction("OBJECT_CREATE_RADAR_EVENT", mcv, "Information")
                            if g_LastMCVWarningFrame == nil or g_LastMCVWarningFrame + 30 <= GetFrame() then
                                g_LastMCVWarningFrame = GetFrame()
                                exMessageAppendToMessageArea("禁止将MCV用于战斗！")
                            end
                        end
                    end
                else
                    -- AI 的 MCV：检查是否是技能召唤的龙船
                    if not IsSkillDragonShip(mcv) then
                        -- 非技能龙船 → 击杀
                        ExecuteAction("NAMED_KILL", mcv)
                    end
                    -- 技能龙船 → 保留，不处理
                end
            end
        end
    end
    
    -- 检测 AI 的迅雷运输艇等禁用单位（任何位置都击杀）
    local bannedFilter = CreateObjectFilter({
        Rule = "ANY",
        IncludeThing = g_AIBannedTypes
    })
    local bannedUnits, bannedCount = ObjectFindObjects(nil, nil, bannedFilter)
    for i = 1, bannedCount, 1 do
        local unit = bannedUnits[i]
        if ObjectIsAlive(unit) then
            local ownerPlayerName = ObjectPlayerScriptName(unit)
            local playerIndex = g_PlayerNameToIndex[ownerPlayerName]
            if playerIndex == nil then
                -- AI 的禁用单位：直接击杀
                ExecuteAction("NAMED_KILL", unit)
            end
        end
    end
    
    SchedulerModule.delay_call(NoMCVInCenter, 30, {})
end

RegisterUnitCreateCallback("LuckyUnitCrateSeed", PureDrawOnCrateSeedBorn)
RegisterUnitCreateCallback("UnitCrateNew", PureDrawOnPhysicalCrateBorn)
RegisterUnitCreateCallback("UnitCrate", PureDrawOnPhysicalCrateBorn)

-- 监听所有原生抽卡单位（碰箱子生成的单位）的创建，实现事件驱动拦截
-- （玩家碰箱子 -> 生成自定义单位；AI 碰箱子 -> 加入 AI 攻击队列）。
g_PureDrawRegisteredNativeCrateHashes = {}
for crateType = 1, 4, 1 do
    local source = g_CrateUnitsTemplate[crateType]
    for i = 1, getn(source), 1 do
        local unitType = source[i].Type
        local unitHash = FastHash(unitType)
        if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
            RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
            g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
        end
    end
end
for i = 1, getn(g_GroundCrateUnits), 1 do
    local unitType = g_GroundCrateUnits[i]
    local unitHash = FastHash(unitType)
    if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
        g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
    end
end
for i = 1, getn(g_AirCrateUnits), 1 do
    local unitType = g_AirCrateUnits[i]
    local unitHash = FastHash(unitType)
    if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
        g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
    end
end
for i = 1, getn(g_SeaCrateUnits), 1 do
    local unitType = g_SeaCrateUnits[i]
    local unitHash = FastHash(unitType)
    if not g_PureDrawRegisteredNativeCrateHashes[unitHash] then
        RegisterUnitCreateCallback(unitType, PureDrawOnNativeCrateResultBorn)
        g_PureDrawRegisteredNativeCrateHashes[unitHash] = true
    end
end
