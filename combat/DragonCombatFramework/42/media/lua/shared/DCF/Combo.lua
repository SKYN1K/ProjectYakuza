require "DCF/Registry"
local DCF = DragonCombat
local Combo = {}
DCF.Combo = Combo
function Combo.new()
    return { step=0, active=false, queued=0, finishedAt=nil, startedAt=nil, starting=false, lastDown=false, pressSerial=0, consumedSerial=0 }
end
function Combo.reset(s)
    local held, serial = s.lastDown, s.pressSerial
    for k in pairs(s) do s[k] = nil end
    local fresh = Combo.new()
    for k, v in pairs(fresh) do s[k] = v end
    s.lastDown = held
    s.pressSerial, s.consumedSerial = serial, serial
end
function Combo.press(s, count, bufferLimit)
    s.pressSerial = s.pressSerial + 1
    if s.active or s.starting then
        -- Keep only the next intended attack; repeated early clicks do not fill the chain.
        s.queued = math.min(s.queued + 1, bufferLimit or 1, math.max(0, count - s.step))
    end
end
function Combo.begin(s, style, now)
    local continuation = s.step > 0 and s.step < #style.lightAttacks
    local withinWindow = s.active or s.starting or (s.finishedAt and now - s.finishedAt <= style.comboResetMs)
    local newPress = s.pressSerial > s.consumedSerial or s.queued > 0
    if continuation and withinWindow and newPress then s.step = s.step + 1 else s.step = 1; s.queued = 0 end
    if s.queued > 0 then s.queued = s.queued - 1 end
    s.consumedSerial = s.pressSerial
    s.active, s.starting = true, false
    s.startedAt, s.finishedAt = now, nil
    return style.lightAttacks[s.step]
end
function Combo.finish(s, now)
    if not s.active then return false end
    s.active, s.starting, s.finishedAt = false, false, now
    return true
end
function Combo.expire(s, style, now)
    if not s.active and not s.starting and s.finishedAt and now - s.finishedAt > style.comboResetMs then
        Combo.reset(s)
        return true
    end
    return false
end
function Combo.canStartBuffered(s, style, now)
    return not s.active and not s.starting and s.queued > 0 and s.step < #style.lightAttacks
        and s.finishedAt ~= nil and now - s.finishedAt <= style.comboResetMs
end
return Combo
