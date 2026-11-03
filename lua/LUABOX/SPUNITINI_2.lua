SHIPTEAM =  {}
SHIPTEAMATTACK = {}
SHIPTEAMATTACK[7] = "PlyrCivilian/SHIPATTACK"
SHIPTEAMATTACK[8] = "PlyrCreeps/SHIPATTACK"
SHIPTEAM[7] = "PlyrCivilian/SHIPTEAM"
SHIPTEAM[8] = "PlyrCreeps/SHIPTEAM"

function UNITSPSHIP (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    local spindex = 1
    for unitindex = unitmin , unitmax , 1 do
        -- 禁用模式：该槽位全部兵种都被禁时整槽不出兵（上限 0 让内层直接空转）。
        for playindex = 1 , BanModeSpawnCount(unitindex, 8) , 1 do
            local spiunitcount = UNITCOUNT[playindex][unitindex]
            if spiunitcount > 0 then
                ------------------------------------
                for i = 1 , spiunitcount , 1 do
                    --------------------------------
                    if  spindex < 6 then
                        if g_IsDevilSeat(playindex) then
                            local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[7],{X=x,Y=y,Z=z},"0")
                            spindex = spindex + 1 ;
                        elseif  g_IsAngelSeat(playindex) then
                            local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[8],{X=x,Y=y,Z=z},"180")
                            spindex = spindex + 1 ;
                        end
                    elseif  spindex >= 6 then
                        if g_IsDevilSeat(playindex) then
                            local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[7],{X=x,Y=y,Z=z},"0")
                            spindex =  1 ;
                        elseif  g_IsAngelSeat(playindex) then
                            local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[8],{X=x,Y=y,Z=z},"180")
                            spindex =  1 ;
                        end
                    end
                    ----------------------------------------------
                end
                ---------------------------------------
            end
        end
    end
    -------------------------------------------
    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[7]) then
            for levelindex = 1 , LEVELUP[7] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[7],1)
            end
            --  exMessageAppendToMessageArea("UNITCH[7][spindex]"..UNITCH[7][spindex])
            ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[7],UNITATTACKTEAM[7])
            ExecuteAction("EXIT_SPECIFIC_BUILDING", UNITCH[7] )
        end
        if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[8]) then
            for levelindex = 1 , LEVELUP[8] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[8],1)
            end
            --  exMessageAppendToMessageArea("UNITCH[8][spindex]"..UNITCH[8][spindex])
            ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[8],UNITATTACKTEAM[8])
            ExecuteAction("EXIT_SPECIFIC_BUILDING",UNITCH[8] )
        end
    end
    -------------------------------------------
    -- for spindex = 1 , 6 , 1 do
    --     if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[7]) then
    --         --  exMessageAppendToMessageArea("UNITCH[7][spindex]"..UNITCH[7][spindex])
    --         ExecuteAction("TEAM_GARRISON_SPECIFIC_BUILDING_INSTANTLY", UNITTEAM[7] ,UNITCH[7][spindex] )
    --         for levelindex = 1 , LEVELUP[7] , 1 do
    --             ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[7],1)
    --         end
    --         ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[7],UNITATTACKTEAM[7])
    --         ExecuteAction("EXIT_SPECIFIC_BUILDING", UNITCH[7][spindex] )
    --     end
    --     if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[8]) then
    --         --  exMessageAppendToMessageArea("UNITCH[8][spindex]"..UNITCH[8][spindex])
    --         ExecuteAction("TEAM_GARRISON_SPECIFIC_BUILDING_INSTANTLY", UNITTEAM[8] , UNITCH[8][spindex] )
    --         for levelindex = 1 , LEVELUP[8] , 1 do
    --             ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[8],1)
    --         end
    --         ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[8],UNITATTACKTEAM[8])
    --         ExecuteAction("EXIT_SPECIFIC_BUILDING",UNITCH[8][spindex] )
    --     end
    -- end
    -----------------------------------------------------------
end

-- 为“补充军队”按阵营单独生成海军，避免调用旧函数时把双方海军一起补出来。
-- playerMin / playerMax 是 6 人时代的座位区间参数，现已不再使用（座位一律取自
-- g_Seat7 / g_Seat8），保留形参只为不改动调用点；传 1、4 表示每侧 4 个席位。
function UNITSPSHIP_SIDE(unitmin, unitmax, UNITSP, UNITTEAM, UNITATTACKTEAM, playerMin, playerMax, teamIndex, angle)
    -- 8 人：按阵营座位表出兵（恶魔 1,2,3,8 / 天使 4,5,7,6）
    local seats = g_Seat7 or { 1, 2, 3, 8 }
    if teamIndex == 8 then
        seats = g_Seat8 or { 4, 5, 7, 6 }
    end
    local spindex = 1
    for unitindex = unitmin, unitmax, 1 do
        for seatPos = 1 , BanModeSpawnCount(unitindex, 4) , 1 do
            local playindex = seats[seatPos]
            local unitCount = UNITCOUNT[playindex][unitindex]
            for i = 1, unitCount, 1 do
                local x, y, z = ObjectGetPosition(UNITSP[teamIndex][spindex])
                ExecuteAction("CREATE_OBJECT", UNITLIST[unitindex], UNITTEAM[teamIndex], {X=x,Y=y,Z=z}, angle)
                spindex = spindex + 1
                if spindex > 6 then
                    spindex = 1
                end
            end
        end
    end

    if EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[teamIndex]) then
        for levelindex = 1, LEVELUP[teamIndex], 1 do
            ExecuteAction("TEAM_GAIN_LEVEL", UNITTEAM[teamIndex], 1)
        end
        ExecuteAction("TEAM_MERGE_INTO_TEAM", UNITTEAM[teamIndex], UNITATTACKTEAM[teamIndex])
    end
end

function UNITSPSHIP_left(unitmin, unitmax, UNITSP, UNITTEAM, UNITATTACKTEAM)
    UNITSPSHIP_SIDE(unitmin, unitmax, UNITSP, UNITTEAM, UNITATTACKTEAM, 1, 4, 7, 0)
end

function UNITSPSHIP_right(unitmin, unitmax, UNITSP, UNITTEAM, UNITATTACKTEAM)
    UNITSPSHIP_SIDE(unitmin, unitmax, UNITSP, UNITTEAM, UNITATTACKTEAM, 1, 4, 8, 180)
end
--exMessageAppendToMessageArea("函数定义")
