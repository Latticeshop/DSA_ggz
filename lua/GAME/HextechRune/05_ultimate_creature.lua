-- 讲解见 analysis/地图注释说明文档.md 附录 A.12、A.32

-- 海克斯符文“究极生物”：献祭玩家单位池，并在每回合出兵时强化该玩家 1 只随机 T3/T4 单位。

HextechRune = HextechRune or {}

HextechRune.UltimateCreatureStates = HextechRune.UltimateCreatureStates or {}
HextechRune.UltimateCreatureEmperorsRageModifier =
    "AttributeModifer_JapanEmperorsResolve_L1"
HextechRune.UltimateCreatureScale = 1.3
-- 每只献祭单位的加成百分比：T1→血量、T2→伤害、T3→攻速、T4→射程，与播报文案共用一份。
HextechRune.UltimateCreatureTierPercent = { 5, 5, 5, 7 }
HextechRune.UltimateCreatureRegisteredUnits =
    HextechRune.UltimateCreatureRegisteredUnits or {}

HextechRune.UltimateCreatureTargetTypes = {
    -- 盟军
    "AlliedCryoLegionnaire",                -- 冰冻军团
    "AlliedCommandoTech1",                  -- 谭雅
    "AlliedAntiStructureVehicle",           -- 雅典娜炮
    "AlliedAntiVehicleVehicleTech3",        -- 幻影坦克
    "AlliedInterceptorAircraft",            -- 阿瑞斯截击机
    "AlliedAntiNavyShipTech3",              -- 波塞冬巡洋舰
    "AlliedFutureTank",                     -- 未来坦克 X-1
    "AlliedBattleFortress",                 -- 特洛伊要塞
    "AlliedGunshipAircraft",                -- 先锋炮艇机
    "AlliedAntiStructureShip",              -- 航母
    "AlliedThetisBattleShip",               -- 忒提斯战列舰
    -- 苏联
    "SovietCommandoTech1",                  -- 娜塔莎
    "SovietAntiStructureVehicle",           -- V4 导弹发射车
    "SovietAntiVehicleVehicleTech3",        -- 天启坦克
    "VUMissileAntiVehicleVehicleTech1",     -- “菊花”导弹车
    "SovietHeavyMortarVehicle",             -- 郁金香自行迫击炮
    "SovietInterceptorAircraft",            -- 苏霍伊截击机
    "SovietTransportAircraft",              -- 纤夫运输直升机
    "SovietAntiNavyShipTech3",              -- 光荣级导弹巡洋舰
    "SovietAntiVehicleVehicleTech4",        -- 联盟重型坦克（新联盟，玩家可生产）
    "Overlordtank",                         -- 联盟重型坦克（旧联盟，箱子单位；与上面同名不同 ID）
    "SovietBomberAircraft",                 -- 基洛夫飞艇
    "SovietTransportAircraft_HeavyCannon",  -- 武装纤夫
    "SovietAntiStructureShip",              -- 无畏级武库舰
    -- 帝国
    "JapanAntiVehicleInfantryTech3",            -- 火箭天使
    "JapanCommandoTech1",                       -- 欧米伽百合子
    "JapanMissileMechaAdvanced",                -- 心神机甲
    "JapanAntiVehicleVehicleTech3",             -- 鬼王
    "JapanAntiStructureVehicle",                -- 波能坦克
    "JapanAntiNavyShipTech3",                   -- 太刀重巡洋舰
    "CelestialSeized_JapanAntiNavyShipTech3",   -- 一式磁轨炮重巡
    "JapanMechaX",                              -- 鬼王X
    "JapanAntiStructureShip",                   -- 将军战列舰
    -- 神州
    "CelestialAntiInfantryInfantryAdvanced",    -- 迅雷天罡
    "CelestialAntiVehicleVehicleTech3",         -- 祝融攻坚战车
    "CelestialHeavyAntiAirVehicleTech3",        -- 祝融雷铳战车
    "CelestialAntiStructureVehicle",            -- 白虎量子重炮运载车
    "CelestialInterceptorAircraft",             -- 重明截击机
    "CelestialAdvanceAircraftTech4",            -- 摇光巡天炮
    "CelestialAntiNavyShipTech3",               -- 玄冥级战列巡洋舰
    "CelestialAntiVehicleVehicleTech4",         -- 破军金甲
    "CelestialAntiStructureShip",               -- 玄武级攻击潜艇
}

-- 名单里的舰船条目：禁海模式（g_DisableSeaArmy == 1）下整条跳过。
HextechRune.UltimateCreatureSeaTargetTypes = {
    AlliedAntiNavyShipTech3 = true,                 -- 波塞冬巡洋舰
    AlliedAntiStructureShip = true,                 -- 航母
    AlliedThetisBattleShip = true,                  -- 忒提斯战列舰
    SovietAntiNavyShipTech3 = true,                 -- 光荣级导弹巡洋舰
    SovietAntiStructureShip = true,                 -- 无畏级武库舰
    JapanAntiNavyShipTech3 = true,                  -- 太刀重巡洋舰
    JapanAntiStructureShip = true,                  -- 将军战列舰
    CelestialSeized_JapanAntiNavyShipTech3 = true,  -- 一式磁轨炮重巡
    CelestialAntiNavyShipTech3 = true,              -- 玄冥级战列巡洋舰
    CelestialAntiStructureShip = true,              -- 玄武级攻击潜艇
}

-- 玩家持有出口内销时太刀一律以一式形态入池，圈中原形态就永远进化不出来。
function HextechRune:PickUltimateCreatureTarget(excluded)
    if g_UnitNameToUnitIndex == nil then
        return nil
    end
    local types = self.UltimateCreatureTargetTypes
    local sea = self.UltimateCreatureSeaTargetTypes
    local candidates = {}
    for i = 1, getn(types), 1 do
        local unitType = types[i]
        local unitIndex = g_UnitNameToUnitIndex[unitType]
        if unitIndex ~= nil
            and (g_DisableSeaArmy ~= 1 or sea[unitType] == nil)
            and (excluded == nil or excluded[unitType] == nil) then
            tinsert(candidates, {
                Type = unitType,
                UnitIndex = unitIndex,
                Name = Localization.ObjectsTranslate(unitType),
            })
        end
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

HextechRune.NonProductionUnitTier = {
    -- T1：增援步兵、功能与空投形态
    JapanKamikazeInfantry = 1,             -- 狂热帝国武士
    AlliedHumveeVehicle = 1,               -- 机枪悍马
    AlliedHumveeVehicle_Ranger = 1,
    AlliedGrizzlyMainBattleTank = 1,       -- 灰熊坦克
    AlliedRangerInfantry = 1,              -- 游骑兵（原生箱子结果，玩家不可生产）
    AlliedRangerInfantry_AirAssault = 1,
    VUAntiInfantryVehicleTech1 = 1,        -- “蝾螈”步兵战车
    SovietAntiAirVehicle = 1,              -- 石勒喀河自行高射炮
    SovietAntiAirVehicle_Transport = 1,
    CelestialSaluteGun = 1,                -- 神州礼炮
    CelestialForkLiftVehicle = 1,          -- 神州军用叉车
    CelestialMBT99A = 1,                   -- 貔貅破阵战车—甲型
    CelestialMBT99B = 1,                   -- 貔貅破阵战车—乙型
    CelestialEngineerRepairDrone = 1,      -- 维修天灯（灯火辉煌召唤 Lv2）
    CelestialEngineerRepairDroneLv2 = 1,
    CelestialEngineerRepairDroneLv3 = 1,
    WinterArmyKoelAttackUAV = 1,           -- 蜂鸟侦查无人机
    WinterArmyScoutVehicle = 1,            -- 勘察飞轮
    SovietWeatherBalloon = 1,              -- 民用气象飞艇
    CelestialShipNearDefenseMissileTurret = 1, -- 磁弩高射炮近防形态
    CelestialFireworkTrigger = 1,          -- 天眼哨机烟花形态
    CelestialWaveriderIFV_Water = 1,       -- 凌波护卫战车（水陆形态）
    CelestialWaveriderIFV_Mortar = 1,      -- 凌波火力支援战车
    CelestialWaveriderIFV_DragonBreathe = 1, -- 凌波龙息炮重型战车
    CelestialAntiInfantryVehicle_B_Heavy = 1,
    CelestialAntiInfantryVehicle_Dropped = 1,
    CelestialAntiInfantryVehicle_HeavyTransport = 1,
    CelestialAirDrop_Land = 1,             -- 凌波空投形态
    JapanLightTransportVehicle = 1,        -- 迅雷运输艇
    JapanLightTransportVehicle_AntiTank = 1,
    JapanLightTransportVehicle_Kamikaze = 1,
    SovietSurveyor = 1,                    -- 史普尼克勘查车
    SovietSurveyor_Naval = 1,
    -- T2：不可生产的二线战斗单位
    AlliedInfiltrationInfantry = 2,        -- 间谍
    AlliedPacifierFAV = 2,                 -- 平定者
    AlliedArtilleryVehicle = 2,
    RheinEntenteNimravusMBT = 2,           -- 莱茵豹主战坦克
    RheinEntentePalaeoloxodonTD = 2,       -- 菱齿象坦克歼击车
    VUBmptVehicle = 2,                     -- BMPT 坦克支援车
    SovietHeavyAntiAirVehicleTech2 = 2,    -- ZSU-85 自行防空炮
    VUAntiAirVehicleTech1 = 2,             -- “偏流”两栖高射炮
    VUAntiVehicleVehicleTech1 = 2,         -- “章鱼”突击炮
    WinterArmyReaperHeavyMecha = 2,        -- 收割机甲
    SovietAntiVehicleVehicleTech2 = 2,     -- 磁爆坦克
    SovietAntiVehicleVehicleTech1 = 2,     -- 铁锤坦克
    CelestialWheeledAssaultVehicle = 2,    -- 玄铁歼击车
    SovietHeavyGrinder = 2,                -- 粉碎者
    SovietGrinderVehicleCorona = 2,
    AlliedAvengerAttackAircraft = 2,       -- 复仇者攻击机
    AlliedNightinaleHelicopter = 2,        -- 夜莺直升机
    AlliedLandingCraftAirCushion = 2,      -- 气垫登陆舰
    AlliedLandingCraftAirCushion_Ranger = 2,
    CelestialWaveriderIFV_ATGM = 2,        -- 青锋两栖导弹战车
    -- T3：不可生产的重火力与运输单位
    VUMissileAntiVehicleVehicleTech1 = 3,  -- “菊花”导弹车
    SovietHeavyMortarVehicle = 3,          -- 郁金香自行迫击炮
    SovietHeavyTransportAircraft = 3,      -- 鲁斯兰大型运输机
    JapanSakuraAttackRocket = 3,           -- 鬼樱特攻机
    CelestialSeized_JapanAntiNavyShipTech3 = 3, -- 一式磁轨炮重巡
    -- T4：超级要塞与要塞变体
    AlliedThetisBattleShip = 4,            -- 忒提斯战列舰
    Overlordtank = 4,                      -- 联盟重型坦克
    Overlordtank_SpitfireEngineer = 4,
    JapanGigaFortress_Land = 4,            -- 超级要塞（大头轰炸形态）
    JapanFortressShip = 4,                 -- 超级要塞（空中形态）
    -- T5：按 T4 结算的超阶单位
    CelestialMCV = 5,                      -- 青龙战斗核心舰
    CelestialMCV_Air = 5,
    CelestialMCV_Ground = 5,
    CelestialMCV_Naval = 5,
    CelestialMCV_Enhanced = 5,
    CelestialMCV_Enhanced_Air = 5,
    CelestialMCV_Enhanced_Ground = 5,
    CelestialMCV_Enhanced_Naval = 5,
    CelestialDF41 = 5,                     -- 东风洲际导弹发射车
    AlliedGaintAirCraftCarrier_B = 5,      -- 奥林匹斯级航空母舰
    JapanYumiAircraftCarrier = 5,          -- 千鸟特攻母舰
}

-- 生产别名形态默认继承来源单位的阶级，重炮纤夫按策划表比来源高一级，
-- 又不进抽卡池（进池就会被空投抽中），所以在这里覆盖，优先级高于抽卡池。
HextechRune.ProductionFormTierOverride = {
    SovietTransportAircraft_HeavyCannon = 4, -- 重炮纤夫（纤夫的武装形态，不可生产）
}

-- 查回收价：先查阵营回收表，再查箱子模板表。
function HextechRune:GetUltimateCreatureRecycleMoney(unitType)
    if g_RecycleBtnsMapByFaction ~= nil then
        for faction = 1, 4, 1 do
            local factionMap = g_RecycleBtnsMapByFaction[faction]
            if factionMap ~= nil then
                for category = 1, 4, 1 do
                    local unitInfos = factionMap[category]
                    if unitInfos ~= nil then
                        for i = 1, getn(unitInfos), 1 do
                            local info = unitInfos[i]
                            if info.Type == unitType or info.CountType == unitType then
                                return tonumber(info.Money) or 0
                            end
                        end
                    end
                end
            end
        end
    end
    if g_CrateUnits ~= nil then
        for category = 1, 4, 1 do
            local unitInfos = g_CrateUnits[category]
            if unitInfos ~= nil then
                for i = 1, getn(unitInfos), 1 do
                    if unitInfos[i].Type == unitType then
                        return tonumber(unitInfos[i].Money) or 0
                    end
                end
            end
        end
    end
    return 0
end

-- 究极生物与以战养战共用这一个判定入口，优先级见 NonProductionUnitTier 上方的说明。
function HextechRune:GetUltimateCreatureUnitTier(unitType)
    local override = self.ProductionFormTierOverride[unitType]
    if override ~= nil then
        if override > 4 then
            return 4
        end
        return override
    end

    if g_PureDrawUnitInfoByHash ~= nil then
        local info = g_PureDrawUnitInfoByHash[FastHash(unitType)]
        if info ~= nil and info.Tier ~= nil then
            return info.Tier
        end
    end

    local tier = self.NonProductionUnitTier[unitType]
    if tier ~= nil then
        if tier > 4 then
            return 4
        end
        return tier
    end

    if string ~= nil and string.find ~= nil then
        if string.find(unitType, "Tech4", 1, true) ~= nil then
            return 4
        elseif string.find(unitType, "Tech3", 1, true) ~= nil then
            return 3
        elseif string.find(unitType, "Tech2", 1, true) ~= nil then
            return 2
        elseif string.find(unitType, "Tech1", 1, true) ~= nil then
            return 1
        end
    end

    local money = self:GetUltimateCreatureRecycleMoney(unitType)
    if money > 3000 then
        return 4
    elseif money > 1800 then
        return 3
    elseif money > 1000 then
        return 2
    end
    return 1
end

function HextechRune:SacrificeUnitPoolForUltimateCreature(playerIndex)
    local tierCounts = { 0, 0, 0, 0 }
    local yaoguangCount = 0
    for unitIndex = 1, unitcountmax, 1 do
        local count = tonumber(UNITCOUNT[playerIndex][unitIndex]) or 0
        if count > 0 then
            local unitType = UNITLIST[unitIndex]
            local tier = self:GetUltimateCreatureUnitTier(unitType)
            tierCounts[tier] = tierCounts[tier] + count
            if unitType == "CelestialAdvanceAircraftTech4" then
                yaoguangCount = count
            end
        end
        UNITCOUNT[playerIndex][unitIndex] = 0
        if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[playerIndex] ~= nil then
            CRATEUNITCOUNT[playerIndex][unitIndex] = 0
        end
    end

    -- 超级要塞核心使用独立计数槽，不计入 ANYUNITCOUNT，但仍属于玩家单位池。
    if g_UnitCount ~= nil then
        local gigaSlot = g_UnitCount[FastHash("JapanGigaFortressShipEgg")]
        if gigaSlot ~= nil then
            local gigaCount = tonumber(gigaSlot[playerIndex]) or 0
            tierCounts[4] = tierCounts[4] + gigaCount
            gigaSlot[playerIndex] = 0
        end
    end
    if yaoguangCount > 0 and RemovePlayerProducedYaoguangFromPool ~= nil then
        RemovePlayerProducedYaoguangFromPool(playerIndex, yaoguangCount)
    end
    ANYUNITCOUNT[playerIndex] = 0
    return tierCounts
end

-- 回收完成后按以战养战同款格式播报，让持有者看清献祭换到了多少数值。
function HextechRune:BroadcastUltimateCreature(playerIndex, tierCounts)
    if tierCounts[1] + tierCounts[2] + tierCounts[3] + tierCounts[4] <= 0 then
        return
    end
    local percents = self.UltimateCreatureTierPercent
    local text = Localization.get("hextech.rune.ultimate_creature.broadcast",
        tierCounts[1] * percents[1], tierCounts[2] * percents[2],
        tierCounts[3] * percents[3], tierCounts[4] * percents[4])
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, text, 10)
end

function HextechRune:CreateUltimateCreature(playerIndex, rune)
    local tierCounts = self:SacrificeUnitPoolForUltimateCreature(playerIndex)
    self.UltimateCreatureStates[playerIndex] = {
        TierCounts = tierCounts,
        UnitIndex = rune.TargetUnitIndex,
    }
    self:BroadcastUltimateCreature(playerIndex, tierCounts)

    -- 目标单位在选卡那一刻随机定好（见 CreateRuneCandidateForPlayer 的 minTier 分支），
    -- 献祭之后只把它作为唯一种子放回单位池。
    UNITCOUNT[playerIndex][rune.TargetUnitIndex] = 1
    ANYUNITCOUNT[playerIndex] = 1
end

-- 地编把 T3 塔守护者直接摆成了旧联盟坦克模板（PassengerLoadSpawn 的 g_PLSpawnGuardCarNames
-- 就是为它们开的）。究极生物每人每回合只进化一只，圈中守卫等于把整层收益花在地图单位上，
-- 所以施加入口按脚本名剔除。判定只比对象 id、不缓存句柄。
HextechRune.UltimateCreatureGuardScriptNames = {
    "overlord7", "overlord8",
}

function HextechRune:IsUltimateCreatureGuardUnit(unit)
    if unit == nil or GetObjectByScriptName == nil then
        return false
    end
    local objectId = ObjectGetId(unit)
    for i = 1, getn(self.UltimateCreatureGuardScriptNames), 1 do
        local guard = GetObjectByScriptName(
            self.UltimateCreatureGuardScriptNames[i])
        if guard ~= nil and ObjectGetId(guard) == objectId then
            return true
        end
    end
    return false
end

function HextechRune:IsUltimateCreatureRegistered(unit)
    if not ObjectIsAlive(unit) then
        return false
    end
    local objectId = ObjectGetId(unit)
    local entry = self.UltimateCreatureRegisteredUnits[objectId]
    if entry == nil or entry.Unit == nil or not ObjectIsAlive(entry.Unit) then
        return false
    end
    local registeredObjectId = entry.ObjectId or ObjectGetId(entry.Unit)
    return registeredObjectId == objectId
end

function HextechRune:CleanupUltimateCreatureRegistrations()
    for objectId, entry in self.UltimateCreatureRegisteredUnits do
        if entry.Unit == nil or not ObjectIsAlive(entry.Unit)
            or (entry.ObjectId or ObjectGetId(entry.Unit)) ~= objectId then
            self.UltimateCreatureRegisteredUnits[objectId] = nil
        end
    end
end

-- NAMED_SHOW_INFOBOX 与天界守护者使用同一套命名对象信息框机制。
-- 目标单位不是地编预命名单位，因此先按对象ID建立唯一单位引用，再显示本地化文案。
function HextechRune:ShowUltimateCreatureInfoBox(unit)
    local objectId = ObjectGetId(unit)
    local unitReference = "HextechUltimateCreature_" .. tostring(objectId)
    ExecuteAction("SET_UNIT_REFERENCE", unitReference, unit)
    TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", unitReference,
        "SCRIPT:UltimateCreature", 0, "")
    return unitReference
end

function HextechRune:ApplyUltimateCreatureToUnit(unit, state, playerIndex)
    if not ObjectIsAlive(unit) then
        return false
    end
    if self:IsUltimateCreatureGuardUnit(unit) then
        return false
    end
    if self:IsUltimateCreatureRegistered(unit) then
        return false
    end

    -- 每只究极生物使用独立的动态Modifier实例，避免同一实例在不同对象间
    -- 表现为全场唯一或后加载者覆盖前一只。
    local tierCounts = state.TierCounts
    local percents = self.UltimateCreatureTierPercent
    -- T1~T4 与血量/伤害/攻速/射程一一对应。射程必须与索敌视野同倍率，
    -- 否则单位会在射程边缘停下却看不见目标。
    local rangeBonus = 1 + tierCounts[4] * percents[4] / 100
    local modifier = exAttributeModifierCreate({
        HEALTH_MULT = 1 + tierCounts[1] * percents[1] / 100,
        DAMAGE_MULT = 1 + tierCounts[2] * percents[2] / 100,
        RATE_OF_FIRE = 1 + tierCounts[3] * percents[3] / 100,
        RANGE = rangeBonus,
        VISION = rangeBonus,
    }, 1)
    ObjectLoadAttributeModifier(unit, modifier,
        self.PersistentBuffDuration)
    -- 只加载天皇之怒一级的实际数值，不释放其范围武器和地面特效。
    ObjectLoadAttributeModifier(unit,
        self.UltimateCreatureEmperorsRageModifier,
        self.PersistentBuffDuration)
    -- 复用塔防守护者的固定缩放接口，只放大模型表现。
    exObjectSetFixedScale(ObjectGetId(unit), self.UltimateCreatureScale)
    -- 与数值BUFF同步，为每只实际进化成功的究极生物建立自己的常驻信息框。
    local infoBoxReference = self:ShowUltimateCreatureInfoBox(unit)
    self.UltimateCreatureRegisteredUnits[ObjectGetId(unit)] = {
        Unit = unit,
        ObjectId = ObjectGetId(unit),
        PlayerIndex = playerIndex,
        Modifier = modifier,
        InfoBoxReference = infoBoxReference,
    }
    return true
end

-- 复用普通数值BUFF的本轮新单位分配结果。即使普通载具 BUFF 使多只目标单位
-- 同时进入 assignments，每名持有者每回合仍只进化其中 1 只。
-- 普通符文先于本函数加载，因此两个独立 Modifier 会按引擎属性规则叠加。
function HextechRune:ApplyUltimateCreatures(assignments)
    local appliedPlayers = {}
    self:CleanupUltimateCreatureRegistrations()

    for i = 1, getn(assignments), 1 do
        local assignment = assignments[i]
        local playerIndex = assignment.PlayerIndex
        local state = self.UltimateCreatureStates[playerIndex]
        if state ~= nil and not appliedPlayers[playerIndex]
            and assignment.UnitIndex == state.UnitIndex
            and self:IsCurrentAssignment(assignment.Unit, assignment) then
            if self:ApplyUltimateCreatureToUnit(assignment.Unit, state,
                playerIndex) then
                assignment.UltimateCreatureGranted = true
                appliedPlayers[playerIndex] = true
            end
        end
    end
end
