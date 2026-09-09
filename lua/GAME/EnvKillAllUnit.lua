unitallEnv = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing={},
    ExcludeThing={
        "JapanLightTransportVehicle",
        "AlliedNightinaleHelicopter",
        "AlliedMCV",
    },
    Include="SELECTABLE",
    Exclude="STRUCTURE",
})

-- 夜莺也需要被干掉
killableNightinale = CreateObjectFilter({
    Relationship="SAME_PLAYER",
    IncludeThing={ "AlliedNightinaleHelicopter" },
    StatusBitFlagsExclude="STEALTHED",
})

RoundLuaManager.CallOnEveryRoundBegin(function(list)
    local level = exCounterGetByName("lvc")
    if level ~= nil and g_GameMode == 1 then
        if level == 8 or level == 22 then
            exAddTextToPublicBoard(Localization.get("env_kill_all_unit.warning_next_round"), 15)
        end
        if level == 9 or level == 23 then
            exAddTextToPublicBoard(Localization.get("env_kill_all_unit.execute"), 10)
            local units, count = ObjectFindObjects(T74, nil, unitallEnv);
            for i = 1 , count , 1 do
                if not IsTowerGuardian(units[i]) then
                    ExecuteAction("NAMED_KILL", units[i]);
                end
            end

            local units2, count2 = ObjectFindObjects(T84, nil, unitallEnv);
            for i = 1 , count2 , 1 do
                if not IsTowerGuardian(units2[i]) then
                    ExecuteAction("NAMED_KILL", units2[i]);
                end
            end

            local nightinaleUnits, nightinaleCount = ObjectFindObjects(T74, nil, killableNightinale)
            for i = 1 , nightinaleCount , 1 do
                ExecuteAction("NAMED_KILL", nightinaleUnits[i]);
            end

            local nightinaleUnits2, nightinaleCount2 = ObjectFindObjects(T84, nil, killableNightinale)
            for i = 1 , nightinaleCount2 , 1 do
                ExecuteAction("NAMED_KILL", nightinaleUnits2[i]);
            end
        end
    end
end, {  })
