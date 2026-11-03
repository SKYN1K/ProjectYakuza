require "ProjectYakuza/Registry"
require "ProjectYakuza/InputPrompts"
local PY=ProjectYakuza
local U={providers={},sessions=setmetatable({}, {__mode="k"}),textures={}}
PY.StyleUI=U
local channels={heat=true,status=true,selector=true,selectorSlot=true,setup=true,encounter=true,heatAction=true}

function PY.registerStyleUI(id,provider)
    assert(type(id)=="string" and string.match(id,"^[%w_.-]+$"),"namespaced UI provider ID required")
    assert(type(provider)=="table" and type(provider.render)=="function","UI render callback required")
    for _,key in ipairs({"create","update","destroy"}) do
        assert(provider[key]==nil or type(provider[key])=="function",key.." must be a function")
    end
    U.providers[id]=provider
end
function PY.unregisterStyleUI(id)
    local provider=U.providers[id];if not provider then return false end
    U.providers[id]=nil
    for host,list in pairs(U.sessions) do
        local keys={};for key,s in pairs(list) do if s.provider==provider then keys[#keys+1]=key end end
        for _,key in ipairs(keys) do U.release(host,key) end
    end
    return true
end
function U.texture(path)
    if not U.textures[path] then U.textures[path]=getTexture(path) or false end
    return U.textures[path] or nil
end
function U.release(host,key)
    local list=U.sessions[host];local session=list and list[key]
    if not session then return end
    list[key]=nil
    if session.created and session.provider.destroy then
        local renderer=SpriteRenderer and SpriteRenderer.instance
        local additive=renderer and renderer:getDoAdditive()
        local ok,err=pcall(session.provider.destroy,session.context,session.state)
        if renderer then renderer:setDoAdditive(additive) end
        if not ok then print("[ProjectYakuza] UI destroy error: "..tostring(err)) end
    end
end
function U.releaseAll(host)
    local list=U.sessions[host];if not list then return end
    local keys={};for key in pairs(list) do keys[#keys+1]=key end
    for _,key in ipairs(keys) do U.release(host,key) end
    U.sessions[host]=nil
end
function U.render(channel,p,host,extra)
    assert(channels[channel],"unknown UI channel")
    local style
    if channel=="selectorSlot" then style=extra and extra.style
    else style=extra and extra.style or (p and PY.getPlayerStyle(p)) end
    local key=channel..(extra and extra.side or "")
    local id=style and style.ui and style.ui[channel]
    if id==false then U.release(host,key);return true end
    local provider=id and U.providers[id]
    local list=U.sessions[host]
    local session=list and list[key]
    if session and (session.provider~=provider or session.player~=p or session.style~=style) then U.release(host,key);session=nil end
    if not provider then return false end
    if not list then list={};U.sessions[host]=list end
    local time=getTimestampMs()
    if not session then
        session={provider=provider,player=p,style=style,state={},last=time,clock=0};list[key]=session
    end
    if session.failed then return false end
    local paused=isGamePaused();local dt=paused and 0 or math.max(0,math.min(250,time-session.last))/1000
    session.last=time;session.clock=session.clock+dt
    local H=PY.Heat
    local c={player=p,style=style,panel=host,channel=channel,dt=dt,time=session.clock,paused=paused,
        heat=H and H.display(p) or 0,stocks=H and H.stocks(p) or 0,
        maxStocks=H and (H.rules and H.rules(p)or H.config).maxStocks or 0,extreme=H and H.isExtreme(p) or false,
        action=PY.activeActions[p],combo=PY.stateFor and PY.stateFor(p),
        texture=U.texture,binding=PY.Bindings and PY.Bindings.label,inputPrompt=PY.InputPrompts and PY.InputPrompts.describe,drawInputPrompt=PY.InputPrompts and PY.InputPrompts.draw,
        viewport={x=getPlayerScreenLeft(p:getPlayerNum()),y=getPlayerScreenTop(p:getPlayerNum()),
            width=getPlayerScreenWidth(p:getPlayerNum()),height=getPlayerScreenHeight(p:getPlayerNum())},extra=extra or {}}
    session.context=c
    local renderer=SpriteRenderer and SpriteRenderer.instance
    local additive=renderer and renderer:getDoAdditive()
    local ok,handled=pcall(function()
        if not session.created then
            session.created=true
            if provider.create then provider.create(c,session.state) end
        end
        if provider.update then provider.update(c,session.state) end
        return provider.render(c,session.state)==true
    end)
    if renderer then renderer:setDoAdditive(additive) end
    if not ok then
        session.failed=true
        print("[ProjectYakuza] UI provider "..id.." failed: "..tostring(handled))
        if provider.destroy then pcall(provider.destroy,c,session.state) end
        if renderer then renderer:setDoAdditive(additive) end
        session.created=false
        return false
    end
    return handled
end
function U.clear()
    local hosts={};for host in pairs(U.sessions) do hosts[#hosts+1]=host end
    for _,host in ipairs(hosts) do U.releaseAll(host) end
    U.textures={}
end
Events.OnSave.Add(U.clear)
Events.OnMainMenuEnter.Add(U.clear)
