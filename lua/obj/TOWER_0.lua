FilterTOWER=CreateObjectFilter({
    Rule="ANY",
    IncludeThing = {
       "celestialbasedefenseadvanced","celestialenergygatlingtower" ,"AlliedHeavyArtilleryDefenseBase", "SovietBaseDefenseAdvanced", "JapanBaseDefenseAdvanced"
    }
})
TARTOWER, countTOWER = ObjectFindObjects(nil, nil,FilterTOWER)
--exMessageAppendToMessageArea("countTOWER:"..countTOWER)
function UNFROZEN()
    for i = 1 , countTOWER , 1 do
        local objectId = ObjectGetId(TARTOWER[i])
        exObjectDealSecondaryDamage(objectId, -50000)
        --exMessageAppendToMessageArea("countTOWERp:"..countTOWER)
    end
end

T74= GetObjectByScriptName("T74") ;
T84= GetObjectByScriptName("T84") ;
