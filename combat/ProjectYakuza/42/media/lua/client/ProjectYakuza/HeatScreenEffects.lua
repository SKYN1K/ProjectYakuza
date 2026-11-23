require "ProjectYakuza/Registry"
local PY=ProjectYakuza
local F={}
PY.HeatScreenEffects=F
function F.restoreCamera()
    local camera=F.camera;if not camera then return end
    if math.abs(IsoCamera.getOffX()-camera.x)<.01 then IsoCamera.setOffX(camera.baseX-camera.rightX)end
    if math.abs(IsoCamera.getOffY()-camera.y)<.01 then IsoCamera.setOffY(camera.baseY-camera.rightY)end
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
function F.hit(p,z,index,contact)
    if not F.allowed(p)or not z or not contact or contact.bloodOnly then return end
    local presentation=PY.HeatActionPresentation
    if not presentation or not presentation.states[p]then return end
    local strength=contact.sumQTE and 1 or contact.charged and .8 or contact.strong~=false and .65 or .35
    local previous=F.state
    F.state={p=p,at=getTimestampMs(),life=140+strength*100,strength=math.min(1,math.max(strength,previous and previous.strength*.5 or 0)),seed=(index or 1)*1.73+getTimestampMs()*.01}
    if not F.hooked then
        Events.OnTick.Add(F.update);Events.OnPreUIDraw.Add(F.draw);Events.OnRenderTick.Add(F.restoreCamera);F.hooked=true
    end
end
function F.sample()
    local state=F.state;if not state or not F.allowed(state.p)then return end
    local age=math.max(0,getTimestampMs()-state.at)
    if age>=state.life then return end
    return state,(1-age/state.life)^2,age
end
function F.update()
    F.restoreCamera()
    local state,envelope,age=F.sample();if not state then F.stop();return end
    local amplitude=state.strength*5*envelope*getCore():getZoom(0)
    local x=math.floor(math.sin(age*.13+state.seed)*amplitude+.5)
    local y=math.floor(math.sin(age*.19+state.seed*.73)*amplitude*.7+.5)
    if x==0 and y==0 then return end
    local baseX,baseY=IsoCamera.getOffX(),IsoCamera.getOffY()
    local rightX,rightY=IsoCamera.getRightClickOffX(),IsoCamera.getRightClickOffY()
    IsoCamera.setOffX(baseX-rightX+x);IsoCamera.setOffY(baseY-rightY+y)
    F.camera={baseX=baseX,baseY=baseY,rightX=rightX,rightY=rightY,x=IsoCamera.getOffX(),y=IsoCamera.getOffY()}
end
function F.draw()
    F.restoreCamera()
    local state,envelope=F.sample();if not state then F.stop();return end
    local renderer=SpriteRenderer.instance;local previous=renderer:getDoAdditive();renderer:setDoAdditive(false)
    local ok,message=pcall(function()
        renderer:renderRect(getPlayerScreenLeft(0),getPlayerScreenTop(0),getPlayerScreenWidth(0),getPlayerScreenHeight(0),.10,.27,.43,state.strength*envelope*.12)
    end)
    renderer:setDoAdditive(previous)
    if not ok then F.stop();error(message)end
end
PY.on("heatRushHit",F.hit)
Events.OnSave.Add(F.stop)
Events.OnMainMenuEnter.Add(F.stop)
