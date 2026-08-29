AIRFIELD = {}
AIRFIELD[7] = GetObjectByScriptName("AIRFIELD"..7) ;
AIRFIELD[8] = GetObjectByScriptName("AIRFIELD"..8) ;
PLANELIST = {}
AIRRESP = {}
AIRRESPCH ={}
AIRRESP[7] = {}
AIRRESPCH[7] = {}
AIRRESP[8] = {}
AIRRESPCH[8] = {}
for i = 1 , 6 , 1 do
    AIRRESP[7][i] = GetObjectByScriptName("AIRRE1"..i) ;
    ExecuteAction("SET_UNIT_REFERENCE","AIRRESP7"..i , AIRRESP[7][i])
    AIRRESPCH[7][i] = "AIRRESP7"..i
    AIRRESP[8][i] = GetObjectByScriptName("AIRRE2"..i) ;
    ExecuteAction("SET_UNIT_REFERENCE","AIRRESP8"..i , AIRRESP[8][i])
    AIRRESPCH[8][i] = "AIRRESP8"..i
end
local indexPLANE = 1
PLANELIST[indexPLANE] = "AlliedAntiGroundAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "AlliedAntiStructureBomberAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "AlliedFighterAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "AlliedInterceptorAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "CelestialBomberAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "CelestialFighterAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "SovietFighterAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "SovietInterceptorAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "SovietAntiGroundAttacker"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "CelestialInterceptorAircraft"
indexPLANE = indexPLANE + 1 ;
PLANELIST[indexPLANE] = "AlliedBomberAircraft"
indexPLANE = indexPLANE + 1 ;
PLANEcountmax = indexPLANE + 5
--exMessageAppendToMessageArea("LIST定义")
--exMessageAppendToMessageArea("PLANELIST[1]"..PLANELIST[1])
FilterPLANELIST = {}

for i = 1 , PLANEcountmax , 1 do
    FilterPLANELIST[i]=CreateObjectFilter({
        Rule="ANY",
        Relationship="SAME_PLAYER",
        IncludeThing = {
            PLANELIST[i],
        },
    })
end
--exMessageAppendToMessageArea("FILTER定义")

function PLANEREBORN (UNITSP,UNITTEAM,UNITATTACKTEAM,UNITCH)
    local spindex = 1
    for playindex = 7 , 8 ,1 do
        local x0, y0, z0 = ObjectGetPosition(AIRFIELD[playindex]) ;
        for unitindex = 1 , PLANEcountmax , 1 do
            local TAR, count = ObjectFindObjects(P[playindex],  {
                X=x0, Y=y0, Z=z0, Radius=500, DistType="CENTER_2D"
            }, FilterPLANELIST[unitindex])
            -- exMessageAppendToMessageArea("count:"..count)
            --------------------------------
            for j = 1 , count , 1 do
                ExecuteAction("NAMED_DELETE",TAR[j])
                if  spindex < 6 then
                    if playindex <= 7 then
                        --exMessageAppendToMessageArea("执行1")
                        local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",PLANELIST[unitindex],UNITTEAM[7][spindex],{X=x,Y=y,Z=z},"0")
                        --exMessageAppendToMessageArea("执行1完毕")
                        spindex = spindex + 1 ;
                    elseif  playindex >= 8 then
                        --exMessageAppendToMessageArea("执行2")
                        local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",PLANELIST[unitindex],UNITTEAM[8][spindex],{X=x,Y=y,Z=z},"180")
                        spindex = spindex + 1 ;
                    end
                elseif  spindex >= 6 then
                    if playindex <= 7 then
                        --exMessageAppendToMessageArea("执行3")
                        local x, y, z = ObjectGetPosition(UNITSP[7][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",PLANELIST[unitindex],UNITTEAM[7][spindex],{X=x,Y=y,Z=z},"0")
                        spindex =  1 ;
                    elseif  playindex >= 8 then
                        --exMessageAppendToMessageArea("执行4")
                        local x, y, z = ObjectGetPosition(UNITSP[8][spindex]) ;
                        ExecuteAction("CREATE_OBJECT",PLANELIST[unitindex],UNITTEAM[8][spindex],{X=x,Y=y,Z=z},"180")
                        spindex =  1 ;
                    end
                end
            end
            ---------------------------------------
        end
    end
    -------------------------------------------
    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[7][spindex]) then
            for levelindex = 1 , LEVELUP[7] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[7][spindex],1)
            end
            --exMessageAppendToMessageArea("UNITCH[7][spindex]"..UNITCH[7][spindex])
            ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[7][spindex],UNITATTACKTEAM[7][spindex])
            ExecuteAction("EXIT_SPECIFIC_BUILDING", UNITCH[7][spindex] )
        end
        if  EvaluateCondition("TEAM_HAS_UNITS", UNITTEAM[8][spindex]) then
            for levelindex = 1 , LEVELUP[7] , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",UNITTEAM[8][spindex],1)
            end
            --exMessageAppendToMessageArea("UNITCH[8][spindex]"..UNITCH[8][spindex])
            ExecuteAction("TEAM_MERGE_INTO_TEAM",UNITTEAM[8][spindex],UNITATTACKTEAM[8][spindex])
            ExecuteAction("EXIT_SPECIFIC_BUILDING",UNITCH[8][spindex] )
        end
    end
    -----------------------------------------------------------
end
--exMessageAppendToMessageArea("函数定义")
