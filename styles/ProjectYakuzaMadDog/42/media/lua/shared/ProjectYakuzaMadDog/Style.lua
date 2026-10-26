require "ProjectYakuza/Registry"
require "ProjectYakuzaMadDog/NetworkCatalog"
local motions=require "ProjectYakuzaMadDog/Motions"
local P=ProjectYakuza
assert(P.API_VERSION>=2 and P.prepareTokenAppearance and P.actionKinds.styleEntry,
    "Mad Dog of Shimano requires Project Yakuza with the style weaponSprite API")
local speed=1.8
local function move(name,node,damage)
    local source=assert(motions[name],"Missing Mad Dog motion: "..name)
    return {animation=source.animation,nodeValue=node,duration=source.duration/speed,
        speed=speed,impact=source.impact,damageMultiplier=damage or 1,fullBody=true}
end
local lights,finishers,steps,stepAttacks={},{},{},{}
for i=1,4 do
    local index=string.format("%02d",i)
    local light=move("Light"..index,"md_light_"..index,.95)
    light.chainAt=.62;lights[i]=light
    local finisher=move("Finisher"..index,"md_finisher_"..index,1.5)
    finisher.enabled=true;finisher.afterLight=i
    finishers["after_"..i]=finisher
end
for i,direction in ipairs({"forward","backward","left","right"}) do
    local index=string.format("%02d",i)
    local source=motions["Quickstep"..index]
    steps[direction]={enabled=true,direction=direction,animation=source.animation,
        nodeValue="md_quickstep_"..index,duration=source.duration/1.35,speed=1.35,
        distance=1.0,fullBody=true}
    local attack=move("QuickstepAttack"..index,"md_quickattack_"..index,1.2)
    attack.enabled=true;attack.direction=direction;attack.quickstepAttack=true
    stepAttacks[direction]=attack
end
-- The framework's running controller chooses these four internal variants.
-- Mad Dog intentionally uses its own running knife slash for every trigger.
local running={}
for _,variant in ipairs({"left","right","knee","dropkick"}) do
    local attack=move("RunningSlash","md_run_slash",1.35)
    attack.enabled=true;attack.variant=variant;attack.runningAttack=true;attack.distance=.8
    running[variant]=attack
end
local ground=move("GroundSlash","md_ground_slash",1.2)
ground.groundAttack=true
P.registerStyle({
    id="project_yakuza.mad_dog_of_shimano",
    name="Mad Dog of Shimano",
    description="Majima's original Yakuza 0 knife chain, finishers and evasive slashes.",
    weaponSprite="HuntingKnife",
    attackSpeed=speed,
    comboResetMs=450,
    lightBufferLimit=1,
    lightAttacks=lights,
    groundAttacks={ground},
    -- Shared heat rules; no implicit Kiryu aura, music, reactions or voices.
    heat=true,
    heatHud="yakuza6",
    hitEffects="yakuza6",
    combatVoices=false,
    music=false,
    sounds={punchImpact="HuntingKnifeHit",kickImpact="HuntingKnifeHit",
        heatImpact="HuntingKnifeHit",punchSwing="HuntingKnifeSwing",
        kickSwing="HuntingKnifeSwing"},
    actions={
        finisher={enabled=true,variants=finishers},
        quickstep={enabled=true,cooldownMs=180,variants=steps},
        quickstepAttack={enabled=true,variants=stepAttacks},
        runningAttack={enabled=true,runupMs=250,variants=running},
        block={enabled=true,animation="ProjectYakuza_MD_Guard",staminaPerHit=.08},
        -- Original style-action flourish and stance entry, using shared handlers.
        taunt={enabled=true,animation=motions.Taunt.animation,duration=motions.Taunt.duration},
        heatActivation={enabled=true,animation=motions.HeatActivate.animation,duration=motions.HeatActivate.duration},
        styleEntry={enabled=true,animation=motions.StyleEntry.animation,duration=motions.StyleEntry.duration},
    },
})
