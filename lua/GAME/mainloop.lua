function mainloop()
    SchedulerModule.__runner_function()
    if g_BuildingNoCollisionsTick ~= nil then
        g_BuildingNoCollisionsTick()
    end
    -- 卖船区（SHIPMONEY/GETSHIP__7、__8）的结算循环：首帧停掉那两个地编节点、注册周期扫描。
    if g_SellShipTick ~= nil then
        g_SellShipTick()
    end
end