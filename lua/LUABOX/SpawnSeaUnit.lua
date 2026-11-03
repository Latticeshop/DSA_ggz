-- 大概以后会扩充成生成所有海军  目前先只管acv

function SpawnSeaUnit()
    -- 但情况又发生了变化！ACV 现在不需要特殊处理了，而目前的这里的代码还没有实现“扩充成生成所有海军”
    -- 所以实际上应该还是先禁用这段代码
    -- SpawnSeaUnit_left()
    -- SpawnSeaUnit_right()
end

function SpawnSeaUnit_left()
    local countSlot = g_UnitCount[FastHash("AlliedAntiInfantryVehicle")];
    local _seatsDemon = g_SideSeatsOf(7)
for _si = 1, 4 do
    local i = _seatsDemon[_si]

        local teamIndex = g_SeatToSide(i)
        local angle = 0;
        if teamIndex == 8 then
            angle = 180
        end
        for j = 1, countSlot[i] do
            local suffix = mod(j, 6);
            if suffix == 0 then
                suffix = 6;
            end

            local x, y, z = ObjectGetPosition(AIRSP[teamIndex][suffix]) ;
            ExecuteAction("CREATE_OBJECT", "AlliedAntiInfantryVehicle", SHIPTEAM[teamIndex], {X=x,Y=y,Z=z}, 0)

        end
    end

    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", SHIPTEAM[7]) then
            for levelindex = 1 , (LEVELUP[7] or 0) , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",SHIPTEAM[7],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM",SHIPTEAM[7], SHIPTEAMATTACK[7])
        end
    end

end

function SpawnSeaUnit_right()
    local countSlot = g_UnitCount[FastHash("AlliedAntiInfantryVehicle")];
    local _seatsAngel = g_SideSeatsOf(8)
for _si = 1, 4 do
    local i = _seatsAngel[_si]
        local teamIndex = g_SeatToSide(i)
        local angle = 0;
        if teamIndex == 8 then
            angle = 180
        end
        for j = 1, countSlot[i] do
            local suffix = mod(j, 6);
            if suffix == 0 then
                suffix = 6;
            end

            local x, y, z = ObjectGetPosition(AIRSP[teamIndex][suffix]) ;
            ExecuteAction("CREATE_OBJECT", "AlliedAntiInfantryVehicle", SHIPTEAM[teamIndex], {X=x,Y=y,Z=z}, 180)


        end
    end

    for spindex = 1 , 6 , 1 do
        if  EvaluateCondition("TEAM_HAS_UNITS", SHIPTEAM[8]) then
            for levelindex = 1 , (LEVELUP[8] or 0) , 1 do
                ExecuteAction("TEAM_GAIN_LEVEL",SHIPTEAM[8],1)
            end
            ExecuteAction("TEAM_MERGE_INTO_TEAM", SHIPTEAM[8], SHIPTEAMATTACK[8])
        end
    end

end