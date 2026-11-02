
T84= GetObjectByScriptName('T84')
T74= GetObjectByScriptName('T74')
BOMB = {}
BOMBID = {}
exCenterTopBtnsChangeVisibility(1)
exCenterTopBtnSetHealthBarVisibility(1,1);
CenterTopBtnFunc_InitializeAutoSurrender()
--exCenterTopBtnShowForPlayer('Player_1', 1,'Button_SovietTeslaMissile','局部毁灭武器(全局仅限一次)\n摧毁一大片地区的所有敌方单位')
--exCenterTopBtnShowForPlayer('Player_1',2,'Button_CelestialPantaOrbitalStrike','达摩克利斯之剑(全局可使用两次)\n请求太空的卫星对敌方启用15秒的精准卫星打击')
--exCenterTopBtnShowForPlayer('Player_2', 1,'Button_PlayerPower_IronCurtain','铁幕演说(全局可使用两次)\n进行铁幕演说,让全体单位套上坚不可摧的铁幕，持续15秒')
--exCenterTopBtnShowForPlayer('Player_2', 2,'AUA_Timebelt','时空管理局(全局仅限2次)\n借助未来科技的力量时停对方单位13s')
--exCenterTopBtnShowForPlayer('Player_3', 1,'CEL_DragonShipLand','龙行天下(全局仅限一次)\n召唤回合数减三的龙船数量于主巨炮位置,上限不得超过三艘')
--exCenterTopBtnShowForPlayer('Player_3', 2,'Button_SovietInterceptorAircraft','空军元帅(全局可使用两次)\n请求超级苏霍伊群抵达战场对敌方的空军造成毁灭性的攻击')
--exCenterTopBtnShowForPlayer('Player_4', 1,'Button_SovietTeslaMissile','局部毁灭武器(全局仅限一次)\n摧毁一大片地区的所有敌方单位')
--exCenterTopBtnShowForPlayer('Player_4',2,'Button_CelestialPantaOrbitalStrike','达摩克利斯之剑(全局可使用两次)\n请求太空的卫星对敌方启用15秒的精准卫星打击')
--exCenterTopBtnShowForPlayer('Player_5', 1,'Button_PlayerPower_IronCurtain','铁幕演说(全局可使用两次)\n进行铁幕演说,让全体单位套上坚不可摧的铁幕持续15秒')
--exCenterTopBtnShowForPlayer('Player_5', 2,'AUA_Timebelt','时空管理局(全局仅限2次)\n借助未来科技的力量时停对方单位13s')
--exCenterTopBtnShowForPlayer('Player_6', 1,'CEL_DragonShipLand','龙行天下(全局仅限一次)\n召唤回合数减三的龙船数量于主巨炮位置,上限不得超过三艘')
--exCenterTopBtnShowForPlayer('Player_6', 2,'Button_SovietInterceptorAircraft','空军元帅(全局可使用两次)\n请求超级苏霍伊群抵达战场对敌方的空军造成毁灭性的攻击')
for i = 1 , 8 , 1 do
    CenterTopBtnFunc_CreateInitialButtons(i)
    BOMB[i] = GetObjectByScriptName("BOMB"..i) ;
    local objectId = ObjectGetId(BOMB[i])
    BOMBID[i] = objectId
end

FilterMCVC=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    IncludeThing = {
        "CelestialMCV"
    }
})

FilterALLUNIT=CreateObjectFilter({
    Rule="ANY",
    Relationship="SAME_PLAYER",
    Include="SELECTABLE"--exMessageAppendToMessageArea
})