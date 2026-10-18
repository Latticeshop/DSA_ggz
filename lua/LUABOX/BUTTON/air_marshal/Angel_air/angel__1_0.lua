for i=3,4,1 do
local wuti = GetObjectByScriptName("angel"..i)
RegisterSkillSummonedUnit(wuti)
for levelindex=1,5,1 do
ExecuteAction("UNIT_GAIN_LEVEL", wuti, 1)
end
ObjectLoadAttributeModifier(wuti,'AttributeMod_GenericSpeedSet200',300000000)
for i=1,5,1 do
ObjectLoadAttributeModifier(wuti,'AttributeModifier_CelestialZhuRongRapidFire',300000000)
end
ObjectLoadAttributeModifier(wuti,'AttributeMod_JapanShipBOSSAIUnitCheat',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeModifier_Buff3',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeMod_GenericBOSSAIUnitCheat',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeModifier_BoxDamageMultUp',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeModifier_BoxAttackSuperUp',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeMod_LongYanWeaponBOSSAICheat',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeModifier_BoxRangeSuperUp',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeModifier_BoxRangeUp',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeMod_JapanCommandoSpeedReduce02',300000000)
ObjectLoadAttributeModifier(wuti,'AttributeModifier_CelestialInterceptorRapidFire',300000000)
ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(wuti, 1, 1, 1,100000)   
 ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(wuti, 1, 1, 2,100000)
    ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(wuti, 1, 1, 3,100000)
    ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(wuti, 1, 1, 4,100000)
    ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(wuti, 1, 1, 5,100000)
end