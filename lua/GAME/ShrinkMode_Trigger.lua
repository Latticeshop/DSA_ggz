if g_EnableShrinkMode == 1 then
    ShrinkMode_Apply()
end

-- LandArmySpawn 生成并混编完本回合单位后，在与缩小模式相同的时机按玩家单位池配额施加符文。
if g_EnableHextechRune == 1 and HextechRune ~= nil then
    HextechRune:ApplyRoundEffects(exCounterGetByName("lvc"))
end
