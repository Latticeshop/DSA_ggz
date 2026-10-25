
UNITSPAIRST (step3+1,step35,LIGHTVEHSP,AIRTEAM,AIRATTACK,LIGHTVEHSPCH)

-- 四个转化符文统一等空军/轻载具批次出完后再结算。原来挂在 LandArmySpawn 末尾的
-- ShrinkMode_Trigger 上，会抢在这批飞机生成之前转换，空军只能转掉早批次。
-- 延迟与 BUFF 首扫同口径（45 帧），给引擎留出补建单位的余量。
if HextechRune ~= nil and HextechRune.ApplyAllConversionPulses ~= nil then
    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(function(conversionRound)
            HextechRune:ApplyAllConversionPulses(conversionRound)
        end, 45, { exCounterGetByName("lvc") })
    else
        HextechRune:ApplyAllConversionPulses(exCounterGetByName("lvc"))
    end
end
