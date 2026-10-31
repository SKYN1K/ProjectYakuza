require "ProjectYakuza/Registry"
local D={}
ProjectYakuza.DirectionalAttacks=D
local function unit(x,y)
    if type(x)~="number"or type(y)~="number"or x~=x or y~=y then return end
    local length=math.sqrt(x*x+y*y);if length<.001 or length==math.huge then return end
    return x/length,y/length
end
function D.direction(fx,fy,dx,dy,minimum,rear)
    minimum=minimum or 65;rear=rear or 145
    if type(minimum)~="number"or type(rear)~="number"or minimum~=minimum or rear~=rear or minimum<30 or rear<=minimum or rear>180 then return end
    fx,fy=unit(fx,fy);dx,dy=unit(dx,dy);if not fx or not dx then return end
    local dot=math.max(-1,math.min(1,fx*dx+fy*dy))
    if dot>math.cos(minimum*math.pi/180)then return end
    if dot<=math.cos(rear*math.pi/180)then return "rear"end
    return fx*dy-fy*dx>=0 and "right"or"left"
end
function D.select(p,s,style)
    local cfg=style and style.directionalAttacks;local previous=s.lightFacing
    if not cfg or style.weaponProfile or not previous or s.step<1 or s.directionalLight or s.finisherMove or s.groundMove or not p:isAiming()or p:isAimAtFloor()then return end
    if not s.active and not s.starting and (not s.finishedAt or getTimestampMs()-s.finishedAt>style.comboResetMs)then return end
    local facing=p:getForwardDirection();local direction=D.direction(previous.x,previous.y,facing:getX(),facing:getY(),cfg.minimumDegrees,cfg.rearDegrees)
    return direction and cfg.moves[direction]or nil
end
function D.record(p,s,move)
    local f=p:getForwardDirection();local x,y=unit(f:getX(),f:getY())
    s.lightFacing=x and {x=x,y=y}or nil;s.directionalLight=move.directional==true
end
