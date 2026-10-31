require "ProjectYakuza/HeatRush"
require "ISUI/ISPanel"
local PY=ProjectYakuza
local U=ISPanel:derive("ProjectYakuzaHeatRushPrompt");PY.HeatRushUI=U
function U:render()
    local p=getSpecificPlayer(self.playerNum);local action=p and PY.HeatRush.active[p]
    if not action or not action.seen or not action.qte or action.qte.closed then return end
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
