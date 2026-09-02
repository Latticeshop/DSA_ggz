FilterPowerPlantOrEggNotCelestial=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        'JapanPowerPlantEgg',"AlliedPowerPlant","JapanPowerPlant","SovietPowerPlant"
    }
})

-- ADDMONEY 可能早于 BasicVar1 执行，先为欠债状态提供安全默认值。
g_PlayerInDebt = g_PlayerInDebt or {}
for i = 1, 6, 1 do
    local playerName = "Player_" .. i
    if g_PlayerInDebt[playerName] == nil then
        g_PlayerInDebt[playerName] = 0
    end
end

FilterAnyPowerPlantOrEgg=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        'CelestialPowerPlant','JapanPowerPlantEgg',"AlliedPowerPlant","JapanPowerPlant","SovietPowerPlant"
    }
})

FilterPlayerYaoguang=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialAdvanceAircraftTech4",
        "CelestialAdvanceAircraftTech4_Enhanced"
    }
})
FilterPlayerGuardianTank=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "AlliedAntiVehicleVehicleTech1",
        "AlliedAntiVehicleVehicleTech1_Enhanced"
    }
})
FilterPower=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "AlliedPowerPlant","JapanPowerPlant","SovietPowerPlant"
    }
})
function addmoney  (money)
    for playindex = 1 , 6 , 1 do
        local playerName = "Player_"..playindex;
        if ObjectIsAlive(P[playindex]) and g_PlayerInDebt[playerName] == 0 then
            local TAR, count = ObjectFindObjects(P[playindex], nil,FilterPower)
            for i = 1 , count , 1 do
                if not EvaluateCondition("UNIT_HAS_MODELCONDITION", TAR[i] , "STRUCTURE_UNPACKING") then
                    if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", TAR[i] ,"PLAYER_POWER_2") then
                        ExecuteAction("PLAYER_GIVE_MONEY","Player_"..playindex , money)
                        --  exMessageAppendToMessageArea("¼ÛÇ®")
                        local objectId = ObjectGetId(TAR[i])
                        exShowFloatingIntAtObject( objectId, money)
                    end
                end
            end
        end

    end
end
