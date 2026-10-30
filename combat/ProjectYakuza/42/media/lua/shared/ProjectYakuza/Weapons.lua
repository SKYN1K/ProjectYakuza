-- Style-owned equipment overlays. Never replaces an item or changes its script/model.
local PY=ProjectYakuza
local W={profiles={},byItem={},views={},equipment=setmetatable({}, {__mode="k"})}
PY.Weapons=W
function W.register(styleId,profile)
    local base=PY.getStyle(styleId)
    assert(base and type(profile)=="table","register the base style before its weapon profile")
    assert(type(profile.id)=="string" and profile.id:match("^[%w_.-]+$"),"weapon profile ID required")
    local profiles=W.profiles[styleId] or {};assert(not profiles[profile.id],"duplicate weapon profile")
    for _,key in ipairs({"standaloneHeavy","quickstepCancelLights"}) do
        assert(profile[key]==nil or type(profile[key])=="boolean",key.." must be boolean")
    end
    assert(type(profile.items)=="table" and #profile.items>0,"explicit weapon item IDs required")
    local lookup=W.byItem[styleId] or {};local seen={}
    for _,id in ipairs(profile.items) do
        assert(type(id)=="string" and id:match("^[%w_]+%.[%w_]+$") and id~=PY.TOKEN,"full weapon item ID required")
        assert(not seen[id] and not lookup[id],"weapon already mapped in this style: "..id);seen[id]=true
    end
    local view={};for key,value in pairs(base) do view[key]=value end
    view.weaponStandaloneHeavy=profile.standaloneHeavy==true
    view.weaponProfile=profile.id;view.lightAttacks=profile.lightAttacks;view.groundAttacks=profile.groundAttacks
    view.actions=profile.actions or {};view.attackSpeed=profile.attackSpeed or 1
    view.quickstepCancelLights=profile.quickstepCancelLights==true
    view.tigerDrop=false;view.enemyReactions=false
    view.hitResponses=profile.hitResponses;view.juggling=profile.juggling
    view.sounds=profile.sounds or false
    local valid,errors=PY.validateStyle(view);assert(valid,table.concat(errors,"; "))
    if view.weaponStandaloneHeavy then
        local slot=view.actions.finisher
        assert(slot and slot.enabled and slot.variants and slot.variants.default,"standaloneHeavy requires actions.finisher.variants.default")
    end
    -- The network resolver addresses moves by nodeValue under the base style ID.
    -- Shared action objects (e.g. the same quicksteps) may deliberately be reused.
    local nodes={}
    local function collect(s)
        local function add(m)
            if m.nodeValue then
                assert(not nodes[m.nodeValue] or nodes[m.nodeValue]==m,"weapon nodeValue already belongs to another move: "..m.nodeValue)
                nodes[m.nodeValue]=m
            end
        end
        for _,m in ipairs(s.lightAttacks or {}) do add(m) end
        for _,m in ipairs(s.groundAttacks or {}) do add(m) end
        for _,slot in pairs(s.actions or {}) do add(slot);for _,m in pairs(slot.variants or {}) do add(m) end end
    end
    collect(base);for _,s in pairs(W.views[styleId] or {}) do collect(s) end;collect(view)
    profiles[profile.id]=profile;W.profiles[styleId]=profiles;W.byItem[styleId]=lookup
    W.views[styleId]=W.views[styleId] or {};W.views[styleId][profile.id]=view
    for id in pairs(seen) do lookup[id]=profile.id end
    PY.emit("weaponProfileRegistered",styleId,profile.id)
    return view
end
function W.profile(styleId,item)
    if not item or PY.isStyleToken(item) then return nil end
    local lookup=W.byItem[styleId];local id=lookup and lookup[item:getFullType()]
    -- No firearms, broken weapons or items merely sharing a display name/category.
    if not id or (item.getCondition and item:getCondition()<=0) then return nil end
    return id
end
function W.view(style,id)
    return id and W.views[style.id] and W.views[style.id][id] or style
end
function W.forPlayer(p,style)
    if not style then return nil end
    local id=W.profile(style.id,p:getPrimaryHandItem())
    if PY.Network and not p:isLocalPlayer() then
        local remote=PY.Network.remote[p:getOnlineID()]
        if remote and remote.packet.equipped then id=remote.packet.weaponProfile end
    end
    return W.view(style,id)
end
function W.matches(p,item)
    if not item or item~=p:getPrimaryHandItem() then return false end
    if PY.isStyleToken(item) then return true end
    local style=PY.getStyle(p:getModData().ProjectYakuzaStyle)
    return style and W.profile(style.id,item)~=nil or false
end
function W.findMove(style,node)
    if not style then return nil end
    for _,m in ipairs(style.lightAttacks or {}) do if m.nodeValue==node then return m end end
    for _,m in ipairs(style.groundAttacks or {}) do if m.nodeValue==node then return m end end
    for _,slot in pairs(style.actions or {}) do
        if slot.nodeValue==node then return slot end
        for _,m in pairs(slot.variants or {}) do if m.nodeValue==node then return m end end
    end
end
function PY.isCombatWeapon(p,item)
    return PY.isStyleToken(item) or W.matches(p,item)
end
-- Supplementary victims use the real weapon's reach, within the framework's
-- existing world/path budget. Native primary-hit collision remains untouched.
function W.hitRange(item)
    local range=item and item.getMaxRange and item:getMaxRange()
    if type(range)~="number" or range~=range or range==math.huge or range==-math.huge then return 1.25 end
    return math.max(.25,math.min(1.65,range))
end
function W.extraDamage(item,damage)
    if type(damage)~="number" or damage~=damage then return 0 end
    local maximum=item and item:getMaxDamage() or 0
    if type(maximum)~="number" or maximum~=maximum or maximum==math.huge or maximum==-math.huge then return 0 end
    -- Do not copy a primary-only knife jaw kill/critical onto every nearby target.
    return math.max(0,math.min(20,maximum,damage))
end
function W.sync(p)
    if not p or not p:isLocalPlayer() then return end
    local item=p:getPrimaryHandItem();local id=p:getModData().ProjectYakuzaStyle
    local profile=W.profile(id,item) or ""
    local old=W.equipment[p]
    if old and (old.item~=item or old.style~=id or old.profile~=profile) then
        if PY.Heat then PY.Heat.endSwing(p);PY.Heat.stop(p,"equipment_changed") end
        if PY.resetPlayer then PY.resetPlayer(p,"equipment_changed") end
        if PY.groundNext then PY.groundNext[p:getPlayerNum()]=1 end
        if PY.Network and isClient and isClient() then
            local net=PY.Network.localState(p)
            net.equipReady=nil;net.equipReply=nil;net.equipWanted=nil;net.equipTarget=nil;net.entryWanted=nil;net.nextEquip=0
        end
    end
    if not old or old.item~=item or old.style~=id or old.profile~=profile then
        W.equipment[p]={item=item,style=id,profile=profile}
        p:setVariable("ProjectYakuzaWeaponProfile",profile)
        if PY.Heat then PY.Heat.playback(p,false) end
        PY.emit("weaponProfileChanged",p,profile,item)
    end
end
if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(W.sync) end
