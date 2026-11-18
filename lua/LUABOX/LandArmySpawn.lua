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

function SpawnNoNavyAssaultDestroyerLandForSide(seats, teamIndex, angle)
    local unitIndex = g_UnitNameToUnitIndex["AlliedAntiNavyShipTech3"]
    if unitIndex == nil then
        return
    end

    local spindex = 1
    for _si = 1, getn(seats), 1 do
        local playindex = seats[_si]
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
    SpawnNoNavyAssaultDestroyerLandForSide(g_Seat7, 7, 0)
end

function SpawnNoNavyAssaultDestroyerLand_right()
    SpawnNoNavyAssaultDestroyerLandForSide(g_Seat8, 8, 180)
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

function SpawnSeaWingFromSeaForSide(seats, teamIndex, angle)
    local unitIndex = g_UnitNameToUnitIndex["JapanAntiAirShip"]
    if unitIndex == nil then
        return
    end
    local spindex = 1
    for _si = 1, getn(seats), 1 do
        local playindex = seats[_si]
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
    SpawnSeaWingFromSeaForSide(g_Seat7, 7, 0)
end

function SpawnSeaWingFromSea_right()
    SpawnSeaWingFromSeaForSide(g_Seat8, 8, 180)
end

------------------------------------------------------------------------------
-- 火炮机车（UNITLIST 第 42 格，轻型载具段）移速快，跟通用 LIGHTVEH 批一起出生会送
-- 刷兵仍走 UNITSPST*；WB 脚本 attackLIGHTVEH__7/__8 每 8 帧重下发一次 attack-move，会自己接管。
g_MortarCycleDelayFrames = 25     -- 25 帧 ≈ 0.8 秒（30 帧/秒）；调大 = 更晚出发

-- 延迟回调。mode 为 "both" 时左右一起刷（UNITSPST），"left"/"right" 只在补充军队技能里用。
function SpawnMortarCycleLand(mode)
    local mortarIndex = g_UnitNameToUnitIndex["SovietMortarCycle"]
    if mortarIndex == nil then
        return
    end
    if mode == "left" then
        UNITSPST_left(mortarIndex, mortarIndex, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    elseif mode == "right" then
        UNITSPST_right(mortarIndex, mortarIndex, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    else
        UNITSPST(mortarIndex, mortarIndex, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    end
end

-- 轻型载具段的通用批：跳过火炮机车那一格，它改由 SpawnMortarCycleLand 延迟生成。
function SpawnLightVehicleBatch(spawnBatch, mode)
    local mortarIndex = g_UnitNameToUnitIndex["SovietMortarCycle"]
    if mortarIndex == nil or mortarIndex <= step1 or mortarIndex > step2 then
        spawnBatch(step1+1, step2, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
        return
    end
    spawnBatch(step1+1, mortarIndex-1, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    spawnBatch(mortarIndex+1, step2, LIGHTVEHSP, LIGHTVEHTEAM, LIGHTVEHATTACK, LIGHTVEHSPCH)
    if mode == nil then
        mode = "both"
    end
    SchedulerModule.delay_call(SpawnMortarCycleLand, g_MortarCycleDelayFrames, {mode})
end

-- 空军护航批次（见附录 A.60）：非轰炸机、非摇光的飞机比空军主批提前 5 秒出场。
g_AirEscortDelayFrames = 75
g_AirEscortRunePassDelayFrames = 45

function g_AirEscortRunePass()
    -- 与 ShrinkMode_Trigger.lua 同一个开关口径：海克斯没开就整段跳过。
    if g_EnableHextechRune ~= 1 or HextechRune == nil
        or HextechRune.ApplyBattleUnitEffectPass == nil then
        return
    end
    HextechRune:ApplyBattleUnitEffectPass("本回合空军护航批次", nil, nil)
    if HextechRune.ApplyAtFieldShields ~= nil then
        HextechRune:ApplyAtFieldShields()
    end
end

-- 出兵 5 秒后单独出护航机；攻击指令和空军 buff 必须在这里就开，
-- 否则要等到 AIRSPACT 那趟（出兵后 10 秒）才生效，飞机先站桩 5 秒。
function SpawnAirEscortBatch()
    UNITSPAIRST (step3+1,step35,LIGHTVEHSP,AIRTEAM,AIRATTACK,LIGHTVEHSPCH,"escort")
    exEnableWBScript('PlyrCivilian/attackAIR__7')
    exEnableWBScript('PlyrCreeps/attackAIR__8')
    exEnableWBScript('BUFFACTONCE__AIR')
    -- 符文/AT立场：等变形载具（天狗、心神）变完形再补一趟，口径同首扫的 45 帧。
    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(g_AirEscortRunePass,
            g_AirEscortRunePassDelayFrames, {})
    end
end

function LandArmySpawn()
    -- 遭遇战电脑的编制同步（LUABOX/AI/AIINI_1.lua: AICOMP）：放在所有兵种批次之前，
    -- 补齐的 UNITCOUNT 当回合就能刷出来；内部按回合号去重，地编那四个 AIUNITBUILDACT 入口也调它。
    if AICOMP ~= nil and AICOMP.EnsureRound ~= nil then
        AICOMP.EnsureRound()
    end
    UNITSPST (1,step1,INFANTSP,INFANTTEAM,INFANTATTACK,INFANTSPCH)
    SpawnLightVehicleBatch(UNITSPST)
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

    -- 护航飞机在出兵 5 秒后单独一批；轰炸机/摇光仍走 AIRSPACT 的 10 秒批次。
    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(SpawnAirEscortBatch, g_AirEscortDelayFrames, {})
    end

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
