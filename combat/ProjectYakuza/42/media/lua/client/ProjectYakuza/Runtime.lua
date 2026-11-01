require "ProjectYakuza/Registry"
require "ProjectYakuza/Combo"
require "ProjectYakuza/Styles/DragonOfDojima"
require "ProjectYakuza/Reactions"
require "ProjectYakuza/Heat"
require "ProjectYakuza/Bindings"
require "ProjectYakuza/DirectionalAttacks"
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
function ProjectYakuza.resetPlayer(player, reason,keepStance)
    local s = ProjectYakuza.stateFor(player)
    ProjectYakuza.releaseFinisherHandoff(player)
    ProjectYakuza.Heat.endSwing(player)
    if ProjectYakuza.Quicksteps then ProjectYakuza.Quicksteps.pending[player]=nil end
    if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.finish(player) end
    if s.groundMove or s.finisherMove or s.pendingFinisher or s.directionalLight then player:setBlockMovement(false) end
    Combo.reset(s)
    ProjectYakuza.setVisual(player,keepStance==true,"")
    player:setVariable("ProjectYakuzaClipStarted", "")
    player:setVariable("ProjectYakuzaHitMarker", "")
    player:setVariable("ProjectYakuzaChainReady", "")
    player:setVariable("ProjectYakuzaQuickstepCancelReady", "")
    player:setVariable("ProjectYakuzaDoubleReady", "")
    ProjectYakuza.cancelAction(player, reason or "reset")
    ProjectYakuza.emit("comboCancelled", player, reason)
end

function ProjectYakuza.prepareToken(token)
    if token and ProjectYakuza.StyleItem and not ProjectYakuza.StyleItem.prepared[token] then ProjectYakuza.StyleItem.clean(token) end
    if token and ProjectYakuza.isStyleToken(token) and token:getMaxHitCount()~=ProjectYakuza.MAX_HIT_COUNT then token:setMaxHitCount(ProjectYakuza.MAX_HIT_COUNT) end
    if token and ProjectYakuza.isStyleToken(token) and token:getWeaponSprite() ~= "ProjectYakuza_EmptyHand" then
        token:setWeaponSprite("ProjectYakuza_EmptyHand")
        token:setOriginalWeaponSprite("ProjectYakuza_EmptyHand")
        return true
    end
    return false
end
local function setReadyVariables(player, style, s)
    local move = s.groundMove or s.finisherMove or s.pendingFinisher or s.activeLightMove or style.lightAttacks[s.step > 0 and s.step or 1] or style.lightAttacks[1]
    ProjectYakuza.setVisual(player,true,move.nodeValue)
    local visual=ProjectYakuza.visuals[player]
    local profile=style.weaponProfile or ""
    if visual.weaponProfile~=profile then player:setVariable("ProjectYakuzaWeaponProfile",profile);visual.weaponProfile=profile end
    local linked=move.double==true and ProjectYakuza.finisherHandoffs[player]~=nil
    if visual.linkedDouble~=linked then player:setVariable("ProjectYakuzaLinkedDouble",linked);visual.linkedDouble=linked end
    if visual.style~=style.id then player:setVariable("ProjectYakuzaStyle",style.id);visual.style=style.id end
    local enabled=style.groundAttacks~=nil
    if visual.groundEnabled~=enabled then player:setVariable("DFCGroundEnabled",enabled);visual.groundEnabled=enabled end
    local index=ProjectYakuza.groundNext[player:getPlayerNum()] or 1
    if enabled and visual.groundIndex~=index then player:setVariable("ProjectYakuzaStompVariant",tostring(index));visual.groundIndex=index end
end

local function pollPress(player, style, s)
    local down = B.down("light")
    if ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.isCancelling and ProjectYakuza.Quicksteps.isCancelling(player) then s.lastDown=down;return end
    if ProjectYakuza.activeActions[player] and ProjectYakuza.activeActions[player].kind=="quickstep" then return end
    if down and not s.lastDown and player:isAiming() and not s.groundMove and not s.finisherMove and not s.pendingFinisher and not s.queuedFinisher and not s.queuedDouble and not s.queuedWeaponHeavy then Combo.press(s, #style.lightAttacks, style.lightBufferLimit) end
    s.lastDown = down
end
local function onSwing(player, weapon)
    if localPlayer(player) and ProjectYakuza.Weapons then ProjectYakuza.Weapons.sync(player) end
    if not localPlayer(player) or not ProjectYakuza.isEquipped(player) then return end
    if not weapon or not (ProjectYakuza.isStyleToken(weapon) or (ProjectYakuza.Weapons and ProjectYakuza.Weapons.matches(player,weapon))) then return end
    local style, s = ProjectYakuza.getPlayerStyle(player), ProjectYakuza.stateFor(player)
    local owned=ProjectYakuza.activeActions[player]
    local firstQuickstepSwing=owned and (owned.kind=="quickstepAttack" or owned.kind=="chargedHeavy") and s.pendingFinisher==owned.action
    if ProjectYakuza.isCustomAction(player) or (ProjectYakuza.blocksNativeAttacks(player) and not firstQuickstepSwing) then return end
    s.groundMove=nil
    pollPress(player, style, s)

    local move
    if s.pendingFinisher then
        move = s.pendingFinisher
        s.pendingFinisher, s.finisherMove = nil, move
        s.active, s.starting, s.startedAt, s.finishedAt = true, false, now(), nil
        s.queued, s.queuedFinisher = 0, nil
    else
        s.finisherBranch, s.finisherFinishedAt, s.finisherExtreme = nil, nil, nil
        local directional=ProjectYakuza.DirectionalAttacks and ProjectYakuza.DirectionalAttacks.select(player,s,style)
        if s.lightMode~=nil and s.lightMode~=(style.extremeView==true) then Combo.reset(s) end
        s.lightMode=style.extremeView==true
        move = Combo.begin(s, style, now())
        if directional then move=directional;s.step=#style.lightAttacks;s.queued=0 end
        s.activeLightMove=move
        if ProjectYakuza.DirectionalAttacks then ProjectYakuza.DirectionalAttacks.record(player,s,move)end
    end
    if move.chargeBranch or move.afterLight then s.step=move.chargeBranch or move.afterLight end
    s.multiHitToken={};s.effectVictims=nil
    s.seenClip, s.seenHit, s.confirmedHit, s.recoveryReleased, s.heatVictims = nil, nil, false, false, nil
    if move.runningAttack and ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.onSwing(player,move) end
    if move.double and ProjectYakuza.finisherHandoffs[player] then ProjectYakuza.finisherHandoffs[player].playingDouble=true end
    ProjectYakuza.Heat.onSwing(player,move)
    player:setVariable("ProjectYakuzaClipStarted", "")
    player:setVariable("ProjectYakuzaHitMarker", "")
    player:setVariable("ProjectYakuzaChainReady", "")
    player:setVariable("ProjectYakuzaQuickstepCancelReady", "")
    player:setVariable("ProjectYakuzaDoubleReady", "")
    setReadyVariables(player, style, s)
    trace(player, "swing style=" .. style.id .. " step=" .. s.step .. " move=" .. move.nodeValue .. " queued=" .. s.queued)
    ProjectYakuza.emit("attackCommitted",player,style,move,s.multiHitToken)
    if move.runningAttack then ProjectYakuza.emit("runningAttackStarted",player,style,move)
    elseif move.chargedHeavy then ProjectYakuza.emit("chargedHeavyStarted",player,style,move)
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
        if move.quickstepAttack or move.chargedHeavy or move.neutralHeavy then setReadyVariables(player,ProjectYakuza.getPlayerStyle(player),s) end
        if not move.neutralHeavy and not move.double and not move.quickstepAttack and not move.runningAttack and (not move.chargedHeavy or move.chargedFinisher) then
            s.finisherBranch, s.finisherFinishedAt = step, now()
            s.finisherExtreme=move.extremeHeat==true;s.finisherReverse=move.reverseFinisher==true
            if followup then s.step, s.finishedAt, s.queuedDouble = step, now(), true end
        end
        trace(player, "finisher finished after light=" .. step .. " double=" .. tostring(move.double == true))
        if followup then player:setMeleeDelay(0) end
        if move.runningAttack then ProjectYakuza.emit("runningAttackFinished",player,move)
        elseif move.chargedHeavy then ProjectYakuza.emit("chargedHeavyFinished",player,move)
        elseif move.quickstepAttack then ProjectYakuza.emit("quickstepAttackFinished", player, move)
        else ProjectYakuza.emit("finisherFinished", player, step, move) end
        return
    end
    if Combo.finish(s, now()) then
        if s.directionalLight then player:setBlockMovement(false);Combo.reset(s)end
        s.activeLightMove=nil
        trace(player, "finished step=" .. s.step .. " queued=" .. s.queued)
        ProjectYakuza.emit("lightAttackFinished", player, s.step)
    end
end
local function finisherStep(style,step)return step>0 and style.finisherBranches and (step-1)%style.finisherBranches+1 or step end
local function finisherVariant(player,style,key,linked)
    local extreme=linked
    if extreme==nil then extreme=ProjectYakuza.Heat and ProjectYakuza.Heat.isExtreme and ProjectYakuza.Heat.isExtreme(player) end
    local variants=style.actions.finisher.variants
    if extreme and variants and variants["extreme_"..key] and variants["extreme_"..key].enabled then return "extreme_"..key end
    return ProjectYakuza.DirectionalAttacks and ProjectYakuza.DirectionalAttacks.finisher(player,ProjectYakuza.stateFor(player),style,key)or key
end
function ProjectYakuza.queueFinisher(player)
    if not ProjectYakuza.isEquipped(player) or not player:isAiming() or player:isDead() then return false, "not_ready" end
    local s, style = ProjectYakuza.stateFor(player), ProjectYakuza.getPlayerStyle(player)
    if s.directionalLight then return false,"directional_ender"end
    local slot = style.actions.finisher
    if not slot or not slot.enabled then return false, "not_implemented" end
    local first = s.finisherMove or s.pendingFinisher
    if s.groundMove or (first and (first.neutralHeavy or first.quickstepAttack or first.runningAttack or (first.chargedHeavy and not first.chargedFinisher))) then return false,"busy" end
    if style.weaponStandaloneHeavy then
        if s.active or s.starting then
            if s.finisherMove or s.pendingFinisher or s.groundMove then return false,"busy" end
            s.queuedWeaponHeavy=true;s.queued=0;return true
        end
        return ProjectYakuza.requestAction(player,"finisher","default")
    end
    if not first and not s.active and not s.starting then
        if s.finishedAt and now()-s.finishedAt>style.comboResetMs then Combo.reset(s) end
        if s.finisherFinishedAt and now()-s.finisherFinishedAt>style.comboResetMs then s.finisherBranch=nil;s.finisherFinishedAt=nil;s.finisherExtreme=nil end
    end
    if not first and s.step<1 and not s.finisherBranch and not ProjectYakuza.activeActions[player] then
        local variant=finisherVariant(player,style,"default")
        local neutral=slot.variants and slot.variants[variant]
        if neutral and neutral.enabled and neutral.neutralHeavy then return ProjectYakuza.requestAction(player,"finisher",variant) end
    end
    local branch = first and (first.afterLight or first.chargeBranch) or s.queuedFinisher or s.finisherBranch
    if first or s.queuedFinisher or s.finisherBranch then
        if (first and first.double) or s.queuedDouble then return false, "finisher_limit" end
        if not first and not s.queuedFinisher and now() - s.finisherFinishedAt > style.comboResetMs then return false, "combo_window_closed" end
        local extreme=(first and first.extremeHeat==true) or (not first and s.finisherExtreme==true)
        local double = slot.variants and slot.variants[finisherVariant(player,style,"double_after_"..branch,extreme)]
        if not double or not double.enabled then return false, "not_implemented" end
        s.queuedDouble = true;s.queuedDoubleVariant=finisherVariant(player,style,"double_after_"..branch,extreme)
        if not first and not s.queuedFinisher then s.step, s.finishedAt = branch, s.finisherFinishedAt end
        trace(player, "queued double finisher after light=" .. branch)
        ProjectYakuza.tryRecoveryCancel(player,style,s)
        return true
    end
    if s.step < 1 or ProjectYakuza.activeActions[player] then return false, "no_light_branch" end
    branch = finisherStep(style,math.min(#style.lightAttacks, s.step + s.queued))
    local move = slot.variants and slot.variants["after_" .. branch]
    if not move or not move.enabled then return false, "not_implemented" end
    if not s.active and (not s.finishedAt or now() - s.finishedAt > style.comboResetMs) then return false, "combo_window_closed" end
    s.queuedFinisher = branch;s.queuedFinisherVariant=finisherVariant(player,style,"after_"..branch)
    trace(player, "queued finisher after light=" .. branch)
    return true
end

function ProjectYakuza.tryRecoveryCancel(player, style, s)
    if not s.active or s.groundMove or s.recoveryReleased or not player:isAiming() then return false end
    local move = s.groundMove or s.finisherMove or s.activeLightMove or style.lightAttacks[s.step]
    local finisher=s.finisherMove~=nil
    local queued = finisher and (not move.double and s.queuedDouble) or (not finisher and (s.queued > 0 or s.queuedFinisher ~= nil or s.queuedWeaponHeavy==true))
    if not finisher and ProjectYakuza.ChargedHeavy and ProjectYakuza.ChargedHeavy.wantsRecovery and ProjectYakuza.ChargedHeavy.wantsRecovery(player,s,style) then queued=true end
    if not finisher and ProjectYakuza.HeatRush and ProjectYakuza.HeatRush.tickets[player]and ProjectYakuza.HeatRush.tickets[player].pressed then queued=true end
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
        if context.action.extremeHeat and not ((ProjectYakuza.Heat.isExtreme and ProjectYakuza.Heat.isExtreme(context.player))
            or (context.action.double and s.finisherExtreme)) then return false,"extreme_heat_required" end
        if context.action.double and (context.action.extremeHeat==true)~=(s.finisherExtreme==true) then return false,"finisher_mode_mismatch" end
        if context.action.runningAttack then
            local R=ProjectYakuza.RunningAttacks
            local ticket=R and R.tickets[context.player]
            if not ticket or context.target~=ticket or ticket.variant~=context.action.variant or ticket.expiresAt<now()
                or not R.ready(context.player) then return false,"running_required" end
        end
        if context.action.quickstepAttack then
            local pending=ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.pending[context.player]
            if not pending or context.target~=pending or pending.consumed or context.variant~=pending.direction or pending.expiresAt<now() then return false,"quickstep_required" end
        end
        if context.action.chargedHeavy then
            local ticket=ProjectYakuza.ChargedHeavy and ProjectYakuza.ChargedHeavy.pending[context.player]
            if not ticket or context.target~=ticket or ticket.consumed or ticket.expiresAt<now()
                or (ticket.variant or "default")~=(context.variant or "default") or ticket.branch~=context.action.chargeBranch then return false,"charge_required" end
        end
        if context.action.double and (s.finisherBranch ~= context.comboStep or not s.finisherFinishedAt
            or now() - s.finisherFinishedAt > context.style.comboResetMs) then return false, "first_finisher_required" end
        return (context.action.runningAttack or context.player:isAiming()) and context.player:isWeaponReady() and not context.player:isAttackStarted()
            and not context.player:isPerformingAttackAnimation(), "native_attack_busy"
    end,
    start = function(context)
        local player, s = context.player, ProjectYakuza.stateFor(context.player)
        if context.action.chargedHeavy then
            local move={};for key,value in pairs(context.action) do move[key]=value end
            move.chargePower=math.max(0,math.min(1,context.target.power or 0))
            move.damageMultiplier=ProjectYakuza.ChargeRules.damage(context.action,move.chargePower)
            context.action=move
        end
        if context.action.runningAttack then Combo.reset(s);ProjectYakuza.RunningAttacks.beforeStart(context) end
        s.pendingFinisher, s.starting, s.startRequestedAt = context.action, true, now()
        setReadyVariables(player, context.style, s)
        if context.action.double or context.action.quickstepAttack or context.action.runningAttack or context.action.chargedHeavy then player:setMeleeDelay(0) end
        if context.action.runningAttack then return true end
        ProjectYakuza.attemptAttack(player)
        if not s.active and not player:isAttackStarted() then
            s.pendingFinisher, s.starting = nil, false
            setReadyVariables(player, context.style, s)
            return false, "native_attack_rejected"
        end
        if context.action.chargedHeavy then
            context.target.consumed=true
            if ProjectYakuza.ChargedHeavy.pending[player]==context.target then ProjectYakuza.ChargedHeavy.pending[player]=nil end
        end
        if context.action.quickstepAttack then
            context.target.consumed=true
            if ProjectYakuza.Quicksteps.pending[player]==context.target then ProjectYakuza.Quicksteps.pending[player]=nil end
        end
        return true
    end,
    cancel = function(context)
        local s = ProjectYakuza.stateFor(context.player)
        if context.action.quickstepAttack and context.target and (s.active or context.player:isAttackStarted()) then
            context.target.consumed=true
            if ProjectYakuza.Quicksteps.pending[context.player]==context.target then ProjectYakuza.Quicksteps.pending[context.player]=nil end
        end
        ProjectYakuza.releaseFinisherHandoff(context.player)
        ProjectYakuza.Heat.endSwing(context.player)
        context.player:setBlockMovement(false)
        if context.action.runningAttack and ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.finish(context.player) end
        s.pendingFinisher, s.finisherMove, s.queuedFinisher, s.queuedDouble, s.starting = nil, nil, nil, nil, false
        s.finisherBranch, s.finisherFinishedAt, s.finisherExtreme = nil, nil, nil
    end,
}
ProjectYakuza.registerActionHandler("chargedHeavy", nativeAttackHandler)
ProjectYakuza.registerActionHandler("finisher", nativeAttackHandler)
ProjectYakuza.registerActionHandler("quickstepAttack", nativeAttackHandler)
ProjectYakuza.registerActionHandler("runningAttack", nativeAttackHandler)

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
    if not hadSwing then ProjectYakuza.emit("attackCommitted",player,style,move,s.multiHitToken)end
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
    if ProjectYakuza.StyleEntry and ProjectYakuza.StyleEntry.pending and ProjectYakuza.StyleEntry.pending[player] then s.lastDown=B.down("light");return end
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
    if ProjectYakuza.prepareToken(token) then
        player:resetModelNextFrame()
        trace(player, "migrated saved style item to ProjectYakuza_EmptyHand")
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
    local charging=ProjectYakuza.activeActions[player]
    if charging and charging.kind=="heavyCharge" and ProjectYakuza.ChargedHeavy then
        ProjectYakuza.ChargedHeavy.watch(player,charging);s.lastDown=B.down("light");return
    end
    if ProjectYakuza.Defense and ProjectYakuza.Defense.update(player,throwPressed) then s.lastDown=B.down("light");return end
    local context=ProjectYakuza.activeActions[player]
    if context and context.kind=="heatAction"and context.timedAction then if not context.timedAction.started and now()-context.requestedAt>650 then ProjectYakuza.cancelAction(player,"heat_rush_start_timeout")end;s.lastDown=B.down("light");return end
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
    if ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.isCancelling and ProjectYakuza.Quicksteps.isCancelling(player) then s.lastDown=B.down("light");return end
    if ProjectYakuza.RunningAttacks then ProjectYakuza.RunningAttacks.update(player) end
    ProjectYakuza.syncGroundAttack(player,style,s)
    if (counterPressed or finisherPressed) and ProjectYakuza.TigerDrop and ProjectYakuza.TigerDrop.tryCounter(player) then if ProjectYakuza.ChargedHeavy then ProjectYakuza.ChargedHeavy.clearPlayer(player) end;s.lastDown=B.down("light");return end
    if s.directionalLight then finisherPressed=false;finisherDown=false end
    if ProjectYakuza.HeatRush and ProjectYakuza.HeatRush.input(player,s,style)then s.lastDown=B.down("light");return end
    local heavyInput=ProjectYakuza.ChargedHeavy and ProjectYakuza.ChargedHeavy.input(player,finisherDown,finisherPressed,s,style)
    if finisherPressed and not heavyInput then ProjectYakuza.queueFinisher(player) end
    if ProjectYakuza.activeActions[player] and ProjectYakuza.activeActions[player].kind=="heavyCharge" then s.lastDown=B.down("light");return end
    pollPress(player, style, s)
    if not player:isAiming() then
        s.queuedWeaponHeavy=nil
        s.queued, s.queuedFinisher, s.queuedDouble = 0, nil, nil
        s.finisherBranch, s.finisherFinishedAt, s.finisherExtreme = nil, nil, nil
        if not s.active and not s.starting and (s.step~=0 or s.finishedAt or s.queued~=0) then Combo.reset(s) end
        if not s.active and not s.starting then return end
    end
    local time = now()
    if s.active then
        local clip, hit = variable(player, "ProjectYakuzaClipStarted"), variable(player, "ProjectYakuzaHitMarker")
        if clip ~= "" and clip ~= s.seenClip then s.seenClip = clip; trace(player, "clip-start " .. clip) end
        if hit ~= "" and hit ~= s.seenHit then s.seenHit = hit; trace(player, "collision-marker " .. hit) end
        local move = s.groundMove or s.finisherMove or s.activeLightMove or style.lightAttacks[s.step]
        ProjectYakuza.tryRecoveryCancel(player, style, s)
        if time - s.startedAt > move.duration * 1000 + 1200 then
            trace(player, "attack timeout; " .. ProjectYakuza.diagnosticLine(player), true)
            ProjectYakuza.resetPlayer(player, "attack_timeout")
            return
        end

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
        local ok, reason = ProjectYakuza.requestAction(player, "finisher", s.queuedDoubleVariant or finisherVariant(player,style,"double_after_"..s.finisherBranch,s.finisherExtreme==true))
        if ok then s.queuedDouble = nil;s.queuedDoubleVariant=nil
        elseif reason ~= "native_attack_busy" then
            s.queuedDouble = nil
            trace(player, "double finisher rejected: " .. tostring(reason))
        end
        return
    end
    if s.queuedWeaponHeavy and not s.active and not s.starting and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        s.queuedWeaponHeavy=nil;ProjectYakuza.requestAction(player,"finisher","default");return
    end
    if s.queuedFinisher == finisherStep(style,s.step) and not s.active and not s.starting and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        local branch = s.queuedFinisher
        local ok, reason = ProjectYakuza.requestAction(player, "finisher", s.queuedFinisherVariant or finisherVariant(player,style,"after_"..branch))
        if ok then s.queuedFinisher = nil;s.queuedFinisherVariant=nil
        elseif reason ~= "native_attack_busy" then
            s.queuedFinisher = nil
            trace(player, "finisher rejected: " .. tostring(reason))
        end
        return
    end
    if not s.finisherMove and not ProjectYakuza.activeActions[player] and Combo.canStartBuffered(s, style, time) and not player:isAttackStarted() and not player:isPerformingAttackAnimation() then
        s.starting, s.startRequestedAt = true, time

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
    if not weapon or (not (ProjectYakuza.isStyleToken(weapon) or (ProjectYakuza.Weapons and ProjectYakuza.Weapons.matches(attacker,weapon))) and not (s.groundMove and weapon:getFullType()=="Base.BareHands")) then return end
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
