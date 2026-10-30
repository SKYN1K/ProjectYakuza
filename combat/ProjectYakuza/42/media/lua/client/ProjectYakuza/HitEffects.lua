require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
require "ProjectYakuza/BloodEffects"
local ProjectYakuza=ProjectYakuza
local F={bursts={},pool={},maxBursts=6,maxTotal=24}
ProjectYakuza.HitEffects=F

local chargedParticles={
    {kind="chargeCore",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.20,dx=0,dy=0},
}
for i=1,8 do local a=i*math.pi/4;chargedParticles[#chargedParticles+1]={kind="chargeSpark",path="media/textures/ProjectYakuza/ChargeSpark.png",size=32,scale=.28,dx=math.cos(a)*17,dy=math.sin(a)*14} end
local particles={
    {kind="core",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.20,dx=0,dy=0},
    {kind="spark",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.07,dx=-9,dy=-6},
    {kind="spark",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.08,dx=8,dy=-8},
    {kind="spark",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.06,dx=-5,dy=7},
    {kind="spark",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.07,dx=10,dy=5},
}
local function detach(b)
    for _,e in ipairs(b.emitters) do
        e.instance:Dispose();IsoSpriteInstance.add(e.instance);e.slot.busy=false
    end
end
local function stopIfEmpty()
    if #F.bursts==0 and F.ticking then
        Events.OnTick.Remove(F.update);Events.OnPostRender.Remove(F.render);F.ticking=false
    end
end
function F.clear(player)
    if ProjectYakuza.BloodEffects then ProjectYakuza.BloodEffects.clear(player) end
    for i=#F.bursts,1,-1 do
        local b=F.bursts[i]
        if not player or b.player==player then detach(b);table.remove(F.bursts,i) end
    end
    stopIfEmpty()
end
function F.toggle(player)
    local d=player:getModData();d.ProjectYakuzaHitEffectsDisabled=not d.ProjectYakuzaHitEffectsDisabled
    if d.ProjectYakuzaHitEffectsDisabled then F.clear(player) end
end
local function acquire(point)
    local count=0
    for _,slot in ipairs(F.pool) do
        if slot.kind==point.kind then
            if not slot.busy then slot.busy=true;return slot end
            count=count+1
        end
    end
    if count>=F.maxTotal*4 then return nil end
    local sprite=IsoSprite.CreateSprite(nil)
    sprite:LoadFramesNoDirPageSimple(point.path)
    local slot={sprite=sprite,kind=point.kind,busy=true};F.pool[#F.pool+1]=slot;return slot
end
function F.onHit(player,victim,weapon,damage)
    if not player or not instanceof(player,"IsoPlayer") or not player:isLocalPlayer() or not ProjectYakuza.isEquipped(player)
        or player:getModData().ProjectYakuzaHitEffectsDisabled or type(damage)~="number" or damage<=0
        or not victim or not instanceof(victim,"IsoZombie") then return end
    local s=ProjectYakuza.stateFor(player)
    if ProjectYakuza.getPlayerStyle(player).hitEffects~="yakuza6" then return end
    if not s.active or not weapon or (not (ProjectYakuza.isStyleToken(weapon) or (ProjectYakuza.Weapons and ProjectYakuza.Weapons.matches(player,weapon)))
        and not (s.groundMove and weapon:getFullType()=="Base.BareHands")) then return end
    s.effectVictims=s.effectVictims or setmetatable({}, {__mode="k"})
    if s.effectVictims[victim] then return end
    s.effectVictims[victim]=true
    local move=s.groundMove or s.finisherMove
    local strong=move and (move.neutralHeavy or move.double or move.afterLight or move.chargedHeavy) and not move.runningAttack and not move.quickstepAttack
    F.spawn(player,victim,strong,move and move.chargedHeavy)
end
function F.spawn(player,victim,strong,charged)
    local style=ProjectYakuza.getPlayerStyle(player)
    if not style or style.hitEffects~="yakuza6" then return end
    if player:getModData().ProjectYakuzaHitEffectsDisabled then return end
    if ProjectYakuza.BloodEffects then ProjectYakuza.BloodEffects.spawn(player,victim,strong,charged) end
    local count=0
    for _,b in ipairs(F.bursts) do if b.player==player then count=count+1 end end
    if count>=F.maxBursts or #F.bursts>=F.maxTotal then
        for i,b in ipairs(F.bursts) do
            if count<F.maxBursts or b.player==player then detach(b);table.remove(F.bursts,i);break end
        end
    end
    local tile=Core.getTileScale()
    local b={player=player,victim=victim,emitters={},last=getTimestampMs(),age=0,life=charged and 340 or strong and 280 or 240,strong=strong,charged=charged}
    for _,point in ipairs(charged and chargedParticles or particles) do
        local slot=acquire(point)
        if slot then
            local scale=tile*point.scale*(strong and 1.15 or 1)
            local height=(victim:isOnFloor() and 6 or 26)*tile
            local instance=ProjectYakuza.WorldEffects.attach(victim,slot.sprite,point.size,scale,height,true,0)
            victim:getAttachedAnimSprite():remove(instance)
            instance:SetAlpha(1);instance:SetTargetAlpha(1)
            b.emitters[#b.emitters+1]={slot=slot,instance=instance,point=point,scale=scale}
        end
    end
    if #b.emitters==0 then return end
    F.bursts[#F.bursts+1]=b
    if not F.ticking then
        F.ticking=true;Events.OnTick.Add(F.update);Events.OnPostRender.Add(F.render)
    end
end
function F.update()
    if #F.bursts==0 then stopIfEmpty();return end
    local t=getTimestampMs();local paused=isGamePaused()
    for i=#F.bursts,1,-1 do
        local b=F.bursts[i];local dt=math.max(0,t-b.last);b.last=t
        if not paused then b.age=b.age+dt end
        if b.age>=b.life or b.player:isDead() or not ProjectYakuza.isEquipped(b.player)
            or b.player:getModData().ProjectYakuzaHitEffectsDisabled then
            detach(b);table.remove(F.bursts,i)
        end
    end
    stopIfEmpty()
end
function F.render()
    F.update()
    if not F.color then F.color=ColorInfo.new(1,1,1,1);F.chargeColor=ColorInfo.new(.3,.7,1,1) end
    local tile=Core.getTileScale()
    for _,b in ipairs(F.bursts) do
        local v=b.victim;local t=b.age/b.life
        local alpha=math.min(1,(1-t)*1.1)
        for _,e in ipairs(b.emitters) do
            local growth=e.point.kind=="core" and (.65+.6*math.sin(t*math.pi)) or (1-.6*t)
            local scale=e.scale*growth
            e.instance:setScale(scale,scale)
            e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha)
            e.instance:render(v,v:getX(),v:getY(),v:getZ(),IsoDirections.N,
                v:getOffsetX()+tile-e.point.dx*t*tile,
                v:getOffsetY()-89*tile+e.point.size*(e.scale-scale)/2-e.point.dy*t*tile,b.charged and F.chargeColor or F.color)
        end
    end
end
ProjectYakuza.on("combatHit",F.onHit)
ProjectYakuza.on("tigerDrop",function(p,z)F.spawn(p,z,true)end)
ProjectYakuza.on("throwHit",function(p,z)F.spawn(p,z,true)end)
Events.OnGameStart.Add(function()F.clear()end)
Events.OnMainMenuEnter.Add(function()F.clear()end)
Events.OnSave.Add(function()F.clear()end)
