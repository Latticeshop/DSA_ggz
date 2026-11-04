-- 防御塔开局统一初始化（节点名沿用历史名 TowerFreeOfFreeze，实际做两件事）：
--   ① 14 座地图塔免疫冷冻（IN_SHIELD_SPHERE）；② 七类塔伤害 ×1.5，陆地一塔攻速再 ×1.5。
-- 机制、为什么不用 MAP_* 叠层、待实机核对项见 analysis/地图注释说明文档.md §6.7；数值改下一段常量即可。
local object = GetObjectByScriptName("T71")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T72")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T73")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T74")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)

object = GetObjectByScriptName("T81")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T82")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T83")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T84")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)

object = GetObjectByScriptName("T71F")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T72F")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T73F")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)

object = GetObjectByScriptName("T81F")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T82F")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)
object = GetObjectByScriptName("T83F")
ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", object,"IN_SHIELD_SPHERE", 1)

-- 七类 × 两边：陆地 T71~T74 / T81~T84，海上 T71F~T73F / T81F~T83F（模板见 GAME/TowerUnfreeze.lua）。
-- 陆地一塔（T71 / T81）伤害 +100%、攻速 +50%；其余六类伤害 +50%。
g_TowerStrengthenDamageNames = {
    "T72", "T73", "T74", "T82", "T83", "T84",
    "T71F", "T72F", "T73F", "T81F", "T82F", "T83F",
}
g_TowerStrengthenFirstTowerNames = { "T71", "T81" }

if g_TowerStrengthenDamageModifier == nil then
    g_TowerStrengthenDamageModifier = exAttributeModifierCreate({ DAMAGE_MULT = 1.5 }, 1)
end
if g_TowerStrengthenFirstTowerDamageModifier == nil then
    g_TowerStrengthenFirstTowerDamageModifier = exAttributeModifierCreate({ DAMAGE_MULT = 2.0 }, 1)
end
if g_TowerStrengthenRateOfFireModifier == nil then
    g_TowerStrengthenRateOfFireModifier = exAttributeModifierCreate({ RATE_OF_FIRE = 1.5 }, 1)
end

function g_TowerStrengthenApplyOne(tower, modifier)
    if tower ~= nil and modifier ~= nil then
        ObjectLoadAttributeModifier(tower, modifier)
    end
end

function g_TowerStrengthenApply()
    local index
    local tower
    for index = 1, getn(g_TowerStrengthenDamageNames), 1 do
        g_TowerStrengthenApplyOne(GetObjectByScriptName(g_TowerStrengthenDamageNames[index]),
            g_TowerStrengthenDamageModifier)
    end
    for index = 1, getn(g_TowerStrengthenFirstTowerNames), 1 do
        tower = GetObjectByScriptName(g_TowerStrengthenFirstTowerNames[index])
        g_TowerStrengthenApplyOne(tower, g_TowerStrengthenFirstTowerDamageModifier)
        g_TowerStrengthenApplyOne(tower, g_TowerStrengthenRateOfFireModifier)
    end
end

-- 幂等：节点被重复触发时不要再叠一份（属性修改器是累加的，叠两次就是 ×2.25）。
if g_TowerStrengthenApplied ~= 1 then
    g_TowerStrengthenApplied = 1
    g_TowerStrengthenApply()
end
