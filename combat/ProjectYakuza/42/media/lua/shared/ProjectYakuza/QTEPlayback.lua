require "ProjectYakuza/Registry"
local T={cache=setmetatable({}, {__mode="k"})};ProjectYakuza.QTEPlayback=T
function T.plan(def)
    if not def then return end
    local cached=T.cache[def];if cached then return cached end
    local plan={segments={},extraMs=0};local prompts={};local last=0;local paced=false
    for i,prompt in ipairs(def.prompts)do
        local out={};for key,value in pairs(prompt)do out[key]=value end
        if prompt.countdownMs then
            local first=prompt.sourceStartMs or math.max(last,prompt.atMs-prompt.windowMs)
            local segment={first=first,last=prompt.atMs,realFirst=first+plan.extraMs,realLast=first+plan.extraMs+prompt.countdownMs,speed=(prompt.atMs-first)/prompt.countdownMs}
            plan.segments[#plan.segments+1]=segment;plan.extraMs=segment.realLast-segment.last
            out.atMs=segment.realLast;out.windowMs=prompt.countdownMs;out.countdownMs=nil;out.sourceStartMs=nil;paced=true
        else out.atMs=prompt.atMs+plan.extraMs end
        prompts[i]=out;last=prompt.atMs
    end
    if paced then local runtime={};for key,value in pairs(def)do runtime[key]=value end;runtime.prompts=prompts;plan.definition=runtime end
    T.cache[def]=plan;return plan
end
function T.time(def,sourceMs)
    local plan=T.plan(def);if not plan then return sourceMs end
    local extra=0
    for _,v in ipairs(plan.segments)do
        if sourceMs<v.first then return sourceMs+extra end
        if sourceMs<v.last then return v.realFirst+(sourceMs-v.first)/v.speed end
        extra=v.realLast-v.last
    end
    return sourceMs+extra
end
function T.source(def,timeMs)
    local plan=T.plan(def);if not plan then return timeMs end
    local extra=0
    for _,v in ipairs(plan.segments)do
        if timeMs<v.realFirst then return timeMs-extra end
        if timeMs<v.realLast then return v.first+(timeMs-v.realFirst)*v.speed end
        extra=v.realLast-v.last
    end
    return timeMs-extra
end
function T.speed(def,sourceMs)
    local plan=T.plan(def);if plan then for _,v in ipairs(plan.segments)do if sourceMs>=v.first and sourceMs<v.last then return v.speed end end end
    return 1
end

function T.definition(def)
    local plan=T.plan(def);if not plan then return end
    local result=plan.definition;if not result then return def end
    result.failureLimit=def.failureLimit;result.failureMode=def.failureMode;result.feedback=def.feedback;result.allowOverlap=def.allowOverlap
    return result
end
