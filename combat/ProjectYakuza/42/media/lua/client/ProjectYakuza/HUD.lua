require "ProjectYakuza/Runtime"
require "ProjectYakuza/StyleUI"
local ProjectYakuza = ProjectYakuza
local cache={}
local function draw()
    local player=getSpecificPlayer(0)
    if not player or not ProjectYakuza.isEquipped(player) then ProjectYakuza.StyleUI.releaseAll(cache);return end
    if ProjectYakuza.StyleUI.render("status",player,cache) then return end
    local diagnostics=player:getModData().ProjectYakuzaDiagnostics
    local time=getTimestampMs()
    local feedback=ProjectYakuza.Feedback and ProjectYakuza.Feedback.states[player]
    local visible=feedback and time<feedback.untilAt and not isGamePaused()
        and not(ISWorldMap_instance and ISWorldMap_instance:isVisible())and not(ProjectYakuza.StyleSelector and ProjectYakuza.StyleSelector.setup)
    if not player:isAiming()and not diagnostics then
        if visible then getTextManager():DrawString(UIFont.Small,20,getCore():getScreenHeight()-130,feedback.text,.8,.9,1,1)end
        return
    end
    if time>=(cache.nextText or 0) then
        local style,s=ProjectYakuza.getPlayerStyle(player),ProjectYakuza.stateFor(player)
        local context=ProjectYakuza.activeActions[player]
        local action=context and context.kind=="heavyCharge" and "CHARGING - release heavy to strike" or context and context.kind=="taunt" and "TAUNT" or context and context.kind=="heatActivation" and "EXTREME HEAT ACTIVATION" or context and context.kind=="block" and ("GUARD - release "..ProjectYakuza.Bindings.label("block").." to lower") or context and context.kind=="grab" and ("GRAB - "..ProjectYakuza.Bindings.label("grab")..": throw") or s.groundMove and "GROUND STOMP" or context and context.kind=="quickstep" and ("QUICKSTEP "..context.action.direction..(" - "..ProjectYakuza.Bindings.label("light")..": attack")) or s.finisherMove and (s.finisherMove.chargedHeavy and "CHARGED HEAVY" or s.finisherMove.runningAttack and ("RUNNING "..string.upper(s.finisherMove.variant)) or s.finisherMove.quickstepAttack and "QUICKSTEP ATTACK" or s.finisherMove.double and "DOUBLE FINISHER" or ("FINISHER - "..ProjectYakuza.Bindings.label("finisher")..": follow-up"))
            or (s.queuedDouble and "double finisher queued" or (s.queuedFinisher and "finisher queued" or (style.actions.finisher and style.actions.finisher.enabled and (ProjectYakuza.Bindings.label("finisher")..": finisher") or (ProjectYakuza.Bindings.label("light")..": attack"))))
        cache.text=style.name.."  "..s.step.."/"..#style.lightAttacks.."  queued: "..s.queued.."  "..action
        cache.nextText=time+100
    end
    local x,y=20,getCore():getScreenHeight()-110
    local manager=getTextManager()
    manager:DrawString(UIFont.Small,x,y,cache.text,1,0.83,0.3,1)
    if visible then manager:DrawString(UIFont.Small,x,y-20,feedback.text,.8,.9,1,1)end
    if diagnostics then
        if time>=(cache.nextDiagnostic or 0) then cache.diagnostic=ProjectYakuza.diagnosticLine(player);cache.nextDiagnostic=time+250 end
        manager:DrawString(UIFont.Small,x,y+20,cache.diagnostic,1,1,1,1)
    end
end
Events.OnPostUIDraw.Add(draw)
