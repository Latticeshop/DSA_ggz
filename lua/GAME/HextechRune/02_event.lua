-- 海克斯符文系统：回合事件（开局测试事件 + 正式海克斯事件）
--   - 回合监听：轮询 lvc 计数器（不依赖 RoundLuaManager）
--   - 开局测试事件（第 1 回合，测试环境专用，不受配置数量影响）：
--     - 屏幕正中间 3 个方框，展示测试指定的符文和三种稀有度选项
--     - 3 个选项稀有度不同（彩/金/银 各一），按默认概率加权抽取
--   - 正式海克斯事件（第 5/11/18 回合，按 g_HextechCount 截取）：
--     - 先全场抽一个统一稀有度（彩/金/银，按回合概率）
--     - 再对每个玩家独立刷新 3 个方框（每个玩家选项不同，稀有度相同，内容留空）
--     - 内容（具体符文）在符文池接入后填充
--
-- 注意：本文件遵循本图 Lua 4.0 约束——闭包不访问外层局部变量，
--       需要的数据通过 self 或参数传递。

-- 海克斯选择对话框 ID 偏移（保留，正式事件用；当前用屏幕方框）
HEXTECH_DIALOG_ID_OFFSET = 300

HextechRune = HextechRune or {}

HextechRune.RarityNames = {
    [1] = "prismatic", -- 彩
    [2] = "gold",      -- 金
    [3] = "silver",    -- 银
}

-- 三档稀有度展示顺序（彩 / 金 / 银）对应的卡框图片 ID
HextechRune.RarityFrameImageIds = {
    [1] = g_HextechFramePrismaticId,
    [2] = g_HextechFrameGoldId,
    [3] = g_HextechFrameSilverId,
}

-- 开局测试事件是否已触发（第 1 回合，测试环境专用）
HextechRune.OpeningTestTriggered = false

-- 记录每个玩家开局测试选择的结果（用于展示）
HextechRune.PlayerOpeningTestRarity = {}

-- 记录每个玩家的 3 个选项稀有度（index 100 起，每玩家 3 个）
HextechRune.PlayerOptionRarity = {}

-- 记录当前显示的选项是否为测试事件（true=开局测试，false=正式事件）
HextechRune.PlayerOptionIsTest = {}

-- 记录每个玩家正式事件的选择（后续 buff 用）
HextechRune.PlayerChosenRarity = {}

-- 正式事件已触发的回合（防止重复触发）
HextechRune.FormalTriggered = {}

-- ===== 屏幕中央 3 个方框的布局参数 =====
-- 说明：日冕地图逻辑分辨率 1366x768，CenterX/Y 为屏幕中心像素坐标。
-- 若你的实际画面显示偏右/偏左，请调整 CenterX（减小=左移，增大=右移）。
HextechRune.CenterX = 583
HextechRune.CenterY = 384
-- 方框尺寸（卡框素材是方形，越大越醒目）
HextechRune.FrameSize = 200
HextechRune.FrameSpacing = 30
-- 自定义按钮 index 基础：玩家 i 的方框 j = CustomBtnIndexBase + (i-1)*3 + j
-- 避开已用 index（1-7、21-25、999、1000）
HextechRune.CustomBtnIndexBase = 100
-- 自定义文字 index 基础（每玩家 index 唯一）
HextechRune.CustomTextIndexBase = 200

-- 正式海克斯事件发放回合（按 g_HextechCount 取前 N 个）
HextechRune.FormalRounds = { 5, 11, 18 }

-- 计算某玩家某个方框的按钮 index
function HextechRune:GetOptionBtnIndex(playerIndex, optionIndex)
    return self.CustomBtnIndexBase + (playerIndex - 1) * 3 + optionIndex
end

-- 计算某玩家某个方框的文字 index
function HextechRune:GetOptionTextIndex(playerIndex, optionIndex)
    return self.CustomTextIndexBase + (playerIndex - 1) * 3 + optionIndex
end

-- 按稀有度概率抽取 3 个不同稀有度选项（去重）。开局测试事件用（默认概率）。
function HextechRune:PickThreeRarityByProbability()
    -- 默认概率：彩 10% / 金 40% / 银 50%
    local weightMap = {
        [1] = 10,  -- 彩
        [2] = 40,  -- 金
        [3] = 50,  -- 银
    }
    -- 抽出 3 个不同的稀有度（不放回），保证选项不重复
    local picked = {}
    local pickedCount = 0
    local pool = { 1, 2, 3 }
    while pickedCount < 3 do
        local totalWeight = 0
        for i = 1, getn(pool), 1 do
            totalWeight = totalWeight + weightMap[pool[i]]
        end
        local roll = GetRandomNumber() * totalWeight
        local acc = 0
        local chosenIndex = 1
        for i = 1, getn(pool), 1 do
            acc = acc + weightMap[pool[i]]
            if roll < acc then
                chosenIndex = i
                break
            end
        end
        local rarity = pool[chosenIndex]
        tinsert(picked, rarity)
        tremove(pool, chosenIndex)
        pickedCount = pickedCount + 1
    end
    return picked
end

-- 正式事件：按回合抽一个全场统一的稀有度（彩/金/银）。
-- 第 5 回合（第一次）= 彩 5% / 金 30% / 银 65%；第 11/18 回合 = 彩 10% / 金 40% / 银 50%
function HextechRune:RollFieldRarity(round)
    local weightMap
    if round <= self.FormalRounds[1] then
        -- 第一次正式事件：彩 5 / 金 30 / 银 65
        weightMap = { [1] = 5, [2] = 30, [3] = 65 }
    else
        -- 后续：彩 10 / 金 40 / 银 50
        weightMap = { [1] = 10, [2] = 40, [3] = 50 }
    end
    local totalWeight = weightMap[1] + weightMap[2] + weightMap[3]
    local roll = GetRandomNumber() * totalWeight
    local acc = 0
    for i = 1, 3, 1 do
        acc = acc + weightMap[i]
        if roll < acc then
            return i
        end
    end
    return 3
end

-- 判断某回合是否为正式海克斯发放回合（按 g_HextechCount 截取）
function HextechRune:IsFormalRound(round)
    local count = g_HextechCount or 0
    if count <= 0 then
        return false
    end
    for i = 1, count, 1 do
        if self.FormalRounds[i] == round then
            return true
        end
    end
    return false
end

-- 创建单个屏幕中央方框（按钮 + 文字）
function HextechRune:CreateOptionBox(playerIndex, optionIndex, rarity, frameImageId, optionText)
    local playerName = "Player_" .. playerIndex
    local btnIndex = self:GetOptionBtnIndex(playerIndex, optionIndex)
    local textIndex = self:GetOptionTextIndex(playerIndex, optionIndex)
    -- 3 个方框水平居中排列
    local totalWidth = self.FrameSize * 3 + self.FrameSpacing * 2
    local startX = self.CenterX - totalWidth / 2
    local x = startX + (optionIndex - 1) * (self.FrameSize + self.FrameSpacing)
    local y = self.CenterY - self.FrameSize / 2 - 30

    -- 卡框按钮（TextureName 接受数字图片 ID）
    exCreateCustomButtonForPlayer(playerName, {
        Index = btnIndex,
        TextureName = frameImageId,
        Desc = optionText,
        X = x,
        Y = y,
        SizeX = self.FrameSize,
        SizeY = self.FrameSize,
        GroupIndex = btnIndex,
        AlignX = "left",
        AlignY = "top",
    })
    -- 方框上的文字标签（每玩家独立文字）
    exCreateCustomTextForPlayer(playerName, {
        Index = textIndex,
        Content = optionText,
        X = x + 10,
        Y = y + self.FrameSize - 28,
        Color = 16777215,
        Size = 16,
        AlignX = "left",
        AlignY = "top",
    })
end

-- 弹出开局测试三选一事件（屏幕正中间 3 个方框，测试环境专用）
function HextechRune:ShowOpeningTestEvent(playerIndex)
    local pickedRarity = self:PickThreeRarityByProbability()
    self.PlayerOptionRarity[playerIndex] = pickedRarity
    self.PlayerOptionIsTest[playerIndex] = true
    for i = 1, 3, 1 do
        local rarity = pickedRarity[i]
        local rarityName = self.RarityNames[rarity]
        local optionText = Localization.get("hextech.test.option", i, Localization.get("hextech.rarity." .. rarityName))
        self:CreateOptionBox(playerIndex, i, rarity, self.RarityFrameImageIds[rarity], optionText)
    end
end

-- 正式海克斯事件：全场统一稀有度 + 每个玩家独立 3 个空选项
function HextechRune:ShowFormalEvent(round)
    local rarity = self:RollFieldRarity(round)
    for playerIndex = 1, 6, 1 do
        -- 仅对存在的玩家触发（有建筑的玩家）
        local playerName = "Player_" .. playerIndex
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if structureCount > 0 then
            -- 每个玩家 3 个选项，稀有度相同，内容留空（符文池接入后填充）
            self.PlayerOptionRarity[playerIndex] = { rarity, rarity, rarity }
            self.PlayerOptionIsTest[playerIndex] = false
            for i = 1, 3, 1 do
                self:CreateOptionBox(playerIndex, i, rarity, self.RarityFrameImageIds[rarity], "")
            end
        end
    end
end

-- 处理玩家点击方框（记录选择并关闭方框）
function HextechRune:HandleOptionClick(playerIndex, optionIndex)
    if not self.PlayerOptionRarity[playerIndex] then
        return
    end
    local rarity = self.PlayerOptionRarity[playerIndex][optionIndex]
    local rarityName = self.RarityNames[rarity]
    local rarityLabel = Localization.get("hextech.rarity." .. rarityName)
    -- 记录选择（测试事件和正式事件都记录到 PlayerChosenRarity）
    self.PlayerChosenRarity[playerIndex] = rarity
    -- 移除该玩家的 3 个方框按钮和文字
    for i = 1, 3, 1 do
        local btnIndex = self:GetOptionBtnIndex(playerIndex, i)
        local textIndex = self:GetOptionTextIndex(playerIndex, i)
        exCustomBtnRemoveForPlayer("Player_" .. playerIndex, btnIndex)
        exCustomTextUpdateVisibilityForPlayer("Player_" .. playerIndex, textIndex, 0)
    end
    -- 广播选择结果（测试事件和正式事件用不同文案）
    local msg
    if self.PlayerOptionIsTest[playerIndex] then
        msg = Localization.get("hextech.test.picked", rarityLabel)
    else
        msg = Localization.get("hextech.picked", rarityLabel)
    end
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, msg, 10)
end

-- 注册自定义按钮点击处理（屏幕中央方框）
-- 注意：回调闭包内不使用外层局部变量（Lua 4.0 约束），一律用全局 HextechRune 访问。
function HextechRune:RegisterCustomBtnHandler()
    if HextechRune._btnHandlerRegistered then
        return
    end
    HextechRune._btnHandlerRegistered = true
    ButtonManager:RegisterCustomButtonHandler(function(playerName, index)
        -- 解析 index 属于哪位玩家的哪个方框
        if index >= HextechRune.CustomBtnIndexBase then
            local offset = index - HextechRune.CustomBtnIndexBase - 1
            local playerIndex = floor(offset / 3) + 1
            local optionIndex = mod(offset, 3) + 1
            if playerIndex >= 1 and playerIndex <= 6 and optionIndex >= 1 and optionIndex <= 3 then
                if HextechRune.PlayerOptionRarity[playerIndex] then
                    HextechRune:HandleOptionClick(playerIndex, optionIndex)
                    return true
                end
            end
        end
        return nil
    end)
end

-- 回合开始回调（由 RoundLuaManager 驱动，仅回合变化时调用）
function HextechRune:OnRoundBegin(round)
    -- 开局测试事件：第 1 回合开始触发一次（测试环境专用，不受配置数量影响）
    if not self.OpeningTestTriggered and round == 1 then
        self.OpeningTestTriggered = true
        for playerIndex = 1, 6, 1 do
            -- 仅对存在的玩家触发（有建筑的玩家）
            local playerName = "Player_" .. playerIndex
            local previous = SetWorldBuilderThisPlayer(1)
            local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
            SetWorldBuilderThisPlayer(previous)
            if structureCount > 0 then
                self:ShowOpeningTestEvent(playerIndex)
            end
        end
    end
    -- 正式海克斯事件：按配置次数截取的回合触发（全场统一稀有度）
    if g_EnableHextechRune == 1 and not self.FormalTriggered[round] and self:IsFormalRound(round) then
        self.FormalTriggered[round] = true
        self:ShowFormalEvent(round)
    end
end

-- 注册到回合开始钩子（复用抽卡模式 PureDraw 的 RoundLuaManager 方案）。
-- RoundLuaManager 由 huihe/spawn（start 计时器到期）定义，本脚本（CONDITION_TRUE）
-- 在地图加载早期执行时其尚未就绪；这里延迟重试直到就绪，成功后不再轮询。
function HextechRune:RegisterRoundBegin()
    if HextechRune._roundRegistered then
        return
    end
    if RoundLuaManager == nil then
        -- 未就绪：15 帧（约 1 秒）后重试；不打日志避免刷屏
        SchedulerModule.delay_call(function()
            HextechRune:RegisterRoundBegin()
        end, 15, {})
        return
    end
    HextechRune._roundRegistered = true
    RoundLuaManager.CallOnEveryRoundBegin(function(args)
        HextechRune:OnRoundBegin(exCounterGetByName("lvc"))
    end, {})
    -- 注册成功时若第 1 回合已经开始（lvc>=1），立即补触发一次，避免错过开局测试事件
    local currentRound = exCounterGetByName("lvc")
    if currentRound ~= nil and currentRound >= 1 then
        HextechRune:OnRoundBegin(currentRound)
    end
end

-- 注册自定义按钮点击处理（屏幕中央方框）
HextechRune:RegisterCustomBtnHandler()

-- 注册回合开始回调（RoundLuaManager 就绪后自动注册，无需轮询）
HextechRune:RegisterRoundBegin()
