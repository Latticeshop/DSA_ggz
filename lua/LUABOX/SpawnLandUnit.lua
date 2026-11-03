-- 大概以后会扩充成生成所有陆军  目前先只管acv
function SpawnLandUnit()
    -- 但情况又发生了变化！ACV 现在不需要特殊处理了，而目前的这里的代码还没有实现“扩充成生成所有陆军”
    -- 所以实际上应该还是先禁用这段代码
    -- SpawnLandUnit_left()
    -- SpawnLandUnit_right()
end

function SpawnLandUnit_left()
    local countSlot = g_UnitCount[FastHash("AlliedAntiInfantryVehicle_Ground")];
    local _seatsDemon = g_SideSeatsOf(7)
for _si = 1, 4 do
    local i = _seatsDemon[_si]
        local teamIndex = g_SeatToSide(i)
        local spawnPosPrefix = "LIGHTVEH" .. tostring(teamIndex - 6)
        local landSpawnPosPrefix = spawnPosPrefix

        local angle = 0;
        if teamIndex == 8 then
            angle = 180
        end
        for j = 1, countSlot[i] do
            local suffix = mod(j, 6);
            if suffix == 0 then
                suffix = 6;
            end

            local x, y, z = ObjectGetPosition(LIGHTVEHSP[teamIndex][suffix]) ;
            ExecuteAction("CREATE_OBJECT", "AlliedAntiInfantryVehicle_Ground", LIGHTVEHTEAM[teamIndex][suffix], {X=x,Y=y,Z=z}, 0)

        end
    end

    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", LIGHTVEHTEAM[7][spindex]) then
            ExecuteAction("TEAM_GARRISON_SPECIFIC_BUILDING_INSTANTLY", LIGHTVEHTEAM[7][spindex] ,LIGHTVEHSPCH[7][spindex] )
            for levelindex = 1 , (LEVELUP[7] or 0) , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",LIGHTVEHTEAM[7][spindex],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",LIGHTVEHTEAM[7][spindex],LIGHTVEHATTACK[7][spindex])
            ExecuteAction("EXIT_SPECIFIC_BUILDING", LIGHTVEHSPCH[7][spindex] )
        end
    end

end

function SpawnLandUnit_right()
    local countSlot = g_UnitCount[FastHash("AlliedAntiInfantryVehicle_Ground")];
    local _seatsAngel = g_SideSeatsOf(8)
for _si = 1, 4 do
    local i = _seatsAngel[_si]
        local teamIndex = g_SeatToSide(i)
        local spawnPosPrefix = "LIGHTVEH" .. tostring(teamIndex - 6)
        local landSpawnPosPrefix = spawnPosPrefix

        local angle = 0;
        if teamIndex == 8 then
            angle = 180
        end
        for j = 1, countSlot[i] do
            local suffix = mod(j, 6);
            if suffix == 0 then
                suffix = 6;
            end
            local x, y, z = ObjectGetPosition(LIGHTVEHSP[teamIndex][suffix]) ;
            ExecuteAction("CREATE_OBJECT", "AlliedAntiInfantryVehicle_Ground", LIGHTVEHTEAM[teamIndex][suffix], {X=x,Y=y,Z=z}, 180)

        end
    end

    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", LIGHTVEHTEAM[8][spindex]) then
            ExecuteAction("TEAM_GARRISON_SPECIFIC_BUILDING_INSTANTLY", LIGHTVEHTEAM[8][spindex] , LIGHTVEHSPCH[8][spindex] )
            for levelindex = 1 , (LEVELUP[8] or 0) , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",LIGHTVEHTEAM[8][spindex],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",LIGHTVEHTEAM[8][spindex],LIGHTVEHATTACK[8][spindex])
            ExecuteAction("EXIT_SPECIFIC_BUILDING",LIGHTVEHSPCH[8][spindex] )
        end
    end

end