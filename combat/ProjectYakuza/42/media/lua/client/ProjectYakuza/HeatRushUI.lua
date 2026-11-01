require "ProjectYakuza/HeatRush"
require "ISUI/ISPanel"
local PY=ProjectYakuza
local U=ISPanel:derive("ProjectYakuzaHeatRushPrompt");PY.HeatRushUI=U
function U:onMouseDown()return false end
function U:onMouseUp()return false end
function U:onMouseMove()return false end
function U:onRightMouseDown()return false end
function U:onRightMouseUp()return false end
function U:render()
    local p=getSpecificPlayer(self.playerNum);local action=p and PY.HeatRush.active[p]
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
