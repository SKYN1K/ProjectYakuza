require "ProjectYakuza/Registry"
local W={}
ProjectYakuza.WorldEffects=W

function W.detached(sprite,scale,speed)
    local instance=IsoSpriteInstance.get(sprite)
    instance:setScale(scale,scale);instance:setFrameSpeedPerFrame(speed or 0)
    return instance
end
function W.renderCentered(character,instance,frameHeight,scale,x,y,color,anchorX,anchorY,anchorZ)

    anchorX,anchorY,anchorZ=anchorX or 0,anchorY or 0,anchorZ or 0
    local tile=Core.getTileScale()
    local sx=(anchorX-anchorY)*32*tile
    local sy=(anchorX+anchorY)*16*tile-anchorZ*96*tile

    instance:render(character,character:getX()+anchorX,character:getY()+anchorY,character:getZ()+anchorZ,IsoDirections.N,
        sx-x,sy-y-frameHeight*scale/2,color)
end

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
