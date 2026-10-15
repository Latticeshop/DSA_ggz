-- 讲解见 analysis/地图注释说明文档.md 附录 A.47

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
-- 供替换型符文把樱花回天雷的入池计数落到它身上（见 HextechRune.UnitReplacementRunes）。
index = index + 1 ;
UNITLIST [index] = "JapanSakuraAttackRocket"

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
UNITLIST [index] = "SovietPineElectronicRadarTruck"
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
g_BanModeInfantry = g_BanModeInfantry or 0
g_BanModeVehicle = g_BanModeVehicle or 0
g_BanModeAir = g_BanModeAir or 0
g_BanModeOrder = g_BanModeOrder or {}
g_BanModeTypesReady = 0
g_BanModeSlotTypes = {}
g_BanModeNameTypes = {}
-- 与 g_BanModeIds 同序，供 ExtraCommand.lua 的禁用模式子页使用。
g_BanModeIds = { "infantry", "vehicle", "aircraft", "navy" }
-- 回收表 g_RecycleBtnsMapByFaction 的 1..4 类，顺序与 g_BanModeIds 一致。
g_BanModeCategoryTypes = { "infantry", "vehicle", "aircraft", "navy" }

function BanModeDeriveTypesFromRecycle()
    local map = {}
    if g_RecycleBtnsMapByFaction ~= nil then
        for faction = 1, 4, 1 do
            local byCategory = g_RecycleBtnsMapByFaction[faction]
            if byCategory ~= nil then
                for category = 1, 4, 1 do
                    local list = byCategory[category]
                    if list ~= nil then
                        for i = 1, getn(list), 1 do
                            local unitName = list[i].Type
                            if unitName ~= nil and map[unitName] == nil then
                                map[unitName] = g_BanModeCategoryTypes[category]
                            end
                        end
                    end
                end
            end
        end
    end
    if g_CrateUnitsTemplate ~= nil then
        for category = 1, 4, 1 do
            local list = g_CrateUnitsTemplate[category]
            if list ~= nil then
                for i = 1, getn(list), 1 do
                    local unitName = list[i].Type
                    if unitName ~= nil and map[unitName] == nil then
                        map[unitName] = g_BanModeCategoryTypes[category]
                    end
                end
            end
        end
    end
    return map
end

-- 兜底分段：步兵 / 载具 / 飞机 / 海军 / 飞机 / 载具。只在回收系统查不到该名字时使用。
function BanModeFallbackType(unitIndex)
    if unitIndex <= step1 then
        return "infantry"
    elseif unitIndex <= step3 then
        return "vehicle"
    elseif unitIndex <= step35 then
        return "aircraft"
    elseif unitIndex <= step4 then
        return "navy"
    elseif unitIndex <= step5 then
        return "aircraft"
    end
    return "vehicle"
end

-- 只登记「真正的例外」：回收系统推导不出来的，或用户明确改判的。
-- 普通单位的分类一律由 BanModeDeriveTypesFromRecycle() 推出，不要再往这里加。
g_BanModeTypeOverrides = {
    JapanAntiInfantryVehicle = { "vehicle", "aircraft" },
    JapanAntiInfantryVehicle_Enhanced = { "vehicle", "aircraft" },
    JapanAntiInfantryVehicle_Enhanced_Water = { "vehicle", "aircraft" },
    JapanAntiAirVehicleTech1 = { "vehicle", "aircraft" },
    JapanAntiAirVehicleTech1_Enhanced = { "vehicle", "aircraft" },
    JapanAntiAirVehicleTech1_Enhanced_Water = { "vehicle", "aircraft" },
    JapanMissileMechaAdvanced = { "vehicle", "aircraft" },
    JapanMissileMechaAdvanced_Enhanced = { "vehicle", "aircraft" },
    JapanMissileMechaAdvanced_Enhanced_Water = { "vehicle", "aircraft" },
    --    火箭天使：会飞的帝国反装甲步兵 → 步兵 + 飞机
    JapanAntiVehicleInfantryTech3 = { "infantry", "aircraft" },
    --    海翼：潜艇与飞机双形态 → 飞机 + 海军
    JapanAntiAirShip = { "aircraft", "navy" },
    JapanAntiAirShip_Enhanced = { "aircraft", "navy" },
    -- ② 回收表把日本截击机放在载具页，但本图走空军批次，按纯空军算
    JapanInterceptorAircraft = { "aircraft" },
    -- ③ 超级要塞按纯空军算，只禁空军即被禁用。
    JapanGigaFortressShipEgg = { "aircraft" },
    JapanGigaFortressShip = { "aircraft" },
    JapanFortressShip = { "aircraft" },
    JapanGigaFortress_Land = { "aircraft" },
}

function BanModeBuildTypes()
    if g_BanModeTypesReady == 1 then
        return
    end
    -- 本文件的 step1..step6 / unitcountmax 还没建好时不落 ready 标记，下次调用再建。
    if unitcountmax == nil or step1 == nil or step6 == nil then
        return
    end
    g_BanModeTypesReady = 1
    -- 优先用回收系统给的名字→兵种表；查不到再退回分段。
    local fromRecycle = BanModeDeriveTypesFromRecycle()
    for unitIndex = 1, unitcountmax, 1 do
        local unitName = UNITLIST[unitIndex]
        local types = nil
        if unitName ~= nil then
            types = g_BanModeTypeOverrides[unitName]
            if types == nil then
                local derived = fromRecycle[unitName]
                if derived ~= nil then
                    types = { derived }
                end
            end
        end
        if types == nil then
            types = { BanModeFallbackType(unitIndex) }
        end
        g_BanModeSlotTypes[unitIndex] = types
        if unitName ~= nil then
            g_BanModeNameTypes[unitName] = types
        end
    end
    -- 回收表里有、但没有 UNITLIST 槽的名字（例如超级要塞核心）也要能按名查到。
    for unitName, derived in fromRecycle do
        if g_BanModeNameTypes[unitName] == nil then
            g_BanModeNameTypes[unitName] = { derived }
        end
    end
    -- 例外表放最后，确保它压过推导结果。
    for unitName, types in g_BanModeTypeOverrides do
        g_BanModeNameTypes[unitName] = types
    end
end

-- 出兵过滤的豁免名单：只作用于「出兵」这一个入口（BanModeSpawnCount）。
g_BanModeSpawnExempt = {
    AlliedAntiNavyShipTech3 = 1,
    SovietAntiNavyShipTech1 = 1,
}

function BanModeIsTypeBanned(typeName)
    if typeName == "infantry" then
        return g_BanModeInfantry
    elseif typeName == "vehicle" then
        return g_BanModeVehicle
    elseif typeName == "aircraft" then
        return g_BanModeAir
    elseif typeName == "navy" then
        return g_DisableSeaArmy
    end
    return 0
end

function BanModeIsTypeEnabled(typeName)
    if BanModeIsTypeBanned(typeName) == 1 then
        return 0
    end
    return 1
end

-- 一组兵种里只要还有一个没被禁，单位就正常上场（双形态的核心规则）。
function BanModeTypesAllBanned(types)
    if types == nil or getn(types) == 0 then
        return 0
    end
    for i = 1, getn(types), 1 do
        if BanModeIsTypeBanned(types[i]) ~= 1 then
            return 0
        end
    end
    return 1
end

function BanModeGetNameTypes(unitType)
    if g_BanModeTypesReady ~= 1 then
        BanModeBuildTypes()
    end
    local types = g_BanModeNameTypes[unitType]
    if types ~= nil then
        return types
    end
    local unitIndex = g_UnitNameToUnitIndex[unitType]
    if unitIndex == nil then
        return nil
    end
    return g_BanModeSlotTypes[unitIndex]
end

function BanModeIsSlotBanned(unitIndex)
    if g_BanModeTypesReady ~= 1 then
        BanModeBuildTypes()
    end
    return BanModeTypesAllBanned(g_BanModeSlotTypes[unitIndex])
end

-- 按模板名判定；没有 UNITLIST 槽的形态（超级要塞）走 g_BanModeNameTypes。
function BanModeIsNameBanned(unitType)
    return BanModeTypesAllBanned(BanModeGetNameTypes(unitType))
end

-- 出兵函数的内层循环上限：整槽被禁时返回 0，让 for 直接空转（不改铺开逻辑）。
-- 豁免名单（g_BanModeSpawnExempt）里的模板不受这里的影响。
function BanModeSpawnCount(unitIndex, baseMax)
    if BanModeIsSlotBanned(unitIndex) == 1 then
        if g_BanModeSpawnExempt[UNITLIST[unitIndex]] == nil then
            return 0
        end
    end
    return baseMax
end

function BanModeRecycleCategoryEnabled(category)
    return BanModeIsTypeEnabled(g_BanModeCategoryTypes[category])
end

-- 未禁用的兵种列表（顺序与 HextechRune.UnitTypeOrder 一致），供符文候选池使用。
function BanModeEnabledUnitTypes()
    local result = {}
    for i = 1, getn(g_BanModeCategoryTypes), 1 do
        if BanModeIsTypeEnabled(g_BanModeCategoryTypes[i]) == 1 then
            tinsert(result, g_BanModeCategoryTypes[i])
        end
    end
    return result
end

-- 结果池缓存键后缀：四种禁用组合各自缓存一份（禁用配置开局前定稿，每局只建一次）。
function BanModePoolKeySuffix()
    return format("_%d%d%d%d", g_BanModeInfantry, g_BanModeVehicle, g_BanModeAir,
        g_DisableSeaArmy or 0)
end
--exMessageAppendToMessageArea("过滤器完毕")
----------------------------------------------------------------
function GetDrawnUnitNameFromRecycleList(playindex, unitType)
    local playerFaction = g_PlayerSide[playindex]
    if g_RecycleBtnsMapByFaction ~= nil and playerFaction ~= nil then
        for category = 1, 4, 1 do
            local unitInfos = g_RecycleBtnsMapByFaction[playerFaction][category]
            for i = 1, getn(unitInfos), 1 do
                if unitInfos[i].Type == unitType then
                    return unitInfos[i].Name
                end
            end
        end
        for faction = 1, 4, 1 do
            if faction ~= playerFaction then
                for category = 1, 4, 1 do
                    local unitInfos = g_RecycleBtnsMapByFaction[faction][category]
                    for i = 1, getn(unitInfos), 1 do
                        if unitInfos[i].Type == unitType then
                            return unitInfos[i].Name
                        end
                    end
                end
            end
        end
    end
    if g_CrateUnits ~= nil then
        for category = 1, 4, 1 do
            local unitInfos = g_CrateUnits[category]
            for i = 1, getn(unitInfos), 1 do
                if unitInfos[i].Type == unitType then
                    return unitInfos[i].Name
                end
            end
        end
    end
    return Localization.ObjectsTranslate(unitType)
end

-- 登场的要塞自带 4 个标枪兵，现在由装车逻辑（PassengerLoadSpawn）在回合开始就清成空车，
-- 所以它们不会跟着进单位池，回收侧不需要再扣载员额度。
function unitgetcountanddelet (playindex)
    --exMessageAppendToMessageArea("unitgetcountanddelet")
    local drawnUnitCounts = {}
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
        -- 海克斯“登神”：目标单位超出种子数量的部分不进入单位池，直接转为层数。
        if HextechRune ~= nil and HextechRune.FilterAscensionUnits ~= nil then
            TAR, count = HextechRune:FilterAscensionUnits(playindex, unitindex, TAR, count)
        end

        if count > 0 then
            for i = 1 , count , 1  do
                local unitId = ObjectGetId(TAR[i])
                if ObjectIsAlive(unitId) then
                    -- 如果有精确匹配的 index，优先使用该 index
                    local actualUnitIndex = g_UnitNameToUnitIndex[ObjectGetInstanceId(unitId)]
                    if not actualUnitIndex then
                        actualUnitIndex = unitindex
                    end
                    if HextechRune ~= nil
                        and HextechRune.ResolveCollectedUnitIndex ~= nil then
                        actualUnitIndex = HextechRune:ResolveCollectedUnitIndex(
                            playindex, actualUnitIndex)
                    end
                    -- 检查箱子单位
                    local producer = ObjectGetProducerObject(unitId)
                    local isProducedUnit = producer ~= nil
                    if g_PureDrawProducedUnitIds ~= nil
                        and g_PureDrawProducedUnitIds[unitId] then
                        isProducedUnit = true
                    end
                    if not isProducedUnit then
                        -- 没有生产者的单位，说明是箱子单位
                        CRATEUNITCOUNT[playindex][actualUnitIndex] = CRATEUNITCOUNT[playindex][actualUnitIndex] + 1
                        drawnUnitCounts[actualUnitIndex] = (drawnUnitCounts[actualUnitIndex] or 0) + 1
                    end
                    if g_PureDrawProducedUnitIds ~= nil then
                        g_PureDrawProducedUnitIds[unitId] = nil
                    end
                    ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
                    UNITCOUNT[playindex][actualUnitIndex] = UNITCOUNT[playindex][actualUnitIndex] + 1

                    -- 摇光限造 3 个只统计玩家实际生产的单位。
                    -- 海克斯/箱子赠送没有生产者，不增加此独立计数。
                    if isProducedUnit
                        and UNITLIST[actualUnitIndex] == "CelestialAdvanceAircraftTech4"
                        and RecordPlayerProducedYaoguang ~= nil then
                        RecordPlayerProducedYaoguang(playindex, 1)
                    end

                    -- 海克斯“买二送一”：复用狂热武士的回收计数时机。
                    -- 赠送直接写入单位池，不生成待回收实体，因此不会递归计数。
                    if HextechRune ~= nil and HextechRune.OnPlayerUnitCollected ~= nil then
                        HextechRune:OnPlayerUnitCollected(playindex, actualUnitIndex)
                    end

                    if UNITLIST[actualUnitIndex] == "JapanAntiInfantryInfantry"
                        or (UNITLIST[actualUnitIndex] == "JapanKamikazeInfantry"
                            and HextechRune ~= nil
                            and HextechRune.IsKamikazeGiftWarrior ~= nil
                            and HextechRune:IsKamikazeGiftWarrior(playindex)) then
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
                if PureDrawRemoveKnownPlayerUnit ~= nil then
                    PureDrawRemoveKnownPlayerUnit(ObjectGetId(TAR[i]))
                end
                ExecuteAction("NAMED_DELETE", TAR[i])
            end
        end
    end
    -- 登神：任何来源（赠送、箱子等）挤进单位池的多余目标单位同样转为层数。
    if HextechRune ~= nil and HextechRune.TrimAscensionPoolSurplus ~= nil then
        HextechRune:TrimAscensionPoolSurplus(playindex)
    end
    if g_LuckyCrateMode == 1 then
        for unitindex = 1, unitcountmax, 1 do
            local drawnCount = drawnUnitCounts[unitindex] or 0
            if drawnCount > 0 then
                local unitName = GetDrawnUnitNameFromRecycleList(playindex, UNITLIST[unitindex])
                exAddTextToPublicBoardForPlayer("Player_" .. playindex,
                    Localization.get("draw.unit_received", drawnCount, unitName), 5)
            end
        end
    end
    --exMessageAppendToMessageArea("unitgetcountanddeletdone")
end
--exMessageAppendToMessageArea("定义函数1完毕")
-------------------------------------------------------------------------------
g_SovietMortarCycleUnlocked = 0

-- 第一回合起解除地图对火炮机车的禁造；单位自身的原生前置仍由游戏处理。
function UpdateSovietMortarCycleBuildability()
    if g_SovietMortarCycleUnlocked == 1 then
        return
    end
    if exCounterGetByName("lvc") < 1 then
        return
    end
    for playindex = 1, 6, 1 do
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "SovietMortarCycle", 1)
        if PureDrawReapplyPlayerQuota ~= nil then
            PureDrawReapplyPlayerQuota(playindex)
        end
    end
    g_SovietMortarCycleUnlocked = 1
end

function UpdateNoNavyTeslaBoatBuildability()
    if g_DisableSeaArmy ~= 1 or g_NoNavyTeslaBoatUnlocked == 1 then
        return
    end
    if exCounterGetByName("lvc") < 3 then
        return
    end
    for playindex = 1, 6, 1 do
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "SovietAntiNavyShipTech1", 1)
        if PureDrawReapplyPlayerQuota ~= nil then
            PureDrawReapplyPlayerQuota(playindex)
        end
    end
    g_NoNavyTeslaBoatUnlocked = 1
end

function unitgenerate ()
    UpdateSovietMortarCycleBuildability()
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

-- 四种 T4 大船共用一个限造额度（单位池数量，按玩家个人）。讲解见 analysis/地图注释说明文档.md §3。
BIGSHIP_LIMIT = 2
FLAGENBIGSHIP = { 1, 1, 1, 1, 1, 1 }
BigShipBuildTypes = {
    "JapanAntiStructureShip",
    "JapanAntiStructureShip_Enhanced",
    "SovietAntiStructureShip",
    "SovietAntiStructureShip_Enhanced",
    "AlliedAntiStructureShip",
    "AlliedAntiStructureShip_Enhanced",
    "CelestialAntiStructureShip",
    "CelestialAntiStructureShip_Enhanced",
}

function SetBigShipBuildability(playindex, allowed)
    for i = 1, getn(BigShipBuildTypes), 1 do
        ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_"..playindex, BigShipBuildTypes[i], allowed)
    end
end

-- 地编的 bigshiplimit__N 触发器是一次性禁造（DeactivateUponSuccess），卖掉船之后没人负责解禁，
-- 回收后重新开放只能由这里负责；它顺带补上了地编漏掉的 alliedantistructureship_enhanced。
function LIMITBIGSHIP(playindex, bigShipCount)
    if bigShipCount >= BIGSHIP_LIMIT then
        if FLAGENBIGSHIP[playindex] == 1 then
            SetBigShipBuildability(playindex, 0)
            FLAGENBIGSHIP[playindex] = 0
        end
        return
    end
    if FLAGENBIGSHIP[playindex] == 1 then
        return
    end
    FLAGENBIGSHIP[playindex] = 1
    -- 纯抽卡模式对可造性另有完整规则（科技、禁海、解锁回合），重算交给它自己。
    if g_DrawMode == 2 and PureDrawReapplyPlayerQuota ~= nil then
        PureDrawReapplyPlayerQuota(playindex)
        return
    end
    -- 禁海模式海军本就不开放，这里只把状态复位，不替模式解锁。
    if g_DisableSeaArmy == 1 then
        return
    end
    SetBigShipBuildability(playindex, 1)
end

function bigshiplimit()
    --exMessageAppendToMessageArea("ACT")
    for i = 1 , 6 , 1 do
        bigshiplimitc[i] = UNITCOUNT[i][step35+4] +  UNITCOUNT[i][step35+1] +  UNITCOUNT[i][step35+2] +  UNITCOUNT[i][step35+3]
        -- MONEYINI 的定义偶尔晚于本触发器首次执行；未就绪时先显示 0，
        -- 后续调用会自动切回只统计玩家实际生产摇光的正式函数。
        if GetPlayerYaoguangCount ~= nil then
            if ReconcilePlayerProducedYaoguang ~= nil then
                ReconcilePlayerProducedYaoguang(i)
            end
            CAIRTECH4limitc[i] = GetPlayerYaoguangCount(i)
        elseif g_PlayerProducedYaoguangCount ~= nil then
            CAIRTECH4limitc[i] = tonumber(g_PlayerProducedYaoguangCount[i]) or 0
        else
            CAIRTECH4limitc[i] = 0
        end
        --exMessageAppendToMessageArea(" bigshiplimitc[i]".. bigshiplimitc[i])
        exCounterSetByName("bigshiplimit"..i,  bigshiplimitc[i]);
        exCounterSetByName("CAIRTECH4limit"..i,  CAIRTECH4limitc[i]);
        LIMITBIGSHIP(i, bigshiplimitc[i])
    end
end
