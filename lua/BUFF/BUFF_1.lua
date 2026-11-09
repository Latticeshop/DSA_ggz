-- 讲解见 analysis/地图注释说明文档.md 附录 A.21

FilterJapanSentinelVehicle=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "JapanSentinelVehicle","JapanAntiVehicleVehicleTech3","JapanMechaX","JapanMissileMechaAdvanced","CelestialAntiVehicleVehicleTech4","AlliedAntiVehicleVehicleTech1","CelestialAntiVehicleVehicleTech1","JapanAntiVehicleVehicleTech1","SovietHeavyAntiVehicleVehicleTech2",
        -- 衍生形态（g_PureDrawProductionAliases）
        "JapanAntiVehicleVehicleTech3_Movie","JapanKingOniXMecha_Enhanced","JapanMissileMechaAdvanced_Enhanced","JapanMissileMechaAdvanced_Enhanced_Water","CelestialAntiVehicleVehicleTech4_Enhanced","CelestialAntiVehicleVehicleTech4_S01","AlliedAntiVehicleVehicleTech1_Enhanced","CelestialAntiVehicleVehicleTech1_EMC","JapanAntiVehicleVehicleTech1_Naval","SovietHeavyAntiVehicleVehicleTech2_Enhanced"
    }
})


function JapanSentinelVehicleBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterJapanSentinelVehicle)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_GunshipBOSSAIUnitCheat",9999)
    end
end

FilterLONGRANGEANTIINFANT=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "JapanInfiltrationInfantry",
    }
})

--瑶光
function LONGRANGEANTIINFANTBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterLONGRANGEANTIINFANT)
    for i = 1 , COUNTX ,1 do
        ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(TAR[i], 10, 10, 10, 10)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxRangeUp",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_CelestialZhuRongRapidFire",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_CelestialInterceptorRapidFire",9999)
    end
end

FilterAlliedAntiStructureVehicle=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "AlliedAntiStructureVehicle",
        "AlliedAntiStructureVehicle_Enhanced",
    }
})


function AlliedAntiStructureVehicleBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterAlliedAntiStructureVehicle)
    for i = 1 , COUNTX ,1 do
        local instanceId = exObjectGetInstanceId(ObjectGetId(TAR[i]))
        -- exMessageAppendToMessageArea("AlliedAntiStructureVehicleBUFF instance id:"..instanceId)
        if instanceId ~= -234022367 then
            -- exMessageAppendToMessageArea("AlliedAntiStructureVehicleBUFF zhurong buff")
            ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_CelestialZhuRongRapidFire",9999)
        end
        -- local rateOfFire = ObjectGetAttributeModifier(TAR[i], "RATE_OF_FIRE")
        -- exMessageAppendToMessageArea("AlliedAntiStructureVehicleBUFF rate of fire:"..rateOfFire)
    end
end

FilterDamange75Percent=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "SovietSledgehammerSPG","CelestialAlmightlyShip",
        -- 衍生形态（g_PureDrawProductionAliases）；这条是减益，形态也必须一起减，
        -- 否则变成「转成强化形态就躲掉 25% 伤害惩罚」。
        "SovietSledgehammerSPG_Enhanced","CelestialAlmightlyShip_AA","CelestialAlmightlyShip_Enhanced","CelestialAlmightlyShip_FireWork","CelestialAlmightlyShip_Old"
    }
})
--重锤,激萌,宫女DEBUFF

function JapanAntiStructureVehicleBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterDamange75Percent)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxDamageMultDown",9999)
        -- ObjectLoadAttributeModifier(TAR[i], "HardAISinglePlayer_Bonus",9999)
    end
end


FilterCelestialLongRangeMissileVehicle=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        -- 生产池里青锋是 _B（UNITLIST 里就是它），"CelestialLongRangeMissileVehicle" 是它的
        -- 变形形态别名（见 02_data.lua 的 g_PureDrawProductionAliases 反向条目），两个都要列，
        -- 只写裸名会让上场的那一型完全吃不到射程强化。
        "CelestialLongRangeMissileVehicle_B","CelestialLongRangeMissileVehicle"
    }
})



function CelestialLongRangeMissileVehicleBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterCelestialLongRangeMissileVehicle)
    for i = 1 , COUNTX ,1 do
        --ObjectLoadAttributeModifier(TAR[i], "AttributeMod_AlliedPrismAttackBoost",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxRangeUp",9999)
    end
end



FilterMIDDLEENHANCE=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "JapanMechaX","CelestialAntiVehicleInfantry","JapanAntiAirVehicleTech1",
        -- 衍生形态（g_PureDrawProductionAliases）
        "JapanKingOniXMecha_Enhanced","CelestialAntiVehicleInfantry_EMC","JapanAntiAirVehicleTech1_Enhanced","JapanAntiAirVehicleTech1_Enhanced_Water"
    }
})

FilterJapanAntiVehicleInfantryTech3=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "JapanAntiVehicleInfantryTech3"
    }
})

--鬼王X



function MIDDLEENHANCEBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterMIDDLEENHANCE)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_AlliedPrismAttackBoost",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxRangeUp",9999)
    end

    -- 岚影刺使用祝融射速/射程强化，不叠加上面的通用强化。
    local LanYingCi , LanYingCiCount = ObjectFindObjects(nil, nil, FilterJapanAntiVehicleInfantryTech3)
    for i = 1 , LanYingCiCount ,1 do
        ObjectLoadAttributeModifier(LanYingCi[i], "AttributeModifier_CelestialZhuRongRapidFire",9999)
    end
end



FilterANTIGROUNDAIRCRAFT=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "CelestialAttackerAircraft","AlliedSupportAircraft","SovietAntiGroundAircraft","SovietAntiGroundAttacker",
        "CelestialSupportAircraft",
        -- 衍生形态（g_PureDrawProductionAliases）
        "AlliedSupportAircraft_Enhanced","SovietAntiGroundAircraft_Enhanced","SovietAntiGroundAttacker_Enhanced"
    }
})

--冰人

function ANTIGROUNDAIRCRAFTBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterANTIGROUNDAIRCRAFT)
    --exMessageAppendToMessageArea("COUNTX:"..COUNTX)
    for i = 1 , COUNTX ,1 do
        --ObjectLoadAttributeModifier(TAR[i], "AttributeMod_GunshipBOSSAIUnitCheat",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_AlliedPrismAttackBoost",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxRangeUp",9999)
    end
end

-- FilterCelestialAntiInfantryInfantryAdvanced=CreateObjectFilter({
--     Rule="ANY",

--     IncludeThing = {
--         "SovietHeavyAntiVehicleInfantry"
--     }
-- })

-- function CelestialAntiInfantryInfantryAdvancedBUFF ()
--     local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterCelestialAntiInfantryInfantryAdvanced)
--     --exMessageAppendToMessageArea("COUNTX:"..COUNTX)
--     for i = 1 , COUNTX ,1 do
--         ObjectLoadAttributeModifier(TAR[i], "AttributeMod_GenericBOSSAIUnitCheat",9999)
--     end
-- end

FilterCelestialAntiInfantryInfantryAdvancedSINGLE=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "CelestialAntiInfantryInfantry"
    }
})

function CelestialAntiInfantryInfantryAdvancedSINGLEBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterCelestialAntiInfantryInfantryAdvancedSINGLE)
    --exMessageAppendToMessageArea("COUNTX:"..COUNTX)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_AlliedPrismAttackBoost",9999)
    end
end


FilterLARGEENHANCE=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        -- 它改吃下方的磁爆组（伤害 ×2 + 射程 ×1.25，无生命）。
        "CelestialBomberAircraft",
        "AlliedGunshipAircraft","CelestialAntiVehicleVehicleTech4",
        -- 衍生形态（g_PureDrawProductionAliases）
        "CelestialBomberAircraft_Enhanced",
        "CelestialAntiVehicleVehicleTech4_Enhanced","CelestialAntiVehicleVehicleTech4_S01"
        -- 先锋炮艇机的其余形态故意不列：标准型吃这里的 1.5 倍生命，其余形态由
        -- FilterAlliedGunshipAircraftAll 统一给 2 倍（见 LARGEENHANCEBUFF 里的注释）。
    }
})

FilterSovietBomberAircraft=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "SovietBomberAircraft",
        "SovietBomberAircraft_Movie"
    }
})

-- 先锋武装炮艇机的普通、强化、AC-130 和信标形态统一计算。
FilterAlliedGunshipAircraftAll=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "AlliedGunshipAircraft",
        "AlliedGunshipAircraft_Enhanced",
        "AlliedAC130GunshipAircraft",
        "AlliedChronoBeacon_Harbinger"
    }
})

FilterSovietInterceptorAircraft=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "SovietInterceptorAircraft",
        "SovietInterceptorAircraft_Enhanced"
    }
})

FilterCelestialInterceptorAircraft=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "CelestialInterceptorAircraft",
        "CelestialInterceptorAircraft_Enhanced"
    }
})

FilterAlliedCryoLegionnaire=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "AlliedCryoLegionnaire"
    }
})

FilterJapanInterceptorAircraft=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "JapanInterceptorAircraft",
        "JapanInterceptorAircraft_Ground",
        "JapanInterceptorAircraft_WarfactoryWater"
    }
})

FilterSovietTeslaBoat=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "SovietAntiNavyShipTech1",
        -- 衍生形态（g_PureDrawProductionAliases）
        "SovietAntiNavyShipTech1_AirAssault","SovietAntiNavyShipTech1_Enhanced"
    }
})

-- 磁爆组（2026-11）：苏联三件套统一吃「伤害 ×2 + 射程 ×1.25」，**一律不给生命加成**。
FilterTeslaBoost=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "SovietHeavyAntiVehicleInfantry","SovietHeavyAntiVehicleInfantry_Enhanced",
        "SovietAntiVehicleVehicleTech2",
        "SovietAntiNavyShipTech1","SovietAntiNavyShipTech1_AirAssault","SovietAntiNavyShipTech1_Enhanced"
    }
})

function TESLABOOSTBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterTeslaBoost)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_AlliedTeslaBoost",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxRangeUp",9999)
    end
end

if not g_SukhoiHealthX2Modifier then
    g_SukhoiHealthX2Modifier = exAttributeModifierCreate({ HEALTH_MULT = 2.0 }, 1)
end
if not g_CelestialInterceptorRangeX075Modifier then
    g_CelestialInterceptorRangeX075Modifier = exAttributeModifierCreate({ RANGE = 0.75 }, 1)
end
if not g_CryoLegionnaireRateOfFireX075Modifier then
    g_CryoLegionnaireRateOfFireX075Modifier = exAttributeModifierCreate({ RATE_OF_FIRE = 0.75 }, 1)
end
if not g_JapanInterceptorHealthX3Modifier then
    g_JapanInterceptorHealthX3Modifier = exAttributeModifierCreate({ HEALTH_MULT = 3.0 }, 1)
end
if not g_AlliedGunshipHealthX2Modifier then
    g_AlliedGunshipHealthX2Modifier = exAttributeModifierCreate({ HEALTH_MULT = 2.0 }, 1)
end
if not g_SovietTeslaBoatRateOfFireX125Modifier then
    -- 磁爆快艇仅增加25%攻速，不混入现有组合式伤害/射程 Buff。
    g_SovietTeslaBoatRateOfFireX125Modifier = exAttributeModifierCreate({ RATE_OF_FIRE = 1.25 }, 1)
end


function LARGEENHANCEBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterLARGEENHANCE)
    --exMessageAppendToMessageArea("COUNTX:"..COUNTX)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_GunshipBOSSAIUnitCheat",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_AlliedTeslaBoost",9999)
        ObjectLoadAttributeModifier(TAR[i], "AttributeModifier_BoxRangeUp",9999)
    end

    -- 基洛夫：200% 移速 Buff 叠加蜻蜓的 50% 减速，最终为 150% 移速。
    local Kirov , KirovCount = ObjectFindObjects(nil, nil, FilterSovietBomberAircraft)
    for i = 1 , KirovCount ,1 do
        ObjectLoadAttributeModifier(Kirov[i], "AttributeModifier_JapanAntiVehicleVehicleTech3RushAttack",9999)
        ObjectLoadAttributeModifier(Kirov[i], "AttributeMod_JapanScoutInfantrySlowAttached",9999)
    end

    -- 先锋全部形态加载 2 倍生命 Buff；标准型还会与上方原有 1.5 倍 Buff 叠加至 3 倍。
    local Gunship , GunshipCount = ObjectFindObjects(nil, nil, FilterAlliedGunshipAircraftAll)
    for i = 1 , GunshipCount ,1 do
        ObjectLoadAttributeModifier(Gunship[i], g_AlliedGunshipHealthX2Modifier)
    end

    -- 苏霍伊：保留原有伤害、射程强化，将生命值从 1.5 倍改为精确 2 倍。
    local Sukhoi , SukhoiCount = ObjectFindObjects(nil, nil, FilterSovietInterceptorAircraft)
    for i = 1 , SukhoiCount ,1 do
        ObjectLoadAttributeModifier(Sukhoi[i], g_SukhoiHealthX2Modifier)
        ObjectLoadAttributeModifier(Sukhoi[i], "AttributeMod_AlliedTeslaBoost",9999)
        ObjectLoadAttributeModifier(Sukhoi[i], "AttributeModifier_BoxRangeUp",9999)
    end

    -- 重明截击机：射程下调 25%，保留原射程的 0.75 倍。
    local Chongming , ChongmingCount = ObjectFindObjects(nil, nil, FilterCelestialInterceptorAircraft)
    for i = 1 , ChongmingCount ,1 do
        ObjectLoadAttributeModifier(Chongming[i], g_CelestialInterceptorRangeX075Modifier)
    end

    -- 冷冻军团：保留生命、伤害和 25% 攻速削减，不再加载任何射程 Buff。
    local CryoLegionnaire , CryoLegionnaireCount = ObjectFindObjects(nil, nil, FilterAlliedCryoLegionnaire)
    for i = 1 , CryoLegionnaireCount ,1 do
        ObjectLoadAttributeModifier(CryoLegionnaire[i], "AttributeMod_GunshipBOSSAIUnitCheat",9999)
        ObjectLoadAttributeModifier(CryoLegionnaire[i], "AttributeMod_AlliedTeslaBoost",9999)
        ObjectLoadAttributeModifier(CryoLegionnaire[i], g_CryoLegionnaireRateOfFireX075Modifier)
    end

    -- 樱花回天雷：覆盖空中、地面和船厂水面三种形态，生命值提升为 3 倍。
    local SakuraMine , SakuraMineCount = ObjectFindObjects(nil, nil, FilterJapanInterceptorAircraft)
    for i = 1 , SakuraMineCount ,1 do
        ObjectLoadAttributeModifier(SakuraMine[i], g_JapanInterceptorHealthX3Modifier)
    end

    -- 磁爆快艇：纯25%攻速强化，水面与禁海模式下的陆地形态使用同一单位模板。
    local TeslaBoat , TeslaBoatCount = ObjectFindObjects(nil, nil, FilterSovietTeslaBoat)
    for i = 1 , TeslaBoatCount ,1 do
        ObjectLoadAttributeModifier(TeslaBoat[i], g_SovietTeslaBoatRateOfFireX125Modifier)
    end

    -- 磁爆组（部队 / 坦克 / 快艇）：伤害 ×2 + 射程 ×1.25，无生命加成。
    -- 放在本函数末尾调用，是为了跟着 BUFFACTONCE__AIR 这个「每回合出兵后 / 每次补充军队」
    -- 的既有节点走，不必新开 WB 脚本节点（ScriptsData 里的脚本树不动）。
    TESLABOOSTBUFF ()
end
