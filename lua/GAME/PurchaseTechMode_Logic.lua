g_evilTechLevel = 1;
g_angelTechLevel = 1;

g_evilTechBuyRound = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
}

g_angelTechBuyRound = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
}

g_techLevelNeededMoney = {
    [1] = 10500,
    [2] = 23000,
    [3] = 35000,
}


g_maxTechLevelDecreaseMoney = {
    [1] = 9000,
    [2] = 14400,
    [3] = 23100,
}

g_maxTechLevelDecreaseRate = {
    [1] = 1500,
    [2] = 1800,
    [3] = 2100,
}

function PurchaseTechMode_Setting()

    ExecuteAction("NAMED_SET_MAX_HEALTH", "T73", 30000, 1)
    ExecuteAction("NAMED_SET_MAX_HEALTH", "T74", 140000, 1)
    ExecuteAction("NAMED_SET_MAX_HEALTH", "T83", 30000, 1)
    ExecuteAction("NAMED_SET_MAX_HEALTH", "T84", 140000, 1)

    -- 删除展示体前必须解除守护者登记：引擎复用对象 id 后，新单位会被当成守护神。
    local object = GetObjectByScriptName("overlord7")
    UnregisterTowerGuardian(object)
    ExecuteAction("NAMED_DELETE", object);
    object = GetObjectByScriptName("overlord8")
    UnregisterTowerGuardian(object)
    ExecuteAction("NAMED_DELETE", object);

    exDisableWBScript("NATURALUNLOCK__1")
    exDisableWBScript("NATURALUNLOCK__2")
    exDisableWBScript("NATURALUNLOCK__3")

    exCreateCustomButton({
        Index = 7,
        TextureName = "AUA_Bribe",
        Desc = Localization.get("purchase_tech.button"),
        X = 250,
        Y = 20,
        GroupIndex = 1,
        AlignX = "right",
        AlignY = "top",
    })

    exEnableWBScript("HidePowerCounter")

    exCreateCustomText({
        Index = 1,
        Content = Localization.get("purchase_tech.level", 1),
        X = 10,
        Y = 10,
        Color = 16711680,
        Size = 15,
        AlignX = "left",
        AlignY = "top",
    })

    exCreateCustomText({
        Index = 2,
        Content = Localization.get("purchase_tech.power_plants", 5),
        X = 0,
        Y = 30,
        Color = 16711680,
        Size = 15,
        AlignX = "left",
        AlignY = "top",
    })

    exCreateCustomText({
        Index = 3,
        Content = Localization.get("purchase_tech.celestial_plants", 4),
        X = 0,
        Y = 50,
        Color = 16711680,
        Size = 15,
        AlignX = "left",
        AlignY = "top",
    })

    -- 按每个玩家真实的小电上限刷新（继承队友后会变成多份），不再写死 5/4。
    for i = 1, 6, 1 do
        local limit = 5
        if GetPlayerPowerPlantLimit ~= nil then
            limit = GetPlayerPowerPlantLimit(i)
        end
        exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 2,
            Localization.get("purchase_tech.power_plants", limit))
        exCustomTextUpdateTextForPlayer("Player_" .. tostring(i), 3,
            Localization.get("purchase_tech.celestial_plants", limit))
    end

end

ButtonManager:RegisterCustomButtonHandler(function(playerName, index)
    if index ~= 7 then
        return nil    
    end
    BtnChoiceDialogEventFunc_ShowPurchaseTechDialog(playerName)
    return 1
end)
