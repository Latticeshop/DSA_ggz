
--- 浪人鬼王HP*1.5，浪人去除无限弹匣
--- 忍者岚影刺鬼王X攻速射程增加
---雅典娜攻速*1.4
---重锤计蒙伤害75%
---剃刀太刀攻击*1.2




FilterJapanSentinelVehicle=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "JapanSentinelVehicle","JapanAntiVehicleVehicleTech3","JapanMechaX","JapanMissileMechaAdvanced","CelestialAntiVehicleVehicleTech4","AlliedAntiVehicleVehicleTech1","CelestialAntiVehicleVehicleTech1","JapanAntiVehicleVehicleTech1","SovietHeavyAntiVehicleVehicleTech2"
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
        "SovietSledgehammerSPG","CelestialAlmightlyShip"
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

FilterJapanShip=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "JapanAntiNavyShipTech3","JapanAntiVehicleShip"
    }
})



function JapanShipBUFF ()
    local TAR , COUNTX = ObjectFindObjects(nil, nil, FilterJapanShip)
    for i = 1 , COUNTX ,1 do
        ObjectLoadAttributeModifier(TAR[i], "AttributeMod_CenturionUpgradeLv1",9999)
    end
end


FilterCelestialLongRangeMissileVehicle=CreateObjectFilter({
    Rule="ANY",

    IncludeThing = {
        "CelestialLongRangeMissileVehicle"
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
        "JapanMechaX","CelestialAntiVehicleInfantry","JapanAntiAirVehicleTech1"
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
        "CelestialSupportAircraft"
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
        "CelestialBomberAircraft","SovietHeavyAntiVehicleInfantry",
        "AlliedGunshipAircraft","CelestialAntiVehicleVehicleTech4"
    }
})

FilterSovietBomberAircraft=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "SovietBomberAircraft"
    }
})

FilterSovietHeavyTankTech4=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "SovietAntiVehicleVehicleTech4",
        "SovietAntiVehicleVehicleTech4_Enhanced"
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
        "SovietInterceptorAircraft"
    }
})

FilterCelestialInterceptorAircraft=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
        "CelestialInterceptorAircraft"
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

    -- 联盟重型坦克：在现有属性基础上再叠加 1.25 倍生命。
    local HeavyTank , HeavyTankCount = ObjectFindObjects(nil, nil, FilterSovietHeavyTankTech4)
    for i = 1 , HeavyTankCount ,1 do
        ObjectLoadAttributeModifier(HeavyTank[i], "AttributeMod_CenturionUpgradeLeaderLv1",9999)
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
end
