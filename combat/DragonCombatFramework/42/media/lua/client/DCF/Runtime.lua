require "DCF/Registry"
require "DCF/Combo"
require "DCF/Styles/DragonOfDojima"
require "DCF/Reactions"
require "DCF/Heat"
require "DCF/Bindings"
local DCF = DragonCombat
local B=DCF.Bindings
local Combo = DCF.Combo
DCF.states = DCF.states or {}
DCF.visuals = DCF.visuals or setmetatable({}, {__mode="k"})
DCF.finisherDown = DCF.finisherDown or {}
DCF.finisherHandoffs = DCF.finisherHandoffs or setmetatable({}, {__mode="k"})
function DCF.releaseFinisherHandoff(player)
    local handoff=DCF.finisherHandoffs[player]
    if handoff then player:setIgnoreMovement(handoff.oldIgnore==true);DCF.finisherHandoffs[player]=nil end
end
DCF.groundNext = DCF.groundNext or {}
DCF.FINISHER_MOUSE_BUTTON = 2
local function now() return getTimestampMs() end
local function localPlayer(player)
    return player and instanceof(player, "IsoPlayer") and player:isLocalPlayer()
end
function DCF.stateFor(player)
    local id = player:getPlayerNum()
    if not DCF.states[id] then DCF.states[id] = Combo.new() end
    return DCF.states[id]
end
local function variable(player, name) return player:GetVariable(name) or "" end
local function trace(player, message, important)
    if not important and not player:getModData().DCFDiagnostics then return end
    print("[DCF] p" .. tostring(player:getPlayerNum()) .. " " .. message)
end
function DCF.isBusy(player)
    local s = DCF.stateFor(player)
    return s.active or s.starting or DCF.activeActions[player] ~= nil
end
-- PZ DoAttack checks the same native authorization used to suppress Space.
-- Lift only our own temporary shove gate, and always restore it after the call.
function DCF.attemptAttack(player)
    local saved=(B and B.attackGates[player]) or (DCF.Quicksteps and DCF.Quicksteps.shoveAuth and DCF.Quicksteps.shoveAuth[player])
    if not saved or not saved.allowed or not DCF.isEquipped(player) or player:isAuthorizeMeleeAction() then return player:AttemptAttack() end
    player:setAuthorizeMeleeAction(true)
    local ok,result=pcall(player.AttemptAttack,player)
    player:setAuthorizeMeleeAction(false)
    if not ok then error(result) end
    return result
end
function DCF.setVisual(player, active, move)
    local state=DCF.visuals[player]
    if not state then state={};DCF.visuals[player]=state end
    if state.active~=active then player:setVariable("DCFActive",active);state.active=active end
    if not active and state.style~=nil then player:setVariable("DCFStyle","");state.style=nil end
    if move~=nil and state.move~=move then player:setVariable("DCFMove",move);state.move=move end
end
function DCF.resetPlayer(player, reason)
    local s = DCF.stateFor(player)
    DCF.releaseFinisherHandoff(player)
    DCF.Heat.endSwing(player)
    if DCF.Quicksteps then DCF.Quicksteps.pending[player]=nil end
    if DCF.RunningAttacks then DCF.RunningAttacks.finish(player) end
    if s.groundMove or s.finisherMove or s.pendingFinisher then player:setBlockMovement(false) end
    Combo.reset(s)
    DCF.setVisual(player,false,"")
    player:setVariable("DCFClipStarted", "")
    player:setVariable("DCFHitMarker", "")
    player:setVariable("DCFChainReady", "")
    player:setVariable("DCFDoubleReady", "")
    DCF.cancelAction(player, reason or "reset")
    DCF.emit("comboCancelled", player, reason)
end
-- Old saves retain the literal "null" sprite from v0.3.0.
function DCF.prepareToken(token)
    if token and token:getFullType()==DCF.TOKEN and token:getMaxHitCount()~=DCF.MAX_HIT_COUNT then token:setMaxHitCount(DCF.MAX_HIT_COUNT) end
    if token and token:getFullType() == DCF.TOKEN and token:getWeaponSprite() ~= "DCF_EmptyHand" then
        token:setWeaponSprite("DCF_EmptyHand")
        token:setOriginalWeaponSprite("DCF_EmptyHand")
        return true
    end
    return false
end
local function setReadyVariables(player, style, s)
    local move = s.groundMove or s.finisherMove or s.pendingFinisher or style.lightAttacks[s.step > 0 and s.step or 1]
    DCF.setVisual(player,true,move.nodeValue)
    local visual=DCF.visuals[player]
    local linked=move.double==true and DCF.finisherHandoffs[player]~=nil
    if visual.linkedDouble~=linked then player:setVariable("DCFLinkedDouble",linked);visual.linkedDouble=linked end
    if visual.style~=style.id then player:setVariable("DCFStyle",style.id);visual.style=style.id end
    local enabled=style.groundAttacks~=nil
    if visual.groundEnabled~=enabled then player:setVariable("DFCGroundEnabled",enabled);visual.groundEnabled=enabled end
    local index=DCF.groundNext[player:getPlayerNum()] or 1
    if enabled and visual.groundIndex~=index then player:setVariable("DCFStompVariant",tostring(index));visual.groundIndex=index end
end
-- Poll in both update and OnWeaponSwing: native swing events can precede the Lua update.
local function pollPress(player, style, s)
    local down = B.down("light")
    if DCF.activeActions[player] and DCF.activeActions[player].kind=="quickstep" then return end
    if down and not s.lastDown and player:isAiming() and not s.groundMove and not s.finisherMove and not s.pendingFinisher and not s.queuedFinisher and not s.queuedDouble then Combo.press(s, #style.lightAttacks, style.lightBufferLimit) end
    s.lastDown = down
end
local function onSwing(player, weapon)
    if not localPlayer(player) or not DCF.isEquipped(player) then return end
    if not weapon or weapon:getFullType() ~= DCF.TOKEN then return end
    local style, s = DCF.getPlayerStyle(player), DCF.stateFor(player)
    s.groundMove=nil
    pollPress(player, style, s)
    -- Every accepted native attack gets its own collision/armor/LOS calculation.
    local move
    if s.pendingFinisher then
        move = s.pendingFinisher
        s.pendingFinisher, s.finisherMove = nil, move
        s.active, s.starting, s.startedAt, s.finishedAt = true, false, now(), nil
        s.queued, s.queuedFinisher = 0, nil
    else
        s.finisherBranch, s.finisherFinishedAt = nil, nil
        move = Combo.begin(s, style, now())
    end
    s.multiHitToken={};s.effectVictims=nil
    s.seenClip, s.seenHit, s.confirmedHit, s.recoveryReleased, s.heatVictims = nil, nil, false, false, nil
    if move.runningAttack and DCF.RunningAttacks then DCF.RunningAttacks.onSwing(player,move) end
    if move.double and DCF.finisherHandoffs[player] then DCF.finisherHandoffs[player].playingDouble=true end
    DCF.Heat.onSwing(player,move)
    player:setVariable("DCFClipStarted", "")
    player:setVariable("DCFHitMarker", "")
    player:setVariable("DCFChainReady", "")
    player:setVariable("DCFDoubleReady", "")
    setReadyVariables(player, style, s)
    trace(player, "swing style=" .. style.id .. " step=" .. s.step .. " move=" .. move.nodeValue .. " queued=" .. s.queued)
    if move.runningAttack then DCF.emit("runningAttackStarted",player,style,move)
    elseif move.quickstepAttack then DCF.emit("quickstepAttackStarted", player, style, move)
    elseif s.finisherMove then DCF.emit("finisherStarted", player, style, s.step, move)
    else DCF.emit("lightAttackStarted", player, style, s.step, move) end
end
local function onFinished(player, weapon)
    if not localPlayer(player) then return end
    DCF.Heat.endSwing(player)
    local s = DCF.stateFor(player)
    if s.active and s.groundMove then
        local move=s.groundMove
        player:setBlockMovement(false)
        Combo.reset(s)
        local style=DCF.getPlayerStyle(player)
        DCF.groundNext[player:getPlayerNum()]=((DCF.groundNext[player:getPlayerNum()] or 1)%#style.groundAttacks)+1
        DCF.emit("groundAttackFinished",player,move)
        return
    end
    if s.active and s.finisherMove then
        local move, step, followup = s.finisherMove, s.step, s.queuedDouble
        if move.double or not followup then DCF.releaseFinisherHandoff(player) end
        player:setBlockMovement(false)
        if move.runningAttack and DCF.RunningAttacks then DCF.RunningAttacks.finish(player) end
        DCF.completeAction(player)
        Combo.reset(s)
        if not move.double and not move.quickstepAttack and not move.runningAttack then
            s.finisherBranch, s.finisherFinishedAt = step, now()
            if followup then s.step, s.finishedAt, s.queuedDouble = step, now(), true end
        end
        trace(player, "finisher finished after light=" .. step .. " double=" .. tostring(move.double == true))
        if followup then player:setMeleeDelay(0) end
        if move.runningAttack then DCF.emit("runningAttackFinished",player,move)
        elseif move.quickstepAttack then DCF.emit("quickstepAttackFinished", player, move)
        else DCF.emit("finisherFinished", player, step, move) end
        return
    end
    if Combo.finish(s, now()) then
        trace(player, "finished step=" .. s.step .. " queued=" .. s.queued)
        DCF.emit("lightAttackFinished", player, s.step)
    end
end
function DCF.queueFinisher(player)
    if not DCF.isEquipped(player) or not player:isAiming() or player:isDead() then return false, "not_ready" end
    local s, style = DCF.stateFor(player), DCF.getPlayerStyle(player)
    local slot = style.actions.finisher
    if not slot or not slot.enabled then return false, "not_implemented" end
    local first = s.finisherMove or s.pendingFinisher
    if s.groundMove or (first and (first.quickstepAttack or first.runningAttack)) then return false,"busy" end
    local branch = first and first.afterLight or s.queuedFinisher or s.finisherBranch
    if first or s.queuedFinisher or s.finisherBranch then
        if (first and first.double) or s.queuedDouble then return false, "finisher_limit" end
        if not first and not s.queuedFinisher and now() - s.finisherFinishedAt > style.comboResetMs then return false, "combo_window_closed" end
        local double = slot.variants and slot.variants["double_after_" .. branch]
        if not double or not double.enabled then return false, "not_implemented" end
        s.queuedDouble = true
        if not first and not s.queuedFinisher then s.step, s.finishedAt = branch, s.finisherFinishedAt end
        trace(player, "queued double finisher after light=" .. branch)
        DCF.tryRecoveryCancel(player,style,s)
        return true
    end
    if s.step < 1 or DCF.activeActions[player] then return false, "no_light_branch" end
    branch = math.min(#style.lightAttacks, s.step + s.queued)
    local move = slot.variants and slot.variants["after_" .. branch]
    if not move or not move.enabled then return false, "not_implemented" end
    if not s.active and (not s.finishedAt or now() - s.finishedAt > style.comboResetMs) then return false, "combo_window_closed" end
    s.queuedFinisher = branch
    trace(player, "queued finisher after light=" .. branch)
    return true
end
-- Only release recovery after the clip itself has passed its hit and chain markers.
-- The normal ActionGroup transition and SwipeStatePlayer.exit handle native cleanup.
function DCF.tryRecoveryCancel(player, style, s)
    if not s.active or s.groundMove or s.recoveryReleased or not player:isAiming() then return false end
    local move = s.groundMove or s.finisherMove or style.lightAttacks[s.step]
    local finisher=s.finisherMove~=nil
    local queued = finisher and (not move.double and s.queuedDouble) or (not finisher and (s.queued > 0 or s.queuedFinisher ~= nil))
    local marker=finisher and "DCFDoubleReady" or "DCFChainReady"
    if not queued or variable(player, marker) ~= move.nodeValue
        or variable(player, "DCFHitMarker") ~= move.nodeValue then return false end
    if finisher then
        DCF.finisherHandoffs[player]={oldIgnore=player:getIgnoreMovement(),deadline=now()+600,branch=s.step}
        player:setIgnoreMovement(true)
    end
    s.recoveryReleased = true
    player:setMeleeDelay(0)
    player:setPerformingAttackAnimation(false)
    player:reportEvent("ActiveAnimFinishing")
    trace(player, "early recovery exit " .. move.nodeValue)
    return true
end
local nativeAttackHandler = {
    canStart = function(context)
        local s = DCF.stateFor(context.player)
        if context.action.runningAttack then
            local R=DCF.RunningAttacks
            local ticket=R and R.tickets[context.player]
            if not ticket or context.target~=ticket or ticket.variant~=context.action.variant or ticket.expiresAt<now()
                or not R.ready(context.player) then return false,"running_required" end
        end
        if context.action.quickstepAttack then
            local pending=DCF.Quicksteps and DCF.Quicksteps.pending[context.player]
            if not pending or context.target~=pending or pending.expiresAt<now() then return false,"quickstep_required" end
        end
        if context.action.double and (s.finisherBranch ~= context.comboStep or not s.finisherFinishedAt
            or now() - s.finisherFinishedAt > context.style.comboResetMs) then return false, "first_finisher_required" end
        return (context.action.runningAttack or context.player:isAiming()) and context.player:isWeaponReady() and not context.player:isAttackStarted()
            and not context.player:isPerformingAttackAnimation(), "native_attack_busy"
    end,
    start = function(context)
        local player, s = context.player, DCF.stateFor(context.player)
        if context.action.runningAttack then Combo.reset(s);DCF.RunningAttacks.beforeStart(context) end
        s.pendingFinisher, s.starting, s.startRequestedAt = context.action, true, now()
        setReadyVariables(player, context.style, s)
        if context.action.double or context.action.quickstepAttack or context.action.runningAttack then player:setMeleeDelay(0) end
        if context.action.runningAttack then return true end
        DCF.attemptAttack(player)
        if not s.active and not player:isAttackStarted() then
            s.pendingFinisher, s.starting = nil, false
            setReadyVariables(player, context.style, s)
            return false, "native_attack_rejected"
        end
        return true
    end,
    cancel = function(context)
        local s = DCF.stateFor(context.player)
        DCF.releaseFinisherHandoff(context.player)
        DCF.Heat.endSwing(context.player)
        context.player:setBlockMovement(false)
        if context.action.runningAttack and DCF.RunningAttacks then DCF.RunningAttacks.finish(context.player) end
        s.pendingFinisher, s.finisherMove, s.queuedFinisher, s.queuedDouble, s.starting = nil, nil, nil, nil, false
        s.finisherBranch, s.finisherFinishedAt = nil, nil
    end,
}
DCF.registerActionHandler("finisher", nativeAttackHandler)
DCF.registerActionHandler("quickstepAttack", nativeAttackHandler)
DCF.registerActionHandler("runningAttack", nativeAttackHandler)
-- SwipeStatePlayer publishes AimFloorAnim after OnWeaponSwing. Read the native getter
-- after entry; do not use the inaccessible Java fields on AttackVars.
function DCF.syncGroundAttack(player,style,s)
    if not style.groundAttacks or s.groundMove or not player:isAimAtFloor()
        or not (player:isAttackStarted() or player:isPerformingStompAnimation()) then return false end
    local move=style.groundAttacks[DCF.groundNext[player:getPlayerNum()] or 1]
    local hadSwing=s.active
    if DCF.RunningAttacks then DCF.RunningAttacks.finish(player) end
    if DCF.activeActions[player] then DCF.completeAction(player) end
    Combo.reset(s)
    s.active=true;s.startedAt=now();s.groundMove=move;s.multiHitToken={}
    if not hadSwing then DCF.Heat.onSwing(player,move) else DCF.Heat.applyMoveDamage(player,move) end
    setReadyVariables(player,style,s)
    DCF.emit("groundAttackStarted",player,style,move)
    return true
end
local function onUpdate(player)
    if not localPlayer(player) then return end
    if DCF.TigerDrop then DCF.TigerDrop.track(player) end
    local s = DCF.stateFor(player)
    local counterPressed=B.pressed(player,"counter")
    local throwPressed=B.pressed(player,"throw")
    local finisherDown = B.down("finisher")
    local finisherPressed = finisherDown and not DCF.finisherDown[player:getPlayerNum()]
    DCF.finisherDown[player:getPlayerNum()] = finisherDown
    if not DCF.isEquipped(player) or player:isDead() then
        if s.active or s.starting or s.step > 0 or DCF.activeActions[player] then DCF.resetPlayer(player, "unequipped_or_dead") end
        DCF.setVisual(player,false)
        s.lastDown = B.down("light")
        return
    end
    if DCF.StyleSelector and (DCF.StyleSelector.wheel or DCF.StyleSelector.setup) then s.lastDown=B.down("light");return end
    local handoff=DCF.finisherHandoffs[player]
    if handoff then
        local reaction=player:getHitReaction()
        if (not handoff.playingDouble and now()>handoff.deadline) or player:isOnFloor() or player:isKnockedDown()
            or player:isClimbing() or player:getVehicle() or (reaction and reaction~="") then DCF.releaseFinisherHandoff(player) end
    end
    local token = player:getPrimaryHandItem()
    if DCF.prepareToken(token) then
        player:resetModelNextFrame()
        trace(player, "migrated saved style item to DCF_EmptyHand")
    end
    local style = DCF.getPlayerStyle(player)
    if isClient() and DCF.Network and not DCF.Network.equipmentReady(player) then return end
    setReadyVariables(player, style, s)
    if DCF.styleInputHandlers[style.id] and DCF.handleStyleInput(player,{
        aiming=player:isAiming(),lightDown=B.down("light"),
        heavyPressed=finisherPressed,heavyDown=finisherDown,
    }) then s.lastDown=B.down("light");return end
    if DCF.Defense and DCF.Defense.update(player,throwPressed) then s.lastDown=B.down("light");return end
    local context=DCF.activeActions[player]
    if context and (context.kind=="parry" or context.kind=="heatActivation" or context.kind=="taunt") then
        if context.kind=="heatActivation" and DCF.HeatActivation then DCF.HeatActivation.watch(player,context) end
        if context.kind=="taunt" and DCF.Taunts then DCF.Taunts.watch(player,context) end
        s.lastDown=B.down("light");return
    end
    if context and context.kind=="quickstep" then
        if DCF.Quicksteps then DCF.Quicksteps.pollAttack(player,context) end
        if DCF.RunningAttacks then DCF.RunningAttacks.pause(player) end
        s.lastDown=B.down("light")
        return
    end
    if DCF.Quicksteps and DCF.Quicksteps.pending[player] then
        if DCF.RunningAttacks then DCF.RunningAttacks.pause(player) end
        s.lastDown=B.down("light");return
    end
    if DCF.RunningAttacks then DCF.RunningAttacks.update(player) end
    DCF.syncGroundAttack(player,style,s)
    if counterPressed and DCF.TigerDrop and DCF.TigerDrop.tryCounter(player) then s.lastDown=B.down("light");return end
    if finisherPressed then
        DCF.queueFinisher(player)
    end
    pollPress(player, style, s)
    if not player:isAiming() then
        s.queued, s.queuedFinisher, s.queuedDouble = 0, nil, nil
        s.finisherBranch, s.finisherFinishedAt = nil, nil
        if not s.active and not s.starting and (s.step~=0 or s.finishedAt or s.queued~=0) then Combo.reset(s) end
        if not s.active and not s.starting then return end
    end
    local time = now()
    if s.active then
        local clip, hit = variable(player, "DCFClipStarted"), variable(player, "DCFHitMarker")
        if clip ~= "" and clip ~= s.seenClip then s.seenClip = clip; trace(player, "clip-start " .. clip) end
        if hit ~= "" and hit ~= s.seenHit then s.seenHit = hit; trace(player, "collision-marker " .. hit) end
        local move = s.groundMove or s.finisherMove or style.lightAttacks[s.step]
        DCF.tryRecoveryCancel(player, style, s)
        if time - s.startedAt > move.duration * 1000 + 1200 then
            trace(player, "attack timeout; " .. DCF.diagnosticLine(player), true)
            DCF.resetPlayer(player, "attack_timeout")
            return
        end
        -- Exit recovery if another mod omitted OnPlayerAttackFinished, only after the engine actually leaves the attack.
        if time - s.startedAt > move.duration * 1000 and not player:isAttackStarted()
            and not player:isPerformingAttackAnimation() and player:getCurrentStateName() ~= "SwipeStatePlayer" then
            onFinished(player)
        end
    end
    if s.starting and time - (s.startRequestedAt or time) > 350 then
        trace(player, "buffered attack did not reach swing; " .. DCF.diagnosticLine(player), true)
        if s.pendingFinisher then
            DCF.cancelAction(player, "finisher_start_timeout")
            s.pendingFinisher, s.queuedFinisher = nil, nil
        end
        s.starting = false
    end
    if not player:isWeaponReady() and s.pressSerial > (s.lastReadinessWarning or 0) then
        s.lastReadinessWarning = s.pressSerial
        trace(player, "attack blocked: hand model or weapon not ready; " .. DCF.diagnosticLine(player), true)
    end
    if Combo.expire(s, style, time) then DCF.emit("comboExpired", player) end
    if s.queuedDouble and s.finisherFinishedAt and not s.active and not s.starting
        and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        local ok, reason = DCF.requestAction(player, "finisher", "double_after_" .. s.finisherBranch)
        if ok then s.queuedDouble = nil
        elseif reason ~= "native_attack_busy" then
            s.queuedDouble = nil
            trace(player, "double finisher rejected: " .. tostring(reason))
        end
        return
    end
    if s.queuedFinisher == s.step and not s.active and not s.starting and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        local branch = s.queuedFinisher
        local ok, reason = DCF.requestAction(player, "finisher", "after_" .. branch)
        if ok then s.queuedFinisher = nil
        elseif reason ~= "native_attack_busy" then
            s.queuedFinisher = nil
            trace(player, "finisher rejected: " .. tostring(reason))
        end
        return
    end
    if not s.finisherMove and not DCF.activeActions[player] and Combo.canStartBuffered(s, style, time) and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        s.starting, s.startRequestedAt = true, time
        -- Build 42.21 returns false even after submitting a valid attack.
        -- OnWeaponSwing clears starting; otherwise retain the lock until the event or timeout.
        DCF.attemptAttack(player)
        if s.starting and not player:isAttackStarted() then s.starting = false end
    end
end
function DCF.diagnosticLine(player)
    local s, style = DCF.stateFor(player), DCF.getPlayerStyle(player)
    local item = player:getPrimaryHandItem()
    return "v" .. DCF.VERSION .. " item=" .. (item and item:getFullType() or "none")
        .. " style=" .. (style and style.id or "none") .. " step=" .. s.step .. " queued=" .. s.queued
        .. " finisher=" .. tostring(s.finisherMove and s.finisherMove.nodeValue or s.queuedFinisher or "none")
        .. " ready=" .. tostring(player:isWeaponReady()) .. " sprite=" .. tostring(item and item:getWeaponSprite())
        .. " ai=" .. tostring(player:getCurrentStateName()) .. " action=" .. tostring(player:getCurrentActionContextStateName())
        .. " Weapon=" .. variable(player, "Weapon") .. " active=" .. variable(player, "DCFActive")
        .. " move=" .. variable(player, "DCFMove") .. " clip=" .. variable(player, "DCFClipStarted")
        .. " hitMarker=" .. variable(player, "DCFHitMarker") .. " confirmedHit=" .. tostring(s.confirmedHit == true)
end
local function onHit(attacker, victim, weapon, damage)
    if not localPlayer(attacker) or not DCF.isEquipped(attacker) then return end
    local s = DCF.stateFor(attacker)
    if not weapon or (weapon:getFullType() ~= DCF.TOKEN and not (s.groundMove and weapon:getFullType()=="Base.BareHands")) then return end
    s.confirmedHit = true
    DCF.Heat.onHit(attacker,victim,damage,s)
    trace(attacker, "confirmed native hit step=" .. s.step .. " damage=" .. tostring(damage))
    DCF.emit("combatHit", attacker, victim, weapon, damage, s.step)
end
Events.OnWeaponSwing.Add(onSwing)
Events.OnPlayerAttackFinished.Add(onFinished)
Events.OnPlayerUpdate.Add(onUpdate)
Events.OnWeaponHitCharacter.Add(onHit)
print("[DCF] Runtime loaded v" .. DCF.VERSION .. "; styles=" .. #DCF.styleOrder)
