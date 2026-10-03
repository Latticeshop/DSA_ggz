-- 讲解见 analysis/地图注释说明文档.md 附录 A.18、A.30

HextechRune = HextechRune or {}

HextechRune.TimeRiftRuneId = "prismatic_time_rift"
-- 15 帧 = 1 秒：29 秒 = 435 帧，3 秒 = 45 帧。
HextechRune.TimeRiftInterval = 435
-- 基础时停 45 帧（3 秒）；同阵营每多一份增加基础时长的一半，
-- 22.5 帧向上取 23 帧（与神圣干预同一口径），1/2/3 份 = 45/68/91 帧。
HextechRune.TimeRiftBaseDuration = 45
HextechRune.TimeRiftExtraDurationPerCopy = 23
HextechRune.TimeRiftSchedulerId = HextechRune.TimeRiftSchedulerId or nil
HextechRune.TimeRiftRefPrefix = "HextechTimeRift_"
HextechRune.TimeRiftSound = "ALL_Chronorift_OnOffMS"

function HextechRune:SetTimeRiftFrozen(unit, frozen, refPrefix, duration)
    local referenceName = refPrefix .. tostring(ObjectGetId(unit))
    if frozen then
        g_SetTimeStopFrozen(unit, referenceName, "rift", true,
            duration, duration)
    else
        g_SetTimeStopFrozen(unit, referenceName, "rift", false, 0, 0)
    end
end

-- 冻结阵营 sideIndex 的全部单位和建筑，duration 帧后解除。
function HextechRune:FreezeSideByTimeRift(sideIndex, duration)
    if P == nil or P[sideIndex] == nil then
        return
    end
    local objects, count = ObjectFindObjects(P[sideIndex], nil,
        self.AllSideUnitsAndStructuresFilter)
    if count <= 0 then
        return
    end
    local frozenIds = {}
    local refPrefix = self.TimeRiftRefPrefix .. tostring(sideIndex) .. "_"
    for i = 1, count, 1 do
        -- 已经处于时停（技能组原生时停或上一批时间裂隙）的对象直接跳过：
        -- 符文的时停不该去改写已有的租约，解除交给原来那条租约。
        if ObjectIsAlive(objects[i]) and not g_IsTimeStopActive(objects[i]) then
            self:SetTimeRiftFrozen(objects[i], true, refPrefix, duration)
            tinsert(frozenIds, ObjectGetId(objects[i]))
        end
    end
    -- 整批都被过滤掉时本批没有任何实际效果，不再播裂缝音效，避免误导。
    if getn(frozenIds) <= 0 then
        return
    end
    ExecuteAction("PLAY_SOUND_EFFECT", self.TimeRiftSound)
    local releaseFrame = GetFrame() + duration
    SchedulerModule.delay_call(function(ids, prefix, endFrame)
        for i = 1, getn(ids), 1 do
            if ObjectIsAlive(ids[i]) then
                local holders = nil
                if g_TimeStopHolders ~= nil then
                    holders = g_TimeStopHolders[ids[i]]
                end
                if holders == nil or (holders.rift or 0) <= endFrame then
                    HextechRune:SetTimeRiftFrozen(GetObjectById(ids[i]), false,
                        prefix)
                end
            end
        end
    end, duration, { frozenIds, refPrefix, releaseFrame })
end

-- 持有方冻结的是自己的对手，双方都持有时互相冻结。
-- 份数只增加时停时长（与神圣干预同一口径），29 秒周期不变。
function HextechRune:ApplyTimeRiftToSide(sideIndex)
    local copies = self:GetSideOwnedRuneCount(sideIndex, self.TimeRiftRuneId)
    if copies <= 0 then
        return
    end
    local duration = self.TimeRiftBaseDuration
        + self.TimeRiftExtraDurationPerCopy * (copies - 1)
    local targetSideIndex = 8
    if sideIndex == 8 then
        targetSideIndex = 7
    end
    self:FreezeSideByTimeRift(targetSideIndex, duration)
end

function HextechRune:ApplyTimeRiftPulse(sourceName)
    self:ApplyTimeRiftToSide(7)
    self:ApplyTimeRiftToSide(8)
end

-- 详情文案展示的时停时长：按“这份符文到手后”的本方份数换算（1/2/3 份 = 3/4.5/6 秒）。
function HextechRune:GetTimeRiftDisplaySeconds(playerIndex)
    return self:GetRuneBuffDurationText(self:GetRuneDisplayCopyCount(playerIndex,
        self.TimeRiftRuneId))
end

function HextechRune:EnsureTimeRiftScheduler()
    if self.TimeRiftSchedulerId ~= nil then
        return
    end
    self.TimeRiftSchedulerId = SchedulerModule.call_every_x_frame(function()
        HextechRune:ApplyTimeRiftPulse("周期触发")
    end, self.TimeRiftInterval, nil, {})
end
