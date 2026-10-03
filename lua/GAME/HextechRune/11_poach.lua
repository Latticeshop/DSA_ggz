-- 讲解见 analysis/地图注释说明文档.md 附录 A.25

HextechRune = HextechRune or {}

-- 触发点：回合起点之后「本回合预算 − 5 秒」。地图回合由 WorldBuilder 的 start 计时器
-- 定为 60 秒，之后被 lvcadd 逐轮加时（+1~5 秒），所以首个回合按 60 秒算，
-- 之后用上一回合实测到的时长自我校准，始终落在回合结束前 5 秒附近。
HextechRune.PoachDefaultRoundFrames = 60 * 15
HextechRune.PoachFireLeadFrames = 5 * 15
-- 校准值的合法区间（30~180 秒）：投降提前结束等异常观测不参与校准。
HextechRune.PoachMinRoundFrames = 30 * 15
HextechRune.PoachMaxRoundFrames = 180 * 15
HextechRune.PoachObservedRoundFrames = HextechRune.PoachObservedRoundFrames or nil
-- 轮询间隔（15 帧 = 1 秒）。
HextechRune.PoachPollInterval = 15
HextechRune.PoachSchedulerId = HextechRune.PoachSchedulerId or nil
-- 已产出过的回合号，保证同一个回合不会重复触发。
HextechRune.PoachTriggeredRounds = HextechRune.PoachTriggeredRounds or {}
-- 当前观测到的回合号与它的起点帧（回合切换时重新锚定）。
HextechRune.PoachWatchedRound = HextechRune.PoachWatchedRound or -1
HextechRune.PoachRoundStartFrame = HextechRune.PoachRoundStartFrame or 0
-- 持有判定兼看 Id：Effect 字段意外缺失时也不会漏判。
HextechRune.PoachRuneId = "gold_poach"
-- 敌方卡池为空时向持有者播报诊断行（排查用；确认无误后置 nil 关闭）。
HextechRune.PoachDiagnostics = true
-- 生成落点在本方出生点两侧的偏移（本符文每人唯一，正常只有 1 份）。
HextechRune.PoachSpawnSideStep = 60

function HextechRune:GetPlayerPoachCopies(playerIndex)
    self:EnsurePlayerRuneState(playerIndex)
    local copies = 0
    local owned = self.PlayerOwnedRunes[playerIndex]
    for i = 1, getn(owned), 1 do
        if owned[i].Effect == "poach" or owned[i].Id == self.PoachRuneId then
            copies = copies + 1
        end
    end
    return copies
end

function HextechRune:EnsurePoachScheduler()
    if self.PoachSchedulerId ~= nil then
        return
    end
    self.PoachSchedulerId = SchedulerModule.call_every_x_frame(function()
        HextechRune:CheckPoachTrigger()
    end, self.PoachPollInterval, nil, {})
end

-- 本回合从起点到触发所需的帧数（15 帧 = 1 秒）。
function HextechRune:GetPoachFireFrames()
    local roundFrames = self.PoachObservedRoundFrames or self.PoachDefaultRoundFrames
    local fireFrames = roundFrames - self.PoachFireLeadFrames
    if fireFrames < self.PoachPollInterval then
        fireFrames = self.PoachPollInterval
    end
    return fireFrames
end

-- 敌方三名玩家单位池里出现过的单位下标（按单位下标去重，与阵营无关）。
function HextechRune:CollectPoachSourceUnitIndexes(playerIndex)
    local indexes = {}
    if UNITCOUNT == nil or UNITLIST == nil or unitcountmax == nil then
        return indexes
    end
    local firstPlayerIndex, lastPlayerIndex =
        self:GetSidePlayerRange(self:GetEnemySideIndex(playerIndex))
    local seen = {}
    for enemyIndex = firstPlayerIndex, lastPlayerIndex, 1 do
        local enemyPool = UNITCOUNT[enemyIndex]
        if enemyPool ~= nil then
            for unitIndex = 1, unitcountmax, 1 do
                if UNITLIST[unitIndex] ~= nil and seen[unitIndex] == nil
                    and (enemyPool[unitIndex] or 0) > 0 then
                    seen[unitIndex] = true
                    tinsert(indexes, unitIndex)
                end
            end
        end
    end
    return indexes
end

-- 生成给拥有者：与穿云定海同款通道，单位归属自己的 teamPlayer，
-- 随后由 unitgenerate 的周期回收折算进单位池。
function HextechRune:GrantPoachUnit(playerIndex, unitIndex, copyIndex)
    local unitType = UNITLIST[unitIndex]
    if unitType == nil then
        return nil
    end
    self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        unitType, format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120,
            self.PoachSpawnSideStep * copyIndex), 0)
    return unitType
end

function HextechRune:ApplyPoachToPlayer(playerIndex)
    local copies = self:GetPlayerPoachCopies(playerIndex)
    if copies <= 0 then
        return
    end
    local sources = self:CollectPoachSourceUnitIndexes(playerIndex)
    if getn(sources) == 0 then
        -- 敌方单位池为空（尚未回收过任何单位）时不产出。诊断开启时告知持有者，
        -- 便于区分「压根没触发」与「触发了但敌方池子为空」。
        if self.PoachDiagnostics then
            exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
                Localization.get("hextech.rune.poach.no_source"), 10)
        end
        return
    end
    for copyIndex = 1, copies, 1 do
        local unitIndex = sources[self:RandomIndex(getn(sources))]
        local unitType = self:GrantPoachUnit(playerIndex, unitIndex, copyIndex)
        if unitType ~= nil then
            exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
                Localization.get("hextech.rune.poach.broadcast",
                    GetDrawnUnitNameFromRecycleList(playerIndex, unitType)), 10)
        end
    end
end

function HextechRune:CheckPoachTrigger()
    if exCounterGetByName == nil or GetFrame == nil then
        return
    end
    local round = tonumber(exCounterGetByName("lvc")) or 0
    if round < 1 then
        self.PoachWatchedRound = round
        return
    end
    if round ~= self.PoachWatchedRound then
        -- 新回合：先用刚结束那一回合的实测时长校准本回合预算，再重新锚定起点帧。
        if self.PoachWatchedRound >= 1 and GetFrame() > self.PoachRoundStartFrame then
            local observed = GetFrame() - self.PoachRoundStartFrame
            if observed >= self.PoachMinRoundFrames
                and observed <= self.PoachMaxRoundFrames then
                self.PoachObservedRoundFrames = observed
            end
        end
        self.PoachWatchedRound = round
        self.PoachRoundStartFrame = GetFrame()
        return
    end
    if self.PoachTriggeredRounds[round] then
        return
    end
    if GetFrame() - self.PoachRoundStartFrame < self:GetPoachFireFrames() then
        return
    end
    self.PoachTriggeredRounds[round] = true
    for playerIndex = 1, 6, 1 do
        self:ApplyPoachToPlayer(playerIndex)
    end
end
