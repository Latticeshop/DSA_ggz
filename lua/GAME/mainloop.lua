function mainloop()
    SchedulerModule.__runner_function()
    if g_BuildingNoCollisionsTick ~= nil then
        g_BuildingNoCollisionsTick()
    end
end