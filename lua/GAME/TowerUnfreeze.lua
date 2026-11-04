-- 防御塔防冻结：周期性地把塔的冷冻条抽干。
g_TowerUnfreezeTypes = {
    -- 地编塔模板（清单见 map.xml 的 Structure 段）。这里记的血量是**地编里的百分比**（`Health="450"` = 原建筑血量 ×450%），
    -- 不是绝对值；绝对值 = 原模板血量 × 百分比，原模板血量在游戏 INI 里。
    "SovietBaseDefenseGround",          -- 450%：T71 / T81（上限，再加就吃不住达摩剑的一击必杀）
    "CelestialBaseDefenseAdvanced",     -- 1500%：T72 / T82；5000%：T73F / T83F（同模板两个不同百分比）
    "CelestialEnergyGatlingTower",      -- 4000%：T73 / T83
    "AlliedHeavyArtilleryDefenseBase",  -- 7500%：T74 / T84
    "SovietBaseDefenseAdvanced",        -- 210%：T71F / T81F；缩小模式 ShrinkMode741 / 841
    "JapanBaseDefenseAdvanced",         -- 2500%：T72F / T82F
    -- 另外两种「防御塔」模板（BasicVar1: g_TargetGroupNames.DefenseTower，九头蛇/冰天雪地按它排除）：
    -- 地图上目前没有实例，但塔防专家/缩小模式这类生成路径随时可能摆出来，先按模板兜住。
    "CelestialBaseDefenseAir",              -- 对空型
    "CelestialBaseDefenseAdvanced_NoCore",  -- 无核心型
    -- 市场五塔模板
    "JapanPointShieldControlTower",     -- 护盾塔
    "SovietHeavyAntiAirMissileTurret",  -- 胡杨；缩小模式 ShrinkMode742 / 842
    "JapanKamikazeCommandTower",        -- 樱花井
    "AlliedAegisLargeDefenseBase",      -- 埃奎斯
    "CelestialEnergyRailgunBase",       -- 天门神弓
}

-- 一次抽掉的冷冻量：-50000 足够清空任何塔的冷冻条（血量最厚的缩小模式塔 3 万也一次归零）。
g_TowerUnfreezeDrain = -50000

if g_TowerUnfreezeFilter == nil then
    g_TowerUnfreezeFilter = CreateObjectFilter({
        Rule = "ANY",
        IncludeThing = g_TowerUnfreezeTypes,
    })
end

function g_TowerUnfreezeTick()
    local towers, count = ObjectFindObjects(nil, nil, g_TowerUnfreezeFilter)
    for i = 1, count, 1 do
        local tower = towers[i]
        if tower ~= nil and ObjectIsAlive(tower) then
            exObjectDealSecondaryDamage(ObjectGetId(tower), g_TowerUnfreezeDrain)
        end
    end
end

g_TowerUnfreezeTick()
