-- 海克斯符文系统：回合事件（开局测试事件 + 正式海克斯事件）+ 海克斯面板
--   - 回合监听：RoundLuaManager.CallOnEveryRoundBegin（复用抽卡模式 PureDraw 方案）
--   - 开局测试事件（第 1 回合，测试环境专用，不受配置数量影响）：
--     - 屏幕正中间 3 个方框，展示测试指定的符文和三种稀有度选项
--     - 3 个选项稀有度不同（彩/金/银 各一），按默认概率加权抽取
--   - 正式海克斯事件（第 5/11/18 回合，按 g_HextechCount 截取）：
--     - 先全场抽一个统一稀有度（彩/金/银，按回合概率）
--     - 再对每个玩家独立刷新 3 个方框（每个玩家选项不同，稀有度相同，内容留空）
--     - 内容（具体符文）在符文池接入后填充
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
-- 面板符文小卡框尺寸（占位展示）
-- 注：4 个符文总宽 = 4*50 + 3*10 = 230 < 列间距 240，保证相邻玩家的符文不重叠
HextechRune.PanelRuneSize = 50
HextechRune.PanelRuneGap = 10
-- 单个玩家最多可拥有的符文数（占位测试 0~4）
HextechRune.PanelMaxRuneCount = 4
-- 测试用占位符文数量（每个玩家 0~4 个，用于检测不同数量的布局兼容性；
-- 符文池接入后改为读取玩家真实已拥有符文）
HextechRune.PanelTestRuneCount = {
    [1] = 3,  -- 恶魔1号（下行）：3 个
    [2] = 3,  -- 恶魔2号（下行）：3 个
    [3] = 3,  -- 恶魔3号（下行）：3 个
    [4] = 4,  -- 天使1号（上行）：4 个
    [5] = 4,  -- 天使2号（上行）：4 个
    [6] = 4,  -- 天使3号（上行）：4 个
}
-- 面板自定义元素 index 基础（避开已用 index）
HextechRune.PanelBtnIndexBase = 400      -- 符文占位按钮：玩家 i 的第 j 个 = 400 + (i-1)*4 + j（每玩家 4 槽，400~423）
HextechRune.PanelCloseBtnBase = 500      -- 关闭按钮：玩家 i = 500 + i
HextechRune.PanelTextIndexBase = 600     -- 名字文字：玩家 i = 600 + i
HextechRune.PanelTitleTextBase = 610     -- 标题文字：玩家 i = 610 + i

-- 每玩家面板是否展开
HextechRune.PanelVisible = {}

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
    -- 移除该玩家的 3 个方框按钮和文字。
    -- 注意：先隐藏按钮（exCustomBtnSetVisibilityForPlayer 0）再移除，
    -- 否则引擎的原生悬浮详情窗（Desc 文本）会在按钮移除后残留。
    for i = 1, 3, 1 do
        local btnIndex = self:GetOptionBtnIndex(playerIndex, i)
        local textIndex = self:GetOptionTextIndex(playerIndex, i)
        exCustomBtnSetVisibilityForPlayer("Player_" .. playerIndex, btnIndex, 0)
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

-- ===== 海克斯面板（按钮 5 展开）=====
-- 面板显示上三玩家（天使 4/5/6）与下三玩家（恶魔 1/2/3）的海克斯符文。
-- 测试阶段：每个玩家用 3 个占位符文（彩/金/银卡框各一）占满 3 个位置。

-- 计算某玩家面板符文按钮 index（slot 1..PanelMaxRuneCount）
-- 注意：每玩家必须预留 PanelMaxRuneCount（4）个 index，否则 4 个符文时
--       玩家 i 的第 4 个符文会与玩家 i+1 的第 1 个符文共用 index（被覆盖）。
function HextechRune:GetPanelRuneBtnIndex(playerIndex, slot)
    return self.PanelBtnIndexBase + (playerIndex - 1) * self.PanelMaxRuneCount + slot
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

-- 显示面板（对单个玩家）。占位符文：3 个 = 彩/金/银卡框各一。
function HextechRune:ShowPanel(playerIndex)
    local playerName = "Player_" .. playerIndex
    -- 标题（固定居中于屏幕中央，不随面板整体左移）
    local titleTextIndex = self:GetPanelTitleTextIndex(playerIndex)
    exCreateCustomTextForPlayer(playerName, {
        Index = titleTextIndex,
        Content = Localization.get("hextech.panel.title"),
        X = self.PanelTitleCenterX,
        Y = 180,
        Color = 16777215,
        Size = 24,
        AlignX = "center",
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
    exCreateCustomTextForPlayer(viewerName, {
        Index = nameTextIndex,
        Content = "$p" .. targetIndex .. "Name",
        X = x,
        Y = y,
        Color = 16777215,
        Size = 16,
        AlignX = "center",
        AlignY = "center",
    })
end

-- 创建某玩家的一行符文（按 PanelTestRuneCount 动态创建 0~4 个占位，水平一排，居中于列）
function HextechRune:CreatePanelRuneRow(viewerIndex, targetIndex, colX, y)
    local viewerName = "Player_" .. viewerIndex
    local count = self.PanelTestRuneCount[targetIndex] or 0
    if count < 0 then
        count = 0
    elseif count > self.PanelMaxRuneCount then
        count = self.PanelMaxRuneCount
    end
    if count == 0 then
        return
    end
    -- 占位符文水平一排，整体居中于列中心 colX
    local totalWidth = self.PanelRuneSize * count + self.PanelRuneGap * (count - 1)
    local startX = colX - totalWidth / 2
    for slot = 1, count, 1 do
        -- 占位稀有度：slot1=彩(1) slot2=金(2) slot3=银(3) slot4=彩(1)（循环）
        local rarity = mod(slot - 1, 3) + 1
        local btnIndex = self:GetPanelRuneBtnIndex(targetIndex, slot)
        local x = startX + (slot - 1) * (self.PanelRuneSize + self.PanelRuneGap)
        -- 悬浮详情窗：聚焦时展示符文描述（占位阶段用测试符文文案，符文池接入后替换为真实描述）
        local runeDesc = Localization.get("hextech.test.option", slot, Localization.get("hextech.rarity." .. self.RarityNames[rarity]))
        exCreateCustomButtonForPlayer(viewerName, {
            Index = btnIndex,
            TextureName = self.RarityFrameImageIds[rarity],
            Desc = runeDesc,
            X = x,
            Y = y - self.PanelRuneSize / 2,
            SizeX = self.PanelRuneSize,
            SizeY = self.PanelRuneSize,
            GroupIndex = btnIndex,
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
            exCustomBtnSetVisibilityForPlayer(playerName, btnIndex, 0)
            exCustomBtnRemoveForPlayer(playerName, btnIndex)
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
