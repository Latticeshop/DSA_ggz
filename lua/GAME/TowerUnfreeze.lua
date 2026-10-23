-- 防御塔防冻结：周期性地把塔的冷冻条抽干。
g_TowerUnfreezeTypes = {
    -- 地编塔模板（清单见 map.xml 的 Structure 段，血量可核对）
    "SovietBaseDefenseGround",          -- 陆地 450：T71 / T81
    "CelestialBaseDefenseAdvanced",     -- 陆地 1000：T72 / T82；海塔 3400：T73F / T83F
    "CelestialEnergyGatlingTower",      -- 陆地 2500：T73 / T83
    "AlliedHeavyArtilleryDefenseBase",  -- 陆地 5000：T74 / T84
    "SovietBaseDefenseAdvanced",        -- 海塔 210：T71F / T81F；缩小模式 ShrinkMode741 / 841
    "JapanBaseDefenseAdvanced",         -- 海塔 1500：T72F / T82F
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
