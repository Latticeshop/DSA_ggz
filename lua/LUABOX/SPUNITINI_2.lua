SHIPTEAM =  {}
SHIPTEAMATTACK = {}
SHIPTEAMATTACK[7] = "PlyrCivilian/SHIPATTACK"
SHIPTEAMATTACK[8] = "PlyrCreeps/SHIPATTACK"
SHIPTEAM[7] = "PlyrCivilian/SHIPTEAM"
SHIPTEAM[8] = "PlyrCreeps/SHIPTEAM"

function UNITSPSHIP (unitmin,unitmax,UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    local spindex = 1
    for unitindex = unitmin , unitmax , 1 do
        for playindex = 1 , 6 , 1 do
            local spiunitcount = UNITCOUNT[playindex][unitindex]
            if spiunitcount > 0 then
                ------------------------------------
                for i = 1 , spiunitcount , 1 do
                    --------------------------------
                    if  spindex < 6 then
                        if playindex <= 3 then
                            local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[7],{X=x,Y=y,Z=z},"0")
                            spindex = spindex + 1 ;
                        elseif  playindex > 3 then
                            local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[8],{X=x,Y=y,Z=z},"180")
                            spindex = spindex + 1 ;
                        end
                    elseif  spindex >= 6 then
                        if playindex <= 3 then
                            local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                            ExecuteAction("CREATE_OBJECT",UNITLIST[unitindex],UNITTEAM[7],{X=x,Y=y,Z=z},"0")
                            spindex =  1 ;
                        elseif  playindex > 3 then
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
--exMessageAppendToMessageArea("函数定义")
