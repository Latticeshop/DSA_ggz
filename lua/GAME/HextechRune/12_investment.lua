-- 海克斯符文「投资」（银色，可重复）：选择时失去当前全部金钱，
-- 5 个回合后（回合开始结算的那一刻）获得当时投入金额的两倍。
-- 每份独立计时，可重复获取叠加多笔互不影响的投资。

HextechRune = HextechRune or {}

-- 到期回合数：选择回合 + 该值。
HextechRune.InvestmentDueRounds = 5
-- 回报倍率：2 倍（本金 + 等额收益）。
HextechRune.InvestmentPayoutMultiplier = 2
-- 每个玩家一份待结算列表：{ Amount = 投入金额, DueRound = 到期回合 }。
HextechRune.InvestmentPending = HextechRune.InvestmentPending or {}

function HextechRune:EnsureInvestmentPlayerState(playerIndex)
    if self.InvestmentPending[playerIndex] == nil then
        self.InvestmentPending[playerIndex] = {}
    end
end

-- 与起始资金同口径：海克斯按钮回调没有 WorldBuilder 玩家上下文，
-- 必须显式切换后再恢复，否则加钱/扣钱不生效。金额为负即扣钱。
function HextechRune:ChangePlayerMoney(playerIndex, amount)
    if amount == 0 then
        return
    end
    local previous = SetWorldBuilderThisPlayer(1)
    ExecuteAction("PLAYER_GIVE_MONEY", "Player_" .. playerIndex, amount)
    SetWorldBuilderThisPlayer(previous)
end

function HextechRune:GetPlayerCurrentMoney(playerIndex)
    return tonumber(exPlayerGetCurrentMoney("Player_" .. playerIndex)) or 0
end

-- 选择符文时结算：扣光当前金钱并登记到期回合。金额不为正时不动账（也不登记）。
function HextechRune:ApplyInvestment(playerIndex)
    self:EnsureInvestmentPlayerState(playerIndex)
    local money = self:GetPlayerCurrentMoney(playerIndex)
    if money <= 0 then
        return
    end
    local round = tonumber(exCounterGetByName("lvc")) or 0
    local dueRound = round + self.InvestmentDueRounds
    self:ChangePlayerMoney(playerIndex, -money)
    tinsert(self.InvestmentPending[playerIndex], {
        Amount = money,
        DueRound = dueRound,
    })
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
        Localization.get("hextech.rune.investment.invested",
            floor(money), dueRound), 10)
end

-- 回合开始（出兵）时逐笔查到期：同一回合到期的多笔一起返还，各自独立。
function HextechRune:ApplyInvestmentPayouts(round)
    local currentRound = tonumber(round) or 0
    if currentRound < 1 then
        return
    end
    for playerIndex = 1, 6, 1 do
        self:EnsureInvestmentPlayerState(playerIndex)
        local pending = self.InvestmentPending[playerIndex]
        local index = 1
        while index <= getn(pending) do
            local entry = pending[index]
            if currentRound >= entry.DueRound then
                local payout = entry.Amount * self.InvestmentPayoutMultiplier
                self:ChangePlayerMoney(playerIndex, payout)
                exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
                    Localization.get("hextech.rune.investment.payout",
                        floor(payout)), 10)
                tremove(pending, index)
            else
                index = index + 1
            end
        end
    end
end
