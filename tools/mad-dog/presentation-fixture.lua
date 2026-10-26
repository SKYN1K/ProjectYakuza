local loaded={}
require=function(name)
    if loaded[name] then return loaded[name] end
    loaded[name]=true
    if modules[name] then loaded[name]=modules[name]() or true end
    return loaded[name]
end
local checks=0
local function check(v,msg)checks=checks+1;if not v then error(msg)end end
local function empty(t)for _ in pairs(t)do return false end;return true end
local clock,paused=10000,false
getTimestampMs=function()return clock end
isGamePaused=function()return paused end
isClient=function()return false end
instanceof=function(_,class)return class=="IsoPlayer"end
local function event()
    local handlers={}
    return {Add=function(fn)handlers[fn]=true end,Remove=function(fn)handlers[fn]=nil end,
        fire=function(...)local copy={};for fn in pairs(handlers)do copy[#copy+1]=fn end;for _,fn in ipairs(copy)do fn(...)end end}
end
Events=setmetatable({}, {__index=function(t,k)local e=event();rawset(t,k,e);return e end})
local Panel={}
function Panel:derive()local c={};c.__index=c;setmetatable(c,{__index=self});return c end
function Panel:new(x,y,w,h)return setmetatable({x=x,y=y,width=w,height=h,draws={}},self)end
function Panel:initialise()end
function Panel:setX(v)self.x=v end
function Panel:setY(v)self.y=v end
function Panel:setWantMouseEvents(v)self.mouseEvents=v end
function Panel:addToUIManager()self.added=true end
function Panel:removeFromUIManager()self.added=false end
function Panel:drawTextureScaled(texture,...)self.draws[#self.draws+1]={kind="texture",path=texture.path,args={...}}end
function Panel:drawSubTexture(texture,...)self.draws[#self.draws+1]={kind="sub",path=texture.path,args={...}}end
function Panel:drawRect(...)self.draws[#self.draws+1]={kind="fill",args={...}}end
function Panel:drawRectBorder(...)self.draws[#self.draws+1]={kind="border",args={...}}end
function Panel:drawText(text,...)self.draws[#self.draws+1]={kind="text",text=text,args={...}}end
ISPanel=Panel;UIFont={Small="Small"}
getTexture=function(path)return {path=path}end
getPlayerScreenLeft=function(index)return index*800 end
getPlayerScreenTop=function()return 0 end
Core={getTileScale=function()return 2 end};IsoDirections={N="N"}
ColorInfo={new=function(r,g,b,a)return {r=r,g=g,b=b,a=a}end}
local additive=false
SpriteRenderer={instance={getDoAdditive=function()return additive end,setDoAdditive=function(_,v)additive=v end}}
local instances={};local loads=0
local function instance(sprite)
    local i={sprite=sprite,updates=0,draws=0}
    function i:setScale(x,y)self.scale=x;self.scaleY=y end
    function i:setFrameSpeedPerFrame(v)self.speed=v end
    function i:SetAlpha(v)self.alpha=v end
    function i:SetTargetAlpha(v)self.targetAlpha=v end
    function i:getParentSprite()return self.sprite end
    function i:Dispose()check(not self.disposed,"no double disposal");self.disposed=true end
    function i:render(...)check(not self.disposed,"disposed instance cannot render");self.draws=self.draws+1 end
    instances[#instances+1]=i;return i
end
IsoSprite={CreateSprite=function()
    local s={}
    function s:LoadFramesNoDirPageDirect(prefix,kind,count)self.path=prefix..kind;self.count=count;loads=loads+1 end
    function s:setAnimate(v)self.animated=v end
    function s:update(i)i.updates=i.updates+1 end
    return s
end}
IsoSpriteInstance={add=function(i)check(i.disposed and not i.pooled,"pool only owned disposed instance once");i.pooled=true end}
require "ProjectYakuza/Registry"
local P=ProjectYakuza
require "ProjectYakuza/Styles/DragonOfDojima"
require "ProjectYakuzaMadDog/Style"
local md="project_yakuza.mad_dog_of_shimano"
local function player(index,id,heat)
    local p={index=index,data={ProjectYakuzaStyle=id,ProjectYakuzaHeat=heat},attached={},localPlayer=true}
    function p:getModData()return self.data end
    function p:getPrimaryHandItem()return {getFullType=function()return P.TOKEN end}end
    function p:isLocalPlayer()return self.localPlayer end
    function p:isDead()return self.dead==true end
    function p:getVehicle()return self.vehicle end
    function p:getOffsetX()return 0 end
    function p:getOffsetY()return 0 end
    function p:getX()return 10 end
    function p:getY()return 12 end
    function p:getZ()return 0 end
    function p:getPlayerNum()return self.index end
    function p:getAttachedAnimSprite()
        local t=self.attached
        return {size=function()return #t end,get=function(_,i)return t[i+1]end,
            remove=function(_,i)for n=#t,1,-1 do if t[n]==i then table.remove(t,n);return end end end}
    end
    function p:AttachExistingAnim(sprite)self.attached[#self.attached+1]=instance(sprite)end
    return p
end
local p=player(0,md,50);local kiryu=player(1,"dragon_of_dojima",50)
local players={[0]=p,[1]=kiryu}
getSpecificPlayer=function(index)return players[index]end
P.Bindings={label=function()return "N"end}
P.Heat={config={maxStocks=6},enabled=function(who)local s=P.getPlayerStyle(who);return s and s.heat end,
    stocks=function(who)return math.floor((who.data.ProjectYakuzaHeat or 0)*6/100+.000001)end,
    display=function(who)return who.extreme and who.fuel or who.data.ProjectYakuzaHeat end,
    isExtreme=function(who)return who.extreme==true end}
require "ProjectYakuza/WorldEffects"
require "ProjectYakuza/HeatUI"
require "ProjectYakuza/HeatAura"
local originalHUD,originalAura=P.HeatUI,P.HeatAura
require "ProjectYakuzaMadDog/HUD"
require "ProjectYakuzaMadDog/Aura"
local H,A=P.MadDogHUD,P.MadDogAura
check(P.HeatUI==originalHUD and P.HeatAura==originalAura,"framework HUD/aura objects not overwritten")
check(P.getStyle("dragon_of_dojima").heatHud=="yakuza6" and P.getStyle("dragon_of_dojima").heatAura=="kiryu","Kiryu profile unchanged")
check(P.getStyle(md).heatHud=="mad_dog_y0" and P.getStyle(md).heatAura=="mad_dog_y0","Mad Dog owns separate profiles")
check(P.getStyle(md).selectorIcon=="media/textures/ProjectYakuzaMadDog/LegendIcon.png","selector uses original Mad Dog image")
Events.OnGameStart.fire()
local panel=H.panels[0];check(panel and panel.mouseEvents==false,"HUD exists with mouse pass-through")
H.panels[1]:prerender();check(#H.panels[1].draws==0,"custom HUD hidden for Kiryu split-screen player")
panel:prerender();check(#panel.draws>0,"Mad Dog HUD renders")
for _,d in ipairs(panel.draws)do if d.path then check(string.find(d.path,"ProjectYakuzaMadDog",1,true),"HUD uses only addon texture names") end end
check(panel.visualHeat==50 and panel.x==16,"HUD follows heat and player viewport")
local basePanel=originalHUD.instance;basePanel.draws={};basePanel:prerender()
check(#basePanel.draws==0,"original heat HUD does not double-render over Mad Dog")
originalAura.update(kiryu);local baseState=originalAura.states[kiryu]
check(baseState and #baseState.emitters==4,"Kiryu still gets original four emitters")
check(not A.states[kiryu] and not originalAura.states[p],"world aura profiles remain style-local")
local state=A.states[p];check(state and #state.emitters==4,"Mad Dog gets independent torso emitters")
check(#p.attached==0 and #kiryu.attached==0,"aura instances render through one world path")
for _,e in ipairs(state.emitters)do check(string.find(e.sprite.path,"ProjectYakuzaMadDog",1,true),"Mad Dog aura uses supplied addon sprites")end
clock=clock+200;A.render();clock=clock+200;A.render();check(state.fade==350,"aura fade completes")
local spark=state.emitters[2].instance;local before=spark.updates
paused=true;clock=clock+1000;A.render();check(spark.updates==before and state.fade==350,"pause freezes aura animation")
paused=false;clock=clock+16;A.render();check(spark.updates==before+1,"one frame advance per render")
check(additive==false,"custom aura does not change global blend mode")
p.extreme=true;p.fuel=80;A.update(p);clock=clock+16;A.render()
check(state.extreme and #state.emitters==4,"Extreme Heat changes own profile without stacking another aura")
check(originalAura.states[kiryu]==baseState,"Mad Dog mode leaves Kiryu aura state untouched")
panel.draws={};clock=clock+100;panel:prerender();check(panel.extreme and panel.heat==80,"custom HUD displays Extreme Heat fuel")
p.extreme=false;p.data.ProjectYakuzaHeat=0;A.update(p);check(not A.states[p],"zero heat releases own instances")
local oldHeat=p.data.ProjectYakuzaHeat;A.flash(p)
check(A.states[p] and p.data.ProjectYakuzaHeat==oldHeat,"zero-heat completion flash changes no heat resource")
clock=clock+250;A.render();clock=clock+16;A.render();check(not A.states[p],"completion flash expires without leaking instances")
p.data.ProjectYakuzaHeat=50;A.update(p);state=A.states[p]
p.data.ProjectYakuzaHeatAuraDisabled=true;A.update(p);check(not A.states[p],"existing framework aura toggle hides custom aura")
p.data.ProjectYakuzaHeatAuraDisabled=nil;A.update(p)
local owned={};for _,e in ipairs(A.states[p].emitters)do owned[#owned+1]=e.instance end
check(P.selectStyle(p,"dragon_of_dojima"),"switching to Kiryu accepted")
check(not A.states[p] and originalAura.states[p],"style change swaps aura owners")
for _,i in ipairs(owned)do check(i.disposed and i.pooled,"old Mad Dog instances cleaned on style change")end
for _,e in ipairs(baseState.emitters)do check(not e.instance.disposed,"other player's Kiryu instances remain alive")end
panel.draws={};panel:prerender();check(#panel.draws==0,"Mad Dog HUD stops drawing on style switch")
basePanel.draws={};basePanel:prerender();check(#basePanel.draws>0,"Kiryu original HUD returns normally")
check(P.selectStyle(p,md),"switching back to Mad Dog accepted")
panel:prerender();check(panel.wasActive and panel.visualHeat==50,"custom HUD resumes without stale other-style heat")
-- Remote actors are read from existing network presentation state; no handler is replaced.
local remote=player(2,md,50);remote.localPlayer=false
local apply=function()end
P.Network={remote={[42]={actor=remote,packet={taunt=1}}},applyState=apply,remoteEquipped=function()return true end}
clock=clock+300;A.poll();check(A.states[remote]~=nil and P.Network.applyState==apply,"remote aura discovery leaves network handlers intact")
remote.data.ProjectYakuzaHeat=0;A.update(remote);check(not A.states[remote],"remote has no idle aura at zero heat")
P.Network.remote[42].packet.taunt=2;clock=clock+300;A.poll();check(A.states[remote]~=nil,"remote completed taunt flashes at zero heat")
P.Network.remote={};clock=clock+300;A.poll();check(not A.states[remote],"disconnected observer instances cleaned")
p.dead=true;A.render();check(not A.states[p],"death removes custom aura")
p.dead=false;A.update(p);Events.OnSave.fire();check(empty(A.states),"save clears world instances")
Events.OnMainMenuEnter.fire();check(not A.running and empty(H.panels),"menu exit removes private HUD and disables polling")
clock=clock+500;A.poll();check(empty(A.states),"menu polling cannot resurrect old world instances")
return "PASS "..checks.." presentation lifecycle, original-HUD isolation, split-screen, pause, observer and cleanup checks"
