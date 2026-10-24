-- 自由贸易（收入奖励协议）的加钱结算。
FilterFreeTradePower = CreateObjectFilter({
    Rule = "ANY",
    Relationship = "SAME_PLAYER",
    IncludeThing = {
        "AlliedPowerPlant",
        "SovietPowerPlant",
        "JapanPowerPlant",
        "JapanPowerPlantEgg",
        "CelestialPowerPlant"
    }
})
function addmoneyAllied  (money)
    for playindex = 1, 6, 1 do
        local playerName = "Player_"..playindex;
        if EvaluateCondition("NAMED_NOT_DESTROYED", 'PlayerA_' .. playindex) and g_PlayerInDebt[playerName] == 0 then

            local TAR, count = ObjectFindObjects(P[playindex], nil, FilterFreeTradePower)
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
