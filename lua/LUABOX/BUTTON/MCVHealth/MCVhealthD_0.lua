local units, count = ObjectFindObjects(T74, nil,CelestialMCV)--获得寻找到的单位的数量
          for i = 1, count do--寻找每一个单位，并操作
             local wuti = ObjectGetId(units[i])
             local str = "Unit11" .. i
   ExecuteAction("SET_UNIT_REFERENCE", str, units[i])
             ExecuteAction("NAMED_SET_MAX_HEALTH","Unit11" .. i,'30000','true') 
        end