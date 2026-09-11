function spinfantlv1 ()
  local unitindex = {}
  for playindex = 1 , 6 , 1 do
  unitindex [playindex] = RANDOMGENERATE(step1, 4)
  ----exMessageAppendToMessageArea("unitindex:"..unitindex [playindex])
  end
  for playindex = 1 , 6 , 1 do  
      local unitindexget = 0
      if unitindex[playindex] >= 0 then
          while unitindexget + 1 <=  unitindex[playindex] do
              unitindexget = unitindexget + 1
          end
      end
     -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
      if AI[playindex] == 1 then
         -- --exMessageAppendToMessageArea("AI造兵")
  --local actindex = floor100(AIFAKEMONEY[playindex])
  ----exMessageAppendToMessageArea("actindex"..actindex)
  ---------------------------------------------------------------
     -- --exMessageAppendToMessageArea("actindex"..actindex)
      UNITCOUNT[playindex][unitindexget] =   UNITCOUNT[playindex][unitindexget] + 1 ;
      ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
    -- --exMessageAppendToMessageArea("playindex:"..playindex)
   --   --exMessageAppendToMessageArea("unitindex:"..unitindexget)
   --   --exMessageAppendToMessageArea("UNITCOUNT[playindex][unitindexget]:"..UNITCOUNT[playindex][unitindexget])
  end
  end
  end
  
  function spinlightvehlv1 ()
  local unitindex = {}
  for playindex = 1 , 6 , 1 do
  unitindex [playindex] = RANDOMGENERATE(step2, step1+1)
  --exMessageAppendToMessageArea("unitindex:"..unitindex [playindex])
  end
  for playindex = 1 , 6 , 1 do  
      local unitindexget = 0
      if unitindex[playindex] >= 0 then
          while unitindexget + 1 <=  unitindex[playindex] do
              unitindexget = unitindexget + 1
          end
      end
     -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
      if AI[playindex] == 1 then
         -- --exMessageAppendToMessageArea("AI造兵")
  --local actindex = floor100(AIFAKEMONEY[playindex])
  ----exMessageAppendToMessageArea("actindex"..actindex)
  ---------------------------------------------------------------
     -- --exMessageAppendToMessageArea("actindex"..actindex)
      UNITCOUNT[playindex][unitindexget] =   UNITCOUNT[playindex][unitindexget] + 1 ;
      ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
     -- --exMessageAppendToMessageArea("playindex:"..playindex)
     -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
    -- --exMessageAppendToMessageArea("UNITCOUNT[playindex][unitindexget]:"..UNITCOUNT[playindex][unitindexget])
  end
  end
  end
  
  function spinheavyvehlv1 ()
      local unitindex = {}
      for playindex = 1 , 6 , 1 do
      unitindex [playindex] = RANDOMGENERATE(step3, step2+1)
      --exMessageAppendToMessageArea("unitindex:"..unitindex [playindex])
      end
      for playindex = 1 , 6 , 1 do  
          local unitindexget = 0
          if unitindex[playindex] >= 0 then
              while unitindexget + 1 <=  unitindex[playindex] do
                  unitindexget = unitindexget + 1
              end
          end
         -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
          if AI[playindex] == 1 then
             -- --exMessageAppendToMessageArea("AI造兵")
      --local actindex = floor100(AIFAKEMONEY[playindex])
      ----exMessageAppendToMessageArea("actindex"..actindex)
      ---------------------------------------------------------------
         -- --exMessageAppendToMessageArea("actindex"..actindex)
          UNITCOUNT[playindex][unitindexget] =   UNITCOUNT[playindex][unitindexget] + 1 ;
          ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
         -- --exMessageAppendToMessageArea("playindex:"..playindex)
         -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
        -- --exMessageAppendToMessageArea("UNITCOUNT[playindex][unitindexget]:"..UNITCOUNT[playindex][unitindexget])
      end
      end
  end
  
  
  function spaircraftlv1 ()
  local unitindex = {}
  for playindex = 1 , 6 , 1 do
  unitindex [playindex] = RANDOMGENERATE(step4, step3+1)
  --exMessageAppendToMessageArea("unitindex:"..unitindex [playindex])
  end
  for playindex = 1 , 6 , 1 do  
      local unitindexget = 0
      if unitindex[playindex] >= 0 then
          while unitindexget + 1 <=  unitindex[playindex] do
              unitindexget = unitindexget + 1
          end
      end
     -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
      if AI[playindex] == 1 then
         -- --exMessageAppendToMessageArea("AI造兵")
  --local actindex = floor100(AIFAKEMONEY[playindex])
  ----exMessageAppendToMessageArea("actindex"..actindex)
  ---------------------------------------------------------------
     -- --exMessageAppendToMessageArea("actindex"..actindex)
      UNITCOUNT[playindex][unitindexget] =   UNITCOUNT[playindex][unitindexget] + 1 ;
      ANYUNITCOUNT[playindex] = ANYUNITCOUNT[playindex] + 1
     -- --exMessageAppendToMessageArea("playindex:"..playindex)
     -- --exMessageAppendToMessageArea("unitindex:"..unitindexget)
    -- --exMessageAppendToMessageArea("UNITCOUNT[playindex][unitindexget]:"..UNITCOUNT[playindex][unitindexget])
  end
  end
  end
  
  