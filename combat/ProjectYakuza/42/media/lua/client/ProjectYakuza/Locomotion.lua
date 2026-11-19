require "ProjectYakuza/Runtime"
local PY=ProjectYakuza
local L={states=setmetatable({}, {__mode="k"})}
PY.Locomotion=L
function L.update(p)
    if not p or not instanceof(p,"IsoPlayer")then return end
    local style=PY.getPlayerStyle(p);local rested=false
    if style and style.id=="dragon_of_dojima"and not style.weaponProfile and PY.isEquipped(p)and not p:isDead()then
        if p:isLocalPlayer()then
            local moodles=p:getMoodles()
            rested=moodles:getMoodleLevel(MoodleType.ENDURANCE)==0 and moodles:getMoodleLevel(MoodleType.TIRED)==0
        else
            local speed=tonumber(p:GetVariable("WalkSpeed"))
            rested=not speed or speed>=.60
        end
    end
    if L.states[p]~=rested then p:setVariable("ProjectYakuzaRestedRun",rested);L.states[p]=rested end
end
function L.tick()
    if not isClient()or getTimestampMs()<(L.nextRemote or 0)then return end
    L.nextRemote=getTimestampMs()+250
    local players=getOnlinePlayers()
    if players then for index=0,players:size()-1 do local p=players:get(index);if p and not p:isLocalPlayer()then L.update(p)end end end
end
Events.OnPlayerUpdate.Add(L.update)
Events.OnTick.Add(L.tick)
