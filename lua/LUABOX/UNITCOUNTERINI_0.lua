FilterLIST = {}
UNITLIST = {}
UNITCOUNT = {}
CRATEUNITCOUNT = {} -- 箱子单位计数，主要是为了回收单位时区别对待箱子单位，避免无限抽卡
g_UnitNameToUnitIndex = {}
g_PlayerGiftStates = {}
P = {}
ANYUNITCOUNT = {}
--unitcountmax = 200
for i = 1 , 8 , 1 do
    P[i] = GetObjectByScriptName("P"..i) ;
    ANYUNITCOUNT[i] = 0 ;
    g_PlayerGiftStates[i] = {
        GiftJapanKamikazeInfantry = 0,
        -- GiftSovietAntiInfantryInfantry = 0, -- 暂停：动员兵造二送一
    }
end
UNITLIST [1] = "SovietCommandoTech1"
UNITLIST [2] = "JapanCommandoTech1"
UNITLIST [3] = "AlliedCommandoTech1"
UNITLIST [4] = "AlliedCryoLegionnaire"
UNITLIST [5] = "AlliedAntiInfantryInfantry"
UNITLIST [6] = "CelestialAntiInfantryInfantryAdvanced"
UNITLIST [7] = "CelestialAntiInfantryInfantry"
UNITLIST [8] = "CelestialAntiVehicleInfantry"
UNITLIST [9] = "AlliedScoutInfantry"
UNITLIST [10] = "CelestialInfiltrationInfantry"
local index = 10
index = index + 1 ;
UNITLIST [index] = "AlliedRangerInfantry"
index = index + 1 ;
UNITLIST [index] = "JapanAntiInfantryInfantry"
index = index + 1 ;
UNITLIST [index] = "JapanAntiVehicleInfantry"
index = index + 1 ;
UNITLIST [index] = "JapanArcherInfantry"
index = index + 1 ;
UNITLIST [index] = "SovietAntiInfantryInfantry"
index = index + 1 ;
UNITLIST [index] = "SovietAntiVehicleInfantry"
index = index + 1 ;
UNITLIST [index] = "SovietHeavyAntiVehicleInfantry"
index = index + 1 ;
UNITLIST [index] = "JapanInfiltrationInfantry"
index = index + 1 ;
UNITLIST [index] = "SovietScoutInfantry"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiVehicleInfantry"
index = index + 1 ;
-- UNITLIST [index] = "CelestialInfiltrationInfantry"
-- index = index + 1 ;
--exMessageAppendToMessageArea("indexINFANT"..index)
step1 = index-1 ;
--index = 51
--UNITLIST [index] = "AlliedAntiAirVehicleTech1"
--index = index + 1 ;
UNITLIST [index] = "AlliedAntiInfantryVehicle_Ground"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiVehicleVehicleTech1"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiVehicleVehicleTech3"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiAirShip"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiAirVehicle"
index = index + 1 ;
-- UNITLIST [index] = "CelestialAntiInfantryVehicle"
-- index = index + 1 ;
UNITLIST [index] = "CelestialAntiInfantryVehicle_B"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiVehicleVehicleTech1"
index = index + 1 ;
UNITLIST [index] = "CelestialLongRangeMissileVehicle"
index = index + 1 ;
UNITLIST [index] = "JapanAntiAirVehicleTech1"
index = index + 1 ;
UNITLIST [index] = "JapanAntiVehicleVehicleTech1"
index = index + 1 ;
UNITLIST [index] = "JapanSentinelVehicle"
index = index + 1 ;
-- UNITLIST [index] = "SovietAntiAirShip"
-- index = index + 1 ;
UNITLIST [index] = "SovietAntiInfantryVehicle"
index = index + 1 ;
UNITLIST [index] = "SovietAntiVehicleVehicleTech1"
index = index + 1 ;
UNITLIST [index] = "SovietAntiVehicleVehicleTech2"
index = index + 1 ;
UNITLIST [index] = "SovietHeavyAntiVehicleVehicleTech2"
index = index + 1 ;
UNITLIST [index] = "SovietSledgehammerSPG"
index = index + 1 ;
UNITLIST [index] = "SovietScoutVehicle"
index = index + 1 ;
UNITLIST [index] = "SovietAntiStructureVehicle"
index = index + 1 ;
UNITLIST [index] = "SovietHeavyMortarVehicle"
index = index + 1 ;
UNITLIST [index] = "JapanAntiStructureVehicle"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiStructureVehicle"
index = index + 1 ;
UNITLIST [index] = "CelestialLongRangeMissileVehicle_B"
index = index + 1 ;
UNITLIST [index] = "SovietMortarCycle"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiStructureVehicle"
index = index + 1 ;
UNITLIST [index] = "prismtank"
index = index + 1 ;
--exMessageAppendToMessageArea("indexLIGHTVEH"..index)
step2 = index-1
--index = 101
UNITLIST [index] = "AlliedFutureTank"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiVehicleVehicleTech3"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiVehicleVehicleTech4"
index = index + 1 ;
UNITLIST [index] = "CelestialHeavyAntiAirVehicleTech3"
index = index + 1 ;
UNITLIST [index] = "JapanAntiVehicleVehicleTech3"
index = index + 1 ;
UNITLIST [index] = "JapanMechaX"
index = index + 1 ;
UNITLIST [index] = "SovietAntiVehicleVehicleTech3"
index = index + 1 ;
UNITLIST [index] = "SovietAntiVehicleVehicleTech4"
index = index + 1 ;
UNITLIST [index] = "SovietGrinderVehicle"
index = index + 1 ;
UNITLIST [index] = "Overlordtank"
index = index + 1 ;
UNITLIST [index] = "AlliedBattleFortress"

-- 陆地箱子单位统一放在这里吧
g_GroundCrateUnits = {
    "SovietAntiAirVehicle",
    "VUAntiAirVehicleTech1",
    "VUAntiInfantryVehicleTech1",
    "VUAntiVehicleVehicleTech1",
    "SovietHeavyGrinder",
    "CelestialWaveriderIFV_DragonBreathe",
    "AlliedPacifierFAV",
    "CelestialWaveriderIFV_Mortar",
    "CelestialWaveriderIFV_ATGM",
    "SovietHeavyAntiAirVehicleTech2",
    "AlliedHumveeVehicle",
    "JapanKamikazeInfantry",
    "CelestialWheeledAssaultVehicle",
    "CelestialMBT99A",
    "VUMissileAntiVehicleVehicleTech1",
    "VUBmptVehicle",
    "AlliedGrizzlyMainBattleTank",
    "RheinEntenteNimravusMBT",
    "RheinEntentePalaeoloxodonTD",
    "CelestialMBT99B",
    "WinterArmyReaperHeavyMecha",
    "CelestialSaluteGun"
}
g_SeaCrateUnits = {
    "CelestialWaveriderIFV_Water",
    "AlliedLandingCraftAirCushion",
    "AlliedThetisBattleShip",
    "JapanYumiAircraftCarrier",
    "CelestialSeized_JapanAntiNavyShipTech3",
    "AlliedGaintAirCraftCarrier_B",
}
g_AirCrateUnits = {
    "AlliedAvengerAttackAircraft",
    "WinterArmyKoelAttackUAV",
    "SovietTransportAircraft_HeavyCannon",
}

for i = 1 , getn(g_GroundCrateUnits) , 1 do
    index = index + 1 ;
    UNITLIST [index] = g_GroundCrateUnits[i]
end

index = index + 1 ;
--exMessageAppendToMessageArea("indexHEAVYVEH"..index)
step3 = index-1
--index = 151
-- 天狗、心神按飞机批次登场，并使用飞机队伍及出生时序。
UNITLIST [index] = "JapanAntiInfantryVehicle"
index = index + 1 ;
UNITLIST [index] = "JapanMissileMechaAdvanced"
index = index + 1 ;
UNITLIST [index] = "JapanScoutInfantry"
index = index + 1 ;
UNITLIST [index] = "CelestialScoutDrone"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiGroundAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedAC130GunshipAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiStructureBomberAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedBomberAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedGunshipAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedInterceptorAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedNightinaleHelicopter"
index = index + 1 ;
UNITLIST [index] = "AlliedSupportAircraft"
index = index + 1 ;
UNITLIST [index] = "AlliedFighterAircraft"
index = index + 1 ;
-- UNITLIST [index] = "CelestialAdvanceAircraftTech4"
-- index = index + 1 ;
UNITLIST [index] = "CelestialBomberAircraft"
index = index + 1 ;
UNITLIST [index] = "CelestialFighterAircraft"
index = index + 1 ;
UNITLIST [index] = "CelestialAttackerAircraft"
index = index + 1 ;
UNITLIST [index] = "CelestialInterceptorAircraft"
index = index + 1 ;
UNITLIST [index] = "JapanAntiVehicleInfantryTech3"
index = index + 1 ;
UNITLIST [index] = "JapanInterceptorAircraft"
index = index + 1 ;
UNITLIST [index] = "SovietAntiGroundAircraft"
index = index + 1 ;
UNITLIST [index] = "SovietAntiGroundAttacker"
index = index + 1 ;
UNITLIST [index] = "SovietFighterAircraft"
index = index + 1 ;
UNITLIST [index] = "SovietTransportAircraft"
index = index + 1 ;
UNITLIST [index] = "SovietInterceptorAircraft"
index = index + 1 ;
UNITLIST [index] = "CelestialSupportAircraft"
index = index + 1 ;
UNITLIST [index] = "CelestialAdvanceAircraftTech4"

for i = 1 , getn(g_AirCrateUnits) , 1 do
    index = index + 1 ;
    UNITLIST [index] = g_AirCrateUnits[i]
end

index = index + 1 ;
step35 = index-1
UNITLIST [index] = "JapanAntiStructureShip"
index = index + 1 ;
UNITLIST [index] = "SovietAntiStructureShip"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiStructureShip"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiStructureShip"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiInfantryVehicle"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiAirShip"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiNavalScout"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiNavyShipTech3"
index = index + 1 ;
UNITLIST [index] = "CelestialAlmightlyShip"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiNavyShipTech1"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiNavyShipTech3"
index = index + 1 ;
UNITLIST [index] = "JapanAntiVehicleShip"
index = index + 1 ;
UNITLIST [index] = "JapanNavyScoutShip"
index = index + 1 ;
-- 海翼属于海军：启用海军时以潜艇形态从海军生成点登场。
UNITLIST [index] = "JapanAntiAirShip"
index = index + 1 ;
UNITLIST [index] = "JapanAntiNavyShipTech3"
index = index + 1 ;
UNITLIST [index] = "SovietAntiNavyShipTech2"
index = index + 1 ;
UNITLIST [index] = "SovietAntiNavyShipTech3"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiNavyShipTech1"
index = index + 1 ;
UNITLIST [index] = "SovietAntiNavyShipTech1"

-- 海上箱子单位
for i = 1 , getn(g_SeaCrateUnits) , 1 do
    index = index + 1 ;
    UNITLIST [index] = g_SeaCrateUnits[i]
end

index = index + 1 ;
--UNITLIST [index] = "JapanFortressShip"
--index = index + 1 ;
--UNITLIST [index] = "JapanGigaFortressShip"
--index = index + 1 ;
--exMessageAppendToMessageArea("indexAIR"..index)
step4 = index-1
UNITLIST [index] = "SovietBomberAircraft"
index = index + 1 ;
UNITLIST [index] = "CelestialAntiAirVehicleTech3"
index = index + 1 ;
step5= index-1
UNITLIST [index] = "SovietAntiAirShip"
index = index + 1 ;
UNITLIST [index] = "AlliedAntiAirVehicleTech1"
index = index + 1 ;
UNITLIST [index] = "AlliedAirForceDispatchVehicle"
index = index + 1 ;
UNITLIST [index] = "JapanAntiAirVehicleTech3"
index = index + 1 ;
UNITLIST [index] = "SovietElectronicRadarTruck"
index = index + 1 ;
step6= index-1
unitcountmax = index-1
-----------------------------------------
for playindex = 1 , 6 , 1 do
    UNITCOUNT[playindex] = {}
    CRATEUNITCOUNT[playindex] = {}
    for unitindex = 1 , unitcountmax , 1 do
        UNITCOUNT[playindex][unitindex] = 0 ;
        CRATEUNITCOUNT[playindex][unitindex] = 0 ;
    end
end
--exMessageAppendToMessageArea("二维数组完毕")
----------------------------------------------
for i = 1 , unitcountmax , 1 do
    FilterLIST[i]=CreateObjectFilter({
        Rule="ANY",
        Relationship="SAME_PLAYER",
        IncludeThing = {
            UNITLIST[i],
        },
    })
    g_UnitNameToUnitIndex[UNITLIST[i]] = i
    g_UnitNameToUnitIndex[FastHash(UNITLIST[i])] = i
end
-- 摇光普通/强化形态共享同一个自走棋计数槽。
local yaoguangIndex = g_UnitNameToUnitIndex["CelestialAdvanceAircraftTech4"]
if yaoguangIndex ~= nil then
    FilterLIST[yaoguangIndex] = CreateObjectFilter({
        Rule="ANY",
        Relationship="SAME_PLAYER",
        IncludeThing = {
            "CelestialAdvanceAircraftTech4",
            "CelestialAdvanceAircraftTech4_Enhanced"
        }
    })
    g_UnitNameToUnitIndex["CelestialAdvanceAircraftTech4_Enhanced"] = yaoguangIndex
    g_UnitNameToUnitIndex[FastHash("CelestialAdvanceAircraftTech4_Enhanced")] = yaoguangIndex
end
--exMessageAppendToMessageArea("过滤器完毕")
----------------------------------------------------------------
function unitgetcountanddelet (playindex)
    --exMessageAppendToMessageArea("unitgetcountanddelet")
    -- 先让单位下车
    for unitindex = 1 , unitcountmax , 1 do
        local TAR, count = ObjectFindObjects(P[playindex], nil, FilterLIST[unitindex])
        for i = 1 , count , 1  do
            if ObjectGetContainerObject(TAR[i]) ~= nil then
                ExecuteAction("NAMED_EXIT_BUILDING", TAR[i])
            end
        end
    end
    -- 然后再计数
    for unitindex = 1 , unitcountmax , 1 do
        local TAR, count = ObjectFindObjects(P[playindex], nil, FilterLIST[unitindex])

        if count > 0 then
            for i = 1 , count , 1  do
                local unitId = ObjectGetId(TAR[i])
                if ObjectIsAlive(unitId) then
                    -- 如果有精确匹配的 index，优先使用该 index
                    local actualUnitIndex = g_UnitNameToUnitIndex[ObjectGetInstanceId(unitId)]
                    if not actualUnitIndex then
                        actualUnitIndex = unitindex
                    end
                    -- 检查箱子单位
                    local producer = ObjectGetProducerObject(unitId)
                    if producer == nil then
                        -- 没有生产者的单位，说明是箱子单位
                        CRATEUNITCOUNT[playindex][actualUnitIndex] = CRATEUNITCOUNT[playindex][actualUnitIndex] + 1
                    end
                    ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
                    UNITCOUNT[playindex][actualUnitIndex] = UNITCOUNT[playindex][actualUnitIndex] + 1

                    -- 每两个 JapanAntiInfantryInfantry 赠送一个 JapanKamikazeInfantry
                    if UNITLIST[actualUnitIndex] == "JapanAntiInfantryInfantry" then
                        local playerGiftState = g_PlayerGiftStates[playindex]
                        local kamikazeState = playerGiftState.GiftJapanKamikazeInfantry or 0
                        kamikazeState = kamikazeState + 1
                        if kamikazeState >= 2 then
                            kamikazeState = 0
                            -- 赠送一个 JapanKamikazeInfantry
                            ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
                            local kamikazeIndex = g_UnitNameToUnitIndex["JapanKamikazeInfantry"]
                            UNITCOUNT[playindex][kamikazeIndex] = UNITCOUNT[playindex][kamikazeIndex] + 1
                        end
                        playerGiftState.GiftJapanKamikazeInfantry = kamikazeState
                    end

                    -- 暂停：与帝国武士相同，每生产两个苏联动员兵，额外记入一个动员兵。
                    -- if UNITLIST[actualUnitIndex] == "SovietAntiInfantryInfantry" then
                    --     local playerGiftState = g_PlayerGiftStates[playindex]
                    --     local conscriptState = playerGiftState.GiftSovietAntiInfantryInfantry or 0
                    --     conscriptState = conscriptState + 1
                    --     if conscriptState >= 2 then
                    --         conscriptState = 0
                    --         ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
                    --         local conscriptIndex = g_UnitNameToUnitIndex["SovietAntiInfantryInfantry"]
                    --         UNITCOUNT[playindex][conscriptIndex] = UNITCOUNT[playindex][conscriptIndex] + 1
                    --     end
                    --     playerGiftState.GiftSovietAntiInfantryInfantry = conscriptState
                    -- end
                end
                ExecuteAction("NAMED_DELETE", TAR[i])
            end
        end
    end
    --exMessageAppendToMessageArea("unitgetcountanddeletdone")
end
--exMessageAppendToMessageArea("定义函数1完毕")
-------------------------------------------------------------------------------
function UpdateNoNavyTeslaBoatBuildability()
    if g_DisableSeaArmy ~= 1 or g_NoNavyTeslaBoatUnlocked == 1 then
        return
    end
    if exCounterGetByName("lvc") < 3 then
        return
    end
    for playindex = 1, 6, 1 do
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "SovietAntiNavyShipTech1", 1)
    end
    g_NoNavyTeslaBoatUnlocked = 1
end

function unitgenerate ()
    UpdateNoNavyTeslaBoatBuildability()
    ----exMessageAppendToMessageArea("unitgenerate")
    for playindex = 1 , 6 , 1 do
        local units, unitsCount = CopyPlayerRegisteredObjectSet("Player_"..playindex, "UNITS")
        if unitsCount > 0 then
            unitgetcountanddelet (playindex)
            --exMessageAppendToMessageArea("unitgeneratedone")
        end
    end
end
--exMessageAppendToMessageArea("定义函数2完毕")

CAIRTECH4limitc = {}
bigshiplimitc = {}

function bigshiplimit()
    --exMessageAppendToMessageArea("ACT")
    for i = 1 , 6 , 1 do
        bigshiplimitc[i] = UNITCOUNT[i][step35+4] +  UNITCOUNT[i][step35+1] +  UNITCOUNT[i][step35+2] +  UNITCOUNT[i][step35+3]
        CAIRTECH4limitc[i] = UNITCOUNT[i][step35]
        --exMessageAppendToMessageArea(" bigshiplimitc[i]".. bigshiplimitc[i])
        exCounterSetByName("bigshiplimit"..i,  bigshiplimitc[i]);
        exCounterSetByName("CAIRTECH4limit"..i,  CAIRTECH4limitc[i]);
    end
end
