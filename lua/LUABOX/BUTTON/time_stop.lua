-- 讲解见 analysis/地图注释说明文档.md 附录 A.20、A.69

--@angel_cast
-- 施放：冻结本方全体单位 14 秒（210 帧），并挂上常驻裂缝特效。
g_TimeStopFreezeSide(T74, "units", true, 210, 100000000)

--@angel_tick
g_TimeStopFreezeSide(T74, "units", true, 60, 0)

--@angel_release
g_TimeStopFreezeSide(T74, "units", false, 0, 0)

--@devil_cast
g_TimeStopFreezeSide(T84, "units2", true, 210, 1000000)

--@devil_tick
g_TimeStopFreezeSide(T84, "units2", true, 60, 0)

--@devil_release
g_TimeStopFreezeSide(T84, "units2", false, 0, 0)
