function onUnitTopBtnClickEvent(playerName, unitId)
  ----exMessageAppendToMessageArea("执行")
  local cutMCV = 3
  for i = 1 , 6 , 1 do
  if playerName == "Player_"..i and unitId == BOMBID[i] then
    if i == 1 then
      exMessageAppendToMessageArea(Localization.get("unit_button.angel.dragonship_called"))
      ExecuteAction("PLAY_SOUND_EFFECT","CEL_DragonShip_VoicePack")   
      local counterValue = exCounterGetByName("lvc");
      if counterValue > cutMCV then
      local x1, y1, z1 = ObjectGetPosition(T74) ;
      local sign = 1
      local deltay = 100 
      local realy = 0
      for j = 1 , counterValue - cutMCV , 1 do
        if j <= 6 then
        --exMessageAppendToMessageArea("龙船数量："..i)
        sign = ( sign ) * (-1)
        deltay = deltay * (-1)
        realy = ( realy + deltay ) * sign
      ExecuteAction("CREATE_OBJECT",'CelestialMCV','PlyrCivilian/ATTACK',{X=x1 ,Y=y1 + realy ,Z=z1},"0")   
      end
      end
    end
      exObjectDeleteBtnAtTop(unitId);  -- 删除按钮
    end
    if i == 2 then
      exMessageAppendToMessageArea(Localization.get("unit_button.angel.used_bomb"))
        ExecuteAction("PLAY_SOUND_EFFECT","A01_CoastalGun_ImpactExplosion") 
    exEnableWBScript("KW");
    exObjectDeleteBtnAtTop(unitId);  -- 删除按钮
    end
    if i == 3 then 
      exMessageAppendToMessageArea(Localization.get("unit_button.angel.used_iron_curtain"))
        ExecuteAction("PLAY_SOUND_EFFECT","SOV_IronCurtain_Cast") 
      local TAR, count = ObjectFindObjects(P[7],nil,FilterALLUNIT)
      for j = 1 , count , 1 do
        ObjectLoadAttributeModifier(TAR[j], "AttributeModifier_IronCurtain", 600)
      end
      exObjectDeleteBtnAtTop(unitId);  -- 删除按钮
    end
    if i == 4 then 
      exMessageAppendToMessageArea(Localization.get("unit_button.devil.dragonship_called"))
        ExecuteAction("PLAY_SOUND_EFFECT","CEL_DragonShip_VoicePack")  
      local counterValue = exCounterGetByName("lvc");
      if counterValue > cutMCV then
      local x1, y1, z1 = ObjectGetPosition(T84) ;
      local sign = 1
      local deltay = 100 
      local realy = 0
      for j = 1 , counterValue - cutMCV , 1 do
        if j <= 6 then
        sign = ( sign ) * (-1)
        deltay = deltay * (-1)
        realy = ( realy + deltay ) * sign
      ExecuteAction("CREATE_OBJECT",'CelestialMCV','PlyrCreeps/ATTACK',{X=x1 ,Y=y1 + realy ,Z=z1},"180")   
        end
      end
      end
      exObjectDeleteBtnAtTop(unitId);  -- 删除按钮
    end
    if i == 5 then 
      exMessageAppendToMessageArea(Localization.get("unit_button.devil.used_bomb"))
        ExecuteAction("PLAY_SOUND_EFFECT","A01_CoastalGun_ImpactExplosion") 
      exEnableWBScript("KB");
      exObjectDeleteBtnAtTop(unitId);  -- 删除按钮
    end
    if i == 6 then 
      exMessageAppendToMessageArea(Localization.get("unit_button.devil.used_iron_curtain"))
        ExecuteAction("PLAY_SOUND_EFFECT","SOV_IronCurtain_Cast") 
      local TAR, count = ObjectFindObjects(P[8],nil,FilterALLUNIT)
      for j = 1 , count , 1 do
        ObjectLoadAttributeModifier(TAR[j], "AttributeModifier_IronCurtain", 600)
      end
      exObjectDeleteBtnAtTop(unitId);  -- 删除按钮
    end
end
end
end
