require "DCF/Registry"
local DCF=DragonCombat
local H={states=setmetatable({}, {__mode="k"})}
DCF.Heat=H
H.config={maxStocks=6,gainPerDamage=2.5,lossPerDamage=0.5,idleGraceMs=3000,idleLossPerSecond=4,
    knockdownLoss=8,secondsPerStock=3.75,attackFuelCost=1.5,extremeDamage=1.5,extremeSpeed=1.2}
local function time()return getTimestampMs()end
function H.enabled(p)local style=DCF.getPlayerStyle(p);return style and style.heat==true or false end
function H.playback(p,extreme)
    local style=DCF.getPlayerStyle(p) or {}
    local speed=style.attackSpeed or 1
    local factor=extreme and H.config.extremeSpeed or 1
    p:setVariable("DCFCombatSpeed",speed*factor)
    p:setVariable("DCFRunningKneeSpeed",(style.runningKneeSpeed or speed)*factor)
end
local function state(p)
    local s=H.states[p]
    if not s then s={lastAction=time(),nextUpdate=0};H.states[p]=s end
    return s
end
function H.stockSize()return 100/H.config.maxStocks end
function H.stocks(p)return math.min(H.config.maxStocks,math.floor((DCF.getHeat(p)+0.000001)/H.stockSize()))end
function H.isExtreme(p)local s=H.states[p];return s and s.extreme==true or false end
function H.display(p)local s=H.states[p];return s and s.extreme and s.fuel or DCF.getHeat(p)end
function H.restoreMoveDamage(item)
    if not item or item:getFullType()~=DCF.TOKEN then return end
    local d=item:getModData()
    if d.DCFMoveOriginalMin~=nil then
        item:setMinDamage(d.DCFMoveOriginalMin);item:setMaxDamage(d.DCFMoveOriginalMax)
        d.DCFMoveOriginalMin=nil;d.DCFMoveOriginalMax=nil
    end
end
function H.applyMoveDamage(p,move)
    local item=p:getPrimaryHandItem();local s=state(p)
    H.restoreMoveDamage(item)
    local factor=move and move.damageMultiplier or 1
    s.damageWeapon=item;s.damageMultiplier=factor
    if factor~=1 and item and item:getFullType()==DCF.TOKEN then
        local d=item:getModData()
        d.DCFMoveOriginalMin=item:getMinDamage();d.DCFMoveOriginalMax=item:getMaxDamage()
        item:setMinDamage(d.DCFMoveOriginalMin*factor);item:setMaxDamage(d.DCFMoveOriginalMax*factor)
    end
end
function H.endSwing(p)
    local s=H.states[p];if not s then return end
    H.restoreMoveDamage(s.damageWeapon);s.damageWeapon=nil;s.damageMultiplier=nil
end
function H.prepareToken(item)
    if not item or item:getFullType()~=DCF.TOKEN then return end
    H.restoreMoveDamage(item)
    local d=item:getModData()
    if d.DCFHeatOriginalMin~=nil then
        item:setMinDamage(d.DCFHeatOriginalMin);item:setMaxDamage(d.DCFHeatOriginalMax)
        d.DCFHeatOriginalMin=nil;d.DCFHeatOriginalMax=nil
    end
end
local function initialize(p,s)
    if s.initialized then return end
    s.initialized=true
    local d=p:getModData()
    if d.DCFHeatOldStagger~=nil then p:setIgnoreStaggerBack(d.DCFHeatOldStagger);d.DCFHeatOldStagger=nil end
    if DCF.isEquipped(p) then H.prepareToken(p:getPrimaryHandItem()) end
    H.playback(p,false)
end
function H.stop(p,reason)
    local s=H.states[p]
    if not s or not s.extreme then return false end
    local factor=s.damageMultiplier
    s.extreme=false;s.fuel=0
    H.prepareToken(s.weapon);s.weapon=nil
    p:setIgnoreStaggerBack(s.oldStagger==true)
    p:getModData().DCFHeatOldStagger=nil
    H.playback(p,false)
    local combo=DCF.stateFor and DCF.stateFor(p)
    if factor and combo and combo.active and DCF.isEquipped(p) and not p:isDead() then H.applyMoveDamage(p,{damageMultiplier=factor}) end
    DCF.emit("extremeHeatEnded",p,reason or "depleted")
    return true
end
function H.start(p,activation)
    if not H.enabled(p) then return false,"heat_not_supported" end
    local cinematic=activation and DCF.activeActions[p]==activation and activation.kind=="heatActivation"
        and activation.timedAction and activation.timedAction.started and p:GetVariable("DCFHeatActivation")=="done"
    if not DCF.isEquipped(p) or p:isDead() or (not cinematic and not p:isAiming()) or p:isOnFloor() or p:isKnockedDown()
        or p:isClimbing() or p:getVehicle() or (not cinematic and (p:hasTimedActions() or DCF.isBusy(p))) then return false,"not_ready" end
    local s=state(p);initialize(p,s)
    if s.extreme then return false,"already_active" end
    if H.stocks(p)<1 then return false,"heat_stock_required" end
    local item=p:getPrimaryHandItem();H.prepareToken(item)
    local d=item:getModData()
    d.DCFHeatOriginalMin=item:getMinDamage();d.DCFHeatOriginalMax=item:getMaxDamage()
    item:setMinDamage(d.DCFHeatOriginalMin*H.config.extremeDamage)
    item:setMaxDamage(d.DCFHeatOriginalMax*H.config.extremeDamage)
    s.weapon=item;s.oldStagger=p:isIgnoreStaggerBack()
    p:getModData().DCFHeatOldStagger=s.oldStagger
    s.extreme=true;s.fuel=DCF.getHeat(p);s.lastUpdate=time()
    DCF.setHeat(p,0)
    p:setIgnoreStaggerBack(true);H.playback(p,true)
    DCF.emit("extremeHeatStarted",p,s.fuel)
    return true
end
function H.toggle(p)
    if H.isExtreme(p) then return false,"already_active" end
    if DCF.HeatActivation then return DCF.HeatActivation.request(p) end
    return H.start(p)
end
function H.lose(p,amount)
    if type(amount)~="number" or amount<=0 then return end
    local s=state(p)
    if s.extreme then
        s.fuel=math.max(0,s.fuel-amount)
        if s.fuel<=0 then H.stop(p) end
        return
    end
    -- Completed stocks are banked; only the unfinished stock can fall away.
    local heat=DCF.getHeat(p);local floor=H.stocks(p)*H.stockSize()
    local value=math.max(floor,heat-amount)
    if math.abs(value-heat)>0.000001 then DCF.setHeat(p,value) end
end
function H.onSwing(p,move)
    local s=state(p);initialize(p,s);s.lastAction=time()
    if s.extreme then H.lose(p,H.config.attackFuelCost)
    else H.prepareToken(p:getPrimaryHandItem());H.playback(p,false) end
    H.applyMoveDamage(p,move)
end
function H.onHit(p,victim,damage,combo)
    if not H.enabled(p) then return end
    if not combo.active or not victim or not instanceof(victim,"IsoZombie")
        or type(damage)~="number" or damage<=0 then return end
    local s=state(p);s.lastAction=time()
    if s.extreme then return end
    combo.heatVictims=combo.heatVictims or setmetatable({}, {__mode="k"})
    if combo.heatVictims[victim] then return end
    combo.heatVictims[victim]=true
    DCF.setHeat(p,DCF.getHeat(p)+math.min(damage,2)*H.config.gainPerDamage)
end
function H.onDamage(p,kind,damage)
    if not p or not instanceof(p,"IsoPlayer") or not p:isLocalPlayer() or not DCF.isEquipped(p) or not H.enabled(p) then return end
    if kind=="BLEEDING" or kind=="HUNGRY" or kind=="THIRST" or kind=="SICKNESS" or kind=="POISON" then return end
    H.lose(p,(tonumber(damage) or 0)*H.config.lossPerDamage)
end
function H.update(p)
    if not p or not instanceof(p,"IsoPlayer") or not p:isLocalPlayer() then return end
    local s=state(p);local t=time();local equipped=DCF.isEquipped(p)
    initialize(p,s)
    local down=equipped and H.enabled(p) and p:isAiming() and (DCF.Bindings and DCF.Bindings.down("extremeHeat") or (not DCF.Bindings and isKeyDown(Keyboard.KEY_N)))
    if down and not s.keyDown then H.toggle(p) end
    s.keyDown=down
    if t<s.nextUpdate then return end
    s.nextUpdate=t+100
    if DCF.HeatAura then DCF.HeatAura.update(p) end
    local elapsed=math.max(0,math.min(0.25,(t-(s.lastUpdate or t))/1000));s.lastUpdate=t
    if p:isDead() then H.stop(p,"death");if DCF.getHeat(p)>0 then DCF.setHeat(p,0) end;return end
    if not H.enabled(p) then H.stop(p,"style_without_heat");return end
    local action=DCF.activeActions[p]
    if action and action.kind=="heatActivation" then s.lastAction=t;return end
    if action and action.kind=="taunt" then s.lastAction=t end
    if s.extreme then
        if not equipped or p:getPrimaryHandItem()~=s.weapon or p:getVehicle() then H.stop(p,"unequipped");return end
        H.lose(p,elapsed*H.stockSize()/H.config.secondsPerStock)
    elseif equipped and DCF.getHeat(p)>0 and t-s.lastAction>H.config.idleGraceMs then
        H.lose(p,elapsed*H.config.idleLossPerSecond)
    end
    if equipped and (H.isExtreme(p) or DCF.getHeat(p)>0) then
        local knocked=p:isOnFloor() or p:isKnockedDown()
        if knocked and not s.knocked then H.lose(p,H.config.knockdownLoss) end
        s.knocked=knocked
    else s.knocked=false end
end
Events.OnPlayerUpdate.Add(H.update)
Events.OnPlayerGetDamage.Add(H.onDamage)
DCF.on("styleChanged",function(p)H.stop(p,"style_changed");H.playback(p,false)end)
