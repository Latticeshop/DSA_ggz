FilterPowerCelestial = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    IncludeThing = {
        "CelestialPowerPlant"
    }
})

function addmoneyCelestial  (money)
    for playindex = 1, 8, 1 do
        local playerName = "Player_"..playindex;
        if ObjectIsAlive(P[playindex]) and g_PlayerInDebt[playerName] == 0 then
            local TAR, count = ObjectFindObjects(P[playindex], nil, FilterPowerCelestial)
            for i = 1, count, 1 do
                if not EvaluateCondition("UNIT_HAS_MODELCONDITION", TAR[i], "STRUCTURE_UNPACKING") then
                    ExecuteAction("PLAYER_GIVE_MONEY", "Player_" .. playindex, money)

                    local objectId = ObjectGetId(TAR[i])
                    exShowFloatingIntAtObject(objectId, money)
                end
            end
        end

    end
end

