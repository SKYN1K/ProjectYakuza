require "ProjectYakuza/HeatRush"
require "ProjectYakuza/StyleUI"
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
    if p and not active then target,move=PY.HeatRush.weaponCandidate(p,PY.stateFor(p),style)end
    local desired=target and 1 or 0;local alpha=self.promptAlpha or 0
    if not isGamePaused()then
        if desired==1 then alpha=math.min(1,alpha+dt/120)else alpha=math.max(0,alpha-dt/80)end
    end
    self.promptAlpha=alpha
    if PY.StyleUI and PY.StyleUI.render("heatAction",p,self,{eligible=target~=nil,target=target,move=move,alpha=alpha,binding=PY.Bindings.label("heatAction")})then return end
    if alpha<=0 then return end
    if U.heatIcon==nil then U.heatIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatActionIconAtlas.png")or false end
    local x,y=self.width*.5,self.height*.67
    self:drawTextCentre(PY.Bindings.label("heatAction"),x,y-24,1,1,1,alpha,UIFont.Medium or UIFont.Small or UIFont.Large)
    if U.heatIcon then
        self:drawSubTexture(U.heatIcon,0,0,64,80,x-32,y,64,80,alpha*.35,.12,.42,1)
        self:drawSubTexture(U.heatIcon,64,0,64,80,x-32,y,64,80,alpha,1,1,1)
    end
end
function U:drawTimingRing(x,y,size,alpha,r,g,b)
    if U.qteIcon==nil then U.qteIcon=getTexture and getTexture("media/textures/ProjectYakuza/HeatRushQTEAtlas.png")or false end
    if not U.qteIcon or not SpriteRenderer or not SpriteRenderer.instance then return end
    local cx=(self:getAbsoluteX())+x;local cy=(self:getAbsoluteY())+y
    for _,rotation in ipairs(rotations)do
        local c,v=rotation[1],rotation[2]
        SpriteRenderer.instance:renderPoly(U.qteIcon,cx+(-c+v)*size,cy+(-v-c)*size,cx+v*size,cy-c*size,cx,cy,cx-c*size,cy-v*size,r,g,b,alpha)
    end
end
function U:render()
    local p=getSpecificPlayer(self.playerNum);local action=p and PY.HeatRush.active[p]
    self:renderEligibility(p,action)
    if not action then
        local style=p and PY.getPlayerStyle(p);local chain=p and PY.HeatRush.chains[p]
        if not style or not style.heatRush or not PY.Heat.isExtreme(p)or not p:isAiming()then return end
        local ticket=PY.HeatRush.tickets[p]
        if ticket and (ticket.sent or getTimestampMs()<=ticket.expires)then
            self:drawTextCentre("Heat Rush",self.width/2,self.height*.7,.7,.85,1,1,UIFont.Large)
        elseif chain and chain.count>0 and getTimestampMs()-chain.at<=1200 then
            self:drawTextCentre(PY.Bindings.label("light").."  "..chain.count.." / "..style.heatRush.hits,self.width/2,self.height*.7,.7,.85,1,1,UIFont.Large)
        end
        return
    end
    if not action.seen or not action.qte or action.qte.closed then return end
    local state=action.qte;local prompt=state.definition.prompts[state.index]
    if not prompt then return end
    local age=action.elapsed*1000;local untilHit=prompt.atMs-age
    if untilHit<0 or untilHit>math.max(prompt.windowMs,600)then return end
    local open=PY.QTE.window(state.definition,state.index,age)
    local alpha=state.accepted[state.index]and .55 or open and 1 or .6
    local x,y=self.width*.5,self.height*.7
    self:drawTimingRing(x,y,56,alpha,.35,.7,1)
    self:drawTimingRing(x,y,56+36*math.min(1,untilHit/math.max(600,prompt.windowMs)),alpha*.6,.75,.9,1)
    self:drawTextCentre(PY.Bindings.label(prompt.binding),x,y-12,.85,1,1,alpha,UIFont.Large)
    local labels={}
    for i,v in ipairs(state.definition.prompts)do
        labels[i]=(i==state.index and "["or "")..PY.Bindings.label(v.binding)..(i==state.index and "]"or "")
    end
    self:drawTextCentre(table.concat(labels,"  >  "),x,y+62,.85,1,1,.8,UIFont.Small or UIFont.Large)

end
function U.create()
    U.instances=U.instances or {}
    for i=0,getNumActivePlayers()-1 do
        if not U.instances[i]then
            local panel=U:new(getPlayerScreenLeft(i),getPlayerScreenTop(i),getPlayerScreenWidth(i),getPlayerScreenHeight(i));panel.playerNum=i;panel.background=false;panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager();U.instances[i]=panel
        end
    end
end
Events.OnGameStart.Add(U.create)
Events.OnCreatePlayer.Add(function()U.create()end)
