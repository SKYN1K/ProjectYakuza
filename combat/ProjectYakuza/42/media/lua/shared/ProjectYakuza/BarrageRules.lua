require "ProjectYakuza/Registry"
local R={}
ProjectYakuza.BarrageRules=R
function R.valid(move)
    if type(move)~="table" or type(move.contactFrames)~="table" or #move.contactFrames<1 or #move.contactFrames>32 then return false end
    for _,key in ipairs({"fps","speed","duration","damageMultiplier","finalMultiplier","range"})do local v=move[key];if type(v)~="number"or v~=v then return false end end
    if type(move.fps)~="number" or move.fps<1 or move.fps>120 or type(move.speed)~="number" or move.speed<=0 or move.speed>3 then return false end
    if type(move.duration)~="number" or move.duration<=0 or move.duration>10 or type(move.damageMultiplier)~="number" or move.damageMultiplier<=0 or move.damageMultiplier>2 then return false end
    if type(move.finalMultiplier)~="number" or move.finalMultiplier<=0 or move.finalMultiplier>3 or type(move.range)~="number" or move.range<.25 or move.range>1.65 then return false end
    local previous=-1
    for _,f in ipairs(move.contactFrames)do if type(f)~="number" or f~=math.floor(f) or f<=previous or f>=move.duration*move.speed*move.fps then return false end;previous=f end
    return true
end
function R.damage(move,index,base,extreme)
    if not R.valid(move) or type(index)~="number" or index~=math.floor(index) or index<1 or index>#move.contactFrames then return 0 end
    local factor=index==#move.contactFrames and move.finalMultiplier or move.damageMultiplier
    return math.max(0,math.min(2,base))*factor*(extreme and 1.5 or 1)
end
function R.time(move,index)return move.contactFrames[index]/move.fps/move.speed*1000 end
