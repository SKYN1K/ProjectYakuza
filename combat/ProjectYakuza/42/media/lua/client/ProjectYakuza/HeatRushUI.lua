require "ProjectYakuza/HeatRush"
require "ProjectYakuza/GrabCombat"
require "ProjectYakuza/StyleUI"
require "ProjectYakuza/InputPrompts"
require "ISUI/ISPanel"
local PY=ProjectYakuza
local rotations={{1,0},{0,1},{-1,0},{0,-1}}
local U=ISPanel:derive("ProjectYakuzaHeatRushPrompt");PY.HeatRushUI=U
function U:onMouseDown()return false end
function U:onMouseUp()return false end
function U:onMouseMove()return false end
function U:onRightMouseDown()return false end
function U:onRightMouseUp()return false end
function U:renderEligibility(p,active)
    local t=getTimestampMs();local dt=math.max(0,math.min(100,t-(self.promptAt or t)));self.promptAt=t
    local style=p and PY.getPlayerStyle(p);local target,move
    if p and not active then target,move=PY.GrabCombat.candidate(p)
        if not target then target,move=PY.HeatRush.weaponCandidate(p,PY.stateFor(p),style)end end
    local desired=target and 1 or 0;local alpha=self.promptAlpha or 0
    if not isGamePaused()then
        if desired==1 then alpha=math.min(1,alpha+dt/120)else alpha=math.max(0,alpha-dt/80)end
    end
    self.promptAlpha=alpha
    if PY.StyleUI and PY.StyleUI.render("heatAction",p,self,{eligible=target~=nil,target=target,move=move,alpha=alpha,binding=PY.Bindings.label("heatAction"),inputPrompt=PY.InputPrompts.describe("heatAction")})then return end
    if alpha<=0 then return end
    if U.heatIcon==nil then U.heatIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatActionIconAtlas.png")or false end
    local x,y=self.width*.5,self.height*.67
    PY.InputPrompts.draw(self,"heatAction",x,y-32,44,alpha)
    if U.heatIcon then
        self:drawSubTexture(U.heatIcon,0,0,64,80,x-32,y,64,80,alpha*.35,.12,.42,1)
        self:drawSubTexture(U.heatIcon,64,0,64,80,x-32,y,64,80,alpha,1,1,1)
    end
end
function U:drawTimingRing(x,y,size,alpha,r,g,b,angle)
    if U.qteIcon==nil then U.qteIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatRushQTEAtlas.png")or false end
    if not U.qteIcon or not SpriteRenderer or not SpriteRenderer.instance then return end
    local cx=(self:getAbsoluteX())+x;local cy=(self:getAbsoluteY())+y
    for _,rotation in ipairs(rotations)do
        local a,b=math.cos(angle or 0),math.sin(angle or 0)
        local c,v=rotation[1]*a-rotation[2]*b,rotation[1]*b+rotation[2]*a
        SpriteRenderer.instance:renderPoly(U.qteIcon,cx+(-c+v)*size,cy+(-v-c)*size,cx+v*size,cy-c*size,cx,cy,cx-c*size,cy-v*size,r,g,b,alpha)
    end
end
function U:drawRadialTimer(x,y,size,fraction,alpha,r,g,b)
    if U.qteIcon==nil then U.qteIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatRushQTEAtlas.png")or false end
    if not U.qteIcon or not SpriteRenderer or not SpriteRenderer.instance then return end
    local cx,cy=self:getAbsoluteX()+x,self:getAbsoluteY()+y
    local segments=48;local count=math.max(0,math.min(1,fraction))*segments
    for i=0,math.ceil(count)-1 do
        local q=math.floor(i/12);local start=-math.pi+(i%12)/12*math.pi*.5;local finish=start+math.min(1,count-i)/12*math.pi*.5
        local u1,v1=1+math.cos(start),1+math.sin(start);local u2,v2=1+math.cos(finish),1+math.sin(finish)
        local angle=(q+1)*math.pi*.5;local c,s=math.cos(angle),math.sin(angle)
        local x1,y1=(u1-1)*size,(v1-1)*size;local x2,y2=(u2-1)*size,(v2-1)*size
        SpriteRenderer.instance:renderPoly(U.qteIcon,cx,cy,cx+x1*c-y1*s,cy+x1*s+y1*c,cx+x2*c-y2*s,cy+x2*s+y2*c,cx,cy,r,g,b,alpha,1,1,u1,v1,u2,v2,1,1)
    end
end
function U:render()
    local p=getSpecificPlayer(self.playerNum);local action=p and PY.HeatRush.active[p]
    self:renderEligibility(p,action)
    if not action then return end
    if not action.seen or not action.qte or action.qte.closed then return end
    local state=action.qte;local index=state.definition.allowOverlap and (PY.QTE.promptIndex(state)or #state.definition.prompts)or state.index;local prompt=state.definition.prompts[index]
    if not prompt then return end
    local age=PY.HeatRushRules.time(action.context and action.context.action,action.elapsed)*1000;local untilHit=prompt.atMs-age
    if untilHit<0 or untilHit>prompt.windowMs then return end
    local alpha=state.accepted[index]and .8 or 1
    local x,y=self.width*.5,self.height*.7
    local remaining=math.max(0,math.min(1,untilHit/prompt.windowMs))
    local appear=math.min(1,(prompt.windowMs-untilHit)/60)
    local accepted=state.lastInputAt or state.inputAt[index]
    local flash=accepted and math.max(0,1-(age-accepted)/180)or 0
    self:drawTimingRing(x,y,60,.18*appear,.15,.35,1,0)
    self:drawRadialTimer(x,y,60,remaining,appear,.15+.4*flash,.65+.3*flash,1)
    PY.InputPrompts.draw(self,prompt.binding,x,y,64,alpha*appear)
    if prompt.presses then self:drawTextCentre(tostring(state.pressCounts[index]or 0).." / "..tostring(prompt.presses),x,y+48,1,1,1,alpha*appear,UIFont.Medium)end

end
function U.create()
    U.instances=U.instances or {}
    for i=0,getNumActivePlayers()-1 do
        if not U.instances[i]then
            local panel=U:new(getPlayerScreenLeft(i),getPlayerScreenTop(i),getPlayerScreenWidth(i),getPlayerScreenHeight(i));panel.playerNum=i;panel.background=false;PY.StyleUI.renderOnly(panel);panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager();U.instances[i]=panel
        end
    end
end
Events.OnGameStart.Add(U.create)
Events.OnCreatePlayer.Add(function()U.create()end)
