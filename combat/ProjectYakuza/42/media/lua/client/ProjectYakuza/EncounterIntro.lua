require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleUI"
require "ISUI/ISPanel"
local PY=ProjectYakuza
local E={states=setmetatable({}, {__mode="k"}),countBudget=192,squareBudget=256,offsetCache={},detectors={},playerBudget=16}
PY.EncounterIntro=E
local Panel=ISPanel:derive("ProjectYakuzaEncounterIntro")
E.Panel=Panel
local function now()return getTimestampMs()end
local function eligible(p)
    if not p or not p:isLocalPlayer() or p:isDead() or p:getVehicle() or not PY.isEquipped(p) then return end
    local style=PY.getPlayerStyle(p);local config=style and style.encounterIntro
    if type(config)~="table" or config.enabled~=true or not style.ui or type(style.ui.encounter)~="string"
        or not PY.StyleUI.providers[style.ui.encounter] then return end
    return style,config
end
function PY.registerEncounterDetector(id,fn)
    assert(type(id)=="string" and string.match(id,"^[%w_.-]+$") and type(fn)=="function","namespaced encounter detector and function required")
    E.detectors[id]=fn
end
function PY.unregisterEncounterDetector(id,fn)
    if E.detectors[id] and (not fn or E.detectors[id]==fn) then E.detectors[id]=nil;return true end
    return false
end
local function trigger(config,key)
    if config.triggers==nil then return key=="threat" or key=="hit" end
    return config.triggers[key]==true
end
function E.canSee(observer,target,config)
    if not observer or not target or observer==target or target:isDead() or observer:isDead() or math.abs(observer:getZ()-target:getZ())>.5 then return false end
    local dx,dy=target:getX()-observer:getX(),target:getY()-observer:getY();local d=dx*dx+dy*dy
    if d<.0001 or d>(config.playerRadius or config.radius or 12)^2 then return false end
    local f=observer:getForwardDirection();local fx,fy=f:getX(),f:getY();local length=math.sqrt(fx*fx+fy*fy)
    if length<.001 or (dx*fx+dy*fy)/(math.sqrt(d)*length)<math.cos((config.playerFov or 140)*math.pi/360) then return false end
    return observer:CanSee(target)==true
end
function E.playerThreat(p,s,config)
    if not trigger(config,"visiblePlayer") and not trigger(config,"seenByPlayer") then return end
    local function matches(other)
        return other and instanceof(other,"IsoPlayer") and ((trigger(config,"visiblePlayer") and E.canSee(p,other,config)) or (trigger(config,"seenByPlayer") and E.canSee(other,p,config)))
    end
    if matches(s.target) then return s.target end
    local list=getOnlinePlayers and getOnlinePlayers()
    if list and list:size()>0 then
        local size=list:size();local cursor=(s.playerCursor or 0)%size
        for i=1,math.min(size,E.playerBudget) do
            local other=list:get(cursor);cursor=(cursor+1)%size;s.playerCursor=cursor
            if matches(other) then return other end
        end
    end
    if getSpecificPlayer then for i=0,3 do local other=getSpecificPlayer(i);if matches(other) then return other end end end
end
function E.detect(p,s,style,config)
    local target=E.playerThreat(p,s,config)
    if target then return true,"player_seen",target end
    local fn=config.detector and E.detectors[config.detector]
    if fn and s.failedDetector~=fn then
        local ok,found,other=pcall(fn,p,style,{inEncounter=s.inEncounter==true,lastThreat=s.lastThreat,target=s.target})
        if not ok then s.failedDetector=fn;PY.emit("encounterDetectorFailed",p,style,config.detector,found)
        elseif found==true then return true,"custom",other end
    end
    if trigger(config,"threat") then
        local stats=p:getStats()
        if stats:getNumChasingZombies()>0 or (stats:getNumVeryCloseZombies()>0 and stats:getNumVisibleZombies()>0) then return true,"threat" end
    end
    return false
end
function E.textScale(layout,font,width,height,config,pulse)
    pulse=pulse or 1
    return math.min(1,(config.textScale or 1)*pulse,width*(config.textWidth or .88)/math.max(1,layout.width),height*.22/math.max(1,font.lineHeight))
end
function E.title(config,count)
    for _,entry in ipairs(config.titles or {}) do if entry.max==nil or count<=entry.max then return entry.text end end
    return config.title or ""
end
function E.layoutText(font,text)
    local layout={glyphs={},width=0,height=font.lineHeight};local previous
    for i=1,#text do
        local code=tostring(string.byte(text,i));local glyph=font.glyphs[code] or font.glyphs["63"]
        if glyph then
            if previous then layout.width=layout.width+((font.kerning or {})[previous..":"..code] or 0) end
            layout.glyphs[#layout.glyphs+1]={glyph=glyph,x=layout.width}
            layout.width=layout.width+glyph.advance;previous=code
        end
    end
    return layout
end
function E.drawText(panel,font,layout,texture,x,y,scale,alpha,r,g,b)
    if not texture or scale<=0 or alpha<=0 then return end
    for _,point in ipairs(layout.glyphs) do
        local glyph=point.glyph
        if glyph.width>0 and glyph.height>0 then
            panel:drawSubTexture(texture,glyph.x,glyph.y,glyph.width,glyph.height,
                x+(point.x+glyph.offsetX)*scale,y+glyph.offsetY*scale,glyph.width*scale,glyph.height*scale,alpha,r,g,b)
        end
    end
end
local function syncHook()
    local wanted=false
    for _,s in pairs(E.states) do if s.job or s.panel then wanted=true;break end end
    if wanted and not E.hooked then Events.OnTick.Add(E.tick);E.hooked=true
    elseif not wanted and E.hooked then Events.OnTick.Remove(E.tick);E.hooked=false end
end
function E.close(p,reason)
    local s=E.states[p];if not s then return end
    s.job=nil
    if s.panel then
        local panel=s.panel;s.panel=nil
        PY.StyleUI.releaseAll(panel);panel:removeFromUIManager()
        PY.emit("encounterIntroEnded",p,s.style,s.context,reason or "complete")
    end
    syncHook()
end
function E.clear(p,reason)
    if p then
        local s=E.states[p];E.close(p,reason);E.states[p]=nil
        if s and s.inEncounter then PY.emit("encounterEnded",p,s.style,reason or "cleared") end
    else
        local players={};for player in pairs(E.states) do players[#players+1]=player end
        for _,player in ipairs(players) do E.clear(player,reason or "world_exit") end
    end
end
function Panel:prerender()
    local s=E.states[self.player]
    if not s or s.panel~=self then return end
    local p=self.player;local n=p:getPlayerNum()
    self:setX(getPlayerScreenLeft(n));self:setY(getPlayerScreenTop(n))
    self:setWidth(getPlayerScreenWidth(n));self:setHeight(getPlayerScreenHeight(n))
    local context={style=s.style,title=s.context.title,count=s.context.count,capped=s.context.capped,
        radius=s.config.radius or 12,elapsed=s.age/1000,duration=(s.config.durationMs or 2300)/1000,reason=s.context.reason,target=s.context.target,config=s.config}
    PY.StyleUI.render("encounter",p,self,context)
end
function E.show(p,count,capped)
    local s=E.states[p];local style,config=eligible(p)
    if not s or not style or config~=s.config then E.clear(p,"style_changed");return false end
    s.job=nil
    if count<(config.minZombies or 0) then
        s.inEncounter=false;s.target=nil;s.nextPoll=now()+math.max(config.pollMs or 400,config.rejectRetryMs or 1500)
        s.rejectUntil=s.nextPoll;PY.emit("encounterRejected",p,style,count,config.minZombies,s.reason);syncHook();return false
    end
    s.rejectUntil=nil;s.age=0;s.last=now()
    s.context={title=E.title(config,count),count=count,capped=capped==true,reason=s.reason,radius=config.radius or 12,target=s.target}
    local panel=Panel:new(0,0,getPlayerScreenWidth(p:getPlayerNum()),getPlayerScreenHeight(p:getPlayerNum()))
    panel.player=p;panel:initialise();panel:setWantMouseEvents(false);panel:addToUIManager();s.panel=panel
    local name=config.soundKey and PY.Feedback and PY.Feedback.sound(p,config.soundKey)
    if name then PY.Feedback.play(p,name,config.soundVolume or 1) end
    PY.emit("encounterIntroStarted",p,s.style,s.context)
    syncHook();return true
end
function E.request(p,reason,target)
    local style,config=eligible(p)
    if not style or isGamePaused() then return false,"not_available" end
    local s=E.states[p]
    if s and s.inEncounter then return false,"already_in_encounter" end
    local cell=config.countZombies~=false and getCell() or nil
    if config.countZombies~=false and not cell then return false,"world_not_ready" end
    s=s or {};E.states[p]=s
    s.style=style;s.config=config;s.inEncounter=true;s.lastThreat=now();s.nextPoll=now()+(config.pollMs or 400);s.reason=reason or "manual";s.target=target
    if config.countZombies==false then E.show(p,0,false);return true end
    local cap
    for _,title in ipairs(config.titles or {}) do if title.max then cap=math.max(cap or 0,title.max+1) end end
    if (config.minZombies or 0)>0 then cap=math.max(cap or 0,config.minZombies) end
    local radius=config.radius or 12;local offsets=E.offsetCache[radius]
    if not offsets then
        offsets={};local limit=math.ceil(radius)
        for dx=-limit,limit do for dy=-limit,limit do offsets[#offsets+1]={dx,dy,d=dx*dx+dy*dy} end end
        table.sort(offsets,function(a,b)return a.d<b.d end);E.offsetCache[radius]=offsets
    end
    s.job={cell=cell,offsets=offsets,square=1,index=0,count=0,cap=cap,x=p:getX(),y=p:getY(),z=p:getZ(),radius2=radius^2,seen=setmetatable({}, {__mode="k"})}
    syncHook();return true
end
function E.count(p,s)
    local job=s.job;local squares,reads=0,0
    while squares<E.squareBudget and reads<E.countBudget do
        if not job.objects then
            local offset=job.offsets[job.square]
            if not offset then E.show(p,job.count,false);return end
            job.square=job.square+1;squares=squares+1
            local square=job.cell:getGridSquare(math.floor(job.x)+offset[1],math.floor(job.y)+offset[2],math.floor(job.z))
            job.objects=square and square:getMovingObjects();job.index=0
        end
        local objects=job.objects
        if objects and job.index<objects:size() then
            local z=objects:get(job.index);job.index=job.index+1;reads=reads+1
            if z and instanceof(z,"IsoZombie") and not job.seen[z] then
                job.seen[z]=true
                if not z:isDead() and math.abs(z:getZ()-job.z)<.5 then
                    local dx,dy=z:getX()-job.x,z:getY()-job.y
                    if dx*dx+dy*dy<=job.radius2 then job.count=job.count+1 end
                end
            end
            if job.cap and job.count>=job.cap then E.show(p,job.count,true);return end
        else job.objects=nil end
    end
end
function E.tick()
    local t=now();local paused=isGamePaused()
    for p,s in pairs(E.states) do
        if s.job or s.panel then
            local style,config=eligible(p)
            if not style or style.id~=s.style.id or config~=s.config then E.clear(p,"style_changed")
            elseif s.job then if not paused then E.count(p,s) end
            elseif s.panel then
                local elapsed=math.max(0,t-s.last);s.last=t
                if not paused then s.age=s.age+elapsed else s.lastThreat=s.lastThreat+elapsed end
                if s.age>=(s.config.durationMs or 2300) then E.close(p,"complete") end
            end
        end
    end
    syncHook()
end
function E.update(p)
    if not p or not p:isLocalPlayer() then return end
    local style,config=eligible(p)
    if not style then if E.states[p] then E.clear(p,"not_equipped") end;return end
    if isGamePaused() then return end
    local t=now();local s=E.states[p]
    if s and (s.style.id~=style.id or s.config~=config) then E.clear(p,"style_changed");s=nil end
    if not s then s={style=style,config=config,nextPoll=0,lastThreat=t};E.states[p]=s end
    if t<(s.nextPoll or 0) then return end
    s.nextPoll=t+(config.pollMs or 400)
    local threat,reason,target=E.detect(p,s,style,config)
    if threat then
        if target then s.target=target end
        s.lastThreat=t
        if not s.inEncounter then E.request(p,reason,target) end
    elseif s.inEncounter and t-s.lastThreat>=(config.quietMs or 12000) then
        E.close(p,"encounter_ended");s.inEncounter=false
        PY.emit("encounterEnded",p,style,"quiet")
    end
end
function E.onHit(p,victim,weapon,damage)
    if not p or not p:isLocalPlayer() or not victim or type(damage)~="number" or damage<=0 then return end
    local style,config=eligible(p);if not style or isGamePaused() then return end
    if not ((instanceof(victim,"IsoZombie") and trigger(config,"hit")) or (instanceof(victim,"IsoPlayer") and victim~=p and trigger(config,"playerHit"))) then return end
    local s=E.states[p]
    if s and (s.style.id~=style.id or s.config~=config) then E.clear(p,"style_changed");s=nil end
    if s and s.rejectUntil and now()<s.rejectUntil then return end
    if not s or not s.inEncounter then E.request(p,"hit") end
    s=E.states[p];if s then s.lastThreat=now() end
end
PY.on("combatHit",E.onHit)
Events.OnWeaponHitCharacter.Add(function(p,victim,weapon,damage)
    if victim and instanceof(victim,"IsoPlayer") then E.onHit(p,victim,weapon,damage) end
end)
PY.on("styleChanged",function(p)E.clear(p,"style_changed")end)
Events.OnPlayerUpdate.Add(E.update)
Events.OnGameStart.Add(function()E.clear()end)
Events.OnSave.Add(function()E.clear()end)
Events.OnMainMenuEnter.Add(function()E.clear()end)
