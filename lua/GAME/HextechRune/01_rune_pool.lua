-- 讲解见 analysis/地图注释说明文档.md 附录 A.3、A.39、A.46、A.71、A.73、A.82、A.88

-- 海克斯符文系统：首批正式符文池与候选抽取。
-- 抽取顺序：先确定全场稀有度，再按玩家状态筛池，最后无放回抽取 3 个。

HextechRune = HextechRune or {}

HextechRune.RunePool = {
    -- 白银
    { Id = "silver_strength", Rarity = 3, NameKey = "hextech.rune.strength.name",
        DescKey = "hextech.rune.strength.desc", Effect = "damage", NeedsUnitType = true,
        Icon = "Button_PlayerPower_EmperorRage3" },
    { Id = "silver_swiftness", Rarity = 3, NameKey = "hextech.rune.swiftness.name",
        DescKey = "hextech.rune.swiftness.desc", Effect = "rate_of_fire", NeedsUnitType = true,
        Icon = "Upgrade_CelestialSpeedUpdate" },
    { Id = "silver_hunt", Rarity = 3, NameKey = "hextech.rune.hunt.name",
        DescKey = "hextech.rune.hunt.desc", Effect = "speed", NeedsUnitType = true,
        Icon = "SUA_Grinder_TurboBoost" },
    { Id = "silver_scope", Rarity = 3, NameKey = "hextech.rune.scope.silver.name",
        DescKey = "hextech.rune.scope.silver.desc", Effect = "range_silver", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "silver_astral_body", Rarity = 3,
        NameKey = "hextech.rune.astral_body.name",
        DescKey = "hextech.rune.astral_body.desc", Effect = "astral_body",
        NeedsUnitType = true, Icon = "SovietCompositeArmorUpgrade" },
    { Id = "silver_mcv", Rarity = 3, NameKey = "hextech.rune.mcv.name",
        DescKey = "hextech.rune.mcv.desc", Effect = "grant_foreign_mcv",
        Icon = "Button_JapanMCV" },
    { Id = "silver_giga_fortress", Rarity = 3,
        NameKey = "hextech.rune.giga_fortress.name",
        DescKey = "hextech.rune.giga_fortress.desc", Effect = "grant_giga_fortress",
        RequiresType = "aircraft",
        Icon = "Button_JapanGigaFortressShip" },
    { Id = "silver_five_tiger_generals", Rarity = 3,
        NameKey = "hextech.rune.five_tiger_generals.name",
        DescKey = "hextech.rune.five_tiger_generals.desc",
        Effect = "five_tiger_generals", RequiresType = "infantry",
        Icon = "CelestialCenturion" },
    { Id = "silver_quality_transformation", Rarity = 3,
        NameKey = "hextech.rune.quality_transformation.name",
        DescKey = "hextech.rune.quality_transformation.desc",
        Effect = "quality_transformation", UpgradeRarity = 2,
        Icon = "CAAT4_Transform" },
    { Id = "silver_export_domestic", Rarity = 3,
        NameKey = "hextech.rune.export_domestic.name",
        DescKey = "hextech.rune.export_domestic.desc",
        Effect = "upgrade_tachi_cruiser", RequiredFaction = 3,
        RequiresType = "navy",
        Icon = "Button_JapanAntiNavyShipTech3" },
    { Id = "silver_dual_purpose", Rarity = 3,
        NameKey = "hextech.rune.dual_purpose.name",
        DescKey = "hextech.rune.dual_purpose.desc",
        Effect = "upgrade_bullfrog", RequiredFaction = 2,
        RequiresType = "vehicle",
        Icon = "Button_VDVAntiAirVehicleTech1" },
    { Id = "silver_dragon_breathe", Rarity = 3,
        NameKey = "hextech.rune.dragon_breathe.name",
        DescKey = "hextech.rune.dragon_breathe.desc",
        Effect = "upgrade_waverider_dragon_breathe", RequiredFaction = 4,
        RequiresType = "vehicle",
        Icon = "CelestialHeavyLingboIFV" },
    { Id = "silver_advanced_artillery", Rarity = 3,
        NameKey = "hextech.rune.advanced_artillery.name",
        DescKey = "hextech.rune.advanced_artillery.desc",
        Effect = "upgrade_vanguard_gunship", RequiredFaction = 1,
        RequiresType = "aircraft",
        Icon = "Button_AlliedHarbingerGunship" },
    { Id = "silver_banzai_charge", Rarity = 3,
        NameKey = "hextech.rune.banzai_charge.name",
        DescKey = "hextech.rune.banzai_charge.desc",
        Effect = "upgrade_imperial_warrior", RequiredFaction = 3,
        RequiresType = "infantry",
        Icon = "Button_JapanKamikazeBonzai" },
    -- （前几回合就把樱花换成鬼樱过于超模；判定见 BuildFilteredPool 与 §4.0 全局规则）。
    { Id = "silver_five_centimeters", Rarity = 3,
        NameKey = "hextech.rune.five_centimeters.name",
        DescKey = "hextech.rune.five_centimeters.desc",
        Effect = "upgrade_sakura_rocket", RequiredFaction = 3,
        RequiresType = "aircraft",
        ExcludeOnFirstFormalSelection = true,
        Icon = "Portrait_JapanInterceptorAircraft_air" },
    { Id = "silver_wheeled_cannon", Rarity = 3,
        NameKey = "hextech.rune.wheeled_cannon.name",
        DescKey = "hextech.rune.wheeled_cannon.desc",
        Effect = "upgrade_rhino_tank", RequiredFaction = 2,
        RequiresType = "vehicle",
        Icon = "Button_SovietHeavyAntiAirVehicleTech2" },
    { Id = "silver_investment", Rarity = 3,
        NameKey = "hextech.rune.investment.name",
        DescKey = "hextech.rune.investment.desc",
        Effect = "investment", Icon = "Button_CelestialRefinery" },
    { Id = "silver_hunt_rhythm", Rarity = 3,
        NameKey = "hextech.rune.hunt_rhythm.name",
        DescKey = "hextech.rune.hunt_rhythm.desc",
        Effect = "hunt_rhythm", NeedsUnitType = true,
        Icon = "Button_CelestialSupportAircraft_Skill" },
    -- ExcludeOnLastFormalRound 使它不会出现在本场最后一次选择里（那时已无下一次）。
    { Id = "silver_prepare_backpack", Rarity = 3,
        NameKey = "hextech.rune.prepare_backpack.name",
        DescKey = "hextech.rune.prepare_backpack.desc",
        Effect = "prepare_backpack", ExcludeOnLastFormalRound = true,
        Icon = "SUA_Unpack" },
    { Id = "silver_tulip_mortar", Rarity = 3,
        NameKey = "hextech.rune.tulip_mortar.name",
        DescKey = "hextech.rune.tulip_mortar.desc",
        Effect = "upgrade_v4_tulip", RequiredFaction = 2,
        RequiresType = "vehicle",
        Icon = "Button_SovietHeavyMortarVehicle" },
    -- 「时空裂缝2级」、图标随档位换 ChronoRift2，Id 也跟着改（详见设计文档 §7 当日条目）。
    { Id = "silver_divine_might", Rarity = 3,
        NameKey = "hextech.rune.divine_might.name",
        DescKey = "hextech.rune.divine_might.desc", Effect = "grant_chrono_rift",
        Icon = "Button_PlayerPower_ChronoRift2" },
    { Id = "silver_chicken_soup", Rarity = 3,
        NameKey = "hextech.rune.chicken_soup.name",
        DescKey = "hextech.rune.chicken_soup.desc", Effect = "grant_irradiate",
        -- 毒质腐蚀只对载具生效：禁载具时这张符文没有可用目标，整张不入池。
        RequiresType = "vehicle",
        Icon = "Button_PlayerPower_IrradiateTarget" },
    { Id = "silver_easy_does_it", Rarity = 3,
        NameKey = "hextech.rune.easy_does_it.name",
        DescKey = "hextech.rune.easy_does_it.desc",
        Effect = "easy_does_it", ExcludeOnLastFormalRound = true,
        ExclusiveRuneIds = { prismatic_gambling_addict = true },
        Icon = "AUA_Unpack" },
    { Id = "silver_recycler", Rarity = 3, NameKey = "hextech.rune.recycler.name",
        DescKey = "hextech.rune.recycler.desc", Effect = "recycler",
        Icon = "Button_AlliedSalvageShip" },

    -- 黄金
    { Id = "gold_oblivion_bomb", Rarity = 2,
        NameKey = "hextech.rune.oblivion_bomb.name",
        DescKey = "hextech.rune.oblivion_bomb.desc", Effect = "grant_oblivion_bomb",
        Icon = "Button_PlayerPower_Telekenetic" },
    -- 烧福瑞：只对敌方步兵生效（禁步兵时对面没有步兵，整张下架）。
    { Id = "gold_burn_furry", Rarity = 2,
        NameKey = "hextech.rune.burn_furry.name",
        DescKey = "hextech.rune.burn_furry.desc",
        Effect = "burn_furry", RequiresType = "infantry",
        Icon = "Button_SovietScoutInfantry_small" },
    -- 生异形 / 钓鱼佬：已上调为棱彩（Rarity 1），Id 保留 gold_ 前缀，避免排除名单与文档联动。
    -- 生异形：与烧福瑞同款回合转化，目标换成敌方载具（禁载具时整张下架）。
    { Id = "gold_spawn_alien", Rarity = 1,
        NameKey = "hextech.rune.spawn_alien.name",
        DescKey = "hextech.rune.spawn_alien.desc",
        Effect = "spawn_alien", RequiresType = "vehicle",
        Icon = "Button_SovietScoutVehicle_small" },
    -- 钓鱼佬：与烧福瑞同款回合转化，目标换成敌方海军（禁海时整张下架）。
    { Id = "gold_angler", Rarity = 1,
        NameKey = "hextech.rune.angler.name",
        DescKey = "hextech.rune.angler.desc",
        Effect = "angler", RequiresType = "navy",
        Icon = "Button_JapanAntiShipAircraft_air" },
    -- 樱落：同款回合转化，目标换成敌方空军（禁空军时整张下架）。
    { Id = "prismatic_sit_tight", Rarity = 1,
        NameKey = "hextech.rune.sit_tight.name",
        DescKey = "hextech.rune.sit_tight.desc",
        Effect = "sit_tight", RequiresType = "aircraft",
        Icon = "Button_JapanInterceptorAircraft_sea" },
    { Id = "gold_cloudbreaker", Rarity = 2, NameKey = "hextech.rune.cloudbreaker.name",
        DescKey = "hextech.rune.cloudbreaker.desc", Effect = "grant_yaoguang",
        -- 摇光是 UNITLIST 槽 103（飞机段），按纯空军算：禁空军时这张符文不入池。
        RequiresType = "aircraft",
        Icon = "Button_CelestialAdvancedAircraftTech4" },
    { Id = "gold_oil_king", Rarity = 2, NameKey = "hextech.rune.oil_king.name",
        DescKey = "hextech.rune.oil_king.desc", Effect = "oil_king",
        Icon = "Button_PlayerPower_FreeTrade" },
    { Id = "gold_buy_two_get_one", Rarity = 2, NameKey = "hextech.rune.buy_two_get_one.name",
        DescKey = "hextech.rune.buy_two_get_one.desc", Effect = "buy_two_get_one",
        Icon = "Button_JapanAntiInfantryInfantry" },
    { Id = "gold_starting_funds", Rarity = 2, NameKey = "hextech.rune.starting_funds.name",
        DescKey = "hextech.rune.starting_funds.desc", Effect = "starting_funds",
        Icon = "AUA_Bribe" },
    -- 协议授予·金·现金奖励：—— 多人局里协议放不出来、也不结算的
    -- 问题还没定性，先不让它进池。恢复时取消这条注释，并同步取消 04_buff.lua 派发分支与本表
    -- { Id = "gold_cash_reward", Rarity = 2,
    --     NameKey = "hextech.rune.cash_reward.name",
    --     DescKey = "hextech.rune.cash_reward.desc", Effect = "cash_reward",
    --     Icon = "Button_PlayerPower_ProductionKickback" },
    { Id = "gold_safety", Rarity = 2,
        NameKey = "hextech.rune.safety.name",
        DescKey = "hextech.rune.safety.desc", Effect = "safety",
        Icon = "Button_AlliedAegisLargeDefenseBase" },
    -- 与安全感同类：即时赠送建筑，可重复获取，不占用交易市场的购买名额。
    { Id = "gold_railgun_duel", Rarity = 2,
        NameKey = "hextech.rune.railgun_duel.name",
        DescKey = "hextech.rune.railgun_duel.desc", Effect = "grant_railgun",
        Icon = "Button_CelestialEnergyRailgunBase" },
    -- 协议授予·金·冷冻卫星：地图外钥匙基地 + HELD 禁用的机制已实测跑通，但本轮仍不上线。
    -- 恢复时取消这条注释，并同步取消 04_buff.lua 的派发分支与本表排除名单里对应行的注释。
    -- 同门的「银·神威」已按白银档上线（见上方白银段末尾）。
    -- { Id = "gold_cryo_satellite", Rarity = 2,
    --     NameKey = "hextech.rune.cryo_satellite.name",
    --     DescKey = "hextech.rune.cryo_satellite.desc", Effect = "grant_cryo_satellite",
    --     Icon = "Button_PlayerPower_CryoSatellite3" },
    { Id = "gold_fortified", Rarity = 2, NameKey = "hextech.rune.fortified.name",
        DescKey = "hextech.rune.fortified.desc", Effect = "fortified",
        Icon = "Button_CelestialAntiVehicleInfantry_Skill" },
    { Id = "gold_scope", Rarity = 2, NameKey = "hextech.rune.scope.gold.name",
        DescKey = "hextech.rune.scope.gold.desc", Effect = "range_gold", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "gold_transcendent_evil", Rarity = 2,
        NameKey = "hextech.rune.transcendent_evil.name",
        DescKey = "hextech.rune.transcendent_evil.desc",
        Effect = "transcendent_evil", NeedsUnitType = true,
        Icon = "Button_PlayerPower_EmperorRage3" },
    { Id = "gold_brilliant_lights", Rarity = 2,
        NameKey = "hextech.rune.brilliant_lights.name",
        DescKey = "hextech.rune.brilliant_lights.desc",
        Effect = "brilliant_lights", Icon = "CelestialEngineerDroneSpecialPower" },
    { Id = "gold_quality_transformation", Rarity = 2,
        NameKey = "hextech.rune.quality_transformation.name",
        DescKey = "hextech.rune.quality_transformation.desc",
        Effect = "quality_transformation", UpgradeRarity = 1,
        Icon = "CAAT4_Transform" },
    { Id = "gold_combustion_interest", Rarity = 2,
        NameKey = "hextech.rune.combustion_interest.name",
        DescKey = "hextech.rune.combustion_interest.desc",
        Effect = "combustion_interest", Icon = "Button_PlayerPower_ProductionKickback" },
    -- 死亡触发类：与炽燃利息共用一条死亡转发。
    { Id = "gold_ascension", Rarity = 2,
        NameKey = "hextech.rune.ascension.name",
        DescKey = "hextech.rune.ascension.desc",
        Effect = "ascension", Icon = "JapanAVVT4Heal" },
    { Id = "gold_ragnarok", Rarity = 2,
        NameKey = "hextech.rune.ragnarok.name",
        DescKey = "hextech.rune.ragnarok.desc",
        Effect = "ragnarok", NeedsUnitType = true,
        Icon = "CelestialLightningTroop_Lv2" },
    { Id = "gold_poach", Rarity = 2,
        NameKey = "hextech.rune.poach.name",
        DescKey = "hextech.rune.poach.desc",
        Effect = "poach", Icon = "Portrait_CelestialSaluteGun" },
    { Id = "gold_recombobulator", Rarity = 2,
        NameKey = "hextech.rune.recombobulator.name",
        DescKey = "hextech.rune.recombobulator.desc",
        Effect = "recombobulator_same", ExcludeOnFirstFormalSelection = true,
        Icon = "JUA_Nanotech_Upgrade1" },
    -- 可重复获取：每获得一次就立刻吸取一次。
    { Id = "gold_drain", Rarity = 2,
        NameKey = "hextech.rune.drain.name",
        DescKey = "hextech.rune.drain.desc",
        Effect = "drain", Icon = "Button_PlayerPower_MagneticSingularity" },
    { Id = "gold_soul_interlock", Rarity = 2,
        NameKey = "hextech.rune.soul_interlock.name",
        DescKey = "hextech.rune.soul_interlock.desc",
        Effect = "soul_interlock", NeedsUnitTypePair = true,
        RequireTwoUnitTypes = true,
        Icon = "CelestialQuantumLink" },

    { Id = "gold_ten_pull", Rarity = 1,
        NameKey = "hextech.rune.ten_pull.name",
        DescKey = "hextech.rune.ten_pull.desc",
        Effect = "ten_pull", Icon = "JUA_Archer_Barrage" },
    -- 艾卡西亚的惊喜：盟军三级时空炸弹协议；苏联玩家选到它时同样由钥匙基地解锁。
    { Id = "gold_icathia_surprise", Rarity = 2,
        NameKey = "hextech.rune.icathia_surprise.name",
        DescKey = "hextech.rune.icathia_surprise.desc",
        Effect = "grant_time_bomb", Icon = "Button_PlayerPower_TimeBomb3" },

    -- 棱彩
    { Id = "prismatic_infinite_ammo", Rarity = 1, NameKey = "hextech.rune.infinite_ammo.name",
        DescKey = "hextech.rune.infinite_ammo.desc", Effect = "infinite_ammo", NeedsUnitType = true,
        UnitTypes = { "aircraft" },
        ExcludedFaction = 3,
        Icon = "Button_SovietInterceptorAircraft" },
    { Id = "prismatic_scope", Rarity = 1, NameKey = "hextech.rune.scope.prismatic.name",
        DescKey = "hextech.rune.scope.prismatic.desc", Effect = "range_prismatic", NeedsUnitType = true,
        Icon = "AUA_Tank_TargetPainter" },
    { Id = "prismatic_lethal_tempo", Rarity = 1,
        NameKey = "hextech.rune.lethal_tempo.name",
        DescKey = "hextech.rune.lethal_tempo.desc",
        Effect = "lethal_tempo", Icon = "Portrait_CelestialAntiVehicleVehicleTech3" },
    -- 可重复获取；稀有池与隐性特等奖概率见 10_recombobulator.lua。
    -- ExcludeOnFirstFormalSelection：与金色变形重组器同口径，玩家第一次选择不发（见上条注释）。
    { Id = "prismatic_upgrade_recombobulator", Rarity = 1,
        NameKey = "hextech.rune.upgrade_recombobulator.name",
        DescKey = "hextech.rune.upgrade_recombobulator.desc",
        Effect = "recombobulator_upgrade", ExcludeOnFirstFormalSelection = true,
        Icon = "JUA_Nanotech_Upgrade2" },
    { Id = "prismatic_broadband_jamming", Rarity = 1,
        NameKey = "hextech.rune.broadband_jamming.name",
        DescKey = "hextech.rune.broadband_jamming.desc", Effect = "broadband_jamming",
        Icon = "Upgrade_AlliedAircraftCarrierDrone" },
    { Id = "prismatic_divine_intervention", Rarity = 1,
        NameKey = "hextech.rune.divine_intervention.name",
        DescKey = "hextech.rune.divine_intervention.desc", Effect = "divine_intervention",
        Icon = "Button_PlayerPower_IronCurtain" },
    -- 五雷天罚：2026-10-13 由彩降金（Rarity 1 → 2）。Id 前缀不跟着改（同 gold_ten_pull
    -- 的先例：改稀有度只动 Rarity，Id 一旦改名要连着排除名单与文档一起动，得不偿失）。
    { Id = "prismatic_five_thunder", Rarity = 2,
        NameKey = "hextech.rune.five_thunder.name",
        DescKey = "hextech.rune.five_thunder.desc", Effect = "five_thunder",
        RequiredFaction = 4, Icon = "Button_CelestialPantaOrbitalStrike" },
    { Id = "prismatic_tower_defense_expert", Rarity = 1,
        NameKey = "hextech.rune.tower_defense_expert.name",
        DescKey = "hextech.rune.tower_defense_expert.desc",
        Effect = "tower_defense_expert",
        Icon = "Button_JapanPointShieldControlTower" },
    { Id = "prismatic_ultimate_refresh", Rarity = 1,
        NameKey = "hextech.rune.ultimate_refresh.name",
        DescKey = "hextech.rune.ultimate_refresh.desc",
        Effect = "ultimate_refresh", Icon = "Button_PlayerPower_PointDefenseDrones" },
    { Id = "prismatic_gambling_addict", Rarity = 1,
        NameKey = "hextech.rune.gambling_addict.name",
        DescKey = "hextech.rune.gambling_addict.desc",
        Effect = "gambling_addict", ExclusiveRuneIds = { silver_easy_does_it = true },
        Icon = "Button_PlayerPower_FreeTrade" },
    { Id = "prismatic_ultimate_creature", Rarity = 1,
        NameKey = "hextech.rune.ultimate_creature.name",
        DescKey = "hextech.rune.ultimate_creature.desc",
        Effect = "ultimate_creature", Icon = "Button_RedKingOni" },
    { Id = "prismatic_sea_overlord", Rarity = 1,
        NameKey = "hextech.rune.sea_overlord.name",
        DescKey = "hextech.rune.sea_overlord.desc", Effect = "grant_olympus_carrier",
        RequiresSea = true, Icon = "Button_AlliedGaintAircraftCarrier" },
    { Id = "prismatic_dongfeng_express", Rarity = 1,
        NameKey = "hextech.rune.dongfeng_express.name",
        DescKey = "hextech.rune.dongfeng_express.desc",
        Effect = "grant_dongfeng_express", Icon = "Button_CelestialDF41" },
    { Id = "prismatic_war_efficiency", Rarity = 1,
        NameKey = "hextech.rune.war_efficiency.name",
        DescKey = "hextech.rune.war_efficiency.desc",
        Effect = "war_efficiency", NeedsUnitType = true,
        Icon = "Button_CelestialArmybreakerSwordSlash" },
    { Id = "prismatic_time_rift", Rarity = 1,
        NameKey = "hextech.rune.time_rift.name",
        DescKey = "hextech.rune.time_rift.desc",
        Effect = "time_rift", Icon = "Button_PlayerPower_ChronoRift1" },
    { Id = "prismatic_shrink_ray", Rarity = 1,
        NameKey = "hextech.rune.shrink_ray.name",
        DescKey = "hextech.rune.shrink_ray.desc",
        Effect = "shrink_ray", ExcludeInShrinkMode = true,
        Icon = "AUA_Shrink_Beam" },
    { Id = "prismatic_goliath", Rarity = 1,
        NameKey = "hextech.rune.goliath.name",
        DescKey = "hextech.rune.goliath.desc",
        Effect = "goliath", NeedsUnitType = true,
        Icon = "Button_JapanMechaKing" },
    { Id = "prismatic_back_to_basics", Rarity = 1,
        NameKey = "hextech.rune.back_to_basics.name",
        DescKey = "hextech.rune.back_to_basics.desc",
        Effect = "back_to_basics", NeedsUnitType = true,
        ExcludeOnFirstFormalSelection = true,
        Icon = "SUA_Twinblade_Evacuate" },
    -- 等价交换：兵种1 受益、兵种2 受损。两个兵种在生成候选那一刻一次性随机定好
    -- 持有判定按基础 Id（GetRuneOwnershipId），不按兵种对，避免靠重随叠着拿多份。
    { Id = "prismatic_equivalent_exchange", Rarity = 1,
        NameKey = "hextech.rune.equivalent_exchange.name",
        DescKey = "hextech.rune.equivalent_exchange.desc",
        Effect = "equivalent_exchange", NeedsUnitTypePair = true,
        Icon = "Button_PlayerPower_ChronoSwap" },
    { Id = "prismatic_radiant_bliss", Rarity = 2,
        NameKey = "hextech.rune.radiant_bliss.name",
        DescKey = "hextech.rune.radiant_bliss.desc",
        Effect = "grant_desolator_bomb", Icon = "Button_PlayerPower_DesolatorBomb3" },
    -- 兵种被禁时 GetRuneCandidateUnitTypes 自动把该版本去掉，不需要另写 RequiresType。
    { Id = "gold_at_field", Rarity = 2,
        NameKey = "hextech.rune.at_field.name",
        DescKey = "hextech.rune.at_field.desc",
        Effect = "at_field", NeedsUnitType = true,
        UnitTypes = { "vehicle", "navy" },
        Icon = "Button_JapanNanoSustainingForceField" },
    -- 万象天引：苏联磁力奇点协议，同款钥匙基地解锁。2026-10-24 由彩降金（Id 前缀不跟着改）。
    { Id = "prismatic_myriad_pull", Rarity = 2,
        NameKey = "hextech.rune.myriad_pull.name",
        DescKey = "hextech.rune.myriad_pull.desc",
        Effect = "grant_magnetic_singularity", Icon = "Button_PlayerPower_MagneticSingularity" },
    { Id = "gold_free_trade", Rarity = 2,
        NameKey = "hextech.rune.free_trade.name",
        DescKey = "hextech.rune.free_trade.desc",
        Effect = "grant_free_trade", ExcludedFaction = 1,
        Icon = "Button_PlayerPower_FreeTrade" },
}

-- 只有列在这里的基础符文，才会在玩家持有后永久从该玩家后续候选池排除。
-- 同一轮三选一仍由 PickThreeRunes 的无放回抽取保证互不重复。
HextechRune.NonRepeatableRuneIds = {
    silver_export_domestic = true,
    silver_dual_purpose = true,
    silver_dragon_breathe = true,
    silver_advanced_artillery = true,
    silver_banzai_charge = true,
    -- 花来！：重复持有只是把同一个替换再做一遍，入池替换按持有与否判定，天然无叠加。
    silver_tulip_mortar = true,
    -- 秒速五厘米：同属替换型，第二份不产生任何额外效果。
    silver_five_centimeters = true,
    -- 轮式大炮：同属替换型，第二份不产生任何额外效果。
    silver_wheeled_cannon = true,
    -- 准备背包：每人一份升阶机会；第二份在「下一次已是本场最后一次」时也无从兑现。
    silver_prepare_backpack = true,
    -- 顺手的事：每人一份；两份会把「下一次多拿一张」叠在同一处，整局张数还会顶到 6。
    silver_easy_does_it = true,
    -- 元神互锁：同步组只有一组，第二份没有额外作用，故唯一。
    gold_soul_interlock = true,
    -- 烧福瑞：队友各持一份按 50/75/100% 叠加，同一名玩家第二份不再加档。
    gold_burn_furry = true,
    -- 生异形 / 钓鱼佬 / 樱落：与烧福瑞同口径，队友各持一份按 50/75/100% 叠加，第二份不再加档。
    gold_spawn_alien = true,
    gold_angler = true,
    prismatic_sit_tight = true,
    -- 百虎上将：改成「名下全部步兵」后不再按份数给名额，第二份没有任何额外作用。
    silver_five_tiger_generals = true,
    gold_fortified = true,
    gold_transcendent_evil = true,
    -- 破烂王
    silver_recycler = true,
    silver_divine_might = true,
    -- 金·现金奖励下架留档期间一并注释，恢复时和池内条目一起放开。
    -- gold_cash_reward = true,
    -- 鸡汤来咯：与现金奖励同属苏联协议，重复授予只会互相重置冷却。
    silver_chicken_soup = true,
    -- 金·冷冻卫星仍在下架留档中，恢复时与 16_cryo_satellite.lua 的条目一起取消注释。
    -- gold_cryo_satellite = true,
    prismatic_broadband_jamming = true,
    prismatic_divine_intervention = true,
    prismatic_infinite_ammo = true,
    gold_combustion_interest = true,
    prismatic_tower_defense_expert = true,
    prismatic_gambling_addict = true,
    prismatic_ultimate_creature = true,
    prismatic_five_thunder = true,
    prismatic_dongfeng_express = true,
    gold_ascension = true,
    gold_ragnarok = true,
    -- 挖角：每人唯一，多份等于每回合多拿单位，故列入排除名单。
    gold_poach = true,
    -- 致命节奏：每人唯一，本方全体单位同吃一份修正器，重复没有意义。
    prismatic_lethal_tempo = true,
    -- 回归基本功：整体改写 T1~T4 的强度榜，多份只会让 T3/T4 被压得更狠，故唯一。
    prismatic_back_to_basics = true,
    -- 等价交换：一份就已经把两个兵种分别推到极端，重复只会放大两极分化，故唯一。
    prismatic_equivalent_exchange = true,
    -- 以战养战改为玩家独立且可重复获取：多份只叠加在自己的单位上，故不列入排除。
    prismatic_time_rift = true,
    prismatic_shrink_ray = true,
    -- 狩猎律动：每个兵种各限一份（带兵种，判重键是 Id:兵种；同一兵种重复等于每次死亡多治一只）。
    silver_hunt_rhythm = true,
    -- 享辐 / 万象天引 / 艾卡西亚的惊喜：协议授予类，重复授予只会互相重置冷却。
    prismatic_radiant_bliss = true,
    prismatic_myriad_pull = true,
    gold_icathia_surprise = true,
    gold_free_trade = true,
    -- AT立场：兵种版按 OwnershipId 判重（Id:UnitType），载具与舰船各自独立占位。
    gold_at_field = true,
    -- prismatic_tesla_air_assault = true, -- 磁暴突袭符文：暂不启用
}

-- 登神与究极生物的目标黑名单。
-- 买二送一不受影响，仍然可以圈它们。强化形态今天就没有卡池索引、进不了候选
HextechRune.RuneTargetExcludedTypes = {
    AlliedBomberAircraft = true,                    -- 世纪轰炸机
    AlliedAntiStructureBomberAircraft = true,       -- 世纪轰炸机（对建筑）
    AlliedAntiStructureBomberAircraft_Enhanced = true,
    SovietAntiGroundAttacker = true,                -- 伊尔攻击机
    SovietAntiGroundAttacker_Enhanced = true,
    CelestialBomberAircraft = true,                 -- 金乌轰炸机
    CelestialBomberAircraft_Enhanced = true,
    AlliedScoutInfantry = true,                     -- 将军犬
    SovietScoutInfantry = true,                     -- 熊
    SovietScoutVehicle = true,                      -- 恐怖机器人
    JapanScoutInfantry = true,                      -- 爆裂机器人（蜻蜓）
    CelestialScoutDrone = true,                     -- 天眼哨机
    AlliedAntiVehicleVehicleTech1 = true,           -- 守护者坦克
    AlliedAntiVehicleVehicleTech1_Enhanced = true,
    JapanInterceptorAircraft = true,                -- 樱花回天雷
    JapanSakuraAttackRocket = true,                 -- 鬼樱特攻机
}

HextechRune.PlayerOwnedRunes = HextechRune.PlayerOwnedRunes or {}
HextechRune.PlayerOwnedRuneIds = HextechRune.PlayerOwnedRuneIds or {}
HextechRune.PlayerOwnedRuneCounts = HextechRune.PlayerOwnedRuneCounts or {}
HextechRune.PlayerOptions = HextechRune.PlayerOptions or {}
-- 槽位展示数据：玩家退出后，槽位保留原符文，但名字换成继承者。
HextechRune.PlayerSlotOwnedRunes = HextechRune.PlayerSlotOwnedRunes or {}
HextechRune.PlayerSlotOwnedRuneIds = HextechRune.PlayerSlotOwnedRuneIds or {}
HextechRune.PlayerSlotOwner = HextechRune.PlayerSlotOwner or {}
HextechRune.CurrentGrantSlot = HextechRune.CurrentGrantSlot or {}
HextechRune.SlotFormalSelectionCount = HextechRune.SlotFormalSelectionCount or {}

function HextechRune:EnsurePlayerRuneState(playerIndex)
    if self.PlayerOwnedRunes[playerIndex] == nil then
        self.PlayerOwnedRunes[playerIndex] = {}
    end
    if self.PlayerOwnedRuneIds[playerIndex] == nil then
        self.PlayerOwnedRuneIds[playerIndex] = {}
    end
    if self.PlayerOwnedRuneCounts[playerIndex] == nil then
        self.PlayerOwnedRuneCounts[playerIndex] = {}
    end
end

-- 槽位初始为空；所有符文都通过 AddOwnedRune 同时写入聚合表与槽位展示表。
function HextechRune:EnsureRuneSlotState(slotIndex)
    if slotIndex == nil then
        return
    end
    if self.PlayerSlotOwner[slotIndex] == nil then
        self.PlayerSlotOwner[slotIndex] = slotIndex
    end
    if self.PlayerSlotOwnedRunes[slotIndex] == nil then
        self.PlayerSlotOwnedRunes[slotIndex] = {}
        self.PlayerSlotOwnedRuneIds[slotIndex] = {}
    end
end

function HextechRune:CopyRuneForCandidate(rune, unitType)
    return {
        Id = rune.Id,
        Rarity = rune.Rarity,
        NameKey = rune.NameKey,
        DescKey = rune.DescKey,
        Effect = rune.Effect,
        UnitType = unitType,
        -- 等价交换的第二个兵种（受损方）；其余符文为 nil。
        UnitType2 = rune.UnitType2,
        Icon = rune.Icon,
        TargetUnitType = rune.TargetUnitType,
        TargetUnitIndex = rune.TargetUnitIndex,
        TargetUnitName = rune.TargetUnitName,
        RequiresSea = rune.RequiresSea,
        -- 候选只用于展示与判重，兵种约束是在 BuildFilteredPool 里按**原始符文**判的；
        -- 一并带上只为让候选与定义保持一致（海军的旧写法 RequiresSea 同样如此）。
        RequiresType = rune.RequiresType,
        RequiredFaction = rune.RequiredFaction,
        ExcludedFaction = rune.ExcludedFaction,
        UpgradeRarity = rune.UpgradeRarity,
    }
end

function HextechRune:BuildBuyTwoGetOneTargetFilter()
    if self.BuyTwoGetOneProducibleTypes ~= nil then
        return self.BuyTwoGetOneProducibleTypes, self.BuyTwoGetOneAliasOnlyTypes
    end
    local producible = {}
    local producibleCount = 0
    if g_PureDrawBuildableUnitPool ~= nil then
        for tier = 1, 4, 1 do
            local tierPool = g_PureDrawBuildableUnitPool[tier]
            if tierPool ~= nil then
                for i = 1, getn(tierPool), 1 do
                    local unitType = tierPool[i].Type
                    if unitType ~= nil and producible[unitType] == nil then
                        producible[unitType] = true
                        producibleCount = producibleCount + 1
                    end
                end
            end
        end
    end
    if producibleCount == 0 then
        -- 生产池尚未加载或数据缺失：不缓存、不启用白名单，退回原有行为，
        -- 避免把整个候选池清空导致“买二送一”从三选一里消失。
        return nil, nil
    end
    local aliasOnly = {}
    if g_PureDrawProductionAliases ~= nil then
        for baseType, aliases in g_PureDrawProductionAliases do
            for i = 1, getn(aliases), 1 do
                local alias = aliases[i]
                if alias ~= nil and producible[alias] == nil then
                    aliasOnly[alias] = true
                end
            end
        end
    end
    self.BuyTwoGetOneProducibleTypes = producible
    self.BuyTwoGetOneAliasOnlyTypes = aliasOnly
    return producible, aliasOnly
end

-- 玩家已持有的“买二送一”指定的单位类型。“买二送一”本身可重复选择，
-- 但同一玩家的两个买二送一不能圈同一个单位，否则等于把同一份进度叠了两遍。
function HextechRune:GetOwnedBuyTwoGetOneTargetTypes(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    local result = {}
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == "buy_two_get_one" and rune.TargetUnitType ~= nil then
            result[rune.TargetUnitType] = true
        end
    end
    return result
end

function HextechRune:GetReplacementTargetFilter(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local blocked = {}
    local ownedReplacement = {}
    for i = 1, getn(self.UnitReplacementRunes), 1 do
        local entry = self.UnitReplacementRunes[i]
        if self.PlayerOwnedRuneIds[playerIndex][entry.RuneId] then
            blocked[entry.SourceType] = true
            ownedReplacement[entry.ReplacementType] = true
        else
            blocked[entry.ReplacementType] = true
        end
    end
    return blocked, ownedReplacement
end

-- 单位名 → 池槽位的安全查表：全局表可能尚未初始化，键也可能为 nil，而本引擎不接受 nil 键。
function HextechRune:LookupUnitPoolIndex(unitType)
    if g_UnitNameToUnitIndex == nil or unitType == nil then
        return nil
    end
    return g_UnitNameToUnitIndex[unitType]
end

function HextechRune:GetReplacementTargetName(playerIndex, unitType)
    local info = self:FindAscensionUnitInfo(playerIndex, unitType)
    if info ~= nil and info.Name ~= nil then
        return info.Name
    end
    return self:PickUltimateCreatureDisplayName(unitType)
end

function HextechRune:RemapReplacedRuneTargets(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    -- 本引擎（RA3LuaBridge 方言）对 nil 键查表会直接抛「table index is nil」，不像 PC 版 Lua 4.0 那样
    -- 安静返回 nil；所以下面所有「可能为 nil 的变量当键」的地方都必须先判空（否则一拿替换型符文就报错）。
    local replacements = self.UnitReplacementRunes
    if replacements == nil then
        return
    end
    local mapped = {}
    for i = 1, getn(replacements), 1 do
        local entry = replacements[i]
        if entry ~= nil and entry.SourceType ~= nil
            and self.PlayerOwnedRuneIds[playerIndex][entry.RuneId] ~= nil then
            mapped[entry.SourceType] = entry
        end
    end
    local owned = self.PlayerOwnedRunes[playerIndex]
    if owned == nil then
        return
    end
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune ~= nil then
            -- 只有指定单位型（登神 / 买二送一 / 究极生物）才有 TargetUnitType，其余全是 nil。
            local targetType = rune.TargetUnitType
            if targetType ~= nil then
                local entry = mapped[targetType]
                if entry ~= nil and (rune.Effect == "ascension"
                    or rune.Effect == "buy_two_get_one") then
                    rune.TargetUnitType = entry.ReplacementType
                    rune.TargetUnitIndex = self:LookupUnitPoolIndex(entry.ReplacementType)
                        or rune.TargetUnitIndex
                    rune.TargetUnitName = self:GetReplacementTargetName(playerIndex,
                        entry.ReplacementType)
                end
            end
        end
    end
    local states = nil
    if g_HextechBuyTwoGetOne ~= nil then
        states = g_HextechBuyTwoGetOne[playerIndex]
    end
    if states == nil then
        return
    end
    for i = 1, getn(states), 1 do
        local state = states[i]
        if state ~= nil and state.UnitType ~= nil then
            local entry = mapped[state.UnitType]
            if entry ~= nil and entry.ReplacementType ~= nil then
                state.UnitType = entry.ReplacementType
                state.UnitIndex = self:LookupUnitPoolIndex(entry.ReplacementType)
                    or state.UnitIndex
                state.UnitName = self:GetReplacementTargetName(playerIndex,
                    entry.ReplacementType)
            end
        end
    end
end

function HextechRune:PickBuyTwoGetOneTarget(playerIndex, excluded, ownedReplacement)
    if g_PlayerSide == nil or g_RecycleBtnsMapByFaction == nil
        or g_UnitNameToUnitIndex == nil then
        return nil
    end
    local faction = g_PlayerSide[playerIndex]
    local factionPool = g_RecycleBtnsMapByFaction[faction]
    if factionPool == nil then
        return nil
    end
    local producible, aliasOnly = self:BuildBuyTwoGetOneTargetFilter()
    local candidates = self:CollectBuyTwoGetOneCandidates(factionPool, producible, aliasOnly,
        excluded, ownedReplacement)
    if getn(candidates) == 0 and producible ~= nil then
        -- 保证符文仍然出现在三选一里（宁可目标偏弱，也不要整张符文消失）。
        candidates = self:CollectBuyTwoGetOneCandidates(factionPool, nil, nil, excluded,
            ownedReplacement)
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

function HextechRune:BuildLockedTargetUnitTypes()
    if self.LockedTargetUnitTypes ~= nil then
        return self.LockedTargetUnitTypes
    end
    local locked = {}
    if g_PureDrawBuildableUnitPool ~= nil then
        for tier = 1, 4, 1 do
            local tierPool = g_PureDrawBuildableUnitPool[tier]
            if tierPool ~= nil then
                for i = 1, getn(tierPool), 1 do
                    local info = tierPool[i]
                    if info.LockPlayerProduction then
                        locked[info.Type] = true
                        local aliases = nil
                        if g_PureDrawProductionAliases ~= nil then
                            aliases = g_PureDrawProductionAliases[info.Type]
                        end
                        if aliases ~= nil then
                            for aliasIndex = 1, getn(aliases), 1 do
                                locked[aliases[aliasIndex]] = true
                            end
                        end
                    end
                end
            end
        end
    end
    self.LockedTargetUnitTypes = locked
    if g_PureDrawBuildableUnitPool == nil then
        -- 生产池还没加载，这次的结果不作数，留给下次重新构建。
        self.LockedTargetUnitTypes = nil
    end
    return locked
end

-- 汇总自身阵营四类回收表里“可计数 + 可生产”的单位，并按单位类型去重。
-- ownedReplacement 放行玩家已持有替换符文的那只升级形态（它不在抽卡池里）。
function HextechRune:CollectBuyTwoGetOneCandidates(factionPool, producible, aliasOnly,
    excluded, ownedReplacement)
    local locked = self:BuildLockedTargetUnitTypes()
    local seen = {}
    local candidates = {}
    for category = 1, 4, 1 do
        if BanModeRecycleCategoryEnabled(category) == 1 then
            local units = factionPool[category]
            if units ~= nil then
                for i = 1, getn(units), 1 do
                    local info = units[i]
                    local countType = info.CountType or info.Type
                    local unitIndex = g_UnitNameToUnitIndex[countType]
                    local allowed = producible == nil
                        or (producible[countType] == true and aliasOnly[countType] == nil)
                        or (ownedReplacement ~= nil and ownedReplacement[countType] == true)
                    if unitIndex ~= nil and info.CountsTowardArmyTotal ~= false
                        and allowed and locked[countType] == nil
                        and seen[countType] == nil
                        and (excluded == nil or excluded[countType] == nil) then
                        seen[countType] = true
                        tinsert(candidates, {
                            Type = countType,
                            UnitIndex = unitIndex,
                            Name = info.Name or Localization.ObjectsTranslate(countType),
                        })
                    end
                end
            end
        end
    end
    return candidates
end

-- ignoreFaction：跳过全部阵营判定。analysis/hextech_dev_test_backup.md）按原样贴回时用。
function HextechRune:IsRuneFactionAvailable(playerIndex, rune, ignoreFaction)
    if ignoreFaction then
        return true
    end
    local faction = nil
    if g_PlayerSide ~= nil then
        faction = g_PlayerSide[playerIndex]
    end
    -- 协议类符文不给「自己阵营的协议」：协议归属读 16_cryo_satellite.lua 的
    -- ProtocolGrants[rune.Effect].Faction，新增协议符文只改那张表就自动生效。
    if faction ~= nil and rune.Effect ~= nil and self.ProtocolGrants ~= nil then
        local grant = self.ProtocolGrants[rune.Effect]
        if grant ~= nil and grant.Faction == faction then
            return false
        end
    end
    if faction ~= nil and rune.ExcludedFaction ~= nil
        and faction == rune.ExcludedFaction then
        return false
    end
    if rune.RequiredFaction == nil then
        return true
    end
    return faction ~= nil and faction == rune.RequiredFaction
end

function HextechRune:CreateRuneCandidateForPlayer(playerIndex, rune, unitType,
        ignoreFaction)
    if not self:IsRuneFactionAvailable(playerIndex, rune, ignoreFaction) then
        return nil
    end
    local candidate = self:CopyRuneForCandidate(rune, unitType)
    if rune.NeedsUnitTypePair then
        -- 等价交换：候选生成这一刻一次性抽定「受益兵种 + 受损兵种」，两者必然不同；
        -- 禁海配置下 GetRuneCandidateUnitTypes 已经把海军去掉，所以禁海时只在三种兵种里抽。
        local types = self:GetRuneCandidateUnitTypes(playerIndex, rune)
        if getn(types) < 2 then
            return nil
        end
        local buffIndex = self:RandomIndex(getn(types))
        -- 受损兵种在「去掉受益兵种后的 n-1 个」里抽，保证两个兵种不会撞在一起。
        local debuffIndex = self:RandomIndex(getn(types) - 1)
        if debuffIndex >= buffIndex then
            debuffIndex = debuffIndex + 1
        end
        candidate.UnitType = types[buffIndex]
        candidate.UnitType2 = types[debuffIndex]
    end
    if candidate.Effect == "buy_two_get_one" or candidate.Effect == "ascension"
        or candidate.Effect == "ultimate_creature" then
        -- 替换型符文的双向排除：未持有的升级形态造不出来，持有的原形态不再入池。
        local excluded, ownedReplacement = self:GetReplacementTargetFilter(playerIndex)
        -- “买二送一”可重复选择，但同一个玩家的两个买二送一不能圈同一个单位；
        -- 登神不做这项排除，允许与买二送一指向同一个单位。
        if candidate.Effect == "buy_two_get_one" then
            local ownedTargets = self:GetOwnedBuyTwoGetOneTargetTypes(playerIndex)
            for targetType, owned in ownedTargets do
                excluded[targetType] = true
            end
        end
        -- 登神与究极生物额外剔掉策划裁决不圈的单位（买二送一不受影响）。
        if candidate.Effect == "ascension" or candidate.Effect == "ultimate_creature" then
            for unitType, banned in self.RuneTargetExcludedTypes do
                excluded[unitType] = true
            end
        end
        -- 究极生物的目标不走阵营回收表，改用策划表 T3/T4 的独立名单，且不分阵营
        local target
        if candidate.Effect == "ultimate_creature" then
            target = self:PickUltimateCreatureTarget(excluded)
        else
            target = self:PickBuyTwoGetOneTarget(playerIndex, excluded, ownedReplacement)
        end
        if target == nil then
            return nil
        end
        candidate.TargetUnitType = target.Type
        candidate.TargetUnitIndex = target.UnitIndex
        candidate.TargetUnitName = target.Name
    end
    return candidate
end

function HextechRune:GetRuneOwnershipId(rune)
    if rune.UnitType2 ~= nil then
        return rune.Id
    end
    if rune.UnitType ~= nil then
        return rune.Id .. ":" .. rune.UnitType
    end
    return rune.Id
end

function HextechRune:IsRuneNonRepeatable(rune)
    return rune ~= nil and self.NonRepeatableRuneIds[rune.Id] == true
end

function HextechRune:IsRuneCandidateAvailable(playerIndex, rune)
    if not self:IsRuneNonRepeatable(rune) then
        return true
    end
    return not self.PlayerOwnedRuneIds[playerIndex][self:GetRuneOwnershipId(rune)]
end

function HextechRune:IsRuneExclusiveBlocked(playerIndex, rune)
    if rune == nil or rune.ExclusiveRuneIds == nil then
        return false
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        if rune.ExclusiveRuneIds[owned[i].Id] ~= nil then
            return true
        end
    end
    return false
end

-- 元神互锁：持有者的「同步组」= 那张符文候选生成时随机定下的两个兵种。
-- 判定每次都实时查持有状态，所以先拿到的 buff 与后拿到的 buff 走同一组同步。
function HextechRune:GetInterlockUnitTypes(playerIndex)
    if playerIndex == nil then
        return nil
    end
    self:EnsurePlayerRuneState(playerIndex)
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        if rune.Effect == "soul_interlock" and rune.UnitType ~= nil
            and rune.UnitType2 ~= nil then
            local set = {}
            set[rune.UnitType] = true
            set[rune.UnitType2] = true
            return set
        end
    end
    return nil
end

-- 传一个兵种进来：它在同步组里就返回组内的另一个兵种，否则返回 nil。
function HextechRune:GetInterlockPartnerType(playerIndex, unitType)
    if unitType == nil then
        return nil
    end
    local set = self:GetInterlockUnitTypes(playerIndex)
    if set == nil or set[unitType] == nil then
        return nil
    end
    for other, owned in set do
        if other ~= unitType then
            return other
        end
    end
    return nil
end

-- 可重复符文每次选择都获得独立实例 ID，用于持续效果的单位级加载标记。
function HextechRune:GetRuneEffectInstanceId(rune)
    if rune.OwnedInstanceId ~= nil then
        return rune.OwnedInstanceId
    end
    return self:GetRuneOwnershipId(rune)
end

-- 个别符文的兵种名换个说法：AT立场的海军档按用户口径显示「舰船」。
HextechRune.UnitTypeLabelKeyOverrides = {
    at_field = { navy = "hextech.rune.at_field.ship" },
}

function HextechRune:GetRuneUnitTypeLabel(rune)
    if rune == nil or rune.UnitType == nil then
        return ""
    end
    -- 单个符文的兵种名可以换个说法（AT立场的海军档按用户口径显示「舰船」）。
    local override = self.UnitTypeLabelKeyOverrides[rune.Effect]
    if override ~= nil and override[rune.UnitType] ~= nil then
        return Localization.get(override[rune.UnitType])
    end
    return Localization.get("hextech.unit_type." .. rune.UnitType)
end

-- 等价交换的第二个兵种（受损方）；只有一个兵种槽的符文返回空串。
function HextechRune:GetRuneUnitTypeLabel2(rune)
    if rune == nil or rune.UnitType2 == nil then
        return ""
    end
    return Localization.get("hextech.unit_type." .. rune.UnitType2)
end

function HextechRune:GetRuneDisplayName(rune)
    if rune == nil then
        return ""
    end
    local name = Localization.get(rune.NameKey)
    if rune.UnitType ~= nil then
        if rune.UnitType2 ~= nil then
            -- 两个兵种一起写进后缀，悬浮详情一眼能看出谁受益、谁受损。
            name = name .. Localization.get("hextech.unit_type.suffix",
                self:GetRuneUnitTypeLabel(rune) .. "/" .. self:GetRuneUnitTypeLabel2(rune))
            return name
        end
        name = name .. Localization.get("hextech.unit_type.suffix", self:GetRuneUnitTypeLabel(rune))
    end
    return name
end

-- 动态描述：playerIndex 是“符文详情的视角玩家”。三选一卡传选择者自己（候选符文还没到手），
-- 面板详情传符文的持有者。只有需要按持有状态算数值的符文会用到它。
function HextechRune:GetRuneDescription(rune, playerIndex)
    if rune == nil then
        return ""
    end
    if rune.UnitType ~= nil then
        local label = self:GetRuneUnitTypeLabel(rune)
        -- 等价交换：一段文案里两个兵种槽，受益兵种在前、受损兵种在后。
        if rune.UnitType2 ~= nil then
            return Localization.get(rune.DescKey, label,
                self:GetRuneUnitTypeLabel2(rune))
        end
        -- 狩猎律动的敌我两侧各有一个兵种槽。
        if rune.Effect == "hunt_rhythm" then
            return Localization.get(rune.DescKey, label, label)
        end
        -- 回归基本功：加成段与削弱段各写一个兵种槽，两处填同一个兵种。
        if rune.Effect == "back_to_basics" then
            return Localization.get(rune.DescKey, label, label)
        end
        -- 以战养战的每单位百分比随对局经济倍率变化，卡面按当前档位显示 1% 或 0.5%。
        if rune.Effect == "war_efficiency" then
            return Localization.get(rune.DescKey, label,
                self:FormatWarEfficiencyPercent(self:GetWarEfficiencyBonusPerDeath() * 100))
        end
        return Localization.get(rune.DescKey, label)
    elseif rune.Effect == "buy_two_get_one" or rune.Effect == "ascension" then
        local targetName = rune.TargetUnitName or rune.TargetUnitType or "?"
        if rune.Effect == "ascension" then
            -- 登神每回收一只只随机命中一维，各档数值相同，按目标单位阶级显示。
            local percent = self:GetAscensionTierPercent(rune.TargetUnitType)
            if self:IsAmmoAircraftUnitType(rune.TargetUnitType) then
                -- 带弹药的飞机多一维「弹药」。
                return Localization.get("hextech.rune.ascension.desc_ammo", targetName,
                    percent, percent, percent, percent, percent)
            end
            return Localization.get(rune.DescKey, targetName,
                percent, percent, percent, percent)
        end
        return Localization.get(rune.DescKey, targetName)
    elseif rune.Effect == "ultimate_creature" then
        -- 简介里“进化为究极生物”与“获得一个单位”共用同一个随机目标，占位两处。
        local targetName = rune.TargetUnitName or rune.TargetUnitType or "?"
        if self:IsAmmoAircraftUnitType(rune.TargetUnitType) then
            return Localization.get("hextech.rune.ultimate_creature.desc_ammo",
                targetName, targetName)
        end
        return Localization.get(rune.DescKey, targetName, targetName)
    elseif rune.Effect == "recycler" then
        return Localization.get(rune.DescKey, floor(GetHextechRecycleBonusRate() * 100 + 0.5))
    elseif rune.Effect == "combustion_interest" then
        return Localization.get(rune.DescKey, GetCombustionInterestMoney())
    elseif rune.Effect == "starting_funds" then
        return Localization.get(rune.DescKey, GetStartingFundsMoney())
    elseif rune.Effect == "shrink_ray" then
        return Localization.get(rune.DescKey, self:GetShrinkRayDisplayRounds(playerIndex))
    elseif rune.Effect == "burn_furry" then
        -- 转化比例随本方（含队友）份数变化，卡面按拿到之后的份数显示 50/75/100。
        return Localization.get(rune.DescKey,
            self:GetBurnFurryDisplayPercent(playerIndex))
    elseif rune.Effect == "spawn_alien" then
        return Localization.get(rune.DescKey,
            self:GetConversionRuneDisplayPercent(playerIndex, self.SpawnAlienRuneId))
    elseif rune.Effect == "angler" then
        return Localization.get(rune.DescKey,
            self:GetConversionRuneDisplayPercent(playerIndex, self.AnglerRuneId))
    elseif rune.Effect == "sit_tight" then
        return Localization.get(rune.DescKey,
            self:GetConversionRuneDisplayPercent(playerIndex, self.SitTightRuneId))
    elseif rune.Effect == "divine_intervention" then
        return Localization.get(rune.DescKey,
            self:GetDivineInterventionDisplaySeconds(playerIndex))
    elseif rune.Effect == "time_rift" then
        return Localization.get(rune.DescKey,
            self:GetTimeRiftDisplaySeconds(playerIndex))
    end
    return Localization.get(rune.DescKey)
end

-- 神圣干预与时间裂隙共用：份数 → 文案里的名义秒数（1/2/3 份 = 3/4.5/6 秒）。
-- 实际帧数各自按「基础 45 帧 + 每份 23 帧」向上取整（45/68/91 帧），文案只写名义值。
function HextechRune:GetRuneBuffDurationText(copies)
    local seconds = 3 + 1.5 * (copies - 1)
    if seconds == floor(seconds) then
        return format("%d", seconds)
    end
    return format("%.1f", seconds)
end

-- 详情视角换算份数：三选一卡传选择者（候选还没到手，按拿到后 +1 份展示），
-- 面板详情传持有者（已到手，按当前份数展示）。视角缺失时退回单份口径。
function HextechRune:GetRuneDisplayCopyCount(playerIndex, runeId)
    if playerIndex == nil then
        return 1
    end
    self:EnsurePlayerRuneState(playerIndex)
    local copies = self:GetSideOwnedRuneCount(self:GetPlayerSideIndex(playerIndex),
        runeId)
    if not self.PlayerOwnedRuneIds[playerIndex][runeId] then
        copies = copies + 1
    end
    return copies
end

-- 带兵种标题拆成两行；事件卡与缩小后的总览卡都可避免标题越界。
function HextechRune:GetRuneCompactTitle(rune)
    if rune == nil then
        return ""
    end
    local name = Localization.get(rune.NameKey)
    if rune.UnitType ~= nil then
        if rune.UnitType2 ~= nil then
            -- 等价交换：「兵种1/」占一行、受损兵种另起一行，别合回一行
            -- （四个全角字会被卡面自动折行，断在兵种名中间）。
            return name .. "\n" .. self:GetRuneUnitTypeLabel(rune) .. "/\n"
                .. self:GetRuneUnitTypeLabel2(rune)
        end
        return name .. "\n" .. self:GetRuneUnitTypeLabel(rune)
    end
    if rune.Effect == "broadband_jamming" then
        return "全频段阻塞\n干扰"
    end
    -- 艾卡西亚的惊喜：七字太长，按「四字标题」排版拆成 艾卡西亚 / 的惊喜 两行。
    if rune.Effect == "grant_time_bomb" then
        return "艾卡西亚\n的惊喜"
    end
    return name
end

-- 标题字号随卡片尺寸同比缩放；较长的三档瞄准镜额外缩小。
function HextechRune:GetRuneTitleFontSize(rune, cardSize)
    local baseSize = 16
    if rune ~= nil and (rune.Effect == "range_silver" or rune.Effect == "range_gold"
        or rune.Effect == "range_prismatic") then
        baseSize = 10
    elseif rune ~= nil and rune.Effect == "broadband_jamming" then
        baseSize = 12
    elseif rune ~= nil and rune.UnitType ~= nil then
        baseSize = 14
    end
    local result = floor(baseSize * cardSize / 200)
    if result < 3 then
        result = 3
    end
    return result
end

-- 默认展开全部允许兵种；个别符文可用 UnitTypes 限制当前已经开放的版本。
-- 例如无限火力目前只开放飞机，以后只需扩展其 UnitTypes 即可增加其他兵种。
function HextechRune:GetRuneCandidateUnitTypes(playerIndex, rune)
    if rune.UnitTypes == nil then
        return self:GetAvailableUnitTypes(playerIndex)
    end
    local result = {}
    for i = 1, getn(rune.UnitTypes), 1 do
        local unitType = rune.UnitTypes[i]
        if BanModeIsTypeEnabled(unitType) == 1 then
            tinsert(result, unitType)
        end
    end
    return result
end

function HextechRune:RandomIndex(count)
    if count <= 1 then
        return 1
    end
    local index = floor(GetRandomNumber() * count) + 1
    if index < 1 then
        index = 1
    elseif index > count then
        index = count
    end
    return index
end

function HextechRune:BuildFilteredPool(playerIndex, rarity)
    self:EnsurePlayerRuneState(playerIndex)
    local filtered = {}
    for i = 1, getn(self.RunePool), 1 do
        local rune = self.RunePool[i]
        local factionAllowed = self:IsRuneFactionAvailable(playerIndex, rune)
        if rune.Rarity == rarity and factionAllowed
            and (not rune.RequiresSea or BanModeIsTypeEnabled("navy") == 1)
            -- 通用兵种约束：只对某个兵种有效的符文（含 grant_* 直接生成单位的），该兵种被禁
            -- 时就不入池 —— 赠送路径不过出兵函数，漏声明会绕过整套禁用判定（见 §4.5.1）。
            and (rune.RequiresType == nil or BanModeIsTypeEnabled(rune.RequiresType) == 1)
            -- 元神互锁要从可用兵种里随机抽两个配成同步组，凑不出两个时整张不发
            -- （禁用页最多同时禁 3 项，禁到 3 项就只剩一个兵种，这张牌等于空牌）。
            and (not rune.RequireTwoUnitTypes
                or getn(self:GetAvailableUnitTypes(playerIndex)) >= 2)
            and (not rune.ExcludeInShrinkMode or g_EnableShrinkMode ~= 1)
            -- 本场已无下一次正式事件时，这类「只对下一次起作用」的符文不发。
            and (not rune.ExcludeOnLastFormalRound or self:HasNextFormalEvent())
            -- 玩家的第一次正式选择里，这类「前期过强 / 依赖已有单位池」的符文不发（与回合数无关）。
            and (not rune.ExcludeOnFirstFormalSelection
                or not self:IsFirstFormalSelection(playerIndex))
            -- 与已持有的符文互斥时同样不发（顺手的事 × 赌怪，避免单人整局超过 5 张）。
            and not self:IsRuneExclusiveBlocked(playerIndex, rune) then
            if rune.NeedsUnitTypePair then
                -- 等价交换这一类：兵种对在候选里定死，一次事件只出 1 个候选，
                -- 不像普通兵种符文那样把每个兵种各展开一份（否则会霸占整个棱彩池）。
                local candidate = self:CreateRuneCandidateForPlayer(playerIndex, rune, nil)
                if candidate ~= nil and candidate.UnitType2 ~= nil
                    and self:IsRuneCandidateAvailable(playerIndex, candidate) then
                    tinsert(filtered, candidate)
                end
            elseif rune.NeedsUnitType then
                local availableTypes = self:GetRuneCandidateUnitTypes(playerIndex, rune)
                for typeIndex = 1, getn(availableTypes), 1 do
                    local candidate = self:CreateRuneCandidateForPlayer(playerIndex, rune,
                        availableTypes[typeIndex])
                    if self:IsRuneCandidateAvailable(playerIndex, candidate) then
                        tinsert(filtered, candidate)
                    end
                end
            else
                local candidate = self:CreateRuneCandidateForPlayer(playerIndex, rune, nil)
                if candidate ~= nil and self:IsRuneCandidateAvailable(playerIndex, candidate) then
                    tinsert(filtered, candidate)
                end
            end
        end
    end
    return filtered
end

function HextechRune:PickThreeRunes(playerIndex, rarity)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    -- 不足 3 张时按实际张数发（有几张展示几张），只有 0 张才放弃本次事件。
    if getn(pool) < 1 then
        return nil
    end
    local picked = {}
    local drawCount = getn(pool)
    if drawCount > 3 then
        drawCount = 3
    end
    for i = 1, drawCount, 1 do
        local poolIndex = self:RandomIndex(getn(pool))
        tinsert(picked, pool[poolIndex])
        tremove(pool, poolIndex)
    end
    return picked
end

-- 遭遇战电脑不操作符文选择界面，直接从自身筛选后的同阶池中等概率抽取一个。
-- 与真人三选一使用同一套阵营、禁海、兵种版本和不可重复规则。
function HextechRune:PickOneRune(playerIndex, rarity)
    local pool = self:BuildFilteredPool(playerIndex, rarity)
    if getn(pool) < 1 then
        return nil
    end
    return pool[self:RandomIndex(getn(pool))]
end

function HextechRune:AddOwnedRune(playerIndex, rune, slotIndex)
    -- 槽位展示数据：正常选择时槽位就是玩家自己；退出继承后的额外选择由调用方传 slotIndex。
    if slotIndex == nil then
        slotIndex = self.CurrentGrantSlot[playerIndex]
    end
    if slotIndex == nil then
        slotIndex = playerIndex
    end
    self:EnsurePlayerRuneState(playerIndex)
    -- 必须在写入聚合表之前初始化槽位，否则会把刚加的这一条再复制一次。
    self:EnsureRuneSlotState(slotIndex)
    local ownershipId = self:GetRuneOwnershipId(rune)
    if self:IsRuneNonRepeatable(rune)
        and self.PlayerOwnedRuneIds[playerIndex][ownershipId] then
        return false
    end
    local ownedCount = (self.PlayerOwnedRuneCounts[playerIndex][ownershipId] or 0) + 1
    self.PlayerOwnedRuneCounts[playerIndex][ownershipId] = ownedCount
    self.PlayerOwnedRuneIds[playerIndex][ownershipId] = true
    rune.OwnedInstanceId = ownershipId .. "#" .. tostring(ownedCount)
    tinsert(self.PlayerOwnedRunes[playerIndex], rune)
    tinsert(self.PlayerSlotOwnedRunes[slotIndex], rune)
    self.PlayerSlotOwnedRuneIds[slotIndex][ownershipId] = true
    return true
end

-- 退出继承：把一条符文并进继承者的“效果聚合”，槽位展示列表保持原样。
function HextechRune:TransferOwnedRuneToPlayer(playerIndex, rune)
    self:EnsurePlayerRuneState(playerIndex)
    local ownershipId = self:GetRuneOwnershipId(rune)
    local ownedCount = (self.PlayerOwnedRuneCounts[playerIndex][ownershipId] or 0) + 1
    self.PlayerOwnedRuneCounts[playerIndex][ownershipId] = ownedCount
    self.PlayerOwnedRuneIds[playerIndex][ownershipId] = true
    -- 用继承者名下的新序号，避免与继承者已有的同 ID 副本撞实例 ID 而少叠一层。
    rune.OwnedInstanceId = ownershipId .. "#" .. tostring(ownedCount)
    tinsert(self.PlayerOwnedRunes[playerIndex], rune)
end

-- 每回合「名额」：登神 / 究极生物这类「一名玩家同一回合只能有一只」的效果共用。
-- 一回合里出兵扫描会跑两趟（固定出兵 + 延迟补扫），各自的局部标记管不住跨趟重复，
-- 所以名额按玩家存在这张表里，回合号取 lvc 计数器（与播报、以战养战同一口径）。
HextechRune.RoundSlots = HextechRune.RoundSlots or {}

function HextechRune:GetBattleRoundIndex()
    return tonumber(exCounterGetByName("lvc")) or 0
end

-- 该玩家本回合的名额是否已被占用。名额上的单位已经死了就当场收回，避免新单位拿不到。
function HextechRune:IsRoundSlotTaken(playerIndex, slotName)
    local slot = self.RoundSlots[playerIndex]
    if slot == nil or slot.Name ~= slotName then
        return false
    end
    if slot.Round ~= self:GetBattleRoundIndex() then
        return false
    end
    local unit = GetObjectById(slot.ObjectId)
    if unit == nil or not ObjectIsAlive(unit) then
        self.RoundSlots[playerIndex] = nil
        return false
    end
    return true
end

function HextechRune:MarkRoundSlot(playerIndex, slotName, unit)
    if playerIndex == nil or unit == nil then
        return
    end
    self.RoundSlots[playerIndex] = {
        Name = slotName,
        Round = self:GetBattleRoundIndex(),
        ObjectId = ObjectGetId(unit)
    }
end
