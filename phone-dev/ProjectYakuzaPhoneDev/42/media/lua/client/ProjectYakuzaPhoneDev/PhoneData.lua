require "ProjectYakuzaPhoneDev/PhoneMath"
require "ProjectYakuza/StyleSelector"
require "ProjectYakuza/Heat"
require "ProjectYakuza/Menu"
require "ISUI/ISInventoryPaneContextMenu"
local PY=ProjectYakuza
local D=PY.PhoneDev
D.pages={{id="styles",label="Styles",description="Styles and quick slots."},{id="equipment",label="Equipment",description="Weapons in your inventory."},{id="combat",label="Combat",description="Condition and combat rules."},{id="heat",label="Heat",description="Heat and Extreme Heat."},{id="audio",label="Audio",description="Music, impacts and voices."},{id="effects",label="Effects",description="Choose your visual effects."},{id="grabs",label="Grabs",description="Grabs, throws and Heat Actions."},{id="controls",label="Controls",description="Your current combat bindings."},{id="settings",label="Settings",description="Phone and advanced settings."}}
function D.preferences(p)
    local data=p:getModData()
    if type(data.ProjectYakuzaPhoneDev)~="table"then data.ProjectYakuzaPhoneDev={page=2,tilt=true,reduceMotion=false}end
    return data.ProjectYakuzaPhoneDev
end
local function status(v)return v and "On"or "Off"end
local function add(rows,label,detail,action,adjust)
    rows[#rows+1]={label=tostring(label),detail=tostring(detail or ""),action=action,adjust=adjust}
end
local function after(p,fn)
    if PY.isBusy(p)then return false,"Finish your current action first."end
    if D.panel then D.panel:close(false,fn)else fn()end
    return true
end
local function flag(p,module,key)
    if PY[module]and PY[module].toggle then PY[module].toggle(p)else local md=p:getModData();md[key]=not md[key]end
end
local function cycleSlot(p,side)
    local entries=PY.listStyles();local ids={false};for _,style in ipairs(entries)do ids[#ids+1]=style.id end
    local id=PY.StyleSlots.id(p,side);local index=1;for i,v in ipairs(ids)do if v==id then index=i end end
    return PY.StyleSlots.assign(p,side,ids[index%#ids+1]or nil)
end
function D.volume(id,delta)
    local options=PZAPI.ModOptions:getOptions("ProjectYakuza");local option=options and options:getOption(id)
    if not option then return false,"Audio settings are not ready."end
    option:setValue(D.Math.clamp(option:getValue()+delta,option.min,option.max));options:apply();PZAPI.ModOptions:save();return true
end
function D.rows(p,page)
    local rows={};local style=PY.getPlayerStyle(p);local md=p:getModData();local binding=PY.Bindings.label
    if page=="styles"then
        add(rows,"Current style",PY.isEquipped(p)and style and style.name or "No style equipped")
        for _,entry in ipairs(PY.listStyles())do local id=entry.id;add(rows,"Equip "..entry.name,"Switch to this style",function()return after(p,function()PY.equipStyle(p,id)end)end)end
        for _,side in ipairs({"left","right"})do local slot=side;local current=PY.getStyle(PY.StyleSlots.id(p,side));add(rows,side=="left"and"First style slot"or"Second style slot",(current and current.name or "Empty").."  |  Select to cycle",function()return cycleSlot(p,slot)end)end
        add(rows,"Unequip style","Return to ordinary weapon handling",function()return after(p,function()PY.unequipStyle(p)end)end)
    elseif page=="equipment"then
        local held=p:getPrimaryHandItem();add(rows,"In hand",held and held:getDisplayName()or"Empty")
        local items=p:getInventory():getItems();local weapons={}
        for i=0,items:size()-1 do local item=items:get(i);if instanceof(item,"HandWeapon")and not PY.isStyleToken(item)then weapons[#weapons+1]={item=item,name=item:getDisplayName()}end end
        table.sort(weapons,function(a,b)return a.name<b.name end)
        for _,entry in ipairs(weapons)do local weapon=entry.item;local max=math.max(1,weapon:getConditionMax());add(rows,entry.name,"Condition "..math.floor(weapon:getCondition()/max*100).."%  |  Select to equip",function()
            if not p:getInventory():contains(weapon)then return false,"That weapon is no longer in your inventory."end
            return after(p,function()ISInventoryPaneContextMenu.equipWeapon(weapon,true,weapon:isTwoHandWeapon(),p:getPlayerNum())end)
        end)end
        if #weapons==0 then add(rows,"No weapons in this container","Weapons in your main inventory appear here.")end
        add(rows,"Open inventory","Use the normal inventory and containers",function()return after(p,function()local inventory=getPlayerInventory(p:getPlayerNum());if inventory then inventory:setVisible(true)end end)end)
    elseif page=="combat"then
        add(rows,"Health",math.floor(p:getBodyDamage():getOverallBodyHealth()+.5).." / 100")
        add(rows,"Fighting style",style and style.name or"None")
        add(rows,"Tiger Drop",PY.Sandbox.tigerDrop(style)and"Enabled"or"Disabled by sandbox rules")
        add(rows,"Tiger Drop window",PY.Sandbox.tigerWindowMs(style).." ms")
        add(rows,"Tiger Drop cooldown",string.format("%.1f seconds",PY.Sandbox.tigerCooldownMs(style)/1000))
        add(rows,"Quickstep",binding("quickstep").."  |  Aim and step away from an attack")
    elseif page=="heat"then
        local rules=PY.Heat.rules(p);add(rows,"Heat orbs",PY.Heat.stocks(p).." / "..rules.maxStocks)
        add(rows,"Extreme Heat",status(PY.Heat.isExtreme(p)).."  |  "..binding("extremeHeat"))
        add(rows,"Heat Actions",PY.Sandbox.enabled("HeatActions")and"Enabled  |  "..binding("heatAction")or"Disabled by sandbox rules")
        add(rows,"Idle heat drain",string.format("Starts after %.1fs without combat",rules.idleGraceMs/1000))
        add(rows,"Heat aura",status(not md.ProjectYakuzaHeatAuraDisabled),function()flag(p,"HeatAura","ProjectYakuzaHeatAuraDisabled");return true end)
    elseif page=="audio"then
        local options=PZAPI.ModOptions:getOptions("ProjectYakuza")
        for _,entry in ipairs({{"musicVolume","Combat music"},{"hitVolume","Hit sounds"},{"voiceVolume","Voices"}})do local id=entry[1];local option=options and options:getOption(id)
            add(rows,entry[2],tostring(option and option:getValue()or 100).."%",function()return D.volume(id,10)end,function(delta)return D.volume(id,delta*10)end)
        end
        add(rows,"Menu sounds","Local Yakuza 6 interface sounds")
    elseif page=="effects"then
        add(rows,"Hit effects",status(not md.ProjectYakuzaHitEffectsDisabled),function()flag(p,"HitEffects","ProjectYakuzaHitEffectsDisabled");return true end)
        add(rows,"Heat aura",status(not md.ProjectYakuzaHeatAuraDisabled),function()flag(p,"HeatAura","ProjectYakuzaHeatAuraDisabled");return true end)
    elseif page=="grabs"then
        add(rows,"Grabs",PY.Sandbox.enabled("Grabs")and"Enabled"or"Disabled by sandbox rules")
        add(rows,"Grab / throw",binding("grab").."  |  Use while close to a zombie")
        add(rows,"Grab Heat Action",binding("heatAction").."  |  Hold a zombie with enough heat")
        add(rows,"Weapon Heat Actions","Hold a supported weapon and face a nearby target")
    elseif page=="controls"then
        for _,definition in ipairs(PY.Bindings.definitions)do add(rows,definition.name,binding(definition.id))end
        add(rows,"Change bindings","Options > Mods > Project Yakuza")
    elseif page=="settings"then
        local pref=D.preferences(p)
        add(rows,"Pointer tilt",status(pref.tilt~=false),function()pref.tilt=pref.tilt==false;return true end)
        add(rows,"Reduced motion",status(pref.reduceMotion==true),function()pref.reduceMotion=not pref.reduceMotion;return true end)
        add(rows,"Advanced mod settings","Style slots, effects and diagnostics",function()return after(p,function()D.legacyOpenSetup(p)end)end)
        add(rows,"Phone development build",D.VERSION.."  |  Combat "..PY.VERSION)
    end
    return rows
end
