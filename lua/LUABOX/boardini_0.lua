PLYNAME = {}
PLYNAME[1] = "$p1Name:"
PLYNAME[2] = "$p2Name:"
PLYNAME[3] = "$p3Name:"
PLYNAME[4] = "$p4Name:"
PLYNAME[5] = "$p5Name:"
PLYNAME[6] = "$p6Name:"
PLYNAME[7] = "$p7Name:"
PLYNAME[8] = "$p8Name:"
exScoreBoardSetVisibility(1)
-- 设置标题文字
exScoreBoardSetTitle(Localization.get("board.title.troop_count"))
-- 设置某行某列的文字，row = 玩家号（1~8），col 1=名字 2=部队数量 3=阵营位次
for i = 1 , 8 , 1 do
    exScoreBoardSetText(PLYNAME[i], i, 1)
end

function boardact ()
    local counterValue= exCounterGetByName("lvc");
    for i = 1 , 8 , 1 do
        exScoreBoardSetText("   "..ANYUNITCOUNT[i], i, 2)
    end
    -- 8 个玩家占满 1~8 行，回合信息并入标题（原来占第 7 行，会和 7 号玩家冲突）
    exScoreBoardSetTitle(Localization.get("board.title.troop_count") .. "   " ..
        Localization.get("board.title.current_round") .. "" .. counterValue)
    exScoreBoardSetText(Localization.get("board.role.devil1"), 1, 3)
    exScoreBoardSetText(Localization.get("board.role.devil2"), 2, 3)
    exScoreBoardSetText(Localization.get("board.role.devil4"), 3, 3)
    exScoreBoardSetText(Localization.get("board.role.devil3"), 8, 3)
    exScoreBoardSetText(Localization.get("board.role.angel1"), 4, 3)
    exScoreBoardSetText(Localization.get("board.role.angel2"), 5, 3)
    exScoreBoardSetText(Localization.get("board.role.angel4"), 6, 3)
    exScoreBoardSetText(Localization.get("board.role.angel3"), 7, 3)
end
