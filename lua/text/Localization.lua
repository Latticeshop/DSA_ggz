Localization = Localization or {}

Localization.lang = Localization.lang or "en"
if TextTranslate then
    if strupper(TextTranslate("GUI:OK")) == "OK" then
        Localization.lang = "en"
    else
        Localization.lang = "zh"
    end
end

Localization._map_sources = {
    player_side_name = {
        zh = {
            ["Player_1"] = "恶魔",
            ["Player_2"] = "恶魔",
            ["Player_3"] = "恶魔",
            ["Player_4"] = "天使",
            ["Player_5"] = "天使",
            ["Player_6"] = "天使",
        },
        en = {
            ["Player_1"] = "Devil",
            ["Player_2"] = "Devil",
            ["Player_3"] = "Devil",
            ["Player_4"] = "Angel",
            ["Player_5"] = "Angel",
            ["Player_6"] = "Angel",
        },
    },
}

Localization._text_sources = {
    -- === 升级系统 ===
    ["upgrade.tech.airpower"] = { zh = "%s$p%dName取得空军升级!", en = "%s $p%dName received the Advanced Aeronautics upgrade!" },
    ["upgrade.tech.high_technology"] = { zh = "%s$p%dName取得高科技升级!", en = "%s $p%dName received the High Technology upgrade!" },
    ["upgrade.tech.crush_puppies"] = { zh = "%s$p%dName取得碾压升级!", en = "%s $p%dName received the Grinder Treads upgrade!" },
    ["upgrade.tech.terror_drone_eggs"] = { zh = "%s$p%dName取得蜘蛛升级!", en = "%s $p%dName received the Terror Drone Surprise upgrade!" },
    ["upgrade.tech.naval_power"] = { zh = "%s$p%dName取得海军协议!", en = "%s $p%dName received the Empire Fortified Fleet protocol!" },
    ["upgrade.tech.enhanced_kamikaze"] = { zh = "%s$p%dName取得光荣自爆!", en = "%s $p%dName received the Honorable Discharge upgrade!" },
    ["upgrade.tech.advanced_missile_packs"] = { zh = "%s$p%dName取得先进弹药匣!", en = "%s $p%dName received the Advanced Rocket Pods upgrade!" },
    ["upgrade.tech.electromagnetic_gun"] = { zh = "%s$p%dName取得电磁炮!", en = "%s $p%dName received the Celestial Piercing Thunderbolt upgrade!" },
    ["upgrade.tech.power_seal_off_now"] = { zh = "%s$p%dName获得电能纳贡，解锁蓄元鼎建造权限!", en = "%s $p%dName gained Celestial Power Tribute and unlocked Deposit Ding!" },
    ["upgrade.tech.power_seal_off_later"] = { zh = "%s$p%dName获得电能纳贡，第3回合后解锁蓄元鼎建造权限!", en = "%s $p%dName gained Celestial Power Tribute. Deposit Ding unlocks after round 3!" },
    ["upgrade.tech.production_bonus_allied"] = { zh = "%s$p%dName获得盟军自由贸易协议，取得经济提升!", en = "%s $p%dName gained Allied Free Trade and received an economic boost!" },
    ["upgrade.tech.production_bonus_japan"] = { zh = "%s$p%dName获得帝国机械化组装协议，解锁全体坦克护盾技能", en = "%s $p%dName gained Empire Robotic Assembly, unlocked Point Defense Drone for all units!" },
    ["upgrade.tech.production_bonus_soviet"] = { zh = "%s$p%dName获得苏联大生产协议，全体单位降价", en = "%s $p%dName gained Soviet Mass Production. All units are cheaper!" },
    -- 升级完成提示（有序）
    ["upgrade.Upgrade_AlliedMissileIntercept"] = { zh = "取得先进反导系统!", en = "Unlocked Advanced Missile Intercept System!" },
    ["upgrade.Upgrade_AlliedPrismTankReduceSpeed"] = { zh = "取得激光协调矩阵!", en = "Unlocked Allied Laser Upgrade!" },
    ["upgrade.Upgrade_AlliedAircraftAutoDivideBombs"] = { zh = "取得智能航电系统!", en = "Unlocked Allied Bombing Fire Control Upgrade!" },
    ["upgrade.Upgrade_AlliedAdvancedPrismEquipment"] = { zh = "取得先进稳相光学设备!", en = "Unlocked Allied Advanced Spectral Equipment!" },
    ["upgrade.Upgrade_AlliedCommandControlSystem"] = { zh = "取得战场全面信息化!", en = "Unlocked Allied Joint Space Command Control System!" },
    ["upgrade.Upgrade_AlliedAircraftCarrierDrone"] = { zh = "取得先进航空指挥系统!", en = "Unlocked Allied Advanced Air Combat Command!" },
    ["upgrade.Upgrade_SovietMissileIntercept"] = { zh = "获得防空火控雷达!", en = "Unlocked Soviet FC Radar!" },
    ["upgrade.Upgrade_SovietCompositeArmor"] = { zh = "获得外附装甲!", en = "Unlocked Soviet Composite Armour!" },
    ["upgrade.Upgrade_SovietImprovedTeslaCoil"] = { zh = "获得预充能线圈!", en = "Unlocked Improved Tesla Weapons!" },
    ["upgrade.Upgrade_SovietMultiModeGuidance"] = { zh = "获得目标识别导引头!", en = "Unlocked Soviet Multi-Mode Guidance Warhead!" },
    ["upgrade.Upgrade_JapanSubmarineAttack"] = { zh = "获得潜航发射!", en = "Unlocked Submerged Launching!" },
    ["upgrade.Upgrade_JapanMechaRush"] = { zh = "获得机甲冲击!", en = "Unlocked Mecha Rush!" },
    ["upgrade.Upgrade_JapanNanoTransmissionStructure"] = { zh = "获得高强度机械变形框架!", en = "Unlocked Enhanced Nano Frames!" },
    ["upgrade.Upgrade_JapanNanoSustainingForceField"] = { zh = "获得纳米维持力场!", en = "Unlocked Sustaining Nano Field!" },
    ["upgrade.Upgrade_CelestialSpeedUpdate"] = { zh = "获得电掣之势!", en = "Unlocked Celestial Driveshaft Enhancement!" },
    ["upgrade.Upgrade_CelestialSupplyElectricitySystem"] = { zh = "获得超导电枢!", en = "Unlocked Celestial Weapon Power System Upgrade!" },
    ["upgrade.Upgrade_CelestialAuxiliaryAimingSystem"] = { zh = "获得穿云定海!", en = "Unlocked Celestial Auxiliary Aiming System!" },
    ["upgrade.Upgrade_CelestialLodestarDevice"] = { zh = "获得移星换位!", en = "Unlocked CelestialLodestarDevice!" },
    ["upgrade.Upgrade_JapanIntelligentAmmunition"] = { zh = "获得白田火控AI!", en = "Unlocked Shirada Intelligent Ammunition!" },
    ["upgrade.Upgrade_SovietGloriousArmedForce"] = { zh = "获得光荣武装!", en = "Unlocked SovietGloriousArmedForce!" },
    ["upgrade.Upgrade_AlliedCryoWeaponArray"] = { zh = "获得冰冻武器阵列!", en = "Unlocked AlliedCryoWeaponArray!" },
    ["upgrade.Upgrade_SovietAdvancedTeslaCoil"] = { zh = "获得过载线圈!", en = "Unlocked SovietAdvancedTeslaCoil!" },

    -- === 游戏模式 ===
    ["game_mode.name.1"] = { zh = "正常模式", en = "Normal Mode" },
    ["game_mode.name.2"] = { zh = "死亡模式", en = "Death Mode" },
    ["game_mode.name.3"] = { zh = "缩小模式", en = "Shrink Mode" },
    ["game_mode.option.1.name"] = { zh = "正常模式", en = "Normal Mode" },
    ["game_mode.option.2.name"] = { zh = "死亡模式", en = "Death Mode" },
    ["game_mode.option.3.name"] = { zh = "缩小模式", en = "Shrink Mode" },
    ["game_mode.option.4.name"] = { zh = "升本模式", en = "Level-Up Mode" },
    ["game_mode.option.5.name"] = { zh = "禁止海军", en = "No Navy" },
    ["game_mode.option.6.name"] = { zh = "抽卡模式", en = "Lucky Crate" },
    ["game_mode.dialog.title"] = { zh = "请选择游戏模式", en = "Please choose a game mode" },
    ["game_mode.confirm"] = { zh = ">>确认<<", en = ">>Confirm<<" },
    ["game_mode.selected_suffix"] = { zh = "(已选择)", en = "(Selected)" },
    ["game_mode.error.invalid_button"] = { zh = "错误：玩家 %s 点击了非法按钮 %d", en = "Error: player %s clicked invalid button %d" },
    ["game_mode.host.selected"] = { zh = "房主已选择%s", en = "Host selected %s" },
    ["game_mode.host.canceled"] = { zh = "房主已取消选择%s", en = "Host canceled selection of %s" },
    ["game_mode.normal"] = { zh = "正常模式", en = "Normal Mode" },
    ["game_mode.death"] = { zh = "死亡模式", en = "Death Mode" },
    ["game_mode.shrink"] = { zh = "缩小模式", en = "Shrink Mode" },
    ["game_mode.shrink_with_effect"] = { zh = "缩小模式(启用死亡模式效果)", en = "Shrink Mode (Death Mode effect enabled)" },
    ["game_mode.level_up"] = { zh = "升本模式", en = "Level-Up Mode" },
    ["game_mode.no_navy_suffix"] = { zh = " (禁止海军)", en = " (No Navy)" },
    ["game_mode.lucky_crate_suffix"] = { zh = " 已启用抽卡模式", en = " Lucky Crate Enabled" },

    -- === 技能系统 ===
    ["skill.name.1"] = { zh = "炸弹+达摩克利斯之剑", en = "Bomb＆DamoclesSword" },
    ["skill.name.2"] = { zh = "铁幕+时停", en = "IronCurtain＆TimeStop" },
    ["skill.name.3"] = { zh = "龙船+空军元帅", en = "DragonShip＆AirMarshal" },
    ["skill.name.4"] = { zh = "补充军队+纳米维修", en = "ReinforceArmy＆Repair" },
    ["skill.name.5"] = { zh = "复制己方技能+复制敌方技能", en = "Copy Other Players Skills" },
    ["skill_mode.dialog.title"] = { zh = "请选择技能组模式", en = "Please choose a skill group mode" },
    ["skill_mode.choose_yourself"] = { zh = "让每个玩家自行选择", en = "Let players chooose" },
    ["skill_mode.host_symmetric"] = { zh = "房主规定技能组(对称)", en = "Host-defined" },
    ["skill_mode.random_symmetric"] = { zh = "随机（可重复，对称）", en = "Random symmetric" },
    ["skill_mode.random_asymmetric"] = { zh = "随机（可重复，不对称）", en = "Random asymmetric" },
    ["skill_mode.selected_suffix"] = { zh = "(已选)", en = "(Selected)" },
    ["skill_mode.cancel"] = { zh = "取消选择", en = "Cancel selection" },
    ["skill_mode.continue"] = { zh = "请继续选择（还剩%d个）", en = "Please continue choosing (%d remaining)" },
    ["skill_mode.invalid_button"] = { zh = "错误：玩家 %s 点击了非法技能组按钮 %d", en = "Error: player %s clicked an invalid skill-group button %d" },
    ["skill_mode.all.title"] = { zh = "请选择各个玩家的技能组", en = "Please choose the skill set for each player" },
    ["skill_mode.player_choose.title"] = { zh = "请选择您的技能组", en = "Please choose your skill set" },
    ["skill_mode.player_choose.exit"] = { zh = "退出(待会再选)", en = "Exit (choose later)" },
    ["skill_mode.player_choose.invalid_player_name"] = { zh = "错误：BtnChoiceDialogEventFunc_ShowPlayerChooseSkillDialog 的参数 playerName 无效", en = "Error: invalid playerName parameter in BtnChoiceDialogEventFunc_ShowPlayerChooseSkillDialog" },
    ["skill_mode.player_choose.invalid_tech_player_name"] = { zh = "错误：BtnChoiceDialogEventFunc_ShowPurchaseTechDialog 的参数 playerName 无效", en = "Error: invalid playerName parameter in BtnChoiceDialogEventFunc_ShowPurchaseTechDialog" },
    ["skill_mode.error.preselected_count"] = { zh = "错误：预选技能组数量不正确，应该是 0 或 6，但实际是 %d", en = "Error: invalid preselected skill group count; expected 0 or 6, got %d" },
    ["skill_mode.purchase.tech.title"] = { zh = "购买下一级科技权限($%d)", en = "Buy next tech permission ($%d)" },
    ["skill_mode.purchase.tech.failed"] = { zh = "购买失败，资金不足", en = "Purchase failed: insufficient funds" },
    ["skill_mode.purchase.tech.success"] = { zh = "购买成功，解锁下一级科技等级和更多电厂", en = "Purchase successful: next tech tier and more power plants unlocked" },
    ["skill_mode.purchase.tech.description"] = { zh = "购买下一级科技(当前等级：%d)\n解锁下一级科技等级和更多电厂权限", en = "Buy next tech level (current: %d)\nUnlock next tech tier and more power plant rights" },
    ["skill_mode.purchase.tech.choice.buy"] = { zh = "购买", en = "Buy" },
    ["skill_mode.purchase.tech.choice.no_buy"] = { zh = "不购买", en = "Do not buy" },
    ["recycle.dialog.title"] = { zh = "回收%s", en = "Recycle %s" },

    -- === 交易市场 ===
    ["market.role.1"] = { zh = "恶魔1号", en = "Devil 1" },
    ["market.role.2"] = { zh = "恶魔2号", en = "Devil 2" },
    ["market.role.3"] = { zh = "恶魔3号", en = "Devil 3" },
    ["market.role.4"] = { zh = "天使1号", en = "Angel 1" },
    ["market.role.5"] = { zh = "天使2号", en = "Angel 2" },
    ["market.role.6"] = { zh = "天使3号", en = "Angel 3" },
    ["market.title"] = { zh = "欢迎进入交易市场", en = "Welcome to the Market" },
    ["market.title_with_investment"] = { zh = "欢迎进入交易市场\n投资金额(上限%d):%d", en = "Welcome to the Market\nInvestment amount (cap %d): %d" },
    ["market.next_investment.devil"] = { zh = "购买100恶魔投资", en = "Buy 100 Devil Investment" },
    ["market.next_investment.angel"] = { zh = "购买100天使投资", en = "Buy 100 Angel Investment" },
    ["market.next_investment.benefit"] = { zh = "\n若回合胜利可获收益", en = "" }, -- 英文写不下就不写了
    ["market.transfer.choice"] = { zh = "向%s%s转移1000资金", en = "1000＄ to %s%s" },
    ["market.back_to_battle"] = { zh = "回到战场", en = "Back to Battle" },
    ["market.buy_shield_tower"] = { zh = "购买护盾塔(%d)", en = "Buy Shield Tower %d＄" },
    ["market.buy_poplar_tower"] = { zh = "购买胡杨塔(%d)", en = "Buy AA Tower %d＄" },
    ["market.transfer.success"] = { zh = "成功转账1000给$p%dName", en = "Successfully transferred 1000＄ to $p%dName" },
    ["market.transfer.insufficient"] = { zh = "您的余额不足", en = "Your balance is insufficient" },
    ["market.invest.failed.max"] = { zh = "投资失败：投资已达到上限", en = "Investment failed: the investment cap has been reached" },
    ["market.invest.failed.start_only"] = { zh = "投资失败：只能在每个回合刚开始时投资", en = "Investment failed: you can only invest at the start of each round" },
    ["market.invest.failed.insufficient"] = { zh = "投资失败：余额不足", en = "Investment failed: insufficient balance" },
    ["market.invest.success"] = { zh = "投资成功，当前投资金额：%d", en = "Investment successful. Current investment amount: %d" },
    ["market.loan.message"] = { zh = "$p%dName向银行贷款", en = "$p%dName took a bank loan" },
    ["market.loan.success"] = { zh = "贷款成功", en = "Loan successful" },
    ["market.tower.already_exists"] = { zh = "塔还在，不能重复购买", en = "The tower is still alive, you cannot buy another one" },
    ["market.funds.insufficient"] = { zh = "资金不足", en = "Insufficient funds" },

    -- === 游戏开局 ===
    ["game.start.begin"] = { zh = "游戏开始！已选择游戏模式：%s", en = "Game starting! Selected game mode: %s" },
    ["game.start.economic_multiplier"] = { zh = "经济倍率: %.2f", en = "Economic multiplier: %.2f" },
    ["game.start.skill_prefix"] = { zh = "技能组：", en = "Skill set: " },
    ["game.start.skill_free_choice"] = { zh = "技能组：由玩家自由选择", en = "Skill set: chosen freely by players" },
    ["game.start.skill_random_symmetric"] = { zh = "技能组：随机（可重复，对称）", en = "Skill set: random (repeatable, symmetric)" },
    ["game.start.skill_random_asymmetric"] = { zh = "技能组：随机（可重复，不对称）", en = "Skill set: random (repeatable, asymmetric)" },

    -- === 按钮文案 ===
    ["button.choose_skill.title"] = { zh = "请选择你的技能组", en = "Choose your skill set" },
    ["button.choose_skill.description"] = { zh = "选择后可获得两个强力技能，请尽快选择", en = "You will gain two powerful skills after choosing. Please choose soon." },
    ["button.market.title"] = { zh = "交易市场", en = "Trading Market" },
    ["button.market.description"] = { zh = "购买理财项目或者定向转移资金", en = "Buy investment (earn money if round win), buy towers or transfer funds to a teammate" },
    ["button.surrender.title"] = { zh = "投降", en = "Surrender" },
    ["button.surrender.description"] = { zh = "召开一次严肃的会议试图结束游戏", en = "Hold a serious meeting in an attempt to end the game" },
    ["button.destruction.title"] = { zh = "局部毁灭武器", en = "Localized Destruction Weapon" },
    ["button.destruction.description"] = { zh = "摧毁战场中央区域（己方与敌方的防御塔之间）的所有敌方单位，无视铁幕效果", en = "Destroy all enemy units in the central battlefield area (between your and the enemy's defensive towers), ignoring Iron Curtain effects" },
    ["button.damocles.title"] = { zh = "达摩克利斯之剑", en = "Damocles Sword" },
    ["button.damocles.description"] = { zh = "请求太空的卫星对敌方随机单位启用12秒的精准卫星打击", en = "Request a satellite strike from space against random enemy units for 12 seconds" },
    ["button.iron_curtain.title"] = { zh = "铁幕演说", en = "Iron Curtain Speech" },
    ["button.iron_curtain.description"] = { zh = "发表铁幕演说,让全体单位套上坚不可摧的铁幕，持续15秒", en = "Give an Iron Curtain speech and place an indestructible Iron Curtain on all units for 15 seconds" },
    ["button.time_stop.title"] = { zh = "时空管理局", en = "Time Control Bureau" },
    ["button.time_stop.description"] = { zh = "借助未来科技的力量时停对方单位13秒", en = "Use FutureTech power to time-stop enemy units for 13 seconds" },
    ["button.dragonship.title"] = { zh = "龙行天下", en = "Dragon Ship Ascends" },
    ["button.dragonship.description"] = { zh = "召唤龙船(第5回合起可以使用)", en = "Summon a Dragon Ship (available starting from round 5)" },
    ["button.dragonship.unlocked_description"] = { zh = "召唤龙船于主巨炮位置\n第一次召唤1艘，第二次召唤2艘\n龙船出现得越迟，血量越高，第18回合后血量抵达上限\n冷却时间1回合", en = "Summon Dragon Ships at the main cannon position\nFirst summon: 1 ship, second summon: 2 ships\nThe later the ship appears, the higher its health. Health caps after round 18\nCooldown: 1 round" },
    ["button.air_marshal.title"] = { zh = "空军元帅", en = "Air Marshal" },
    ["button.air_marshal.description"] = { zh = "请求超级苏霍伊群抵达战场对敌方的空军造成毁灭性的攻击\n【仅对空、不可攻击敌方空军元帅】", en = "Request a super Sukhoi squad to reach the battlefield and deal devastating damage to enemy air units\n[Air only; cannot attack the enemy Air Marshal]" },
    ["button.skill_selected"] = { zh = "$p%dName选择了%s", en = "$p%dName selected %s" },

    -- CenterTop specific
    ["center_top.copy_our_skill.title"] = { zh = "复制己方技能", en = "Copy Friendly Skill" },
    ["center_top.copy_our_skill.description"] = { zh = "复制己方最近一次使用的技能（如果最近一次是复制技能，则一直回溯到最近一次非复制的技能），如果没有找到合适的技能，则不释放(冷却30s)", en = "Copy your last used friendly skill (cooldown 30s)" },
    ["center_top.copy_enemy_skill.title"] = { zh = "复制敌方技能", en = "Copy Enemy Skill" },
    ["center_top.copy_enemy_skill.description"] = { zh = "复制敌方最近一次使用的技能（如果最近一次是复制技能，则一直回溯到最近一次非复制的技能），如果没有找到合适的技能，则不释放(冷却30s)", en = "Copy the last enemy-used skill (cooldown 30s)" },
    ["center_top.nano_repair.title"] = { zh = "纳米维修", en = "Nano Repair" },
    ["center_top.nano_repair.description"] = { zh = "在陆地前线防御塔周围生成1个纳米维修立场和4个大型维修天灯，治愈己方部队和前线防御塔\n【仅可支援陆地】", en = "Spawn repair field around frontline towers (land only)" },
    ["center_top.reinforce_army.title"] = { zh = "补充军队", en = "Reinforce Army" },
    ["center_top.reinforce_army.description"] = { zh = "立即触发一次生成陆地和空中部队(冷却70秒)", en = "Trigger immediate spawn of land and air units (70s cooldown)" },
    ["center_top.temporal_raid.title"] = { zh = "超时空突袭", en = "ChronoSphere Raid" },
    ["center_top.temporal_raid.description"] = { zh = "请建造盟军小超武「超时空传送仪」以解锁此按钮", en = "Build the Allied Chronosphere to unlock this button" },
    ["center_top.morale_boost.title"] = { zh = "士气提升", en = "Morale Boost" },
    ["center_top.morale_boost.description"] = { zh = "请获得止戈立场以解锁此按钮", en = "Obtain Array of Sundial (Armistice Field) to unlock this button" },
    ["center_top.error.dragonship_invalid_number"] = { zh = "错误：龙船召唤失败，数量必须为1或2", en = "Error: Dragonship summon failed, count must be 1 or 2" },
    ["center_top.error.dragonship_round_insufficient"] = { zh = "龙船召唤失败，回合数不足！", en = "Dragonship summon failed: insufficient rounds" },
    ["center_top.dragonship.hp_change"] = { zh = "龙船#%d 血量%d->%d", en = "Dragonship#%d HP %d->%d" },
    ["center_top.error.no_skill_to_copy"] = { zh = "未释放过技能，无法复制技能", en = "No skill released, cannot copy" },
    ["center_top.error.no_suitable_skill"] = { zh = "未找到合适的技能，无法复制技能", en = "No suitable skill found, cannot copy" },

    ["center_top.used.copy_our_skill"] = { zh = "%s方使用了复制己方技能！", en = "%s used Copy Friendly Skill!" },
    ["center_top.used.copy_enemy_skill"] = { zh = "%s方使用了复制敌方技能！", en = "%s used Copy Enemy Skill!" },
    ["center_top.used.reinforce_army"] = { zh = "%s方使用了补充军队！", en = "%s used Reinforce Army!" },
    ["center_top.used.nano_repair"] = { zh = "%s方启动了纳米维修！", en = "%s started Nano Repair!" },
    ["center_top.used.temporal_raid"] = { zh = "%s方使用了超时空突袭！", en = "%s used ChronoSphere Raid!" },
    ["center_top.kill_reward.title"] = { zh = "杀敌奖励", en = "Kill Reward" },
    ["center_top.kill_reward.description"] = { zh = "为所有敌方陆地单位（不包括空军）套上钱套子(持续30秒)，击杀后使用技能者获得金钱(冷却40秒)", en = "Apply cash bounty to all enemy land units (30s); killing grants money (40s cooldown)" },
    ["center_top.temporal_raid.unlocked_description"] = { zh = "打开时空裂缝让主战坦克突袭敌方后排并获得短暂的铁幕\n冷却时间三回合", en = "Open a temporal rift to raid enemy backline with tanks; 3-round cooldown" },
    ["center_top.japan_shield.title"] = { zh = "全体护盾", en = "All Point Defense Drones" },
    ["center_top.japan_shield.description"] = { zh = "请激活帝国最高机密协议「机械化组装」以解锁此按钮", en = "Requiers Robotic Assembly protocol to unlock" },
    ["center_top.japan_shield.unlocked_description"] = { zh = "为所有己方载具套上纳米护盾\n冷却时间200秒", en = "Apply Point Defense Drones to all friendly vehicles; 200s cooldown" },
    ["center_top.morale_boost.unlocked_description"] = { zh = "己方全体单位获得18秒的1.25倍移速和伤害加成\n冷却时间220秒", en = "All friendly units gain 1.25x speed and damage for 18s; 220s cooldown" },
    ["center_top.used.damocles_struck"] = { zh = "%s方落下了达摩克利斯之剑！", en = "%s's Damocles Sword struck!" },
    ["center_top.used.iron_curtain_speech"] = { zh = "%s方发表了铁幕演说！", en = "%s gave an Iron Curtain speech!" },
    ["center_top.used.time_stop"] = { zh = "%s方竟然让时间停止！", en = "%s actually stopped time!" },
    ["center_top.used.dragon_core_called"] = { zh = "%s方召唤了青龙核心战斗舰！", en = "%s summoned DragonShip!" },
    ["center_top.used.air_marshal"] = { zh = "%s方请求了空军元帅！", en = "%s requested Air Marshal!" },
    ["center_top.error.enemy_no_skill_to_copy"] = { zh = "敌方未释放过技能，无法复制技能", en = "Enemy hasn't released skills, cannot copy" },
    ["center_top.error.player_not_built_chronosphere"] = { zh = "错误：玩家 %d 尚未建造超时空。", en = "Error: player %d hasn't built Chronosphere." },
    ["center_top.error.player_not_emp_mech_protocol"] = { zh = "错误：玩家 %d 尚未获得帝国机械化组装协议。", en = "Error: player %d hasn't obtained Empire mech protocol." },
    ["center_top.error.player_not_obtained_morale"] = { zh = "错误：玩家 %d 尚未获得止戈立场。", en = "Error: player %d hasn't obtained Array of Sundial." },
    ["center_top.error.no_tank_found"] = { zh = "错误：没有找到任何坦克单位，无法施加纳米护盾。", en = "Error: no tank units found, cannot apply nano shield." },
    ["center_top.error.no_land_unit_found"] = { zh = "错误：没有找到任何陆地单位，无法释放杀敌奖励", en = "Error: no land units found, cannot cash bounty" },
    ["center_top.error.no_unit_found"] = { zh = "错误：没有找到任何单位，无法施加士气提升。", en = "Error: no units found, cannot apply morale boost" },
    ["center_top.used.local_destruction"] = { zh = "%s方使用了局部杀伤性武器！", en = "%s used Local Destruction Weapon!" },
    ["center_top.used.bribe"] = { zh = "%s方使用了策反！", en = "%s used Bribe!" },
    ["center_top.used.emp_nano_shield"] = { zh = "%s $p%dName使用了由帝国机械化组装协议提供的纳米护盾！", en = "%s $p%dName used Empire Nano Shield from Robotic Assembly!" },
    ["center_top.used.kill_reward"] = { zh = "%s方使用了杀敌奖励！", en = "%s used Kill Reward!" },
    ["center_top.used.global_morale"] = { zh = "%s $p%dName使用了由止戈立场提供的全图士气提升技能！", en = "%s $p%dName used Global Morale Boost from Array of Sundial!" },

    -- Button manager messages
    ["button_manager.error.incomplete_data"] = { zh = "错误：按钮数据不完整，无法设置按钮", en = "Error: button data incomplete, cannot set button" },
    ["button_manager.error.no_playerindex"] = { zh = "错误：按钮 %s 没有定义 PlayerIndex", en = "Error: button %s has no PlayerIndex" },
    ["button_manager.error.no_click_event"] = { zh = "%s 点击了按钮 %d，但该按钮没有定义点击事件", en = "%s clicked button %d, but no click handler defined" },
    ["button_manager.error.no_sharedcooldown_id"] = { zh = "玩家 %s 的按钮 %s 没有定义共享冷却 ID 却试图触发共享冷却事件", en = "Player %s's button %s has no shared cooldown ID but attempted to trigger shared cooldown" },
    ["button_manager.error.no_sharedcooldown_handler"] = { zh = "玩家 %s 的按钮 %s 没有定义共享冷却事件", en = "Player %s's button %s has no shared cooldown handler" },
    ["button_manager.error.overwritten_cannot_restore"] = { zh = "玩家 %s 的按钮 %s 已经被其他按钮覆盖，无法恢复", en = "Player %s's button %s has been overwritten and cannot be restored" },
    ["button_manager.text.not_initialized"] = { zh = "<尚未初始化完毕>%s\n%s", en = "<Not initialized>%s\n%s" },
    ["button.default.title"] = { zh = "没有名字", en = "No Name" },
    ["button.default.description"] = { zh = "没有描述", en = "No Description" },
    ["button.default.unknown"] = { zh = "未知按钮", en = "Unknown button" },
    ["button.suffix.used"] = { zh = "(已使用)", en = "(Used)" },
    ["button.suffix.cooldown"] = { zh = "(冷却中)", en = "(Cooling)" },
    ["button.suffix.single_use"] = { zh = "(仅限一次)", en = "(Single Use)" },
    ["button.suffix.use_count"] = { zh = "(可使用%d次)", en = "(Usable %d times)" },

    -- Extra command notices
    ["extra_command.ban_sea"] = { zh = "房主已禁止海军！", en = "Host has banned navy!" },
    ["extra_command.ban_infantry"] = { zh = "房主已禁止兵营！", en = "Host has banned barracks!" },
    ["extra_command.dialog.title"] = { zh = "额外设定", en = "Extra Settings" },
    ["extra_command.choice.ban_sea"] = { zh = "禁海军", en = "Ban Navy" },
    ["extra_command.choice.ban_infantry"] = { zh = "禁兵营", en = "Ban Barracks" },

    -- Round cleanup notices
    ["env_kill_all_unit.warning_next_round"] = { zh = "下一回合开始将会清除场上双方单位，请做好准备", en = "Units from both sides will be cleared at the start of next round. Please prepare." },
    ["env_kill_all_unit.execute"] = { zh = "清除场上双方单位", en = "Clear units from both sides" },
    ["celestial_centurion.unlock"] = { zh = "$p%dName解锁千夫长/万夫长!", en = "$p%dName unlocked Centurion promotion to Chiliarch!" },

    -- Unit button events
    ["unit_button.angel.dragonship_called"] = { zh = "天使方召唤了龙船！", en = "Angel summoned Dragonship!" },
    ["unit_button.angel.used_bomb"] = { zh = "天使方使用了炸弹！", en = "Angel used Bomb!" },
    ["unit_button.angel.used_iron_curtain"] = { zh = "天使方使用了铁幕！", en = "Angel used Iron Curtain!" },
    ["unit_button.devil.dragonship_called"] = { zh = "恶魔方召唤了龙船！", en = "Devil summoned Dragonship!" },
    ["unit_button.devil.used_bomb"] = { zh = "恶魔方使用了炸弹！", en = "Devil used Bomb!" },
    ["unit_button.devil.used_iron_curtain"] = { zh = "恶魔方使用了铁幕！", en = "Devil used Iron Curtain!" },

    -- Round outcome messages
    ["round.devil_win"] = { zh = "恶魔方本回合胜!", en = "Devils won this round!" },
    ["round.devil_end_streak"] = { zh = "恶魔方终结连胜!", en = "Devils ended a winning streak!" },
    ["round.devil_on_streak"] = { zh = "恶魔方正在连胜!", en = "Devils are on a winning streak!" },
    ["round.angel_win"] = { zh = "天使方本回合胜!", en = "Angels won this round!" },
    ["round.angel_on_streak"] = { zh = "天使方正在连胜!", en = "Angels are on a winning streak!" },
    ["round.angel_end_streak"] = { zh = "天使方终结连胜!", en = "Angels ended a winning streak!" },
    ["round.no_winner"] = { zh = "本回合暂无胜者", en = "No winner this round" },
    ["mirrortower.unlock_t4_ship.devil"] = { zh = "恶魔方摧毁敌方海3塔，立即释放一次达摩克利斯之剑(不消耗释放次数)!", en = "Devils destroyed the enemy sea tower 3 and immediately triggered free Damocles Sword!" },
    ["mirrortower.unlock_t4_ship.angel"] = { zh = "天使方摧毁敌方海3塔，立即释放一次达摩克利斯之剑(不消耗释放次数)!", en = "Angels destroyed the enemy sea tower 3 and immediately triggered free Damocles Sword!" },
    ["unit_die.money_gained"] = { zh = "获得$%s", en = "Gained $%s" },

    -- === 投降系统 ===
    ["side.devil"] = { zh = "恶魔", en = "Devil" },
    ["side.angel"] = { zh = "天使", en = "Angel" },
    ["surrender.vote_text"] = { zh = "                                                          正在投票\n规则:投降大于战斗则为成功投降,票数相等会继续游戏\n全局每个人只能发动一次投降", en = "                                                          Voting in progress\nRule: surrender beats fight for a successful surrender; tied votes continue the game\nEach player can initiate surrender only once globally" },
    ["surrender.choice.surrender"] = { zh = "投降", en = "Surrender" },
    ["surrender.choice.pass"] = { zh = "弃权", en = "Pass" },
    ["surrender.choice.fight"] = { zh = "战斗", en = "Fight" },
    ["surrender.public.start"] = { zh = "%s$p%dName发起了投降", en = "%s $p%dName initiated surrender" },
    ["surrender.public.auto"] = { zh = "%s$p%dName选择投降", en = "%s $p%dName chose surrender" },

    -- === 颜色 ===
    ["color.black"] = { zh = "黑色", en = "Black" },
    ["color.white"] = { zh = "白色", en = "White" },
    ["color.gray"] = { zh = "灰色", en = "Gray" },
    ["color.red"] = { zh = "红色", en = "Red" },
    ["color.orange"] = { zh = "橙色", en = "Orange" },
    ["color.yellow"] = { zh = "黄色", en = "Yellow" },
    ["color.green"] = { zh = "绿色", en = "Green" },
    ["color.cyan"] = { zh = "青色", en = "Cyan" },
    ["color.blue"] = { zh = "蓝色", en = "Blue" },
    ["color.purple"] = { zh = "紫色", en = "Purple" },
    ["color.pink"] = { zh = "粉色", en = "Pink" },

    -- === 轮次提示 ===
    ["round.begin"] = { zh = "第%d回合，开始！", en = "Round %d, begin!" },
    ["round.angel_formation"] = { zh = "战场右侧：天使$p4Name $p5Name $p6Name", en = "Right side of battlefield: Angels $p4Name $p5Name $p6Name" },
    ["round.devil_formation"] = { zh = "战场左侧：恶魔$p1Name $p2Name $p3Name", en = "Left side of battlefield: Devils $p1Name $p2Name $p3Name" },

    -- === 回收系统 ===
    ["recycle.choice.1"] = { zh = "回收1个", en = "Recycle 1" },
    ["recycle.choice.5"] = { zh = "回收5个", en = "Recycle 5" },
    ["recycle.choice.10"] = { zh = "回收10个", en = "Recycle 10" },
    ["recycle.choice.20"] = { zh = "回收20个", en = "Recycle 20" },
    ["recycle.choice.cancel"] = { zh = "取消", en = "Cancel" },
    ["recycle.message"] = { zh = "$p%dName回收了%d个%s，剩余%d个", en = "$p%dName recycled %d %s, %d remaining" },

    -- 回收按钮描述文字
    ["recycle.desc.infantry"] = { zh = "回收步兵单位", en = "Recycle infantry units" },
    ["recycle.desc.vehicle"] = { zh = "回收坦克单位", en = "Recycle vehicle units" },
    ["recycle.desc.air"] = { zh = "回收空军单位", en = "Recycle air units" },
    ["recycle.desc.navy"] = { zh = "回收海军单位", en = "Recycle navy units" },
    ["recycle.desc.collapse"] = { zh = "收起下方按钮", en = "Collapse lower buttons" },

    -- === 投降反馈 ===
    ["surrender.devil.choose"] = { zh = "恶魔$p%dName选择投降", en = "Devil $p%dName chose surrender" },
    ["surrender.devil.fight"] = { zh = "恶魔$p%dName选择战斗", en = "Devil $p%dName chose to fight" },
    ["surrender.devil.pass"] = { zh = "恶魔$p%dName选择弃权", en = "Devil $p%dName chose to pass" },
    ["surrender.angel.choose"] = { zh = "天使$p%dName选择投降", en = "Angel $p%dName chose surrender" },
    ["surrender.angel.fight"] = { zh = "天使$p%dName选择战斗", en = "Angel $p%dName chose to fight" },
    ["surrender.angel.pass"] = { zh = "天使$p%dName选择弃权", en = "Angel $p%dName chose to pass" },

    -- === 升本模式 ===
    ["purchase_tech.button"] = { zh = "购买下一级科技(当前等级：1)\n解锁下一级科技等级和更多电厂权限", en = "Buy next tech level (current: 1)\nUnlock next tech tier and more power plant rights" },
    ["purchase_tech.level"] = { zh = "己方科技等级: %d", en = "Our tech level: %d" },
    ["purchase_tech.power_plants"] = { zh = "己方电厂最大数量: %d", en = "Max power plants: %d" },
    ["purchase_tech.celestial_plants"] = { zh = "己方神州电厂最大数量: %d", en = "Max Celestial power plants: %d" },

    -- === 记分牌 ===
    ["board.title.troop_count"] = { zh = "部队数量", en = "Unit Count" },
    ["board.title.current_round"] = { zh = "当前回合:", en = "Round:" },
    ["board.role.devil1"] = { zh = "恶魔1号", en = "Devil 1" },
    ["board.role.devil2"] = { zh = "恶魔2号", en = "Devil 2" },
    ["board.role.devil3"] = { zh = "恶魔3号", en = "Devil 3" },
    ["board.role.angel1"] = { zh = "天使1号", en = "Angel 1" },
    ["board.role.angel2"] = { zh = "天使2号", en = "Angel 2" },
    ["board.role.angel3"] = { zh = "天使3号", en = "Angel 3" },

    -- === 按钮对话框管理器 ===
    ["button_dialog.player_not_found"] = { zh = "玩家 %s 点击了按钮 %d，但没有找到对应的对话框 ID: %d", en = "Player %s clicked button %d, but no matching dialog ID was found: %d" },
    ["button_dialog.player_mismatch"] = { zh = "对话框 %d 的按钮 %d 被点击，但玩家名称不匹配: %s != %s", en = "Dialog %d button %d was clicked, but the player name does not match: %s != %s" },
    ["button_dialog.no_choice_handler"] = { zh = "玩家 %s 点击了按钮 %d，但该对话框没有定义按钮事件处理函数", en = "Player %s clicked button %d, but this dialog has no button event handler" },
    ["button_dialog.invalid_dialog"] = { zh = "错误：尝试添加一个无效的按钮选择对话框", en = "Error: attempted to add an invalid button choice dialog" },
    ["button_dialog.invalid_dialog_id"] = { zh = "错误：尝试创建一个无效的按钮选择对话框，DialogId 必须是数字", en = "Error: attempted to create an invalid button choice dialog; DialogId must be a number" },
    ["button_dialog.invalid_player_name"] = { zh = "错误：尝试创建一个无效的按钮选择对话框，PlayerName 必须是字符串", en = "Error: attempted to create an invalid button choice dialog; PlayerName must be a string" },
    ["button_dialog.not_enough_choices"] = { zh = "错误：尝试显示对话框 %d 时，选项数量不足。至少需要一个选项！", en = "Error: when displaying dialog %d, there are not enough choices. At least one choice is required!" },
    ["button_dialog.too_many_choices"] = { zh = "错误：尝试显示对话框 %d 时，选项数量超过了预设的最大值。在加入更多选项之前应该先实现分页功能！", en = "Error: when displaying dialog %d, the number of choices exceeds the preset maximum. Implement pagination before adding more choices!" },

    -- === 错误信息 ===
    ["error.invalid_kind"] = { zh = "错误：CenterTopBtnFunc_CreatePlayerSkillButtons 的 kind 参数无效", en = "Error: invalid kind parameter in CenterTopBtnFunc_CreatePlayerSkillButtons" },
    ["error.crate_in_battlefield"] = { zh = "禁止把抽卡箱子放在中央战场，作为惩罚，箱子会被随机分配！", en = "Placing a crate in the central battlefield is prohibited. As a penalty, the crate will be randomly distributed!" },

    -- === 游戏规则与更新日志 ===
    ["dialog.choose_mode.waiting"] = { zh = "等待房主选择游戏模式", en = "Waiting for host to choose game mode" },
    ["dialog.read_done"] = { zh = "清楚!", en = "Got it!" },
    ["dialog.update_log"] = { zh = "更新日志", en = "Update Log" },
    ["dialog.previous_page"] = { zh = "上一页", en = "Previous" },
    ["dialog.next_page"] = { zh = "下一页", en = "Next" },
    ["dialog.read_completed"] = { zh = "$p%dName已阅读完成", en = "$p%dName has finished reading" },
    ["ai.infantry_built"] = { zh = "AI步兵建造完毕", en = "AI infantry build complete" },
    ["game.rules"] = { 
        zh = [[自走棋游戏规则简介：
本地图为格格子协助开发的测试版本，具有很多实验性内容和不稳定因素，测试通过的内容会更新并合并到正式版本DSA_XXX%%COR_mix地图中
1. 玩家造出的单位会被记录，每个回合开始时，战场上都会重新刷出玩家造过的所有单位，由电脑控制
2. 上方玩家（天使）单位出现在战场右侧，下方玩家（恶魔）单位出现在战场左侧
3. 电厂提供收入，请尽快造满电厂以避免卡钱；苏联超级反应堆和神州导流尖塔不提供收入（仅解锁科技）；建造T4高科附赠精兵学院
正常模式：前期收入有限，请摧毁敌方防御塔来解锁更多的电厂和科技
死亡模式：双方开局就只剩最后一座塔
抽卡模式：可以使用抽卡技能获得额外单位。禁止在战场中央抽卡！
可点击下方"更新日志"按钮查看更新内容]],
        en = [[DSA Game Rules:
1. Units you build are recorded. At the start of each round, all units you've built are respawned on the battlefield under AI control.
2. Upper-side players (Angel) units appear on the right side of the battlefield. Lower-side players (Devil) units appear on the left side.
3. Power plants provide income. Build power plants ASAP to avoid running out of money. Soviet Super Reactors and Celestial Diversion Spire do not provide income (tech unlock only). Building T4 high-tech grants a free Veteran Academy.
Normal Mode: Limited income in early stages. Destroy enemy defense towers to unlock more power plants and technology.
Death Mode: Both sides start with only the last tower remaining.
Lucky Crate Mode: Use the Lucky Crate Boxes to gain extra units. Do not use Lucky Crate in the central battlefield!
Click the "Update Log" button below to view update details.]]
    },
    ["game.qq_group"] = { 
        zh = "自走棋交流/反馈QQ群: 219951578\n", 
        en = "DSA Discussion/Feedback QQ Group: 219951578\n" 
    },
}

function Localization_copy_value(value)
    if type(value) ~= "table" then
        return value
    end
    local copied = {}
    for key, item in value do
        copied[key] = Localization_copy_value(item)
    end
    return copied
end

Localization.set_language = function(language)
    if language ~= "zh" and language ~= "en" then
        return false
    end
    Localization.lang = language
    local callbacks = Localization._language_changed_callbacks
    if callbacks then
        for i = 1, getn(callbacks), 1 do
            local c = callbacks[i]
            call(c.f, { c.data }, "x")
        end
    end
    return true
end

Localization.get = function(...)
    local key = arg[1]
    local source = Localization._text_sources[key]
    if not source then
        _ALERT("Localization: missing key " .. key)
        return key
    end
    local template = source[Localization.lang] or source.zh or source.en or key
    if getn(arg) > 0 then
        arg[1] = template
        return call(format, arg)
    end
    return template
end

Localization.InternalTranslate = function(text)
    if not TextTranslate then
        return nil
    end
    local result = TextTranslate(text)
    if result == text then
        return nil
    end
    return result
end
Localization._objects_translate_map = {
    ["JAPANMECHAX"] = "JAPANEMPERORMECHA",
    ["PRISMTANK"] = "AlliedPrismTank",
    ["SOVIETSLEDGEHAMMERSPG"] = "SovietSPG",
    ["JAPANSENTINELVEHICLE"] = "JapanSteelRoninMecha",
    ["CELESTIALANTIVEHICLEVEHICLETECH1"] = "CelestialMBT",
    ["CELESTIALLONGRANGEMISSILEVEHICLE_B"] = "CelestialHJ-10",
    ["ALLIEDANTISTRUCTUREBOMBERAIRCRAFT"] = "AlliedBomberAircraft",
    ["CELESTIALADVANCEDAIRCRAFTTECH4"] = "CelestialAdvanceAircraftTech4"
}
Localization.ObjectsTranslate = function(id)
    local t = Localization.InternalTranslate
    id = Localization._objects_translate_map[strupper(id)] or id
    return t("NAME:" .. id)
        or t("NAME:" .. gsub(id, "_Ground", "", 1))
        or t("NAME:" .. gsub(id, "_Naval", "", 1))
        or t("NAME:" .. gsub(id, "_Air", "", 1))
        or t("NAME:" .. gsub(id, "_Water", "", 1))
        or t("NAME:" .. gsub(id, "_B", "", 1))
        or t("NAME:" .. gsub(id, "_EMC", "", 1))
        or id
end

Localization.UpgradesTranslate = function(id)
    local t = Localization.InternalTranslate
    return t("UPGRADENAME:" .. id)
        or t("UPGRADE:" .. id)
        or t("NAME:" .. id)
        or t(gsub(id, "Upgrade_", "UpgradeName:", 1))
        or t(gsub(id, "Upgrade_", "Name:", 1))
        or id
end

Localization.recycle = function(key, ...)
    -- if key is unit.CelestialScoutDrone, we need to obtain CelestialScoutDrone
    if strsub(key, 1, 5) == "unit." then
        local unit_key = strsub(key, 6)
        local translated = Localization.ObjectsTranslate(unit_key)
        if translated ~= unit_key then
            return translated
        else
            _ALERT("Localization: failed to translate unit key " .. unit_key)
        end
        return translated
    end

    local recycle_args = { 'recycle.' .. key }
    for i = 1, getn(arg) do
        recycle_args[i + 1] = arg[i]
    end
    return call(Localization.get, recycle_args)
end

Localization.map = function(key)
    local source = Localization._map_sources[key]
    if not source then
        return {}
    end
    local selected = source[Localization.lang] or source.zh or source.en or {}
    return Localization_copy_value(selected)
end

Localization.on_language_changed = function(f, data)
    if type(f) ~= "function" then
        _ALERT("Localization.on_language_changed: argument is not a function")
        return
    end
    Localization._language_changed_callbacks = Localization._language_changed_callbacks or {}
    if getn(Localization._language_changed_callbacks) > 200 then
        _ALERT("Localization.on_language_changed: too many callbacks registered, possible memory leak, aborting")
        return
    end
    tinsert(Localization._language_changed_callbacks, { f = f, data = data })
end

function TextDoActionLocalizedOnce(id, ...)
    -- NAMED_SHOW_INFOBOX
    -- SHOW_MILITARY_CAPTION
    -- DISPLAY_TUTORIAL_TEXT
    -- DISPLAY_COUNTER
    -- DISPLAY_COUNTDOWN_TIMER

    -- example: TextDoActionLocalized("NAMED_SHOW_INFOBOX", "HOME", "SCRIPT:learn", "0", "")

    if not id then
        _ALERT("TextDoActionLocalized: missing action id")
        return
    end
    -- handle each action type
    local data = {}
    data.get_text_key = function(self)
        local text_key = self.text_key
        if not text_key then
            _ALERT("TextDoActionLocalized: missing text_key")
            return "GUI:ERROR"
        end
        local text_key_en = text_key .. "_en"
        if Localization.lang == "en" then
            -- check if en key exists
            if Localization.InternalTranslate(text_key_en) then
                return text_key_en
            end
        end
        return text_key
    end
    if id == "NAMED_SHOW_INFOBOX" then
        data.unit_name = arg[1]
        data.text_key = arg[2]
        data.duration = tonumber(arg[3]) or 0
        data.image_id = arg[4] or ""
        data.f = function(self)
            local text_key = self:get_text_key()
            -- use localization key directly for ExecuteAction
            ExecuteAction("NAMED_SHOW_INFOBOX", self.unit_name, text_key, self.duration, self.image_id)
        end
    elseif id == "SHOW_MILITARY_CAPTION" then
        data.text_key = arg[1]
        data.duration = tonumber(arg[2]) or 0
        data.f = function(self)
            local text_key = self:get_text_key()
            -- use localization key directly for ExecuteAction
            ExecuteAction("SHOW_MILITARY_CAPTION", text_key, self.duration)
        end
    elseif id == "DISPLAY_TUTORIAL_TEXT" then
        data.text_key = arg[1]
        data.f = function(self)
            local text_key = self:get_text_key()
            -- use localization key directly for ExecuteAction
            ExecuteAction("DISPLAY_TUTORIAL_TEXT", text_key)
        end
    elseif id == "DISPLAY_COUNTER" then
        data.counter_name = arg[1]
        data.text_key = arg[2]
        data.f = function(self)
            local text_key = self:get_text_key()
            -- use localization key directly for ExecuteAction
            ExecuteAction("DISPLAY_COUNTER", self.counter_name, text_key)
        end
    elseif id == "DISPLAY_COUNTDOWN_TIMER" then
        data.counter_name = arg[1]
        data.text_key = arg[2]
        data.f = function(self)
            local text_key = self:get_text_key()
            -- use localization key directly for ExecuteAction
            ExecuteAction("DISPLAY_COUNTDOWN_TIMER", self.counter_name, text_key)
        end
    else
        _ALERT("TextDoActionLocalized: unknown action id " .. id)
        return
    end

    data:f()
    return data
end

function TextDoActionLocalized(id, ...)
    local action_args = { id }
    for i = 1, getn(arg) do
        tinsert(action_args, arg[i])
    end
    local data = call(TextDoActionLocalizedOnce, action_args)
    if not data then
        return
    end
    -- register callback for language change
    Localization.on_language_changed(data.f, data)
end
