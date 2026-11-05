-- 讲解见 analysis/地图注释说明文档.md 附录 A.42

AICOMP = AICOMP or {}

-- 自然解锁：更新日志「第 6、12、19 回合解锁下一回合的科技」→ 从第 7/13/20 回合起该阶级可造。
AICOMP.NaturalUnlockRounds = { 7, 13, 20 }
-- 电脑席位 → 参考真人席位（开局定下后固定；参考席位不再是真人时重选）。
AICOMP.Reference = AICOMP.Reference or {}
AICOMP.LastRound = AICOMP.LastRound or -1
AICOMP.PoolCache = AICOMP.PoolCache or {}
AICOMP.BuildableSet = AICOMP.BuildableSet
AICOMP.MoneyMap = AICOMP.MoneyMap

-- 本方科技等级要看「对面」的陆地塔：对面塔被推掉一座 = 本方科技 +1（与 T71Unlock/T81Unlock 一致）。
AICOMP.EnemyTowerNames = {
    [7] = { "T81", "T82", "T83" },
    [8] = { "T71", "T72", "T73" },
}

-- 编制统计 / 补兵顺序的类别数：就是出兵分段的 5 个桶，优先级顺序 = 1..5（步兵 > 载具 > 空军 > 海军 > 额外段）。
AICOMP.CategoryCount = 5

-- 真人席位：AID_0 已把非人类席位标成 AI[seat] = 1，且席位上的 MCV 锚点 P[seat] 存在。
function AICOMP.IsHumanSeat(seat)
    if seat == nil or P == nil or P[seat] == nil then
        return false
    end
    if AI == nil then
        return false
    end
    return AI[seat] ~= 1
end

function AICOMP.OppositeSide(side)
    if side == 7 then
        return 8
    end
    return 7
end

-- 优先对面阵营的真人；对面没有真人时用任意真人；一个真人都没有时返回 nil。
function AICOMP.GetReference(aiSeat)
    local current = AICOMP.Reference[aiSeat]
    if current ~= nil and AICOMP.IsHumanSeat(current) then
        return current
    end
    local side = g_SeatToSide(aiSeat)
    if side == nil then
        return nil
    end
    local enemySide = AICOMP.OppositeSide(side)
    local enemyHumans = {}
    local anyHumans = {}
    for seat = 1, 8, 1 do
        if seat ~= aiSeat and AICOMP.IsHumanSeat(seat) then
            tinsert(anyHumans, seat)
            if g_SeatToSide(seat) == enemySide then
                tinsert(enemyHumans, seat)
            end
        end
    end
    local pool = enemyHumans
    if getn(pool) == 0 then
        pool = anyHumans
    end
    if getn(pool) == 0 then
        AICOMP.Reference[aiSeat] = nil
        return nil
    end
    -- 多个真人时随机挑一个当参考（单人对局时池里只有那一个）。
    local pick = pool[RANDOMGENERATE(getn(pool), 1)]
    AICOMP.Reference[aiSeat] = pick
    return pick
end

-- 本方科技等级（1..4）。
function AICOMP.GetSideTechLevel(side)
    -- 死亡模式与「缩小模式(启用死亡模式效果)」科技全开。
    if g_GameMode == 2 or g_EnableDeathModeEffect == 1 then
        return 4
    end
    -- 升本模式：科技靠钱买，直接读购买等级。
    if g_GameMode == 4 then
        local level = g_evilTechLevel
        if side == 8 then
            level = g_angelTechLevel
        end
        level = tonumber(level) or 1
        if level > 4 then
            level = 4
        end
        if level < 1 then
            level = 1
        end
        return level
    end
    local byTower = 1
    local names = AICOMP.EnemyTowerNames[side]
    if names ~= nil then
        for i = 1, getn(names), 1 do
            local tower = GetObjectByScriptName(names[i])
            local alive = false
            if tower ~= nil and ObjectIsAlive(tower) then
                alive = true
            end
            if not alive then
                byTower = byTower + 1
            end
        end
    end
    local round = tonumber(exCounterGetByName("lvc")) or 1
    local byRound = 1
    for i = 1, getn(AICOMP.NaturalUnlockRounds), 1 do
        if round >= AICOMP.NaturalUnlockRounds[i] then
            byRound = byRound + 1
        end
    end
    local level = byTower
    if byRound > level then
        level = byRound
    end
    if level > 4 then
        level = 4
    end
    return level
end

-- UNITLIST 的出兵分段 → 类别号。出兵批次只覆盖到 step5，之后（step5+1..step6）没有批次可用，
-- 这类槽位直接返回 0（电脑不镜像它们，因为镜像了也刷不出来）。
function AICOMP.GetBandOfUnitIndex(unitIndex)
    if step1 == nil or step2 == nil or step3 == nil or step35 == nil
        or step4 == nil or step5 == nil then
        return 0
    end
    if unitIndex <= step1 then
        return 1
    end
    if unitIndex <= step3 then
        return 2
    end
    if unitIndex <= step35 then
        return 3
    end
    if unitIndex <= step4 then
        return 4
    end
    if unitIndex <= step5 then
        return 5
    end
    return 0
end

-- ===== 阵营（1 = 盟军 / 2 = 苏联 / 3 = 帝国 / 4 = 神州）=====
-- 席位阵营由 PlayerSide.lua 用 PLAYER_HAS_PLAYER_TECH 判出来，电脑席位也有值。
function AICOMP.GetSeatFaction(seat)
    if g_PlayerSide == nil or seat == nil then
        return nil
    end
    return g_PlayerSide[seat]
end

-- 抽卡/幸运箱是否开启：g_DrawMode 0 = 关闭，1 = 原版幸运箱，2 = 纯抽卡。
-- （06_init_mcv.lua 在地图里有 GenericCrateSpawner 时会把 0 默认成 1，房主在开局对话框里
--   选「关闭」才会保持 0，所以这里就是最终口径。）
function AICOMP.IsDrawModeOn()
    if g_DrawMode == nil then
        return false
    end
    return g_DrawMode ~= 0
end

-- 可生产池名单：g_PureDrawBuildableUnitPool 里玩家造得出来的单位（去掉 LockPlayerProduction）。
function AICOMP.GetBuildableSet()
    if AICOMP.BuildableSet ~= nil then
        return AICOMP.BuildableSet
    end
    local set = {}
    if g_PureDrawBuildableUnitPool ~= nil then
        for tier = 1, 4, 1 do
            local list = g_PureDrawBuildableUnitPool[tier]
            if list ~= nil then
                for i = 1, getn(list), 1 do
                    local info = list[i]
                    if info.Type ~= nil and info.LockPlayerProduction ~= true then
                        set[info.Type] = true
                    end
                end
            end
        end
    end
    AICOMP.BuildableSet = set
    return set
end

-- 抽卡开着时，回收表里的战斗单位玩家都可能通过箱子拿到（含 Ranger / 摇光 / AC130 等箱子专属）；
-- 抽卡关着时只认可生产池。
function AICOMP.IsUnitObtainable(unitType)
    if AICOMP.IsDrawModeOn() then
        return true
    end
    return AICOMP.GetBuildableSet()[unitType] == true
end

-- 回收价（单位 → 金钱），阶级兜底用；表结构同 g_RecycleBtnsMapByFaction。
function AICOMP.GetRecycleMoney(unitType)
    if AICOMP.MoneyMap == nil then
        local map = {}
        if g_RecycleBtnsMapByFaction ~= nil then
            for faction = 1, 4, 1 do
                local factionMap = g_RecycleBtnsMapByFaction[faction]
                if factionMap ~= nil then
                    for category = 1, 4, 1 do
                        local units = factionMap[category]
                        if units ~= nil then
                            for i = 1, getn(units), 1 do
                                local info = units[i]
                                if info.Type ~= nil and map[info.Type] == nil then
                                    map[info.Type] = tonumber(info.Money) or 0
                                end
                            end
                        end
                    end
                end
            end
        end
        AICOMP.MoneyMap = map
    end
    return AICOMP.MoneyMap[unitType] or 0
end

-- 单位阶级（1..4）。顺序与 05_ultimate_creature 的 GetUltimateCreatureUnitTier 对齐：
-- 抽卡表 → 名字里的 TechN → 回收价阈值，最后按 T1 算。
function AICOMP.GetUnitTier(unitType)
    if unitType == nil then
        return 1
    end
    if g_PureDrawUnitInfoByHash ~= nil and FastHash ~= nil then
        local info = g_PureDrawUnitInfoByHash[FastHash(unitType)]
        if info ~= nil and info.Tier ~= nil then
            local tier = tonumber(info.Tier) or 1
            if tier > 4 then
                tier = 4
            end
            if tier < 1 then
                tier = 1
            end
            return tier
        end
    end
    if strfind ~= nil then
        if strfind(unitType, "Tech4") ~= nil then
            return 4
        end
        if strfind(unitType, "Tech3") ~= nil then
            return 3
        end
        if strfind(unitType, "Tech2") ~= nil then
            return 2
        end
    end
    local money = AICOMP.GetRecycleMoney(unitType)
    if money > 3000 then
        return 4
    elseif money > 1800 then
        return 3
    elseif money > 1000 then
        return 2
    end
    return 1
end

-- 某个席位按类别（＝出兵分段的 5 个桶）的编制：Cat 数量、MaxTier 该类别最高阶级、Total 总数量。
-- 杂项段（step5+1..step6，band 0）不统计：没有任何出兵批次会刷它们，算进去总量永远追不平。
function AICOMP.CollectCategoryState(seat)
    local state = { Cat = { 0, 0, 0, 0, 0 }, MaxTier = { 0, 0, 0, 0, 0 }, Total = 0 }
    if UNITCOUNT == nil or UNITCOUNT[seat] == nil or unitcountmax == nil
        or UNITLIST == nil then
        return state
    end
    for unitIndex = 1, unitcountmax, 1 do
        local count = tonumber(UNITCOUNT[seat][unitIndex]) or 0
        if count > 0 then
            local band = AICOMP.GetBandOfUnitIndex(unitIndex)
            if band > 0 and band <= AICOMP.CategoryCount then
                local tier = AICOMP.GetUnitTier(UNITLIST[unitIndex])
                state.Cat[band] = state.Cat[band] + count
                if tier > state.MaxTier[band] then
                    state.MaxTier[band] = tier
                end
                state.Total = state.Total + count
            end
        end
    end
    return state
end

-- 补兵用的阶级：min(参考玩家该类别最高阶级, 本方科技等级)；该阶级本阵营投不出来就往下退到 T1。
-- 返回 0 = 这一类别的所有阶级都投不出来（禁用 / 池子被掏空），调用方跳过它。
function AICOMP.ResolveCategoryTier(seat, category, refTier, techLevel)
    local tier = refTier
    if tier <= 0 then
        tier = techLevel
    end
    if techLevel < tier then
        tier = techLevel
    end
    if tier > 4 then
        tier = 4
    end
    if tier < 1 then
        tier = 1
    end
    while tier >= 1 do
        local pool = AICOMP.GetCandidatePool(seat, tier, category)
        if getn(pool) > 0 then
            return tier
        end
        tier = tier - 1
    end
    return 0
end

function AICOMP.BuildFactionPool(faction, tier, band)
    local pool = {}
    if g_RecycleBtnsMapByFaction == nil or faction == nil
        or g_UnitNameToUnitIndex == nil then
        return pool
    end
    local factionMap = g_RecycleBtnsMapByFaction[faction]
    if factionMap == nil then
        return pool
    end
    local seen = {}
    for category = 1, 4, 1 do
        local units = factionMap[category]
        if units ~= nil then
            for i = 1, getn(units), 1 do
                local info = units[i]
                local unitType = info.Type
                if unitType ~= nil and seen[unitType] == nil
                    and info.CountType == nil
                    and info.CountsTowardArmyTotal ~= false then
                    seen[unitType] = true
                    local unitIndex = g_UnitNameToUnitIndex[unitType]
                    if unitIndex ~= nil
                        and AICOMP.GetBandOfUnitIndex(unitIndex) == band
                        and AICOMP.GetUnitTier(unitType) == tier
                        and BanModeIsSlotBanned(unitIndex) == 0
                        and AICOMP.IsUnitObtainable(unitType) then
                        tinsert(pool, unitIndex)
                    end
                end
            end
        end
    end
    return pool
end

-- 全阵营合并池：本阵营这一阶级这一类别没有可投单位时的兜底（例如帝国空军表只有 1 个单位）。
function AICOMP.BuildAllFactionPool(tier, band)
    local merged = {}
    local seen = {}
    for faction = 1, 4, 1 do
        local pool = AICOMP.BuildFactionPool(faction, tier, band)
        for i = 1, getn(pool), 1 do
            local unitIndex = pool[i]
            if seen[unitIndex] == nil then
                seen[unitIndex] = true
                tinsert(merged, unitIndex)
            end
        end
    end
    return merged
end

-- 池子缓存的键：抽卡开关 × 阵营 × 阶级 × 类别。
function AICOMP.PoolKey(seat, tier, band)
    local faction = AICOMP.GetSeatFaction(seat)
    if faction == nil then
        faction = 0
    end
    local drawKey = 0
    if AICOMP.IsDrawModeOn() then
        drawKey = 1
    end
    return drawKey * 10000 + faction * 100 + tier * 10 + band
end

function AICOMP.GetCandidatePool(seat, tier, band)
    local key = AICOMP.PoolKey(seat, tier, band)
    local cached = AICOMP.PoolCache[key]
    if cached ~= nil then
        return cached
    end
    local faction = AICOMP.GetSeatFaction(seat)
    local pool = nil
    if faction ~= nil then
        pool = AICOMP.BuildFactionPool(faction, tier, band)
    end
    if pool == nil or getn(pool) == 0 then
        pool = AICOMP.BuildAllFactionPool(tier, band)
    end
    AICOMP.PoolCache[key] = pool
    return pool
end

-- 往席位编制里随机塞 amount 个该阶级该类别的单位，返回实际塞进去的数量。
function AICOMP.AddRandomUnits(seat, band, tier, amount)
    if UNITCOUNT == nil or UNITCOUNT[seat] == nil or amount <= 0 then
        return 0
    end
    local pool = AICOMP.GetCandidatePool(seat, tier, band)
    local total = getn(pool)
    if total <= 0 then
        return 0
    end
    local added = 0
    for i = 1, amount, 1 do
        local unitIndex = pool[RANDOMGENERATE(total, 1)]
        UNITCOUNT[seat][unitIndex] = (tonumber(UNITCOUNT[seat][unitIndex]) or 0) + 1
        added = added + 1
    end
    if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[seat] ~= nil then
        ANYUNITCOUNT[seat] = (tonumber(ANYUNITCOUNT[seat]) or 0) + added
    end
    return added
end

function AICOMP.ApplySeat(aiSeat)
    local side = g_SeatToSide(aiSeat)
    if side == nil then
        return
    end
    local refSeat = AICOMP.GetReference(aiSeat)
    if refSeat == nil then
        -- 全电脑局（没有真人可参照）：保留老行为，每回合四个兵种段各 +1 个 T1 单位。
        for band = 1, 4, 1 do
            AICOMP.AddRandomUnits(aiSeat, band, 1, 1)
        end
        return
    end
    local techLevel = AICOMP.GetSideTechLevel(side)
    local refState = AICOMP.CollectCategoryState(refSeat)
    local ownState = AICOMP.CollectCategoryState(aiSeat)
    local need = refState.Total - ownState.Total
    if need <= 0 then
        return
    end
    for category = 1, AICOMP.CategoryCount, 1 do
        if need <= 0 then
            break
        end
        local deficit = refState.Cat[category] - ownState.Cat[category]
        if deficit > 0 then
            local tier = AICOMP.ResolveCategoryTier(aiSeat, category,
                refState.MaxTier[category], techLevel)
            if tier > 0 then
                local take = deficit
                if take > need then
                    take = need
                end
                local added = AICOMP.AddRandomUnits(aiSeat, category, tier, take)
                if added > 0 then
                    need = need - added
                end
            end
        end
    end
end

-- 每回合一次：把所有电脑席位补齐。按回合号去重，重复调用（地编钩子 + 出兵钩子）不会叠加。
function AICOMP.EnsureRound()
    if AI == nil or P == nil or UNITCOUNT == nil or unitcountmax == nil then
        return
    end
    local round = tonumber(exCounterGetByName("lvc")) or 1
    if AICOMP.LastRound == round then
        return
    end
    AICOMP.LastRound = round
    for aiSeat = 1, 8, 1 do
        if AI[aiSeat] == 1 and P[aiSeat] ~= nil then
            AICOMP.ApplySeat(aiSeat)
        end
    end
end

-- ===== 地编脚本入口（AIUNITBUILDACT__0..3）=====
-- 这四个函数原来是「每回合给电脑 +1 个随机 T1 单位」，现在统一转成编制同步入口。
-- 幂等：同一回合被调用多次（四个入口 + 出兵钩子）只会生效一次。
function spinfantlv1()
    AICOMP.EnsureRound()
end

function spinlightvehlv1()
    AICOMP.EnsureRound()
end

function spinheavyvehlv1()
    AICOMP.EnsureRound()
end

function spaircraftlv1()
    AICOMP.EnsureRound()
end
