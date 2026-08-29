if not RoundLuaManager then
    RoundLuaManager = {
        _onBegin = {},
        _onEnd = {},
        _delayedOnBegin = {},

        _begin = function()
            for i = 1, getn(RoundLuaManager._onBegin) do
                local data = RoundLuaManager._onBegin[i]
                if data.Enabled == 1 then
                    call(data.Callback, data.Arguments, "x")
                end
            end
            -- 处理延迟调用
            local delayedCalls = RoundLuaManager._delayedOnBegin
            local d = 1
            while d <= getn(delayedCalls) do
                local data = delayedCalls[d]
                data.Delay = data.Delay - 1
                if data.Delay > 0 then
                    d = d + 1
                else
                    call(data.Callback, data.Arguments, "x")
                    tremove(delayedCalls, d)
                end
            end
        end,

        _end = function()
            for i = 1, getn(RoundLuaManager._onEnd) do
                local data = RoundLuaManager._onEnd[i]
                if data.Enabled == 1 then
                    call(data.Callback, data.Arguments, "x")
                end
            end
        end,
    }

    function RoundLuaManager.CallOnEveryRoundBegin(callback, arguments)
        local id = getn(RoundLuaManager._onBegin) + 1
        RoundLuaManager._onBegin[id] = {
            Callback = callback,
            Arguments = arguments or {},
            Enabled = 1,
        }
        return id
    end

    function RoundLuaManager.CallOnEveryRoundEnd(callback, arguments)
        local id = getn(RoundLuaManager._onEnd) + 1
        RoundLuaManager._onEnd[id] = {
            Callback = callback,
            Arguments = arguments or {},
            Enabled = 1,
        }
        return id
    end

    function RoundLuaManager.DelayCallOnRoundBegin(callback, arguments, delay)
        tinsert(RoundLuaManager._delayedOnBegin, {
            Callback = callback,
            Arguments = arguments or {},
            Delay = delay or 0,
        })
    end

    exSetPublicBoardColor(HexToUInt32("FFFF00"))
    local rhinoMineFilter = CreateObjectFilter({
        Rule="ANY",
        IncludeThing = {
            "SovietRhinoTankMine"
        }
    })
    RoundLuaManager.CallOnEveryRoundBegin(function(filter)
        local mines, mineCount = ObjectFindObjects(nil, nil, filter)
        for i = 1, mineCount, 1 do
            ExecuteAction("NAMED_DELETE", mines[i])
        end
    end, { rhinoMineFilter })

    local list = { "INFANT12", "INFANT15", "INFANT23", "INFANT24", "AIR14", "AIR16", "AIR24", "AIR26" }
    RoundLuaManager.CallOnEveryRoundBegin(function(list)
        for i = 1, getn(list), 1 do
            ExecuteAction("OBJECT_CREATE_RADAR_EVENT", list[i], "Information")
        end
        local level = exCounterGetByName("lvc")
        if level ~= nil and level > 0 then
            exAddTextToPublicBoard(Localization.get("round.begin", level), 10)
            if level == 1 then
                exAddTextToPublicBoard(Localization.get("round.angel_formation"), 20)
                exAddTextToPublicBoard(Localization.get("round.devil_formation"), 20)
            end
        end
    end, { list })

    exEnableWBScript("EnvKillAllUnit");
end

-- 回合结束
RoundLuaManager._end()

local countD  = GetPlayerAllUnitsValue('PlyrCivilian')
local  countA = GetPlayerAllUnitsValue('PlyrCreeps')
if countD>countA then
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction('PLAYER_GIVE_MONEY','Player_1',devil_money)
    ExecuteAction('PLAYER_GIVE_MONEY','Player_2',devil_money)
    ExecuteAction('PLAYER_GIVE_MONEY','Player_3',devil_money)
    exAddTextToPublicBoard(Localization.get('round.devil_win'),10)
    if devil_max>=1200 then
        exAddTextToPublicBoard(Localization.get('round.devil_end_streak'),10)
    end
    if angel_max>=1200 then
        exAddTextToPublicBoard(Localization.get('round.devil_on_streak'),10)
    end
    devil_money=0
    angel_money=0
    if angel_max<4200 then
        angel_max=angel_max+400
    end
    if devil_max >= 1800 then
        devil_max = devil_max / 2;
    else
        devil_max=200
    end
elseif countD<countA then
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction('PLAYER_GIVE_MONEY','Player_4',angel_money)
    ExecuteAction('PLAYER_GIVE_MONEY','Player_5',angel_money)
    ExecuteAction('PLAYER_GIVE_MONEY','Player_6',angel_money)
    exAddTextToPublicBoard(Localization.get('round.angel_win'),10)
    if devil_max>=1200 then
        exAddTextToPublicBoard(Localization.get('round.angel_on_streak'),10)
    end
    if angel_max>=1200 then
        exAddTextToPublicBoard(Localization.get('round.angel_end_streak'),10)
    end
    devil_money=0
    angel_money=0
    if angel_max >= 1800 then
        angel_max = angel_max / 2;
    else
        angel_max=200
    end
    if devil_max<4200 then
        devil_max=devil_max+400
    end
else
    devil_money=0
    angel_money=0
    exAddTextToPublicBoard(Localization.get('round.no_winner'),10)
end
