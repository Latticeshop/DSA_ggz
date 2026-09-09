if g_GameMode == 2 or g_EnableDeathModeEffect == 1 then
    exEnableWBScript("DeathMode")
end

if g_EnableShrinkMode == 1 then
    ShrinkMode_Setting()
end

if g_GameMode == 4 then
    PurchaseTechMode_Setting()
end

if g_DrawMode == 2 then
    PureLuckyCrateMode_Setting()
end

RecycleUnit_Setting()
