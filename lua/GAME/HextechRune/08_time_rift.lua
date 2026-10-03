-- 讲解见 analysis/地图注释说明文档.md 附录 A.18

HextechRune = HextechRune or {}

HextechRune.TimeRiftRuneId = "prismatic_time_rift"
-- 15 帧 = 1 秒：29 秒 = 435 帧，3 秒 = 45 帧。
HextechRune.TimeRiftInterval = 435
HextechRune.TimeRiftDuration = 45
HextechRune.TimeRiftSchedulerId = HextechRune.TimeRiftSchedulerId or nil
HextechRune.TimeRiftRefPrefix = "HextechTimeRift_"
HextechRune.TimeRiftSound = "ALL_Chronorift_OnOffMS"

function HextechRune:SetTimeRiftFrozen(unit, frozen, refPrefix)
    local referenceName = refPrefix .. tostring(ObjectGetId(unit))
    if frozen then
        g_SetTimeStopFrozen(unit, referenceName, "rift", true,
            self.TimeRiftDuration, self.TimeRiftDuration)
    else
        g_SetTimeStopFrozen(unit, referenceName, "rift", false, 0, 0)
    end
end

-- 冻结阵营 sideIndex 的全部单位和建筑，TimeRiftDuration 帧后解除。
function HextechRune:FreezeSideByTimeRift(sideIndex)
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
        if ObjectIsAlive(objects[i]) then
            self:SetTimeRiftFrozen(objects[i], true, refPrefix)
            tinsert(frozenIds, ObjectGetId(objects[i]))
        end
    end
    ExecuteAction("PLAY_SOUND_EFFECT", self.TimeRiftSound)
    -- 只解除本次真正冻结过的对象；登记的是 id，阵亡的对象直接跳过，
    -- 活着的再按 id 现取句柄，避免缓存的旧句柄把 nil 喂进引擎。
    SchedulerModule.delay_call(function(ids, prefix)
        for i = 1, getn(ids), 1 do
            if ObjectIsAlive(ids[i]) then
                HextechRune:SetTimeRiftFrozen(GetObjectById(ids[i]), false, prefix)
            end
        end
    end, HextechRune.TimeRiftDuration, { frozenIds, refPrefix })
end

-- 持有方冻结的是自己的对手，双方都持有时互相冻结。
function HextechRune:ApplyTimeRiftPulse(sourceName)
    if self:GetSideOwnedRuneCount(7, self.TimeRiftRuneId) > 0 then
        self:FreezeSideByTimeRift(8)
    end
    if self:GetSideOwnedRuneCount(8, self.TimeRiftRuneId) > 0 then
        self:FreezeSideByTimeRift(7)
    end
end

function HextechRune:EnsureTimeRiftScheduler()
    if self.TimeRiftSchedulerId ~= nil then
        return
    end
    self.TimeRiftSchedulerId = SchedulerModule.call_every_x_frame(function()
        HextechRune:ApplyTimeRiftPulse("周期触发")
    end, self.TimeRiftInterval, nil, {})
end
