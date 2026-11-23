-- 规则页文案不再走 Localization.get("game.rules")（那条要过一次 format，长文本容易出岔子）：
-- 中文从本地化表里取，英文用下面的字面量，最终由 g_GetRuleText() 统一给出。
g_RuleText = ""

-- 规则页中英各存一份：切语言时只换引用，避免某一语言取不到文本
function g_PickRuleText(lang)
    local src = Localization._text_sources["game.rules"]
    if src == nil and g_LocalizationExtraText ~= nil then
        src = g_LocalizationExtraText["game.rules"]
    end
    if src == nil then
        return ""
    end
    local t = src[lang] or src.zh or src.en
    if type(t) ~= "string" then
        return ""
    end
    return t
end

g_RuleTextZh = g_PickRuleText("zh")
-- 英文规则页直接用字面量：和更新日志各页走完全相同的路径（那些页实测能正常显示），
-- 不再依赖 Localization 表里那条 en（那条保留，给别处用）。
g_RuleTextEn = "DSA Game Rules：\nThis map is developed with assistance from Latticeshop. It contains many experimental features and may be unstable. Features that pass testing will be updated and merged into the official DSA map.\n1. Units you build are recorded. At the start of each round, all units you have built are respawned on the battlefield under AI control.\n2. Upper-side players (Angel) units appear on the right side of the battlefield. Lower-side players (Devil) units appear on the left side.\n3. Power plants provide income. Build power plants ASAP to avoid running out of money. Soviet Super Reactors and Celestial Diversion Spire do not provide income (tech unlock only). Building T4 high-tech grants a free Veteran Academy.\nStandard Mode：Limited income in early stages. Destroy enemy defense towers to unlock more power plants and technology.\nDeath Mode：Both sides start with only their final tower remaining, with no tech-access restrictions.\nLevel-Up Mode：Players spend money to unlock more power plants and higher tech tiers. Tech unlock costs decrease over time, and players of the same faction share their unlocks.\nShrink Mode：Units on the battlefield receive the Shrink buff!\nLucky Crate Feature：Use the Lucky Crate skill to gain extra units. Do not use it in the central battlefield!\nPure Draw Mode：Lucky Crates are available from the start. Only 5 units may be produced during each 3-round cycle. Half of all draws are replaced with weighted buildable units from all factions, and random airdrops appear in the center of the battlefield!\nHextech Runes：Granted on rounds 3/10/18/27, each time with one rarity for the whole field (Prismatic/Gold/Silver), bringing random twists to battle! Press J to hide or restore the selection screen. Use the Hextech Panel in the top button bar to view the runes of every player.\nArmor formula：damage reduction ratio is armor divided by armor plus 100.\nClick the Update Log button below to view update details."
if type(g_RuleTextZh) ~= "string" or g_RuleTextZh == "" then
    g_RuleTextZh = ""
end

function g_SafeText(v)
    if type(v) ~= "string" then
        return ""
    end
    return v
end

function g_GetRuleText()
    if Localization.lang == "en" then
        return g_SafeText(g_RuleTextEn)
    end
    return g_SafeText(g_RuleTextZh)
end

g_RuleText = g_GetRuleText()

g_UpdateBoxText = {
    g_RuleTextZh,
    '363版本更新日志\n1，新增海克斯符文系统：第 3、10、18 回合（房主可再开第 27 回合）全场统一抽定稀有度，之后每名玩家独立三选一，选到的符文整局生效，每回合出兵时按兵种施加。发放次数房主可选 0～4 次，重随可选 1 次 / 3 次（3 次模式每张卡各限一次），单人游玩自动开启无限重随。海克斯事件到点在屏幕提示“当前有未选择的海克斯，按\'J\'键展开面板”，按 J 可收起/重新展开；顶部第 5 个按钮改为“海克斯面板”，可查看双方每名玩家的符文，被队友继承的座位名字显示为金色；有人拿到符文时全图播报一次“获得一个海克斯符文，请查收~”。\n2，新增技能组：九头蛇万岁 + 冰天雪地。九头蛇万岁：派出间谍渗透敌后，随机一半敌方场上单位被心控为己方（1 次，冷却 70 秒）；冰天雪地：立即冻结敌方场上全部单位（不含防御塔与建筑，2 次，冷却 70 秒）。同一技能组的两个技能共享 10 秒公共冷却，防止连点。\n3，新增抽卡模式和抽卡功能。抽卡模式：开局即开放抽卡，每 3 回合补满 5 个生产余额（屏幕实时显示剩余余额），余额用完时新生产的单位会被自动取消；抽卡结果有一半概率替换为全阵营加权的可生产单位；场地中央会随机出现十连空投（每次阵型随机）。抽卡模式不再改写海克斯设置，抽卡也不会再抽出工程师。抽卡功能即原先抽卡模式：常规出兵模式在一塔摧毁后开启抽卡。\n4，新增禁用模式（开局“更多选项”菜单里）：可以直接禁步兵、禁载具、禁空军、禁海，最多同时禁 3 项。被禁的兵种会同时从出兵、抽卡卡池、十连保底、变形/升级重组器、赠送型与替换型符文里剔除；双形态单位只有在它登记的所有兵种都被禁时才会从战场消失。\n5，开局选项重整：游戏模式 / 抽卡模式选择 / 海克斯符文设置 / 更多选项 / 技能组，抽卡与海克斯是两个独立选项，互不改写对方的状态。\n6，新增载具装填：双方电脑的卡池载具出生后会把阵营已有的步兵装上车，不限制装车数量；特洛伊要塞出生时自带的标枪兵先被清空再重新装填；装车后禁用下车按钮。\n7，新增单位寿命规则：（默认）战场中的单位存活 4 回合后自动清除（即场上最多累计 4 个回合的出兵量）。摇光在解锁 T4 前只保留当回合部署的批次，解锁后恢复默认寿命；守护神单位与“龙行天下”召唤的龙船不受影响。\n8，新增继承功能——队友退出后的继承扩展：小电份额（电厂上限）、单位上限、东风速递额度、已有符文，以及在排队未选/正在选/准备背包/顺手的事，全部转给同侧继承者；继承者在一次符文事件里会按继承到的座位数各拿一次选择。\n9，跨阵营协议会在图外生成一座对应阵营的钥匙基地用于释放（不出兵、不提供建造页），重进游戏后自动重解锁技能。\n10，AI 海军改为优先索敌敌方海军，并修复斜向航线的海军走不全的问题；剃刀每 20 秒自动开一次 F（附近有非空中敌人时）；打击者 VX 改走飞机出生点。\n11，联盟重型坦克不再额外获得 1.25 倍生命；太刀的自动 F 与“只打水面”限制停用；海上霸主的奥林匹斯与千鸟存活 2 回合；龙行天下的龙船随回合成长血量；胡杨防空系统增加射程；市场五座防御塔降价，氪金防御塔同样能吃纳米维修。\n12，海克斯稀有度概率：第 1 次 彩 10％/金 40％/银 50％，第 2、3 次 彩 15％/金 42％/银 43％，第 4 次 彩 30％/金 50％/银 20％。遭遇战里的电脑也会按同阶随机拿符文。\n13，海克斯符文池共 72 张（白银 24 / 黄金 25 / 棱彩 23）：\n白银：大力（兵种伤害 +50％）、迅捷（兵种攻速 +50％）、神行（兵种移速 +40％）、通用瞄准镜（兵种射程 +15％）、星界躯体（兵种血量 +75％、伤害 -25％）、狩猎律动（敌方对应兵种每死亡一个，随机一个己方该兵种单位回 10％ 血）、投资（立即把当前金钱翻倍）、MCV（获得一个非自身阵营的 MCV）、破烂王（回收倍率 +20％）、质变（获得高一阶的随机符文）、准备背包（下次符文选择整体升一阶）、顺手的事（下次符文选择可多拿一张）、百虎上将（回合开始为己方步兵加一层百夫长）、超级要塞（获得 1 个超级要塞核心）、先进火炮（盟军先锋→AC130）、万岁冲锋（帝国武士→狂热武士）、出口内销（帝国太刀重巡→一式磁轨炮重巡）、高平两用（苏联牛蛙→“偏流”两栖高射炮）、龙息凌波（神州凌波→凌波龙息炮重装）、花来！（苏联 V4→郁金香自行迫击炮）、轮式大炮（苏联犀牛→ZSU-85 自行防空炮）、秒速五厘米（帝国樱花回天雷→鬼樱特攻机）、鸡汤来咯（毒质腐蚀协议）、神威（时空裂缝协议）。\n黄金：登神、AT 立场、灯火辉煌、买二送一、穿云定海、炽燃利息、吸星大法、固若金汤、自由贸易、艾卡西亚的惊喜、享辐、万象天引、五雷天罚（每 3 回合一次，仅神州）、中门对狙（获得一个天门神弓）、安全感（获得 2 个埃奎斯护盾发生器）、石油王（获得两个油井）、湮灭炸弹（获得 1 次部署次数，按 K 键就地投放）、挖角、启动资金（立即获得 10000）、万用瞄准镜（兵种射程 +25％）、元神互锁（两个兵种的符文数值 BUFF 同步生效）、超凡邪恶（兵种血量与伤害按回合数每回合 +3％）、诸神黄昏（回合开始兵种血量降为 50％、伤害 +90％）、变形重组器、质变。\n棱彩：钓鱼佬（回合开始按本方持有份数把敌方 25％/50％/75％/100％ 的海军变成海翼）、烧福瑞（敌方步兵 25％/50％/75％/100％ 变成警犬/战熊）、生异形（敌方载具 25％/50％/75％/100％ 变成恐怖机器人）、樱落（敌方空军 25％/50％/75％/100％ 变成樱花回天雷；四张同口径，1/2/3/4 份对应 25％/50％/75％/100％，3v3 最多 3 份）、全频段阻塞干扰（敌方全体射程 -25％）、神圣干预（己方全体单位与建筑每 30 秒获得 3/4.5/6 秒铁幕）、The World（敌方全体单位与建筑每 29 秒被时停 3/4.5/6 秒）、东风速递（获得 1 辆东风洲际导弹发射车）、十连（获得 10 个随机单位，其中 1 个必定为 T4 及以上）、塔防专家（购买防御塔无视数量限制且价格打五折）、终极刷新（第一、第二技能使用次数各 +1）、致命节奏（+40％ 攻速且攻击越打越快）、无限火力（飞机无限弹药）、万能瞄准镜（兵种射程 +50％）、海上霸主（获得奥林匹斯级航母与千鸟特攻母舰各 1）、天堂制造（每 7 回合让敌方全体缩小一回合）、歌莉娅巨人（兵种血量 +90％、伤害 +25％）、以战养战（敌方每死一个单位，按 T1/T2/T3/T4 分别给下回合的兵种 +1％ 血量/伤害/攻速/射程）、等价交换（一个兵种大幅增强、另一个兵种大幅削弱）、回归基本功（T1/T2 兵种大幅增强、T3/T4 兵种大幅削弱）、究极生物（回收当前 T1/T2 单位，凑出一个进化的究极生物）、赌怪（获得两个随机符文）、升级重组器（把当前单位池整体升阶重组）。\n14，带兵种的符文会展开成步兵 / 载具 / 飞机 / 海军四个独立版本（无限火力只开飞机），同一次三选一里可以出现不同兵种版本，同一玩家也可以分别持有；对应兵种被禁用时该版本不再入池。赌怪与顺手的事互斥；转化类符文与指定单位类符文互斥；变形/升级重组器、回归基本功、秒速五厘米不会在该玩家本场第一次正式选择中出现；准备背包、顺手的事不会在最后一次出现。\n15，经济相关：以战养战、炽燃利息、启动资金等经济类符文数值跟随经济倍率缩放；开局播报会同时显示当前经济倍率与回收倍率。\n16，BUG修复：修复了海3塔会被冷冻协议冻住的问题。去掉地图默认的升星逻辑：加入 ATTACK 队列的单位不再被强制升级，单位升级改由指定名单控制。修复了快速连点顶部按钮报错的问题；修复了技能冷却与使用次数互串的老 bug（终极刷新/连续使用）。修复了随机非对称技能组开不了局、技能组按实际人数分配错位的问题。修复了海上神州哨站出生越界、超时空突袭索敌、天门神弓索防御塔、埃奎斯护盾生成逻辑等一批已知 bug。',
    '362版本更新日志\n1，以下单位(光棱坦克，祝融雷铳战车，青峰，重锤，守护者，鬼王X)射程AI调整：优先射击射程内最远的敌人，避免碾压意图。VX优先最近目标避免追击飞机。\n2，炮车(白虎 V4 波能 雅典娜 超级要塞大头形态)专用AI：场上有坦克时优先索敌坦克，其次是步兵，最后是建筑。射程里遇到建筑时停止移动。\n3，取消对空飞机原本固定路线AI(阿波罗、阿瑞斯、凤凰、崇明、天狗、心神、米格、苏霍伊)，改为自由活动(心神有意想不到的战术效果?)\n4，每回合清除场上犀牛F技能的地雷(由于大量地雷累计存在会导致游戏运行卡死)。\n5，禁用冷冻军团和光荣的F技能。\n6，限制摇光数量：每个玩家最多建造3辆，场上存活可累计。\n7，帝国可以建造百合子，攻击优先级：坦克＞飞机＞步兵，但百合子不会攻击任何建筑(百合子百分比秒塔)。\n8，娜塔莎优先级：步兵＞坦克＞建筑。谭雅只会爆破一次塔。英雄单位(百合子，娜塔莎，谭雅)不再限量。\n9，帝国单位出场为飞机形态。\n10，超级要塞登场形态各占50％概率。\n11，启用守护者坦克，平定者，白虎，海啸坦克的F技能。\n12，禁用海军时，海翼和磁爆快艇(第三回合解锁)会从陆地生成。\n13，帝国狂热武士不再强制使用技能。\n14，苏联第一回合可以造摩托，准备阶段可以造机场。\n15，更多单位支持回收。\n16，陆地一塔血量增加至450(刚好达摩一剑)。\n17，修复了随机技能可能全部复制的情况，现在至少一个其他技能。\n18，重做超时空突袭技能，改为随机目标不会聚团。\n19，新增防御塔：樱花井10000，埃奎斯护盾发生器15000。\n20，允许玩家造工程师来弥补工程师卡死无法抽奖的情况。\n21，苏霍伊2倍血量，樱花雷3倍血量，基洛夫1.5倍速度，先锋2倍血量，联盟1.25倍血量，麒麟1.25倍血量，崇明射程-25％，磁爆快艇攻速+25％，冷冻军团攻速-25％，谭雅增加25％射程，岚影刺增加祝融攻速，百合子2.5倍射程，海啸坦克使用大型单位护甲，雅典娜还原原版输出，冷冻军团还原原版射程。\n22，再次修复队友退出后继承电厂数量上限的问题。\n23，修复了大量的已知bug。',
    '359,360,361版本更新\n1.允许回收箱子单位，但回收价格较低\n2.帝国狂热武士bug转正为特性：每造2帝国武士送1狂热武士；调整武士回收价格\n3.箱子里抽出的航母/战列舰不再会每回合无限增加\n4.继续调整海塔位置\n5.正常模式下第23回合也清除双方场上单位\n6.ACV可以被回收\n7.纳米维修技能为海塔回复15％血量\n360版本修复抽卡获得神州MCV电厂上限不正确的bug\n361版本修复了夜莺无法被攻击的bug',
    '356,357,358版本更新\n1.支持抽卡模式（1塔爆炸后解锁）\n2.帝国在1塔爆炸后获得免费重工；太刀自动开技能\n3.支持盟军冰冻升级和苏联过载线圈升级\n4.海2塔往后方移动100距离\n5.移除杨叔的部分buff\n6.修复阿瑞斯无法回收的bug；修复凌波出现两遍的bug\n358版本已经修复357版本中抽卡不花钱的bug',
    '353,354,355版本更新\n1.回收单位现在只返还0.9倍造价，苏联点了大生产后只返回0.72倍造价\n2.删除各个阵营t4大船的回收按钮\n正常模式下，第9回合的开始阶段将会清除双方场上的单位\n苏联摩托第三回合开始才能造\n海2塔攻击和射程加强',
    '350,351,352版本重要更新\n加入回收单位机制：可通过按钮回收自己已经出过的单位，回收后将返还一定资金（一般等于造价），并且减少改单位计数（影响每回合出兵数量）\n回收时，若请求回收的数量大于该单位当前计数，将只回收该单位当前计数的数量\n修复部分回收单位的bug',
    '347版本更新\n1.修复盟军能用拓展车无视科技限制升级T3的bug\n2.取消对于波能的削弱；若是阵营拓展模式，则雅典娜的5％射程buff不再生效\n3.帝国允许使用套子协议\n4.谭雅限造两个',
    '346版本更新\n1.支持更多日冕新单位\n2.修复复制时停会变成炸弹的bug',
    '344版本更新\n1.重新取消盟军维和步兵的开盾技能\n2.苏联苏霍伊血量buff从3倍降低到1.5倍',
    '343版本更新\n提高升本模式的科技解锁所需的金钱, 升本模式下，陆地一二塔被摧毁后不会杀死附近的敌军，陆地3、4塔血量减少，陆地2塔被摧毁后不会有老联盟坦克出现\n升科技等级所需金钱提高，但所需金钱会随着回合进行有所降低(但有下限)',
    '341及342版本更新\n1.新增升本模式：在这个模式下，科技和可建造电厂数量不会自然解锁，也不会因为推掉塔而解锁\n双方需要出钱购买科技等级,然后才能获得更高级单位的建造权限和更多电厂的建造权限（只需要一个人购买即可让己方所有人获得建造权限）\n2.双方4塔恢复为巨炮，修复达摩克利斯之剑伤害异常问题，推掉海3塔赏金下降至每人2000\n3.科技自然解锁回合延后一回合，即第6、12、19回合解锁下一回合的科技\n4.海3塔伤害和射程大幅提升',
    '340版本更新\n1.禁止四阵营大塔，禁止帝国湮灭炸弹、盟军超时空集结\n2.盟军城管恢复使用技能\n3.双方4塔替换为苏联礁石岸防导弹要塞',
    '336版本更：\n取消银行贷款，增加购买防御建筑的选项：购买护盾塔和胡杨塔（每一边每种塔最多同时只能存在一个，被摧毁后才能再次购买）\n护盾塔价格10000，5500血,1.25倍射速和1.25倍攻击范围\n胡杨塔价格12000，9000血，1.5倍攻击范围，2倍伤害，1.5倍射速\n2.删除杀敌奖励技能，替换为复制敌方技能，只能使用一次',
    '334版本更：\n1.纳米维修技能修改：改为生成一个纳米维修立场和4个大型维修天灯\n.2.新增一个技能组：杀敌奖励+复制技能：\n杀敌奖励：为所有敌方陆地单位和船（不包括空军）套上钱套子(持续30秒)，击杀后使用技能者获得金钱(冷却70秒)\n复制技能：复制己方最近一次使用的技能（如果最近一次是复制技能，则一直回溯到最近一次非复制的技能），如果没有找到合适的技能，则不释放(冷却30s)\n3.龙船初始血量提升到8000,并且出生位置总在最前面, 达摩技能削到11秒',
    '331版本更：\n1.重构初始选项，房主可选择技能组模式：玩家自选 或 房主规定 或 随机(系统自动给玩家一组技能)\n2.天火塔赠送的单位改为破甲铁卫\n盟军acv区分海面和陆地，船厂出的去海里，重工出的去陆地',
    '329版本更新(第一页)：\n新增技能组：纳米维修、补充军队\n纳米维修：在前线防御塔附近生成纳米维修立场，治愈己方部队和防御塔(可使用2次)\n补充军队：立即额外触发一次陆地和空军生成(可使用2次)\n2.达摩持续时间从16秒减少到14秒\n尝试修复时停导致刷出来的联盟/要塞永久瘫痪；修复多次召唤龙船导致之前的龙船回血\n',
    '327版本更：龙船初始血量从30000改为6000，从第10回合起龙船出现得越晚血量越高，第18回合抵达上限30000\n'
    .. '326版本更\n1.修复325版本的众多bug\n2.龙船可以使用两次，第一次1艘，第二次2艘，冷却一回合\n3.取消神州岚影刺的造1送2;百夫长改为使用3次\n'
    .. '325版本重大更新\n1.顶部技能重构！每个玩家的前两个顶部技能可以选择其中一个组合（炸弹+达摩，铁幕+时停，龙船+元帅）,选定后无法修改' ,
    '321版本更\n1.修复盟军超时空突袭技能偶尔失效的问题\n2.房主可选择是否禁止生成海军\n3.帝国大头出生点改到陆地空军，并且可同时使用导弹和激光武器（海面武器）' ,
    '319版本更\n1.神州鼎（318新机制）改为120秒后返钱1100，并且最多只会有3个鼎在同时扣血\n2.百夫长改为每回合开始可立刻使用4次，第1回合只能使用2次；第9回合解锁千夫长，对相同单位连续使用可获得万夫长\n3.顶部技能现在有10秒冷却时间 以防止连点两次\n4.检测到帝国卡电厂核心时会自动取消建造' ,
    '318版本更\n1.神州鼎机制修改：不可开启售电模式，会持续扣血2分钟然后死亡，死亡时返钱1200\n2.死亡模式下，所有人都会在开局2分钟后得到超时空物流协议\n3.修复塔被冷冻的bug, 修复缩小模式下船直接冲去后面的问题\n4.坦克和船在缩小模式下额外获得2倍血量提升' ,
    '317版本更\n1.缩小模式更新：建筑不再被缩小，选择了缩小模式后，可进一步选择是否启用死亡模式效果（水陆只有1座塔，科技全开）\n 坦克和船在缩小buff的基础上，获得2倍伤害提升和1.5倍射程提升; 海豚禁止生产\n缩小死亡模式下，陆地额外有加强过的胡杨和磁暴线圈，海里塔额外加强\n2.修复塔仍然可能会被冻住的问题\n3.死亡模式下：盟军超时空解锁提前（建造需求不变），神州开局获得额外3个电厂(总电厂数不变)' ,
    '316版本更\n新增缩小模式：所有ai的坦克、小兵、船、建筑均变成缩小状态, 飞机初始为也为缩小状态（补弹后恢复）' ,
    '315版本更新\n1.神州天火塔效果修改：直接赠送一个迅雷天罡(跟随之后的部队一起出生)\n2.苏联可建造娜塔莎，盟军可建造谭雅\n3.神州建造止戈立场后，获得士气提升技能(己方全体坦克小兵飞机获得18秒的1.25倍移速和伤害加成)，冷却时间220秒\n4.帝国波能射程恢复，伤害降低百分之25' ,
    "314版本更新\n1.帝国的机械化组装协议新增效果：获得全体坦克护盾技能，给所有己方坦克套上纳米护盾，冷却时间180秒\n2.修复时间停止技能只能用一次的bug,取消神州摇光数量限制\n3.初始协议点数变为2个（但开局依然只能点第一行协议）\n4.海3塔赏金降低到每人3000\n5.开局房主可选择正常模式或者死亡模式，死亡模式下只有海陆各只有一个塔，第三回合后获得7点协议点数并且可点击5级协议",
    '312死亡模式\n开局陆地和水里都只会剩余最后一座塔，科技全开' ,
    '311版本更新，在310基础上\n1.取消帽子协议花费\n2.VX优先对空\n3.调低空对地战斗机攻击倍率，取消血量加成。' ,
    '310版本更新，在306基础上\n1.修复了闪退BUG \n2.单位平衡调整：所有基础坦克血量↑\n苏联{磁暴步兵射程伤害↑ 双刃血量射程伤害↑ 重锤射程↓}\n盟军{冷冻血量射程伤害↑ 雅典娜射速↑ 冰人血量伤害↑ 先锋血量射程伤害↑}\n帝国{忍者射程射速↑ VX朱雀伤害↑ 鬼王血量↑ 鬼王X血量射程伤害↑ 心神血量↑ 雉刀伤害↑ 太刀伤害↑  浪人血量↓ 波能射程↓}\n神州{T1步兵伤害↑ 岚影刺倍率*2 天罡下方T2,伤害↑ 清风射程伤害↑ 毕方射程血量伤害↑ 朱雀射程血量伤害↑ 金乌血量伤害↑ 摇光微操↑限制只能造三个↓ 记蒙射程↓ }\n3. 天火塔释放后会摧毁并且在对应一塔后生成一个星级天罡给AI\n4. 帽子协议要花费500 ，凌波重甲化免费 \n5. 任意一塔摧毁所有人获得对应阵营机场（帝国无）' ,
    '                            305版本更新\n1.市场交易里加入贷款功能，效果是：立即获得大量资金，但是接下来3分钟电厂没有收入，【只能贷款一次】。初始贷款资金为4000，任意一方陆地1塔掉了之后变为6600,，任意一方陆地2塔掉了之后变为9200，任意一方陆地3塔掉了之后变为11800\n2.顶部技能解锁时间提前到第3回合\n3.海3塔替换为浑天塔, 伤害略微提升\n4.时间停止技能可以使用2次，但每次只能时停13秒\n5.开局会根据阵营赠送对应的船厂',
    '                            304版本更新\n1.经济作弊倍率现在会生效\n2.海3塔血量略微上升，射程增加百分之二十\n3.海3塔被摧毁后，被摧毁的一方会在16秒后在海上出现一个超级要塞作为防卫\n4.电能纳贡协议被禁止，只保留解锁蓄元鼎的效果',
    '                  303版本更新  第一页\n1.海3塔被摧毁后，将立即额外释 放一次达摩克利斯之剑(不消耗顶部按钮释放次数)\n2.海1塔赏金提高到每人1000，海2塔赏金提高到每人2000，海3塔赏金提高到每人5000\n3.海塔被摧毁后，后面的海塔会移动到前面\n4.投资初始上限改为200，每次失败增加400，当投资上限超过1800，胜利后投资上限只砍半\n5.陆地1塔替换为机枪碉堡,血量略微降低\n6.神州百夫长协议cd改为8秒',
    '                  303版本更新  第二页\n7.神州的电能纳贡效果变为解锁蓄元鼎建造(第3回合后)，但只能给【其他阵营】的【友军】电厂加钱，不受导流尖塔影响，不受盟军电厂升级影响，并且蓄元鼎会逐渐扣血，当使用苏联大电厂产钱时，只有神州能从中获得钱\n8.帝国超级要塞解锁不再需要摧毁海3塔\n9.东风导弹车禁止生产\n10.初始电量减少\n11.建造重工后会送一个对应阵营的基础反步兵坦克',
    '                                                         \n测试/BUG建议群：219951578地图更新!作者：Myself/群复读机\n1、海域合并。\n2、最前方的苏霍伊会把后方的非重甲或炮车载具往前方空投。\n3、超时空改为技能，将非重甲或炮车载具往前方传送。',
    '                                                    老版本更新日志 \n6、神州电厂进行了平衡性调整，前期资金会变少，但后期会更强，盟军先锋变换为AC130\n7、取消了T2船只的无碰撞，略微加快了雅典娜的蓄力时间，第二次升级后盟军可以制造超时空传送仪\n8、修改了开局方式，需要所有人确定看完更新说明才可开始(人机默认阅读完成)\n9、禁用了苏联起重机，修复了冷冻可以秒杀防御塔的BUG，可以更换BGM了，加入了结算动画\n10、修改了技能释放方式，第五回合解锁技能，通过顶部技能栏释放',
    '                                                    老版本更新日志 \n10、盟军超时空在建造之后会转换成超时空技能，冷却三回合\n11、上半为天界，下半为地狱，可以随时查看守护者知晓自己的阵营\n12、纳米虫巢会在敌方二塔被摧毁后解锁，并且双方玩家已和电脑结盟，可以给电脑的单位加上自己的协议了\n13、双方铁幕位新增加一个时停的技能，龙船位增加一个可使用两次的空军元帅技能，炸弹位增加一个可以使用两次的持续打击技能\n14、所有除龙船外的升级和协议加成都可以同步对应的电脑\n15、修复了龙船武器bug，减少了龙船数量提高了龙船血量，铁幕时间缩短但可以使用两次',
    '                                                    老版本更新日志 \n16、回调了铁幕时间，可以使用两次15秒的铁幕，并且盟军现在点出自由贸易后电厂产钱会增加\n17、加入了市场交易，可以向其他玩家转移资金，并且加入了投资功能\n18、队伍里每个人都能进行投资，总金额共享，只能在剩余时间大于40秒的时候进行投资\n19、每回合结束后会统计两边的单位总价值，胜利的一方三个人都可以获得投资里的同等金额，失败方则没有，但失败的一方投资上限会增加(最高上限4000)，并且在胜利后会回到初始上限(400)\n20、一二塔加装了小型炸弹，巨炮加装了略微的回复效果\n21、加入了投降选项并将技能获取时间调整为第五回合',
    '                               294版本更新\n1.海里塔被摧毁有赏金，1塔每人500，2塔每人900,3塔每人2100\n2.盟军侦查卫星协议被禁用，元神互锁禁用\n3.科技自然解锁的回合延后，t2在第5回合，t3在第11回合，t4在第18回合\n4.船去到对面出生点的赏金从200提高到300',
    '                               298版本更新\n1.天火塔可以正常使用了\n2.一塔血量提高，两边三塔掉落后的支援单位增强\n3.t4大船和超级要塞解锁逻辑修改：摧毁对方海3塔后才能出t4大船和超级要塞\n4.海2塔被摧毁后，攻击方将获得船坞科技建筑',
}

-- 语言切到 en 时由 g_GetUpdateBoxText() 取这一份；两条数组条数必须一致，否则翻页会错位。
g_UpdateBoxTextEn = {
    g_RuleTextEn,
    "363 Update Notes\n1, New Hextech Rune system：rarity is rolled once for the whole field on rounds 3, 10 and 18 (the host may also enable round 27), after which every player picks one of three cards on their own. A chosen rune lasts the whole game and is applied per unit type whenever units spawn each round. The host can set the number of grants to 0-4 and rerolls to 1 or 3 (in 3-reroll mode each card may be rerolled once); single player automatically gets unlimited rerolls. When the Hextech event is due, the screen shows 'You have an unselected Hextech rune, press J to open the panel'; press J again to hide or reopen it. The 5th top button becomes the 'Hextech Panel', listing every player's runes on both sides, with seats inherited from teammates shown in gold. Whenever someone receives a rune, the whole map is notified once：'A Hextech rune has been received, please check~'.\n2, New skill set：Hail Hydra + Frozen Wasteland. Hail Hydra：send spies behind enemy lines and mind-control half of the enemy units on the field at random (1 use, 70 s cooldown). Frozen Wasteland：immediately freeze every enemy unit on the field, excluding defense towers and structures (2 uses, 70 s cooldown). The two skills of one set share a 10 s common cooldown so they cannot be spammed.\n3, New Pure Draw mode and Lucky Crate feature. Pure Draw mode：crates are available from the start; every 3 rounds the 5 production credits are refilled (the remaining credits are shown on screen), and any unit produced after the credits run out is cancelled automatically; half of all draw results are replaced with weighted buildable units from all factions; ten-pull airdrops appear at random in the center of the field (the formation is rerolled each time). Pure Draw no longer overwrites the Hextech settings, and crates no longer produce engineers. The Lucky Crate feature is the old crate mode：in normal spawn mode it unlocks once a first tower is destroyed.\n4, New Ban Mode (in the host's 'More Options' menu)：infantry, vehicles, aircraft or navy can be banned outright, up to 3 categories at once. Banned unit types are removed from spawning, the crate pool, the ten-pull pity, the transformation/upgrade recombobulators and from gift-type and replacement-type runes; dual-form units only disappear from the field when every unit type they are registered under is banned.\n5, Reworked start menu：Game Mode / Pure Draw selection / Hextech Rune settings / More Options / Skill Set. Draw and Hextech are two independent options and never overwrite each other's state.\n6, New vehicle loading：vehicles spawned from both sides' AI pools now load the infantry their faction already owns, with no limit on how many are loaded; the Trojan Fortress starts with its own Javelin soldiers cleared out and is then reloaded; the unload button is disabled while loaded.\n7, New unit lifetime rule：(default) units on the field are removed 4 rounds after they spawn, so the field holds at most 4 rounds' worth of spawns. Yaoguang keeps only the batch deployed in the current round until tier 4 is unlocked and returns to the default lifetime afterwards; guardian units and the dragon ship summoned by 'Dragon Lord' are not affected.\n8, New inheritance — extended for teammates who leave：the small-power share (power plant cap), unit cap, Dongfeng Express quota, existing runes, plus Backpack Ready / While I'm At It and cards still queued, being picked or not yet chosen are all transferred to the inheritor on the same side, and the inheritor gets one pick per inherited seat in a rune event.",
    "362 Update Notes\n1, Range AI adjusted for the following units (Prism Tank, Zhurong Thunder Gun, Qingfeng, Hammer, Guardian, Ghost King X)：they now prefer the farthest enemy in range, so they no longer push forward. Striker VX prefers the nearest target so it no longer chases aircraft.\n2, Dedicated AI for artillery vehicles (White Tiger, V4, Wave-Force, Athena, Giga Fortress head form)：when tanks are on the field they seek tanks first, then infantry, then structures; they stop moving when a structure enters range.\n3, The fixed-route AI of anti-air aircraft (Apollo, Ares, Phoenix, Chongming, Tengu, Shin-Zen, MiG, Suhoy) is removed and they move freely (Shin-Zen has surprising tactical uses?).\n4, The mines left by the Rhino's F skill are cleared every round (a large pile of mines freezes the game).\n5, The F skills of Cryo Legionnaire and Glory are disabled.\n6, Yaoguang is capped at 3 per player, counted cumulatively while alive on the field.\n7, The Empire can now build Yuriko; target priority is tanks > aircraft > infantry, but Yuriko never attacks structures (she deletes towers by percentage damage).\n8, Natasha priority is infantry > tanks > structures; Tanya blows up a tower only once; hero units (Yuriko, Natasha, Tanya) are no longer limited.\n9, Empire units now appear in aircraft form.\n10, Each Giga Fortress entry form has a 50% chance.\n11, The F skills of the Guardian Tank, Pacifier, White Tiger and Tsunami Tank are enabled.\n12, With navy banned, Sea Wings and Tesla Boats (unlocked on round 3) spawn from land instead.\n13, The Empire Fanatic Warrior no longer forces its skill.\n14, The Soviets may build bikes on round 1 and may build airfields during the preparation phase.\n15, More units can be recycled.\n16, Land tower 1 health raised to 450 (exactly one Damocles strike).\n17, Fixed the case where a random skill copied only itself; at least one other skill is now guaranteed.\n18, Reworked the Temporal Raid skill so random targets no longer pile up.\n19, New defense towers：Sakura Well 10000, Aegis Shield Generator 15000.\n20, Players may build engineers again to recover from the engineer bug that blocked draws.\n21, Suhoy 2x health, Sakura Thunder 3x health, Kirov 1.5x speed, Vanguard 2x health, Apocalypse 1.25x health, Qilin 1.25x health, Chongming range -25％, Tesla Boat attack speed +25％, Cryo Legionnaire attack speed -25％, Tanya +25％ range, Lanying Thorn buffs Zhurong attack speed, Yuriko 2.5x range, Tsunami Tank uses heavy-unit armor, Athena damage restored to vanilla, Cryo Legionnaire range restored to vanilla.\n22, Fixed the power plant cap inheritance after a teammate leaves, again.\n23, Fixed a large number of known bugs.",
    "359, 360, 361 Update Notes\n1. Crate units may be recycled, but at a lower price\n2. The Empire Fanatic Warrior bug becomes a feature：every 2 Empire Warriors built grant 1 Fanatic Warrior; Warrior recycle price adjusted\n3. Carriers and battleships drawn from crates no longer grow endlessly every round\n4. Sea tower positions adjusted further\n5. In normal mode the field of both sides is also cleared on round 23\n6. ACVs can be recycled\n7. The Nano Repair skill heals sea towers for 15％ health\nVersion 360 fixes the wrong power plant cap after drawing a Celestial MCV\nVersion 361 fixes the bug where the Nightingale could not be attacked",
    "356, 357, 358 Update Notes\n1. Pure Draw mode supported (unlocks after a first tower explodes)\n2. The Empire gets a free War Factory after a first tower explodes; Tachi fires its skill automatically\n3. Allied Cryo upgrade and Soviet Overload Coil upgrade supported\n4. Sea tower 2 moved 100 distance backwards\n5. Some of Uncle Yang's buffs removed\n6. Fixed the bug where Ares could not be recycled; fixed Waverider appearing twice\nVersion 358 already fixed the bug in 357 where crates were free",
    "353, 354, 355 Update Notes\n1. Recycled units now refund only 0.9x of their cost, and only 0.72x for the Soviets after Mass Production\n2. Recycle buttons removed from every faction's tier 4 capital ship\nIn normal mode both sides' units on the field are cleared at the start of round 9\nSoviet bikes can only be built from round 3\nSea tower 2 gains attack and range",
    "350, 351, 352 Major Update\nThe unit recycle mechanism is added：a button recycles units you have already produced, refunding some money (normally equal to the cost) and reducing that unit's count (which affects how many spawn each round)\nWhen recycling, if the requested amount is larger than the unit's current count, only the current count is recycled\nFixed several recycle bugs",
    "347 Update Notes\n1. Fixed the bug where the Allies could upgrade to tier 3 with the Expansion Vehicle while ignoring tech limits\n2. The Wave-Force nerf is reverted; in faction expansion mode Athena's 5％ range buff no longer applies\n3. The Empire may use the Condom protocol\n4. Tanya is limited to two",
    "346 Update Notes\n1. Support for more new Corona units\n2. Fixed the bug where copying Time Stop became Bomb",
    "344 Update Notes\n1. The Allied Peacekeeper's shield skill is disabled again\n2. The Soviet Suhoy health buff drops from 3x to 1.5x",
    "343 Update Notes\nThe money needed to unlock tech in Level-Up Mode is raised. In Level-Up Mode, destroying land towers 1 and 2 no longer kills nearby enemy units, land towers 3 and 4 lose health, and no old Apocalypse tanks appear after land tower 2 is destroyed\nThe money needed to raise a tech level is raised, but it decreases as rounds go by (with a lower bound)",
    "341 and 342 Update Notes\n1. New Level-Up Mode：tech and buildable power plants do not unlock naturally, and destroying towers does not unlock them either\nBoth sides must pay for tech levels to gain access to higher-tier units and more power plants (one player paying unlocks it for everyone on that side)\n2. Both sides' tower 4 becomes a Grand Cannon again, the abnormal Damocles Sword damage is fixed, and the bounty for destroying sea tower 3 drops to 2000 per player\n3. Natural tech unlock rounds are pushed back by one round：rounds 6, 12 and 19 unlock the tech of the following round\n4. Sea tower 3 gains a large amount of damage and range",
    "340 Update Notes\n1. The four factions' super towers are banned, as are the Empire Oblivion Bomb and the Allied Chrono Gathering\n2. The Allied Peacekeeper may use its skill again\n3. Both sides' tower 4 is replaced by the Soviet Reef Coastal Missile Fortress",
    "336 Update Notes\nBank loans are removed and buying defense structures is added：buy a Shield Tower and a Poplar Tower (at most one of each may exist per side at a time; after it is destroyed another can be bought)\nShield Tower costs 10000, has 5500 health, 1.25x fire rate and 1.25x attack range\nPoplar Tower costs 12000, has 9000 health, 1.5x attack range, 2x damage and 1.5x fire rate\n2. The Kill Reward skill is removed and replaced by Copy Enemy Skill, which can be used once",
    "334 Update Notes\n1. Nano Repair changed：it now spawns a nano repair field plus 4 large repair lanterns\n2. New skill set：Kill Reward + Copy Skill\nKill Reward：put a money bag on all enemy land units and ships, excluding aircraft, for 30 seconds; killing them pays the caster (70 s cooldown)\nCopy Skill：copy the skill your side used most recently (if the most recent one was Copy Skill, keep going back to the most recent non-copy skill); if nothing suitable is found, nothing is cast (30 s cooldown)\n3. The dragon ship's starting health rises to 8000, it always spawns at the very front, and the Damocles skill is cut to 11 seconds",
    "331 Update Notes\n1. Start options reworked; the host can choose the skill set mode：players pick their own, or the host decides, or random (the system hands each player a set)\n2. The unit gifted by the Skyfire Tower becomes the Armor-Piercing Guard\nThe Allied ACV distinguishes sea from land：one built at the naval yard goes to sea, one built at the War Factory goes to land",
    "329 Update Notes (page 1)\nNew skill set：Nano Repair and Reinforce Army\nNano Repair：spawn a nano repair field near a frontline defense tower, healing friendly units and defense towers (2 uses)\nReinforce Army：immediately trigger one extra land and air spawn (2 uses)\n2. Damocles duration reduced from 16 to 14 seconds\nAn attempt to fix Time Stop leaving spawned Apocalypse / Fortress units permanently paralyzed; fixed the dragon ship healing after several summons",
    "327 Update Notes：the dragon ship's starting health goes from 30000 to 6000, and from round 10 on the later it appears the more health it has, reaching the 30000 cap on round 18\n326 Update Notes\n1. Fixed many bugs from 325\n2. The dragon ship may be used twice, one ship the first time and two the second time, with a one-round cooldown\n3. The Celestial Lanying Thorn no longer gives 2 free units per 1 built; Centurion changed to 3 uses\n325 Major Update\n1. Top skills reworked! Each player's first two top skills may be chosen as one of the combos (Bomb + Damocles, Iron Curtain + Time Stop, Dragon Ship + Air Marshal); the choice cannot be changed afterwards",
    "321 Update Notes\n1. Fixed the Allied Temporal Raid skill occasionally failing\n2. The host can choose whether to ban navy spawning\n3. The Empire Giga Fortress spawn point moves to the land air spawn, and it can use missile and laser (surface) weapons at the same time",
    "319 Update Notes\n1. The Celestial Ding (new in 318) now refunds 1100 after 120 seconds, and at most 3 dings lose health at the same time\n2. Centurion can be used 4 times right at the start of each round, but only twice on round 1; Chiliarch unlocks on round 9, and using it on the same unit repeatedly yields the Myriarch\n3. Top skills now have a 10 second cooldown so they cannot be double-clicked\n4. Building the Empire power plant core is cancelled automatically when it would be blocked",
    "318 Update Notes\n1. The Celestial Ding mechanic changes：power selling mode cannot be enabled, it keeps losing health for 2 minutes and then dies, refunding 1200 when it dies\n2. In Death Mode everyone receives the Chrono Logistics protocol 2 minutes after the start\n3. Fixed towers being frozen, and fixed ships rushing to the back in Shrink Mode\n4. Tanks and ships gain an extra 2x health in Shrink Mode",
    "317 Update Notes\n1. Shrink Mode update：structures are no longer shrunk. After choosing Shrink Mode you may also choose whether to apply the Death Mode effect (one tower each on land and sea, all tech unlocked)\nTanks and ships gain 2x damage and 1.5x range on top of the shrink buff; dolphins cannot be produced\nIn Shrink Death Mode the land side additionally gets buffed Poplar towers and Tesla Coils, and the sea towers are buffed as well\n2. Fixed towers still being frozen\n3. In Death Mode：the Allied chrono skills unlock earlier (build requirements unchanged), and the Celestial start with 3 extra power plants (total power plants unchanged)",
    "316 Update Notes\nNew Shrink Mode：every AI tank, infantry unit, ship and structure is shrunk, and aircraft start shrunk as well (returning to normal after reloading)",
    "315 Update Notes\n1. The Celestial Skyfire Tower effect changes：it now gifts a Thunder Tiangang directly (spawning together with the following units)\n2. The Soviets may build Natasha and the Allies may build Tanya\n3. After the Celestial build the Zhige Field they gain the Morale Boost skill (all friendly tanks, infantry and aircraft gain 1.25x speed and damage for 18 seconds), 220 s cooldown\n4. Empire Wave-Force range restored, damage reduced by 25％",
    "314 Update Notes\n1. The Empire Mechanical Assembly protocol gains a new effect：the All-Tank Shield skill, putting nano shields on all friendly tanks, 180 s cooldown\n2. Fixed the bug where Time Stop could only be used once; the Celestial Yaoguang count limit is removed\n3. Starting protocol points become 2 (the first row of protocols is still the only one clickable at the start)\n4. Sea tower 3 bounty drops to 3000 per player\n5. At the start the host may choose Normal Mode or Death Mode; in Death Mode there is only one tower each on land and sea, 7 protocol points are granted from round 3 on and tier 5 protocols become clickable",
    "312 Death Mode\nAt the start only the last tower remains on both land and sea, and all tech is unlocked",
    "311 Update Notes, on top of 310\n1. The Hat protocol no longer costs anything\n2. Striker VX prioritizes air targets\n3. Lowered the attack multiplier of air-to-ground fighters and removed their health bonus",
    "310 Update Notes, on top of 306\n1. Fixed a crash bug\n2. Unit balance：all basic tanks gain health\nSoviet {Tesla Trooper range damage up, Twinblade health range damage up, Hammer range down}\nAllied {Cryo health range damage up, Athena fire rate up, Ice Man health damage up, Vanguard health range damage up}\nEmpire {Shinobi range fire rate up, Striker VX Vermilion Bird damage up, Ghost King health up, Ghost King X health range damage up, Shin-Zen health up, Nagamaki damage up, Tachi damage up, Ronin health down, Wave-Force range down}\nCelestial {T1 infantry damage up, Lanying Thorn multiplier x2, Tiangang moved down to T2 with damage up, Qingfeng range damage up, Bifang range health damage up, Vermilion Bird range health damage up, Golden Crow health damage up, Yaoguang micro up and limited to three, Jimeng range down}\n3. After the Skyfire Tower is used it is destroyed and a star-level Tiangang spawns behind the matching first tower for the AI\n4. The Hat protocol costs 500, and the Waverider heavy armor upgrade is free\n5. When any tower is destroyed everyone receives the airfield of the matching faction (the Empire gets none)",
    "305 Update Notes\n1. Loans are added to the market：you immediately receive a lot of money but your power plants earn nothing for the next 3 minutes, and you may only take one loan. The starting loan is 4000; it becomes 6600 once any side's land tower 1 falls, 9200 once land tower 2 falls and 11800 once land tower 3 falls\n2. Top skills unlock one round earlier, on round 3\n3. Sea tower 3 is replaced by the Huntian Tower, with slightly more damage\n4. Time Stop may be used twice, but each use stops time for only 13 seconds\n5. At the start each side is gifted the matching naval yard",
    "304 Update Notes\n1. The economy cheat multiplier now takes effect\n2. Sea tower 3 gains a little health and 20％ more range\n3. After sea tower 3 is destroyed, the side that lost it gets a Giga Fortress on the sea 16 seconds later as a defense\n4. The Power Tribute protocol is banned, keeping only its effect of unlocking the Deposit Ding",
    "303 Update Notes, page 1\n1. After sea tower 3 is destroyed a Damocles Sword is cast immediately (it does not consume a top button use)\n2. Sea tower bounties rise：sea tower 1 to 1000 per player, sea tower 2 to 2000 and sea tower 3 to 5000\n3. Destroying a sea tower makes the ones behind it move forward\n4. The initial investment cap becomes 200 and rises by 400 on each failure; once the cap passes 1800 it is only halved after a win\n5. Land tower 1 is replaced by a machine gun bunker with slightly less health\n6. The Celestial Centurion protocol cooldown becomes 8 seconds",
    "303 Update Notes, page 2\n7. The Celestial Power Tribute effect now unlocks the Deposit Ding (after round 3), but it only adds money to power plants of friendly players of other factions, is unaffected by the Diversion Spire and by Allied power plant upgrades, and the Deposit Ding slowly loses health; when Soviet super reactors earn money only the Celestial profit from it\n8. Unlocking the Empire Giga Fortress no longer requires destroying sea tower 3\n9. The Dongfeng missile launcher cannot be produced\n10. Starting power is reduced\n11. Building the War Factory grants a basic anti-infantry tank of the matching faction",
    "Test / bug report group：219951578 Map update! Author：Myself / group repeater\n1. Sea zones merged.\n2. The frontmost Suhoy airdrops non-heavy-armor or artillery vehicles from the back to the front.\n3. Chrono becomes a skill that teleports non-heavy-armor or artillery vehicles to the front.",
    "Old Update Notes\n6. The Celestial power plants were rebalanced：less money early, stronger later; the Allied Vanguard becomes an AC130\n7. Tier 2 ships lose their no-collision rule, Athena charges slightly faster, and after the second upgrade the Allies can build the Chrono Teleporter\n8. The start sequence changed：everyone must confirm they have read the update notes before the game starts (AI counts as read)\n9. The Soviet crane is disabled, the bug where freezing instakilled defense towers is fixed, the BGM can be changed and a results animation was added\n10. Skill casting changed：skills unlock on round 5 and are cast from the top skill bar",
    "Old Update Notes\n10. The Allied Chrono becomes a Chrono skill once built, with a three-round cooldown\n11. The upper half is Heaven and the lower half is Hell; you can always check a Guardian to learn your faction\n12. The Nano Hive unlocks after the enemy's second tower is destroyed, both players are allied with the AI, and you can apply your protocols to AI units\n13. Both sides' Iron Curtain slot gains a Time Stop skill, the Dragon Ship slot gains an Air Marshal skill usable twice, and the Bomb slot gains a sustained strike skill usable twice\n14. Every upgrade and protocol buff, except the dragon ship, can be shared with the matching AI\n15. Fixed the dragon ship weapon bug, reduced the number of dragon ships and raised their health, and shortened Iron Curtain while making it usable twice",
    "Old Update Notes\n16. Iron Curtain duration reverted：two 15 second curtains are available, and Allied power plants earn more after Free Trade is taken\n17. Market trading is added, money can be transferred to other players, and the investment feature is added\n18. Every player on a team can invest, the total is shared, and investing is only possible while more than 40 seconds remain\n19. After each round both sides' total unit value is counted; on the winning side all three players receive the same amount from the investment pool, the losing side gets nothing but its investment cap rises (up to 4000) and returns to the initial cap (400) after a win\n20. Towers 1 and 2 get small bombs and the Grand Cannon gets a small heal effect\n21. A surrender option is added and skills are obtained from round 5 on",
    "294 Update Notes\n1. Destroying sea towers pays a bounty：tower 1 500 per player, tower 2 900 and tower 3 2100\n2. The Allied Recon Satellite protocol is disabled, as is Soul Interlock\n3. Natural tech unlock rounds are pushed back：tier 2 on round 5, tier 3 on round 11, tier 4 on round 18\n4. The bounty for reaching the enemy spawn point with a ship rises from 200 to 300",
    "298 Update Notes\n1. The Skyfire Tower works properly again\n2. Tower 1 gains health and the support units granted after each side's third tower falls are stronger\n3. Tier 4 capital ships and the Giga Fortress unlock differently：the enemy's sea tower 3 must be destroyed first\n4. After sea tower 2 is destroyed the attacker receives a naval tech structure",
}

-- 当前语言下该用哪一份更新日志（中文 / 英文）。
function g_GetUpdateBoxText()
    if Localization.lang == "en" then
        return g_UpdateBoxTextEn
    end
    return g_UpdateBoxText
end

g_UpdateBoxTextNum = getn(g_UpdateBoxText);
g_QQGroupText = Localization.get('game.qq_group');

-- 第 1 页（游戏规则页）必须走"单玩家版" exShowLongTextDialogForPlayer 逐人显示。
-- 没有 EvaluateCondition 时退回旧的全局调用，保证不会因为少一个函数而整段脚本中断。
if EvaluateCondition ~= nil then
    for i = 1, 8, 1 do
        if EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY", 'Player_'..i, "Human") then
            exShowLongTextDialogForPlayer('Player_'..i, 1, g_SafeText(g_QQGroupText) .. g_SafeText(g_RuleText), '', Localization.get('dialog.read_done'), Localization.get('dialog.update_log'))
        end
    end
else
    exShowLongTextDialog(1, g_SafeText(g_QQGroupText) .. g_SafeText(g_RuleText), '', Localization.get('dialog.read_done'), Localization.get('dialog.update_log'))
end

function onUserLongTextDialogEvent(playerName, btnIndex, dialogId)
    local o
    for i = 1,8,1 do
        if playerName=='Player_'..i then
            o=i
        end
    end

    if btnIndex == 1 then
        local prevText = '';
        if dialogId > 2 then
            prevText = Localization.get("dialog.previous_page")
        end
        local box = g_GetUpdateBoxText()
        exShowLongTextDialogForPlayer(playerName, dialogId - 1, g_SafeText(g_QQGroupText) .. g_SafeText(box[dialogId - 1]), prevText, Localization.get("dialog.read_done"), Localization.get("dialog.next_page"))
    end

    if btnIndex == 3 then
        local nextText = '';
        if dialogId < (g_UpdateBoxTextNum - 1) then
            nextText = Localization.get("dialog.next_page")
        end
        local box = g_GetUpdateBoxText()
        exShowLongTextDialogForPlayer(playerName, dialogId + 1, g_SafeText(g_QQGroupText) .. g_SafeText(box[dialogId + 1]), Localization.get("dialog.previous_page"), Localization.get("dialog.read_done"), nextText)
    end

    if btnIndex==2 then
        local o = (PlayerIndex and PlayerIndex[playerName]) or 1
        ExecuteAction("CREATE_NAMED_ON_TEAM_AT_WAYPOINT",playerName,'AlliedWallPiece','PlyrCreeps/teamPlyrCreeps','toupiaodian'..o)
        exMessageAppendToMessageArea(Localization.get("dialog.read_completed", o))
        exCustomBtnRemoveForPlayer(playerName, 999)
        exCustomBtnRemoveForPlayer(playerName, 1000)
        exCustomTextUpdateVisibilityForPlayer(playerName, 1000, 0)
    end
end

local LanguageButtonX = 1366 / 2
local LanguageButtonY = 550
exCreateCustomImage({
    Index = 999,
    TextureName = "AptWhiteBox",
    X = LanguageButtonX - 80,
    Y = LanguageButtonY - 5 ,
    SizeX = 160,
    SizeY = 60,
    GroupIndex = 999,
})
exCreateCustomButton({
    Index = 1000 ,
    TextureName = "AptWhiteBox",
    Desc = "",
    X = LanguageButtonX  - 75,
    Y = LanguageButtonY ,
    SizeX = 150,
    SizeY = 50,
    GroupIndex = 1000,
})
exCreateCustomText({
    Index = 1000,
    Content = "中文 / English",
    X = LanguageButtonX  + 30,
    Y = LanguageButtonY + 10,
    Color = HexToInt32("0xFFFFFF"),
    Size = 18,
})
exCustomImageGroupSetColor(1000, HexToInt32("0xFF800000"))
exCustomBtnGroupSortDepthAboveAnotherGroup(1000, 999)
ButtonManager:RegisterCustomButtonHandler(function(playerName, index)
    if playerName ~= exGetLocalPlayer() or index ~= 1000 then
        return nil
    end
    if Localization.lang == "zh" then
        Localization.set_language("en")
    else
        Localization.set_language("zh")
    end
    g_RuleText = g_GetRuleText()
    -- 两份日志的第 1 项各自是对应语言的规则页，切语言时重新指向即可
    g_UpdateBoxText[1] = g_RuleTextZh
    g_UpdateBoxTextEn[1] = g_RuleTextEn
    g_UpdateBoxTextNum = getn(g_UpdateBoxText);
    g_QQGroupText = Localization.get('game.qq_group');
    -- 切语言后重弹规则页，同样改走单玩家版（这个回调只对本机玩家生效）。
    -- 先显式关掉旧对话框再弹：同一个 dialog_id 在旧语言下已经渲染过一次，直接覆盖容易留下旧缓存。
    if exHideLongTextDialogForPlayer ~= nil then
        exHideLongTextDialogForPlayer(playerName)
    end
    exShowLongTextDialogForPlayer(playerName, 1, g_SafeText(g_QQGroupText) .. g_SafeText(g_RuleText), '', Localization.get('dialog.read_done'), Localization.get('dialog.update_log'))
    return 1
end)

TextDoActionLocalized("NAMED_SHOW_INFOBOX", "overlord8", "SCRIPT:lightsoul", "0", "")
TextDoActionLocalized("NAMED_SHOW_INFOBOX", "overlord7", "SCRIPT:darksoul", "0", "")