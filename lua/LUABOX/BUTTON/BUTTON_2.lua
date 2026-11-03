function onUserLongTextDialogEvent(playerName, btnIndex, dialogId)
  for i=1,8,1 do
    if playerName=="Player_"..i and (i==1 or i==2 or i==3 or i==8) and dialogId==200+i then
      if btnIndex==1 then
        exAddTextToPublicBoard(Localization.get("surrender.devil.choose", i), 30)
        devil_surrender=devil_surrender+1
      elseif btnIndex==3 then
        exAddTextToPublicBoard(Localization.get("surrender.devil.fight", i), 30)
        devil_surrender=devil_surrender-1
      else
        exAddTextToPublicBoard(Localization.get("surrender.devil.pass", i), 30)
      end
    end
    if playerName=="Player_"..i and (i==4 or i==5 or i==6 or i==7) and dialogId==200+i then
      if btnIndex==1 then
        exAddTextToPublicBoard(Localization.get("surrender.angel.choose", i), 30)
        angel_surrender=angel_surrender+1
      elseif btnIndex==3 then
        exAddTextToPublicBoard(Localization.get("surrender.angel.fight", i), 30)
        angel_surrender=angel_surrender-1
      else
        exAddTextToPublicBoard(Localization.get("surrender.angel.pass", i), 30)
      end
    end
  end
end