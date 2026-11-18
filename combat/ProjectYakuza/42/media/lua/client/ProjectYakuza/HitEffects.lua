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
local shock={kind="shock",path="media/textures/ProjectYakuza/EncounterShock.png",size=256,scale=.075,dx=0,dy=0}
local bluntParticles={{kind="bluntCore",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.22,dx=0,dy=0}}
for i=1,6 do local a=i*math.pi/3;bluntParticles[#bluntParticles+1]={kind="bluntSpark",path="media/textures/ProjectYakuza/ChargeSpark.png",size=32,scale=.19,dx=math.cos(a)*21,dy=math.sin(a)*15}end
local bladeParticles={
    {kind="bladeCore",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.10,dx=0,dy=0},
    {kind="bladeSpark",path="media/textures/ProjectYakuza/ChargeSpark.png",size=32,scale=.16,dx=-12,dy=-7},
    {kind="bladeSpark",path="media/textures/ProjectYakuza/ChargeSpark.png",size=32,scale=.13,dx=9,dy=6},
}
local guardParticles={
    {kind="guardCore",path="media/textures/ProjectYakuza/HitGlint.png",size=64,scale=.09,dx=0,dy=0},
}
for i=1,4 do local a=i*math.pi/2+.3;guardParticles[#guardParticles+1]={kind="guardSpark",path="media/textures/ProjectYakuza/ChargeSpark.png",size=32,scale=.16,dx=math.cos(a)*9,dy=math.sin(a)*7} end
local function noise()
    F.noiseState=((F.noiseState or (getTimestampMs()%2147483646+1))*48271)%2147483647
    return F.noiseState/2147483647
end
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
    local style=ProjectYakuza.getPlayerStyle(player)
    if style.hitEffects~="yakuza6" then return end
    if not s.active or not weapon or (not (ProjectYakuza.isStyleToken(weapon) or (ProjectYakuza.Weapons and ProjectYakuza.Weapons.matches(player,weapon)))
        and not (s.groundMove and weapon:getFullType()=="Base.BareHands")) then return end
    s.effectVictims=s.effectVictims or setmetatable({}, {__mode="k"})
    if s.effectVictims[victim] then return end
    s.effectVictims[victim]=true
    local move=s.groundMove or s.finisherMove
    local strong=(style.weaponProfile and s.finisherMove~=nil) or move and (move.neutralHeavy or move.double or move.afterLight or move.chargedHeavy) and not move.runningAttack and not move.quickstepAttack
    F.spawn(player,victim,strong,move and move.chargedHeavy)
end
function F.spawn(player,victim,strong,charged,guard,feedback,anchor)
    local style=ProjectYakuza.getPlayerStyle(player)
    if not style or style.hitEffects~="yakuza6" then return end
    if player:getModData().ProjectYakuzaHitEffectsDisabled then return end
    local contact
    if not guard and ProjectYakuza.AttackEffects and ProjectYakuza.AttackEffects.hit then contact=ProjectYakuza.AttackEffects.hit(player,victim,strong,charged,anchor)end
    local family=feedback;if family==nil then family=style.impactFeedback end
    if family~="blunt"and family~="blade"then family="unarmed"end
    if not guard and ProjectYakuza.BloodEffects then ProjectYakuza.BloodEffects.spawn(player,victim,strong,charged,family,anchor) end
    if contact then return end
    local count=0
    for _,b in ipairs(F.bursts) do if b.player==player then count=count+1 end end
    if count>=F.maxBursts or #F.bursts>=F.maxTotal then
        for i,b in ipairs(F.bursts) do
            if count<F.maxBursts or b.player==player then detach(b);table.remove(F.bursts,i);break end
        end
    end
    local tile=Core.getTileScale()
    local b={player=player,victim=victim,emitters={},last=getTimestampMs(),age=0,life=charged and 340 or strong and 280 or 240,strong=strong,charged=charged,guard=guard,family=family}
    if anchor then b.anchor={x=anchor.x,y=anchor.y,z=anchor.z}end
    if not guard and not charged and family=="blade"then b.life=strong and 240 or 180 end
    local selected=guard and guardParticles or charged and chargedParticles or family=="blunt"and bluntParticles or family=="blade"and bladeParticles or particles
    local points={};for _,point in ipairs(selected) do points[#points+1]=point end
    if (strong or charged)and family~="blade"then points[#points+1]=shock end
    if guard then
        b.life=180
        local dx,dy=victim:getX()-player:getX(),victim:getY()-player:getY()
        if b.victim==player then dx,dy=0,0 end
        local length=math.sqrt(dx*dx+dy*dy)
        if length>.001 then b.gx,b.gy=dx/length*.28,dy/length*.28 else b.gx,b.gy=0,0 end
        b.victim=player
    end
    local angle=noise()*math.pi*2;local cx,cy=(noise()-.5)*4,(noise()-.5)*4
    for _,template in ipairs(points) do
        local point={};for key,value in pairs(template)do point[key]=value end
        local turn=angle+(noise()-.5)*.7;local speed=.7+noise()*.85
        point.dx=(template.dx*math.cos(turn)-template.dy*math.sin(turn))*speed
        point.dy=(template.dx*math.sin(turn)+template.dy*math.cos(turn))*speed
        local slot=acquire(point)
        if slot then
            local scale=tile*point.scale*(strong and 1.15 or 1)*(.88+noise()*.24)
            local instance=ProjectYakuza.WorldEffects.detached(slot.sprite,scale,0)
            instance:SetAlpha(1);instance:SetTargetAlpha(1)
            b.emitters[#b.emitters+1]={slot=slot,instance=instance,point=point,scale=scale,cx=cx+(noise()-.5)*2,cy=cy+(noise()-.5)*2,life=.78+noise()*.22,curve=(noise()-.5)*12,gravity=8+noise()*13}
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
function F.draw()
    F.update()
    if not F.color then F.color=ColorInfo.new(1,1,1,1);F.chargeColor=ColorInfo.new(.6,.78,1,1);F.guardColor=ColorInfo.new(.8,.9,1,1);F.bluntColor=ColorInfo.new(1,.82,.60,1);F.bladeColor=ColorInfo.new(.88,.94,1,1) end
    local tile=Core.getTileScale()
    for _,b in ipairs(F.bursts) do
        local v=b.victim;local t=b.age/b.life
        local alpha=math.min(1,(1-t)*1.1)
        local grounded=v:isOnFloor()or v.GetVariable and v:GetVariable("ProjectYakuzaPairedVictimClip")=="ProjectYakuza_DD_GroundHeatVictim"
        local height=(grounded and 6 or 35)*tile
        local wx,wy=b.gx or 0,b.gy or 0
        local bx,by=(wx-wy)*32*tile,(wx+wy)*16*tile
        for _,e in ipairs(b.emitters) do
            local ring=e.point.kind=="shock"
            local u=math.min(1,t/e.life);local spark=e.point.dx~=0 or e.point.dy~=0
            local dx=e.cx+e.point.dx*u+(spark and e.curve*u*u or 0)
            local dy=e.cy+e.point.dy*u+(spark and e.gravity*u*u or -2*u)
            local opacity=alpha*math.max(0,1-u*u)
            local growth=ring and (.65+.8*t) or (e.point.kind=="core"or e.point.kind=="bluntCore") and (.65+.6*math.sin(t*math.pi)) or (1-.6*t)
            local scale=e.scale*growth
            e.instance:setScale(scale,scale)
            e.instance:SetAlpha(opacity*(ring and .13 or b.guard and .65 or 1));e.instance:SetTargetAlpha(opacity*(ring and .13 or b.guard and .65 or 1))
            if b.anchor then
                e.instance:render(v,b.anchor.x,b.anchor.y,b.anchor.z,IsoDirections.N,-dx*tile,-dy*tile-e.point.size*scale/2,b.charged and F.chargeColor or b.family=="blunt"and F.bluntColor or b.family=="blade"and F.bladeColor or F.color)
            else ProjectYakuza.WorldEffects.renderCentered(v,e.instance,e.point.size,scale,
                bx+dx*tile,by-height+dy*tile,b.guard and F.guardColor or b.charged and F.chargeColor or b.family=="blunt"and F.bluntColor or b.family=="blade"and F.bladeColor or F.color,wx,wy,height/(96*tile))
            end
        end
    end
end
function F.render()
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,err=pcall(F.draw);renderer:setDoAdditive(previous)
    if not ok then F.clear();error(err) end
end
function F.guard(p,z)
    if not p or not z or not ProjectYakuza.isEquipped(p) then return end
    F.spawn(p,z,false,false,true)
end
ProjectYakuza.on("combatHit",F.onHit)
ProjectYakuza.on("guardHit",F.guard)
ProjectYakuza.on("tigerDrop",function(p,z)F.spawn(p,z,true)end)
ProjectYakuza.on("throwHit",function(p,z)F.spawn(p,z,true)end)
Events.OnGameStart.Add(function()F.clear()end)
Events.OnMainMenuEnter.Add(function()F.clear()end)
Events.OnSave.Add(function()F.clear()end)
