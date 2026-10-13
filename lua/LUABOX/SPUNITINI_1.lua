function UNITSPAIRST (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    UNITSPAIRST_left(unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    UNITSPAIRST_right(unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
end

function UNITSPAIRST_left (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    local spindex = 1
    for unitindex = unitmin , unitmax , 1 do
        -- 禁用模式：该槽位全部兵种都被禁时整槽不出兵（上限 0 让内层直接空转）。
        for playindex = 1 , BanModeSpawnCount(unitindex, 3) , 1 do
            local spiunitcount = UNITCOUNT[playindex][unitindex]
            if spiunitcount > 0 then
                ------------------------------------
                for i = 1 , spiunitcount , 1 do
                    --------------------------------
                    if  spindex < 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[7][spindex],{X=x,Y=y,Z=z},"0")
                        spindex = spindex + 1 ;
                    elseif  spindex >= 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[7][spindex],{X=x,Y=y,Z=z},"0")
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

function UNITSPAIRST_right (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    local spindex = 1
    for unitindex = unitmin , unitmax , 1 do
        for playindex = 4 , BanModeSpawnCount(unitindex, 6) , 1 do
            local spiunitcount = UNITCOUNT[playindex][unitindex]
            if spiunitcount > 0 then
                ------------------------------------
                for i = 1 , spiunitcount , 1 do
                    --------------------------------
                    if  spindex < 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[8][spindex],{X=x,Y=y,Z=z},"180")
                        spindex = spindex + 1 ;
                    elseif  spindex >= 6 then
                        local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[8][spindex],{X=x,Y=y,Z=z},"180")
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

