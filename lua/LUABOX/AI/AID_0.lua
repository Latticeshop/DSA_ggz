AI = {0,0,0,0,0,0}
for playindex = 1 , 8 , 1 do
if not EvaluateCondition("PLAYER_IS_HUMAN_OR_AI_PERSONALITY","Player_"..playindex ,"Human") and P[playindex] then
    AI[playindex] = 1 
end
end