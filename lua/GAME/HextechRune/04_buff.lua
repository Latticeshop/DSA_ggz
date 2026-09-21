-- 海克斯符文系统：首批可实测效果。

HextechRune = HextechRune or {}

HextechRune.UnitTypeFilters = {
    infantry = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "INFANTRY",
        Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS"
    }),
    vehicle = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "VEHICLE HUGE_VEHICLE",
        Exclude = "STRUCTURE AIRCRAFT SHIP DEBRIS"
    }),
    aircraft = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "AIRCRAFT",
        Exclude = "STRUCTURE DEBRIS"
    }),
    navy = CreateObjectFilter({
        Rule = "ANY", Relationship = "SAME_PLAYER", Include = "SHIP",
        Exclude = "STRUCTURE DEBRIS"
    }),
}
HextechRune.UnitTypeOrder = { "infantry", "vehicle", "aircraft", "navy" }
-- 与缩小模式一致，持续时间覆盖整场战斗；同一单位的同一符文只加载一次。
HextechRune.PersistentBuffDuration = 9999
-- 以战斗单位 objectId 为键，记录该单位按单位池配额归属的玩家及已加载符文。
-- Unit 句柄同时用于识别引擎复用 objectId 的情况。
HextechRune.BattleUnitAssignments = HextechRune.BattleUnitAssignments or {}

if not g_HextechDamageX125Modifier then
    g_HextechDamageX125Modifier = exAttributeModifierCreate({ DAMAGE_MULT = 1.25 }, 1)
end
if not g_HextechSpeedX125Modifier then
    g_HextechSpeedX125Modifier = exAttributeModifierCreate({ SPEED = 1.25 }, 1)
end
if not g_HextechRateOfFireX125Modifier then
    g_HextechRateOfFireX125Modifier = exAttributeModifierCreate({ RATE_OF_FIRE = 1.25 }, 1)
end
if not g_HextechRangeX115Modifier then
    g_HextechRangeX115Modifier = exAttributeModifierCreate({ RANGE = 1.15 }, 1)
end
if not g_HextechRangeX125Modifier then
    g_HextechRangeX125Modifier = exAttributeModifierCreate({ RANGE = 1.25 }, 1)
end
if not g_HextechRangeX135Modifier then
    g_HextechRangeX135Modifier = exAttributeModifierCreate({ RANGE = 1.35 }, 1)
end

g_HextechRecycleBonus = g_HextechRecycleBonus or { 0, 0, 0, 0, 0, 0 }
g_HextechBuyTwoGetOne = g_HextechBuyTwoGetOne or {}
g_HextechOilDerrickSerial = g_HextechOilDerrickSerial or { 0, 0, 0, 0, 0, 0 }

-- 在现有经济倍率/苏联大生产修正之后叠加玩家自己的破烂王倍率。
if HextechRune_BaseGetRecycleRate == nil and GetRecycleRate ~= nil then
    HextechRune_BaseGetRecycleRate = GetRecycleRate
    function GetRecycleRate(playerIndex)
        local baseRate = HextechRune_BaseGetRecycleRate(playerIndex)
        return baseRate * (1 + (g_HextechRecycleBonus[playerIndex] or 0))
    end
end

function HextechRune:TestAlert(message)
    _ALERT("[海克斯测试] " .. message)
end

function HextechRune:GetRuneTestValue(rune)
    if rune.Effect == "damage" then
        return "伤害×1.25"
    elseif rune.Effect == "rate_of_fire" then
        return "射速×1.25"
    elseif rune.Effect == "speed" then
        return "速度×1.25"
    elseif rune.Effect == "range_silver" then
        return "射程×1.15"
    elseif rune.Effect == "range_gold" then
        return "射程×1.25"
    elseif rune.Effect == "range_prismatic" then
        return "射程×1.35"
    elseif rune.Effect == "infinite_ammo" then
        return "武器槽1~5弹药=100000"
    end
    return rune.Effect or "未知效果"
end

function HextechRune:GetPlayerHomeSpawnPosition(playerIndex, forwardOffset, sideOffset)
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = 1
    if PureDrawGetQuotaDisplayDirection ~= nil then
        direction = PureDrawGetQuotaDisplayDirection(playerIndex)
    end
    return {
        X = p[1] + direction * forwardOffset,
        Y = p[2] + sideOffset,
        Z = p[3],
    }
end

function HextechRune:MarkNextSpawnAsKnownPureDrawUnit()
    local nextObjectId = GetNextObjectId()
    if g_PureDrawScriptCreatedUnitIds ~= nil then
        g_PureDrawScriptCreatedUnitIds[nextObjectId] = true
    end
    return nextObjectId
end

function HextechRune:GrantYaoguang(playerIndex)
    local nextObjectId = self:MarkNextSpawnAsKnownPureDrawUnit()
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", "",
        "CelestialAdvanceAircraftTech4",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex),
        self:GetPlayerHomeSpawnPosition(playerIndex, 120, 80), 0)
    self:TestAlert(format("P%d 穿云定海：已在基地生成摇光，objectId=%s，等待系统回收进单位池",
        playerIndex, tostring(nextObjectId)))
end

function HextechRune:GrantOilDerricks(playerIndex)
    local teamName = format("Player_%d/teamPlayer_%d", playerIndex, playerIndex)
    g_HextechOilDerrickSerial[playerIndex] = g_HextechOilDerrickSerial[playerIndex] + 1
    local serial = g_HextechOilDerrickSerial[playerIndex]
    for i = 1, 2, 1 do
        local sideOffset = -170
        if i == 2 then
            sideOffset = 170
        end
        ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION",
            format("HextechOilDerrick_%d_%d_%d", playerIndex, serial, i),
            "oilderrick", teamName,
            self:GetPlayerHomeSpawnPosition(playerIndex, 180, sideOffset), 0)
    end
    self:TestAlert(format("P%d 石油王：已在基地生成2个油井，地编ID=oilderrick", playerIndex))
end

function HextechRune:EnableBuyTwoGetOne(playerIndex, rune)
    if g_HextechBuyTwoGetOne[playerIndex] == nil then
        g_HextechBuyTwoGetOne[playerIndex] = {}
    end
    tinsert(g_HextechBuyTwoGetOne[playerIndex], {
        UnitIndex = rune.TargetUnitIndex,
        UnitType = rune.TargetUnitType,
        UnitName = rune.TargetUnitName,
        Progress = 0,
        RuneInstanceId = self:GetRuneEffectInstanceId(rune),
    })
    self:TestAlert(format("P%d 买二送一：目标=%s，unitIndex=%s，当前进度=0/2",
        playerIndex, rune.TargetUnitName or rune.TargetUnitType or "?",
        tostring(rune.TargetUnitIndex)))
end

-- 在 unitgetcountanddelet 的真实单位回收计数后调用，参考狂热武士“每二赠一”。
function HextechRune:OnPlayerUnitCollected(playerIndex, unitIndex)
    local states = g_HextechBuyTwoGetOne[playerIndex]
    if states == nil then
        return
    end
    for i = 1, getn(states), 1 do
        local state = states[i]
        if state.UnitIndex == unitIndex then
            state.Progress = state.Progress + 1
            if state.Progress >= 2 then
                state.Progress = 0
                ANYUNITCOUNT[playerIndex] = ANYUNITCOUNT[playerIndex] + 1
                UNITCOUNT[playerIndex][unitIndex] = UNITCOUNT[playerIndex][unitIndex] + 1
                self:TestAlert(format("P%d 买二送一（%s）：累计2个，已向单位池赠送1个",
                    playerIndex, state.UnitName or state.UnitType or "?"))
            else
                self:TestAlert(format("P%d 买二送一（%s）：当前进度1/2",
                    playerIndex, state.UnitName or state.UnitType or "?"))
            end
        end
    end
end

function HextechRune:GetAvailableUnitTypes(playerIndex)
    -- 每个兵种版本都是独立符文，即使玩家当前尚未生产该兵种也可选择，
    -- 让效果覆盖之后生产/刷新的单位。禁海配置下仅排除海军版本。
    local result = { "infantry", "vehicle", "aircraft" }
    if g_DisableSeaArmy ~= 1 then
        tinsert(result, "navy")
    end
    return result
end

-- 构建阵营战斗单位的兵种查找表。战斗复制体属于 P7/P8，不能再按 Player_1..6 所有权扫描。
function HextechRune:BuildSideUnitTypeLookup(sideIndex)
    local result = {}
    if P == nil or P[sideIndex] == nil then
        return result
    end
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local units, count = ObjectFindObjects(P[sideIndex], nil, self.UnitTypeFilters[unitType])
        local lookup = {}
        for i = 1, count, 1 do
            lookup[ObjectGetId(units[i])] = true
        end
        result[unitType] = lookup
    end
    return result
end

function HextechRune:IsUnitInRuneType(unit, rune, typeLookup)
    if rune.UnitType == nil or typeLookup[rune.UnitType] == nil then
        return false
    end
    return typeLookup[rune.UnitType][ObjectGetId(unit)] == true
end

function HextechRune:ApplyInfiniteAmmoToUnit(unit)
    -- 与空军元帅苏霍伊脚本相同：武器槽 1~5 写入 100000 弹药。
    for weaponIndex = 1, 5, 1 do
        ObjectSetWeaponSetUpdateWeaponCurrentAmmoCount(unit, 1, 1, weaponIndex, 100000)
    end
end

-- 给一只已经按单位池配额分配到玩家的战斗单位加载一个持续型符文。
-- 返回 true 表示兵种匹配且本次确实执行了效果。
function HextechRune:ApplyPersistentRuneToUnit(playerIndex, rune, unit, typeLookup)
    if not self:IsUnitInRuneType(unit, rune, typeLookup) then
        return false
    end
    if rune.Effect == "damage" then
        ObjectLoadAttributeModifier(unit, g_HextechDamageX125Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "rate_of_fire" then
        ObjectLoadAttributeModifier(unit, g_HextechRateOfFireX125Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "speed" then
        ObjectLoadAttributeModifier(unit, g_HextechSpeedX125Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "range_silver" then
        ObjectLoadAttributeModifier(unit, g_HextechRangeX115Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "range_gold" then
        ObjectLoadAttributeModifier(unit, g_HextechRangeX125Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "range_prismatic" then
        ObjectLoadAttributeModifier(unit, g_HextechRangeX135Modifier, self.PersistentBuffDuration)
    elseif rune.Effect == "infinite_ammo" then
        self:ApplyInfiniteAmmoToUnit(unit)
    else
        return false
    end
    return true
end

function HextechRune:IsCurrentAssignment(unit, assignment)
    return assignment ~= nil and assignment.Unit == unit and ObjectIsAlive(unit)
end

-- 对一个阵营仅收集尚未登记的新单位，再按“具体单位类型 + 玩家单位池数量”切片。
-- 即使玩家没有持续符文也会登记归属，防止幸存单位在下一次扫描时被当作新单位。
function HextechRune:AssignNewSideBattleUnits(sideIndex, firstPlayerIndex, lastPlayerIndex)
    local newlyAssigned = {}
    if P == nil or P[sideIndex] == nil then
        return newlyAssigned
    end
    for unitIndex = 1, unitcountmax, 1 do
        local units, count = ObjectFindObjects(P[sideIndex], nil, FilterLIST[unitIndex])
        local newUnits = {}
        for i = 1, count, 1 do
            local unit = units[i]
            local objectId = ObjectGetId(unit)
            local assignment = self.BattleUnitAssignments[objectId]
            if not self:IsCurrentAssignment(unit, assignment) then
                tinsert(newUnits, unit)
            end
        end

        local cursor = 1
        for playerIndex = firstPlayerIndex, lastPlayerIndex, 1 do
            local quota = UNITCOUNT[playerIndex][unitIndex] or 0
            local last = cursor + quota - 1
            if last > getn(newUnits) then
                last = getn(newUnits)
            end
            for unitPosition = cursor, last, 1 do
                local unit = newUnits[unitPosition]
                local assignment = {
                    Unit = unit,
                    PlayerIndex = playerIndex,
                    AppliedRunes = {},
                }
                self.BattleUnitAssignments[ObjectGetId(unit)] = assignment
                tinsert(newlyAssigned, assignment)
            end
            cursor = cursor + quota
        end

        -- 超出三名玩家当前总配额的对象也标成“无归属”，避免以后重复纳入。
        for unitPosition = cursor, getn(newUnits), 1 do
            local unit = newUnits[unitPosition]
            local assignment = {
                Unit = unit,
                PlayerIndex = 0,
                AppliedRunes = {},
            }
            self.BattleUnitAssignments[ObjectGetId(unit)] = assignment
            tinsert(newlyAssigned, assignment)
        end
    end
    return newlyAssigned
end

function HextechRune:AssignNewBattleUnits()
    local result = {}
    if UNITCOUNT == nil or FilterLIST == nil or unitcountmax == nil then
        return result
    end
    local left = self:AssignNewSideBattleUnits(7, 1, 3)
    local right = self:AssignNewSideBattleUnits(8, 4, 6)
    for i = 1, getn(left), 1 do
        tinsert(result, left[i])
    end
    for i = 1, getn(right), 1 do
        tinsert(result, right[i])
    end
    return result
end

function HextechRune:BuildAllBattleUnitTypeLookup()
    local left = self:BuildSideUnitTypeLookup(7)
    local right = self:BuildSideUnitTypeLookup(8)
    local result = {}
    for typeIndex = 1, getn(self.UnitTypeOrder), 1 do
        local unitType = self.UnitTypeOrder[typeIndex]
        local lookup = {}
        if left[unitType] ~= nil then
            for objectId, value in left[unitType] do
                lookup[objectId] = value
            end
        end
        if right[unitType] ~= nil then
            for objectId, value in right[unitType] do
                lookup[objectId] = value
            end
        end
        result[unitType] = lookup
    end
    return result
end

-- AppliedRunes 是“单位 + 独立符文”级标记，阻止幸存单位跨回合重复叠加 Buff。
function HextechRune:ApplyRuneToAssignment(rune, assignment, typeLookup)
    local effectInstanceId = self:GetRuneEffectInstanceId(rune)
    if assignment.AppliedRunes[effectInstanceId] then
        return false
    end
    if self:ApplyPersistentRuneToUnit(assignment.PlayerIndex, rune, assignment.Unit, typeLookup) then
        assignment.AppliedRunes[effectInstanceId] = true
        return true
    end
    return false
end

function HextechRune:AlertPersistentResult(sourceName, playerIndex, rune, assignedCount, appliedCount)
    self:TestAlert(format("%s P%d %s：本次归属/检查%d，符合兵种并生效%d，%s",
        sourceName, playerIndex, self:GetRuneDisplayName(rune), assignedCount,
        appliedCount, self:GetRuneTestValue(rune)))
end

-- 给本次刚登记的新单位应用其归属玩家的全部持续符文。
function HextechRune:ApplyOwnedRunesToNewAssignments(assignments, sourceName,
    excludedPlayerIndex, excludedOwnershipId)
    local typeLookup = self:BuildAllBattleUnitTypeLookup()
    for playerIndex = 1, 6, 1 do
        self:EnsurePlayerRuneState(playerIndex)
        local owned = self.PlayerOwnedRunes[playerIndex]
        for runeIndex = 1, getn(owned), 1 do
            local rune = owned[runeIndex]
            local isExcluded = playerIndex == excludedPlayerIndex
                and self:GetRuneEffectInstanceId(rune) == excludedOwnershipId
            if not isExcluded and rune.Effect ~= "starting_funds" and rune.Effect ~= "fortified"
                and rune.Effect ~= "recycler" then
                local assignedCount = 0
                local appliedCount = 0
                for i = 1, getn(assignments), 1 do
                    local assignment = assignments[i]
                    if assignment.PlayerIndex == playerIndex then
                        assignedCount = assignedCount + 1
                        if self:ApplyRuneToAssignment(rune, assignment, typeLookup) then
                            appliedCount = appliedCount + 1
                        end
                    end
                end
                -- 0 也打印，便于确认触发入口执行过，并区分“没有新单位”和“效果未调用”。
                self:AlertPersistentResult(sourceName, playerIndex, rune,
                    assignedCount, appliedCount)
            end
        end
    end
end

-- 玩家中途获得新符文时，对之前已登记且仍存活的归属单位补施加一次。
function HextechRune:ApplyRuneToAssignedBattleUnits(playerIndex, rune, sourceName)
    local typeLookup = self:BuildAllBattleUnitTypeLookup()
    local assignedCount = 0
    local appliedCount = 0
    for objectId, assignment in self.BattleUnitAssignments do
        if assignment.PlayerIndex == playerIndex and ObjectIsAlive(assignment.Unit)
            and ObjectGetId(assignment.Unit) == objectId then
            assignedCount = assignedCount + 1
            if self:ApplyRuneToAssignment(rune, assignment, typeLookup) then
                appliedCount = appliedCount + 1
            end
        end
    end
    self:AlertPersistentResult(sourceName, playerIndex, rune, assignedCount, appliedCount)
end

function HextechRune:ApplyFortified(playerIndex)
    local towerNames = { "T71", "T72", "T73", "T74" }
    if playerIndex >= 4 then
        towerNames = { "T81", "T82", "T83", "T84" }
    end
    for i = 1, getn(towerNames), 1 do
        local tower = GetObjectByScriptName(towerNames[i])
        if ObjectIsAlive(tower) then
            local maxHealth = exObjectGetMaxHealth(ObjectGetId(tower))
            ExecuteAction("NAMED_SET_MAX_HEALTH", towerNames[i], maxHealth + 1500, 1)
            self:TestAlert(format("P%d 固若金汤：%s 最大生命 %.0f→%.0f",
                playerIndex, towerNames[i], maxHealth, maxHealth + 1500))
            return
        end
    end
    self:TestAlert(format("P%d 固若金汤：未找到仍存活的前线防御塔", playerIndex))
end

function HextechRune:ApplyPersistentRune(playerIndex, rune)
    -- 先登记选择瞬间可能已经存在、但尚未被固定出兵触发器扫描的单位。
    local newAssignments = self:AssignNewBattleUnits()
    self:ApplyRuneToAssignedBattleUnits(playerIndex, rune, "选择符文")
    -- 新登记单位还需要补齐所有玩家此前持有的其他持续符文；当前符文刚处理过，跳过其重复日志。
    self:ApplyOwnedRunesToNewAssignments(newAssignments, "选择时补登记",
        playerIndex, self:GetRuneEffectInstanceId(rune))
end

function HextechRune:OnRuneChosen(playerIndex, rune)
    if rune.Effect == "grant_yaoguang" then
        self:GrantYaoguang(playerIndex)
    elseif rune.Effect == "oil_king" then
        self:GrantOilDerricks(playerIndex)
    elseif rune.Effect == "buy_two_get_one" then
        self:EnableBuyTwoGetOne(playerIndex, rune)
    elseif rune.Effect == "starting_funds" then
        ExecuteAction("PLAYER_GIVE_MONEY", "Player_" .. playerIndex, 10000)
        self:TestAlert(format("P%d 启动资金：资金 +10000", playerIndex))
    elseif rune.Effect == "fortified" then
        self:ApplyFortified(playerIndex)
    elseif rune.Effect == "recycler" then
        g_HextechRecycleBonus[playerIndex] = (g_HextechRecycleBonus[playerIndex] or 0) + 0.2
        self:TestAlert(format("P%d 破烂王：本次回收倍率 +20%%，累计 +%.0f%%",
            playerIndex, g_HextechRecycleBonus[playerIndex] * 100))
    else
        self:ApplyPersistentRune(playerIndex, rune)
    end
end

-- 固定出兵和“补充军队”共用入口：只登记并处理本次新增单位。
function HextechRune:ApplyNewBattleUnitEffects(sourceName)
    local assignments = self:AssignNewBattleUnits()
    self:ApplyOwnedRunesToNewAssignments(assignments, sourceName or "出兵")
end

function HextechRune:ApplyRoundEffects(round)
    self:ApplyNewBattleUnitEffects("第" .. tostring(round) .. "回合固定出兵")
end
