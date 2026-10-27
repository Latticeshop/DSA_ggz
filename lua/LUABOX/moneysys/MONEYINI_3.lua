-- 讲解见 analysis/地图注释说明文档.md 附录 A.50

LIMITPOWERC = 4
FLAGENPOWER = {}
for i = 1, 6, 1 do
    FLAGENPOWER[i] = 1
end

g_CachedPlayersPowerPlantLimit = {}

-- 玩家退出/死亡后的“小电份额”转交登记。
-- 份额只看开局存在的 P 席位：每席位一（神州 LIMITPOWERC，非神州 LIMITPOWERC + 1）。
-- MCV 符文/抽卡获得的额外基地不增加份额。
g_PowerSlotPresent = g_PowerSlotPresent or {}
g_PowerSlotController = g_PowerSlotController or {}
g_PowerSlotVacated = g_PowerSlotVacated or {}
g_PowerPlayerStructureIds = g_PowerPlayerStructureIds or {}
g_PowerSlotInitialized = g_PowerSlotInitialized or 0
-- 死亡由 PlayerSpellBook 死亡事件触发；事件后隔几秒只复查一轮，不做周期扫描。
g_PowerSlotDeathPending = g_PowerSlotDeathPending or {}
g_PowerSlotDeathScheduled = g_PowerSlotDeathScheduled or {}
g_PowerDeathRecheckFrames = 45

YAOGUANG_LIMIT = 3
FLAGENYAOGUANG = { 1, 1, 1, 1, 1, 1 }
g_PlayerProducedYaoguangCount = g_PlayerProducedYaoguangCount or { 0, 0, 0, 0, 0, 0 }

GUARDIAN_TANK_LIMIT = 3
FLAGENGUARDIANTANK = { 1, 1, 1, 1, 1, 1 }

function GetPlayerYaoguangCount(playindex)
    return tonumber(g_PlayerProducedYaoguangCount[playindex]) or 0
end

function RecordPlayerProducedYaoguang(playindex, count)
    local addCount = tonumber(count) or 0
    if addCount <= 0 then
        return
    end
    -- 实际计数不强行截成 3：若引擎同帧完成超额单位，必须保留真实数量，
    -- 防止只回收一个就错误解锁。对外剩余额度由下方函数严格夹在 0~3。
    g_PlayerProducedYaoguangCount[playindex] = GetPlayerYaoguangCount(playindex) + addCount
end

function RemovePlayerProducedYaoguangFromPool(playindex, removedCount)
    local producedCount = GetPlayerYaoguangCount(playindex)
    local reduceCount = tonumber(removedCount) or 0
    if reduceCount < 0 then
        reduceCount = 0
    end
    if reduceCount > producedCount then
        reduceCount = producedCount
    end
    g_PlayerProducedYaoguangCount[playindex] = producedCount - reduceCount
end

-- 池内实有摇光数量（只读单位池计数；箱子/海克斯赠送与重组器产出的摇光也在里面）。
function GetPlayerPoolYaoguangCount(playindex)
    if UNITCOUNT == nil or UNITCOUNT[playindex] == nil or g_UnitNameToUnitIndex == nil then
        return 0
    end
    local unitIndex = g_UnitNameToUnitIndex["CelestialAdvanceAircraftTech4"]
    if unitIndex == nil then
        return 0
    end
    return tonumber(UNITCOUNT[playindex][unitIndex]) or 0
end

function ReconcilePlayerProducedYaoguang(playindex)
    if g_PlayerProducedYaoguangCount == nil then
        return
    end
    local poolCount = GetPlayerPoolYaoguangCount(playindex)
    if GetPlayerYaoguangCount(playindex) > poolCount then
        g_PlayerProducedYaoguangCount[playindex] = poolCount
    end
end

function GetPlayerYaoguangRemainingProductionQuota(playindex)
    local remaining = YAOGUANG_LIMIT - GetPlayerYaoguangCount(playindex)
    if remaining < 0 then
        remaining = 0
    elseif remaining > YAOGUANG_LIMIT then
        remaining = YAOGUANG_LIMIT
    end
    return remaining
end

function LIMITYAOGUANG()
    for playindex = 1, 6, 1 do
        ReconcilePlayerProducedYaoguang(playindex)
        local remainingQuota = GetPlayerYaoguangRemainingProductionQuota(playindex)
        local playerName = "Player_" .. playindex
        if remainingQuota <= 0 and FLAGENYAOGUANG[playindex] == 1 then
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialAdvanceAircraftTech4", 0)
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialAdvanceAircraftTech4_Enhanced", 0)
            FLAGENYAOGUANG[playindex] = 0
            if RescueBlockedProductions_DoRescue then
                local blocked = {}
                blocked[tostring(FastHash("CelestialAdvanceAircraftTech4"))] = true
                blocked[tostring(FastHash("CelestialAdvanceAircraftTech4_Enhanced"))] = true
                RescueBlockedProductions_DoRescue(playerName, blocked)
            end
        elseif remainingQuota > 0 and FLAGENYAOGUANG[playindex] == 0 then
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialAdvanceAircraftTech4", 1)
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "CelestialAdvanceAircraftTech4_Enhanced", 1)
            FLAGENYAOGUANG[playindex] = 1
        end
    end
end

function GetPlayerGuardianTankCount(playindex)
    local savedCount = 0
    if g_UnitNameToUnitIndex ~= nil and UNITCOUNT ~= nil then
        local unitIndex = g_UnitNameToUnitIndex["AlliedAntiVehicleVehicleTech1"]
        if unitIndex ~= nil and UNITCOUNT[playindex] ~= nil then
            savedCount = tonumber(UNITCOUNT[playindex][unitIndex]) or 0
        end
    end
    local units, pendingCount = ObjectFindObjects(P[playindex], nil, FilterPlayerGuardianTank)
    pendingCount = tonumber(pendingCount) or 0
    return savedCount + pendingCount
end

function LIMITGUARDIANTANK()
    for playindex = 1, 6, 1 do
        local count = GetPlayerGuardianTankCount(playindex)
        local playerName = "Player_" .. playindex
        if count >= GUARDIAN_TANK_LIMIT and FLAGENGUARDIANTANK[playindex] == 1 then
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedAntiVehicleVehicleTech1", 0)
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedAntiVehicleVehicleTech1_Enhanced", 0)
            FLAGENGUARDIANTANK[playindex] = 0
            if RescueBlockedProductions_DoRescue then
                local blocked = {}
                blocked[tostring(FastHash("AlliedAntiVehicleVehicleTech1"))] = true
                blocked[tostring(FastHash("AlliedAntiVehicleVehicleTech1_Enhanced"))] = true
                RescueBlockedProductions_DoRescue(playerName, blocked)
            end
        elseif count < GUARDIAN_TANK_LIMIT and FLAGENGUARDIANTANK[playindex] == 0 then
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedAntiVehicleVehicleTech1", 1)
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, "AlliedAntiVehicleVehicleTech1_Enhanced", 1)
            FLAGENGUARDIANTANK[playindex] = 1
        end
    end
end

-- ===== 玩家退出/死亡后的小电份额转交 =====
-- 份额与“开局存在的玩家席位”挂钩，不与 MCV/额外基地挂钩；
-- 每个席位一份 = LIMITPOWERC + 1（全局统一按非神州电厂基础）。
function GetPowerSlotSideIndex(playerIndex)
    if playerIndex ~= nil and playerIndex <= 3 then
        return 7
    end
    return 8
end

function IsValidPowerSlotPlayerIndex(playerIndex)
    return playerIndex ~= nil and playerIndex >= 1 and playerIndex <= 6
end

-- 一个席位的份额：非神州 = LIMITPOWERC + 1（预设 1 座 + 可再建 LIMITPOWERC 座）；
-- 神州 = LIMITPOWERC（神州小电给钱更多，基础额度天生少一个，固有设计）。
function GetPowerSeatShare(seatIndex)
    if seatIndex ~= nil and g_PlayerSide ~= nil and g_PlayerSide[seatIndex] ~= nil then
        if g_PlayerSide[seatIndex] == 4 then
            return LIMITPOWERC
        end
        return LIMITPOWERC + 1
    end
    -- 阵营表还没就绪时按老判定：名下有非神州电厂/电厂蛋才算非神州席位。
    if P ~= nil and seatIndex ~= nil and P[seatIndex] ~= nil then
        local plants, plantCount = ObjectFindObjects(P[seatIndex], nil, FilterPowerPlantOrEggNotCelestial)
        if plantCount > 0 then
            return LIMITPOWERC + 1
        end
    end
    return LIMITPOWERC
end

-- 真实小电上限：把该玩家实际控制的每个席位的份额加起来（继承后跟着控制器走）。
-- 购买科技界面用它显示，显示值与实际限额永远同源。
function GetPlayerPowerPlantLimit(playerIndex)
    local limit = 0
    if g_PowerSlotPresent ~= nil and g_PowerSlotController ~= nil then
        for slotIndex = 1, 6, 1 do
            if g_PowerSlotPresent[slotIndex] == 1
                and g_PowerSlotController[slotIndex] == playerIndex then
                limit = limit + GetPowerSeatShare(slotIndex)
            end
        end
    end
    if limit < 1 then
        limit = GetPowerSeatShare(playerIndex)
    end
    return limit
end

-- 界面参照值：第 2 行「己方电厂最大数量」恒按非神州算，第 3 行「己方神州电厂最大数量」
-- 恒按神州算，与查看者是哪一方无关；份数按实际控制的席位算，所以继承后两行会一起变多。
function GetPlayerPowerPlantReferenceLimit(playerIndex, celestial)
    local slotCount = 0
    if g_PowerSlotPresent ~= nil and g_PowerSlotController ~= nil then
        for slotIndex = 1, 6, 1 do
            if g_PowerSlotPresent[slotIndex] == 1
                and g_PowerSlotController[slotIndex] == playerIndex then
                slotCount = slotCount + 1
            end
        end
    end
    if slotCount < 1 then
        slotCount = 1
    end
    if celestial == 1 then
        return slotCount * LIMITPOWERC
    end
    return slotCount * (LIMITPOWERC + 1)
end

-- 东风 DF41 建造上限：每控制一个玩家席位 1 辆 + 东风速递额外额度。
-- 继承队友会多控制一个席位，因此上限也 +1；与小电/阵营无关。
function GetPlayerDF41BuildLimit(playerIndex)
    local slotCount = 1
    if g_PowerSlotController ~= nil and g_PowerSlotPresent ~= nil then
        slotCount = 0
        for slotIndex = 1, 6, 1 do
            if g_PowerSlotPresent[slotIndex] == 1
                and g_PowerSlotController[slotIndex] == playerIndex then
                slotCount = slotCount + 1
            end
        end
        if slotCount < 1 then
            slotCount = 1
        end
    end
    local extraQuota = 0
    if g_HextechDF41ExtraQuota ~= nil then
        extraQuota = g_HextechDF41ExtraQuota[playerIndex]
        if extraQuota == true then
            extraQuota = 1
        end
        extraQuota = tonumber(extraQuota) or 0
    end
    return slotCount + extraQuota
end

-- 只把 Player_1..Player_6 认成有效归属；PlyrCivilian/PlyrCreeps 等返回 nil。
function GetPowerSlotOwnerIndex(unit)
    if unit == nil or not ObjectIsAlive(unit) then
        return nil
    end
    if ObjectPlayerScriptName == nil or g_PlayerNameToIndex == nil then
        return nil
    end
    local ownerName = ObjectPlayerScriptName(unit)
    if ownerName == nil then
        return nil
    end
    return g_PlayerNameToIndex[ownerName]
end

function IsPowerSlotAvailableBeneficiary(candidateIndex, vacatedIndex, sideIndex)
    return IsValidPowerSlotPlayerIndex(candidateIndex)
        and candidateIndex ~= vacatedIndex
        and g_PowerSlotPresent[candidateIndex] == 1
        and g_PowerSlotVacated[candidateIndex] ~= 1
        and GetPowerSlotSideIndex(candidateIndex) == sideIndex
end

function AddPowerSnapshotId(ids, seen, obj)
    if obj == nil or not ObjectIsAlive(obj) then
        return
    end
    local objectId = ObjectGetId(obj)
    if seen[objectId] ~= nil then
        return
    end
    seen[objectId] = 1
    local instanceId = nil
    if exObjectGetInstanceId ~= nil then
        instanceId = exObjectGetInstanceId(objectId)
    end
    tinsert(ids, { Id = objectId, InstanceId = instanceId })
end

-- 只快照指定玩家当前拥有的建筑/电厂；merge=true 时保留退出前的旧条目。
function SnapshotPowerPlayerStructures(playerIndex, merge)
    if playerIndex == nil or g_PowerSlotPresent[playerIndex] ~= 1
        or g_PowerSlotVacated[playerIndex] == 1 then
        return
    end
    local ids = {}
    local seen = {}
    local oldIds = g_PowerPlayerStructureIds[playerIndex]
    if merge and oldIds ~= nil then
        for i = 1, getn(oldIds), 1 do
            local entry = oldIds[i]
            if seen[entry.Id] == nil then
                seen[entry.Id] = 1
                tinsert(ids, entry)
            end
        end
    end
    if CopyPlayerRegisteredObjectSet ~= nil then
        local previous = nil
        if SetWorldBuilderThisPlayer ~= nil then
            previous = SetWorldBuilderThisPlayer(1)
        end
        local structures, count = CopyPlayerRegisteredObjectSet(
            "Player_" .. playerIndex, "STRUCTURES")
        if previous ~= nil then
            SetWorldBuilderThisPlayer(previous)
        end
        if structures ~= nil then
            for i = 1, count, 1 do
                AddPowerSnapshotId(ids, seen, structures[i])
            end
        end
    end
    -- 只有 P[i] 仍归原玩家时才按电厂过滤器补；否则会扫到继承者的电厂。
    if P ~= nil and P[playerIndex] ~= nil and ObjectIsAlive(P[playerIndex])
        and GetPowerSlotOwnerIndex(P[playerIndex]) == playerIndex then
        local plants, plantCount = ObjectFindObjects(
            P[playerIndex], nil, FilterAnyPowerPlantOrEgg)
        if plants ~= nil then
            for i = 1, plantCount, 1 do
                AddPowerSnapshotId(ids, seen, plants[i])
            end
        end
    end
    g_PowerPlayerStructureIds[playerIndex] = ids
end

function InitPowerSlotTransfers()
    if g_PowerSlotInitialized == 1 then
        return
    end
    if P == nil or g_PlayerNameToIndex == nil then
        return
    end
    for slotIndex = 1, 6, 1 do
        g_PowerSlotPresent[slotIndex] = 0
        g_PowerSlotController[slotIndex] = nil
        g_PowerSlotVacated[slotIndex] = 0
        g_PowerPlayerStructureIds[slotIndex] = {}
        g_PowerSlotDeathPending[slotIndex] = nil
        g_PowerSlotDeathScheduled[slotIndex] = nil
        -- P[i] 只在开局有对应玩家时存在；空位从开局就不参与份额。
        if P[slotIndex] ~= nil then
            g_PowerSlotPresent[slotIndex] = 1
            g_PowerSlotController[slotIndex] = slotIndex
        end
    end
    g_PowerSlotInitialized = 1
end

-- 把退出者当时控制的所有席位（含之前继承来的）一起交给新继承者。
function AssignPowerSlotController(vacatedIndex, beneficiaryIndex)
    for slotIndex = 1, 6, 1 do
        if g_PowerSlotController[slotIndex] == vacatedIndex then
            g_PowerSlotController[slotIndex] = beneficiaryIndex
        end
    end
    g_PowerSlotVacated[vacatedIndex] = 1
    g_PowerPlayerStructureIds[vacatedIndex] = {}
    g_PowerSlotDeathPending[vacatedIndex] = nil
    g_PowerSlotDeathScheduled[vacatedIndex] = nil
end

-- 资产被销毁或找不到继承者：这些席位不再贡献上限。
function ClearPowerSlotController(vacatedIndex)
    for slotIndex = 1, 6, 1 do
        if g_PowerSlotController[slotIndex] == vacatedIndex then
            g_PowerSlotController[slotIndex] = nil
        end
    end
    g_PowerSlotVacated[vacatedIndex] = 1
    g_PowerPlayerStructureIds[vacatedIndex] = {}
    g_PowerSlotDeathPending[vacatedIndex] = nil
    g_PowerSlotDeathScheduled[vacatedIndex] = nil
end

function FindPowerSlotBeneficiary(vacatedIndex)
    local sideIndex = GetPowerSlotSideIndex(vacatedIndex)

    -- 1. P[i] 当前归属
    if P ~= nil then
        local ownerIndex = GetPowerSlotOwnerIndex(P[vacatedIndex])
        if IsPowerSlotAvailableBeneficiary(ownerIndex, vacatedIndex, sideIndex) then
            return ownerIndex
        end
    end

    -- 2. wan[i] 当前归属
    if GetObjectByScriptName ~= nil then
        local wan = GetObjectByScriptName("wan" .. vacatedIndex)
        local ownerIndex = GetPowerSlotOwnerIndex(wan)
        if IsPowerSlotAvailableBeneficiary(ownerIndex, vacatedIndex, sideIndex) then
            return ownerIndex
        end
    end

    -- 3. 退出前建筑快照：这些建筑现在归谁，取数量最多的同侧玩家
    local snapshot = g_PowerPlayerStructureIds[vacatedIndex]
    if snapshot ~= nil and getn(snapshot) > 0 then
        local tally = {}
        for i = 1, getn(snapshot), 1 do
            local entry = snapshot[i]
            local obj = nil
            if GetObjectById ~= nil then
                obj = GetObjectById(entry.Id)
            end
            if obj ~= nil and ObjectIsAlive(obj) then
                local instanceMatches = true
                if entry.InstanceId ~= nil and exObjectGetInstanceId ~= nil then
                    instanceMatches = exObjectGetInstanceId(entry.Id) == entry.InstanceId
                end
                if instanceMatches then
                    local ownerIndex = GetPowerSlotOwnerIndex(obj)
                    if IsPowerSlotAvailableBeneficiary(ownerIndex, vacatedIndex, sideIndex) then
                        tally[ownerIndex] = (tally[ownerIndex] or 0) + 1
                    end
                end
            end
        end
        local bestIndex = nil
        local bestCount = 0
        for candidate = 1, 6, 1 do
            local candidateCount = tally[candidate] or 0
            if candidateCount > bestCount then
                bestCount = candidateCount
                bestIndex = candidate
            end
        end
        if bestIndex ~= nil then
            return bestIndex
        end
    end

    -- 4. 同侧只剩一名尚未退出的队友时，直接交给他
    local teammateCount = 0
    local lastTeammateIndex = nil
    for candidate = 1, 6, 1 do
        if candidate ~= vacatedIndex
            and GetPowerSlotSideIndex(candidate) == sideIndex
            and g_PowerSlotPresent[candidate] == 1
            and g_PowerSlotVacated[candidate] ~= 1 then
            teammateCount = teammateCount + 1
            lastTeammateIndex = candidate
        end
    end
    if teammateCount == 1 then
        return lastTeammateIndex
    end

    return nil
end

-- ===== 退出玩家资产转交：只在该席位第一次判定退出时执行一次 =====
function TransferRuneCountArray(sourceTable, fromIndex, toIndex)
    if sourceTable == nil then
        return
    end
    local fromValues = sourceTable[fromIndex]
    if fromValues == nil then
        return
    end
    local toValues = sourceTable[toIndex]
    if toValues == nil then
        toValues = {}
        sourceTable[toIndex] = toValues
    end
    for i = 1, getn(fromValues), 1 do
        toValues[i] = (toValues[i] or 0) + (fromValues[i] or 0)
        fromValues[i] = 0
    end
end

function TransferRuneNamedCounts(sourceTable, fromIndex, toIndex)
    if sourceTable == nil then
        return
    end
    local fromValues = sourceTable[fromIndex]
    if fromValues == nil then
        return
    end
    local toValues = sourceTable[toIndex]
    if toValues == nil then
        toValues = {}
        sourceTable[toIndex] = toValues
    end
    for key, value in fromValues do
        if type(value) == "number" then
            toValues[key] = (toValues[key] or 0) + value
            fromValues[key] = 0
        end
    end
end

function TransferPlayerUnitPools(fromIndex, toIndex)
    if UNITCOUNT == nil or UNITCOUNT[fromIndex] == nil or UNITCOUNT[toIndex] == nil then
        return
    end
    local maxUnitIndex = 200
    if unitcountmax ~= nil then
        maxUnitIndex = unitcountmax
    end
    for unitIndex = 1, maxUnitIndex, 1 do
        local count = tonumber(UNITCOUNT[fromIndex][unitIndex]) or 0
        if count > 0 then
            UNITCOUNT[toIndex][unitIndex] =
                (tonumber(UNITCOUNT[toIndex][unitIndex]) or 0) + count
            UNITCOUNT[fromIndex][unitIndex] = 0
        end
        if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[fromIndex] ~= nil
            and CRATEUNITCOUNT[toIndex] ~= nil then
            local crateCount = tonumber(CRATEUNITCOUNT[fromIndex][unitIndex]) or 0
            if crateCount > 0 then
                CRATEUNITCOUNT[toIndex][unitIndex] =
                    (tonumber(CRATEUNITCOUNT[toIndex][unitIndex]) or 0) + crateCount
                CRATEUNITCOUNT[fromIndex][unitIndex] = 0
            end
        end
    end
    -- 摇光产量计数跟单位池一起转，保持限造口径。
    if g_PlayerProducedYaoguangCount ~= nil then
        local produced = tonumber(g_PlayerProducedYaoguangCount[fromIndex]) or 0
        if produced > 0 then
            g_PlayerProducedYaoguangCount[toIndex] =
                (tonumber(g_PlayerProducedYaoguangCount[toIndex]) or 0) + produced
            g_PlayerProducedYaoguangCount[fromIndex] = 0
            if ReconcilePlayerProducedYaoguang ~= nil then
                ReconcilePlayerProducedYaoguang(toIndex)
            end
        end
    end
    if ANYUNITCOUNT ~= nil then
        ANYUNITCOUNT[toIndex] = (tonumber(ANYUNITCOUNT[toIndex]) or 0)
            + (tonumber(ANYUNITCOUNT[fromIndex]) or 0)
        ANYUNITCOUNT[fromIndex] = 0
    end
    -- 东风速递额度按数值累加：继承队友的额外导弹上限。
    if g_HextechDF41ExtraQuota ~= nil then
        local fromExtra = g_HextechDF41ExtraQuota[fromIndex]
        if fromExtra == true then
            fromExtra = 1
        end
        fromExtra = tonumber(fromExtra) or 0
        if fromExtra > 0 then
            local toExtra = g_HextechDF41ExtraQuota[toIndex]
            if toExtra == true then
                toExtra = 1
            end
            g_HextechDF41ExtraQuota[toIndex] =
                (tonumber(toExtra) or 0) + fromExtra
            g_HextechDF41ExtraQuota[fromIndex] = nil
        end
    end
    -- 抽卡模式的建造余额也属于单位资源。
    if g_PureDrawQuota ~= nil then
        g_PureDrawQuota[toIndex] = (g_PureDrawQuota[toIndex] or 0)
            + (g_PureDrawQuota[fromIndex] or 0)
        g_PureDrawQuota[fromIndex] = 0
    end
    if g_PureDrawT4ShipUnlocked ~= nil and g_PureDrawT4ShipUnlocked[fromIndex] then
        g_PureDrawT4ShipUnlocked[toIndex] = true
    end
    if PureDrawReapplyPlayerQuota ~= nil then
        PureDrawReapplyPlayerQuota(toIndex)
    end
end

function ZeroPlayerUnitPools(fromIndex)
    if UNITCOUNT == nil or UNITCOUNT[fromIndex] == nil then
        return
    end
    local maxUnitIndex = 200
    if unitcountmax ~= nil then
        maxUnitIndex = unitcountmax
    end
    for unitIndex = 1, maxUnitIndex, 1 do
        UNITCOUNT[fromIndex][unitIndex] = 0
        if CRATEUNITCOUNT ~= nil and CRATEUNITCOUNT[fromIndex] ~= nil then
            CRATEUNITCOUNT[fromIndex][unitIndex] = 0
        end
    end
    if g_PlayerProducedYaoguangCount ~= nil then
        g_PlayerProducedYaoguangCount[fromIndex] = 0
    end
    if ANYUNITCOUNT ~= nil then
        ANYUNITCOUNT[fromIndex] = 0
    end
    if g_HextechDF41ExtraQuota ~= nil then
        g_HextechDF41ExtraQuota[fromIndex] = nil
    end
    if g_PureDrawQuota ~= nil then
        g_PureDrawQuota[fromIndex] = 0
    end
end

function TransferPlayerRuneState(fromIndex, toIndex)
    if HextechRune == nil then
        return
    end
    if HextechRune.TransferPlayerSlotRunes ~= nil then
        HextechRune:TransferPlayerSlotRunes(fromIndex, toIndex)
    end
    -- 各符文自带的按玩家台账：能加的加，能搬的搬。
    if g_HextechRecycleBonus ~= nil then
        g_HextechRecycleBonus[toIndex] = (g_HextechRecycleBonus[toIndex] or 0)
            + (g_HextechRecycleBonus[fromIndex] or 0)
        g_HextechRecycleBonus[fromIndex] = 0
    end
    if g_HextechOblivionBombCharges ~= nil then
        g_HextechOblivionBombCharges[toIndex] =
            (g_HextechOblivionBombCharges[toIndex] or 0)
            + (g_HextechOblivionBombCharges[fromIndex] or 0)
        g_HextechOblivionBombCharges[fromIndex] = 0
        if HextechRune.RefreshOblivionBombHint ~= nil then
            HextechRune:RefreshOblivionBombHint(toIndex)
        end
    end
    if g_HextechOilDerrickSerial ~= nil then
        g_HextechOilDerrickSerial[toIndex] =
            (g_HextechOilDerrickSerial[toIndex] or 0)
            + (g_HextechOilDerrickSerial[fromIndex] or 0)
        g_HextechOilDerrickSerial[fromIndex] = 0
    end
    if g_HextechTowerDefenseExpert ~= nil and g_HextechTowerDefenseExpert[fromIndex] then
        g_HextechTowerDefenseExpert[toIndex] = true
        g_HextechTowerDefenseExpert[fromIndex] = false
    end
    if g_HextechBuyTwoGetOne ~= nil and g_HextechBuyTwoGetOne[fromIndex] ~= nil then
        if g_HextechBuyTwoGetOne[toIndex] == nil then
            g_HextechBuyTwoGetOne[toIndex] = {}
        end
        local fromStates = g_HextechBuyTwoGetOne[fromIndex]
        local toStates = g_HextechBuyTwoGetOne[toIndex]
        for i = 1, getn(fromStates), 1 do
            tinsert(toStates, fromStates[i])
        end
        g_HextechBuyTwoGetOne[fromIndex] = nil
    end
    if HextechRune.WarEfficiencyPending ~= nil then
        TransferRuneCountArray(HextechRune.WarEfficiencyPending, fromIndex, toIndex)
    end
    if HextechRune.WarEfficiencyActive ~= nil then
        TransferRuneCountArray(HextechRune.WarEfficiencyActive, fromIndex, toIndex)
    end
    if HextechRune.WarEfficiencyApplied ~= nil
        and HextechRune.WarEfficiencyApplied[fromIndex] ~= nil then
        if HextechRune.WarEfficiencyApplied[toIndex] == nil then
            HextechRune.WarEfficiencyApplied[toIndex] = {}
        end
        local fromApplied = HextechRune.WarEfficiencyApplied[fromIndex]
        local toApplied = HextechRune.WarEfficiencyApplied[toIndex]
        for unitType, appliedUnits in fromApplied do
            if toApplied[unitType] == nil then
                toApplied[unitType] = {}
            end
            for objectId, applied in appliedUnits do
                toApplied[unitType][objectId] = applied
            end
        end
        HextechRune.WarEfficiencyApplied[fromIndex] = nil
    end
    if HextechRune.AscensionStacks ~= nil then
        HextechRune.AscensionStacks[toIndex] =
            (HextechRune.AscensionStacks[toIndex] or 0)
            + (HextechRune.AscensionStacks[fromIndex] or 0)
        HextechRune.AscensionStacks[fromIndex] = nil
    end
    if HextechRune.AscensionBonusCounts ~= nil then
        TransferRuneNamedCounts(HextechRune.AscensionBonusCounts, fromIndex, toIndex)
    end
    if HextechRune.UltimateCreatureStates ~= nil then
        if HextechRune.UltimateCreatureStates[toIndex] == nil then
            HextechRune.UltimateCreatureStates[toIndex] =
                HextechRune.UltimateCreatureStates[fromIndex]
        end
        HextechRune.UltimateCreatureStates[fromIndex] = nil
    end
    if HextechRune.RoundSlots ~= nil then
        if HextechRune.RoundSlots[toIndex] == nil then
            HextechRune.RoundSlots[toIndex] = HextechRune.RoundSlots[fromIndex]
        end
        HextechRune.RoundSlots[fromIndex] = nil
    end
    if HextechRune.FiveThunderState ~= nil
        and HextechRune.FiveThunderState[fromIndex] ~= nil then
        if HextechRune.FiveThunderState[toIndex] == nil then
            HextechRune.FiveThunderState[toIndex] = HextechRune.FiveThunderState[fromIndex]
        end
        HextechRune.FiveThunderState[fromIndex] = nil
    end
    -- 战场上已经登记的旧单位改认新主人，下一轮才会把继承来的符文也挂上去。
    if HextechRune.BattleUnitAssignments ~= nil then
        for objectId, assignment in HextechRune.BattleUnitAssignments do
            if assignment.PlayerIndex == fromIndex then
                assignment.PlayerIndex = toIndex
            end
        end
    end
    -- 继承来的替换型符文也要作用到继承者的登神 / 买二送一目标上。
    if HextechRune.RemapReplacedRuneTargets ~= nil then
        HextechRune:RemapReplacedRuneTargets(toIndex)
    end
end

function ClearPlayerRuneState(fromIndex)
    if HextechRune == nil then
        return
    end
    if HextechRune.ClearPlayerSlotRunes ~= nil then
        HextechRune:ClearPlayerSlotRunes(fromIndex)
    end
    if g_HextechRecycleBonus ~= nil then
        g_HextechRecycleBonus[fromIndex] = 0
    end
    if g_HextechOblivionBombCharges ~= nil then
        g_HextechOblivionBombCharges[fromIndex] = 0
    end
    if g_HextechUltimateRefreshCount ~= nil then
        g_HextechUltimateRefreshCount[fromIndex] = 0
    end
    if g_HextechBuyTwoGetOne ~= nil then
        g_HextechBuyTwoGetOne[fromIndex] = nil
    end
    if HextechRune.WarEfficiencyPending ~= nil then
        HextechRune.WarEfficiencyPending[fromIndex] = nil
        HextechRune.WarEfficiencyActive[fromIndex] = nil
        HextechRune.WarEfficiencyApplied[fromIndex] = nil
    end
    if HextechRune.AscensionStacks ~= nil then
        HextechRune.AscensionStacks[fromIndex] = nil
        HextechRune.AscensionBonusCounts[fromIndex] = nil
    end
    if HextechRune.UltimateCreatureStates ~= nil then
        HextechRune.UltimateCreatureStates[fromIndex] = nil
    end
    if HextechRune.RoundSlots ~= nil then
        HextechRune.RoundSlots[fromIndex] = nil
    end
    if HextechRune.FiveThunderState ~= nil then
        HextechRune.FiveThunderState[fromIndex] = nil
    end
end

function TransferPlayerAssets(vacatedIndex, beneficiaryIndex)
    if g_PowerSlotVacated[vacatedIndex] == 1 then
        return
    end
    if beneficiaryIndex == nil or beneficiaryIndex == vacatedIndex then
        return
    end
    g_PowerSlotVacated[vacatedIndex] = 1
    -- 先保证小电份额一定跟着走；单位/符文随后接管。
    AssignPowerSlotController(vacatedIndex, beneficiaryIndex)
    TransferPlayerUnitPools(vacatedIndex, beneficiaryIndex)
    TransferPlayerRuneState(vacatedIndex, beneficiaryIndex)
end

function LosePlayerAssets(vacatedIndex)
    if g_PowerSlotVacated[vacatedIndex] == 1 then
        return
    end
    g_PowerSlotVacated[vacatedIndex] = 1
    ClearPowerSlotController(vacatedIndex)
    ZeroPlayerUnitPools(vacatedIndex)
    ClearPlayerRuneState(vacatedIndex)
end

-- 法术书死亡事件：先快照，再隔几秒复查一轮继承者；不做周期扫描。
function OnPlayerSpellBookDied(ownerPlayerName, dyingObjId)
    if g_PowerSlotInitialized ~= 1 then
        InitPowerSlotTransfers()
    end
    if g_PowerSlotInitialized ~= 1 then
        return
    end
    local playerIndex = nil
    if g_PlayerSpellBookId ~= nil and dyingObjId ~= nil then
        for i = 1, 6, 1 do
            if g_PlayerSpellBookId[i] == dyingObjId then
                playerIndex = i
                break
            end
        end
    end
    if playerIndex == nil and ownerPlayerName ~= nil
        and g_PlayerNameToIndex ~= nil then
        playerIndex = g_PlayerNameToIndex[ownerPlayerName]
    end
    if not IsValidPowerSlotPlayerIndex(playerIndex)
        or g_PowerSlotPresent[playerIndex] ~= 1
        or g_PowerSlotVacated[playerIndex] == 1 then
        return
    end
    g_PowerSlotDeathPending[playerIndex] = 1
    -- 死亡当帧先记下建筑/电厂，后面按它们的新归属找继承者。
    SnapshotPowerPlayerStructures(playerIndex, true)
    -- 引擎转交可能是立刻完成的：先试一次，拿到就当场继承。
    local beneficiaryIndex = FindPowerSlotBeneficiary(playerIndex)
    if beneficiaryIndex ~= nil then
        TransferPlayerAssets(playerIndex, beneficiaryIndex)
        return
    end
    -- 没拿到就隔几秒复查一轮；不排周期扫描。
    if g_PowerSlotDeathScheduled[playerIndex] ~= 1 then
        g_PowerSlotDeathScheduled[playerIndex] = 1
        if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
            SchedulerModule.delay_call(ProcessPowerSlotDeath,
                g_PowerDeathRecheckFrames, { playerIndex })
        else
            ProcessPowerSlotDeath(playerIndex)
        end
    end
end

-- 事件后复查：能确定继承者就转交，否则按“无人继承”让资产消失。
function ProcessPowerSlotDeath(playerIndex)
    g_PowerSlotDeathScheduled[playerIndex] = nil
    if g_PowerSlotDeathPending[playerIndex] ~= 1
        or g_PowerSlotVacated[playerIndex] == 1 then
        g_PowerSlotDeathPending[playerIndex] = nil
        return
    end
    local beneficiaryIndex = FindPowerSlotBeneficiary(playerIndex)
    if beneficiaryIndex ~= nil then
        TransferPlayerAssets(playerIndex, beneficiaryIndex)
    else
        LosePlayerAssets(playerIndex)
    end
    g_PowerSlotDeathPending[playerIndex] = nil
end

function LIMITPOWER()
    -- MONEYINI/LIMITACT 的执行顺序早于 UNITCOUNTERINI 时，P 尚未初始化。
    if P == nil then
        return
    end

    InitPowerSlotTransfers()

    for playindex = 1, 6, 1 do
        g_CachedPlayersPowerPlantLimit[playindex] = 0
    end

    if g_PowerSlotInitialized == 1 then
        -- 每个开局存在的席位算一份；退出后份额跟着实际继承者走。
        -- 每份按席位阵营给（神州少一个）：见 GetPowerSeatShare。
        -- 每帧都按当前 LIMITPOWERC 重算：推塔 +2 后，继承来的席位也同步 +2。
        for slotIndex = 1, 6, 1 do
            if g_PowerSlotPresent[slotIndex] == 1 then
                local controllerIndex = g_PowerSlotController[slotIndex]
                if IsValidPowerSlotPlayerIndex(controllerIndex) then
                    g_CachedPlayersPowerPlantLimit[controllerIndex] =
                        (g_CachedPlayersPowerPlantLimit[controllerIndex] or 0)
                        + GetPowerSeatShare(slotIndex)
                end
            end
        end
    else
        -- P 或 g_PlayerNameToIndex 尚未就绪：先按活着的 P 席位给临时上限，避免开局锁死。
        for playindex = 1, 6, 1 do
            if P[playindex] ~= nil and ObjectIsAlive(P[playindex]) then
                g_CachedPlayersPowerPlantLimit[playindex] = GetPowerSeatShare(playindex)
            end
        end
    end
    for playindex = 1, 6, 1 do
        local currentLimit = g_CachedPlayersPowerPlantLimit[playindex] or 0
        local Power, count = ObjectFindObjects(P[playindex], nil, FilterAnyPowerPlantOrEgg)
        if Power ~= nil then
            if count >= currentLimit and FLAGENPOWER[playindex] == 1 then
                --exMessageAppendToMessageArea("LIMLT")
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "alliedpowerplant", 0)
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "celestialpowerplant", 0)
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "SovietPowerPlant", 0)
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "japanpowerplantegg", 0)
                FLAGENPOWER[playindex] = 0
            elseif count < currentLimit and FLAGENPOWER[playindex] == 0 then
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "alliedpowerplant", 1)
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "celestialpowerplant", 1)
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "SovietPowerPlant", 1)
                ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", "Player_" .. playindex, "japanpowerplantegg", 1)
                FLAGENPOWER[playindex] = 1
                --exMessageAppendToMessageArea("RE")
            end
        end
    end
    LIMITYAOGUANG()
    -- 保留守护者坦克限造 3 个的完整实现，当前版本取消数量限制；需要恢复时取消下一行注释。
    -- LIMITGUARDIANTANK()
end
