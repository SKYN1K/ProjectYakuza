require "ProjectYakuzaPhoneDev/PhoneMath"
local PY=ProjectYakuza
local D=PY.PhoneDev
local P={}
D.Preview=P
local function path(value)
    if type(value)~="string"or #value>256 then return end
    value=value:gsub("\\","/")
    if value:sub(1,6)=="media/"and not value:find("..",1,true)and value:lower():sub(-4)==".png"then return value end
end
local function color(value,fallback)
    if type(value)=="string"and value:match("^#%x%x%x%x%x%x$")then return {tonumber(value:sub(2,3),16)/255,tonumber(value:sub(4,5),16)/255,tonumber(value:sub(6,7),16)/255}end
    if type(value)~="table"then return fallback end
    local result={}
    for i,key in ipairs({"r","g","b"})do local n=tonumber(value[i]or value[key]);if not n or n~=n then return fallback end;result[i]=D.Math.clamp(n,0,1)end
    return result
end
function P.animation(value)
    if type(value)~="table"or type(value.frames)~="table"or #value.frames<1 or #value.frames>120 then return end
    local loops=tonumber(value.loops)or 0
    if loops~=loops or loops<0 or loops>65536 then return end
    local result={frames={},ends={},total=0,loops=math.floor(loops)}
    for i,frame in ipairs(value.frames)do
        local file=path(frame);local duration=type(value.durations)=="table"and tonumber(value.durations[i])or nil
        if not file or not duration or duration~=duration or duration<10 or duration>60000 then return end
        result.frames[i]=file;result.total=result.total+duration;result.ends[i]=result.total
    end
    return result
end
function P.style(entry)
    local style=PY.getStyle(entry.id)or entry;local config=type(style.phoneMenu)=="table"and style.phoneMenu or {}
    local theme=type(config.theme)=="table"and config.theme or {};local dragon=entry.id=="dragon_of_dojima"
    local result={id=entry.id,name=style.name,description=style.description or"Additional fighting style.",previews={},theme={
        accent=color(theme.accent,dragon and{.30,.74,1}or{.62,.66,.73}),
        background=color(theme.background,dragon and{.018,.037,.055}or{.025,.025,.032}),
        text=color(theme.text,{.94,.96,.98})}}
    if type(config.previews)=="table"then for i=1,math.min(8,#config.previews)do local source=config.previews[i]
        if type(source)=="table"then local image=path(source.image);local animation=P.animation(source.animation)
            if image or animation then result.previews[#result.previews+1]={label=tostring(source.label or("Preview "..i)),image=image,animation=animation}end
        end
    end end
    if #result.previews==0 then
        local image=dragon and"media/textures/ProjectYakuzaPhoneDev/DragonOfDojima.png"or path(style.previewImage)
        if image then result.previews[1]={label="Overview",image=image}end
    end
    return result
end
function P.start(preview,now)
    local state={preview=preview,at=now,cache={}}
    if preview then
        local first=preview.image or preview.animation.frames[1];state.cache[first]=getTexture(first)
        if preview.animation and preview.animation.frames[2]then local nextFrame=preview.animation.frames[2];state.cache[nextFrame]=getTexture(nextFrame)end
    end
    return state
end
function P.frame(animation,elapsed)
    elapsed=math.max(0,elapsed)
    if animation.loops>0 and elapsed>=animation.total*animation.loops then return #animation.frames end
    local time=elapsed%animation.total;local low,high=1,#animation.ends
    while low<high do local mid=math.floor((low+high)/2);if time<animation.ends[mid]then high=mid else low=mid+1 end end
    return low
end
function P.texture(state,now)
    local preview=state and state.preview;if not preview then return end
    local index=preview.animation and P.frame(preview.animation,now-state.at)or 1
    local file=preview.image or preview.animation.frames[index]
    state.cache[file]=state.cache[file]or getTexture(file)
    local texture=state.cache[file]
    if texture and texture:isReady()then state.last=texture end
    if preview.animation then local nextFile=preview.animation.frames[index%#preview.animation.frames+1];state.cache[nextFile]=state.cache[nextFile]or getTexture(nextFile)end
    return state.last and state.last:isReady()and state.last or nil,index
end
