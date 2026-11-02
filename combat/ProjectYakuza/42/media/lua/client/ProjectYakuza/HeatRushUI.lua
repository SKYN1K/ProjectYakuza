require "ProjectYakuza/HeatRush"
require "ProjectYakuza/StyleUI"
require "ISUI/ISPanel"
local PY=ProjectYakuza
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
    self:drawTextCentre(PY.Bindings.label("heatAction"),x,y-24,alpha,1,1,1,UIFont.Medium or UIFont.Small or UIFont.Large)
    if U.heatIcon then
        self:drawSubTexture(U.heatIcon,0,0,64,80,x-32,y,64,80,alpha*.35,.12,.42,1)
        self:drawSubTexture(U.heatIcon,64,0,64,80,x-32,y,64,80,alpha,1,1,1)
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
    if not prompt or not PY.QTE.window(state.definition,state.index,action.elapsed*1000)then return end
    local alpha=state.accepted[state.index]and .5 or 1
    local text=PY.Bindings.label(prompt.binding).."  "..state.index.." / "..#state.definition.prompts
    self:drawTextCentre(text,self.width/2,self.height*.7,alpha,.85,1,1,UIFont.Large)
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
