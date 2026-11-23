
ProjectYakuza=ProjectYakuza or {}
local ProjectYakuza=ProjectYakuza
local B={edges=setmetatable({}, {__mode="k"}),attackGates=setmetatable({}, {__mode="k"}),shoveGates=setmetatable({}, {__mode="k"})}
ProjectYakuza.Bindings=B
B.definitions={
 {id="light",name="Light Attack",mode=1},
 {id="heatAction",name="Heat Action",mode=3},
 {id="finisher",name="Heavy Attack / Finisher",mode=3},
 {id="quickstep",name="Quickstep",mode=4,key="KEY_SPACE",code=57},
 {id="block",name="Block",mode=4,key="KEY_X",code=45},
 {id="grab",name="Grab / Throw",mode=4,key="KEY_G",code=34},
 {id="taunt",name="Taunt",mode=4,key="KEY_Q",code=16},
 {id="extremeHeat",name="Extreme Heat",mode=4,key="KEY_N",code=49},
 {id="styles",name="Style Selector",mode=4,key="KEY_Z",code=44},
}
B.byId={};for _,d in ipairs(B.definitions) do B.byId[d.id]=d end
function B.mode(id)
 local d=B.byId[id];local o=B.options and B.options:getOption("input_"..id)
 return o and o:getValue() or d.mode
end
function B.key(id)
 local d=B.byId[id];local o=B.options and B.options:getOption("key_"..id)
 return o and o:getValue() or (d.key and Keyboard and Keyboard[d.key]) or d.code or 0
end
function B.down(id)
 local mode=B.mode(id)
 if mode>=1 and mode<=3 then return isMouseButtonDown(mode-1) end
 local key=B.key(id);return key and key>0 and isKeyDown(key) or false
end
function B.matches(id,key)return B.mode(id)==4 and B.key(id)>0 and B.key(id)==key end
function B.pressed(p,id)
 local s=B.edges[p];if not s then s={};B.edges[p]=s end
 local down=B.down(id);local pressed=down and not s[id];s[id]=down;return pressed
end
function B.label(id)
 local mode=B.mode(id);if mode<=3 then return ({"LMB","RMB","MMB"})[mode] end
 return B.key(id)>0 and getKeyName(B.key(id)) or "Unbound"
end
local function caption(d,keyboard)
 local key="UI_ProjectYakuza_"..(keyboard and "Key_" or "Bind_")..d.id
 local text=not d.custom and getText(key)
 if text and text~=key then return text end
 return d.name..(keyboard and " keyboard bind" or " keybind type")
end
function B.configureDefinition(d)
 local options=B.options
 if not options then return end
 local mode=options:addComboBox("input_"..d.id,caption(d,false))
 for i,label in ipairs({"Left mouse button","Right mouse button","Middle mouse button","Keyboard"}) do mode:addItem(label,i==d.mode) end
 options:addKeyBind("key_"..d.id,caption(d,true),(d.key and Keyboard and Keyboard[d.key]) or d.code or 0)
end
function B.register(definition)
 assert(type(definition)=="table","binding definition required")
 local d=definition
 assert(type(d.id)=="string" and string.match(d.id,"^[%w_.-]+$"),"namespaced binding ID required")
 assert(not B.byId[d.id],"binding already registered: "..d.id)
 assert(type(d.name)=="string" and d.name~="","binding display name required")
 assert(type(d.mode)=="number" and d.mode>=1 and d.mode<=4 and d.mode==math.floor(d.mode),"binding mode must be 1..4")
 assert(d.code==nil or (type(d.code)=="number" and d.code>=0 and d.code<=65535 and d.code==math.floor(d.code)),"key code must be 0..65535")
 assert(d.key==nil or type(d.key)=="string","key must name a Keyboard constant")
 local copy={id=d.id,name=d.name,mode=d.mode,key=d.key,code=d.code or 0,custom=true}
 B.byId[copy.id]=copy;B.definitions[#B.definitions+1]=copy
 B.configureDefinition(copy)
 return copy
end
function B.configure(options)
 B.options=options;options:addTitle("Controls")
 options:addDescription("Choose a mouse button, or select Keyboard and assign a key. Aiming and movement use your normal Project Zomboid controls.")
 for _,d in ipairs(B.definitions) do B.configureDefinition(d) end
 if ISDuplicateKeybindDialog and not B.conflictLabels then
  B.conflictLabels=true
  for _,method in ipairs({"createChildren","nextDuplicate"})do
   local original=ISDuplicateKeybindDialog[method]
   ISDuplicateKeybindDialog[method]=function(dialog,...)
    local result=original(dialog,...)
    for _,d in ipairs(B.definitions)do
     local key="UI_ProjectYakuza_Key_"..d.id;local label=caption(d,true)
     if dialog.label and(dialog.keybind2Name==key or dialog.keybind2Name==label)then
      dialog.label.name=getText("UI_optionscreen_keyAlreadyBinded",getKeyName(dialog.key),label,label):gsub("\\n","\n"):gsub('\\"','"');break
     end
    end
    return result
   end
  end
 end
end
function B.restore(p)
 local old=B.attackGates[p];if old then p:setAuthorizeMeleeAction(old.allowed);B.attackGates[p]=nil end
end
function B.restoreShove(p)
 local old=B.shoveGates[p]
 if old then p:setAuthorizeShoveStomp(old.allowed);B.shoveGates[p]=nil end
end
function B.updateShove(p)
 if not p.setAuthorizeShoveStomp or not p.isAuthorizeShoveStomp then return end
 if ProjectYakuza.isEquipped and ProjectYakuza.isEquipped(p)and not p:isDead()then
  if not B.shoveGates[p]then B.shoveGates[p]={allowed=p:isAuthorizeShoveStomp()}end
  p:setAuthorizeShoveStomp(false)
 else B.restoreShove(p)end
end
function B.update(p)
 if not p or not p:isLocalPlayer() then return end
 B.updateShove(p)
 if p:GetVariable("ProjectYakuzaHeatRushVictim")=="true"then B.restore(p);p:setAuthorizeMeleeAction(false);return end
 local custom=B.mode("light")~=1
 local wheel=ProjectYakuza.StyleSelector and (ProjectYakuza.StyleSelector.wheel or ProjectYakuza.StyleSelector.setup)
 local action=ProjectYakuza.activeActions and ProjectYakuza.activeActions[p]
 local entry=(ProjectYakuza.blocksNativeAttacks and ProjectYakuza.blocksNativeAttacks(p)) or (action and action.kind=="styleEntry")
 if ProjectYakuza.isEquipped and ProjectYakuza.isEquipped(p) and not p:isDead() and (custom or wheel or entry) then
  if not B.attackGates[p] then
   local shove=ProjectYakuza.Quicksteps and ProjectYakuza.Quicksteps.shoveAuth[p]
   B.attackGates[p]={allowed=shove and shove.allowed or p:isAuthorizeMeleeAction()}
  end
  p:setAuthorizeMeleeAction(false)
 else B.restore(p) end
end
function B.clear()
 for p in pairs(B.attackGates) do B.restore(p) end
 for p in pairs(B.shoveGates) do B.restoreShove(p)end
 B.edges=setmetatable({}, {__mode="k"})
end
if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(B.update) end
if Events and Events.OnSave then Events.OnSave.Add(B.clear) end
if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(B.clear) end
