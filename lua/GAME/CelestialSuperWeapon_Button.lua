CelestialSuperWeapon_Filter = CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing={"CelestialSuperWeapon"}
})

SchedulerModule.call_every_x_frame(function()
    if g_CelestialSuperWeapon_Get then
        for i = 1 , 8 , 1 do
            if g_CelestialSuperWeapon_Get[i] == 0 then
                local cankao = GetObjectByScriptName("wan" .. i)
                local objects, count = ObjectFindObjects(cankao, nil, CelestialSuperWeapon_Filter)
                if count > 0 and not EvaluateCondition("UNIT_HAS_MODELCONDITION", objects[1], "STRUCTURE_UNPACKING") then
                    g_CelestialSuperWeapon_Get[i] = 1
                    CenterTopBtnFunc_UpdatePlayer3rdButton(i)
                end
            end
        end
    end

end, 20, nil)