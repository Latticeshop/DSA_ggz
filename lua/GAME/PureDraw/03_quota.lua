-- ============================================================
-- PureDraw: 生产配额（余额）
--   - 余额墙/信标 UI 显示
--   - 单位可造性判断与按钮开关
--   - 生产消耗余额、超额删除退款
-- ============================================================

function PureDrawIsHumanPlayer(playerIndex)
    return EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", "Player_" .. playerIndex, "Human")
end

function PureDrawGetQuotaDisplayDirection(playerIndex)
    local playerPosition = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local startXTotal = 0
    for i = 1, 6, 1 do
        local startPosition = exWaypointGetPos(format("Player_%d_Start", i))
        startXTotal = startXTotal + startPosition[1]
    end
    -- 左侧出生点的海岸在基地左边，因此余额展示统一放到基地右侧。
    if playerPosition[1] < startXTotal / 6 then
        return 1
    end
    return -1
end

function PureDrawSpawnQuotaWall(playerIndex, slot)
    if not PureDrawIsHumanPlayer(playerIndex) then
        return
    end
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = PureDrawGetQuotaDisplayDirection(playerIndex)
    local name = format("PureDrawQuota_%d_%d", playerIndex, slot)
    ExecuteAction("NAMED_DELETE", name)
    -- AlliedWallPiece 使用公告等待阶段已经验证过的生成通道：先在现有投票路径点创建，
    -- 再移动到基地旁。不要占用 Player_N 名称，否则会破坏原有的阅读完成判定。
    ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT", name, "AlliedWallPiece",
        "PlyrCreeps/teamPlyrCreeps", "toupiaodian" .. playerIndex)
    local wall = GetObjectByScriptName(name)
    if wall ~= nil then
        ObjectSetPosition(wall,
            p[1] + direction * 260,
            p[2] + (slot - 3) * 38,
            p[3])
        ExecuteAction("UNIT_AFFECT_OBJECT_PANEL_FLAGS", wall, "Indestructible", true)
    end
end

function PureDrawCreateQuotaDisplay(playerIndex)
    for slot = 1, g_PureDrawConfig.ProductionQuota, 1 do
        ExecuteAction("NAMED_DELETE", format("PureDrawQuota_%d_%d", playerIndex, slot))
        if slot <= g_PureDrawQuota[playerIndex] then
            PureDrawSpawnQuotaWall(playerIndex, slot)
        end
    end
    if not PureDrawIsHumanPlayer(playerIndex) then
        return
    end
    local p = exWaypointGetPos(format("Player_%d_Start", playerIndex))
    local direction = PureDrawGetQuotaDisplayDirection(playerIndex)
    local labelName = format("PureDrawQuotaLabel_%d", playerIndex)
    ExecuteAction("NAMED_DELETE", labelName)
    ExecuteAction("UNIT_SPAWN_NAMED_LOCATION_ORIENTATION", labelName, "MultiplayerBeacon",
        format("Player_%d/teamPlayer_%d", playerIndex, playerIndex), {
            X = p[1] + direction * 320,
            Y = p[2],
            Z = p[3],
        }, 0)
    TextDoActionLocalizedOnce("NAMED_SHOW_INFOBOX", labelName, "SCRIPT:PureDrawQuota", 0, "")
end

function PureDrawCanEnableUnit(playerIndex, info)
    if g_DisableSeaArmy == 1 and info.Sea then
        return false
    end
    local round = exCounterGetByName("lvc") or 0
    if info.ProductionUnlockRound ~= nil and round < info.ProductionUnlockRound then
        return false
    end
    if g_DisableSeaArmy == 1 and info.NoNavyProductionUnlockRound ~= nil
        and round < info.NoNavyProductionUnlockRound then
        return false
    end
    if info.IsBigShip then
        if not g_PureDrawT4ShipUnlocked[playerIndex] then
            return false
        end
        if info.Type ~= "JapanGigaFortressShipEgg"
            and exCounterGetByName("bigshiplimit" .. playerIndex) >= 2 then
            return false
        end
    end
    if info.IsYaoguang and GetPlayerYaoguangCount ~= nil and YAOGUANG_LIMIT ~= nil
        and GetPlayerYaoguangCount(playerIndex) >= YAOGUANG_LIMIT then
        return false
    end
    return true
end

function PureDrawSetPlayerBuildability(playerIndex, enable)
    local playerName = "Player_" .. playerIndex
    local disallowedHashes = {}
    for tier = 1, 4, 1 do
        local pool = g_PureDrawBuildableUnitPool[tier]
        for i = 1, getn(pool), 1 do
            local info = pool[i]
            local availability = false
            if enable and PureDrawCanEnableUnit(playerIndex, info) then
                availability = true
            end
            ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, info.Type, availability)
            local aliases = g_PureDrawProductionAliases[info.Type]
            if aliases ~= nil then
                for aliasIndex = 1, getn(aliases), 1 do
                    ExecuteAction("ALLOW_DISALLOW_ONE_BUILDING", playerName, aliases[aliasIndex], availability)
                end
            end
            if not availability then
                disallowedHashes[tostring(FastHash(info.Type))] = true
                if aliases ~= nil then
                    for aliasIndex = 1, getn(aliases), 1 do
                        disallowedHashes[tostring(FastHash(aliases[aliasIndex]))] = true
                    end
                end
            end
        end
    end
    if not enable and RescueBlockedProductions_DoRescue ~= nil then
        RescueBlockedProductions_DoRescue(playerName, disallowedHashes)
    end
end

function PureDrawRefreshQuota(playerIndex)
    g_PureDrawQuota[playerIndex] = g_PureDrawConfig.ProductionQuota
    PureDrawSetPlayerBuildability(playerIndex, true)
    PureDrawCreateQuotaDisplay(playerIndex)
    if PureDrawIsHumanPlayer(playerIndex) then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("pure_draw.quota.refreshed", g_PureDrawQuota[playerIndex]), 8)
    end
end

function PureDrawGetBuildCost(createdObjInstanceId)
    local info = g_PureDrawUnitInfoByHash[createdObjInstanceId]
    if info == nil then
        return 0
    end
    for faction = 1, 4, 1 do
        for category = 1, 4, 1 do
            local units = g_RecycleBtnsMapByFaction[faction][category]
            for i = 1, getn(units), 1 do
                if units[i].Type == info.Type then
                    return units[i].Money or 0
                end
            end
        end
    end
    return 0
end

function PureDrawTryConsumeProductionQuota(createdObjId, createdObjInstanceId,
    playerIndex, ownerPlayerName, retriesLeft)
    if not ObjectIsAlive(createdObjId) or g_DrawMode ~= 2 then
        return
    end
    local producer = ObjectGetProducerObject(createdObjId)
    if producer == nil then
        -- 无生产者的单位（箱子结果/赠送/凭空出现）不消耗生产余额。
        if retriesLeft > 0 then
            SchedulerModule.delay_call(PureDrawTryConsumeProductionQuota, 1, {
                createdObjId, createdObjInstanceId, playerIndex, ownerPlayerName, retriesLeft - 1
            })
            return
        end
        return
    end
    local oldQuota = g_PureDrawQuota[playerIndex] or 0
    if oldQuota <= 0 then
        local refund = PureDrawGetBuildCost(createdObjInstanceId)
        ExecuteAction("NAMED_DELETE", GetObjectById(createdObjId))
        if refund > 0 then
            ExecuteAction("PLAYER_GIVE_MONEY", ownerPlayerName, refund)
        end
        exAddTextToPublicBoardForPlayer(ownerPlayerName,
            Localization.get("pure_draw.quota.exceeded", refund), 6)
        return
    end
    g_PureDrawQuota[playerIndex] = oldQuota - 1
    ExecuteAction("NAMED_DELETE", format("PureDrawQuota_%d_%d", playerIndex, oldQuota))
    exAddTextToPublicBoardForPlayer(ownerPlayerName,
        Localization.get("pure_draw.quota.remaining", g_PureDrawQuota[playerIndex]), 5)
    if g_PureDrawQuota[playerIndex] <= 0 then
        PureDrawSetPlayerBuildability(playerIndex, false)
    end
end
