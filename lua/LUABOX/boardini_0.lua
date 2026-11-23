PLYNAME = {}
PLYNAME[1] = "$p1Name:"
PLYNAME[2] = "$p2Name:"
PLYNAME[3] = "$p3Name:"
PLYNAME[4] = "$p4Name:"
PLYNAME[5] = "$p5Name:"
PLYNAME[6] = "$p6Name:"
PLYNAME[7] = "$p7Name:"
PLYNAME[8] = "$p8Name:"

-- 席位 → 阵营标注（这个图的座位号是 1/2/3/8 = 恶魔 1/2/4/3，4/5/6/7 = 天使 1/2/4/3）
g_BoardRoleKeys = {}
g_BoardRoleKeys[1] = "board.role.devil1"
g_BoardRoleKeys[2] = "board.role.devil2"
g_BoardRoleKeys[3] = "board.role.devil4"
g_BoardRoleKeys[4] = "board.role.angel1"
g_BoardRoleKeys[5] = "board.role.angel2"
g_BoardRoleKeys[6] = "board.role.angel4"
g_BoardRoleKeys[7] = "board.role.angel3"
g_BoardRoleKeys[8] = "board.role.devil3"

-- 只画在场玩家：P[i] 是座位上的玩家对象（UNITCOUNTERINI_0.lua 里 P[i] = GetObjectByScriptName("P"..i)），
-- 空位为 nil。P 还没初始化时先按"全员在场"处理，boardact() 每帧再纠正。
function IsBoardSeatInPlay(seatIndex)
    if P == nil then
        return true
    end
    return P[seatIndex] ~= nil
end

exScoreBoardSetVisibility(1)
-- 设置标题文字
exScoreBoardSetTitle(Localization.get("board.title.troop_count"))
-- 设置某行某列的文字，row = 玩家号（1~8），col 1=名字 2=部队数量 3=阵营位次
for i = 1 , 8 , 1 do
    if IsBoardSeatInPlay(i) then
        exScoreBoardSetText(PLYNAME[i], i, 1)
    end
end

function boardact ()
    if Localization == nil then
        return
    end
    for i = 1 , 8 , 1 do
        if IsBoardSeatInPlay(i) then
            exScoreBoardSetText("   " .. (tonumber(ANYUNITCOUNT[i]) or 0), i, 2)
            exScoreBoardSetText(Localization.get(g_BoardRoleKeys[i]), i, 3)
        else
            -- 空位整行清空，不留占位行
            exScoreBoardSetText("", i, 1)
            exScoreBoardSetText("", i, 2)
            exScoreBoardSetText("", i, 3)
        end
    end
    -- 标题 = 部队数量 + 单位上限（房主没设上限时显示"无限量"）；部队总数本来就在第 2 列，
    -- 所以这里不再重复显示数量，也不占用计分板的行。
    local cap = 0
    if GetUnitCapLimit ~= nil then
        cap = tonumber(GetUnitCapLimit()) or 0
    end
    local capText = Localization.get("board.unit_cap.unlimited")
    if cap > 0 then
        capText = "" .. cap
    end
    exScoreBoardSetTitle(Localization.get("board.title.troop_count") .. "   " ..
        Localization.get("board.title.unit_cap") .. capText)
end
