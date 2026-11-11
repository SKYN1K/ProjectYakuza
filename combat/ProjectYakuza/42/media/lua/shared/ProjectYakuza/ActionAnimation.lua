require "ProjectYakuza/Registry"
local PY=ProjectYakuza
function PY.releaseActionAnimation(p,owner,stopAnimation)
    local context=owner.context
    if PY.activeActions[p] and PY.activeActions[p]~=context then return false end
    local clip=p:GetVariable("PerformingAction") or ""
    if clip~="" and clip~=context.action.animation and clip~=owner.animation then return false end
    if clip=="" then
        local actions=p:getCharacterActions()
        if actions:size()>0 and not (actions:size()==1 and owner.action and actions:contains(owner.action)) then return false end
    end
    p:setVariable("PerformingAction","");p:setVariable("IsPerformingAnAction",false)
    if stopAnimation and clip~="" then p:StopTimedActionAnim() end
    return true
end
