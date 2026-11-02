CelestialCenturionUpgradeUseCount = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 1,
    [5] = 1,
    [6] = 1,
}
CelestialCenturionUpgradeLevel = {
    [1] = 0,
    [2] = 0,
    [3] = 0,
    [4] = 0,
    [5] = 0,
    [6] = 0,
}
CelestialCenturionUpgradeUseCountLevelCounter = 0
CelestialCenturionMaxUseCount = 3

SchedulerModule.call_every_x_frame(function()
    local round = exCounterGetByName("lvc")
    if CelestialCenturionUpgradeUseCountLevelCounter ~= round then
        CelestialCenturionUpgradeUseCountLevelCounter = round
        -- 每个回合重置使用次数
        for i = 1, 8, 1 do
            local spellbookId = g_PlayerSpellBookId[i]
            if spellbookId ~= 0 and exObjectGetSpecialCountDownFrame(spellbookId, "SpecialPower_CelestialCenturionUpgrade") >= 1 then
                ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", GetObjectById(spellbookId), "SpecialPower_CelestialCenturionUpgrade", 1);
                if (CelestialCenturionUpgradeLevel[i] or 0) == 0 then
                    CelestialCenturionUpgradeLevel[i] = 1
                end
            end
            if round >= 9 and CelestialCenturionUpgradeLevel[i] == 1 then
                CelestialCenturionUpgradeLevel[i] = 2
                exMessageAppendToMessageArea(Localization.get("celestial_centurion.unlock", i))
            end
            CelestialCenturionUpgradeUseCount[i] = 1
        end
    end

    local maxUseCount = round + 1
    if maxUseCount > CelestialCenturionMaxUseCount then
        maxUseCount = CelestialCenturionMaxUseCount
    end

    for i = 1, 8, 1 do
        if CelestialCenturionUpgradeUseCount[i] < maxUseCount then
            local spellbookId = g_PlayerSpellBookId[i]
            if spellbookId ~= 0 and exObjectGetSpecialCountDownFrame(spellbookId, "SpecialPower_CelestialCenturionUpgrade") >= 200 then
                ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", GetObjectById(spellbookId), "SpecialPower_CelestialCenturionUpgrade", 2);
                CelestialCenturionUpgradeUseCount[i] = CelestialCenturionUpgradeUseCount[i] + 1
                if (CelestialCenturionUpgradeLevel[i] or 0) == 0 then
                    CelestialCenturionUpgradeLevel[i] = 1
                end
            end
        end
    end

end, 15, nil)