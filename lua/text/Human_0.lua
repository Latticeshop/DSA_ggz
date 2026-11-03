for i = 1,8,1 do
        if not EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", 'Player_'..i , "Human") then
          ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT",'Player_'..i,'AlliedWallPiece','PlyrCreeps/teamPlyrCreeps','toupiaodian'..i)
          exMessageAppendToMessageArea(Localization.get("dialog.read_completed", i))
 end
      end
