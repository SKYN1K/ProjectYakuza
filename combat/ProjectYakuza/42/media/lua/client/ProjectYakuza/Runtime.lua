require "ProjectYakuza/Registry"
require "ProjectYakuza/Combo"
require "ProjectYakuza/Styles/DragonOfDojima"
require "ProjectYakuza/Reactions"
require "ProjectYakuza/Heat"
require "ProjectYakuza/Bindings"
local ProjectYakuza = ProjectYakuza
local B=ProjectYakuza.Bindings
local Combo = ProjectYakuza.Combo
ProjectYakuza.states = ProjectYakuza.states or {}
ProjectYakuza.visuals = ProjectYakuza.visuals or setmetatable({}, {__mode="k"})
ProjectYakuza.finisherDown = ProjectYakuza.finisherDown or {}
ProjectYakuza.finisherHandoffs = ProjectYakuza.finisherHandoffs or setmetatable({}, {__mode="k"})
function ProjectYakuza.releaseFinisherHandoff(player)
    local handoff=ProjectYakuza.finisherHandoffs[player]
    if handoff then player:setIgnoreMovement(handoff.oldIgnore==true);ProjectYakuza.finisherHandoffs[player]=nil end
end
ProjectYakuza.groundNext = ProjectYakuza.groundNext or {}
ProjectYakuza.FINISHER_MOUSE_BUTTON = 2
local function now() return getTimestampMs() end
local function localPlayer(player)
    return player and instanceof(player, "IsoPlayer") and player:isLocalPlayer()
end
function ProjectYakuza.stateFor(player)
    local id = player:getPlayerNum()
    if not ProjectYakuza.states[id] then ProjectYakuza.states[id] = Combo.new() end
    return ProjectYakuza.states[id]
end
local function variable(player, name) return player:GetVariable(name) or "" end
local function trace(player, message, important)
    if not important and not player:getModData().ProjectYakuzaDiagnostics then return end
    print("[ProjectYakuza] p" .. tostring(player:getPlayerNum()) .. " " .. message)
end
function ProjectYakuza.isBusy(player)
    local s = ProjectYakuza.stateFor(player)
    return s.active or s.starting or ProjectYakuza.activeActions[player] ~= nil
end
-- PZ DoAttack checks the same native authorization used to suppress Space.
-- Lift only our own temporary shove gate, and always restore it after the call.
function ProjectYakuza.attemptAttack(player)
    if ProjectYakuza.blocksNativeAttacks(player) then return false end
    local saved=(B and B.attackGates[player]) or (ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.shoveAuth and ProjectYakuza.Quicksteps.shoveAuth[player])
    if not saved or not saved.allowed or not ProjectYakuza.isEquipped(player) or player:isAuthorizeMeleeAction() then return player:AttemptAttack() end
    player:setAuthorizeMeleeAction(true)
    local ok,result=pcall(player.AttemptAttack,player)
    player:setAuthorizeMeleeAction(false)
    if not ok then error(result) end
    return result
end
function ProjectYakuza.setVisual(player, active, move)
    local state=ProjectYakuza.visuals[player]
    if not state then state={};ProjectYakuza.visuals[player]=state end
    if state.active~=active then player:setVariable("ProjectYakuzaActive",active);state.active=active end
    if not active and state.style~=nil then player:setVariable("ProjectYakuzaStyle","");state.style=nil end
    if move~=nil and state.move~=move then player:setVariable("ProjectYakuzaMove",move);state.move=move end
end
function ProjectYakuza.resetPlayer(player, reason)
    local s = ProjectYakuza.stateFor(player)
    ProjectYakuza.releaseFinisherHandoff(player)
    ProjectYakuza.Heat.endSwing(player)
    if ProjectYakuza.Quicksteps then ProjectYakuza.Quicksteps.pending[player]=nil end
    if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.finish(player) end
    if s.groundMove or s.finisherMove or s.pendingFinisher then player:setBlockMovement(false) end
    Combo.reset(s)
    ProjectYakuza.setVisual(player,false,"")
    player:setVariable("ProjectYakuzaClipStarted", "")
    player:setVariable("ProjectYakuzaHitMarker", "")
    player:setVariable("ProjectYakuzaChainReady", "")
    player:setVariable("ProjectYakuzaDoubleReady", "")
    ProjectYakuza.cancelAction(player, reason or "reset")
    ProjectYakuza.emit("comboCancelled", player, reason)
end
-- Old saves retain the literal "null" sprite from v0.3.0.
function ProjectYakuza.prepareToken(token, player)
    if token and ProjectYakuza.isStyleToken(token) and token:getMaxHitCount()~=ProjectYakuza.MAX_HIT_COUNT then token:setMaxHitCount(ProjectYakuza.MAX_HIT_COUNT) end
    return ProjectYakuza.prepareTokenAppearance(token, player and ProjectYakuza.getPlayerStyle(player))
end
local function setReadyVariables(player, style, s)
    local move = s.groundMove or s.finisherMove or s.pendingFinisher or style.lightAttacks[s.step > 0 and s.step or 1]
    ProjectYakuza.setVisual(player,true,move.nodeValue)
    local visual=ProjectYakuza.visuals[player]
    local linked=move.double==true and ProjectYakuza.finisherHandoffs[player]~=nil
    if visual.linkedDouble~=linked then player:setVariable("ProjectYakuzaLinkedDouble",linked);visual.linkedDouble=linked end
    if visual.style~=style.id then player:setVariable("ProjectYakuzaStyle",style.id);visual.style=style.id end
    local enabled=style.groundAttacks~=nil
    if visual.groundEnabled~=enabled then player:setVariable("DFCGroundEnabled",enabled);visual.groundEnabled=enabled end
    local index=ProjectYakuza.groundNext[player:getPlayerNum()] or 1
    if enabled and visual.groundIndex~=index then player:setVariable("ProjectYakuzaStompVariant",tostring(index));visual.groundIndex=index end
end
-- Poll in both update and OnWeaponSwing: native swing events can precede the Lua update.
local function pollPress(player, style, s)
    local down = B.down("light")
    if ProjectYakuza.activeActions[player] and ProjectYakuza.activeActions[player].kind=="quickstep" then return end
    if down and not s.lastDown and player:isAiming() and not s.groundMove and not s.finisherMove and not s.pendingFinisher and not s.queuedFinisher and not s.queuedDouble then Combo.press(s, #style.lightAttacks, style.lightBufferLimit) end
    s.lastDown = down
end
local function onSwing(player, weapon)
    if not localPlayer(player) or not ProjectYakuza.isEquipped(player) then return end
    if not weapon or not ProjectYakuza.isStyleToken(weapon) then return end
    if ProjectYakuza.blocksNativeAttacks(player) or ProjectYakuza.isCustomAction(player) then return end
    local style, s = ProjectYakuza.getPlayerStyle(player), ProjectYakuza.stateFor(player)
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
    if move.runningAttack and ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.onSwing(player,move) end
    if move.double and ProjectYakuza.finisherHandoffs[player] then ProjectYakuza.finisherHandoffs[player].playingDouble=true end
    ProjectYakuza.Heat.onSwing(player,move)
    player:setVariable("ProjectYakuzaClipStarted", "")
    player:setVariable("ProjectYakuzaHitMarker", "")
    player:setVariable("ProjectYakuzaChainReady", "")
    player:setVariable("ProjectYakuzaDoubleReady", "")
    setReadyVariables(player, style, s)
    trace(player, "swing style=" .. style.id .. " step=" .. s.step .. " move=" .. move.nodeValue .. " queued=" .. s.queued)
    if move.runningAttack then ProjectYakuza.emit("runningAttackStarted",player,style,move)
    elseif move.quickstepAttack then ProjectYakuza.emit("quickstepAttackStarted", player, style, move)
    elseif s.finisherMove then ProjectYakuza.emit("finisherStarted", player, style, s.step, move)
    else ProjectYakuza.emit("lightAttackStarted", player, style, s.step, move) end
end
local function onFinished(player, weapon)
    if not localPlayer(player) then return end
    ProjectYakuza.Heat.endSwing(player)
    local s = ProjectYakuza.stateFor(player)
    if s.active and s.groundMove then
        local move=s.groundMove
        player:setBlockMovement(false)
        Combo.reset(s)
        local style=ProjectYakuza.getPlayerStyle(player)
        ProjectYakuza.groundNext[player:getPlayerNum()]=((ProjectYakuza.groundNext[player:getPlayerNum()] or 1)%#style.groundAttacks)+1
        ProjectYakuza.emit("groundAttackFinished",player,move)
        return
    end
    if s.active and s.finisherMove then
        local move, step, followup = s.finisherMove, s.step, s.queuedDouble
        if move.double or not followup then ProjectYakuza.releaseFinisherHandoff(player) end
        player:setBlockMovement(false)
        if move.runningAttack and ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.finish(player) end
        ProjectYakuza.completeAction(player)
        Combo.reset(s)
        if not move.double and not move.quickstepAttack and not move.runningAttack then
            s.finisherBranch, s.finisherFinishedAt = step, now()
            if followup then s.step, s.finishedAt, s.queuedDouble = step, now(), true end
        end
        trace(player, "finisher finished after light=" .. step .. " double=" .. tostring(move.double == true))
        if followup then player:setMeleeDelay(0) end
        if move.runningAttack then ProjectYakuza.emit("runningAttackFinished",player,move)
        elseif move.quickstepAttack then ProjectYakuza.emit("quickstepAttackFinished", player, move)
        else ProjectYakuza.emit("finisherFinished", player, step, move) end
        return
    end
    if Combo.finish(s, now()) then
        trace(player, "finished step=" .. s.step .. " queued=" .. s.queued)
        ProjectYakuza.emit("lightAttackFinished", player, s.step)
    end
end
function ProjectYakuza.queueFinisher(player)
    if not ProjectYakuza.isEquipped(player) or not player:isAiming() or player:isDead() then return false, "not_ready" end
    local s, style = ProjectYakuza.stateFor(player), ProjectYakuza.getPlayerStyle(player)
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
        ProjectYakuza.tryRecoveryCancel(player,style,s)
        return true
    end
    if s.step < 1 or ProjectYakuza.activeActions[player] then return false, "no_light_branch" end
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
function ProjectYakuza.tryRecoveryCancel(player, style, s)
    if not s.active or s.groundMove or s.recoveryReleased or not player:isAiming() then return false end
    local move = s.groundMove or s.finisherMove or style.lightAttacks[s.step]
    local finisher=s.finisherMove~=nil
    local queued = finisher and (not move.double and s.queuedDouble) or (not finisher and (s.queued > 0 or s.queuedFinisher ~= nil))
    local marker=finisher and "ProjectYakuzaDoubleReady" or "ProjectYakuzaChainReady"
    if not queued or variable(player, marker) ~= move.nodeValue
        or variable(player, "ProjectYakuzaHitMarker") ~= move.nodeValue then return false end
    if finisher then
        ProjectYakuza.finisherHandoffs[player]={oldIgnore=player:getIgnoreMovement(),deadline=now()+600,branch=s.step}
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
        local s = ProjectYakuza.stateFor(context.player)
        if context.action.runningAttack then
            local R=ProjectYakuza.RunningAttacks
            local ticket=R and R.tickets[context.player]
            if not ticket or context.target~=ticket or ticket.variant~=context.action.variant or ticket.expiresAt<now()
                or not R.ready(context.player) then return false,"running_required" end
        end
        if context.action.quickstepAttack then
            local pending=ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.pending[context.player]
            if not pending or context.target~=pending or pending.expiresAt<now() then return false,"quickstep_required" end
        end
        if context.action.double and (s.finisherBranch ~= context.comboStep or not s.finisherFinishedAt
            or now() - s.finisherFinishedAt > context.style.comboResetMs) then return false, "first_finisher_required" end
        return (context.action.runningAttack or context.player:isAiming()) and context.player:isWeaponReady() and not context.player:isAttackStarted()
            and not context.player:isPerformingAttackAnimation(), "native_attack_busy"
    end,
    start = function(context)
        local player, s = context.player, ProjectYakuza.stateFor(context.player)
        if context.action.runningAttack then Combo.reset(s);ProjectYakuza.RunningAttacks.beforeStart(context) end
        s.pendingFinisher, s.starting, s.startRequestedAt = context.action, true, now()
        setReadyVariables(player, context.style, s)
        if context.action.double or context.action.quickstepAttack or context.action.runningAttack then player:setMeleeDelay(0) end
        if context.action.runningAttack then return true end
        ProjectYakuza.attemptAttack(player)
        if not s.active and not player:isAttackStarted() then
            s.pendingFinisher, s.starting = nil, false
            setReadyVariables(player, context.style, s)
            return false, "native_attack_rejected"
        end
        return true
    end,
    cancel = function(context)
        local s = ProjectYakuza.stateFor(context.player)
        ProjectYakuza.releaseFinisherHandoff(context.player)
        ProjectYakuza.Heat.endSwing(context.player)
        context.player:setBlockMovement(false)
        if context.action.runningAttack and ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.finish(context.player) end
        s.pendingFinisher, s.finisherMove, s.queuedFinisher, s.queuedDouble, s.starting = nil, nil, nil, nil, false
        s.finisherBranch, s.finisherFinishedAt = nil, nil
    end,
}
ProjectYakuza.registerActionHandler("finisher", nativeAttackHandler)
ProjectYakuza.registerActionHandler("quickstepAttack", nativeAttackHandler)
ProjectYakuza.registerActionHandler("runningAttack", nativeAttackHandler)
-- SwipeStatePlayer publishes AimFloorAnim after OnWeaponSwing. Read the native getter
-- after entry; do not use the inaccessible Java fields on AttackVars.
function ProjectYakuza.syncGroundAttack(player,style,s)
    if not style.groundAttacks or s.groundMove or not player:isAimAtFloor()
        or not (player:isAttackStarted() or player:isPerformingStompAnimation()) then return false end
    local move=style.groundAttacks[ProjectYakuza.groundNext[player:getPlayerNum()] or 1]
    local hadSwing=s.active
    if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.finish(player) end
    if ProjectYakuza.activeActions[player] then ProjectYakuza.completeAction(player) end
    Combo.reset(s)
    s.active=true;s.startedAt=now();s.groundMove=move;s.multiHitToken={}
    if not hadSwing then ProjectYakuza.Heat.onSwing(player,move) else ProjectYakuza.Heat.applyMoveDamage(player,move) end
    setReadyVariables(player,style,s)
    ProjectYakuza.emit("groundAttackStarted",player,style,move)
    return true
end
local function onUpdate(player)
    if not localPlayer(player) then return end
    if ProjectYakuza.TigerDrop then ProjectYakuza.TigerDrop.track(player) end
    local s = ProjectYakuza.stateFor(player)
    local counterPressed=B.pressed(player,"counter")
    local throwPressed=B.pressed(player,"throw")
    local finisherDown = B.down("finisher")
    local finisherPressed = finisherDown and not ProjectYakuza.finisherDown[player:getPlayerNum()]
    ProjectYakuza.finisherDown[player:getPlayerNum()] = finisherDown
    if not ProjectYakuza.isEquipped(player) or player:isDead() then
        if s.active or s.starting or s.step > 0 or ProjectYakuza.activeActions[player] then ProjectYakuza.resetPlayer(player, "unequipped_or_dead") end
        ProjectYakuza.setVisual(player,false)
        s.lastDown = B.down("light")
        return
    end
    if ProjectYakuza.StyleSelector and (ProjectYakuza.StyleSelector.wheel or ProjectYakuza.StyleSelector.setup) then s.lastDown=B.down("light");return end
    local handoff=ProjectYakuza.finisherHandoffs[player]
    if handoff then
        local reaction=player:getHitReaction()
        if (not handoff.playingDouble and now()>handoff.deadline) or player:isOnFloor() or player:isKnockedDown()
            or player:isClimbing() or player:getVehicle() or (reaction and reaction~="") then ProjectYakuza.releaseFinisherHandoff(player) end
    end
    local entry=ProjectYakuza.activeActions[player]
    if entry and entry.kind=="styleEntry" and ProjectYakuza.StyleEntry and ProjectYakuza.StyleEntry.watch(player,entry) then
        s.lastDown=B.down("light");return
    end
    local token = player:getPrimaryHandItem()
    if ProjectYakuza.prepareToken(token, player) then
        player:resetModelNextFrame()
        trace(player, "updated style weapon model")
    end
    local style = ProjectYakuza.getPlayerStyle(player)
    if isClient() and ProjectYakuza.Network and not ProjectYakuza.Network.equipmentReady(player) then return end
    setReadyVariables(player, style, s)
    local customAction=ProjectYakuza.updateCustomAction(player)
    if ProjectYakuza.styleInputHandlers[style.id] and ProjectYakuza.handleStyleInput(player,{
        aiming=player:isAiming(),lightDown=B.down("light"),
        heavyPressed=finisherPressed,heavyDown=finisherDown,
    }) then s.lastDown=B.down("light");return end
    if customAction or ProjectYakuza.isCustomAction(player) then s.lastDown=B.down("light");return end
    if ProjectYakuza.Defense and ProjectYakuza.Defense.update(player,throwPressed) then s.lastDown=B.down("light");return end
    local context=ProjectYakuza.activeActions[player]
    if context and (context.kind=="parry" or context.kind=="heatActivation" or context.kind=="taunt") then
        if context.kind=="heatActivation" and ProjectYakuza.HeatActivation then ProjectYakuza.HeatActivation.watch(player,context) end
        if context.kind=="taunt" and ProjectYakuza.Taunts then ProjectYakuza.Taunts.watch(player,context) end
        s.lastDown=B.down("light");return
    end
    if context and context.kind=="quickstep" then
        if ProjectYakuza.Quicksteps then ProjectYakuza.Quicksteps.pollAttack(player,context) end
        if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.pause(player) end
        s.lastDown=B.down("light")
        return
    end
    if ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.pending[player] then
        if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.pause(player) end
        s.lastDown=B.down("light");return
    end
    if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.update(player) end
    ProjectYakuza.syncGroundAttack(player,style,s)
    if counterPressed and ProjectYakuza.TigerDrop and ProjectYakuza.TigerDrop.tryCounter(player) then s.lastDown=B.down("light");return end
    if finisherPressed then
        ProjectYakuza.queueFinisher(player)
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
        local clip, hit = variable(player, "ProjectYakuzaClipStarted"), variable(player, "ProjectYakuzaHitMarker")
        if clip ~= "" and clip ~= s.seenClip then s.seenClip = clip; trace(player, "clip-start " .. clip) end
        if hit ~= "" and hit ~= s.seenHit then s.seenHit = hit; trace(player, "collision-marker " .. hit) end
        local move = s.groundMove or s.finisherMove or style.lightAttacks[s.step]
        ProjectYakuza.tryRecoveryCancel(player, style, s)
        if time - s.startedAt > move.duration * 1000 + 1200 then
            trace(player, "attack timeout; " .. ProjectYakuza.diagnosticLine(player), true)
            ProjectYakuza.resetPlayer(player, "attack_timeout")
            return
        end
        -- Exit recovery if another mod omitted OnPlayerAttackFinished, only after the engine actually leaves the attack.
        if time - s.startedAt > move.duration * 1000 and not player:isAttackStarted()
            and not player:isPerformingAttackAnimation() and player:getCurrentStateName() ~= "SwipeStatePlayer" then
            onFinished(player)
        end
    end
    if s.starting and time - (s.startRequestedAt or time) > 350 then
        trace(player, "buffered attack did not reach swing; " .. ProjectYakuza.diagnosticLine(player), true)
        if s.pendingFinisher then
            ProjectYakuza.cancelAction(player, "finisher_start_timeout")
            s.pendingFinisher, s.queuedFinisher = nil, nil
        end
        s.starting = false
    end
    if not player:isWeaponReady() and s.pressSerial > (s.lastReadinessWarning or 0) then
        s.lastReadinessWarning = s.pressSerial
        trace(player, "attack blocked: hand model or weapon not ready; " .. ProjectYakuza.diagnosticLine(player), true)
    end
    if Combo.expire(s, style, time) then ProjectYakuza.emit("comboExpired", player) end
    if s.queuedDouble and s.finisherFinishedAt and not s.active and not s.starting
        and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        local ok, reason = ProjectYakuza.requestAction(player, "finisher", "double_after_" .. s.finisherBranch)
        if ok then s.queuedDouble = nil
        elseif reason ~= "native_attack_busy" then
            s.queuedDouble = nil
            trace(player, "double finisher rejected: " .. tostring(reason))
        end
        return
    end
    if s.queuedFinisher == s.step and not s.active and not s.starting and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        local branch = s.queuedFinisher
        local ok, reason = ProjectYakuza.requestAction(player, "finisher", "after_" .. branch)
        if ok then s.queuedFinisher = nil
        elseif reason ~= "native_attack_busy" then
            s.queuedFinisher = nil
            trace(player, "finisher rejected: " .. tostring(reason))
        end
        return
    end
    if not s.finisherMove and not ProjectYakuza.activeActions[player] and Combo.canStartBuffered(s, style, time) and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        s.starting, s.startRequestedAt = true, time
        -- Build 42.21 returns false even after submitting a valid attack.
        -- OnWeaponSwing clears starting; otherwise retain the lock until the event or timeout.
        ProjectYakuza.attemptAttack(player)
        if s.starting and not player:isAttackStarted() then s.starting = false end
    end
end
function ProjectYakuza.diagnosticLine(player)
    local s, style = ProjectYakuza.stateFor(player), ProjectYakuza.getPlayerStyle(player)
    local item = player:getPrimaryHandItem()
    return "v" .. ProjectYakuza.VERSION .. " item=" .. (item and item:getFullType() or "none")
        .. " style=" .. (style and style.id or "none") .. " step=" .. s.step .. " queued=" .. s.queued
        .. " finisher=" .. tostring(s.finisherMove and s.finisherMove.nodeValue or s.queuedFinisher or "none")
        .. " ready=" .. tostring(player:isWeaponReady()) .. " sprite=" .. tostring(item and item:getWeaponSprite())
        .. " ai=" .. tostring(player:getCurrentStateName()) .. " action=" .. tostring(player:getCurrentActionContextStateName())
        .. " Weapon=" .. variable(player, "Weapon") .. " active=" .. variable(player, "ProjectYakuzaActive")
        .. " move=" .. variable(player, "ProjectYakuzaMove") .. " clip=" .. variable(player, "ProjectYakuzaClipStarted")
        .. " hitMarker=" .. variable(player, "ProjectYakuzaHitMarker") .. " confirmedHit=" .. tostring(s.confirmedHit == true)
end
local function onHit(attacker, victim, weapon, damage)
    if not localPlayer(attacker) or not ProjectYakuza.isEquipped(attacker) then return end
    local s = ProjectYakuza.stateFor(attacker)
    if not weapon or (not ProjectYakuza.isStyleToken(weapon) and not (s.groundMove and weapon:getFullType()=="Base.BareHands")) then return end
    s.confirmedHit = true
    ProjectYakuza.Heat.onHit(attacker,victim,damage,s)
    trace(attacker, "confirmed native hit step=" .. s.step .. " damage=" .. tostring(damage))
    ProjectYakuza.emit("combatHit", attacker, victim, weapon, damage, s.step)
end
Events.OnWeaponSwing.Add(onSwing)
Events.OnPlayerAttackFinished.Add(onFinished)
Events.OnPlayerUpdate.Add(onUpdate)
Events.OnWeaponHitCharacter.Add(onHit)
local function clearCustomActions()
    local pending={}
    for p,c in pairs(ProjectYakuza.activeActions) do
        if ProjectYakuza.isCustomAction(p) then pending[#pending+1]={player=p,context=c} end
    end
    for _,entry in ipairs(pending) do ProjectYakuza.cancelAction(entry.player,"world_exit",entry.context) end
end
Events.OnSave.Add(clearCustomActions)
Events.OnMainMenuEnter.Add(clearCustomActions)
print("[ProjectYakuza] Runtime loaded v" .. ProjectYakuza.VERSION .. "; styles=" .. #ProjectYakuza.styleOrder)
