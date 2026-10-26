require "ProjectYakuza/Registry"
local W={}
ProjectYakuza.WorldEffects=W
-- B42 character rendering passes (offsetX + tileScale, offsetY - 89*tileScale).
-- IsoSprite additionally anchors moving-object textures at bottom centre.
-- Frame centre is therefore (0, -frameHeight*scale/2) before our offsets.
function W.attach(character,sprite,frameHeight,scale,height,loop,speed,horizontal)
    local tile=Core.getTileScale()
    local x=-character:getOffsetX()-tile-(horizontal or 0)
    local y=89*tile+height-character:getOffsetY()-frameHeight*scale/2
    character:AttachExistingAnim(sprite,math.floor(x+0.5),math.floor(y+0.5),loop,0,false,0)
    local list=character:getAttachedAnimSprite()
    local instance=list:get(list:size()-1)
    instance:setScale(scale,scale)
    instance:setFrameSpeedPerFrame(speed)
    return instance
end
function W.contains(character,instance,sprite)
    local list=character:getAttachedAnimSprite()
    if not list then return false end
    for i=list:size()-1,0,-1 do
        if list:get(i)==instance and instance:getParentSprite()==sprite then return true end
    end
    return false
end
function W.remove(character,instance,sprite)
    local list=character:getAttachedAnimSprite()
    if not list then return end
    for i=list:size()-1,0,-1 do
        if list:get(i)==instance and instance:getParentSprite()==sprite then
            character:RemoveAttachedAnim(i);return
        end
    end
end
