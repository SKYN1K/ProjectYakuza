require "ProjectYakuza/Registry"
local PY=ProjectYakuza
local F={leadMs=120,tintAlpha=.36,shakePixels=12,tailMs=420,tailStrengthMs=200}
PY.HeatScreenEffects=F
function F.restoreCamera()
    local camera=F.camera;if not camera then return end
    if math.abs(IsoCamera.getOffX()-camera.x)<.01 then IsoCamera.setOffX(camera.baseX-camera.rightX)end
    if math.abs(IsoCamera.getOffY()-camera.y)<.01 then IsoCamera.setOffY(camera.baseY-camera.rightY)end
    if math.abs(IsoCamera.getLastOffX()-camera.lastX)<.01 then IsoCamera.setLastOffX(camera.baseLastX)end
    if math.abs(IsoCamera.getLastOffY()-camera.lastY)<.01 then IsoCamera.setLastOffY(camera.baseLastY)end
    F.camera=nil
end
function F.stop()
    F.restoreCamera();F.state=nil
    if F.hooked then
        Events.OnTick.Remove(F.update);Events.OnPreUIDraw.Remove(F.draw);Events.OnRenderTick.Remove(F.restoreCamera);F.hooked=false
    end
end
function F.allowed(p)
    local style=p and PY.getPlayerStyle(p)
    return p and p:isLocalPlayer()and p:getPlayerNum()==0 and not p:isDead()and PY.isEquipped(p)
        and style and style.hitEffects=="yakuza6"and not p:getModData().ProjectYakuzaHitEffectsDisabled
        and(not getNumActivePlayers or getNumActivePlayers()==1)and not isGamePaused()
        and not(ISWorldMap_instance and ISWorldMap_instance:isVisible())and not(PY.StyleSelector and PY.StyleSelector.setup)
end
function F.begin(p,z,index,contact,remaining)
    if not F.allowed(p)or not z or not contact or contact.bloodOnly then return end
    local presentation=PY.HeatActionPresentation
    if not presentation or not presentation.states[p]then return end
    local strength=contact.sumQTE and 1 or contact.charged and .8 or contact.strong~=false and .65 or .35
    local time=getTimestampMs();local tail=F.tailMs+strength*F.tailStrengthMs
    local previous,envelope=F.sample();local carry=previous and math.min(1,previous.strength*envelope/strength)or 0
    F.state={p=p,source=presentation.states[p].source,index=index,at=time,hitAt=time+remaining,lead=remaining,tail=tail,life=remaining+tail,strength=strength,carry=carry,confirmed=remaining==0,seed=(index or 1)*1.73+time*.01}
    if not F.hooked then
        Events.OnTick.Add(F.update);Events.OnPreUIDraw.Add(F.draw);Events.OnRenderTick.Add(F.restoreCamera);F.hooked=true
    end
    return true
end
function F.prepare(p,z,index,contact,remaining)
    if type(remaining)~="number"or remaining<0 or remaining>F.leadMs then return false end
    local source=PY.HeatActionPresentation and PY.HeatActionPresentation.states[p]
    if F.state and F.state.p==p and F.state.index==index and source and F.state.source==source.source then
        if not F.state.confirmed then F.state.hitAt=getTimestampMs()+remaining end
        return true
    end
    return F.begin(p,z,index,contact,remaining)
end
function F.hit(p,z,index,contact)
    if not F.allowed(p)or not z or not contact or contact.bloodOnly then return end
    local state=F.state;local source=PY.HeatActionPresentation and PY.HeatActionPresentation.states[p]
    if state and not state.confirmed and state.p==p and state.index==index and source and state.source==source.source then
        state.hitAt=getTimestampMs();state.confirmed=true;state.life=state.hitAt-state.at+state.tail;return
    end
    F.begin(p,z,index,contact,0)
end
function F.cancel(p,source)
    if F.state and F.state.p==p and F.state.source==source and not F.state.confirmed then F.stop()end
end
function F.sample()
    local state=F.state;if not state or not F.allowed(state.p)then return end
    local age=math.max(0,getTimestampMs()-state.at)
    local since=getTimestampMs()-state.hitAt
    if since>=state.tail then return end
    local progress=math.max(0,math.min(1,1+since/math.max(1,state.lead)))
    local envelope=not state.confirmed and math.max(.55*progress^2,state.carry*(1-progress))or(1-since/state.tail)^1.3
    return state,envelope,age
end
function F.update()
    F.restoreCamera()
    local state,envelope,age=F.sample();if not state then F.stop();return end
    local amplitude=state.strength*F.shakePixels*envelope*getCore():getZoom(0)
    local x=math.floor(math.sin(age*.13+state.seed)*amplitude+.5)
    local y=math.floor(math.sin(age*.19+state.seed*.73)*amplitude*.7+.5)
    if x==0 and y==0 then return end
    local baseX,baseY=IsoCamera.getOffX(),IsoCamera.getOffY()
    local rightX,rightY=IsoCamera.getRightClickOffX(),IsoCamera.getRightClickOffY()
    local lastX,lastY=IsoCamera.getLastOffX(),IsoCamera.getLastOffY()
    IsoCamera.setOffX(baseX-rightX+x);IsoCamera.setOffY(baseY-rightY+y)
    IsoCamera.setLastOffX(lastX-rightX+x);IsoCamera.setLastOffY(lastY-rightY+y)
    F.camera={baseX=baseX,baseY=baseY,rightX=rightX,rightY=rightY,x=IsoCamera.getOffX(),y=IsoCamera.getOffY(),baseLastX=lastX-rightX,baseLastY=lastY-rightY,lastX=IsoCamera.getLastOffX(),lastY=IsoCamera.getLastOffY()}
end
function F.draw()
    local state,envelope=F.sample();if not state then F.stop();return end
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,message=pcall(function()
        renderer:renderRect(getPlayerScreenLeft(0),getPlayerScreenTop(0),getPlayerScreenWidth(0),getPlayerScreenHeight(0),.10,.27,.43,state.strength*envelope*F.tintAlpha)
    end)
    renderer:setDoAdditive(previous)
    if not ok then F.stop();error(message)end
end
PY.on("heatRushHit",F.hit)
Events.OnSave.Add(F.stop)
Events.OnMainMenuEnter.Add(F.stop)
