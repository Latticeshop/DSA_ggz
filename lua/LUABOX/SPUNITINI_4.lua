unitLIGHTVEHcountmin = 50
unitLIGHTVEHcountmax = 100 
LIGHTVEHSP = {}
LIGHTVEHSPCH = {}
LIGHTVEHSP[7] = {}
LIGHTVEHSP[8] = {}
LIGHTVEHSPCH[7] = {}
LIGHTVEHSPCH[8] = {}
for i = 1 , 6 , 1 do 
    LIGHTVEHSP[7][i] = GetObjectByScriptName("LIGHTVEH1"..i) ;
    ExecuteAction("SET_UNIT_REFERENCE","LIGHTVEHSP7"..i , LIGHTVEHSP[7][i])
    LIGHTVEHSPCH[7][i] = "LIGHTVEHSP7"..i
    LIGHTVEHSP[8][i] = GetObjectByScriptName("LIGHTVEH2"..i) ;
    ExecuteAction("SET_UNIT_REFERENCE","LIGHTVEHSP8"..i , LIGHTVEHSP[8][i])
    LIGHTVEHSPCH[8][i] = "LIGHTVEHSP8"..i
end
--exMessageAppendToMessageArea("物体定义")
LIGHTVEHTEAM = {}
LIGHTVEHTEAM[7] = {}
LIGHTVEHTEAM[8] = {}
LIGHTVEHATTACK = {}
LIGHTVEHATTACK[7] = {}
LIGHTVEHATTACK[8] = {}
for i = 1 , 6 , 1 do 
    LIGHTVEHTEAM[7][i] ="PlyrCivilian/LIGHTVEH"..i ;
    LIGHTVEHATTACK[7][i] = "PlyrCivilian/LIGHTVEHATTACK"..i
    LIGHTVEHTEAM[8][i] ="PlyrCreeps/LIGHTVEH"..i ;
    LIGHTVEHATTACK[8][i] = "PlyrCreeps/LIGHTVEHATTACK"..i
end