JapanTsunamiTankShieldMICROCONTROL ()
JapanTorpedoShipSpreadMICROCONTROL ()
-- 狂热武士由出生事件配置引擎索敌，并使用按单位的轻量技能触发器。
AntiAirAircraftHunterMICROCONTROL ()
JapanAntiAirVehicleTech1MICROCONTROL ()
PrioritySiegeAttackMoveMICROCONTROL ()
-- 轰炸机（维护者 / 伊尔 / 金乌 / 樱花回天雷）优先打陆地炮车，并按机群均分目标；
-- 炮车清空后退化为最近目标。TGMICRO 每 3 帧跑一次：
BomberPrioritySiegeWatchdog ()
BomberPrioritySiegeMICROCONTROL ()
-- 超级要塞形态只在登场时由 SpawnGigaFortress.lua 随机决定，不再周期切换。
JapanAntiAirShipMICROCONTROL ()
SovietScoutVehicleMICROCONTROL ()
-- 太刀微操（自动开技能 + 只索敌水面）已整体停用，函数体见 MOCROCONTROL/MICROINI_0.lua。
-- JapanAntiNavyShipTech3MICROCONTROL()
CommandoNoStructureMICROCONTROL ()
NoStructureBuffedUnitMICROCONTROL ()
if BIGSHIPCONTROL then
    -- 这玩意真的存在吗？我看地图里一直在报错
    BIGSHIPCONTROL ()
end
