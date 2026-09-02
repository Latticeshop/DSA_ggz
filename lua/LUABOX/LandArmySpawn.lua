function SpawnNoNavyAmphibiousLand_left()
    local teslaBoatIndex = g_UnitNameToUnitIndex["SovietAntiNavyShipTech1"]
    if teslaBoatIndex ~= nil then
        UNITSPST_left(teslaBoatIndex, teslaBoatIndex, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    end
    -- 驱逐舰单独延迟生成，避免其两栖形态异常中断磁暴快艇的生成流程。
    SchedulerModule.delay_call(SpawnNoNavyAssaultDestroyerLand_left, 1, {})
end

function SpawnNoNavyAmphibiousLand_right()
    local teslaBoatIndex = g_UnitNameToUnitIndex["SovietAntiNavyShipTech1"]
    if teslaBoatIndex ~= nil then
        UNITSPST_right(teslaBoatIndex, teslaBoatIndex, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    end
    SchedulerModule.delay_call(SpawnNoNavyAssaultDestroyerLand_right, 1, {})
end

function SpawnNoNavyAssaultDestroyerLandForSide(playerMin, playerMax, teamIndex, angle)
    local unitIndex = g_UnitNameToUnitIndex["AlliedAntiNavyShipTech3"]
    if unitIndex == nil then
        return
    end

    local spindex = 1
    for playindex = playerMin, playerMax, 1 do
        local unitCount = UNITCOUNT[playindex][unitIndex]
        for i = 1, unitCount, 1 do
            local x, y, z = ObjectGetPosition(HEAVYVEHSP[teamIndex][spindex])
            -- 使用鬼王/联盟重型坦克的出生坐标和陆军编队，但不强制驻入出口建筑。
            ExecuteAction("CREATE_OBJECT", "AlliedAntiNavyShipTech3", HEAVYVEHTEAM[teamIndex][spindex], {X=x,Y=y,Z=z}, angle)
            spindex = spindex + 1
            if spindex > 6 then
                spindex = 1
            end
        end
    end

    for i = 1, 6, 1 do
        if EvaluateCondition("TEAM_HAS_UNITS", HEAVYVEHTEAM[teamIndex][i]) then
            for levelindex = 1, LEVELUP[teamIndex], 1 do
                ExecuteAction("TEAM_GAIN_LEVEL", HEAVYVEHTEAM[teamIndex][i], 1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM", HEAVYVEHTEAM[teamIndex][i], HEAVYVEHATTACK[teamIndex][i])
        end
    end
end

function SpawnNoNavyAssaultDestroyerLand_left()
    SpawnNoNavyAssaultDestroyerLandForSide(1, 3, 7, 0)
end

function SpawnNoNavyAssaultDestroyerLand_right()
    SpawnNoNavyAssaultDestroyerLandForSide(4, 6, 8, 180)
end

function SpawnNoNavyAmphibiousLand()
    SpawnNoNavyAmphibiousLand_left()
    SpawnNoNavyAmphibiousLand_right()
end

function SpawnNoNavySeaWingAir_left()
    local unitIndex = g_UnitNameToUnitIndex["JapanAntiAirShip"]
    if unitIndex ~= nil then
        UNITSPAIRST_left(unitIndex, unitIndex, LIGHTVEHSP, AIRTEAM, AIRATTACK, LIGHTVEHSPCH)
    end
end

function SpawnNoNavySeaWingAir_right()
    local unitIndex = g_UnitNameToUnitIndex["JapanAntiAirShip"]
    if unitIndex ~= nil then
        UNITSPAIRST_right(unitIndex, unitIndex, LIGHTVEHSP, AIRTEAM, AIRATTACK, LIGHTVEHSPCH)
    end
end

function SpawnNoNavySeaWingAir()
    SpawnNoNavySeaWingAir_left()
    SpawnNoNavySeaWingAir_right()
end

function SpawnSeaWingFromSeaForSide(playerMin, playerMax, teamIndex, angle)
    local unitIndex = g_UnitNameToUnitIndex["JapanAntiAirShip"]
    if unitIndex == nil then
        return
    end
    local spindex = 1
    for playindex = playerMin, playerMax, 1 do
        local unitCount = UNITCOUNT[playindex][unitIndex]
        for i = 1, unitCount, 1 do
            local x, y, z = ObjectGetPosition(AIRSP[teamIndex][spindex])
            ExecuteAction("CREATE_OBJECT", "JapanAntiAirShip", SHIPTEAM[teamIndex], {X=x,Y=y,Z=z}, angle)
            spindex = spindex + 1
            if spindex > 6 then
                spindex = 1
            end
        end
    end
    if EvaluateCondition("TEAM_HAS_UNITS", SHIPTEAM[teamIndex]) then
        for levelindex = 1, LEVELUP[teamIndex], 1 do
            ExecuteAction("TEAM_GAIN_LEVEL", SHIPTEAM[teamIndex], 1)
        end
        ExecuteAction("TEAM_MERGE_INTO_TEAM", SHIPTEAM[teamIndex], SHIPTEAMATTACK[teamIndex])
    end
end

function SpawnSeaWingFromSea_left()
    SpawnSeaWingFromSeaForSide(1, 3, 7, 0)
end

function SpawnSeaWingFromSea_right()
    SpawnSeaWingFromSeaForSide(4, 6, 8, 180)
end

function LandArmySpawn()
    UNITSPST (1,step1,INFANTSP,INFANTTEAM,INFANTATTACK,INFANTSPCH)
    UNITSPST (step1+1,step2,LIGHTVEHSP,LIGHTVEHTEAM,LIGHTVEHATTACK,LIGHTVEHSPCH)
    UNITSPST (step2+1,step3,HEAVYVEHSP,HEAVYVEHTEAM,HEAVYVEHATTACK,HEAVYVEHSPCH)

    SpawnLandUnit()

    if g_DisableSeaArmy == 0 then
        UNITSPSHIP (step35+1,step4,AIRSP,SHIPTEAM,SHIPTEAMATTACK,AIRSPCH)
        SpawnSeaUnit()
    else
        SpawnNoNavyAmphibiousLand()
        SpawnNoNavySeaWingAir()
    end

    UNITSPAIRST (step4+1,step5,INFANTSP,AIRTEAM,AIRATTACK,INFANTSPCH)

    SpawnGigaFortressAir()

    exEnableWBScript('SHIPNOCOACT')
    exEnableWBScript('PlyrCivilian/attackHEAVYVEHVEH__7')
    exEnableWBScript('PlyrCivilian/attackINFANT__7')
    exEnableWBScript('PlyrCivilian/attackLIGHTVEH__7')
    exEnableWBScript('PlyrCivilian/ATTACKSHIP__7')
    exEnableWBScript('PlyrCreeps/attackHEAVYVEHVEH__8')
    exEnableWBScript('PlyrCreeps/attackINFANT__8')
    exEnableWBScript('PlyrCreeps/attackLIGHTVEH__8')
    exEnableWBScript('PlyrCreeps/ATTACKSHIP__8')
    exEnableWBScript('BUFFACTONCE')
    exEnableWBScript('ShrinkMode_Trigger')
end
