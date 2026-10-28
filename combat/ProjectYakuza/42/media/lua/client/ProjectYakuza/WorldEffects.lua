require "ProjectYakuza/Registry"
local W={}
ProjectYakuza.WorldEffects=W
-- Detached effects must use sprites that never pass through AttachExistingAnim.
-- That engine method changes offsets on the shared sprite, not on its instance.
function W.detached(sprite,scale,speed)
    local instance=IsoSpriteInstance.get(sprite)
    instance:setScale(scale,scale);instance:setFrameSpeedPerFrame(speed or 0)
    return instance
end
function W.renderCentered(character,instance,frameHeight,scale,x,y,color)
    -- Native moving-object sprites anchor bottom-centre. Cancel half the height
    -- explicitly per instance, leaving the shared sprite's default offsets at zero.
    instance:render(character,character:getX(),character:getY(),character:getZ(),IsoDirections.N,
        -x,-y-frameHeight*scale/2,color)
end
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
