require "ProjectYakuza/Registry"
local C={modId="ProjectYakuza",accepted={}}
ProjectYakuza.CombatVoiceLines=C
-- Canonical definitions for CVF 1.1+ pack manifests. These are optional,
-- explicit calls, never additions to vanilla voice pools or CVF's voice wheel.
C.definitions={
    {id="CombatLightAttack",label="Combat - Light attack",cooldown=.25},
    {id="CombatHeavyAttack",label="Combat - Heavy attack",cooldown=.5},
    {id="CombatSpecialMove",label="Combat - Special move",cooldown=.75},
    {id="CombatTaunt",label="Combat - Taunt",cooldown=3},
    {id="CombatExtremeHeatActivation",label="Combat - Extreme Heat activation",cooldown=5},
    {id="CombatStanceEntry",label="Combat - Stance entry",cooldown=2},
    {id="CombatGettingHit",label="Combat - Getting hit",cooldown=.6},
    {id="CombatGettingStunned",label="Combat - Getting stunned",cooldown=1.25},
}
C.byId={}
for _,definition in ipairs(C.definitions) do
    definition.modId=C.modId;definition.wheel=false;C.byId[definition.id]=definition
end
function C.register()
    local api=CustomVoice
    if type(api)~="table" or type(api.registerLine)~="function" or type(api.getLine)~="function" then return false end
    if C.api==api then return true end
    C.api=api;C.accepted={}
    for _,definition in ipairs(C.definitions) do
        local ok,registered,reason=pcall(api.registerLine,definition)
        C.accepted[definition.id]=ok and registered==true
        if not C.accepted[definition.id] then
            print("[ProjectYakuza] CVF line unavailable: "..definition.id.." ("..tostring(reason or registered)..")")
        end
    end
    return true
end
C.register()
Events.OnGameBoot.Add(C.register)
