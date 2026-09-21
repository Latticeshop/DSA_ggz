LIMITPOWERC = 4
FLAGENPOWER = {}
for i = 1, 6, 1 do
    FLAGENPOWER[i] = 1
end

g_CachedPlayersPowerPlantLimit = {}

YAOGUANG_LIMIT = 3
FLAGENYAOGUANG = { 1, 1, 1, 1, 1, 1 }
-- 只记录通过玩家生产建筑实际造出、且当前仍保留在单位池中的摇光。
-- 箱子、海克斯及其他脚本赠送来源仍进入 UNITCOUNT，但不占用限造额度。
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

function LIMITPOWER()
    -- MONEYINI/LIMITACT 的执行顺序早于 UNITCOUNTERINI 时，P 尚未初始化。
    if P == nil then
        return
    end

    for playindex = 1, 6, 1 do
        g_CachedPlayersPowerPlantLimit[playindex] = 0
        if ObjectIsAlive(P[playindex]) then
            -- 非神州阵营的玩家能多造一个电厂
            local power, count = ObjectFindObjects(P[playindex], nil, FilterPowerPlantOrEggNotCelestial)
            if count > 0 then
                g_CachedPlayersPowerPlantLimit[playindex] = 1
            end
        end
    end
    -- g_PlayerNameToIndex 这个表在 lua\GAME\BasicVar1.lua 里面
    -- 此时可能还没有初始化
    if g_PlayerNameToIndex ~= nil then
        for playindex = 1, 6, 1 do
            if ObjectIsAlive(P[playindex]) then
                -- 假如有玩家继承了另一位玩家的基地，那这个玩家的电厂上限也要继承过去
                local actualOwner = ObjectPlayerScriptName(P[playindex])
                local actualOwnerIndex = nil
                if actualOwner ~= nil then
                    actualOwnerIndex = g_PlayerNameToIndex[actualOwner]
                end
                if actualOwnerIndex == nil then
                    -- 尝试从另外的参考单位判定
                    local ref = GetObjectByScriptName("wan" .. playindex)
                    if ref ~= nil then
                        actualOwner = ObjectPlayerScriptName(ref)
                        if actualOwner ~= nil then
                            actualOwnerIndex = g_PlayerNameToIndex[actualOwner]
                        end
                    end
                end
                if actualOwnerIndex ~= nil then
                    local currentCount = g_CachedPlayersPowerPlantLimit[actualOwnerIndex]
                    local newCount = currentCount + LIMITPOWERC
                    g_CachedPlayersPowerPlantLimit[actualOwnerIndex] = newCount
                end
            end
        end
    end
    for playindex = 1, 6, 1 do
        local currentLimit = g_CachedPlayersPowerPlantLimit[playindex]
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
