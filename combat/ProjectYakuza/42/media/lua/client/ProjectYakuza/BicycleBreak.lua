require "ProjectYakuza/Registry"
local E={parts={},seen=setmetatable({}, {__mode="k"}),maxParts=24,durationMs=1600};ProjectYakuza.BicycleBreak=E
function E.remove(part)
    if part.item:getWorldItem()==part.object then part.object:removeFromWorld();part.object:removeFromSquare()end
    local container=part.item:getContainer();if container then container:Remove(part.item)end
    part.item:setWorldItem(nil)
end
function E.clear()
    for _,part in ipairs(E.parts)do E.remove(part)end
    E.parts={};E.seen=setmetatable({}, {__mode="k"})
    if E.hooked then Events.OnTick.Remove(E.tick);E.hooked=false end
end
function E.start(p,key,seed,x,y,z)
    if E.seen[p]==key then return false end;E.seen[p]=key
    local world=getWorld();local sound=GameSounds.getSound("ProjectYakuza_BicycleBreak");local clip=sound and sound:getRandomClip()
    if world and clip then local emitter=world:getFreeEmitter(x,y,z);if emitter then local id=emitter:playClip(clip,p);if id and id~=0 then emitter:setVolume(id,.8)end end end
    local cell=getCell();local square=cell and cell:getGridSquare(math.floor(x),math.floor(y),math.floor(z));if not square then return true end
    for i,name in ipairs({"FrontWheel","RearWheel","Handlebars"})do
        if #E.parts<E.maxParts then
            local item=instanceItem("ProjectYakuza.Bicycle"..name)
            if item then
                square:AddWorldInventoryItem(item,x-square:getX(),y-square:getY(),.3,false,false)
                local object=item:getWorldItem()
                if object then
                    object:setNoPicking(true);local angle=(seed*47+i*137.5)%360;local radians=math.rad(angle)
                    E.parts[#E.parts+1]={item=item,object=object,x=x-square:getX(),y=y-square:getY(),height=.3,vx=math.cos(radians)*.32,vy=math.sin(radians)*.32,vz=.28+i*.035,angle=angle,age=0,last=getTimestampMs()}
                end
            end
        end
    end
    if #E.parts>0 and not E.hooked then Events.OnTick.Add(E.tick);E.hooked=true end
    return true
end
function E.remote(p,packet)
    if not packet.weaponBroken or not ProjectYakuza.NetworkProtocol.integer(packet.action,1,1000000000)then return end
    local serial=packet.session..":"..packet.action
    local last=E.seen[p]
    if type(last)=="table"and last.session==packet.session and last.action>=packet.action then return end
    E.start(p,serial,packet.action,p:getX(),p:getY(),p:getZ());E.seen[p]={session=packet.session,action=packet.action}
end
function E.tick()
    local time=getTimestampMs();local paused=isGamePaused()
    for i=#E.parts,1,-1 do
        local part=E.parts[i];local dt=math.min(.05,math.max(0,time-part.last)/1000);part.last=time
        if not paused then
            part.age=part.age+dt*1000;part.x=part.x+part.vx*dt;part.y=part.y+part.vy*dt;part.vz=part.vz-1.8*dt;part.height=part.height+part.vz*dt
            if part.height<.005 then part.height=.005;part.vz=math.abs(part.vz)*.22;part.vx=part.vx*.75;part.vy=part.vy*.75 end
            part.object:setOffX(part.x);part.object:setOffY(part.y);part.object:setOffZ(part.height);part.item:setWorldZRotation(part.angle+part.age*.3)
            if part.age>=E.durationMs then E.remove(part);table.remove(E.parts,i)end
        end
    end
    if #E.parts==0 and E.hooked then Events.OnTick.Remove(E.tick);E.hooked=false end
end
Events.OnSave.Add(E.clear)
Events.OnMainMenuEnter.Add(E.clear)
