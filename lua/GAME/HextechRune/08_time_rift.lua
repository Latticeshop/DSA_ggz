-- 海克斯符文“时间裂隙”：敌方全体单位和建筑每 29 秒被时停 3 秒。
-- 时停沿用地图“时空管理局”技能的实现，释放节奏沿用神圣干预的调度。

HextechRune = HextechRune or {}

HextechRune.TimeRiftRuneId = "prismatic_time_rift"
-- 15 帧 = 1 秒：29 秒 = 435 帧，3 秒 = 45 帧。
HextechRune.TimeRiftInterval = 435
HextechRune.TimeRiftDuration = 45
HextechRune.TimeRiftSchedulerId = HextechRune.TimeRiftSchedulerId or nil
HextechRune.TimeRiftRefPrefix = "HextechTimeRift_"
-- 置灰靠 PARALYZED 禁用状态，本 Modifier 只提供时空裂缝的视觉表现。
HextechRune.TimeRiftFrozenModifier = "AttributeMod_ChronoRiftEffect"
HextechRune.TimeRiftSound = "ALL_Chronorift_OnOffMS"

function HextechRune:SetTimeRiftFrozen(unit, frozen, refPrefix)
    local objectId = ObjectGetId(unit)
    local referenceName = refPrefix .. tostring(objectId)
    ExecuteAction("SET_UNIT_REFERENCE", referenceName, unit)
    if frozen then
        ExecuteAction("NAMED_SET_DISABLED", referenceName, "PARALYZED", "true")
        ObjectLoadAttributeModifier(objectId, self.TimeRiftFrozenModifier,
            self.TimeRiftDuration)
    else
        ExecuteAction("NAMED_SET_DISABLED", referenceName, "PARALYZED", "false")
        ObjectLoadAttributeModifier(objectId, self.TimeRiftFrozenModifier, 1)
    end
end

-- 冻结阵营 sideIndex 的全部单位和建筑，TimeRiftDuration 帧后自动解除。
function HextechRune:FreezeSideByTimeRift(sideIndex)
    if P == nil or P[sideIndex] == nil then
        return
    end
    local objects, count = ObjectFindObjects(P[sideIndex], nil,
        self.AllSideUnitsAndStructuresFilter)
    if count <= 0 then
        return
    end
    local frozen = {}
    local refPrefix = self.TimeRiftRefPrefix .. tostring(sideIndex) .. "_"
    for i = 1, count, 1 do
        if ObjectIsAlive(objects[i]) then
            self:SetTimeRiftFrozen(objects[i], true, refPrefix)
            tinsert(frozen, objects[i])
        end
    end
    ExecuteAction("PLAY_SOUND_EFFECT", self.TimeRiftSound)
    -- 只解除本次真正冻结过的对象；期间阵亡的对象直接跳过。
    SchedulerModule.delay_call(function(units, prefix)
        for i = 1, getn(units), 1 do
            if ObjectIsAlive(units[i]) then
                HextechRune:SetTimeRiftFrozen(units[i], false, prefix)
            end
        end
    end, HextechRune.TimeRiftDuration, { frozen, refPrefix })
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
