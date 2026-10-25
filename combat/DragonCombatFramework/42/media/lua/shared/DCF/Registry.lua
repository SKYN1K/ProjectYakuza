DragonCombat = DragonCombat or {}
local DCF = DragonCombat
DCF.VERSION = "0.27.1"
DCF.API_VERSION = 1
DCF.styles = DCF.styles or {}
DCF.styleOrder = DCF.styleOrder or {}
DCF.actionHandlers = DCF.actionHandlers or {}
DCF.styleActionHandlers = DCF.styleActionHandlers or {}
DCF.styleInputHandlers = DCF.styleInputHandlers or {}
DCF.listeners = DCF.listeners or {}
DCF.actionKinds = { finisher=true, grab=true, parry=true, block=true, quickstep=true, quickstepAttack=true, runningAttack=true, heatAction=true, heatActivation=true, taunt=true }
DCF.activeActions = DCF.activeActions or setmetatable({}, {__mode="k"})
DCF.MAX_HIT_COUNT = 3
DCF.TOKEN = "DragonCombat.StyleToken"

function DCF.on(event, fn)
    assert(type(fn) == "function", "listener must be a function")
    DCF.listeners[event] = DCF.listeners[event] or {}
    table.insert(DCF.listeners[event], fn)
    return fn
end
function DCF.off(event,fn)
    local listeners=DCF.listeners[event]
    if not listeners then return false end
    for i=#listeners,1,-1 do if listeners[i]==fn then table.remove(listeners,i);return true end end
    return false
end
function DCF.emit(event, ...)
    local listeners=DCF.listeners[event]
    if not listeners then return end
    local dispatch={}
    for i,fn in ipairs(listeners) do dispatch[i]=fn end
    for _, fn in ipairs(dispatch) do
        local ok, err = pcall(fn, ...)
        if not ok then print("[DCF] listener error: " .. tostring(err)) end
    end
end
function DCF.validateStyle(style)
    local errors={}
    local function problem(text)errors[#errors+1]=text end
    local function text(value)return type(value)=="string" and value~="" end
    local function number(value)return type(value)=="number" and value==value and value<math.huge and value>-math.huge end
    local function move(value,path,light)
        if type(value)~="table" then problem(path.." must be a table");return end
        if not text(value.animation) then problem(path..".animation is required") end
        if light and not text(value.nodeValue) then problem(path..".nodeValue is required") end
        if light or value.duration~=nil then
            if not number(value.duration) or value.duration<=0 then problem(path..".duration must be positive seconds") end
        end
        for _,key in ipairs({"impact","chainAt"}) do
            local v=value[key];if v~=nil and (not number(v) or v<0 or v>1) then problem(path.."."..key.." must be 0..1") end
        end
        if value.damageMultiplier~=nil and (not number(value.damageMultiplier) or value.damageMultiplier<0) then problem(path..".damageMultiplier must be nonnegative") end
        if value.speed~=nil and (not number(value.speed) or value.speed<=0) then problem(path..".speed must be positive") end
    end
    if type(style)~="table" then return false,{"style must be a table"} end
    if not text(style.id) or style.id=="none" or not string.match(style.id,"^[%w_.-]+$") then problem("style.id must be a unique namespaced ID using letters, numbers, underscore, dot or hyphen") end
    if not text(style.name) then problem("style.name is required") end
    if style.selectorIcon~=nil and not text(style.selectorIcon) then problem("selectorIcon must name a supplied texture") end
    if style.combatVoices~=nil and type(style.combatVoices)~="boolean" then problem("combatVoices must be true or false") end
    for _,key in ipairs({"attackSpeed","runningKneeSpeed"}) do
        if style[key]~=nil and (not number(style[key]) or style[key]<=0) then problem(key.." must be positive") end
    end
    if style.heat~=nil and type(style.heat)~="boolean" then problem("heat must be true or false") end
    if type(style.lightAttacks)~="table" or #style.lightAttacks==0 then problem("lightAttacks must contain at least one move")
    else for i,value in ipairs(style.lightAttacks) do move(value,"lightAttacks["..i.."]",true) end end
    if style.comboResetMs~=nil and (not number(style.comboResetMs) or style.comboResetMs<0) then problem("comboResetMs must be nonnegative milliseconds") end
    if style.lightBufferLimit~=nil and (not number(style.lightBufferLimit) or style.lightBufferLimit<1 or style.lightBufferLimit~=math.floor(style.lightBufferLimit)) then problem("lightBufferLimit must be a positive integer") end
    if style.groundAttacks~=nil then
        if type(style.groundAttacks)~="table" or #style.groundAttacks==0 then problem("groundAttacks must be omitted or contain at least one move")
        else for i,value in ipairs(style.groundAttacks) do move(value,"groundAttacks["..i.."]",true) end end
    end
    if style.actions~=nil and type(style.actions)~="table" then problem("actions must be a table")
    else for kind,slot in pairs(style.actions or {}) do
        if not DCF.actionKinds[kind] then problem("unknown action kind: "..tostring(kind).."; register it with registerActionKind first") end
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
function DCF.registerStyle(style)
    local valid,errors=DCF.validateStyle(style)
    assert(valid,"Invalid DCF style: "..table.concat(errors,"; "))
    style.actions = style.actions or {}
    style.comboResetMs = style.comboResetMs or 750
    style.lightBufferLimit = style.lightBufferLimit or 1
    if not DCF.styles[style.id] then table.insert(DCF.styleOrder, style.id) end
    DCF.styles[style.id] = style
    DCF.emit("styleRegistered", style)
    return style
end
function DCF.listStyles()
    local result={}
    for _,id in ipairs(DCF.styleOrder) do local s=DCF.styles[id];result[#result+1]={id=id,name=s.name,description=s.description} end
    return result
end
function DCF.getStyle(id) return DCF.styles[id] end
function DCF.getPlayerStyle(player)
    local data = player:getModData()
    local id = data.DCFStyle or "dragon_of_dojima"
    return DCF.styles[id]
end
function DCF.isEquipped(player)
    if DCF.Network and not player:isLocalPlayer() then return DCF.Network.remoteEquipped(player) end
    local item = player:getPrimaryHandItem()
    local equipped=item ~= nil and item:getFullType() == DCF.TOKEN and DCF.getPlayerStyle(player) ~= nil
    if equipped and isClient and isClient() and DCF.Network and DCF.Network.equipmentReady then
        return DCF.Network.equipmentReady(player)
    end
    return equipped
end
function DCF.selectStyle(player, id)
    if id ~= "none" and not DCF.styles[id] then return false, "unknown_style" end
    if DCF.isBusy and DCF.isBusy(player) then return false, "busy" end
    player:getModData().DCFStyle = id
    if DCF.resetPlayer then DCF.resetPlayer(player, "style_changed") end
    DCF.emit("styleChanged", player, id)
    return true
end
function DCF.registerActionHandler(kind, handler)
    assert(DCF.actionKinds[kind], "unknown action kind")
    assert(type(handler) == "table" and type(handler.start) == "function", "handler.start required")
    assert(handler.canStart==nil or type(handler.canStart)=="function","handler.canStart must be a function")
    assert(handler.cancel==nil or type(handler.cancel)=="function","handler.cancel must be a function")
    DCF.actionHandlers[kind] = handler
end
function DCF.registerActionKind(kind)
    assert(type(kind)=="string" and kind~="","action kind required")
    DCF.actionKinds[kind]=true
end
function DCF.registerStyleActionHandler(styleId,kind,handler)
    assert(type(styleId)=="string" and styleId~="","style ID required")
    assert(DCF.actionKinds[kind],"unknown action kind")
    assert(type(handler)=="table" and type(handler.start)=="function","handler.start required")
    assert(handler.canStart==nil or type(handler.canStart)=="function","handler.canStart must be a function")
    assert(handler.cancel==nil or type(handler.cancel)=="function","handler.cancel must be a function")
    DCF.styleActionHandlers[styleId]=DCF.styleActionHandlers[styleId] or {}
    DCF.styleActionHandlers[styleId][kind]=handler
end
function DCF.getActionHandler(styleId,kind)
    local handlers=DCF.styleActionHandlers[styleId]
    return handlers and handlers[kind] or DCF.actionHandlers[kind]
end
function DCF.registerStyleInputHandler(styleId,handler)
    assert(type(styleId)=="string" and styleId~="","style ID required")
    assert(type(handler)=="function","input handler must be a function")
    DCF.styleInputHandlers[styleId]=handler
end
function DCF.handleStyleInput(player,input)
    local style=DCF.getPlayerStyle(player)
    local handler=style and DCF.styleInputHandlers[style.id]
    if not handler then return false end
    local ok,consumed=pcall(handler,player,input)
    if not ok then print("[DCF] style input handler error: "..tostring(consumed));return false end
    return consumed==true
end
function DCF.getHeat(player) return player:getModData().DCFHeat or 0 end
function DCF.setHeat(player, value)
    if DCF.Heat and DCF.Heat.isExtreme(player) and value>DCF.getHeat(player) then return false end
    player:getModData().DCFHeat = math.max(0, math.min(100, value))
    DCF.emit("heatChanged", player, DCF.getHeat(player))
end
-- No unfinished action grants effects, protection, movement or damage.
function DCF.requestAction(player, kind, variant, target)
    if not DCF.actionKinds[kind] then return false, "unknown_action" end
    if not DCF.isEquipped(player) then return false, "style_not_equipped" end
    if DCF.isBusy and DCF.isBusy(player) then return false, "busy" end
    local style = DCF.getPlayerStyle(player)
    local slot = style.actions[kind]
    if not slot or slot.enabled ~= true then return false, "not_implemented" end
    local action = slot
    if slot.variants then action = slot.variants[variant or "default"] end
    if not action or action.enabled == false then return false, "unknown_variant" end
    if type(action.animation) ~= "string" or action.animation == "" then return false, "missing_animation" end
    if action.requiresTarget and not target then return false, "target_required" end
    if action.requiresTarget and not action.targetAnimation then return false, "missing_target_animation" end
    local handler = DCF.getActionHandler(style.id,kind)
    if not handler then return false, "missing_handler" end
    local cost = action.heatStocks and action.heatStocks*(DCF.Heat and DCF.Heat.stockSize() or 100/6) or action.heatCost or 0
    if DCF.getHeat(player) < cost then return false, "insufficient_heat" end
    local combo = DCF.stateFor and DCF.stateFor(player) or nil
    local comboStep = combo and combo.step or 0
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
            if not cleaned then print("[DCF] failed-start cleanup error: "..tostring(err)) end
        end
        if not ok then print("[DCF] action handler error: "..tostring(started));return false,"handler_error" end
        return false,reason or "start_failed"
    end
    DCF.activeActions[player] = context
    if cost>0 then DCF.setHeat(player, DCF.getHeat(player) - cost) end
    DCF.emit("actionStarted", context)
    return true
end

function DCF.completeAction(player)
    local context = DCF.activeActions[player]
    if not context then return false end
    DCF.activeActions[player] = nil
    DCF.emit("actionCompleted", context)
    return true
end
function DCF.cancelAction(player, reason)
    local context = DCF.activeActions[player]
    if not context then return false end
    DCF.activeActions[player] = nil
    local handler = context.handler or DCF.getActionHandler(context.style.id,context.kind)
    if handler and handler.cancel then
        local ok, err = pcall(handler.cancel, context, reason)
        if not ok then print("[DCF] cancellation error: " .. tostring(err)) end
    end
    DCF.emit("actionCancelled", context, reason)
    return true
end
