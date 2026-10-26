-- Input settings are owned by this mod; native aiming/movement remain PZ binds.
ProjectYakuza=ProjectYakuza or {}
local ProjectYakuza=ProjectYakuza
local B={edges=setmetatable({}, {__mode="k"}),attackGates=setmetatable({}, {__mode="k"})}
ProjectYakuza.Bindings=B
B.definitions={
 {id="light",name="Light attack",mode=1},
 {id="finisher",name="Finisher / double finisher",mode=3},
 {id="runningLight",name="Running attack",mode=1},
 {id="dropkick",name="Running dropkick",mode=3},
 {id="quickstepAttack",name="Quickstep attack",mode=1},
 {id="counter",name="Tiger Drop",mode=3},
 {id="throw",name="Throw held zombie",mode=3},
 {id="quickstep",name="Quickstep",mode=4,key="KEY_SPACE",code=57},
 {id="block",name="Block",mode=4,key="KEY_X",code=45},
 {id="grab",name="Grab / release",mode=4,key="KEY_G",code=34},
 {id="taunt",name="Taunt",mode=4,key="KEY_Q",code=16},
 {id="extremeHeat",name="Extreme Heat activation",mode=4,key="KEY_N",code=49},
 {id="styles",name="Style selector",mode=4,key="KEY_Z",code=44},
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
function B.configure(options)
 B.options=options;options:addTitle("Controls")
 options:addDescription("Choose a mouse button or Keyboard, then set its key. Aim and movement use Project Zomboid's own bindings. Shift is no longer a quickstep shortcut.")
 for _,d in ipairs(B.definitions) do
  local mode=options:addComboBox("input_"..d.id,"UI_ProjectYakuza_Bind_"..d.id)
  for i,label in ipairs({"Left mouse button","Right mouse button","Middle mouse button","Keyboard"}) do mode:addItem(label,i==d.mode) end
  options:addKeyBind("key_"..d.id,"UI_ProjectYakuza_Key_"..d.id,(d.key and Keyboard and Keyboard[d.key]) or d.code or 0)
 end
end
function B.restore(p)
 local old=B.attackGates[p];if old then p:setAuthorizeMeleeAction(old.allowed);B.attackGates[p]=nil end
end
function B.update(p)
 if not p or not p:isLocalPlayer() then return end
 local custom=B.mode("light")~=1 or B.mode("runningLight")~=1 or B.mode("quickstepAttack")~=1
 local wheel=ProjectYakuza.StyleSelector and (ProjectYakuza.StyleSelector.wheel or ProjectYakuza.StyleSelector.setup)
 local action=ProjectYakuza.activeActions and ProjectYakuza.activeActions[p]
 local entry=action and action.kind=="styleEntry"
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
 B.edges=setmetatable({}, {__mode="k"})
end
if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(B.update) end
if Events and Events.OnSave then Events.OnSave.Add(B.clear) end
if Events and Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(B.clear) end
