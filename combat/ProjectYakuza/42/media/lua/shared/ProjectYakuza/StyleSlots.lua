require "ProjectYakuza/Registry"
local ProjectYakuza=ProjectYakuza
local S={}
ProjectYakuza.StyleSlots=S
function S.get(player)
    local data=player:getModData()
    if type(data.ProjectYakuzaStyleSlots)~="table" then
        data.ProjectYakuzaStyleSlots={version=1,left="dragon_of_dojima"}
    end
    return data.ProjectYakuzaStyleSlots
end
function S.id(player,side)
    if side~="left" and side~="right" then return nil end
    local id=S.get(player)[side]
    return type(id)=="string" and ProjectYakuza.getStyle(id) and id or nil
end
function S.assign(player,side,id)
    if side~="left" and side~="right" then return false,"invalid_slot" end
    if id~=nil and not ProjectYakuza.getStyle(id) then return false,"unknown_style" end
    S.get(player)[side]=id
    ProjectYakuza.emit("styleSlotChanged",player,side,id)
    return true
end
function S.direction(x,y,deadzone)
    if x*x+y*y<(deadzone or 22)^2 then return nil end
    if math.abs(x)>math.abs(y) then return x<0 and "left" or "right" end
    return y<0 and "top" or "bottom"
end
