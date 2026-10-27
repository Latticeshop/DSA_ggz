-- 讲解见 analysis/地图注释说明文档.md 附录 A.90

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
