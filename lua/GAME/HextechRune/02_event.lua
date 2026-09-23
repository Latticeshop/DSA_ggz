-- 海克斯符文系统：真实候选事件 + 海克斯面板
--   - 回合监听：RoundLuaManager.CallOnEveryRoundBegin（复用抽卡模式 PureDraw 方案）
--   - 正式海克斯事件（第 3/10/18 回合，按 g_HextechCount 截取）：
--     - 先全场抽一个统一稀有度（彩/金/银，按回合概率）
--     - 再对每个玩家独立筛池并刷新 3 个不同符文
--   - 海克斯面板（顶部按钮 5 展开）：横六筒造型展示上三/下三玩家的海克斯符文
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

-- PlayerOptions / PlayerOwnedRunes / PlayerOwnedRuneIds 由 01_rune_pool.lua 初始化。

-- 正式事件已触发的回合（防止重复触发）
HextechRune.FormalTriggered = {}

-- ===== 屏幕中央 3 个方框的布局参数 =====
-- 说明：日冕地图逻辑分辨率 1366x768，CenterX/Y 为屏幕中心像素坐标。
-- 若你的实际画面显示偏右/偏左，请调整 CenterX（减小=左移，增大=右移）。
HextechRune.CenterX = 583
HextechRune.CenterY = 384
-- 恢复已经实测满意的 200x200 三卡布局；仅把原生图标缩小到卡宽约三分之一。
HextechRune.OptionCardWidth = 200
HextechRune.OptionCardHeight = 200
HextechRune.OptionCardSpacing = 30
HextechRune.OptionIconSize = 52
-- 日冕文字渲染的实际视觉中心偏差随标题长度变化；默认值再由长度函数细分。
HextechRune.OptionTitleOffsetX = 14
-- 日冕自定义文字的 X 是文字左边界而不是文字中心；中英文使用不同宽度权重。
HextechRune.TextWidthScale = 1.65
HextechRune.AsciiWidthWeight = 0.55
HextechRune.PlayerNameEstimatedUnits = 3
-- 自定义按钮 index 基础：玩家 i 的方框 j = CustomBtnIndexBase + (i-1)*3 + j
-- 回收单位按钮占用 31~230；事件卡改用 251~268，避免同一次点击误入回收处理器。
HextechRune.CustomBtnIndexBase = 250
-- 事件卡片顶部原生图标按钮 index（每玩家 3 个）
HextechRune.CustomIconBtnIndexBase = 300
-- 每张事件卡正下方的重随按钮（每玩家 3 个）
HextechRune.RerollBtnIndexBase = 350
HextechRune.RerollButtonWidth = 57
HextechRune.RerollButtonHeight = 35
-- 自定义文字 index 基础（每玩家 index 唯一）
HextechRune.CustomTextIndexBase = 200
-- 选择页隐藏时显示在顶部技能组下方的提示文字（901~906）。
HextechRune.SelectionHintTextIndexBase = 900
HextechRune.SelectionHintCenterX = 683
HextechRune.SelectionHintY = 82
HextechRune.SelectionHintFontSize = 16
-- 拥有待部署湮灭炸弹时，K 键提示固定显示在 J 键提示下方（911~916）。
HextechRune.OblivionHintTextIndexBase = 910
HextechRune.OblivionHintCenterX = 683
HextechRune.OblivionHintY = 104
HextechRune.OblivionHintFontSize = 16

-- ===== 海克斯面板（按钮 5 展开）布局参数 =====
-- 横六筒造型：上三玩家（天使 4/5/6）名字 + 符文，下三玩家（恶魔 1/2/3）符文 + 名字
-- 第一行：上三玩家名；第二行：上三玩家符文；第三行：下三玩家符文；第四行：下三玩家名
HextechRune.PanelCenterX = 563
-- 标题固定居中于屏幕中央（整体左移后标题保持原位）
HextechRune.PanelTitleCenterX = 683
-- 列中心 x：三列（上左/上中/上右 与 下左/下中/下右 对齐）
HextechRune.PanelColumnGap = 240
-- 四行 y 坐标
HextechRune.PanelRowY = { 230, 300, 420, 490 }
-- 面板恢复原先 50x50 小卡布局；图标保留新版约三分之一的比例。
HextechRune.PanelRuneWidth = 50
HextechRune.PanelRuneHeight = 50
HextechRune.PanelRuneGap = 10
HextechRune.PanelRuneIconSize = 14
HextechRune.PanelRuneTitleOffsetX = 5
-- 总览面板最多展示 4 个符文。
HextechRune.PanelMaxRuneCount = 4
-- 面板自定义元素 index 基础（避开已用 index）
HextechRune.PanelBtnIndexBase = 400      -- 符文按钮：玩家 i 的第 j 个 = 400 + (i-1)*4 + j（401~424）
HextechRune.PanelCloseBtnBase = 500      -- 关闭按钮：玩家 i = 500 + i
HextechRune.PanelTextIndexBase = 600     -- 名字文字：玩家 i = 600 + i
HextechRune.PanelTitleTextBase = 610     -- 标题文字：玩家 i = 610 + i
HextechRune.PanelIconBtnIndexBase = 700  -- 小卡图标按钮：701~724
HextechRune.PanelRuneTextIndexBase = 800 -- 小卡标题文字：801~824

-- 每玩家面板是否展开
HextechRune.PanelVisible = {}
-- 每次打开三选一时重置；三个按钮共享同一次使用机会。
HextechRune.PlayerRerollUsed = HextechRune.PlayerRerollUsed or {}
-- 每名真人玩家独立保存尚未展示的正式符文事件；当前三选一完成后按先进先出弹出。
HextechRune.PlayerEventQueues = HextechRune.PlayerEventQueues or {}
-- 当前三选一是否实际显示；隐藏时 PlayerOptions 仍保留，J 键可原样恢复。
HextechRune.PlayerSelectionVisible = HextechRune.PlayerSelectionVisible or {}

-- 正式海克斯事件发放回合（按 g_HextechCount 取前 N 个）
HextechRune.FormalRounds = { 3, 10, 18 }

-- 计算某玩家某个方框的按钮 index
function HextechRune:GetOptionBtnIndex(playerIndex, optionIndex)
    return self.CustomBtnIndexBase + (playerIndex - 1) * 3 + optionIndex
end

-- 计算某玩家某个方框的文字 index
function HextechRune:GetOptionTextIndex(playerIndex, optionIndex)
    return self.CustomTextIndexBase + (playerIndex - 1) * 3 + optionIndex
end

function HextechRune:GetOptionIconBtnIndex(playerIndex, optionIndex)
    return self.CustomIconBtnIndexBase + (playerIndex - 1) * 3 + optionIndex
end

function HextechRune:GetRerollBtnIndex(playerIndex, optionIndex)
    return self.RerollBtnIndexBase + (playerIndex - 1) * 3 + optionIndex
end

function HextechRune:GetSelectionHintTextIndex(playerIndex)
    return self.SelectionHintTextIndexBase + playerIndex
end

-- 估算自定义文字中最宽一行的视觉宽度单位。
-- 中文等 UTF-8 字符按 1 个全宽字符计算，ASCII 按较窄字符计算；换行分别计宽。
-- $pNName 会在引擎内部展开，Lua 无法预先取得最终昵称，按常见 3 个全宽字符估算。
function HextechRune:GetTextMaxVisualUnits(text)
    if text == nil then
        return 0
    end
    if strsub(text, 1, 2) == "$p" and strsub(text, -4) == "Name" then
        return self.PlayerNameEstimatedUnits
    end
    local maxUnits = 0
    local lineUnits = 0
    local i = 1
    local length = strlen(text)
    while i <= length do
        local b = strbyte(text, i)
        if b == 10 then
            if lineUnits > maxUnits then
                maxUnits = lineUnits
            end
            lineUnits = 0
            i = i + 1
        elseif b < 128 then
            lineUnits = lineUnits + self.AsciiWidthWeight
            i = i + 1
        elseif b < 224 then
            lineUnits = lineUnits + 1
            i = i + 2
        elseif b < 240 then
            lineUnits = lineUnits + 1
            i = i + 3
        else
            lineUnits = lineUnits + 1
            i = i + 4
        end
    end
    if lineUnits > maxUnits then
        maxUnits = lineUnits
    end
    return maxUnits
end

-- 取得最宽一行的真实字符数，仅用于标题长度分档。
-- 不能复用视觉宽度：ASCII 会按 0.55 计宽，导致 MCV 被误判为“其他长度”。
function HextechRune:GetTextMaxCharacterCount(text)
    if text == nil then
        return 0
    end
    local maxCount = 0
    local lineCount = 0
    local i = 1
    local length = strlen(text)
    while i <= length do
        local b = strbyte(text, i)
        if b == 10 then
            if lineCount > maxCount then
                maxCount = lineCount
            end
            lineCount = 0
            i = i + 1
        elseif b < 128 then
            lineCount = lineCount + 1
            i = i + 1
        elseif b < 224 then
            lineCount = lineCount + 1
            i = i + 2
        elseif b < 240 then
            lineCount = lineCount + 1
            i = i + 3
        else
            lineCount = lineCount + 1
            i = i + 4
        end
    end
    if lineCount > maxCount then
        maxCount = lineCount
    end
    return maxCount
end

function HextechRune:IsAsciiText(text)
    if text == nil then
        return false
    end
    for i = 1, strlen(text), 1 do
        if strbyte(text, i) >= 128 then
            return false
        end
    end
    return true
end

-- 自定义文字使用与卡框一致的 left 屏幕锚点，并把估算宽度的一半放到中心点左侧。
function HextechRune:GetCenteredTextLeftX(centerX, text, fontSize)
    local width = self:GetTextMaxVisualUnits(text) * fontSize * self.TextWidthScale
    return centerX - width / 2
end

-- 实机字体并非严格等宽，中文与纯 ASCII 的字面留白也不同。
-- 四字标题保持已确认的参数；三字中文和纯 ASCII 分开校正。
function HextechRune:GetRuneTitleVisualOffsetX(rune, isPanel)
    local name = Localization.get(rune.NameKey)
    local characterCount = self:GetTextMaxCharacterCount(name)
    -- 全频段阻塞干扰在卡面显示为“全频段阻塞 / 干扰”，以最宽的
    -- 五字行实测校正；不用未换行的七字本地化名称分档。
    if rune.Effect == "broadband_jamming" then
        if isPanel then
            return 9
        end
        return 22
    end
    if characterCount == 4 then
        if isPanel then
            return 9
        end
        return 22
    elseif characterCount == 3 then
        if self:IsAsciiText(name) then
            if isPanel then
                return 2
            end
            return 8
        end
        if isPanel then
            return 5
        end
        return 14
    end
    if isPanel then
        return self.PanelRuneTitleOffsetX
    end
    return self.OptionTitleOffsetX
end

-- 正式事件：按回合抽一个全场统一的稀有度（彩/金/银）。
-- 第 3 回合（第一次）= 彩 5% / 金 40% / 银 55%；第 10/18 回合 = 彩 10% / 金 45% / 银 45%
function HextechRune:RollFieldRarity(round)
    local weightMap
    if round <= self.FormalRounds[1] then
        -- 第一次正式事件：彩 5 / 金 40 / 银 55
        weightMap = { [1] = 5, [2] = 40, [3] = 55 }
    else
        -- 后续：彩 10 / 金 45 / 银 45
        weightMap = { [1] = 10, [2] = 45, [3] = 45 }
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
function HextechRune:CreateOptionBox(playerIndex, optionIndex, rarity, frameImageId, rune)
    local playerName = "Player_" .. playerIndex
    local btnIndex = self:GetOptionBtnIndex(playerIndex, optionIndex)
    local iconBtnIndex = self:GetOptionIconBtnIndex(playerIndex, optionIndex)
    local textIndex = self:GetOptionTextIndex(playerIndex, optionIndex)
    local optionText = self:GetRuneCompactTitle(rune)
    local optionTitleSize = self:GetRuneTitleFontSize(rune, self.OptionCardWidth)
    local optionDesc = self:GetRuneDescription(rune)
    local hoverDesc = format("%s\n%s", self:GetRuneDisplayName(rune), optionDesc)
    -- 3 张竖卡水平紧凑居中排列
    local totalWidth = self.OptionCardWidth * 3 + self.OptionCardSpacing * 2
    local startX = self.CenterX - totalWidth / 2
    local x = startX + (optionIndex - 1) * (self.OptionCardWidth + self.OptionCardSpacing)
    local y = self.CenterY - self.OptionCardHeight / 2 - 30

    -- 卡框按钮（TextureName 接受数字图片 ID）
    exCreateCustomButtonForPlayer(playerName, {
        Index = btnIndex,
        TextureName = frameImageId,
        Desc = hoverDesc,
        X = x,
        Y = y,
        SizeX = self.OptionCardWidth,
        SizeY = self.OptionCardHeight,
        GroupIndex = btnIndex,
        AlignX = "left",
        AlignY = "top",
    })
    -- 日冕原生图标：卡片顶部居中。图标按钮与卡框拥有相同详情和点击行为。
    local iconSize = self.OptionIconSize
    exCreateCustomButtonForPlayer(playerName, {
        Index = iconBtnIndex,
        TextureName = rune.Icon,
        Desc = hoverDesc,
        X = x + (self.OptionCardWidth - iconSize) / 2,
        Y = y + 20,
        SizeX = iconSize,
        SizeY = iconSize,
        GroupIndex = iconBtnIndex,
        AlignX = "left",
        AlignY = "top",
    })
    -- 刷新/重建按钮时引擎默认深度不稳定，固定图标在稀有度卡框上方。
    exCustomBtnGroupSortDepthAboveAnotherGroup(iconBtnIndex, btnIndex)
    -- 卡面只保留图标和标题；完整效果放入卡框/图标的原生悬浮详情框。
    exCreateCustomTextForPlayer(playerName, {
        Index = textIndex,
        Content = optionText,
        X = self:GetCenteredTextLeftX(x + self.OptionCardWidth / 2
            + self:GetRuneTitleVisualOffsetX(rune, false),
            optionText, optionTitleSize),
        Y = y + 108,
        Color = 16777215,
        Size = optionTitleSize,
        AlignX = "left",
        AlignY = "top",
    })
end

function HextechRune:IsHumanPlayer(playerIndex)
    return EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY",
        "Player_" .. playerIndex, "Human")
end

function HextechRune:CreateRerollButton(playerIndex, optionIndex)
    local playerName = "Player_" .. playerIndex
    local totalWidth = self.OptionCardWidth * 3 + self.OptionCardSpacing * 2
    local startX = self.CenterX - totalWidth / 2
    local cardX = startX + (optionIndex - 1) * (self.OptionCardWidth + self.OptionCardSpacing)
    local cardY = self.CenterY - self.OptionCardHeight / 2 - 30
    local used = self.PlayerRerollUsed[playerIndex] == true
    exCreateCustomButtonForPlayer(playerName, {
        Index = self:GetRerollBtnIndex(playerIndex, optionIndex),
        TextureName = used and g_HextechRerollUsedBtnId or g_HextechRerollBtnId,
        Desc = Localization.get(used and "hextech.reroll.used" or "hextech.reroll.available"),
        X = cardX + (self.OptionCardWidth - self.RerollButtonWidth) / 2,
        Y = cardY + self.OptionCardHeight + 4,
        SizeX = self.RerollButtonWidth,
        SizeY = self.RerollButtonHeight,
        GroupIndex = self:GetRerollBtnIndex(playerIndex, optionIndex),
        AlignX = "left",
        AlignY = "top",
    })
end

function HextechRune:RefreshRerollButtons(playerIndex)
    local playerName = "Player_" .. playerIndex
    for optionIndex = 1, 3, 1 do
        local buttonIndex = self:GetRerollBtnIndex(playerIndex, optionIndex)
        exCustomBtnSetVisibilityForPlayer(playerName, buttonIndex, 0)
        exCustomBtnRemoveForPlayer(playerName, buttonIndex)
        self:CreateRerollButton(playerIndex, optionIndex)
    end
end

function HextechRune:HideSelectionHint(playerIndex)
    exCustomTextUpdateVisibilityForPlayer("Player_" .. playerIndex,
        self:GetSelectionHintTextIndex(playerIndex), 0)
end

function HextechRune:ShowSelectionHint(playerIndex)
    local playerName = "Player_" .. playerIndex
    local hint = Localization.get("hextech.selection.hidden_hint")
    exCreateCustomTextForPlayer(playerName, {
        Index = self:GetSelectionHintTextIndex(playerIndex),
        Content = hint,
        X = self:GetCenteredTextLeftX(self.SelectionHintCenterX, hint,
            self.SelectionHintFontSize),
        Y = self.SelectionHintY,
        Color = 16777215,
        Size = self.SelectionHintFontSize,
        AlignX = "left",
        AlignY = "top",
    })
end

function HextechRune:GetOblivionHintTextIndex(playerIndex)
    return self.OblivionHintTextIndexBase + playerIndex
end

function HextechRune:RefreshOblivionBombHint(playerIndex)
    local playerName = "Player_" .. playerIndex
    local textIndex = self:GetOblivionHintTextIndex(playerIndex)
    exCustomTextUpdateVisibilityForPlayer(playerName, textIndex, 0)
    if g_HextechOblivionBombCharges == nil
        or (g_HextechOblivionBombCharges[playerIndex] or 0) <= 0 then
        return
    end
    local hint = Localization.get("hextech.oblivion_bomb.hotkey_hint")
    exCreateCustomTextForPlayer(playerName, {
        Index = textIndex,
        Content = hint,
        X = self:GetCenteredTextLeftX(self.OblivionHintCenterX, hint,
            self.OblivionHintFontSize),
        Y = self.OblivionHintY,
        Color = 16777215,
        Size = self.OblivionHintFontSize,
        AlignX = "left",
        AlignY = "top",
    })
end

function HextechRune:SetSelectionPageVisible(playerIndex, visible)
    if self.PlayerOptions[playerIndex] == nil then
        self.PlayerSelectionVisible[playerIndex] = false
        self:HideSelectionHint(playerIndex)
        return false
    end
    local playerName = "Player_" .. playerIndex
    local visibility = 0
    if visible then
        visibility = 1
    end
    for optionIndex = 1, 3, 1 do
        local btnIndex = self:GetOptionBtnIndex(playerIndex, optionIndex)
        local iconBtnIndex = self:GetOptionIconBtnIndex(playerIndex, optionIndex)
        local rerollBtnIndex = self:GetRerollBtnIndex(playerIndex, optionIndex)
        local textIndex = self:GetOptionTextIndex(playerIndex, optionIndex)
        exCustomBtnSetVisibilityForPlayer(playerName, btnIndex, visibility)
        exCustomBtnSetVisibilityForPlayer(playerName, iconBtnIndex, visibility)
        exCustomBtnSetVisibilityForPlayer(playerName, rerollBtnIndex, visibility)
        exCustomTextUpdateVisibilityForPlayer(playerName, textIndex, visibility)
        if visible then
            exCustomBtnGroupSortDepthAboveAnotherGroup(iconBtnIndex, btnIndex)
        end
    end
    self.PlayerSelectionVisible[playerIndex] = visible
    if visible then
        self:HideSelectionHint(playerIndex)
    else
        self:ShowSelectionHint(playerIndex)
    end
    return true
end

function HextechRune:ToggleSelectionPage(playerIndex)
    if self.PlayerOptions[playerIndex] == nil then
        self:HideSelectionHint(playerIndex)
        return false
    end
    return self:SetSelectionPageVisible(playerIndex,
        self.PlayerSelectionVisible[playerIndex] ~= true)
end

function HextechRune:HandleSelectionHotKey(playerName)
    for playerIndex = 1, 6, 1 do
        if playerName == "Player_" .. playerIndex then
            return self:ToggleSelectionPage(playerIndex)
        end
    end
    return false
end

function HextechRune:IsRuneInCurrentOptions(options, candidate, ignoredOptionIndex)
    local candidateId = self:GetRuneOwnershipId(candidate)
    for optionIndex = 1, getn(options), 1 do
        if optionIndex ~= ignoredOptionIndex
            and self:GetRuneOwnershipId(options[optionIndex]) == candidateId then
            return true
        end
    end
    return false
end

function HextechRune:PickRerollReplacement(playerIndex, optionIndex)
    local options = self.PlayerOptions[playerIndex]
    if options == nil or options[optionIndex] == nil then
        return nil
    end
    local oldRune = options[optionIndex]
    local oldId = self:GetRuneOwnershipId(oldRune)
    local pool = self:BuildFilteredPool(playerIndex, oldRune.Rarity)
    local candidates = {}
    for i = 1, getn(pool), 1 do
        local candidate = pool[i]
        if self:GetRuneOwnershipId(candidate) ~= oldId
            and not self:IsRuneInCurrentOptions(options, candidate, optionIndex) then
            tinsert(candidates, candidate)
        end
    end
    if getn(candidates) == 0 then
        return nil
    end
    return candidates[self:RandomIndex(getn(candidates))]
end

function HextechRune:HandleRerollClick(playerIndex, optionIndex)
    if self.PlayerRerollUsed[playerIndex] or self.PlayerOptions[playerIndex] == nil then
        return
    end
    local replacement = self:PickRerollReplacement(playerIndex, optionIndex)
    if replacement == nil then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("hextech.reroll.failed"), 6)
        return
    end
    self.PlayerRerollUsed[playerIndex] = true
    self.PlayerOptions[playerIndex][optionIndex] = replacement
    local playerName = "Player_" .. playerIndex
    local btnIndex = self:GetOptionBtnIndex(playerIndex, optionIndex)
    local iconBtnIndex = self:GetOptionIconBtnIndex(playerIndex, optionIndex)
    local textIndex = self:GetOptionTextIndex(playerIndex, optionIndex)
    exCustomBtnSetVisibilityForPlayer(playerName, btnIndex, 0)
    exCustomBtnRemoveForPlayer(playerName, btnIndex)
    exCustomBtnSetVisibilityForPlayer(playerName, iconBtnIndex, 0)
    exCustomBtnRemoveForPlayer(playerName, iconBtnIndex)
    exCustomTextUpdateVisibilityForPlayer(playerName, textIndex, 0)
    self:CreateOptionBox(playerIndex, optionIndex, replacement.Rarity,
        self.RarityFrameImageIds[replacement.Rarity], replacement)
    self:RefreshRerollButtons(playerIndex)
end

-- 正式事件中的遭遇战电脑不显示三选一界面，直接从自己的同阶筛选池抽一个。
function HextechRune:GrantRandomRuneToComputer(playerIndex, rarity, round)
    local rune = self:PickOneRune(playerIndex, rarity)
    if rune == nil then
        return false
    end
    if not self:AddOwnedRune(playerIndex, rune) then
        return false
    end
    self.PlayerOptions[playerIndex] = nil
    self:OnRuneChosen(playerIndex, rune)
    return true
end

function HextechRune:EnsurePlayerEventQueue(playerIndex)
    if self.PlayerEventQueues[playerIndex] == nil then
        self.PlayerEventQueues[playerIndex] = {}
    end
    return self.PlayerEventQueues[playerIndex]
end

-- 真正展示时才根据玩家最新持有状态筛池，避免排队期间刚选到的唯一符文
-- 仍残留在后续事件的候选中。
function HextechRune:ShowRuneOptionsForPlayer(playerIndex, rarity)
    local options = self:PickThreeRunes(playerIndex, rarity)
    if options == nil then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("hextech.error.not_enough_candidates"), 10)
        return false
    end
    self.PlayerOptions[playerIndex] = options
    self.PlayerRerollUsed[playerIndex] = false
    for i = 1, 3, 1 do
        local rune = options[i]
        self:CreateOptionBox(playerIndex, i, rarity,
            self.RarityFrameImageIds[rarity], rune)
        self:CreateRerollButton(playerIndex, i)
    end
    self.PlayerSelectionVisible[playerIndex] = true
    self:HideSelectionHint(playerIndex)
    return true
end

function HextechRune:QueueOrShowRuneEvent(playerIndex, rarity, round)
    if self.PlayerOptions[playerIndex] == nil then
        return self:ShowRuneOptionsForPlayer(playerIndex, rarity)
    end
    local queue = self:EnsurePlayerEventQueue(playerIndex)
    tinsert(queue, { Rarity = rarity, Round = round })
    return true
end

function HextechRune:ShowNextQueuedRuneEvent(playerIndex)
    if self.PlayerOptions[playerIndex] ~= nil then
        return false
    end
    local queue = self:EnsurePlayerEventQueue(playerIndex)
    while getn(queue) > 0 do
        local event = tremove(queue, 1)
        if self:ShowRuneOptionsForPlayer(playerIndex, event.Rarity) then
            return true
        end
    end
    return false
end

-- 真实符文事件：先确定全场稀有度，再按玩家身份处理。
-- 真人独立筛池并无放回抽 3 个进行选择；遭遇战电脑直接随机获得同阶符文 1 个。
function HextechRune:ShowRuneEvent(round)
    local rarity = self:RollFieldRarity(round)
    for playerIndex = 1, 6, 1 do
        -- 仅对存在的玩家触发（有建筑的玩家）
        local playerName = "Player_" .. playerIndex
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if structureCount > 0 then
            if self:IsHumanPlayer(playerIndex) then
                self:QueueOrShowRuneEvent(playerIndex, rarity, round)
            else
                self:GrantRandomRuneToComputer(playerIndex, rarity, round)
            end
        end
    end
end

function HextechRune:ShowFormalEvent(round)
    self:ShowRuneEvent(round)
end

-- 处理玩家点击方框（记录选择并关闭方框）
function HextechRune:HandleOptionClick(playerIndex, optionIndex)
    local options = self.PlayerOptions[playerIndex]
    if options == nil or options[optionIndex] == nil then
        return
    end
    local rune = options[optionIndex]
    if not self:AddOwnedRune(playerIndex, rune) then
        return
    end
    self.PlayerOptions[playerIndex] = nil
    self.PlayerSelectionVisible[playerIndex] = false
    self:HideSelectionHint(playerIndex)
    self:OnRuneChosen(playerIndex, rune)
    -- 移除该玩家的 3 个方框按钮和文字。
    -- 注意：先隐藏按钮（exCustomBtnSetVisibilityForPlayer 0）再移除，
    -- 否则引擎的原生悬浮详情窗（Desc 文本）会在按钮移除后残留。
    for i = 1, 3, 1 do
        local btnIndex = self:GetOptionBtnIndex(playerIndex, i)
        local iconBtnIndex = self:GetOptionIconBtnIndex(playerIndex, i)
        local rerollBtnIndex = self:GetRerollBtnIndex(playerIndex, i)
        local textIndex = self:GetOptionTextIndex(playerIndex, i)
        exCustomBtnSetVisibilityForPlayer("Player_" .. playerIndex, btnIndex, 0)
        exCustomBtnRemoveForPlayer("Player_" .. playerIndex, btnIndex)
        exCustomBtnSetVisibilityForPlayer("Player_" .. playerIndex, iconBtnIndex, 0)
        exCustomBtnRemoveForPlayer("Player_" .. playerIndex, iconBtnIndex)
        exCustomBtnSetVisibilityForPlayer("Player_" .. playerIndex, rerollBtnIndex, 0)
        exCustomBtnRemoveForPlayer("Player_" .. playerIndex, rerollBtnIndex)
        exCustomTextUpdateVisibilityForPlayer("Player_" .. playerIndex, textIndex, 0)
    end
    local msg = Localization.get("hextech.picked", self:GetRuneDisplayName(rune))
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, msg, 10)
    -- 若总览面板正处于展开状态，立即用真实持有数据刷新。
    if self.PanelVisible[playerIndex] then
        self:HidePanel(playerIndex)
        self:ShowPanel(playerIndex)
    end
    -- 后续正式事件若已到点，则在当前三选一关闭后立即按先进先出展示。
    self:ShowNextQueuedRuneEvent(playerIndex)
end

-- ===== 海克斯面板（按钮 5 展开）=====
-- 面板显示上三玩家（天使 4/5/6）与下三玩家（恶魔 1/2/3）的海克斯符文。
-- 面板内容直接读取每名玩家真实拥有的符文。

-- 计算某玩家面板符文按钮 index（slot 1..PanelMaxRuneCount）
-- 注意：每玩家必须预留 PanelMaxRuneCount（4）个 index，否则 4 个符文时
--       玩家 i 的第 4 个符文会与玩家 i+1 的第 1 个符文共用 index（被覆盖）。
function HextechRune:GetPanelRuneBtnIndex(playerIndex, slot)
    return self.PanelBtnIndexBase + (playerIndex - 1) * self.PanelMaxRuneCount + slot
end

function HextechRune:GetPanelRuneIconBtnIndex(playerIndex, slot)
    return self.PanelIconBtnIndexBase + (playerIndex - 1) * self.PanelMaxRuneCount + slot
end

function HextechRune:GetPanelRuneTextIndex(playerIndex, slot)
    return self.PanelRuneTextIndexBase + (playerIndex - 1) * self.PanelMaxRuneCount + slot
end

-- 计算某玩家面板名字文字 index
function HextechRune:GetPanelNameTextIndex(playerIndex)
    return self.PanelTextIndexBase + playerIndex
end

-- 计算某玩家面板标题文字 index
function HextechRune:GetPanelTitleTextIndex(playerIndex)
    return self.PanelTitleTextBase + playerIndex
end

-- 计算某玩家面板关闭按钮 index
function HextechRune:GetPanelCloseBtnIndex(playerIndex)
    return self.PanelCloseBtnBase + playerIndex
end

-- 判断某玩家是否存活（有建筑）
function HextechRune:IsPlayerAlive(playerIndex)
    local playerName = "Player_" .. playerIndex
    local previous = SetWorldBuilderThisPlayer(1)
    local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
    SetWorldBuilderThisPlayer(previous)
    return structureCount > 0
end

-- 显示面板（对单个玩家），内容为六名玩家真实拥有的符文。
function HextechRune:ShowPanel(playerIndex)
    local playerName = "Player_" .. playerIndex
    self:EnsurePlayerRuneState(playerIndex)
    -- 标题（固定居中于屏幕中央，不随面板整体左移）
    local titleTextIndex = self:GetPanelTitleTextIndex(playerIndex)
    local panelTitle = Localization.get("hextech.panel.title")
    exCreateCustomTextForPlayer(playerName, {
        Index = titleTextIndex,
        Content = panelTitle,
        X = self:GetCenteredTextLeftX(self.PanelTitleCenterX, panelTitle, 24),
        Y = 180,
        Color = 16777215,
        Size = 24,
        AlignX = "left",
        AlignY = "center",
    })
    -- 关闭按钮（右上角，使用 hextechRemoveButton 图标，不显示悬浮详情框）
    local closeBtnIndex = self:GetPanelCloseBtnIndex(playerIndex)
    exCreateCustomButtonForPlayer(playerName, {
        Index = closeBtnIndex,
        TextureName = g_HextechRemoveBtnId,
        Desc = "",
        X = self.PanelCenterX + 320,
        Y = 175,
        SizeX = 76,
        SizeY = 46,
        GroupIndex = closeBtnIndex,
        AlignX = "left",
        AlignY = "top",
    })
    -- 6 个玩家：上三 = 4,5,6（天使，名字行1 符文行2）；下三 = 1,2,3（恶魔，符文行3 名字行4）
    -- 列顺序：列1=左，列2=中，列3=右。上三玩家按 4,5,6 对应列1,2,3；下三玩家按 1,2,3 对应列1,2,3
    for col = 1, 3, 1 do
        -- 上三玩家（天使）：玩家 3 + col → 4,5,6
        local angelIndex = 3 + col
        local colX = self.PanelCenterX + (col - 2) * self.PanelColumnGap
        -- 名字行1（上三玩家名）
        self:CreatePanelNameText(playerIndex, angelIndex, colX, self.PanelRowY[1])
        -- 符文行2（上三玩家符文）
        self:CreatePanelRuneRow(playerIndex, angelIndex, colX, self.PanelRowY[2])
        -- 下三玩家（恶魔）：玩家 col → 1,2,3
        local devilIndex = col
        -- 符文行3（下三玩家符文）
        self:CreatePanelRuneRow(playerIndex, devilIndex, colX, self.PanelRowY[3])
        -- 名字行4（下三玩家名）
        self:CreatePanelNameText(playerIndex, devilIndex, colX, self.PanelRowY[4])
    end
    self.PanelVisible[playerIndex] = true
end

-- 创建单个玩家名文字（垂直居中于所在行；Content 用 $pNName，引擎支持时显示真实昵称）
function HextechRune:CreatePanelNameText(viewerIndex, targetIndex, x, y)
    local viewerName = "Player_" .. viewerIndex
    local nameTextIndex = self:GetPanelNameTextIndex(targetIndex)
    local nameText = "$p" .. targetIndex .. "Name"
    exCreateCustomTextForPlayer(viewerName, {
        Index = nameTextIndex,
        Content = nameText,
        X = self:GetCenteredTextLeftX(x, nameText, 16),
        Y = y,
        Color = 16777215,
        Size = 16,
        AlignX = "left",
        AlignY = "center",
    })
end

-- 创建某玩家的一行真实符文（当前最多显示 4 个，水平一排并居中于列）。
function HextechRune:CreatePanelRuneRow(viewerIndex, targetIndex, colX, y)
    local viewerName = "Player_" .. viewerIndex
    self:EnsurePlayerRuneState(targetIndex)
    local owned = self.PlayerOwnedRunes[targetIndex]
    -- 质变和赌怪属于即时奖励入口，面板只展示它们实际产出的符文。
    local displayRunes = {}
    for ownedIndex = 1, getn(owned), 1 do
        local ownedRune = owned[ownedIndex]
        if ownedRune.Effect ~= "quality_transformation"
            and ownedRune.Effect ~= "gambling_addict" then
            tinsert(displayRunes, ownedRune)
        end
    end
    local count = getn(displayRunes)
    if count > self.PanelMaxRuneCount then
        count = self.PanelMaxRuneCount
    end
    if count == 0 then
        return
    end
    -- 真实符文水平一排，整体居中于列中心 colX
    local totalWidth = self.PanelRuneWidth * count + self.PanelRuneGap * (count - 1)
    local startX = colX - totalWidth / 2
    for slot = 1, count, 1 do
        local rune = displayRunes[slot]
        local rarity = rune.Rarity
        local btnIndex = self:GetPanelRuneBtnIndex(targetIndex, slot)
        local iconBtnIndex = self:GetPanelRuneIconBtnIndex(targetIndex, slot)
        local runeTextIndex = self:GetPanelRuneTextIndex(targetIndex, slot)
        local runeTitle = self:GetRuneCompactTitle(rune)
        local runeTitleSize = self:GetRuneTitleFontSize(rune, self.PanelRuneHeight)
        local x = startX + (slot - 1) * (self.PanelRuneWidth + self.PanelRuneGap)
        local topY = y - self.PanelRuneHeight / 2
        local runeDesc = format("%s\n%s", self:GetRuneDisplayName(rune), self:GetRuneDescription(rune))
        exCreateCustomButtonForPlayer(viewerName, {
            Index = btnIndex,
            TextureName = self.RarityFrameImageIds[rarity],
            Desc = runeDesc,
            X = x,
            Y = topY,
            SizeX = self.PanelRuneWidth,
            SizeY = self.PanelRuneHeight,
            GroupIndex = btnIndex,
            AlignX = "left",
            AlignY = "top",
        })
        -- 总览面板沿用相同比例布局，但卡框和图标都更小。
        local iconSize = self.PanelRuneIconSize
        exCreateCustomButtonForPlayer(viewerName, {
            Index = iconBtnIndex,
            TextureName = rune.Icon,
            Desc = runeDesc,
            X = x + (self.PanelRuneWidth - iconSize) / 2,
            Y = topY + 5,
            SizeX = iconSize,
            SizeY = iconSize,
            GroupIndex = iconBtnIndex,
            AlignX = "left",
            AlignY = "top",
        })
        -- 面板重建时同样固定层级，避免黑色卡框偶发遮住图标。
        exCustomBtnGroupSortDepthAboveAnotherGroup(iconBtnIndex, btnIndex)
        exCreateCustomTextForPlayer(viewerName, {
            Index = runeTextIndex,
            Content = runeTitle,
            X = self:GetCenteredTextLeftX(x + self.PanelRuneWidth / 2
                + self:GetRuneTitleVisualOffsetX(rune, true) - 6,
                runeTitle, runeTitleSize),
            Y = topY + 30,
            Color = 16777215,
            Size = runeTitleSize,
            AlignX = "left",
            AlignY = "top",
        })
    end
end

-- 隐藏面板（对单个玩家）：移除全部面板元素
function HextechRune:HidePanel(playerIndex)
    local playerName = "Player_" .. playerIndex
    -- 移除符文按钮（先隐藏再移除，避免原生悬浮详情窗残留）
    for targetIndex = 1, 6, 1 do
        for slot = 1, self.PanelMaxRuneCount, 1 do
            local btnIndex = self:GetPanelRuneBtnIndex(targetIndex, slot)
            local iconBtnIndex = self:GetPanelRuneIconBtnIndex(targetIndex, slot)
            local runeTextIndex = self:GetPanelRuneTextIndex(targetIndex, slot)
            exCustomBtnSetVisibilityForPlayer(playerName, btnIndex, 0)
            exCustomBtnRemoveForPlayer(playerName, btnIndex)
            exCustomBtnSetVisibilityForPlayer(playerName, iconBtnIndex, 0)
            exCustomBtnRemoveForPlayer(playerName, iconBtnIndex)
            exCustomTextUpdateVisibilityForPlayer(playerName, runeTextIndex, 0)
        end
        -- 移除名字文字
        local nameTextIndex = self:GetPanelNameTextIndex(targetIndex)
        exCustomTextUpdateVisibilityForPlayer(playerName, nameTextIndex, 0)
    end
    -- 移除标题文字
    local titleTextIndex = self:GetPanelTitleTextIndex(playerIndex)
    exCustomTextUpdateVisibilityForPlayer(playerName, titleTextIndex, 0)
    -- 移除关闭按钮（先隐藏再移除）
    local closeBtnIndex = self:GetPanelCloseBtnIndex(playerIndex)
    exCustomBtnSetVisibilityForPlayer(playerName, closeBtnIndex, 0)
    exCustomBtnRemoveForPlayer(playerName, closeBtnIndex)
    self.PanelVisible[playerIndex] = false
end

-- 切换面板（按钮 5 点击）
function HextechRune:TogglePanel(playerIndex)
    if self.PanelVisible[playerIndex] then
        self:HidePanel(playerIndex)
    else
        self:ShowPanel(playerIndex)
    end
end

-- 注册自定义按钮点击处理（屏幕中央方框 + 海克斯面板）
-- 注意：回调闭包内不使用外层局部变量（Lua 4.0 约束），一律用全局 HextechRune 访问。
function HextechRune:RegisterCustomBtnHandler()
    if HextechRune._btnHandlerRegistered then
        return
    end
    HextechRune._btnHandlerRegistered = true
    ButtonManager:RegisterCustomButtonHandler(function(playerName, index)
        -- 海克斯面板关闭按钮（500 + playerIndex）
        if index > HextechRune.PanelCloseBtnBase and index <= HextechRune.PanelCloseBtnBase + 6 then
            local pIndex = index - HextechRune.PanelCloseBtnBase
            if pIndex >= 1 and pIndex <= 6 and playerName == "Player_" .. pIndex then
                HextechRune:HidePanel(pIndex)
                return true
            end
            return nil
        end
        -- 三张事件卡下方的重随按钮共享一次机会，只替换被点击的那张卡。
        if index > HextechRune.RerollBtnIndexBase
            and index <= HextechRune.RerollBtnIndexBase + 18 then
            local rerollOffset = index - HextechRune.RerollBtnIndexBase - 1
            local rerollPlayerIndex = floor(rerollOffset / 3) + 1
            local rerollOptionIndex = mod(rerollOffset, 3) + 1
            if rerollPlayerIndex >= 1 and rerollPlayerIndex <= 6
                and playerName == "Player_" .. rerollPlayerIndex
                and HextechRune.PlayerOptions[rerollPlayerIndex] then
                HextechRune:HandleRerollClick(rerollPlayerIndex, rerollOptionIndex)
                return true
            end
        end
        -- 事件卡片的原生图标按钮与下层卡框按钮执行同一个选择。
        if index > HextechRune.CustomIconBtnIndexBase
            and index <= HextechRune.CustomIconBtnIndexBase + 18 then
            local iconOffset = index - HextechRune.CustomIconBtnIndexBase - 1
            local iconPlayerIndex = floor(iconOffset / 3) + 1
            local iconOptionIndex = mod(iconOffset, 3) + 1
            if iconPlayerIndex >= 1 and iconPlayerIndex <= 6
                and playerName == "Player_" .. iconPlayerIndex
                and HextechRune.PlayerOptions[iconPlayerIndex] then
                HextechRune:HandleOptionClick(iconPlayerIndex, iconOptionIndex)
                return true
            end
        end
        -- 解析 index 属于哪位玩家的哪个方框
        if index > HextechRune.CustomBtnIndexBase
            and index <= HextechRune.CustomBtnIndexBase + 18 then
            local offset = index - HextechRune.CustomBtnIndexBase - 1
            local playerIndex = floor(offset / 3) + 1
            local optionIndex = mod(offset, 3) + 1
            if playerIndex >= 1 and playerIndex <= 6 and optionIndex >= 1 and optionIndex <= 3
                and playerName == "Player_" .. playerIndex then
                if HextechRune.PlayerOptions[playerIndex] then
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
    self:OnFiveThunderRoundBegin(round)
    self:OnTeslaAirAssaultRoundBegin(round)
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
    -- 注册成功时若回合已经开始，立即补一次当前回合状态同步。
    local currentRound = exCounterGetByName("lvc")
    if currentRound ~= nil and currentRound >= 1 then
        HextechRune:OnRoundBegin(currentRound)
    end
end

-- 注册自定义按钮点击处理（屏幕中央方框）
HextechRune:RegisterCustomBtnHandler()

-- 注册回合开始回调（RoundLuaManager 就绪后自动注册，无需轮询）
HextechRune:RegisterRoundBegin()
