-- 讲解见 analysis/地图注释说明文档.md 附录 A.20

--@angel_cast
-- 施放：冻结本方全体单位 14 秒（210 帧），并挂上常驻裂缝特效。
g_TimeStopFreezeSide(T74, "units", true, 210, 100000000)

--@angel_tick
-- 计时器未到点：把 native 租约续上，顺带把 PARALYZED 重新写回 true。
-- 这个脚本约每 2 秒才评估一次，所以租约必须比它长（60 帧 = 4 秒），
-- 否则 2 秒一次的 sweep 会在两次评估之间把单位错手放开。
g_TimeStopFreezeSide(T74, "units", true, 60, 0)

--@angel_release
g_TimeStopFreezeSide(T74, "units", false, 0, 0)

--@devil_cast
g_TimeStopFreezeSide(T84, "units2", true, 210, 1000000)

--@devil_tick
g_TimeStopFreezeSide(T84, "units2", true, 60, 0)

--@devil_release
g_TimeStopFreezeSide(T84, "units2", false, 0, 0)
