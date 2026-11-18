-- 空军段分批（见附录 A.60）：晚批 = 轰炸机/特攻机 + 摇光巡航机，其余飞机按「护航批次」提前出场。
g_AirLateBatchUnitNames = {
    AlliedAntiGroundAircraft = true,          -- 维护者
    AlliedAntiStructureBomberAircraft = true, -- 世纪（对建筑）
    AlliedBomberAircraft = true,              -- 世纪
    CelestialBomberAircraft = true,           -- 金乌
    AlliedGunshipAircraft = true,             -- 先锋武装炮艇机（槽 86）
    AlliedAC130GunshipAircraft = true,        -- 先锋武装炮艇机·130 形态（槽 83）
    JapanInterceptorAircraft = true,          -- 樱花回天雷（出兵形态刷 _Ground，见附录 A.61）
    JapanSakuraAttackRocket = true,           -- 鬼樱特攻机
    SovietAntiGroundAttacker = true,          -- 伊尔攻击机
    CelestialAdvanceAircraftTech4 = true,     -- 摇光巡航机
}

-- mode: nil / "all" 全刷（默认，保持旧行为）；"escort" 只刷护航机；"late" 只刷晚批。
function g_AirBatchAcceptsUnit(unitIndex, mode)
    if mode == nil or mode == "all" then
        return true
    end
    local isLate = g_AirLateBatchUnitNames[UNITLIST[unitIndex]] == true
    if mode == "late" then
        return isLate
    end
    return not isLate
end

-- 樱花回天雷的出兵形态：出生点是陆地出口，直接刷空中形态会卡在原地，改刷 JapanInterceptorAircraft_Ground（本质仍是空中形态）。见附录 A.61。
g_AirSpawnFormOverrides = {
    JapanInterceptorAircraft = "JapanInterceptorAircraft_Ground",
}

function g_GetAirSpawnUnitType(unitIndex)
    local override = g_AirSpawnFormOverrides[UNITLIST[unitIndex]]
    if override ~= nil then
        return override
    end
    return UNITLIST[unitIndex]
end

function UNITSPAIRST (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH,mode)
    UNITSPAIRST_left(unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH,mode)
    UNITSPAIRST_right(unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH,mode)
end

function UNITSPAIRST_left (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH,mode)
    local spindex = 1
    for unitindex = unitmin , unitmax , 1 do
        -- 超级要塞由 SpawnGigaFortressAir 专用生成（随机形态 + 变形复查），通用批次跳过这一格，
        -- 避免双倍出货（见附录 D.18）。
        local skipGigaFortress = (UNITLIST[unitindex] == "JapanGigaFortressShipEgg")
        local acceptsBatch = g_AirBatchAcceptsUnit(unitindex, mode)
        -- 禁用模式：该槽位全部兵种都被禁时整槽不出兵（上限 0 让内层直接空转）。
        for _si = 1 , BanModeSpawnCount(unitindex, getn(g_Seat7)) , 1 do
            local playindex = g_Seat7[_si]
            local spiunitcount = UNITCOUNT[playindex][unitindex]
            if skipGigaFortress or not acceptsBatch then spiunitcount = 0 end
            if spiunitcount > 0 then
                ------------------------------------
                for i = 1 , spiunitcount , 1 do
                    --------------------------------
                    if  spindex < 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",g_GetAirSpawnUnitType(unitindex),UNITTEAM[7][spindex],{X=x,Y=y,Z=z},"0")
                        spindex = spindex + 1 ;
                    elseif  spindex >= 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",g_GetAirSpawnUnitType(unitindex),UNITTEAM[7][spindex],{X=x,Y=y,Z=z},"0")
                        spindex =  1 ;
                    end
                    ----------------------------------------------
                end
                ---------------------------------------
            end
        end
    end
    -------------------------------------------
    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[7][spindex]) then
            for levelindex = 1 , LEVELUP[7] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[7][spindex],1)
            end
            --  exMessageAppendToMessageArea("UNITCH[7][spindex]"..UNITCH[7][spindex])
            ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[7][spindex],UNITATTACKTEAM[7][spindex])
            ExecuteAction("EXIT_SPECIFIC_BUILDING", UNITCH[7][spindex] )
        end
    end
    -----------------------------------------------------------
end

function UNITSPAIRST_right (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH,mode)
    local spindex = 1
    for unitindex = unitmin , unitmax , 1 do
        -- 超级要塞由 SpawnGigaFortressAir 专用生成（随机形态 + 变形复查），通用批次跳过这一格，
        -- 避免双倍出货（见附录 D.18）。
        local skipGigaFortress = (UNITLIST[unitindex] == "JapanGigaFortressShipEgg")
        local acceptsBatch = g_AirBatchAcceptsUnit(unitindex, mode)
        for _si = 1 , BanModeSpawnCount(unitindex, getn(g_Seat8)) , 1 do
            local playindex = g_Seat8[_si]
            local spiunitcount = UNITCOUNT[playindex][unitindex]
            if skipGigaFortress or not acceptsBatch then spiunitcount = 0 end
            if spiunitcount > 0 then
                ------------------------------------
                for i = 1 , spiunitcount , 1 do
                    --------------------------------
                    if  spindex < 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",g_GetAirSpawnUnitType(unitindex),UNITTEAM[8][spindex],{X=x,Y=y,Z=z},"180")
                        spindex = spindex + 1 ;
                    elseif  spindex >= 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",g_GetAirSpawnUnitType(unitindex),UNITTEAM[8][spindex],{X=x,Y=y,Z=z},"180")
                        spindex =  1 ;
                    end
                    ----------------------------------------------
                end
                ---------------------------------------
            end
        end
    end
    -------------------------------------------
    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[8][spindex]) then
            for levelindex = 1 , LEVELUP[8] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[8][spindex],1)
            end
            --  exMessageAppendToMessageArea("UNITCH[8][spindex]"..UNITCH[8][spindex])
            ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[8][spindex],UNITATTACKTEAM[8][spindex])
            ExecuteAction("EXIT_SPECIFIC_BUILDING",UNITCH[8][spindex] )
        end
    end
    -----------------------------------------------------------
end

