-- 讲解见 analysis/地图注释说明文档.md 附录 A.46

UNITSPAIRST (step3+1,step35,LIGHTVEHSP,AIRTEAM,AIRATTACK,LIGHTVEHSPCH)

if HextechRune ~= nil and HextechRune.ApplyAllConversionPulses ~= nil then
    if SchedulerModule ~= nil and SchedulerModule.delay_call ~= nil then
        SchedulerModule.delay_call(function(conversionRound)
            HextechRune:ApplyAllConversionPulses(conversionRound)
        end, 45, { exCounterGetByName("lvc") })
    else
        HextechRune:ApplyAllConversionPulses(exCounterGetByName("lvc"))
    end
end
