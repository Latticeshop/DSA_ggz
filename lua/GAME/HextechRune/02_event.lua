-- 讲解见 analysis/地图注释说明文档.md 附录 A.11、A.35、A.38、A.45

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

-- 最近一次回合开始回调的回合号；准备背包据此判断本场是否还有下一次正式事件。
HextechRune.CurrentRound = 0
-- 准备背包：待消费的升阶机会（按玩家），以及本次事件的真实候选张数（1~3 张）。
HextechRune.PendingRuneAscend = {}
HextechRune.PlayerOptionCount = {}
-- 顺手的事：待消费的「多拿一张」（按玩家），以及当前这次选择里还剩几次多拿的机会。
HextechRune.PendingExtraRunePick = {}
HextechRune.PlayerExtraPickRemaining = {}

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
-- 纯 ASCII 长标题相对估宽需要额外右移的「字母宽度」个数。
HextechRune.AsciiLongTitleShiftLetters = 1
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
-- 左右两块托盘 + 中央竖分隔线，左列恶魔（1/2/3）、右列天使（4/5/6），
-- 列内自上而下按座位号排，空座位跳过（2v2 两行、1v1 一行），
-- 每行 =「玩家名 + 至多 5 张 50x50 小卡」（index 预留 6 格）。
-- 标题「海克斯面板」的金渐变字已烘进底板贴图（analysis/make_hextech_panel_bg.py），
-- 所以这里不再画引擎标题文字；贴图本体是 analysis/hextech_panel_bg.png。
HextechRune.PanelSeatColumnGroups = { { 1, 2, 3 }, { 4, 5, 6 } }
-- 面板恢复原先 50x50 小卡布局；图标保留新版约三分之一的比例。
HextechRune.PanelRuneWidth = 50
HextechRune.PanelRuneHeight = 50
-- 首选卡间距；张数多到放不下时按卡区可用宽度动态收缩（见 CreatePanelRuneRow），
-- 收缩后每两个相邻卡之间的间距仍然相等。
HextechRune.PanelRuneGap = 10
HextechRune.PanelRuneIconSize = 14
HextechRune.PanelRuneTitleOffsetX = 5
-- 显示上限（设计口径）：一格最多 5 张。正式事件按 g_HextechCount 最多 3 次、每次该座位 1 张，
-- 加上「顺手的事」多拿的 1 张，「赌怪/质变」的奖励也落在这 5 张里 —— 玩家自己说的设计上限就是 5。
HextechRune.PanelMaxRuneCount = 5
-- 这一格**只是缓冲**，正常战局不会出现第 6 张；留出来的目的是保证 index 段
HextechRune.PanelIndexSlotCount = 6
-- 面板自定义元素 index 基础（避开已用 index）
HextechRune.PanelBtnIndexBase = 400      -- 符文按钮：玩家 i 的第 j 个 = 400 + (i-1)*6 + j（401~436）
HextechRune.PanelCloseBtnBase = 500      -- 关闭按钮：玩家 i = 500 + i
HextechRune.PanelTextIndexBase = 600     -- 名字文字：玩家 i = 600 + i
HextechRune.PanelIconBtnIndexBase = 700  -- 小卡图标按钮：701~736
HextechRune.PanelRuneTextIndexBase = 800 -- 小卡标题文字：801~836
-- 面板底板：g_HextechPanelBgId（960x320，上边角内凹、三层金边、标题带 + 金标题全烘进贴图）。
-- 贴图原居中位置是 683 - 480 = 203，实测偏右，2026-10-27 按用户要求整体左移两个卡宽
-- （2 * PanelRuneWidth = 100）→ 103；竖直与旧底板同心（146 + 380/2 - 160 = 176）。
HextechRune.PanelBgIndex = 490
HextechRune.PanelBgX = 103
HextechRune.PanelBgY = 176
HextechRune.PanelBgWidth = 960
HextechRune.PanelBgHeight = 320
-- 两列托盘左缘 = 底板 X + 贴图内托盘左缘（22 / 496）
HextechRune.PanelColumnX = { 125, 599 }
-- 名字左对齐于「托盘左缘 + PanelNameOffsetX」。
HextechRune.PanelNameOffsetX = 8
-- 名字字号与实测微调：引擎把 $pNName 画出来时视觉中心偏左偏下，
-- 各补半个字宽 / 半个字高（字号 16 → 右移 8、上移 8）才落在行心正中。
HextechRune.PanelNameFontSize = 16
HextechRune.PanelNameNudgeX = 8
HextechRune.PanelNameNudgeY = -8
-- 名字颜色：本座位原玩家=白；这一格已被继承（归属者 ≠ 座位号）=金。
-- 继承的既定表现是「卡牌位置不动、名字换成继承者」，所以同一个玩家会同时出现在
HextechRune.PanelNameColor = 16777215
HextechRune.PanelInheritedNameColor = 16766720
-- 原玩家退出且无人继承、符文已被清空的座位：面板不再为它留一行。
HextechRune.PanelVacantSeat = {}
-- 小卡从「托盘左缘 + PanelCardOffsetX」开始**依次右排**（不再整体居中）。
-- 卡区可用宽 = 托盘宽 442 - 偏移 100 - 右侧留白 7 = 335：
-- 6 张时 6*50 + 5*7 = 335 正好铺满，5 张及以下维持 PanelRuneGap = 10。
HextechRune.PanelCardOffsetX = 100
HextechRune.PanelCardAreaWidth = 335
-- 三行行心 y = 底板 Y + 贴图内行顶（70 / 150 / 230）+ 行高 64 的一半
HextechRune.PanelRowY = { 278, 358, 438 }
-- 关闭按钮：素材 hextechRemoveButton.png 是 76x46，实测偏大，等比缩到 56x34（约 74%）显示。
-- 位置按缩后的尺寸重摆，仍落在标题带右端、与带右缘（贴图内 946）留 20px，
-- 并避开标题带右上角 R26 的内凹圆弧，否则按钮右上角会戳到圆弧外的透明区。
HextechRune.PanelCloseSizeX = 56
HextechRune.PanelCloseSizeY = 34
HextechRune.PanelCloseOffsetX = 870
HextechRune.PanelCloseOffsetY = 13

-- 每玩家面板是否展开
HextechRune.PanelVisible = {}
-- 每次打开三选一时重置；三个按钮共享同一次使用机会。
HextechRune.PlayerRerollUsed = HextechRune.PlayerRerollUsed or {}
-- 重随次数模式 = 3 时改成按卡记（三张卡各一次）；
-- PlayerRerollHistory 记本次选择里出现过的符文，换下去的那张不再回来（一次选择最多见 6 张）。
HextechRune.PlayerRerollUsedOptions = HextechRune.PlayerRerollUsedOptions or {}
HextechRune.PlayerRerollHistory = HextechRune.PlayerRerollHistory or {}
-- 每名真人玩家独立保存尚未展示的正式符文事件；当前三选一完成后按先进先出弹出。
HextechRune.PlayerEventQueues = HextechRune.PlayerEventQueues or {}
-- 当前三选一是否实际显示；隐藏时 PlayerOptions 仍保留，J 键可原样恢复。
HextechRune.PlayerSelectionVisible = HextechRune.PlayerSelectionVisible or {}
-- 每名玩家已完成过多少次正式符文选择（点下某张卡，或遭遇战电脑直接获得符文）。
-- 与回合号无关：只用来回答「这是不是这名玩家的第一次选择」，见 IsFirstFormalSelection。
HextechRune.PlayerFormalSelectionCount = HextechRune.PlayerFormalSelectionCount or {}
-- 当前选择对应的符文槽位（正常玩家=自己；退出继承后的额外选择=被继承者槽位）。
HextechRune.PlayerOptionSlot = HextechRune.PlayerOptionSlot or {}
HextechRune.PlayerOptionRarity = HextechRune.PlayerOptionRarity or {}

-- 正式海克斯事件发放回合（按 g_HextechCount 取前 N 个）
HextechRune.FormalRounds = { 3, 10, 18, 27 }

-- 1（默认）＝ 当下行为：本次选择三张卡共用一次重随。
-- 3 ＝ 三张卡各能重随一次（总共最多 3 次）；配合「换下去的那张不再回来」，
-- 按钮在 BtnChoiceDialogEventFunc_ShowHextechModeDialog 里，点击调 HextechRerollModeToggle。
g_HextechRerollMode = g_HextechRerollMode or 1
-- 房主手动点过这一行（哪怕点完又切回 1 次）＝ 明确要按次数走，单人无限重随关掉。
g_HextechRerollManual = g_HextechRerollManual or 0

-- 这一行不带「(已选择)」后缀：对话框按钮单行显示，加了会溢出（值本身已写明 1次 / 3次）。
function HextechRerollModeLabel()
    local mode = g_HextechRerollMode
    if mode ~= 3 then
        mode = 1
    end
    return Localization.get("hextech.reroll_mode.label")
        .. Localization.get("hextech.reroll_mode." .. mode)
end

function HextechRerollModeToggle()
    -- 先取「切换前」的状态：单人无限重随被这一下关掉时，要额外播一句解释。
    local wasUnlimited = HextechRune ~= nil and HextechRune:IsUnlimitedReroll()
    if g_HextechRerollMode == 3 then
        g_HextechRerollMode = 1
    else
        g_HextechRerollMode = 3
    end
    g_HextechRerollManual = 1
    exMessageAppendToMessageArea(
        Localization.get("game_mode.host.selected", HextechRerollModeLabel()))
    if wasUnlimited then
        exMessageAppendToMessageArea(
            Localization.get("hextech.solo.unlimited_reroll_off"))
    end
end

-- 切完重画这一页。放在这里而不是 BtnChoiceDialogEventFunc.lua：那个 payload 已经贴着
-- 65536 上限（去注释后 64997 B，余 539 B），页面里只留一行调用。
function HextechRerollModeApply(dialog)
    HextechRerollModeToggle()
    dialog:RefreshData()
    ButtonChoiceDialogManager:ShowDialog(dialog)
end

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
function HextechRune:GetRuneTitleVisualOffsetX(rune, isPanel)
    local name = Localization.get(rune.NameKey)
    local characterCount = self:GetTextMaxCharacterCount(name)
    -- ASCII 字母只有 0.55 个汉字宽，直接按 4 字档排实测偏右，折算 3.1 → 落 3 字档正好居中。
    local visualUnits = self:GetTextMaxVisualUnits(name)
    if visualUnits < characterCount then
        characterCount = floor(visualUnits + 0.5)
    end
    -- 全频段阻塞干扰在卡面显示为“全频段阻塞 / 干扰”，以最宽的
    -- 五字行实测校正；不用未换行的七字本地化名称分档。
    if rune.Effect == "broadband_jamming" then
        if isPanel then
            return 9
        end
        return 22
    end
    -- 艾卡西亚的惊喜在卡面拆成「艾卡西亚 / 的惊喜」（见 01 的 GetRuneCompactTitle），
    -- 分档要按最宽那一行的 4 字算，不能用未换行的七字名称。
    if rune.Effect == "grant_time_bomb" then
        characterCount = 4
    end
    -- 纯 ASCII 长标题右移 AsciiLongTitleShiftLetters 个字母宽度，字母宽度与估宽同套系数、按字号换算。
    if characterCount > 3 and self:IsAsciiText(name) then
        local letterWidth = self.AsciiWidthWeight * self.TextWidthScale
            * self:GetRuneTitleFontSize(rune,
                isPanel and self.PanelRuneHeight or self.OptionCardWidth)
        local shift = self.AsciiLongTitleShiftLetters * letterWidth
        if isPanel then
            return self.PanelRuneTitleOffsetX + shift
        end
        return self.OptionTitleOffsetX + shift
    end
    -- 五字标题（变形重组器 / 升级重组器，16px、无兵种后缀）实测偏左约 2/3 个字，右移 30。
    -- 带兵种后缀的五字标题（回归基本功 / 歌莉娅巨人）字号是 14px，按 16px 那档的字号比例
    -- 折算成 26；万用瞄准镜那三档 10px 小字号实测默认值已居中，不跟着放大。
    if characterCount == 5 then
        if isPanel then
            if rune.UnitType == nil then
                return 13
            end
            return self.PanelRuneTitleOffsetX
        end
        if rune.UnitType == nil then
            return 30
        end
        if rune.Effect == "range_silver" or rune.Effect == "range_gold"
            or rune.Effect == "range_prismatic" then
            return self.OptionTitleOffsetX
        end
        return 26
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

function HextechRune:RollFieldRarity(round)
    local weightMap
    if round == self.FormalRounds[4] then
        weightMap = { [1] = 30, [2] = 50, [3] = 20 }
    elseif round <= self.FormalRounds[1] then
        -- 第一次正式事件：彩 10 / 金 40 / 银 50
        weightMap = { [1] = 10, [2] = 40, [3] = 50 }
    else
        -- 后续：彩 15 / 金 42 / 银 43
        weightMap = { [1] = 15, [2] = 42, [3] = 43 }
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

-- ===== 准备背包：按玩家把下一次符文选择的筛池阶级抬高一档 =====

-- 当前回合之后本场是否还有正式海克斯事件。
function HextechRune:HasNextFormalEvent()
    local count = g_HextechCount or 0
    for i = 1, count, 1 do
        local eventRound = self.FormalRounds[i]
        if eventRound ~= nil and eventRound > self.CurrentRound then
            return true
        end
    end
    return false
end

function HextechRune:IsFirstFormalSelection(playerIndex)
    local slotIndex = self.CurrentGrantSlot[playerIndex] or playerIndex
    return (self.SlotFormalSelectionCount[slotIndex] or 0) == 0
end

function HextechRune:MarkFormalSelectionReceived(playerIndex)
    local slotIndex = self.CurrentGrantSlot[playerIndex] or playerIndex
    self.SlotFormalSelectionCount[slotIndex] =
        (self.SlotFormalSelectionCount[slotIndex] or 0) + 1
    self.PlayerFormalSelectionCount[playerIndex] =
        (self.PlayerFormalSelectionCount[playerIndex] or 0) + 1
end

-- 棱彩已是最高阶：升不动就不该把这次机会花掉。
function HextechRune:CanAscendRuneRarity(playerIndex, rarity)
    return self.PendingRuneAscend[playerIndex] == true and rarity > 1
end

-- 升阶落地后清掉标记并全图播报，播报的是升上去的那一阶。
function HextechRune:CommitAscendRuneRarity(playerIndex, targetRarity)
    self.PendingRuneAscend[playerIndex] = nil
    exAddTextToPublicBoard(Localization.get("hextech.ascend.broadcast", playerIndex,
        Localization.get("hextech.rarity." .. self.RarityNames[targetRarity])), 10)
end

-- 本次事件的卡片张数可能少于 3（高一阶筛池候选不足），整排按实际张数居中。
function HextechRune:GetOptionTotalWidth(playerIndex)
    local count = self.PlayerOptionCount[playerIndex] or 3
    return self.OptionCardWidth * count + self.OptionCardSpacing * (count - 1)
end

-- 创建单个屏幕中央方框（按钮 + 文字）
function HextechRune:CreateOptionBox(playerIndex, optionIndex, rarity, frameImageId, rune)
    local playerName = "Player_" .. playerIndex
    local btnIndex = self:GetOptionBtnIndex(playerIndex, optionIndex)
    local iconBtnIndex = self:GetOptionIconBtnIndex(playerIndex, optionIndex)
    local textIndex = self:GetOptionTextIndex(playerIndex, optionIndex)
    local optionText = self:GetRuneCompactTitle(rune)
    local optionTitleSize = self:GetRuneTitleFontSize(rune, self.OptionCardWidth)
    local optionDesc = self:GetRuneDescription(rune, playerIndex)
    local hoverDesc = format("%s\n%s", self:GetRuneDisplayName(rune), optionDesc)
    -- 竖卡水平紧凑居中排列（张数取本次事件的实际候选数）
    local totalWidth = self:GetOptionTotalWidth(playerIndex)
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

-- 全场只有 1 名真人 ＝ 单机遭遇战。判据与 PureDrawIsHumanPlayer / AID_0 / Human_0 一致：
-- PLAYER_IS_HUMAN_OR_AI_PERSONALITY(..., "Human")；空位/关闭位在这里返回 false
-- （同 BtnChoiceDialogEventFunc_GetSideOccupiedPlayerIndices 的口径：真人看这一条，电脑看 P[i]）。
-- 遭遇战里其余座席都是电脑，电脑的三选一走 GrantRandomRuneToComputer、根本不显示界面，
-- 所以放开重随不会影响它们。
function HextechRune:IsSoloHumanGame()
    local humanCount = 0
    for playerIndex = 1, 6, 1 do
        if self:IsHumanPlayer(playerIndex) then
            humanCount = humanCount + 1
            if humanCount > 1 then
                return false
            end
        end
    end
    return humanCount == 1
end

-- 单人游玩时重随不限次数：单机刷符文只能靠重开，限一次等于没得选。
-- 房主点过「重随次数」那一行（g_HextechRerollManual = 1）就按 1 / 3 次走，无限重随关闭。
function HextechRune:IsUnlimitedReroll()
    if g_HextechRerollManual == 1 then
        return false
    end
    return self.SoloUnlimitedReroll == true
end

function HextechRune:InitSoloUnlimitedReroll()
    if self.SoloUnlimitedEvaluated then
        return
    end
    if g_EnableHextechRune ~= 1 then
        return
    end
    self.SoloUnlimitedEvaluated = true
    if self:IsSoloHumanGame() then
        self.SoloUnlimitedReroll = true
        -- 房主在开局前就点过「重随次数」那一行：无限重随已经是关的，别再播这条。
        if g_HextechRerollManual ~= 1 then
            exMessageAppendToMessageArea(
                Localization.get("hextech.solo.unlimited_reroll"))
        end
    end
end

function HextechRune:IsRerollUsed(playerIndex, optionIndex)
    if self:IsUnlimitedReroll() then
        return false
    end
    if g_HextechRerollMode == 3 then
        local used = self.PlayerRerollUsedOptions[playerIndex]
        return used ~= nil and used[optionIndex] == true
    end
    return self.PlayerRerollUsed[playerIndex] == true
end

-- 开新选择时重置重随状态，并把初始三张记进 history（3 次模式靠它保证不重复）。
function HextechRune:ResetRerollState(playerIndex, options)
    self.PlayerRerollUsed[playerIndex] = false
    self.PlayerRerollUsedOptions[playerIndex] = {}
    local history = {}
    for i = 1, getn(options), 1 do
        tinsert(history, self:GetRuneOwnershipId(options[i]))
    end
    self.PlayerRerollHistory[playerIndex] = history
end

function HextechRune:IsRuneRerolledAway(playerIndex, runeId)
    local history = self.PlayerRerollHistory[playerIndex]
    if history == nil then
        return false
    end
    for i = 1, getn(history), 1 do
        if history[i] == runeId then
            return true
        end
    end
    return false
end

function HextechRune:CreateRerollButton(playerIndex, optionIndex)
    local playerName = "Player_" .. playerIndex
    local totalWidth = self:GetOptionTotalWidth(playerIndex)
    local startX = self.CenterX - totalWidth / 2
    local cardX = startX + (optionIndex - 1) * (self.OptionCardWidth + self.OptionCardSpacing)
    local cardY = self.CenterY - self.OptionCardHeight / 2 - 30
    local used = self:IsRerollUsed(playerIndex, optionIndex)
    local descKey = "hextech.reroll.available"
    if used then
        descKey = "hextech.reroll.used"
    elseif self:IsUnlimitedReroll() then
        descKey = "hextech.reroll.available_solo"
    elseif g_HextechRerollMode == 3 then
        descKey = "hextech.reroll.available_three"
    end
    exCreateCustomButtonForPlayer(playerName, {
        Index = self:GetRerollBtnIndex(playerIndex, optionIndex),
        TextureName = used and g_HextechRerollUsedBtnId or g_HextechRerollBtnId,
        Desc = Localization.get(descKey),
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
    -- 顺手的事重排之后候选可能少于 3 张：只重建实际还在的那些，
    -- 否则空位（尤其整排已按较少张数居中时的右侧空位）会留一颗没用的重随按钮。
    local count = self.PlayerOptionCount[playerIndex] or 3
    for optionIndex = 1, 3, 1 do
        local buttonIndex = self:GetRerollBtnIndex(playerIndex, optionIndex)
        exCustomBtnSetVisibilityForPlayer(playerName, buttonIndex, 0)
        exCustomBtnRemoveForPlayer(playerName, buttonIndex)
        if optionIndex <= count then
            self:CreateRerollButton(playerIndex, optionIndex)
        end
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
        return self:ShowNextQueuedRuneEvent(playerIndex)
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
    -- fresh：本页没出现过的（3 次模式下优先，保证最多见到 6 张不同的卡）；
    -- loose：本页换下去过的（同阶池不足 6 张时用它兜底，宁可重复也不让按钮点不动）。
    local fresh = {}
    local loose = {}
    for i = 1, getn(pool), 1 do
        local candidate = pool[i]
        local candidateId = self:GetRuneOwnershipId(candidate)
        if candidateId ~= oldId
            and not self:IsRuneInCurrentOptions(options, candidate, optionIndex) then
            if g_HextechRerollMode == 3
                and self:IsRuneRerolledAway(playerIndex, candidateId) then
                tinsert(loose, candidate)
            else
                tinsert(fresh, candidate)
            end
        end
    end
    if getn(fresh) > 0 then
        return fresh[self:RandomIndex(getn(fresh))]
    end
    if getn(loose) > 0 then
        return loose[self:RandomIndex(getn(loose))]
    end
    -- 单人无限重随：同阶池小到「去掉当前三张就没得换」时允许重复（含同一张），
    -- 否则重随按钮会卡在「没有可替换的同阶符文」上，白点一次；
    -- 多人局仍返回 nil，保持「失败不消耗」的老行为。
    if not self:IsUnlimitedReroll() then
        return nil
    end
    local fallback = {}
    for i = 1, getn(pool), 1 do
        if getn(pool) == 1 or self:GetRuneOwnershipId(pool[i]) ~= oldId then
            tinsert(fallback, pool[i])
        end
    end
    if getn(fallback) == 0 then
        return nil
    end
    return fallback[self:RandomIndex(getn(fallback))]
end

function HextechRune:HandleRerollClick(playerIndex, optionIndex)
    if self:IsRerollUsed(playerIndex, optionIndex) or self.PlayerOptions[playerIndex] == nil then
        return
    end
    local replacement = self:PickRerollReplacement(playerIndex, optionIndex)
    if replacement == nil then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("hextech.reroll.failed"), 6)
        return
    end
    -- 单人游玩不记「已用」：按钮保持可用，可以一直随到想要的那张。
    if not self:IsUnlimitedReroll() then
        if g_HextechRerollMode == 3 then
            if self.PlayerRerollUsedOptions[playerIndex] == nil then
                self.PlayerRerollUsedOptions[playerIndex] = {}
            end
            self.PlayerRerollUsedOptions[playerIndex][optionIndex] = true
        else
            self.PlayerRerollUsed[playerIndex] = true
        end
    end
    -- 记进 history：3 次模式下这张不会再出现在本页的其它卡上。
    local history = self.PlayerRerollHistory[playerIndex]
    if history == nil then
        history = {}
        self.PlayerRerollHistory[playerIndex] = history
    end
    tinsert(history, self:GetRuneOwnershipId(replacement))
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
function HextechRune:GrantRandomRuneToComputer(playerIndex, rarity, round, slotIndex)
    if slotIndex == nil then
        slotIndex = playerIndex
    end
    self.CurrentGrantSlot[playerIndex] = slotIndex
    local extraPick = self.PendingExtraRunePick[playerIndex] == true
    local rune = nil
    local shownRarity = rarity
    if self:CanAscendRuneRarity(playerIndex, rarity) then
        rune = self:PickOneRune(playerIndex, rarity - 1)
        if rune ~= nil then
            shownRarity = rarity - 1
        end
    end
    if rune == nil then
        rune = self:PickOneRune(playerIndex, rarity)
    end
    if rune == nil then
        self.CurrentGrantSlot[playerIndex] = nil
        return false
    end
    if not self:AddOwnedRune(playerIndex, rune, slotIndex) then
        self.CurrentGrantSlot[playerIndex] = nil
        return false
    end
    if shownRarity ~= rarity then
        self:CommitAscendRuneRarity(playerIndex, shownRarity)
    end
    self.PlayerOptions[playerIndex] = nil
    self:OnRuneChosen(playerIndex, rune)
    -- 记在 OnRuneChosen 之后：这一步才真正结束「第一次选择」，该次选择里质变/赌怪
    -- 现发的奖励符文仍按第一次选择筛池。
    self:MarkFormalSelectionReceived(playerIndex)
    -- 顺手的事：电脑没有选择界面，多拿的一张直接按同阶池再抽一次（同回合、同稀有度）。
    if extraPick then
        self.PendingExtraRunePick[playerIndex] = nil
        self:GrantRandomRuneToComputer(playerIndex, rarity, round, slotIndex)
    end
    self.CurrentGrantSlot[playerIndex] = nil
    return true
end

function HextechRune:EnsurePlayerEventQueue(playerIndex)
    if self.PlayerEventQueues[playerIndex] == nil then
        self.PlayerEventQueues[playerIndex] = {}
    end
    return self.PlayerEventQueues[playerIndex]
end

-- 真正展示时才根据玩家最新持有状态筛池，避免排队期间刚选到的唯一符文
-- 仍残留在后续事件的候选中。slotIndex 是这次选择归属的展示槽位。
function HextechRune:ShowRuneOptionsForPlayer(playerIndex, rarity, slotIndex)
    if slotIndex == nil then
        slotIndex = playerIndex
    end
    self.CurrentGrantSlot[playerIndex] = slotIndex
    self.PlayerOptionSlot[playerIndex] = slotIndex
    self.PlayerOptionRarity[playerIndex] = rarity
    -- 兜底：第 1 回合回调没跑到时，借第一次开选择补判一次（只评估一次、不重复播报）。
    self:InitSoloUnlimitedReroll()
    local options = nil
    local shownRarity = rarity
    if self:CanAscendRuneRarity(playerIndex, rarity) then
        options = self:PickThreeRunes(playerIndex, rarity - 1)
        if options ~= nil then
            shownRarity = rarity - 1
        end
    end
    if options == nil then
        -- 高一阶筛池被阵营/兵种/已持有唯一符文掏空时退回原阶，升阶次数留给下一次：
        -- 这里丢不起事件，队列是先出队再展示的。
        options = self:PickThreeRunes(playerIndex, rarity)
    end
    if options == nil then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("hextech.error.not_enough_candidates"), 10)
        self.CurrentGrantSlot[playerIndex] = nil
        self.PlayerOptionSlot[playerIndex] = nil
        self.PlayerOptionRarity[playerIndex] = nil
        return false
    end
    self.PlayerOptionCount[playerIndex] = getn(options)
    self.PlayerOptionRarity[playerIndex] = shownRarity
    self.PlayerOptions[playerIndex] = options
    self:ResetRerollState(playerIndex, options)
    if shownRarity ~= rarity then
        self:CommitAscendRuneRarity(playerIndex, shownRarity)
    end
    for i = 1, getn(options), 1 do
        local rune = options[i]
        self:CreateOptionBox(playerIndex, i, shownRarity,
            self.RarityFrameImageIds[shownRarity], rune)
        self:CreateRerollButton(playerIndex, i)
    end
    -- 顺手的事：本次选择里多给一次点击机会（只剩一张候选时兑现不了，留着给下一次）。
    if self.PendingExtraRunePick[playerIndex] and getn(options) >= 2 then
        self.PendingExtraRunePick[playerIndex] = nil
        self.PlayerExtraPickRemaining[playerIndex] = 1
        exAddTextToPublicBoard(Localization.get("hextech.easy_does_it.broadcast",
            playerIndex), 10)
    end
    self.PlayerSelectionVisible[playerIndex] = true
    self:HideSelectionHint(playerIndex)
    return true
end

function HextechRune:EnqueueRuneEvent(playerIndex, rarity, round, slotIndex)
    if slotIndex == nil then
        slotIndex = playerIndex
    end
    local queue = self:EnsurePlayerEventQueue(playerIndex)
    tinsert(queue, { Rarity = rarity, Round = round, Slot = slotIndex })
    self:ShowSelectionHint(playerIndex)
    return true
end

function HextechRune:ShowNextQueuedRuneEvent(playerIndex)
    if self.PlayerOptions[playerIndex] ~= nil then
        return false
    end
    local queue = self:EnsurePlayerEventQueue(playerIndex)
    while getn(queue) > 0 do
        local event = tremove(queue, 1)
        if self:ShowRuneOptionsForPlayer(playerIndex, event.Rarity, event.Slot) then
            return true
        end
    end
    -- 队列取空（或候选池不足）后不再留提示，避免玩家反复按 J 却打不开面板。
    self.CurrentGrantSlot[playerIndex] = nil
    self.PlayerOptionSlot[playerIndex] = nil
    self.PlayerOptionRarity[playerIndex] = nil
    self:HideSelectionHint(playerIndex)
    return false
end

-- 真人独立筛池并无放回抽 3 个进行选择；遭遇战电脑直接随机获得同阶符文 1 个。
function HextechRune:ShowRuneEvent(round)
    local rarity = self:RollFieldRarity(round)
    local hasHumanEvent = false
    for slotIndex = 1, 6, 1 do
        -- 按槽位发放：槽位归属者可能是原玩家，也可能是退出继承后的新玩家。
        self:EnsureRuneSlotState(slotIndex)
        local ownerIndex = self.PlayerSlotOwner[slotIndex] or slotIndex
        local playerName = "Player_" .. ownerIndex
        local previous = SetWorldBuilderThisPlayer(1)
        local structures, structureCount = CopyPlayerRegisteredObjectSet(playerName, "STRUCTURES")
        SetWorldBuilderThisPlayer(previous)
        if structureCount > 0 then
            if self:IsHumanPlayer(ownerIndex) then
                self:EnqueueRuneEvent(ownerIndex, rarity, round, slotIndex)
                hasHumanEvent = true
            else
                self:GrantRandomRuneToComputer(ownerIndex, rarity, round, slotIndex)
            end
        end
    end
    -- 到点不再自动弹面板，只挂提示等玩家按 J；因此全图播报一次提醒查收。
    if hasHumanEvent then
        exAddTextToPublicBoard(Localization.get("hextech.selection.ready_broadcast"), 10)
    end
end

function HextechRune:ShowFormalEvent(round)
    self:ShowRuneEvent(round)
end

-- 退出继承：退出者名下的全部符文（含之前继承来的）并进继承者的效果聚合；
-- 各槽位的展示列表保持原样，只把槽位归属名字改成继承者。
function HextechRune:TransferPlayerSlotRunes(fromIndex, toIndex)
    self:EnsurePlayerRuneState(fromIndex)
    self:EnsurePlayerRuneState(toIndex)
    for slotIndex = 1, 6, 1 do
        self:EnsureRuneSlotState(slotIndex)
    end
    local owned = self.PlayerOwnedRunes[fromIndex]
    local protocolSeen = {}
    for i = 1, getn(owned), 1 do
        local rune = owned[i]
        local ownershipId = self:GetRuneOwnershipId(rune)
        local alreadyOwned = self.PlayerOwnedRuneIds[toIndex][ownershipId] == true
        self:TransferOwnedRuneToPlayer(toIndex, rune)
        -- 协议是逐玩家授予的：继承者没有同一协议时，必须重新授予科技/技能；
        -- 基地已由引擎转交，ReregisterInheritedProtocol 内部会跳过重建基地。
        if not alreadyOwned and self:IsInheritedProtocolRune(rune)
            and protocolSeen[rune.Effect] == nil then
            protocolSeen[rune.Effect] = true
            self:ReregisterInheritedProtocol(toIndex, rune)
        end
    end
    -- 先记下退出时正在展示的选择，再清 UI 状态。
    local pendingSlot = self.PlayerOptionSlot[fromIndex]
    local pendingRarity = self.PlayerOptionRarity[fromIndex]
    local fromQueue = self.PlayerEventQueues[fromIndex]
    -- 准备背包 / 顺手的事这类「下一次选择」权益一起转给继承者。
    if self.PendingRuneAscend[fromIndex] then
        self.PendingRuneAscend[toIndex] = true
    end
    if self.PendingExtraRunePick[fromIndex] then
        self.PendingExtraRunePick[toIndex] = true
    end
    -- 玩家聚合清空；槽位展示列表不动。
    self.PlayerOwnedRunes[fromIndex] = {}
    self.PlayerOwnedRuneIds[fromIndex] = {}
    self.PlayerOwnedRuneCounts[fromIndex] = {}
    self.PlayerOptions[fromIndex] = nil
    self.PlayerOptionCount[fromIndex] = nil
    self.PendingRuneAscend[fromIndex] = nil
    self.PendingExtraRunePick[fromIndex] = nil
    self.PlayerExtraPickRemaining[fromIndex] = nil
    self.PlayerSelectionVisible[fromIndex] = false
    self.PlayerRerollUsed[fromIndex] = nil
    self.PlayerRerollUsedOptions[fromIndex] = nil
    self.PlayerRerollHistory[fromIndex] = nil
    self.CurrentGrantSlot[fromIndex] = nil
    self.PlayerOptionSlot[fromIndex] = nil
    self.PlayerOptionRarity[fromIndex] = nil
    self.PlayerEventQueues[fromIndex] = {}
    self.PanelVisible[fromIndex] = nil
    -- 所有仍挂在退出者名下的槽位都改挂继承者（支持 A→B 后再 B→C 的级联）。
    for slotIndex = 1, 6, 1 do
        if self.PlayerSlotOwner[slotIndex] == fromIndex then
            self.PlayerSlotOwner[slotIndex] = toIndex
        end
    end
    -- 未展示/未领取的事件转给继承者，保留原槽位。
    if self:IsHumanPlayer(toIndex) then
        if fromQueue ~= nil and getn(fromQueue) > 0 then
            local toQueue = self:EnsurePlayerEventQueue(toIndex)
            for i = 1, getn(fromQueue), 1 do
                local event = fromQueue[i]
                tinsert(toQueue, { Rarity = event.Rarity, Round = event.Round,
                    Slot = event.Slot or fromIndex })
            end
            self:ShowSelectionHint(toIndex)
        end
        -- 退出时正显示的三选一：补成一个新事件，避免这次选择丢失。
        if pendingRarity ~= nil then
            local toQueue = self:EnsurePlayerEventQueue(toIndex)
            tinsert(toQueue, { Rarity = pendingRarity, Round = self.CurrentRound,
                Slot = pendingSlot or fromIndex })
            self:ShowSelectionHint(toIndex)
        end
    end
    -- 已展开的总览面板立即按新归属重画。
    for viewerIndex = 1, 6, 1 do
        if self.PanelVisible[viewerIndex] then
            self:HidePanel(viewerIndex)
            self:ShowPanel(viewerIndex)
        end
    end
end

-- 无人继承：槽位符文随资产一起消失。
function HextechRune:ClearPlayerSlotRunes(fromIndex)
    self:EnsurePlayerRuneState(fromIndex)
    for slotIndex = 1, 6, 1 do
        self:EnsureRuneSlotState(slotIndex)
    end
    self.PlayerOwnedRunes[fromIndex] = {}
    self.PlayerOwnedRuneIds[fromIndex] = {}
    self.PlayerOwnedRuneCounts[fromIndex] = {}
    for slotIndex = 1, 6, 1 do
        if self.PlayerSlotOwner[slotIndex] == fromIndex then
            self.PlayerSlotOwnedRunes[slotIndex] = {}
            self.PlayerSlotOwnedRuneIds[slotIndex] = {}
            self.PlayerSlotOwner[slotIndex] = nil
            -- 这一格没人接手：面板不再给它留行（否则会留一行空名字 + 0 张卡）
            self.PanelVacantSeat[slotIndex] = true
        end
    end
    self.PlayerOptions[fromIndex] = nil
    self.PlayerOptionCount[fromIndex] = nil
    self.PendingRuneAscend[fromIndex] = nil
    self.PendingExtraRunePick[fromIndex] = nil
    self.PlayerExtraPickRemaining[fromIndex] = nil
    self.PlayerSelectionVisible[fromIndex] = false
    self.PlayerRerollUsed[fromIndex] = nil
    self.PlayerRerollUsedOptions[fromIndex] = nil
    self.PlayerRerollHistory[fromIndex] = nil
    self.CurrentGrantSlot[fromIndex] = nil
    self.PlayerOptionSlot[fromIndex] = nil
    self.PlayerOptionRarity[fromIndex] = nil
    self.PlayerEventQueues[fromIndex] = {}
    self.PanelVisible[fromIndex] = nil
    for viewerIndex = 1, 6, 1 do
        if self.PanelVisible[viewerIndex] then
            self:HidePanel(viewerIndex)
            self:ShowPanel(viewerIndex)
        end
    end
end

-- 移除某玩家当前的候选卡（卡框 / 图标 / 重随按钮 / 标题），不动 PlayerOptions。
-- 关页与「顺手的事」重排都走这里，避免两处各写一份 3 连循环。
function HextechRune:RemoveOptionBoxes(playerIndex)
    local playerName = "Player_" .. playerIndex
    for i = 1, 3, 1 do
        local btnIndex = self:GetOptionBtnIndex(playerIndex, i)
        local iconBtnIndex = self:GetOptionIconBtnIndex(playerIndex, i)
        local rerollBtnIndex = self:GetRerollBtnIndex(playerIndex, i)
        local textIndex = self:GetOptionTextIndex(playerIndex, i)
        exCustomBtnSetVisibilityForPlayer(playerName, btnIndex, 0)
        exCustomBtnRemoveForPlayer(playerName, btnIndex)
        exCustomBtnSetVisibilityForPlayer(playerName, iconBtnIndex, 0)
        exCustomBtnRemoveForPlayer(playerName, iconBtnIndex)
        exCustomBtnSetVisibilityForPlayer(playerName, rerollBtnIndex, 0)
        exCustomBtnRemoveForPlayer(playerName, rerollBtnIndex)
        exCustomTextUpdateVisibilityForPlayer(playerName, textIndex, 0)
    end
end

-- 按 PlayerOptions 的当前张数把候选卡整排重建（张数变少后重新居中）。
function HextechRune:RelayoutOptionBoxes(playerIndex)
    self:RemoveOptionBoxes(playerIndex)
    local options = self.PlayerOptions[playerIndex]
    if options == nil then
        return
    end
    self.PlayerOptionCount[playerIndex] = getn(options)
    for i = 1, getn(options), 1 do
        local rune = options[i]
        self:CreateOptionBox(playerIndex, i, rune.Rarity,
            self.RarityFrameImageIds[rune.Rarity], rune)
        self:CreateRerollButton(playerIndex, i)
    end
end

-- 处理玩家点击方框（记录选择并关闭方框）
function HextechRune:HandleOptionClick(playerIndex, optionIndex)
    local options = self.PlayerOptions[playerIndex]
    if options == nil or options[optionIndex] == nil then
        return
    end
    local rune = options[optionIndex]
    local slotIndex = self.PlayerOptionSlot[playerIndex] or playerIndex
    self.CurrentGrantSlot[playerIndex] = slotIndex
    -- 互斥兜底：候选是选卡那一刻生成的，其间玩家可能已拿到互斥符文（顺手的事的多拿一张
    -- 会在同一批候选里连选），点选时按当时的持有情况再拦一次。
    if self:IsRuneExclusiveBlocked(playerIndex, rune) then
        exAddTextToPublicBoardForPlayer("Player_" .. playerIndex,
            Localization.get("hextech.error.rune_exclusive",
                self:GetRuneDisplayName(rune)), 10)
        return
    end
    if not self:AddOwnedRune(playerIndex, rune, slotIndex) then
        return
    end
    -- 顺手的事：本次还能多拿一张时，取走这一张后把剩下的候选压紧留在屏幕上继续点。
    local extraRemaining = self.PlayerExtraPickRemaining[playerIndex] or 0
    local keepSelection = extraRemaining > 0 and getn(options) > 1
    if keepSelection then
        self.PlayerExtraPickRemaining[playerIndex] = extraRemaining - 1
        tremove(options, optionIndex)
    else
        self.PlayerExtraPickRemaining[playerIndex] = nil
        self.PlayerOptions[playerIndex] = nil
        self.PlayerSelectionVisible[playerIndex] = false
        self:HideSelectionHint(playerIndex)
    end
    self:OnRuneChosen(playerIndex, rune)
    -- 记在 OnRuneChosen 之后：这一步才真正结束「第一次选择」，该次选择里质变/赌怪
    -- 现发的奖励符文仍按第一次选择筛池。
    self:MarkFormalSelectionReceived(playerIndex)
    if not keepSelection then
        -- 选择结束才清槽位上下文；「顺手的事」还要继续用同一个槽位。
        self.CurrentGrantSlot[playerIndex] = nil
        self.PlayerOptionSlot[playerIndex] = nil
        self.PlayerOptionRarity[playerIndex] = nil
    end
    if keepSelection then
        self:RelayoutOptionBoxes(playerIndex)
    else
        self:RemoveOptionBoxes(playerIndex)
    end
    local msg = Localization.get("hextech.picked", self:GetRuneDisplayName(rune))
    exAddTextToPublicBoardForPlayer("Player_" .. playerIndex, msg, 10)
    -- 若总览面板正处于展开状态，立即用真实持有数据刷新。
    if self.PanelVisible[playerIndex] then
        self:HidePanel(playerIndex)
        self:ShowPanel(playerIndex)
    end
    -- 队列里还有到点的事件时继续挂提示，同样等玩家按 J 展开，不自动弹面板。
    -- 候选卡还留在屏幕上时不能挂提示（那句提示说的是「按 J 展开面板」）。
    if not keepSelection and getn(self:EnsurePlayerEventQueue(playerIndex)) > 0 then
        self:ShowSelectionHint(playerIndex)
    end
end

-- ===== 海克斯面板（按钮 5 展开）=====
-- 面板按 GetPanelSeatColumns 的座位表展示六名玩家真实拥有的海克斯符文。

function HextechRune:GetPanelRuneBtnIndex(playerIndex, slot)
    return self.PanelBtnIndexBase + (playerIndex - 1) * self.PanelIndexSlotCount + slot
end

function HextechRune:GetPanelRuneIconBtnIndex(playerIndex, slot)
    return self.PanelIconBtnIndexBase + (playerIndex - 1) * self.PanelIndexSlotCount + slot
end

function HextechRune:GetPanelRuneTextIndex(playerIndex, slot)
    return self.PanelRuneTextIndexBase + (playerIndex - 1) * self.PanelIndexSlotCount + slot
end

-- 计算某玩家面板名字文字 index
function HextechRune:GetPanelNameTextIndex(playerIndex)
    return self.PanelTextIndexBase + playerIndex
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

-- 某座位当前是否有人坐。口径与 BtnChoiceDialogEventFunc_GetSideOccupiedPlayerIndices 一致：
-- 真人看 PLAYER_IS_HUMAN_OR_AI_PERSONALITY，占位/电脑看 P[i]（P 是 UNITCOUNTERINI_0 里
-- GetObjectByScriptName("P"..i) 拿到的本图玩家对象，空位为 nil）。
-- 本图空位不占编号：满 6 位是 1~6，2v2 用 1、2 / 4、5，1v1 用 1 / 4，所以 2v2 时
-- 座位 3、6 会返回 false —— 面板直接跳过它们，行序不留白。
-- PanelVacantSeat：原玩家退出且无人继承（符文已清空）的格子，也不再占位。
function HextechRune:IsPanelSeatOccupied(seatIndex)
    if self.PanelVacantSeat[seatIndex] == true then
        return false
    end
    if P ~= nil and P[seatIndex] ~= nil then
        return true
    end
    return self:IsHumanPlayer(seatIndex)
end

-- 座位表：两列按阵营分（左列 1/2/3 恶魔、右列 4/5/6 天使），列内**自上而下就按座位号**，
-- 不再按出生点坐标排序 —— 2026-10-27 实测：2v2 时坐标排序会把玩家排到第 1、3 行，
-- 中间留一行空白（地图上恶魔在下、天使在上）。现在按用户要求「都从上往下顺序排列、
-- 不要中间留白、不用管玩家位置」：空座位直接跳过，剩下的人自上而下依次占第 1/2/3 行。
-- 每次开面板现算（座位占用会随退出/继承变化，不再缓存）。
function HextechRune:GetPanelSeatColumns()
    local columns = {}
    for column = 1, getn(self.PanelSeatColumnGroups), 1 do
        local seats = {}
        local group = self.PanelSeatColumnGroups[column]
        for row = 1, getn(group), 1 do
            local seatIndex = group[row]
            if self:IsPanelSeatOccupied(seatIndex) then
                tinsert(seats, seatIndex)
            end
        end
        columns[column] = seats
    end
    return columns
end

-- 显示面板（对单个玩家），内容为六名玩家真实拥有的符文。
function HextechRune:ShowPanel(playerIndex)
    local playerName = "Player_" .. playerIndex
    self:EnsurePlayerRuneState(playerIndex)
    -- 底板（最底层）：上边角内凹的深色板 + 三层金边 + 标题带，颜色与
    -- 「海克斯面板」金渐变标题都已烘在贴图里，不再染色、也不再画引擎标题文字。
    exCreateCustomImageForPlayer(playerName, {
        Index = self.PanelBgIndex,
        TextureName = g_HextechPanelBgId,
        X = self.PanelBgX,
        Y = self.PanelBgY,
        SizeX = self.PanelBgWidth,
        SizeY = self.PanelBgHeight,
        GroupIndex = self.PanelBgIndex,
        AlignX = "left",
        AlignY = "top",
    })
    -- 关闭按钮（标题带右端，使用 hextechRemoveButton 图标，不显示悬浮详情框）
    local closeBtnIndex = self:GetPanelCloseBtnIndex(playerIndex)
    exCreateCustomButtonForPlayer(playerName, {
        Index = closeBtnIndex,
        TextureName = g_HextechRemoveBtnId,
        Desc = "",
        X = self.PanelBgX + self.PanelCloseOffsetX,
        Y = self.PanelBgY + self.PanelCloseOffsetY,
        SizeX = self.PanelCloseSizeX,
        SizeY = self.PanelCloseSizeY,
        GroupIndex = closeBtnIndex,
        AlignX = "left",
        AlignY = "top",
    })
    -- 底板后建，显式把关闭按钮压到底板之上。
    exCustomBtnGroupSortDepthAboveAnotherGroup(closeBtnIndex, self.PanelBgIndex)
    -- 两列托盘 × 至多三行：左列恶魔、右列天使；空座位已在 GetPanelSeatColumns 里跳过，
    -- 剩下的人自上而下依次占第 1/2/3 行，中间不留白。
    local columns = self:GetPanelSeatColumns()
    for column = 1, getn(columns), 1 do
        local trayX = self.PanelColumnX[column]
        local seats = columns[column]
        for row = 1, getn(seats), 1 do
            if row > getn(self.PanelRowY) then
                break
            end
            local targetIndex = seats[row]
            self:CreatePanelNameText(playerIndex, targetIndex,
                trayX + self.PanelNameOffsetX, self.PanelRowY[row])
            self:CreatePanelRuneRow(playerIndex, targetIndex,
                trayX + self.PanelCardOffsetX, self.PanelRowY[row])
        end
    end
    self.PanelVisible[playerIndex] = true
end

-- 创建单个玩家名文字（垂直居中于所在行、左对齐于名字列起点；Content 用 $pNName，
-- 继承（退出继承）后这一格的归属者不是座位本人，名字换成继承者并用金色标出来。
function HextechRune:CreatePanelNameText(viewerIndex, targetIndex, x, y)
    local viewerName = "Player_" .. viewerIndex
    local nameTextIndex = self:GetPanelNameTextIndex(targetIndex)
    self:EnsureRuneSlotState(targetIndex)
    local ownerIndex = self.PlayerSlotOwner[targetIndex] or targetIndex
    local nameColor = self.PanelNameColor
    if ownerIndex ~= targetIndex then
        nameColor = self.PanelInheritedNameColor
    end
    local nameText = "$p" .. ownerIndex .. "Name"
    exCreateCustomTextForPlayer(viewerName, {
        Index = nameTextIndex,
        Content = nameText,
        -- 引擎画 $pNName 时视觉中心偏左偏下，各补半个字宽 / 半个字高才落在名字列与行心正中
        X = x + self.PanelNameNudgeX,
        Y = y + self.PanelNameNudgeY,
        Color = nameColor,
        Size = self.PanelNameFontSize,
        AlignX = "left",
        AlignY = "center",
    })
end

-- 创建某玩家的一行真实符文（最多显示 PanelMaxRuneCount = 5 个，水平一排）。
-- areaX 是卡区左缘：小卡接在名字后面依次右排（不再整体居中）；
-- 间距首选 PanelRuneGap，张数多到放不下时按卡区可用宽度动态收缩，
-- 收缩后相邻卡之间的间距依然两两相等（5 张是设计上限，收缩只在缓冲格真的被占用时才生效）。
function HextechRune:CreatePanelRuneRow(viewerIndex, targetIndex, areaX, y)
    local viewerName = "Player_" .. viewerIndex
    self:EnsureRuneSlotState(targetIndex)
    local owned = self.PlayerSlotOwnedRunes[targetIndex]
    local ownerIndex = self.PlayerSlotOwner[targetIndex] or targetIndex
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
    -- 小卡接在名字后面从左往右依次排，不再整体居中。
    -- 间距首选 PanelRuneGap；张数多到按首选间距放不下时，按卡区可用宽度均分收缩，
    local gap = self.PanelRuneGap
    if count > 1 then
        local fitGap = (self.PanelCardAreaWidth - self.PanelRuneWidth * count) / (count - 1)
        if fitGap < gap then
            gap = fitGap
        end
    end
    local startX = areaX
    for slot = 1, count, 1 do
        local rune = displayRunes[slot]
        local rarity = rune.Rarity
        local btnIndex = self:GetPanelRuneBtnIndex(targetIndex, slot)
        local iconBtnIndex = self:GetPanelRuneIconBtnIndex(targetIndex, slot)
        local runeTextIndex = self:GetPanelRuneTextIndex(targetIndex, slot)
        local runeTitle = self:GetRuneCompactTitle(rune)
        local runeTitleSize = self:GetRuneTitleFontSize(rune, self.PanelRuneHeight)
        local x = startX + (slot - 1) * (self.PanelRuneWidth + gap)
        local topY = y - self.PanelRuneHeight / 2
        local runeDesc = format("%s\n%s", self:GetRuneDisplayName(rune),
            self:GetRuneDescription(rune, ownerIndex))
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
        -- 底板后建：先卡框压到底板之上，再让图标压在卡框上（顺带也高于底板），
        -- 顺序不能反，否则最后一步会把图标重新挪到底板正上方、反而被卡框盖住。
        exCustomBtnGroupSortDepthAboveAnotherGroup(btnIndex, self.PanelBgIndex)
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
    -- 按 PanelIndexSlotCount（6，含缓冲那一格）全量清一遍，保证预留 index 不残留
    for targetIndex = 1, 6, 1 do
        for slot = 1, self.PanelIndexSlotCount, 1 do
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
    -- 标题已烘进底板贴图，没有引擎文字需要隐藏
    -- 移除关闭按钮（先隐藏再移除）
    local closeBtnIndex = self:GetPanelCloseBtnIndex(playerIndex)
    exCustomBtnSetVisibilityForPlayer(playerName, closeBtnIndex, 0)
    exCustomBtnRemoveForPlayer(playerName, closeBtnIndex)
    -- 移除底板（先隐藏再移除）
    exCustomBtnSetVisibilityForPlayer(playerName, self.PanelBgIndex, 0)
    exCustomBtnRemoveForPlayer(playerName, self.PanelBgIndex)
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
    self.CurrentRound = round
    self:OnFiveThunderRoundBegin(round)
    -- 单人遭遇战：开局评估一次并播报（消息区小字），此后重随不限次数；多人局不播也不放开。
    self:InitSoloUnlimitedReroll()
    -- 正式海克斯事件：按配置次数截取的回合触发（全场统一稀有度）
    if g_EnableHextechRune == 1 and not self.FormalTriggered[round] and self:IsFormalRound(round) then
        self.FormalTriggered[round] = true
        self:ShowFormalEvent(round)
    end
end

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
