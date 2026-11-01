ProjectYakuza = ProjectYakuza or {}
do
local C={defaults={maxStocks=6,gainPerDamage=1.25,lossPerDamage=.5,idleGraceMs=3000,idleLossPerSecond=4,knockdownLoss=8,secondsPerStock=3.75,attackFuelCost=1.5,extremeDamage=1.5,extremeSpeed=1.2,retainStocks=true}}
ProjectYakuza.HeatRules=C
local limits={maxStocks={1,32},gainPerDamage={0,100},lossPerDamage={0,100},idleGraceMs={0,600000},idleLossPerSecond={0,100},knockdownLoss={0,100},secondsPerStock={.1,600},attackFuelCost={0,100}}
local cache=setmetatable({}, {__mode="k"})
function C.valid(cfg)
    if cfg==nil or cfg==false then return true end
    if type(cfg)~="table"then return false end
    for key,value in pairs(cfg)do
        if key=="retainStocks"then if type(value)~="boolean"then return false end
        else
            local range=limits[key]
            if not range or type(value)~="number"or value~=value or value<range[1]or value>range[2]or key=="maxStocks"and value~=math.floor(value)then return false end
        end
    end
    return true
end
function C.forStyle(style)
    local cfg=style and style.heatConfig
    if type(cfg)~="table"then return C.defaults end
    local result=cache[cfg]
    if not result then
        if not C.valid(cfg)then return C.defaults end
        result={};for key,value in pairs(cfg)do result[key]=value end
        setmetatable(result,{__index=C.defaults});cache[cfg]=result
    end
    return result
end
function C.stockSize(style)return 100/C.forStyle(style).maxStocks end
function C.invalidate(style)if type(style.heatConfig)=="table"then cache[style.heatConfig]=nil end end
end
do
local S={};ProjectYakuza.HeatSpeed=S
local function finite(v)return type(v)=="number"and v==v and v<math.huge and v>-math.huge end
function S.valid(cfg)
    if cfg==nil or cfg==false then return true end
    if type(cfg)~="table"or not finite(cfg.max)or cfg.max<1 or cfg.max>2 then return false end
    if cfg.power~=nil and (not finite(cfg.power)or cfg.power<.25 or cfg.power>4)then return false end
    if cfg.useExtremeFuel~=nil and type(cfg.useExtremeFuel)~="boolean"then return false end
    for key in pairs(cfg)do if key~="max"and key~="power"and key~="useExtremeFuel"then return false end end
    return true
end
function S.factor(style,heat,fuel,extreme)
    local cfg=style and style.heatAttackSpeed
    if not style or style.heat~=true or type(cfg)~="table"or not S.valid(cfg)or extreme and not cfg.useExtremeFuel then return 1 end
    local value=extreme and fuel or heat
    if not finite(value)then return 1 end
    return 1+(cfg.max-1)*(math.max(0,math.min(100,value))/100)^(cfg.power or 1)
end
function S.allowed(style,value,extreme)
    if value==nil then return true end
    if not finite(value)or value<1 or value>2 then return false end
    local cfg=style and style.heatAttackSpeed
    if not style or style.heat~=true or type(cfg)~="table"or not S.valid(cfg)or extreme and not cfg.useExtremeFuel then return value==1 end
    return value<=cfg.max
end
end
do
local Q={};ProjectYakuza.QTE=Q
local function finite(x)return type(x)=="number"and x==x and x<math.huge and x>-math.huge end
function Q.valid(def,durationMs)
    if type(def)~="table"or type(def.prompts)~="table"or #def.prompts<1 or #def.prompts>32 then return false,"QTE requires 1..32 prompts"end
    local last=0
    for _,v in ipairs(def.prompts)do
        if type(v)~="table"or not finite(v.atMs)or v.atMs<=last or v.atMs>120000 or not finite(v.windowMs)or v.windowMs<50 or v.windowMs>2000 or v.atMs-v.windowMs<last or type(v.binding)~="string"or not v.binding:match("^[%w_.-]+$")or #v.binding>80 then return false,"invalid QTE prompt timing or binding"end
        if durationMs and v.atMs>durationMs then return false,"QTE prompt exceeds animation duration"end
        if v.damageMultiplier~=nil and (not finite(v.damageMultiplier)or v.damageMultiplier<0 or v.damageMultiplier>10)then return false,"invalid QTE damage multiplier"end
        last=v.atMs
    end
    return true
end
function Q.window(def,index,timeMs,earlyMs,lateMs)
    local v=def and def.prompts and def.prompts[index]
    return v~=nil and finite(timeMs)and timeMs>=v.atMs-v.windowMs-(earlyMs or 0)and timeMs<v.atMs+(lateMs or 0)
end
function Q.create(def,down,context)
    local valid,reason=Q.valid(def);assert(valid,reason)
    local s={definition=def,context=context,index=1,accepted={},results={},downs={},lastTime=0,successes=0}
    for _,v in ipairs(def.prompts)do s.downs[v.binding]=down and down(v.binding)==true or false end
    return s
end
local function emit(s,name,...)
    if ProjectYakuza.emit then ProjectYakuza.emit(name,s.context,...)end
end
function Q.update(s,timeMs,down,callback)
    if s.closed then return false,"closed"end
    if not finite(timeMs)or timeMs<s.lastTime then return false,"invalid_time"end
    s.lastTime=timeMs
    local current={};for binding in pairs(s.downs)do current[binding]=down(binding)==true end
    local v=s.definition.prompts[s.index]
    if v and Q.window(s.definition,s.index,timeMs)then
        if not s.prompted then s.prompted=true;emit(s,"qtePrompt",s.index,v)end
        if current[v.binding]and not s.downs[v.binding]and not s.accepted[s.index]then
            s.accepted[s.index]=true;emit(s,"qteInput",s.index,v)
            if callback then callback("input",s.index,true,v)end
        end
    end
    s.downs=current
    while s.index<=#s.definition.prompts and timeMs>=s.definition.prompts[s.index].atMs do
        local i=s.index;local prompt=s.definition.prompts[i];local success=s.accepted[i]==true
        s.results[i]=success;if success then s.successes=s.successes+1 end
        s.index=i+1;s.prompted=nil;emit(s,"qteResult",i,success,prompt)
        if callback then callback("result",i,success,prompt)end
    end
    if s.index>#s.definition.prompts then s.closed=true;emit(s,"qteFinished",s.successes,#s.definition.prompts)end
    return true
end
function Q.cancel(s,reason)
    if not s or s.closed then return end;s.closed=true;emit(s,"qteCancelled",reason or "interrupted")
end
end
local R={}
ProjectYakuza.ChargeRules=R
function R.power(age,minimum,maximum)
    return math.max(0,math.min(1,(age-minimum)/math.max(1,maximum-minimum)))
end
function R.damage(move,power)
    local maximum=move.damageMultiplier or 1
    local minimum=math.max(0,math.min(maximum,move.minChargedDamageMultiplier or maximum))
    power=type(power)=="number" and power==power and math.max(0,math.min(1,power)) or 0
    return minimum+(maximum-minimum)*power
end

local H={kinds={flinch=true,stagger=true,knockdown=true,stun=true},stuns=setmetatable({}, {__mode="k"})}
ProjectYakuza.HitResponses=H
function H.valid(kind,force)
    return H.kinds[kind]==true and (kind~="stun"or force==0)and type(force)=="number" and force==force and force>=0 and force<=1.5
end
function H.resolve(style,move)
    if not style or not move or move.groundAttack or move.hitResponse==false then return nil end
    local profiles=style.hitResponses;if not profiles then return nil end
    local key=move.hitResponse
    if not key then
        if move.chargedHeavy then key="chargedHeavy"
        elseif move.double then key="doubleFinisher"
        elseif move.afterLight then key="finisher"
        else for _,light in ipairs(style.lightAttacks or {}) do
            if light==move or (move.nodeValue and light.nodeValue==move.nodeValue) then key="light";break end
        end end
    end
    local profile=key and profiles[key];if not profile then return nil end
    local kind,force=profile.kind,profile.force
    local power=move.chargePower
    if move.chargedHeavy and type(power)=="number" and power==power and profile.fullChargeAt
        and power>=profile.fullChargeAt and power<=1 then kind=profile.fullChargeKind;force=profile.fullChargeForce end
    if H.valid(kind,force) then return {kind=kind,force=force} end
end
function H.releaseStun(victim)
    local state=H.stuns[victim];if not state then return end
    H.stuns[victim]=nil
    victim:setUseless(state.useless);victim:setIgnoreMovement(state.ignore);victim:setDeferredMovementEnabled(state.deferred)
    local any=false;for _ in pairs(H.stuns)do any=true;break end
    if not any and H.stunHooked then Events.OnTick.Remove(H.tickStuns);H.stunHooked=false end
end
function H.clearStuns()
    for victim in pairs(H.stuns)do H.releaseStun(victim)end
end
function H.tickStuns()
    local t=getTimestampMs()
    for victim,state in pairs(H.stuns)do
        if isGamePaused()then state.untilAt=t+state.remaining
        else
            state.remaining=math.max(0,state.untilAt-t)
            if victim:isDead()or victim:isOnFloor()or victim:isKnockedDown()or state.remaining==0 then H.releaseStun(victim)
            else victim:setStaggerBack(false);victim:setHitForce(0)end
        end
    end
end
function H.stun(victim)
    local state=H.stuns[victim]
    if not state then
        state={useless=victim:isUseless(),ignore=victim:getIgnoreMovement(),deferred=victim:isDeferredMovementEnabled()};H.stuns[victim]=state
    end
    state.untilAt=getTimestampMs()+250;state.remaining=250
    victim:setUseless(true);victim:setIgnoreMovement(true);victim:setDeferredMovementEnabled(false)
    victim:setStaggerBack(false);victim:setHitForce(0);victim:setAttackOutcome("fail")
    if not H.stunHooked then Events.OnTick.Add(H.tickStuns);H.stunHooked=true end
    if not H.stunCleanup then
        if Events.OnSave then Events.OnSave.Add(H.clearStuns)end
        if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(H.clearStuns)end
        H.stunCleanup=true
    end
    return true
end
function H.nativeHit(attacker,victim,item,amount,move)
    local saved
    if move and move.noKnockback and item.getPushBackMod then
        saved={item:getPushBackMod(),item:getKnockdownMod(),item:isKnockBackOnNoDeath(),item:isAlwaysKnockdown()}
        item:setPushBackMod(0);item:setKnockdownMod(0);item:setKnockBackOnNoDeath(false);item:setAlwaysKnockdown(false)
    end
    local ok,result=pcall(victim.Hit,victim,item,attacker,amount,false,1)
    if saved then item:setPushBackMod(saved[1]);item:setKnockdownMod(saved[2]);item:setKnockBackOnNoDeath(saved[3]);item:setAlwaysKnockdown(saved[4])end
    return ok,result
end
function H.apply(attacker,victim,response)
    if not response or not H.valid(response.kind,response.force) or not attacker or not victim
        or victim:isDead() or victim:isOnFloor() or victim:isKnockedDown() then return false end
    if response.kind=="stun"then return H.stun(victim)end
    local dx,dy=victim:getX()-attacker:getX(),victim:getY()-attacker:getY()
    local length=math.sqrt(dx*dx+dy*dy);if length<.001 then return false end
    victim:getHitDir():set(dx/length,dy/length)
    victim:setHitForce(response.force)
    if response.kind~="flinch" then
        victim:setVariable("ProjectYakuzaEnemyReaction",false);victim:setVariable("ProjectYakuzaEnemyHitClip","")
        victim:setHitReaction("")
        victim:setStaggerBack(true)
        if response.kind=="knockdown" then victim:setFallOnFront(false);victim:setKnockedDown(true) end
    end
    return true
end

local ProjectYakuza = ProjectYakuza
ProjectYakuza.FEATURES={grab=false}
ProjectYakuza.VERSION = "0.69.0"
ProjectYakuza.API_VERSION = 3
ProjectYakuza.styles = ProjectYakuza.styles or {}
ProjectYakuza.styleOrder = ProjectYakuza.styleOrder or {}
ProjectYakuza.actionHandlers = ProjectYakuza.actionHandlers or {}
ProjectYakuza.styleActionHandlers = ProjectYakuza.styleActionHandlers or {}
ProjectYakuza.styleInputHandlers = ProjectYakuza.styleInputHandlers or {}
ProjectYakuza.listeners = ProjectYakuza.listeners or {}
ProjectYakuza.actionKinds = { finisher=true, grab=true, parry=true, block=true, quickstep=true, quickstepAttack=true, runningAttack=true, heatAction=true, heatActivation=true, taunt=true, styleEntry=true, heavyCharge=true, chargedHeavy=true }
ProjectYakuza.actionDefinitions = ProjectYakuza.actionDefinitions or {}
ProjectYakuza.activeActions = ProjectYakuza.activeActions or setmetatable({}, {__mode="k"})
ProjectYakuza.MAX_HIT_COUNT = 3
ProjectYakuza.TOKEN = "ProjectYakuza.StyleToken"
function ProjectYakuza.on(event, fn)
    assert(type(fn) == "function", "listener must be a function")
    ProjectYakuza.listeners[event] = ProjectYakuza.listeners[event] or {}
    table.insert(ProjectYakuza.listeners[event], fn)
    return fn
end
function ProjectYakuza.off(event,fn)
    local listeners=ProjectYakuza.listeners[event]
    if not listeners then return false end
    for i=#listeners,1,-1 do if listeners[i]==fn then table.remove(listeners,i);return true end end
    return false
end
function ProjectYakuza.emit(event, ...)
    local listeners=ProjectYakuza.listeners[event]
    if not listeners then return end
    local dispatch={}
    for i,fn in ipairs(listeners) do dispatch[i]=fn end
    for _, fn in ipairs(dispatch) do
        local ok, err = pcall(fn, ...)
        if not ok then print("[ProjectYakuza] listener error: " .. tostring(err)) end
    end
end
function ProjectYakuza.validateStyle(style)
    local errors={}
    local function problem(text)errors[#errors+1]=text end
    local function text(value)return type(value)=="string" and value~="" end
    local function number(value)return type(value)=="number" and value==value and value<math.huge and value>-math.huge end
    if type(style)=="table" and style.hitResponses~=nil then
        if type(style.hitResponses)~="table" then problem("hitResponses must be a profile table")
        else for key,profile in pairs(style.hitResponses) do
            local path="hitResponses."..tostring(key)
            if not text(key) or type(profile)~="table" or not H.valid(profile.kind,profile.force) then
                problem(path.." requires kind flinch/stagger/knockdown and force 0..1.5")
            elseif profile.fullChargeAt~=nil or profile.fullChargeKind~=nil or profile.fullChargeForce~=nil then
                if not number(profile.fullChargeAt) or profile.fullChargeAt<0 or profile.fullChargeAt>1
                    or not H.valid(profile.fullChargeKind,profile.fullChargeForce) then problem(path.." requires a fullChargeAt 0..1 and valid full-charge kind/force") end
            end
        end end
    end
    if type(style)=="table" and style.juggling~=nil and style.juggling~=false then
        local c=style.juggling
        if type(c)~="table" then problem("juggling must be false or a configuration table")
        else
            if c.enabled~=nil and type(c.enabled)~="boolean" then problem("juggling.enabled must be boolean") end
            local limits={maxHits={1,12,true},maxRelaunches={0,3,true},windowMs={50,2000},maxDurationMs={50,6000},landingCooldownMs={0,5000}}
            for k,b in pairs(limits) do local v=c[k]
                if v~=nil and (not number(v) or v<b[1] or v>b[2] or (b[3] and v~=math.floor(v))) then problem("invalid juggling."..k) end
            end
            if number(c.windowMs or 650) and number(c.maxDurationMs or 1800) and (c.windowMs or 650)>(c.maxDurationMs or 1800) then problem("juggling window exceeds hard duration") end
            if c.presentation~=nil and (not text(c.presentation) or #c.presentation>100) then problem("juggling.presentation must name an addon presentation") end
        end
    end
    local function move(value,path,light)
        if type(value)~="table" then problem(path.." must be a table");return end
        if value.enduranceCost~=nil and (not number(value.enduranceCost)or value.enduranceCost<0 or value.enduranceCost>.1)then problem(path..".enduranceCost must be 0..0.1")end
        if value.qte~=nil then local ok,reason=ProjectYakuza.QTE.valid(value.qte,type(value.duration)=="number"and value.duration*1000 or nil);if not ok then problem(path..".qte: "..reason)end end
        if value.hitResponse~=nil and value.hitResponse~=false
            and (not text(value.hitResponse) or type(style.hitResponses)~="table" or not style.hitResponses[value.hitResponse]) then problem(path..".hitResponse must name a hitResponses profile or be false") end
        if value.juggle~=nil and value.juggle~=false then
            local j=value.juggle;local c=style.juggling
            if type(c)~="table" or type(j)~="table" then problem(path..".juggle requires enabled style.juggling")
            else
                if j.kind~="launch" and j.kind~="followup" and j.kind~="ender" then problem(path..".juggle.kind must be launch/followup/ender") end
                if value.groundAttack then problem(path..".juggle is not allowed for ground attacks") end
                if j.windowMs~=nil and (not number(j.windowMs) or j.windowMs<50 or j.windowMs>2000 or j.windowMs>(number(c.maxDurationMs) and c.maxDurationMs or 1800)) then problem(path..".juggle.windowMs is outside allowed duration") end
            end
        end
        if not text(value.animation) then problem(path..".animation is required") end
        if value.holdAnimation~=nil and not text(value.holdAnimation) then problem(path..".holdAnimation must name a native clip") end
        if light and not text(value.nodeValue) then problem(path..".nodeValue is required") end
        if light or value.duration~=nil then
            if not number(value.duration) or value.duration<=0 then problem(path..".duration must be positive seconds") end
        end
        for _,key in ipairs({"impact","chainAt","quickstepCancelAt"}) do
            local v=value[key];if v~=nil and (not number(v) or v<0 or v>1) then problem(path.."."..key.." must be 0..1") end
        end
        if value.noKnockback~=nil and type(value.noKnockback)~="boolean"then problem(path..".noKnockback must be a boolean")end
        if value.damageMultiplier~=nil and (not number(value.damageMultiplier) or value.damageMultiplier<0) then problem(path..".damageMultiplier must be nonnegative") end
        if value.minChargedDamageMultiplier~=nil and (not number(value.minChargedDamageMultiplier) or value.minChargedDamageMultiplier<0 or value.minChargedDamageMultiplier>(value.damageMultiplier or 1)) then problem(path..".minChargedDamageMultiplier must be between zero and maximum damageMultiplier") end
        for _,key in ipairs({"heatCost","heatStocks","distance","cooldownMs","windowMs","holdMs","minChargeMs","windupMs","maxHoldMs"}) do
            if value[key]~=nil and (not number(value[key]) or value[key]<0) then problem(path.."."..key.." must be nonnegative") end
        end
        if value.afterLight~=nil and (not number(value.afterLight) or value.afterLight<1 or value.afterLight~=math.floor(value.afterLight) or (type(style.lightAttacks)=="table" and value.afterLight>#style.lightAttacks)) then problem(path..".afterLight must index lightAttacks") end
        if value.speed~=nil and (not number(value.speed) or value.speed<=0) then problem(path..".speed must be positive") end
    end
    if type(style)~="table" then return false,{"style must be a table"} end
    if not text(style.id) or style.id=="none" or not string.match(style.id,"^[%w_.-]+$") then problem("style.id must be a unique namespaced ID using letters, numbers, underscore, dot or hyphen") end
    if not text(style.name) then problem("style.name is required") end
    if style.ui~=nil then
        if type(style.ui)~="table" then problem("ui must be a channel/provider table")
        else for key,value in pairs(style.ui) do
            if not ({heat=true,status=true,selector=true,selectorSlot=true,setup=true,encounter=true})[key] then problem("unknown UI channel: "..tostring(key)) end
            if value~=false and not text(value) then problem("ui."..tostring(key).." must be a provider ID or false") end
        end end
    end
    if style.selectorIcon~=nil and not text(style.selectorIcon) then problem("selectorIcon must name a supplied texture") end
    if style.encounterIntro~=nil and style.encounterIntro~=false then
        local intro=style.encounterIntro
        if type(intro)~="table" then problem("encounterIntro must be false or a configuration table")
        else
            if intro.enabled~=nil and type(intro.enabled)~="boolean" then problem("encounterIntro.enabled must be boolean") end
            for key,limits in pairs({radius={1,30},durationMs={100,10000},quietMs={1000,120000},pollMs={100,5000},soundVolume={0,2},minZombies={0,1000},playerRadius={1,100},playerFov={1,360},textScale={.1,1},textWidth={.1,1},rejectRetryMs={100,30000}}) do
                local value=intro[key]
                if value~=nil and (not number(value) or value<limits[1] or value>limits[2]) then problem("invalid encounterIntro."..key) end
            end
            if intro.minZombies and number(intro.minZombies) and intro.minZombies~=math.floor(intro.minZombies) then problem("encounterIntro.minZombies must be an integer") end
            if intro.countZombies~=nil and type(intro.countZombies)~="boolean" then problem("encounterIntro.countZombies must be boolean") end
            if intro.countZombies==false and number(intro.minZombies) and intro.minZombies>0 then problem("minZombies requires counting") end
            if intro.detector~=nil and not text(intro.detector) then problem("encounterIntro.detector must name a registered detector") end
            if intro.triggers~=nil then
                if type(intro.triggers)~="table" then problem("encounterIntro.triggers must be a table")
                else for k,v in pairs(intro.triggers) do
                    if not ({threat=true,hit=true,playerHit=true,visiblePlayer=true,seenByPlayer=true})[k] or type(v)~="boolean" then problem("invalid encounterIntro trigger: "..tostring(k)) end
                end end
            end
            if intro.soundKey~=nil and not text(intro.soundKey) then problem("encounterIntro.soundKey must name a style sound") end
            if type(intro.titles)~="table" or #intro.titles<1 or #intro.titles>16 then problem("encounterIntro.titles requires 1..16 entries")
            else
                local previous=-1
                for i,entry in ipairs(intro.titles) do
                    if type(entry)~="table" or not text(entry.text) or #entry.text>120 then problem("invalid encounterIntro title")
                    elseif entry.max==nil then if i~=#intro.titles then problem("only final encounterIntro title may omit max") end
                    elseif not number(entry.max) or entry.max<0 or entry.max~=math.floor(entry.max) or entry.max<=previous then problem("encounterIntro title maxima must increase")
                    else previous=entry.max end
                end
                if type(intro.titles[#intro.titles])=="table" and intro.titles[#intro.titles].max~=nil then problem("final encounterIntro title must omit max") end
            end
        end
    end
    for _,key in ipairs({"attackSpeed","runningKneeSpeed"}) do
        if style[key]~=nil and (not number(style[key]) or style[key]<=0) then problem(key.." must be positive") end
    end
    for _,key in ipairs({"heat","combatVoices","quickstepVoices","tigerDrop","enemyReactions","quickstepCancelLights"}) do
        if style[key]~=nil and type(style[key])~="boolean" then problem(key.." must be true or false") end
    end
    if not ProjectYakuza.HeatRules.valid(style.heatConfig)then problem("invalid heatConfig capacity, gain or drain setting")end
    if not ProjectYakuza.HeatSpeed.valid(style.heatAttackSpeed)then problem("heatAttackSpeed requires max 1..2, optional power 0.25..4 and useExtremeFuel boolean")end
    if style.exertion~=nil and style.exertion~=false then
        local allowed={light=true,directional=true,quickstepAttack=true,ground=true,running=true,dropkick=true,heavy=true,finisher=true,double=true,charged=true,counter=true,heatAction=true}
        if type(style.exertion)~="table"then problem("exertion must be a cost table or false")
        else for key,cost in pairs(style.exertion)do if not allowed[key]or not number(cost)or cost<0 or cost>.1 then problem("invalid exertion cost: "..tostring(key))end end end
    end
    if style.combatVoiceVolume~=nil and (not number(style.combatVoiceVolume) or style.combatVoiceVolume<0) then problem("combatVoiceVolume must be nonnegative") end
    if style.combatVoiceGains~=nil then
        if type(style.combatVoiceGains)~="table"then problem("combatVoiceGains must map line IDs to nonnegative gains")
        else for id,gain in pairs(style.combatVoiceGains)do if not text(id)or not number(gain)or gain<0 then problem("combatVoiceGains requires line IDs and nonnegative gains")end end end
    end
    if style.soundVariety~=nil and type(style.soundVariety)~="boolean"then problem("soundVariety must be boolean")end
    if style.impactFeedback~=nil and style.impactFeedback~=false and not ({unarmed=true,blunt=true,blade=true})[style.impactFeedback]then problem("impactFeedback must be unarmed, blunt, blade or false")end
    if type(style.lightAttacks)~="table" or #style.lightAttacks==0 then problem("lightAttacks must contain at least one move")
    else for i,value in ipairs(style.lightAttacks) do move(value,"lightAttacks["..i.."]",true) end end
    if style.extremeLightAttacks~=nil then
        if type(style.extremeLightAttacks)~="table" or #style.extremeLightAttacks<1 or #style.extremeLightAttacks>16 then problem("extremeLightAttacks requires 1..16 moves")
        else for i,value in ipairs(style.extremeLightAttacks)do move(value,"extremeLightAttacks["..i.."]",true)end end
    end
    if style.finisherBranches~=nil and (not number(style.finisherBranches)or style.finisherBranches<1 or style.finisherBranches~=math.floor(style.finisherBranches))then problem("finisherBranches must be a positive integer")end
    if style.directionalFinishers~=nil then
        local cfg=style.directionalFinishers
        if type(cfg)~="table"or not number(cfg.minimumDegrees)or cfg.minimumDegrees<90 or cfg.minimumDegrees>180 or not text(cfg.prefix)then problem("directionalFinishers requires a reverse angle and variant prefix")end
    end
    if style.heatRush~=nil then
        local cfg=style.heatRush
        if type(cfg)~="table"or not number(cfg.hits)or cfg.hits<4 or cfg.hits>16 or cfg.hits~=math.floor(cfg.hits)or not number(cfg.windowMs)or cfg.windowMs<100 or cfg.windowMs>1500 then problem("heatRush requires hits 4..16 and windowMs 100..1500")end
    end
    if style.directionalAttacks~=nil then
        local cfg=style.directionalAttacks
        if type(cfg)~="table"or type(cfg.moves)~="table"then problem("directionalAttacks requires moves")
        else
            local minimum,rear=cfg.minimumDegrees or 65,cfg.rearDegrees or 145
            if not number(minimum)or not number(rear)or minimum<30 or rear<=minimum or rear>180 then problem("invalid directional turn thresholds")end
            local count=0
            for key,value in pairs(cfg.moves)do count=count+1;if key~="left"and key~="right"and key~="rear"then problem("invalid directional move key")end;move(value,"directionalAttacks.moves."..tostring(key),true)end
            if count==0 then problem("directionalAttacks requires at least one move")end
        end
    end
    if style.tauntReactions~=nil then
        local cfg=style.tauntReactions
        if type(cfg)~="table"or not number(cfg.radius)or cfg.radius<1 or cfg.radius>6 or not number(cfg.maxTargets)or cfg.maxTargets<1 or cfg.maxTargets>8 or cfg.maxTargets~=math.floor(cfg.maxTargets)then problem("tauntReactions requires radius 1..6 and maxTargets 1..8")end
    end
    if style.comboResetMs~=nil and (not number(style.comboResetMs) or style.comboResetMs<0) then problem("comboResetMs must be nonnegative milliseconds") end
    if style.lightBufferLimit~=nil and (not number(style.lightBufferLimit) or style.lightBufferLimit<1 or style.lightBufferLimit~=math.floor(style.lightBufferLimit)) then problem("lightBufferLimit must be a positive integer") end
    if style.groundAttacks~=nil then
        if type(style.groundAttacks)~="table" or #style.groundAttacks==0 then problem("groundAttacks must be omitted or contain at least one move")
        else for i,value in ipairs(style.groundAttacks) do move(value,"groundAttacks["..i.."]",true) end end
    end
    if style.actions~=nil and type(style.actions)~="table" then problem("actions must be a table")
    else for kind,slot in pairs(style.actions or {}) do
        if not ProjectYakuza.actionKinds[kind] then problem("unknown action kind: "..tostring(kind).."; register it with registerActionKind first") end
        if type(slot)~="table" then problem("actions."..tostring(kind).." must be a table")
        elseif slot.enabled==true then
            if slot.variants~=nil then
                if type(slot.variants)~="table" then problem("actions."..kind..".variants must be a table")
                else for id,value in pairs(slot.variants) do if type(value)~="table" or value.enabled~=false then move(value,"actions."..kind..".variants."..tostring(id),false) end end end
            else move(slot,"actions."..kind,false) end
        end
    end end
    if style.music~=nil and style.music~=false then
        if type(style.music)~="table" then problem("music must be false or a list of named sound definitions")
        else
            local seen={}
            for i,track in ipairs(style.music) do
                if type(track)~="table" or not text(track.sound) then problem("music["..i.."].sound is required")
                elseif seen[track.sound] then problem("duplicate music sound: "..track.sound)
                else seen[track.sound]=true end
            end
        end
    end
    if style.sounds~=nil and style.sounds~=false then
        if type(style.sounds)~="table" then problem("sounds must be false or a cue-name table")
        else for key,value in pairs(style.sounds) do if not text(value) then problem("sounds."..tostring(key).." must name an existing sound") end end end
    end
    return #errors==0,errors
end
function ProjectYakuza.registerStyle(style)
    local valid,errors=ProjectYakuza.validateStyle(style)
    assert(valid,"Invalid ProjectYakuza style: "..table.concat(errors,"; "))
    style.actions = style.actions or {}
    style.comboResetMs = style.comboResetMs or 750
    style.lightBufferLimit = style.lightBufferLimit or 1
    if not ProjectYakuza.styles[style.id] then table.insert(ProjectYakuza.styleOrder, style.id) end
    ProjectYakuza.HeatRules.invalidate(style)
    ProjectYakuza.styles[style.id] = style
    ProjectYakuza.emit("styleRegistered", style)
    return style
end
function ProjectYakuza.listStyles()
    local result={}
    for _,id in ipairs(ProjectYakuza.styleOrder) do local s=ProjectYakuza.styles[id];result[#result+1]={id=id,name=s.name,description=s.description} end
    return result
end
function ProjectYakuza.getStyle(id) return ProjectYakuza.styles[id] end
function ProjectYakuza.isStyleToken(item)
    return item~=nil and item:getFullType()==ProjectYakuza.TOKEN
end
function ProjectYakuza.getPlayerStyle(player)
    local data = player:getModData()
    local id = data.ProjectYakuzaStyle or "dragon_of_dojima"
    local style=ProjectYakuza.styles[id]
    style=ProjectYakuza.Weapons and ProjectYakuza.Weapons.forPlayer(player,style) or style
    if style and not style.weaponProfile and style.extremeLightAttacks and ProjectYakuza.Heat and ProjectYakuza.Heat.states and ProjectYakuza.Heat.states[player] and ProjectYakuza.Heat.states[player].extreme then
        ProjectYakuza.extremeViews=ProjectYakuza.extremeViews or setmetatable({}, {__mode="k"})
        local view=ProjectYakuza.extremeViews[style]
        if not view then view={};for k,v in pairs(style)do view[k]=v end;view.lightAttacks=style.extremeLightAttacks;view.extremeView=true;ProjectYakuza.extremeViews[style]=view end
        return view
    end
    return style
end
function ProjectYakuza.isEquipped(player)
    if ProjectYakuza.Network and not player:isLocalPlayer() then return ProjectYakuza.Network.remoteEquipped(player) end
    local item = player:getPrimaryHandItem()
    local id=player:getModData().ProjectYakuzaStyle
    local style=ProjectYakuza.styles[id or "dragon_of_dojima"]
    local equipped=style~=nil and (ProjectYakuza.isStyleToken(item) or (id~=nil and ProjectYakuza.Weapons and ProjectYakuza.Weapons.profile(id,item)~=nil)) or false
    if equipped and isClient and isClient() and ProjectYakuza.Network and ProjectYakuza.Network.equipmentReady then
        return ProjectYakuza.Network.equipmentReady(player)
    end
    return equipped
end
function ProjectYakuza.selectStyle(player, id)
    if id ~= "none" and not ProjectYakuza.styles[id] then return false, "unknown_style" end
    if ProjectYakuza.isBusy and ProjectYakuza.isBusy(player) then return false, "busy" end
    player:getModData().ProjectYakuzaStyle = id
    if ProjectYakuza.resetPlayer then ProjectYakuza.resetPlayer(player, "style_changed") end
    ProjectYakuza.emit("styleChanged", player, id)
    return true
end
function ProjectYakuza.registerActionHandler(kind, handler)
    assert(ProjectYakuza.actionKinds[kind], "unknown action kind")
    assert(type(handler) == "table" and type(handler.start) == "function", "handler.start required")
    assert(handler.canStart==nil or type(handler.canStart)=="function","handler.canStart must be a function")
    assert(handler.cancel==nil or type(handler.cancel)=="function","handler.cancel must be a function")
    assert(handler.update==nil or type(handler.update)=="function","handler.update must be a function")
    ProjectYakuza.actionHandlers[kind] = handler
end

function ProjectYakuza.registerActionKind(kind,options)
    assert(type(kind)=="string" and string.match(kind,"^[%w_.-]+$"),"namespaced action kind required")
    assert(options==nil or type(options)=="table","action options must be a table")
    local old=ProjectYakuza.actionDefinitions[kind]
    if ProjectYakuza.actionKinds[kind] and not old then
        assert(options==nil,"built-in action policies cannot be replaced; use a namespaced kind")
        return nil
    end
    local blocked=not options or options.blocksAttacks~=false
    if options then
        for key in pairs(options) do assert(key=="blocksAttacks","unknown action option: "..tostring(key)) end
        assert(options.blocksAttacks==nil or type(options.blocksAttacks)=="boolean","blocksAttacks must be boolean")
    end
    if old then
        assert(not options or old.blocksAttacks==blocked,"action kind already has a different policy")
        return old
    end
    ProjectYakuza.actionKinds[kind]=true
    local definition={blocksAttacks=blocked}
    ProjectYakuza.actionDefinitions[kind]=definition
    return definition
end
function ProjectYakuza.isCustomAction(player)
    local c=ProjectYakuza.activeActions[player]
    return c~=nil and ProjectYakuza.actionDefinitions[c.kind]~=nil
end
function ProjectYakuza.blocksNativeAttacks(player)
    if player:GetVariable("ProjectYakuzaHeatRushVictim")=="true"then return true end
    if ProjectYakuza.StyleEntry and ProjectYakuza.StyleEntry.pending and ProjectYakuza.StyleEntry.pending[player] then return true end
    if ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.isCancelling and ProjectYakuza.Quicksteps.isCancelling(player) then return true end
    local c=ProjectYakuza.activeActions[player]
    local d=c and ProjectYakuza.actionDefinitions[c.kind]
    return c~=nil and (c.kind=="styleEntry" or c.kind=="heatAction" or c.kind=="quickstepAttack" or c.kind=="heavyCharge" or c.kind=="chargedHeavy" or (d~=nil and d.blocksAttacks)) or false
end

function ProjectYakuza.updateCustomAction(player)
    local c=ProjectYakuza.activeActions[player]
    if not c or not ProjectYakuza.actionDefinitions[c.kind] then return false end
    if isGamePaused() then return true end
    if (player:getHitReaction() or "")~="" then
        ProjectYakuza.cancelAction(player,"hit_reaction",c);return true
    end
    if c.handler.update then
        local ok,err=pcall(c.handler.update,c)
        if not ok then
            print("[ProjectYakuza] custom action update error: "..tostring(err))
            ProjectYakuza.cancelAction(player,"update_failed",c)
        end
    end
    return true
end
function ProjectYakuza.registerStyleActionHandler(styleId,kind,handler)
    assert(type(styleId)=="string" and styleId~="","style ID required")
    assert(ProjectYakuza.actionKinds[kind],"unknown action kind")
    assert(type(handler)=="table" and type(handler.start)=="function","handler.start required")
    assert(handler.canStart==nil or type(handler.canStart)=="function","handler.canStart must be a function")
    assert(handler.cancel==nil or type(handler.cancel)=="function","handler.cancel must be a function")
    assert(handler.update==nil or type(handler.update)=="function","handler.update must be a function")
    ProjectYakuza.styleActionHandlers[styleId]=ProjectYakuza.styleActionHandlers[styleId] or {}
    ProjectYakuza.styleActionHandlers[styleId][kind]=handler
end
function ProjectYakuza.getActionHandler(styleId,kind)
    local handlers=ProjectYakuza.styleActionHandlers[styleId]
    return handlers and handlers[kind] or ProjectYakuza.actionHandlers[kind]
end
function ProjectYakuza.registerStyleInputHandler(styleId,handler)
    assert(type(styleId)=="string" and styleId~="","style ID required")
    assert(type(handler)=="function","input handler must be a function")
    ProjectYakuza.styleInputHandlers[styleId]=handler
end
function ProjectYakuza.handleStyleInput(player,input)
    local style=ProjectYakuza.getPlayerStyle(player)
    local handler=style and ProjectYakuza.styleInputHandlers[style.id]
    if not handler then return false end
    local ok,consumed=pcall(handler,player,input)
    if not ok then print("[ProjectYakuza] style input handler error: "..tostring(consumed));return false end
    return consumed==true
end
function ProjectYakuza.getHeat(player) return player:getModData().ProjectYakuzaHeat or 0 end
function ProjectYakuza.setHeat(player, value)
    if ProjectYakuza.Heat and ProjectYakuza.Heat.isExtreme(player) and value>ProjectYakuza.getHeat(player) then return false end
    player:getModData().ProjectYakuzaHeat = math.max(0, math.min(100, value))
    ProjectYakuza.emit("heatChanged", player, ProjectYakuza.getHeat(player))
end

function ProjectYakuza.requestAction(player, kind, variant, target)
    if kind=="grab" and ProjectYakuza.FEATURES.grab==false then return false,"temporarily_disabled" end
    if not ProjectYakuza.actionKinds[kind] then return false, "unknown_action" end
    if not ProjectYakuza.isEquipped(player) then return false, "style_not_equipped" end
    if ProjectYakuza.isBusy and ProjectYakuza.isBusy(player) then return false, "busy" end
    local style = ProjectYakuza.getPlayerStyle(player)
    local slot = style.actions[kind]
    if not slot or slot.enabled ~= true then return false, "not_implemented" end
    local action = slot
    if slot.variants then action = slot.variants[variant or "default"] end
    if not action or action.enabled == false then return false, "unknown_variant" end
    if type(action.animation) ~= "string" or action.animation == "" then return false, "missing_animation" end
    if action.requiresTarget and not target then return false, "target_required" end
    if action.requiresTarget and not action.targetAnimation then return false, "missing_target_animation" end
    local handler = ProjectYakuza.getActionHandler(style.id,kind)
    if not handler then return false, "missing_handler" end
    local cost = action.heatStocks and action.heatStocks*(ProjectYakuza.Heat and ProjectYakuza.Heat.stockSize(player) or ProjectYakuza.HeatRules.stockSize(style)) or action.heatCost or 0
    if ProjectYakuza.getHeat(player) < cost then return false, "insufficient_heat" end
    local combo = ProjectYakuza.stateFor and ProjectYakuza.stateFor(player) or nil
    local comboStep = combo and combo.step or 0
    if action.afterLight and style.finisherBranches and comboStep>style.finisherBranches then comboStep=(comboStep-1)%style.finisherBranches+1 end
    if action.afterLight then
        if comboStep ~= action.afterLight then return false, "wrong_combo_step" end
        if not combo.finishedAt or getTimestampMs() - combo.finishedAt > style.comboResetMs then return false, "combo_window_closed" end
    end
    local context = { player=player, style=style, kind=kind, variant=variant, action=action, target=target, comboStep=comboStep, handler=handler }
    if handler.canStart then
        local ok, allowed, reason = pcall(handler.canStart, context)
        if not ok then return false, "handler_error" end
        if not allowed then return false, reason or "requirements_not_met" end
    end
    local ok, started, reason = pcall(handler.start, context)
    if not ok or started~=true then
        if handler.cancel then
            local cleaned,err=pcall(handler.cancel,context,"start_failed")
            if not cleaned then print("[ProjectYakuza] failed-start cleanup error: "..tostring(err)) end
        end
        if not ok then print("[ProjectYakuza] action handler error: "..tostring(started));return false,"handler_error" end
        return false,reason or "start_failed"
    end
    ProjectYakuza.activeActions[player] = context
    if ProjectYakuza.blocksNativeAttacks(player) and ProjectYakuza.Bindings then ProjectYakuza.Bindings.update(player) end
    if cost>0 then ProjectYakuza.setHeat(player, ProjectYakuza.getHeat(player) - cost) end
    ProjectYakuza.emit("actionStarted", context)
    return true
end
function ProjectYakuza.completeAction(player,expectedContext)
    local context = ProjectYakuza.activeActions[player]
    if expectedContext and context~=expectedContext then return false end
    if not context then return false end
    ProjectYakuza.activeActions[player] = nil
    ProjectYakuza.emit("actionCompleted", context)
    return true
end
function ProjectYakuza.cancelAction(player, reason,expectedContext)
    local context = ProjectYakuza.activeActions[player]
    if expectedContext and context~=expectedContext then return false end
    if not context then return false end
    ProjectYakuza.activeActions[player] = nil
    local handler = context.handler or ProjectYakuza.getActionHandler(context.style.id,context.kind)
    if handler and handler.cancel then
        local ok, err = pcall(handler.cancel, context, reason)
        if not ok then print("[ProjectYakuza] cancellation error: " .. tostring(err)) end
    end
    ProjectYakuza.emit("actionCancelled", context, reason)
    return true
end

require "ProjectYakuza/Weapons"

require "ProjectYakuza/StyleItemPolicy"
