require "ProjectYakuza/Registry"
local V={clips={},states=setmetatable({}, {__mode="k"}),pools={ProjectYakuza_Y6_PunchImpact=9,ProjectYakuza_Y6_KickImpact=5,ProjectYakuza_Y6_HeatImpact=4,ProjectYakuza_Y6_PunchSwing=4,ProjectYakuza_Y6_KickSwing=3,ProjectYakuza_Y6_GuardImpact=3,ProjectYakuza_Y6_HeavyFinisher=3}}
ProjectYakuza.SoundVariety=V
function V.registerPool(name,count)
    assert(type(name)=="string"and name:match("^[%w_.-]+$")and type(count)=="number"and count==math.floor(count)and count>=2 and count<=32,"sound pool requires a name and 2..32 clips")
    assert(not V.pools[name]or V.pools[name]==count,"sound pool size already registered");V.pools[name]=count
end
function V.allowed(style,name,index)
    if not style or style.soundVariety~=true or type(style.sounds)~="table"then return false end
    local size=V.pools[name]
    if not size or type(index)~="number"or index~=math.floor(index)or index<1 or index>size then return false end
    for _,cue in pairs(style.sounds)do if cue==name then return true end end
    return false
end
function V.next(p,style,name)
    if not V.allowed(style,name,1)then return end
    local state=V.states[p];if not state or state.style~=style.id then state={style=style.id,bags={}};V.states[p]=state end
    local job=state.bags[name];if not job then job={bag={}};state.bags[name]=job end
    if #job.bag==0 then
        for i=1,V.pools[name]do job.bag[i]=i end
        for i=#job.bag,2,-1 do local j=ZombRand(i)+1;job.bag[i],job.bag[j]=job.bag[j],job.bag[i]end
        local last=#job.bag
        if job.bag[last]==job.previous then job.bag[1],job.bag[last]=job.bag[last],job.bag[1]end
    end
    local index=table.remove(job.bag);job.previous=index;return index
end
function V.resolve(name)
    local sound=GameSounds and GameSounds.getSound(name)
    if not sound then return end
    local cached=V.clips[name]
    if cached and cached.sound==sound then return cached.items end
    local items,seen={},{}
    local ok=pcall(function()
        for i=1,V.pools[name]*32 do
            local clip=sound:getRandomClip();local file=clip and clip:getFile()
            if type(file)=="string"and file~=""and not seen[file]then
                seen[file]=true;items[#items+1]={file=file,clip=clip}
                if #items==V.pools[name]then break end
            end
        end
    end)
    if not ok or #items~=V.pools[name]then V.clips[name]={sound=sound};return end
    table.sort(items,function(a,b)return a.file<b.file end)
    local clips={};for i,item in ipairs(items)do clips[i]=item.clip end
    V.clips[name]={sound=sound,items=clips};return clips
end
function V.play(p,style,name,index,gain)
    if not V.allowed(style,name,index)or type(gain)~="number"or gain~=gain or gain<0 or gain>1 then return end
    local clips=V.resolve(name);if not clips then return end
    local world=getWorld();if not world then return end
    local emitter=world:getFreeEmitter(p:getX(),p:getY(),p:getZ());if not emitter then return end
    local handle=emitter:playClip(clips[index],p)
    if type(handle)=="number"and handle~=0 then emitter:setVolume(handle,gain)end
    return handle
end
function V.clear(p)if p then V.states[p]=nil else V.states=setmetatable({}, {__mode="k"});V.clips={}end end
ProjectYakuza.on("styleChanged",V.clear)
Events.OnSave.Add(function()V.clear()end)
Events.OnMainMenuEnter.Add(function()V.clear()end)
