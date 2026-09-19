-- 海克斯符文系统：回合事件与开局测试事件
--   - 回合开始钩子（RoundLuaManager.CallOnEveryRoundBegin）
--   - 开局测试事件：第 1 回合开始弹出三选一（额外第四个，不受配置数量影响）
--     - 屏幕正中间出现 3 个方框选项（用卡框素材 g_HextechFrame*Id，可调小像素）
--     - 3 个选项用通用文字（测试符文·彩 / 测试符文·金 / 测试符文·银）
--     - 按默认稀有度概率（彩 10% / 金 40% / 银 50%）加权抽 3 个选项
--     - 方框不会自动消失，除非玩家点击选择了某个选项
--   - 正式的第 5/11/18 回合事件在后续步骤接入（本步骤先做开局测试事件）
--
-- 注意：本文件遵循本图 Lua 4.0 约束——闭包不访问外层局部变量，
--       需要的数据通过 self 或参数传递。

-- 海克斯选择对话框 ID 偏移（保留，正式事件用；当前测试事件用屏幕方框）
HEXTECH_DIALOG_ID_OFFSET = 300

_ALERT("[HextechRune] 02_event.lua 加载，开始定义 HextechRune 表")

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

-- 开局测试事件是否已触发
HextechRune.OpeningTestTriggered = false

-- 记录每个玩家开局测试选择的结果（用于展示）
HextechRune.PlayerOpeningTestRarity = {}

-- 记录每个玩家的 3 个选项稀有度（index 100 起，每玩家 3 个）
HextechRune.PlayerOptionRarity = {}

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
-- 自定义文字 index 基础（全局文字，每玩家 index 唯一）
HextechRune.CustomTextIndexBase = 200

-- 计算某玩家某个方框的按钮 index
function HextechRune:GetOptionBtnIndex(playerIndex, optionIndex)
    return self.CustomBtnIndexBase + (playerIndex - 1) * 3 + optionIndex
end

-- 计算某玩家某个方框的文字 index
function HextechRune:GetOptionTextIndex(playerIndex, optionIndex)
    return self.CustomTextIndexBase + (playerIndex - 1) * 3 + optionIndex
end

-- 按稀有度概率抽取 3 个不同稀有度选项（去重）。
-- tier 1 = 开局测试事件（默认概率），后续可扩展正式回合的 tier。
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
    _ALERT("[HextechRune] 布局: 方框" .. tostring(optionIndex) .. " x=" .. tostring(x) .. " y=" .. tostring(y) .. " 尺寸=" .. tostring(self.FrameSize) .. " CenterX=" .. tostring(self.CenterX) .. " 整体宽=" .. tostring(totalWidth))

    -- 卡框按钮（TextureName 接受数字图片 ID，参考 huohuo 顶部按钮）
    _ALERT("[HextechRune] CreateOptionBox 玩家 " .. tostring(playerIndex) .. " 选项 " .. tostring(optionIndex) .. " 创建按钮 index=" .. tostring(btnIndex) .. " 图片ID=" .. tostring(frameImageId) .. " 文字=" .. optionText)
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

-- 弹出开局测试三选一事件（屏幕正中间 3 个方框）
function HextechRune:ShowOpeningTestEvent(playerIndex)
    _ALERT("[HextechRune] ShowOpeningTestEvent 玩家 " .. tostring(playerIndex) .. " 开始抽稀有度")
    local pickedRarity = self:PickThreeRarityByProbability()
    self.PlayerOptionRarity[playerIndex] = pickedRarity
    _ALERT("[HextechRune] 玩家 " .. tostring(playerIndex) .. " 抽到稀有度: " .. tostring(pickedRarity[1]) .. "," .. tostring(pickedRarity[2]) .. "," .. tostring(pickedRarity[3]))
    for i = 1, 3, 1 do
        local rarity = pickedRarity[i]
        local rarityName = self.RarityNames[rarity]
        local optionText = Localization.get("hextech.test.option", i, Localization.get("hextech.rarity." .. rarityName))
        self:CreateOptionBox(playerIndex, i, rarity, self.RarityFrameImageIds[rarity], optionText)
    end
end

-- 处理玩家点击方框（记录选择并关闭方框）
function HextechRune:HandleOptionClick(playerIndex, optionIndex)
    _ALERT("[HextechRune] HandleOptionClick 玩家 " .. tostring(playerIndex) .. " 点击选项 " .. tostring(optionIndex))
    local rarity = self.PlayerOptionRarity[playerIndex][optionIndex]
    local rarityName = self.RarityNames[rarity]
    local rarityLabel = Localization.get("hextech.rarity." .. rarityName)
    self.PlayerOpeningTestRarity[playerIndex] = rarity
    -- 移除该玩家的 3 个方框按钮和文字
    for i = 1, 3, 1 do
        local btnIndex = self:GetOptionBtnIndex(playerIndex, i)
        local textIndex = self:GetOptionTextIndex(playerIndex, i)
        exCustomBtnRemoveForPlayer("Player_" .. playerIndex, btnIndex)
        exCustomTextUpdateVisibilityForPlayer("Player_" .. playerIndex, textIndex, 0)
    end
    -- 广播选择结果
    exAddTextToPublicBoardForPlayer(
        "Player_" .. playerIndex,
        Localization.get("hextech.test.picked", rarityLabel),
        10)
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

-- 回合开始回调（由 lvc 轮询驱动，每帧检查）
function HextechRune:OnRoundBegin(round)
    -- 开局测试事件：第 1 回合开始触发一次（额外第四个，不受配置数量影响）
    if not self.OpeningTestTriggered and round == 1 then
        self.OpeningTestTriggered = true
        _ALERT("[HextechRune] 第 1 回合开始，弹出开局测试事件")
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
        -- 触发后暂停轮询（后续正式回合事件另接）
        if HextechRune._watcherId then
            SchedulerModule.pause_scheduler(HextechRune._watcherId)
        end
    end
    -- TODO 后续步骤：正式的第 5/11/18 回合三选一事件（按 g_HextechCount 截取发放回合）
end

-- 轮询 lvc 计数器触发回合事件。
-- 不依赖 RoundLuaManager（其在游戏开始后才定义），只要 lvc 计数器可用即可。
function HextechRune:StartRoundWatcher()
    if HextechRune._watcherStarted then
        return
    end
    HextechRune._watcherStarted = true
    _ALERT("[HextechRune] 启动 lvc 轮询（每帧检测回合开始）")
    HextechRune._watcherId = SchedulerModule.call_every_x_frame(function()
        local round = exCounterGetByName("lvc")
        if round ~= nil then
            HextechRune:OnRoundBegin(round)
        end
    end, 1, nil, {})
end

-- 注册自定义按钮点击处理（屏幕中央方框）
HextechRune:RegisterCustomBtnHandler()

-- 启动 lvc 轮询（触发回合事件，不依赖 RoundLuaManager）
HextechRune:StartRoundWatcher()
