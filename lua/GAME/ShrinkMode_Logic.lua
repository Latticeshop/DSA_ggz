g_ShrinkFilter1 = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="INFANTRY VEHICLE AIRCRAFT",
})

g_ShrinkFilter2 = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="VEHICLE",
})

function ShrinkMode_Setting()
    if g_EnableDeathModeEffect == 1 then
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "ShrinkMode741", 'SovietBaseDefenseAdvanced', 'PlyrCivilian/teamPlyrCivilian', 'TD7_2')
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "ShrinkMode742", 'SovietHeavyAntiAirMissileTurret', 'PlyrCivilian/teamPlyrCivilian', 'TD7_2')
        local ShrinkMode741 = GetObjectByScriptName("ShrinkMode741")
        for i = 1, 20, 1 do
            ObjectLoadAttributeModifier(ShrinkMode741,'AttributeModifier_MAP_RATE_OF_FIRE_Up', 999999)
        end

        local ShrinkMode742 = GetObjectByScriptName("ShrinkMode742")
        for i = 1, 5, 1 do
            ObjectLoadAttributeModifier(ShrinkMode742,'AttributeModifier_MAP_RATE_OF_FIRE_Up', 999999)
        end
        ExecuteAction("NAMED_SET_MAX_HEALTH", "ShrinkMode741", 30000, 1)
        ExecuteAction("NAMED_SET_MAX_HEALTH", "ShrinkMode742", 30000, 1)

        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "ShrinkMode841", 'SovietBaseDefenseAdvanced', 'PlyrCreeps/teamPlyrCreeps', 'TD8_2')
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", "ShrinkMode842", 'SovietHeavyAntiAirMissileTurret', 'PlyrCreeps/teamPlyrCreeps', 'TD8_2')
        local ShrinkMode841 = GetObjectByScriptName("ShrinkMode841")
        for i = 1, 20, 1 do
            ObjectLoadAttributeModifier(ShrinkMode841,'AttributeModifier_MAP_RATE_OF_FIRE_Up', 999999)
        end

        local ShrinkMode842 = GetObjectByScriptName("ShrinkMode842")
        for i = 1, 5, 1 do
            ObjectLoadAttributeModifier(ShrinkMode842,'AttributeModifier_MAP_RATE_OF_FIRE_Up', 999999)
        end
        ExecuteAction("NAMED_SET_MAX_HEALTH", "ShrinkMode841", 30000, 1)
        ExecuteAction("NAMED_SET_MAX_HEALTH", "ShrinkMode842", 30000, 1)

        local T73F = GetObjectByScriptName("T73F")
        ObjectLoadAttributeModifier(T73F,'AttributeModifier_JapanNanoEnhanceDroneReinforcement', 999999)
        local T83F = GetObjectByScriptName("T83F")
        ObjectLoadAttributeModifier(T83F,'AttributeModifier_JapanNanoEnhanceDroneReinforcement', 999999)

    end


    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_1", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_2", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_3", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_4", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_5", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_6", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_7", "AlliedAntiNavalScout", 0)
    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_8", "AlliedAntiNavalScout", 0)

    exWaypointSetPos("PLANEREBORN8", 4300, 4484, 200)
    exWaypointSetPos("PLANEREBORN7", 2684, 4512, 200)


end

function ShrinkMode_Apply()
    local matchedObjects, count = ObjectFindObjects(T74, nil, g_ShrinkFilter1)
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        ObjectLoadAttributeModifier(current,'AttributeMod_AlliedSupportAircraftShrinkRay_HighTechnology', 9999)
    end
    matchedObjects, count = ObjectFindObjects(T84, nil, g_ShrinkFilter1)
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        ObjectLoadAttributeModifier(current,'AttributeMod_AlliedSupportAircraftShrinkRay_HighTechnology', 9999)
    end

    matchedObjects, count = ObjectFindObjects(T74, nil, g_ShrinkFilter2)
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        ObjectLoadAttributeModifier(current,'AttributeModifier_JapanNanoEnhanceDroneReinforcement', 9999)
        ObjectLoadAttributeModifier(current,'AttributeModifier_BoxHealSuperUp', 9999)
    end

    matchedObjects, count = ObjectFindObjects(T84, nil, g_ShrinkFilter2)
    for i = 1, count, 1 do
        local current = matchedObjects[i]
        ObjectLoadAttributeModifier(current,'AttributeModifier_JapanNanoEnhanceDroneReinforcement', 9999)
        ObjectLoadAttributeModifier(current,'AttributeModifier_BoxHealSuperUp', 9999)
    end

end