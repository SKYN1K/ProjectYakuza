from pathlib import Path
w=Path(__file__).parent;m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
s=(w/"extension-api-test-fixture.lua").read_text(encoding="utf-8")
for marker,path in [("REGISTRY","shared/ProjectYakuza/Registry.lua"),("COMBO","shared/ProjectYakuza/Combo.lua"),("BINDINGS","shared/ProjectYakuza/Bindings.lua"),("NETWORK_EXTENSIONS","shared/ProjectYakuza/NetworkExtensions.lua"),("RUNTIME","client/ProjectYakuza/Runtime.lua")]:
 s=s.replace("-- "+marker+"\n","do local moduleResult=(function()\n"+(m/path).read_text(encoding="utf-8")+"\nend)() end\n")
(w/"extension-api-tests.lua").write_text(s,encoding="utf-8")
starter=m.parents[2]/"templates/StyleSubmod/42/media/lua"
prefix=(w/"style-entry-test-fixture.lua").read_text(encoding="utf-8").split("-- ENTRY\n")[0]
for marker,path in [("BINDINGS",m/"shared/ProjectYakuza/Bindings.lua"),("REGISTRY",m/"shared/ProjectYakuza/Registry.lua"),("STYLE",starter/"shared/ExampleStyle_Style.lua.example")]:
 prefix=prefix.replace("-- "+marker+"\n","do\n"+path.read_text(encoding="utf-8")+"\nend\n")
prefix+='\np.data.ProjectYakuzaStyle="example_mod.my_style"\ndo\n'+(starter/"client/ExampleStyle_Flourish.lua.example").read_text(encoding="utf-8")+'\nend\n'
prefix+='''
local kind="example_mod.flourish"
local function begin()
 p.nativeAction=nil;p.hit='';p.aim=true
 check(ProjectYakuza.requestAction(p,kind),'starter custom action queues')
 local c=ProjectYakuza.activeActions[p];local a=c.timedAction
 a.action={};p.nativeAction=a.action;a:start();return a,c
end
local a,c=begin()
check(not p.block and not p.ignore and p.deferred,'starter changes no movement or protection flags')
p:setVariable('ExampleStyleFlourish','started');a:update()
p:setVariable('ExampleStyleFlourish','done');a:update()
check(a.completed and not ProjectYakuza.activeActions[p],'starter real end marker completes ownership')
a,c=begin();p.hit='Bite';a:update();p.hit=''
check(a.stopped and not ProjectYakuza.activeActions[p],'starter hit interruption cleans native action')
a,c=begin();clock=clock+601;a:update()
check(a.stopped and not ProjectYakuza.activeActions[p],'starter missing clip cancels')
queueFail=true;p.nativeAction=nil
check(not ProjectYakuza.requestAction(p,kind) and not ProjectYakuza.activeActions[p],'starter rejected queue has no effects')
queueFail=false
check(ProjectYakuza.Bindings.key('example_mod.flourish')==0,'starter custom control begins unbound')
return 'PASS '..checks..' shipped starter lifecycle and missing-playback checks'
'''
(w/"addon-starter-tests.lua").write_text(prefix,encoding="utf-8")
