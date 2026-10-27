require "ProjectYakuza/Registry"
local O={states=setmetatable({}, {__mode="k"})}
ProjectYakuza.HeatOutline=O
local function rgba(value)
    if value<0 then value=value+4294967296 end
    return (value%256)/255,(math.floor(value/256)%256)/255,
        (math.floor(value/65536)%256)/255,(math.floor(value/16777216)%256)/255
end
function O.clear(p)
    local s=O.states[p];if not s then return end
    if s.owned and p:getOutlineHighlightCol(s.index)==s.color then
        local r,g,b,a=rgba(s.previousColor)
        p:setOutlineHighlightCol(s.index,r,g,b,a);p:setOutlineHighlight(s.index,s.previousFlag)
    end
    O.states[p]=nil
end
function O.update(p,wanted)
    if not wanted then O.clear(p);return end
    if O.states[p] then return end
    local index=getPlayer and getPlayer() and getPlayer():getPlayerNum() or 0
    local s={index=index,previousFlag=p:isOutlineHighlight(index),previousColor=p:getOutlineHighlightCol(index)}
    O.states[p]=s
    -- Preserve target highlighting owned by the base game or another addon.
    if s.previousFlag then return end
    p:setOutlineHighlightCol(index,.32,.22,.95,.42)
    s.color=p:getOutlineHighlightCol(index);s.owned=true
end
function O.draw(p)
    local s=O.states[p];if not s or not s.owned then return end
    if p:getOutlineHighlightCol(s.index)~=s.color then s.owned=false;return end
    p:setOutlineHighlight(s.index,true)
end
function O.clearAll()
    local players={};for p in pairs(O.states) do players[#players+1]=p end
    for _,p in ipairs(players) do O.clear(p) end
end
Events.OnSave.Add(O.clearAll)
Events.OnMainMenuEnter.Add(O.clearAll)
