-- 旧版保留脚本，当前地图中不生效。
-- 本文件中的舰船哈希、计数和 spawnShips() 生成系统已不再由地图使用。
-- 当前地图使用 SpawnSeaUnit 和现有回合生成体系；保留此文件仅供历史参考。

g_ShipHashToNameIndex = {
 [1] = FastHash("JapanNavyScoutShip"),
 [2] = FastHash("JapanAntiVehicleVehicleTech1_Naval"),
 [3] = FastHash("JapanAntiAirShip"),
 [4] = FastHash("JapanAntiVehicleShip"),
 [5] = FastHash("JapanInterceptorAircraft"),
 [6] = FastHash("JapanAntiNavyShipTech3"),
 [7] = FastHash("JapanAntiStructureShip"),
 [8] = FastHash("AlliedAntiNavalScout"),
 [9] = FastHash("AlliedAntiInfantryVehicle"),
 [10] = FastHash("AlliedAntiAirShip"),
 [11] = FastHash("AlliedAntiNavyShipTech1"),
 [12] = FastHash("AlliedAntiStructureShip"),
 [13] = FastHash("AlliedAntiNavyShipTech3"),
 [14] = FastHash("SovietAntiNavyShipTech1"),
 [15] = FastHash("SovietAntiStructureShip"),
 [16] = FastHash("SovietAntiAirShip"),
 [17] = FastHash("SovietAntiNavyShipTech2"),
 [18] = FastHash("SovietAntiNavyShipTech3"),
 [19] = FastHash("CelestialAntiNavyShipTech1"),
 [20] = FastHash("CelestialAntiAirShip_Water"),
 [21] = FastHash("CelestialAlmightlyShip"),
 [22] = FastHash("CelestialAntiNavyShipTech3"),
 [23] = FastHash("CelestialAntiStructureShip"),
}

g_ShipHashToName = {
    [FastHash("JapanNavyScoutShip")] = "JapanNavyScoutShip",
    [FastHash("JapanAntiVehicleVehicleTech1_Naval")] = "JapanAntiVehicleVehicleTech1_Naval",
    [FastHash("JapanAntiAirShip")] = "JapanAntiAirShip",
    [FastHash("JapanAntiVehicleShip")] = "JapanAntiVehicleShip",
    [FastHash("JapanInterceptorAircraft")] = "JapanInterceptorAircraft",
    [FastHash("JapanAntiNavyShipTech3")] = "JapanAntiNavyShipTech3",
    [FastHash("JapanAntiStructureShip")] = "JapanAntiStructureShip",
    [FastHash("AlliedAntiNavalScout")] = "AlliedAntiNavalScout",
    [FastHash("AlliedAntiInfantryVehicle")] = "AlliedAntiInfantryVehicle",
    [FastHash("AlliedAntiAirShip")] = "AlliedAntiAirShip",
    [FastHash("AlliedAntiNavyShipTech1")] = "AlliedAntiNavyShipTech1",
    [FastHash("AlliedAntiStructureShip")] = "AlliedAntiStructureShip",
    [FastHash("AlliedAntiNavyShipTech3")] = "AlliedAntiNavyShipTech3",
    [FastHash("SovietAntiNavyShipTech1")] = "SovietAntiNavyShipTech1",
    [FastHash("SovietAntiStructureShip")] = "SovietAntiStructureShip",
    [FastHash("SovietAntiAirShip")] = "SovietAntiAirShip",
    [FastHash("SovietAntiNavyShipTech2")] = "SovietAntiNavyShipTech2",
    [FastHash("SovietAntiNavyShipTech3")] = "SovietAntiNavyShipTech3",
    [FastHash("CelestialAntiNavyShipTech1")] = "CelestialAntiNavyShipTech1",
    [FastHash("CelestialAntiAirShip_Water")] = "CelestialAntiAirShip_Water",
    [FastHash("CelestialAlmightlyShip")] = "CelestialAlmightlyShip",
    [FastHash("CelestialAntiNavyShipTech3")] = "CelestialAntiNavyShipTech3",
    [FastHash("CelestialAntiStructureShip")] = "CelestialAntiStructureShip",
}

g_LeftSpawnLocations = {
    [0] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [1] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [2] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [3] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [4] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [5] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
}

g_RightSpawnLocations = {
    [0] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [1] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [2] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [3] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [4] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
    [5] = {
        ["x"] = 4000,
        ["y"] = 4000,
        ["z"] = 200,
    },
}

g_ShipSpawnLocation = {
    [1] = g_LeftSpawnLocations,
    [2] = g_LeftSpawnLocations,
    [3] = g_LeftSpawnLocations,
    [4] = g_RightSpawnLocations,
    [5] = g_RightSpawnLocations,
    [6] = g_RightSpawnLocations,
}

g_ShipTeam = {
    [1] = "PlyrCivilian/SHIPTEAM",
    [2] = "PlyrCivilian/SHIPTEAM",
    [3] = "PlyrCivilian/SHIPTEAM",
    [4] = "PlyrCreeps/SHIPTEAM",
    [5] = "PlyrCreeps/SHIPTEAM",
    [6] = "PlyrCreeps/SHIPTEAM",
}

-- 某个玩家某种单位的数量 g_PlayerShipCount["Player_1"]["ShipName"]
g_PlayerShipCount = {}

for playindex = 1 , 6 , 1 do
    g_PlayerShipCount[playindex] = {}
    for i = 1, getn(g_ShipHashToNameIndex) do
        g_PlayerShipCount[playindex][g_ShipHashToNameIndex[i]] = 0
    end
end

function onShipBuilt(createdObjId, createdObjInstanceId, ownerPlayerName)
    -- 防止中立玩家的也算上
    -- TODO 计入总单位数
    if g_PlayerShipCount[ownerPlayerName] then
        g_PlayerShipCount[ownerPlayerName][createdObjInstanceId] = g_PlayerShipCount[ownerPlayerName][createdObjInstanceId] + 1
    end
end

function spawnShips()
    for i = 1, 6, 1 do
        local playerName = "Player_"..i;
        local spawnLocationList = g_ShipSpawnLocation[i]
        for j = 1, getn(g_ShipHashToNameIndex) do
            local spawnLoc = spawnLocationList[mod(j, 6)]
            local shipName = g_ShipHashToNameIndex[j]
            local count = g_PlayerShipCount[playerName][shipName]
            for k = 1, count, 1 do
                ExecuteAction("CREATE_OBJECT", g_ShipHashToName[shipName], g_ShipTeam[i], {X = spawnLoc["x"], Y = spawnLoc["y"], Z = spawnLoc["z"]}, 0)
            end
        end
    end
end
