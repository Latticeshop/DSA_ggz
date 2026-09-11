unitinfantcountmin = 1
unitinfantcountmax = 40 
INFANTSP = {}
INFANTSPCH = {}
INFANTSP[7] = {}
INFANTSP[8] = {}
INFANTSPCH[7] = {}
INFANTSPCH[8] = {}
for i = 1 , 6 , 1 do 
    INFANTSP[7][i] = GetObjectByScriptName("INFANT1"..i) ;
    ExecuteAction("SET_UNIT_REFERENCE","INFANTSP7"..i , INFANTSP[7][i])
    INFANTSPCH[7][i] = "INFANTSP7"..i
    INFANTSP[8][i] = GetObjectByScriptName("INFANT2"..i) ;
    ExecuteAction("SET_UNIT_REFERENCE","INFANTSP8"..i , INFANTSP[8][i])
    INFANTSPCH[8][i] = "INFANTSP8"..i
end
--exMessageAppendToMessageArea("物体定义")
INFANTTEAM = {}
INFANTTEAM[7] = {}
INFANTTEAM[8] = {}
INFANTATTACK = {}
INFANTATTACK[7] = {}
INFANTATTACK[8] = {}
for i = 1 , 6 , 1 do 
    INFANTTEAM[7][i] ="PlyrCivilian/INFANT"..i ;
    INFANTATTACK[7][i] = "PlyrCivilian/INFANTATTACK"..i
    INFANTTEAM[8][i] ="PlyrCreeps/INFANT"..i ;
    INFANTATTACK[8][i] = "PlyrCreeps/INFANTATTACK"..i
end