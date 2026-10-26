require "ProjectYakuza/Runtime"
require "ProjectYakuza/WorldEffects"
require "ProjectYakuzaMadDog/Style"
local P=ProjectYakuza
local A={states=setmetatable({}, {__mode="k"}),sprites={},observers=setmetatable({}, {__mode="k"}),nextPoll=0,fadeMs=350,flashMs=260}
P.MadDogAura=A
A.layout={
    {kind="Rim",frames=1,frameHeight=128,height=41,x=0,scale=.43,alpha=.36},
    {kind="Spark",frames=64,frameHeight=32,height=42,x=-7,scale=1.05,alpha=.32},
    {kind="Spark",frames=64,frameHeight=32,height=43,x=7,scale=1.05,alpha=.28},
    {kind="Smoke",frames=1,frameHeight=128,height=52,x=0,scale=.29,alpha=.22},
}
function A.eligible(player)
    local style=player and P.getPlayerStyle(player)
    return player and not player:isDead() and not player:getVehicle() and P.isEquipped(player)
        and style and style.id=="project_yakuza.mad_dog_of_shimano" and style.heatAura=="mad_dog_y0"
        and P.Heat.enabled(player) and not player:getModData().ProjectYakuzaHeatAuraDisabled
end
function A.hook()
    local active=false
    for _ in pairs(A.states) do active=true;break end
    if active and not A.rendering then Events.OnPostRender.Add(A.render);A.rendering=true
    elseif not active and A.rendering then Events.OnPostRender.Remove(A.render);A.rendering=false end
end
function A.clear(player)
    local state=A.states[player]
    if not state then return end
    for _,e in ipairs(state.emitters) do
        e.instance:Dispose();IsoSpriteInstance.add(e.instance)
    end
    A.states[player]=nil;A.hook()
end
function A.update(player)
    local state=A.states[player]
    local extreme=player and P.Heat.isExtreme(player)
    if not A.eligible(player) or not (A.pendingFlash==player or (state and state.flash>0) or P.Heat.stocks(player)>=1
        or (extreme and P.Heat.display(player)>0)) then A.clear(player);return end
    if not state then
        state={emitters={},clock=0,fade=A.pendingFlash==player and A.fadeMs or 0,flash=A.pendingFlash==player and A.flashMs or 0,last=getTimestampMs()};A.states[player]=state
        local tile=Core.getTileScale()
        for _,point in ipairs(A.layout) do
            local sprite=A.sprites[point.kind]
            if not sprite then
                sprite=IsoSprite.CreateSprite(nil)
                sprite:LoadFramesNoDirPageDirect("media/textures/ProjectYakuzaMadDog/Aura",point.kind,point.frames)
                sprite:setAnimate(point.frames>1);A.sprites[point.kind]=sprite
            end
            local instance=P.WorldEffects.attach(player,sprite,point.frameHeight,tile*point.scale,
                point.height*tile,true,point.frames>1 and 20/60 or 0,point.x*tile)
            -- This layer owns only its instances. Render once through the world
            -- callback, rather than leaving a duplicate on character attachments.
            player:getAttachedAnimSprite():remove(instance)
            instance:SetAlpha(0);instance:SetTargetAlpha(0)
            state.emitters[#state.emitters+1]={instance=instance,sprite=sprite,point=point}
        end
        A.hook()
    end
    state.extreme=extreme
end
function A.flash(player)
    if not A.eligible(player) then return end
    -- A transient creator flag supports a zero-heat completion flash without
    -- spending or altering the framework's heat resource.
    A.pendingFlash=player;A.update(player);A.pendingFlash=nil
    local state=A.states[player]
    if state then state.flash=A.flashMs end
end
function A.render()
    if not A.normalColor then
        A.normalColor=ColorInfo.new(.90,.85,1,1);A.extremeColor=ColorInfo.new(1,.95,1,1)
    end
    local now=getTimestampMs();local paused=isGamePaused();local tile=Core.getTileScale()
    for player,state in pairs(A.states) do
        if not A.eligible(player) then A.clear(player)
        else
            local dt=math.max(0,math.min(250,now-state.last));state.last=now
            if not paused then state.clock=state.clock+dt;state.fade=math.min(A.fadeMs,state.fade+dt);state.flash=math.max(0,state.flash-dt) end
            if state.flash<=0 and not P.Heat.isExtreme(player) and P.Heat.stocks(player)<1 then A.clear(player)
            else
                state.extreme=P.Heat.isExtreme(player)
                local opacity=state.fade/A.fadeMs;opacity=opacity*opacity*(3-2*opacity)
                local strength=state.extreme and 1.35 or 1
                if state.flash>0 then strength=strength+.35*math.sin(math.pi*(1-state.flash/A.flashMs)) end
                local color=state.extreme and A.extremeColor or A.normalColor
                for i,e in ipairs(state.emitters) do
                    if e.point.frames>1 and not paused then e.sprite:update(e.instance) end
                    local alpha=e.point.alpha*opacity*strength*(.94+.06*math.sin(state.clock*.005+i))
                    e.instance:SetAlpha(alpha);e.instance:SetTargetAlpha(alpha)
                    e.instance:render(player,player:getX(),player:getY(),player:getZ(),IsoDirections.N,
                        player:getOffsetX()+tile,player:getOffsetY()-89*tile,color)
                end
            end
        end
    end
end
function A.poll()
    if not A.running then return end
    local now=getTimestampMs();if now<A.nextPoll then return end;A.nextPoll=now+250
    for index=0,3 do
        local player=getSpecificPlayer(index)
        if player then A.update(player);if A.states[player] then A.states[player].seen=now end end
    end
    -- Consume the framework's existing observer actors; no world/zombie scan
    -- and no network-handler replacement is needed for this presentation layer.
    for _,remote in pairs(P.Network and P.Network.remote or {}) do
        local player=remote.actor
        if player and not player:isLocalPlayer() then
            local serial=remote.packet and remote.packet.taunt or 0
            local previous=A.observers[player]
            if previous and serial>previous.serial then A.flash(player) end
            A.observers[player]={serial=serial,seen=now}
            A.update(player)
            if A.states[player] then A.states[player].seen=now end
        end
    end
    for player,state in pairs(A.states) do if state.seen~=now then A.clear(player) end end
    for player,observer in pairs(A.observers) do if observer.seen~=now then A.observers[player]=nil end end
end
function A.clearAll()
    for player in pairs(A.states) do A.clear(player) end
    A.observers=setmetatable({}, {__mode="k"})
end
P.on("heatChanged",A.update)
P.on("extremeHeatStarted",A.update)
P.on("extremeHeatEnded",A.update)
P.on("styleChanged",A.update)
P.on("tauntStopped",function(player,complete)if complete then A.flash(player)end end)
Events.OnTick.Add(A.poll)
Events.OnGameStart.Add(function()A.running=true;A.nextPoll=0;A.poll()end)
Events.OnPlayerDeath.Add(A.clear)
Events.OnSave.Add(A.clearAll)
Events.OnMainMenuEnter.Add(function()A.running=false;A.clearAll()end)
