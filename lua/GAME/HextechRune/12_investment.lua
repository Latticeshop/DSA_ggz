-- 讲解见 analysis/地图注释说明文档.md 附录 A.58

HextechRune = HextechRune or {}

-- 回报倍率：2 倍（本金 + 等额收益）。
HextechRune.InvestmentPayoutMultiplier = 2

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

-- 选择符文时当场结算：先扣光当前金钱，再按两倍返还（净效果 = 当前金钱翻倍）。
-- 金额不为正时不动账也不提示（与旧版同一口径，没有到期记账、没有回合钩子）。
function HextechRune:ApplyInvestment(playerIndex)
    local money = self:GetPlayerCurrentMoney(playerIndex)
    if money <= 0 then
        return
    end
    local payout = money * self.InvestmentPayoutMultiplier
    self:ChangePlayerMoney(playerIndex, -money)
    self:ChangePlayerMoney(playerIndex, payout)
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
        Localization.get("hextech.rune.investment.payout", floor(payout)), 10)
end
