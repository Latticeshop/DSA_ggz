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
    -- 龙船由双方电脑玩家持有；出生后再次封锁所有舰载升级，防止对象初始化重新开放按钮。
    SchedulerModule.delay_call(function(playerName)
        DisableCelestialDragonShipUpgradesForPlayer(playerName)
        _ALERT("[PureDraw] reapplied Dragon Ship upgrade lock for owner " .. tostring(playerName))
    end, 2, { ownerPlayerName })
end
g_UnitCreateEventFunc[FastHash("CelestialMCV")] = DisableCrateDragonAttack

-- 纯抽卡模式配置。Tier 权重合计必须为 100。
g_PureDrawConfig = {
    ProductionQuota = 5,
    RefreshRounds = 3,
    CustomDrawChance = 0.50,
    AirdropCheckFrames = 15 * 60,
    AirdropChance = 0.05,
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
    ["AlliedAntiInfantryVehicle_Ground"] = { "AlliedAntiInfantryVehicle" },
    ["CelestialAntiInfantryVehicle_B"] = { "CelestialAntiInfantryVehicle" },
    ["CelestialLongRangeMissileVehicle_B"] = { "CelestialLongRangeMissileVehicle" },
    ["AlliedGunshipAircraft"] = { "AlliedGunshipAircraft_Enhanced", "AlliedAC130GunshipAircraft" },
    ["AlliedAntiVehicleVehicleTech1"] = { "AlliedAntiVehicleVehicleTech1_Enhanced" },
    ["prismtank"] = { "AlliedPrismTank_Enhanced" },
    ["AlliedAntiStructureVehicle"] = { "AlliedAntiStructureVehicle_Enhanced" },
    ["AlliedFighterAircraft"] = { "AlliedFighterAircraft_Enhanced" },
    ["AlliedInterceptorAircraft"] = { "AlliedInterceptorAircraft_Enhanced" },
    ["SovietSledgehammerSPG"] = { "SovietSledgehammerSPG_Enhanced" },
    ["SovietAntiStructureVehicle"] = { "SovietAntiStructureVehicle_Enhanced" },
    ["SovietAntiVehicleVehicleTech4"] = { "SovietAntiVehicleVehicleTech4_Enhanced" },
    ["SovietFighterAircraft"] = { "SovietFighterAircraft_Enhanced" },
    ["SovietInterceptorAircraft"] = { "SovietInterceptorAircraft_Enhanced" },
    ["JapanAntiInfantryVehicle"] = { "JapanAntiInfantryVehicle_Enhanced" },
    ["JapanAntiAirVehicleTech1"] = { "JapanAntiAirVehicleTech1_Enhanced" },
    ["JapanMissileMechaAdvanced"] = { "JapanMissileMechaAdvanced_Enhanced" },
    ["JapanAntiStructureVehicle"] = { "JapanAntiStructureVehicle_Enhanced" },
    ["JapanAntiAirShip"] = { "JapanAntiAirShip_Enhanced" },
    ["CelestialAntiStructureVehicle"] = { "CelestialAntiStructureVehicle_Enhanced" },
    ["CelestialAntiVehicleVehicleTech4"] = { "CelestialAntiVehicleVehicleTech4_Enhanced" },
    ["CelestialInterceptorAircraft"] = { "CelestialInterceptorAircraft_Enhanced" },
    ["CelestialBomberAircraft"] = { "CelestialBomberAircraft_Enhanced" },
    ["CelestialAdvanceAircraftTech4"] = { "CelestialAdvanceAircraftTech4_Enhanced" },
    ["AlliedAntiStructureShip"] = { "AlliedAntiStructureShip_Enhanced" },
    ["SovietAntiStructureShip"] = { "SovietAntiStructureShip_Enhanced" },
    ["JapanAntiStructureShip"] = { "JapanAntiStructureShip_Enhanced" },
    ["CelestialAntiStructureShip"] = { "CelestialAntiStructureShip_Enhanced" },
}

g_PureDrawBuildableUnitSet = {}
g_PureDrawUnitInfoByHash = {}
g_PureDrawQuota = { 0, 0, 0, 0, 0, 0 }
g_PureDrawTrackedCrates = {}
g_PureDrawAirdropCrateIds = {}
g_PureDrawScriptCreatedUnitIds = {}
g_PureDrawLastRound = -1
g_PureDrawT4ShipUnlocked = { false, false, false, false, false, false }
g_PureDrawRegisteredProductionHashes = {}

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

function PureDrawSpawnQuotaWall(playerIndex, slot)
    if not PureDrawIsHumanPlayer(playerIndex) then
        return
    end
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = 1
    if playerIndex >= 4 then
        direction = -1
    end
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
    local direction = 1
    if playerIndex >= 4 then
        direction = -1
    end
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
            local availability = 0
            if enable and PureDrawCanEnableUnit(playerIndex, info) then
                availability = 1
            end
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, info.Type, availability)
            local aliases = g_PureDrawProductionAliases[info.Type]
            if aliases ~= nil then
                for aliasIndex = 1, getn(aliases), 1 do
                    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, aliases[aliasIndex], availability)
                end
            end
            if availability == 0 then
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
    PureDrawDebug("buildability applied to " .. playerName
        .. ", quotaEnabled=" .. tostring(enable)
        .. ", quota=" .. tostring(g_PureDrawQuota[playerIndex] or 0))
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
        if retriesLeft > 0 then
            SchedulerModule.delay_call(PureDrawTryConsumeProductionQuota, 1, {
                createdObjId, createdObjInstanceId, playerIndex, ownerPlayerName, retriesLeft - 1
            })
            return
        else
            -- LuaBridge 对部分生产序列（实测包括赠送船厂的海军序列）不会返回
            -- ProducerObject。出生事件已经仅注册到显式的玩家可生产单位池，并且
            -- 抽卡脚本生成物会在进入本函数前由白名单排除，因此这里按玩家生产
            -- 结果兜底计费，确保赠送船厂、后续重工和机场使用同一套余额规则。
            PureDrawDebug("producer unavailable; treating player-owned buildable unit as produced id="
                .. tostring(createdObjId)
                .. ", typeHash=" .. tostring(createdObjInstanceId)
                .. ", owner=" .. tostring(ownerPlayerName))
        end
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
    PureDrawDebug("buildable unit birth event id=" .. tostring(createdObjId)
        .. ", typeHash=" .. tostring(createdObjInstanceId)
        .. ", owner=" .. tostring(ownerPlayerName))
    PureDrawTryConsumeProductionQuota(createdObjId, createdObjInstanceId,
        playerIndex, ownerPlayerName, 3)
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
    local nextObjectId = GetNextObjectId()
    g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "", info.Type,
        format("%s/team%s", playerName, playerName), { X = x, Y = y, Z = z }, 0)
    PureDrawDebug("custom draw spawned " .. info.Type .. " for " .. playerName
        .. ", tier=" .. tostring(info.Tier))
    exAddTextToPublicBoardForPlayer(playerName,
        Localization.get("pure_draw.custom_result", info.Tier), 5)
end

g_PureDrawCollectorFilter = CreateObjectFilter({
    Rule = "ANY",
    Include = "SELECTABLE",
    Exclude = "STRUCTURE",
})

function PureDrawFindCollector(x, y, z)
    local units, count = ObjectFindObjects(nil, {
        X = x, Y = y, Z = z, Radius = 55, DistType = "CENTER_2D"
    }, g_PureDrawCollectorFilter)
    for i = 1, count, 1 do
        local playerName = ObjectPlayerScriptName(units[i])
        if g_PlayerNameToIndex[playerName] ~= nil then
            return playerName
        end
    end
    return nil
end

function PureDrawTrackCustomCrate(id)
    local state = g_PureDrawTrackedCrates[id]
    if state == nil then
        return
    end
    if not ObjectIsAlive(id) then
        g_PureDrawTrackedCrates[id] = nil
        return
    end
    local crate = GetObjectById(id)
    local x, y, z = ObjectGetPosition(crate)
    state.X, state.Y, state.Z = x, y, z
    local playerName = PureDrawFindCollector(x, y, z)
    if playerName ~= nil then
        g_PureDrawTrackedCrates[id] = nil
        ExecuteAction("NAMED_DELETE", crate)
        PureDrawDebug("custom crate collected id=" .. tostring(id)
            .. ", collector=" .. tostring(playerName))
        PureDrawSpawnCustomUnit(playerName, x, y, z)
        return
    end
    SchedulerModule.delay_call(PureDrawTrackCustomCrate, 1, { id })
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

function PureDrawSpawnAirdrop()
    local leftTower = GetObjectByScriptName("T74")
    local rightTower = GetObjectByScriptName("T84")
    if not ObjectIsAlive(leftTower) or not ObjectIsAlive(rightTower) then
        PureDrawDebug("airdrop cancelled because T74 or T84 is missing")
        return
    end
    local lx, ly, lz = ObjectGetPosition(leftTower)
    local rx, ry, rz = ObjectGetPosition(rightTower)
    local centerX = (lx + rx) / 2
    local centerY = (ly + ry) / 2
    local centerZ = (lz + rz) / 2
    for i = 1, 10, 1 do
        local column = mod(i - 1, 5) - 2
        local row = floor((i - 1) / 5) - 0.5
        local nextObjectId = GetNextObjectId()
        g_PureDrawAirdropCrateIds[nextObjectId] = true
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "", "LuckyUnitCrateSeed",
            "PlyrNeutral/teamPlyrNeutral", {
                X = centerX + column * 55,
                Y = centerY + row * 65,
                Z = centerZ,
            }, 0)
        ExecuteAction("OBJECT_CREATE_RADAR_EVENT", GetObjectById(nextObjectId), "Information")
    end
    PureDrawDebug("airdrop spawned 10 crates at x=" .. tostring(centerX)
        .. ", y=" .. tostring(centerY))
    exAddTextToPublicBoard(Localization.get("pure_draw.airdrop"), 12)
end

function PureDrawAirdropCheck()
    if g_DrawMode == 2 then
        local roll = GetRandomNumber()
        PureDrawDebug("one-minute airdrop check roll=" .. tostring(roll)
            .. ", threshold=" .. tostring(g_PureDrawConfig.AirdropChance))
        if roll < g_PureDrawConfig.AirdropChance then
            PureDrawDebug("airdrop check succeeded")
            PureDrawSpawnAirdrop()
        else
            PureDrawDebug("airdrop check did not trigger")
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
    for playerIndex = 1, 6, 1 do
        PureDrawRefreshQuota(playerIndex)
    end
    SchedulerModule.delay_call(PureDrawAirdropCheck, g_PureDrawConfig.AirdropCheckFrames, {})
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
exObjectRegisterCreateEvent("LuckyUnitCrateSeed")
g_UnitCreateEventFunc[FastHash("LuckyUnitCrateSeed")] = function(createdObjId, createdObjInstanceId, ownerPlayerName)
    local useCustomDraw = false
    if g_DrawMode == 2 then
        local roll = GetRandomNumber()
        useCustomDraw = roll < g_PureDrawConfig.CustomDrawChance
        PureDrawDebug("crate created id=" .. tostring(createdObjId)
            .. ", customRoll=" .. tostring(roll)
            .. ", useCustom=" .. tostring(useCustomDraw))
        if useCustomDraw then
            local x, y, z = ObjectGetPosition(createdObjId)
            g_PureDrawTrackedCrates[createdObjId] = { X = x, Y = y, Z = z }
        end
    end
    if g_PureDrawAirdropCrateIds[createdObjId] then
        if useCustomDraw then
            PureDrawTrackCustomCrate(createdObjId)
        end
    else
        -- 先执行中央战场禁投检查，再开始接触检测，避免自定义分支绕过原规则。
        SchedulerModule.delay_call(NoCreatesInCenter, 1, {createdObjId})
        if useCustomDraw then
            SchedulerModule.delay_call(PureDrawTrackCustomCrate, 2, {createdObjId})
        end
    end
end
