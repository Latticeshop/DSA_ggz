-- 讲解见 analysis/地图注释说明文档.md 附录 A.42 / C / D

AICOMP = AICOMP or {}

AICOMP.NaturalUnlockRounds = { 7, 13, 20 }
-- 电脑席位 → 参考真人席位
AICOMP.Reference = AICOMP.Reference or {}
AICOMP.LastRound = AICOMP.LastRound or -1
AICOMP.PoolCache = AICOMP.PoolCache or {}
AICOMP.BuildableSet = AICOMP.BuildableSet
AICOMP.MoneyMap = AICOMP.MoneyMap
-- 电脑席位 → { [band] = tier }：模仿对象已展示过的最高阶级，只升不降
AICOMP.TierShown = AICOMP.TierShown or {}
-- 电脑席位 → { [组下标] = 本脚本已投放数 }；符文赠送的不计入上限
AICOMP.CapCount = AICOMP.CapCount or {}
AICOMP.CapGroups = AICOMP.CapGroups
-- 电脑席位 → 1：T4 解锁 + 1 星已发
AICOMP.T4Rewarded = AICOMP.T4Rewarded or {}
-- 技能对拼：递归深度 + 本次链已出手的席位
AICOMP.SkillMirrorDepth = AICOMP.SkillMirrorDepth or 0
AICOMP.SkillMirrorChain = AICOMP.SkillMirrorChain or {}
-- 电脑席位 → 技能组号 1..6（选了不改）
AICOMP.SkillGroupOf = AICOMP.SkillGroupOf or {}
AICOMP.SkillGroupBusy = AICOMP.SkillGroupBusy or 0

-- 本方科技看对面陆地塔（与 T71Unlock / T81Unlock 一致）
AICOMP.EnemyTowerNames = {
    [7] = { "T81", "T82", "T83" },
    [8] = { "T71", "T72", "T73" },
}

-- 出兵分段的 5 个桶，优先级 1..5
AICOMP.CategoryCount = 5

-- 真人席位：AI[seat] ~= 1 且 MCV 锚点 P[seat] 存在
function AICOMP.IsHumanSeat(seat)
    if seat == nil or P == nil or P[seat] == nil then
        return false
    end
    if AI == nil then
        return false
    end
    return AI[seat] ~= 1
end

function AICOMP.IsComputerSeat(seat)
    if seat == nil or P == nil or P[seat] == nil or AI == nil then
        return false
    end
    return AI[seat] == 1
end

-- 给 ButtonManager / CenterTopBtnFunc 用（那两个文件不引用 AICOMP）
function g_IsAutoChessComputerSeat(seat)
    return AICOMP.IsComputerSeat(seat)
end

function AICOMP.OppositeSide(side)
    if side == 7 then
        return 8
    end
    return 7
end

-- 可作参照：真人席位 + 没退出（资产已被队友继承、池子已清零）+ 没被推平。
-- 不能用 AI[] 判（它只在开局算一次，掉线者永远是 AI=0 的「真人」）。
function AICOMP.IsReferenceEligible(seat)
    if not AICOMP.IsHumanSeat(seat) then
        return false
    end
    -- 掉线/阵亡：MONEYINI_3 的 TransferPlayerAssets / LosePlayerAssets 会先置该标记，
    -- 再把他名下 UNITCOUNT / ANYUNITCOUNT 清零或转给继承者（见附录 D.1）。
    if g_PowerSlotVacated ~= nil and g_PowerSlotVacated[seat] == 1 then
        return false
    end
    if g_AutoSurrender ~= nil and g_AutoSurrender.PlayerNowDied ~= nil
        and g_AutoSurrender.PlayerNowDied[seat] == 1 then
        return false
    end
    return true
end

-- 候选真人：优先对面阵营，没有则退回全部真人
function AICOMP.GetReferenceCandidates(aiSeat, humans)
    local side = g_SeatToSide(aiSeat)
    if side == nil or getn(humans) == 0 then
        return humans
    end
    local enemySide = AICOMP.OppositeSide(side)
    local sameEnemy = {}
    for i = 1, getn(humans), 1 do
        if g_SeatToSide(humans[i]) == enemySide then
            tinsert(sameEnemy, humans[i])
        end
    end
    if getn(sameEnemy) > 0 then
        return sameEnemy
    end
    return humans
end

-- 均衡分配参照（每回合开头调一次，已稳定的席位直接跳过；见附录 D.1）
function AICOMP.AssignReferences()
    if AI == nil or P == nil or g_SeatToSide == nil then
        return
    end
    local humans = {}
    for seat = 1, 8, 1 do
        if AICOMP.IsReferenceEligible(seat) then
            tinsert(humans, seat)
        end
    end
    if getn(humans) == 0 then
        -- 场上已经没有可参照的真人（全掉线/全被推平）：清掉参照，退回「每段各 +1 个 T1」的老行为。
        -- 不清就会一直照着池子已清零的死人算 need <= 0，电脑从此彻底不出兵。
        for aiSeat = 1, 8, 1 do
            if AI[aiSeat] == 1 and P[aiSeat] ~= nil then
                AICOMP.Reference[aiSeat] = nil
                AICOMP.TierShown[aiSeat] = nil
            end
        end
        return
    end
    for aiSeat = 1, 8, 1 do
        if AI[aiSeat] == 1 and P[aiSeat] ~= nil then
            local current = AICOMP.Reference[aiSeat]
            if current == nil or not AICOMP.IsReferenceEligible(current) then
                local candidates = AICOMP.GetReferenceCandidates(aiSeat, humans)
                local bestCount = nil
                local bestTotal = 0
                local best = {}
                for i = 1, getn(candidates), 1 do
                    local candidate = candidates[i]
                    -- 本席位此时的参照已经失效，统计结果里不会含它自己。
                    local count = 0
                    for other = 1, 8, 1 do
                        if other ~= aiSeat and AICOMP.Reference[other] == candidate then
                            count = count + 1
                        end
                    end
                    if bestCount == nil or count < bestCount then
                        bestCount = count
                        bestTotal = 1
                        best = { candidate }
                    elseif count == bestCount then
                        bestTotal = bestTotal + 1
                        best[bestTotal] = candidate
                    end
                end
                if bestTotal > 0 then
                    AICOMP.Reference[aiSeat] = best[RANDOMGENERATE(bestTotal, 1)]
                    -- 换了人就清掉阶级记忆，否则会带着上一个参照的科技等级继续用。
                    if current ~= nil and current ~= AICOMP.Reference[aiSeat] then
                        AICOMP.TierShown[aiSeat] = nil
                    end
                end
            end
        end
    end
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

-- 抽卡功能是否开启：g_DrawMode 0 = 关闭，1 = 出兵 + 抽卡（原版幸运箱），2 = 纯抽卡。
-- 只管「卡池范围」，不管阶级上限（见附录 D.6）。
function AICOMP.IsDrawModeOn()
    if g_DrawMode == nil then
        return false
    end
    return g_DrawMode ~= 0
end

-- 纯抽卡模式（g_DrawMode == 2）：只有这个模式才不看科技等级、只对总数量。
function AICOMP.IsPureDrawMode()
    if g_DrawMode == nil then
        return false
    end
    return g_DrawMode == 2
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

-- 记录模仿对象的出货阶级快照（只升不降；见附录 D.2）
function AICOMP.SnapshotTiers(aiSeat, refState)
    if refState == nil then
        return
    end
    local shown = AICOMP.TierShown[aiSeat]
    if shown == nil then
        shown = {}
        AICOMP.TierShown[aiSeat] = shown
    end
    for band = 1, AICOMP.CategoryCount, 1 do
        local tier = refState.MaxTier[band]
        if tier > 0 and (shown[band] == nil or tier > shown[band]) then
            shown[band] = tier
        end
    end
end

-- 该段要模仿的阶级：优先用快照（记忆），还没快照到时退回现算值。
function AICOMP.GetShownTier(aiSeat, band, instantaneousTier)
    local shown = AICOMP.TierShown[aiSeat]
    if shown ~= nil and shown[band] ~= nil then
        return shown[band]
    end
    return instantaneousTier
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
        -- 按建造上限过滤后再判断：摇光/大船到顶时这一档等于投不出来，要继续往下退。
        local pool = AICOMP.FilterCappedPool(seat, AICOMP.GetCandidatePool(seat, tier, category))
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

-- ===== 建造上限：摇光 3 / T4 大船 2（见附录 D.3）=====
function AICOMP.IndexOfUnitIndex(list, unitIndex)
    if list == nil or unitIndex == nil then
        return false
    end
    for i = 1, getn(list), 1 do
        if list[i] == unitIndex then
            return true
        end
    end
    return false
end

function AICOMP.EnsureCapGroups()
    if AICOMP.CapGroups ~= nil then
        return AICOMP.CapGroups
    end
    -- 表没建好就先返回空表、不缓存
    if g_UnitNameToUnitIndex == nil or UNITLIST == nil or step35 == nil then
        return {}
    end
    local groups = {}
    if g_UnitNameToUnitIndex ~= nil then
        -- 摇光 3（普通型与加强型共用槽位）
        local yaoguang = g_UnitNameToUnitIndex["CelestialAdvanceAircraftTech4"]
        if yaoguang ~= nil then
            tinsert(groups, { Limit = 3, Indexes = { yaoguang } })
        end
    end
    -- T4 大船 2：step35+1..step35+4 四艘共享
    if step35 ~= nil and UNITLIST ~= nil then
        local ships = {}
        for unitIndex = step35 + 1, step35 + 4, 1 do
            if UNITLIST[unitIndex] ~= nil then
                tinsert(ships, unitIndex)
            end
        end
        if getn(ships) > 0 then
            tinsert(groups, { Limit = 2, Indexes = ships })
        end
    end
    AICOMP.CapGroups = groups
    return groups
end

-- 该槽位属于哪个上限组；不属于任何组返回 nil。
function AICOMP.FindCapGroupIndex(unitIndex)
    if unitIndex == nil then
        return nil
    end
    local groups = AICOMP.EnsureCapGroups()
    for g = 1, getn(groups), 1 do
        if AICOMP.IndexOfUnitIndex(groups[g].Indexes, unitIndex) then
            return g
        end
    end
    return nil
end

function AICOMP.IsCapGroupFull(seat, groupIndex)
    if groupIndex == nil then
        return false
    end
    local caps = AICOMP.CapCount[seat]
    if caps == nil then
        return false
    end
    local groups = AICOMP.EnsureCapGroups()
    if groups[groupIndex] == nil then
        return false
    end
    return (tonumber(caps[groupIndex]) or 0) >= groups[groupIndex].Limit
end

-- 过滤掉已到顶的兵种（池子是共享缓存，不能就地改；每次新建一张表）
function AICOMP.FilterCappedPool(seat, pool)
    if getn(AICOMP.EnsureCapGroups()) == 0 then
        return pool
    end
    local filtered = {}
    for i = 1, getn(pool), 1 do
        local unitIndex = pool[i]
        if not AICOMP.IsCapGroupFull(seat, AICOMP.FindCapGroupIndex(unitIndex)) then
            tinsert(filtered, unitIndex)
        end
    end
    return filtered
end

function AICOMP.MarkCapUsed(seat, unitIndex)
    local g = AICOMP.FindCapGroupIndex(unitIndex)
    if g == nil then
        return
    end
    local caps = AICOMP.CapCount[seat]
    if caps == nil then
        caps = {}
        AICOMP.CapCount[seat] = caps
    end
    caps[g] = (tonumber(caps[g]) or 0) + 1
end

-- 电脑唯一的入池出口（有符文系统就走符文钩子，见附录 D.4）
function AICOMP.CollectUnit(seat, unitIndex)
    if HextechRune ~= nil and HextechRune.CollectPoolUnits ~= nil then
        return HextechRune:CollectPoolUnits(seat, unitIndex, 1)
    end
    if UNITCOUNT == nil or UNITCOUNT[seat] == nil or unitIndex == nil then
        return 0
    end
    UNITCOUNT[seat][unitIndex] = (tonumber(UNITCOUNT[seat][unitIndex]) or 0) + 1
    if ANYUNITCOUNT ~= nil and ANYUNITCOUNT[seat] ~= nil then
        ANYUNITCOUNT[seat] = (tonumber(ANYUNITCOUNT[seat]) or 0) + 1
    end
    return 1
end

-- 抽卡模式专用：该段不限阶级的候选并集（优先本阵营，本阵营整段为空才退到全阵营）。
function AICOMP.GetAnyTierPool(seat, band)
    local faction = AICOMP.GetSeatFaction(seat)
    local factionKey = 0
    if faction ~= nil then
        factionKey = faction
    end
    -- 键与 PoolKey 的数值空间错开，并带上阵营
    local key = 200000 + factionKey * 10 + band
    local cached = AICOMP.PoolCache[key]
    if cached ~= nil then
        return cached
    end
    local pool = {}
    local seen = {}
    if faction ~= nil then
        for tier = 1, 4, 1 do
            local list = AICOMP.BuildFactionPool(faction, tier, band)
            for i = 1, getn(list), 1 do
                local unitIndex = list[i]
                if seen[unitIndex] == nil then
                    seen[unitIndex] = true
                    tinsert(pool, unitIndex)
                end
            end
        end
    end
    if getn(pool) == 0 then
        for tier = 1, 4, 1 do
            local list = AICOMP.BuildAllFactionPool(tier, band)
            for i = 1, getn(list), 1 do
                local unitIndex = list[i]
                if seen[unitIndex] == nil then
                    seen[unitIndex] = true
                    tinsert(pool, unitIndex)
                end
            end
        end
    end
    AICOMP.PoolCache[key] = pool
    return pool
end

-- 往编制里随机塞 amount 个该阶级该类别的单位，返回实际塞进去的数量（入池走 CollectUnit）
function AICOMP.AddRandomUnits(seat, band, tier, amount)
    if UNITCOUNT == nil or UNITCOUNT[seat] == nil or amount <= 0 then
        return 0
    end
    local source = AICOMP.GetCandidatePool(seat, tier, band)
    if getn(source) <= 0 then
        return 0
    end
    local added = 0
    for i = 1, amount, 1 do
        local pool = AICOMP.FilterCappedPool(seat, source)
        local total = getn(pool)
        if total <= 0 then
            break
        end
        local unitIndex = pool[RANDOMGENERATE(total, 1)]
        if AICOMP.CollectUnit(seat, unitIndex) > 0 then
            AICOMP.MarkCapUsed(seat, unitIndex)
            added = added + 1
        end
    end
    return added
end

-- 抽卡模式专用投放：不限阶级、不看模仿对象的兵种构成，只把数量补上。
function AICOMP.AddAnyTierUnits(seat, band, amount)
    if UNITCOUNT == nil or UNITCOUNT[seat] == nil or amount <= 0 then
        return 0
    end
    local source = AICOMP.GetAnyTierPool(seat, band)
    if getn(source) <= 0 then
        return 0
    end
    local added = 0
    for i = 1, amount, 1 do
        local pool = AICOMP.FilterCappedPool(seat, source)
        local total = getn(pool)
        if total <= 0 then
            break
        end
        local unitIndex = pool[RANDOMGENERATE(total, 1)]
        if AICOMP.CollectUnit(seat, unitIndex) > 0 then
            AICOMP.MarkCapUsed(seat, unitIndex)
            added = added + 1
        end
    end
    return added
end

function AICOMP.ApplySeat(aiSeat)
    local side = g_SeatToSide(aiSeat)
    if side == nil then
        return
    end
    local techLevel = AICOMP.GetSideTechLevel(side)
    -- 科技到 T4 的额外奖励（T4 解锁 + 1 星）不依赖模仿对象。
    AICOMP.ApplyT4Reward(aiSeat, techLevel)
    local refSeat = AICOMP.Reference[aiSeat]
    if refSeat == nil then
        -- 全电脑局（没有真人可参照）：保留老行为，每回合四个兵种段各 +1 个 T1 单位。
        for band = 1, 4, 1 do
            AICOMP.AddRandomUnits(aiSeat, band, 1, 1)
        end
        return
    end
    local refState = AICOMP.CollectCategoryState(refSeat)
    AICOMP.SnapshotTiers(aiSeat, refState)
    local ownState = AICOMP.CollectCategoryState(aiSeat)
    -- 纯抽卡模式：不看科技、不看兵种构成，只把总数量追平（逻辑有意简化）。
    -- 出兵 + 抽卡模式（g_DrawMode == 1）走下面正常分支：阶级仍受模仿对象与自身科技限制。
    if AICOMP.IsPureDrawMode() then
        AICOMP.ApplyDrawModeSeat(aiSeat, refState, ownState)
        return
    end
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
                AICOMP.GetShownTier(aiSeat, category, refState.MaxTier[category]),
                techLevel)
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

-- 纯抽卡模式（g_DrawMode == 2）：只追总数量，按 1..5 优先级补缺口且阶级不限（见附录 D.6）
function AICOMP.ApplyDrawModeSeat(seat, refState, ownState)
    local need = refState.Total - ownState.Total
    if need <= 0 then
        return
    end
    for band = 1, AICOMP.CategoryCount, 1 do
        if need <= 0 then
            break
        end
        local deficit = refState.Cat[band] - ownState.Cat[band]
        if deficit > 0 then
            local take = deficit
            if take > need then
                take = need
            end
            need = need - AICOMP.AddAnyTierUnits(seat, band, take)
        end
    end
    -- 各段都已追平、总量还差（模仿对象把兵放在不统计的杂项段）：随便补，只要总数对上。
    if need > 0 then
        for band = 1, AICOMP.CategoryCount, 1 do
            if need <= 0 then
                break
            end
            need = need - AICOMP.AddAnyTierUnits(seat, band, need)
        end
    end
end

-- ===== 电脑科技到 T4：补上真人靠建筑拿到的 T4 解锁 + 1 星（见附录 D.5）=====
function AICOMP.ApplyT4Reward(seat, techLevel)
    if techLevel < 4 or AICOMP.T4Rewarded[seat] == 1 then
        return
    end
    AICOMP.T4Rewarded[seat] = 1
    g_PlayerT4TechUnlocked = g_PlayerT4TechUnlocked
        or { false, false, false, false, false, false, false, false }
    g_PlayerT4TechUnlocked[seat] = true
    if LEVELUP ~= nil and g_SeatToSide ~= nil then
        local side = g_SeatToSide(seat)
        if side ~= nil then
            LEVELUP[side] = (tonumber(LEVELUP[side]) or 0) + 1
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
    -- 自愈：每回合清一次对拼链状态（见附录 D.7）
    AICOMP.SkillMirrorDepth = 0
    AICOMP.SkillMirrorChain = {}
    -- 先维护参照，再逐席位补兵
    AICOMP.AssignReferences()
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

-- ===== 电脑模仿对方释放技能（一次敌方施放 → 对面板一台电脑跟着放，形成对拼链）=====
-- 详见 analysis/地图注释说明文档.md 附录 D.7 / D.8 / D.9

function g_OnPlayerSkillCast(playerIndex, buttonIndex, skillKind)
    AICOMP.MirrorSkillCast(playerIndex, buttonIndex, skillKind)
end

-- 这个按钮现在还能不能放：已解锁、不在冷却、次数没用完
function AICOMP.CanUseSkillButton(button)
    if button == nil then
        return false
    end
    -- IsEnabled 正常是 true/false，引擎侧关按钮时可能写成 0
    if button.IsEnabled == nil or button.IsEnabled == false or button.IsEnabled == 0 then
        return false
    end
    if button._cooldownCount ~= nil and button._cooldownCount > 0 then
        return false
    end
    if button.MaxUseCount ~= nil
        and (tonumber(button._usedCount) or 0) >= button.MaxUseCount then
        return false
    end
    return true
end

-- ===== 阵营技能（按钮 3）：101 超时空突袭=盟军 / 102 全体护盾=帝国 / 103 士气提升=神州 =====
-- 苏联(2) 没有阵营技能，不参与这一路镜像（见附录 D.9）
AICOMP.FactionSkillFaction = { [101] = 1, [102] = 3, [103] = 4 }

-- 补上解锁标志（真人靠造建筑拿到，电脑不造建筑，由镜像代发）
function AICOMP.GrantFactionSkill(seat, skillKind)
    if skillKind == 101 then
        g_AlliedSuperWeaponBuilt = g_AlliedSuperWeaponBuilt or {}
        g_AlliedSuperWeaponBuilt[seat] = 1
    elseif skillKind == 102 then
        g_ProductionBonus_JapanGet = g_ProductionBonus_JapanGet or {}
        g_ProductionBonus_JapanGet[seat] = 1
    elseif skillKind == 103 then
        g_CelestialSuperWeapon_Get = g_CelestialSuperWeapon_Get or {}
        g_CelestialSuperWeapon_Get[seat] = 1
    end
end

-- 取该席位第 buttonIndex 个按钮（同技能）；阵营技能按钮电脑天生没有，按需补建（附录 D.9）
function AICOMP.EnsureSeatButton(seat, buttonIndex, skillKind)
    local button = ButtonManager:GetButton("Player_" .. seat, buttonIndex)
    if button ~= nil and button.SkillKind == skillKind then
        return button
    end
    if buttonIndex ~= 3 or CenterTopBtnFunc_UpdatePlayer3rdButton == nil then
        return nil
    end
    local faction = AICOMP.FactionSkillFaction[skillKind]
    if faction == nil or AICOMP.GetSeatFaction(seat) ~= faction then
        return nil
    end
    AICOMP.GrantFactionSkill(seat, skillKind)
    CenterTopBtnFunc_UpdatePlayer3rdButton(seat)
    button = ButtonManager:GetButton("Player_" .. seat, buttonIndex)
    if button ~= nil and button.SkillKind == skillKind then
        return button
    end
    return nil
end

function AICOMP.MirrorSkillCast(casterIndex, buttonIndex, skillKind)
    if ButtonManager == nil or g_SeatToSide == nil or g_SideSeatsOf == nil
        or AI == nil or P == nil or skillKind == nil then
        return
    end
    local oldDepth = AICOMP.SkillMirrorDepth or 0
    -- 兜底上限（正常链长 = 会这个技能的电脑数）
    if oldDepth >= 16 then
        return
    end
    local casterSide = g_SeatToSide(casterIndex)
    if casterSide == nil then
        return
    end
    if oldDepth == 0 then
        AICOMP.SkillMirrorChain = {}
    end
    local chain = AICOMP.SkillMirrorChain
    -- 本链已出手的席位不再参与：冷却要到 OnClick 尾段才落上去，这一跳正嵌在它中间
    chain[casterIndex] = 1
    local seats = g_SideSeatsOf(AICOMP.OppositeSide(casterSide))
    local candidates = {}
    for i = 1, getn(seats), 1 do
        local seat = seats[i]
        if seat ~= nil and AICOMP.IsComputerSeat(seat) and chain[seat] == nil then
            local button = AICOMP.EnsureSeatButton(seat, buttonIndex, skillKind)
            if button ~= nil and AICOMP.CanUseSkillButton(button) then
                tinsert(candidates, button)
            end
        end
    end
    -- 每一跳只让一台电脑放；它放不出来（返回 false / 次数不涨）就换下一台
    AICOMP.SkillMirrorDepth = oldDepth + 1
    local total = getn(candidates)
    while total >= 1 do
        local pickPos = RANDOMGENERATE(total, 1)
        local button = candidates[pickPos]
        candidates[pickPos] = candidates[total]
        candidates[total] = nil
        total = total - 1
        local before = tonumber(button._usedCount) or 0
        chain[button.PlayerIndex] = 1
        button:OnClick()
        if (tonumber(button._usedCount) or 0) > before then
            break
        end
    end
    AICOMP.SkillMirrorDepth = oldDepth
end

-- ===== 自选技能组模式：电脑照着对面的选择补一组（见附录 D.8）=====
function g_OnPlayerSkillGroupAssigned(playerIndex, kind)
    AICOMP.OnSkillGroupAssigned(playerIndex, kind)
end

function AICOMP.OnSkillGroupAssigned(playerIndex, kind)
    if playerIndex == nil or kind == nil then
        return
    end
    -- 选了不能改
    if AICOMP.SkillGroupOf[playerIndex] ~= nil then
        return
    end
    AICOMP.SkillGroupOf[playerIndex] = kind
    if g_PreselectedSkillIndices == nil or getn(g_PreselectedSkillIndices) > 0 then
        return
    end
    if g_SeatToSide == nil or CenterTopBtnFunc_CreatePlayerSkillButtons == nil then
        return
    end
    -- 只补真人亲手选的；被补课的电脑不再触发，避免递归
    if AICOMP.IsComputerSeat(playerIndex) or AICOMP.SkillGroupBusy == 1 then
        return
    end
    local side = g_SeatToSide(playerIndex)
    if side == nil then
        return
    end
    local oppSide = AICOMP.OppositeSide(side)
    -- 对面板已经有人拿了这一组就不再重复发，让 4 台电脑尽量覆盖不同的组。
    for seat = 1, 8, 1 do
        if AICOMP.IsComputerSeat(seat) and g_SeatToSide(seat) == oppSide
            and AICOMP.SkillGroupOf[seat] == kind then
            return
        end
    end
    for seat = 1, 8, 1 do
        if AICOMP.IsComputerSeat(seat) and g_SeatToSide(seat) == oppSide
            and AICOMP.SkillGroupOf[seat] == nil then
            -- 先记下再建按钮：里面的回调会重新进到这个函数，靠这一行判重。
            AICOMP.SkillGroupOf[seat] = kind
            AICOMP.SkillGroupBusy = 1
            CenterTopBtnFunc_CreatePlayerSkillButtons(seat, kind)
            AICOMP.SkillGroupBusy = 0
            return
        end
    end
end
