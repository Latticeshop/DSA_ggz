PLYNAME = {}
PLYNAME[1] = "$p1Name:"
PLYNAME[2] = "$p2Name:"
PLYNAME[3] = "$p3Name:"
PLYNAME[4] = "$p4Name:"
PLYNAME[5] = "$p5Name:"
PLYNAME[6] = "$p6Name:"
exScoreBoardSetVisibility(1)
-- 设置标题文字
exScoreBoardSetTitle(Localization.get("board.title.troop_count"))
-- 设置某行某列的文字
-- row 行  范围1~7
-- col 列  范围1~3
for i = 1 , 8 , 1 do
    exScoreBoardSetText(PLYNAME[i], i, 1)
end
exScoreBoardSetText(Localization.get("board.title.current_round"),7, 2)

function boardact ()
    local counterValue= exCounterGetByName("lvc");
    for i = 1 , 8 , 1 do
        exScoreBoardSetText("   "..ANYUNITCOUNT[i], i, 2)
    end
    exScoreBoardSetText(""..counterValue, 7, 3)
    exScoreBoardSetText(Localization.get("board.role.devil1"), 1, 3)
    exScoreBoardSetText(Localization.get("board.role.devil2"), 2, 3)
    exScoreBoardSetText(Localization.get("board.role.devil3"), 3, 3)
    exScoreBoardSetText(Localization.get("board.role.angel1"), 4, 3)
    exScoreBoardSetText(Localization.get("board.role.angel2"), 5, 3)
    exScoreBoardSetText(Localization.get("board.role.angel3"), 6, 3)
end
