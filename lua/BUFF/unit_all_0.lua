
-- 达摩剑的常规随机目标池：只允许非建筑单位。
-- 最前方防御塔仅由达摩剑首轮逻辑单独指定一次，不进入本过滤器。
-- 守护神不再按模板名排除：普通 Overlordtank / JapanFortressShip 是合法目标，
-- 抽取时由 g_IsPresetGuardianUnit 剔除真正的地编守护神。
-- 本节点早于 GAME/BasicVar 加载，过滤器必须首次使用时再建。
unitall = nil

function g_GetDamoclesUnitFilter()
    if unitall == nil then
        local excluded = g_CollectTargetNames({"AIAnchorMCV", "DragonShip", "Nightingale"})
        -- 旧口径只排除基础运兵车，保持不变。
        tinsert(excluded, "JapanLightTransportVehicle")
        unitall = CreateObjectFilter({
            Rule="ANY",
            Relationship="SAME_PLAYER",
            ExcludeThing=excluded,
            Include="SELECTABLE",
            -- 所有防御塔和其他建筑都排除，单位不足时也不会拿塔补位。
            Exclude="STRUCTURE",
        })
    end
    return unitall
end
