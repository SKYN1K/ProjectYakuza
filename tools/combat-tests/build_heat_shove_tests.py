from fixture_markers import module_source
from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua'
paths=['shared/ProjectYakuza/Bindings.lua','shared/ProjectYakuza/Registry.lua','shared/ProjectYakuza/Styles/DragonOfDojima.lua','shared/ProjectYakuza/Heat.lua','client/ProjectYakuza/Quicksteps.lua']
s=(w/'heat-shove-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace(fixture_marker('MODULES').rstrip("\n"),'\n'.join('do\n'+module_source(m/p)+'\nend' for p in paths))
(w/'heat-shove-tests.lua').write_text(s,encoding='utf-8')
p=w/'framework-tests.lua';s=p.read_text(encoding='utf-8')
s=s.replace('local bindings={FORWARD=17,BACKWARD=31,LEFT=30,RIGHT=32}','local bindings={FORWARD=17,BACKWARD=31,LEFT=30,RIGHT=32,MELEE=57}')
s=s.replace('getKey=function(self,id)return bindings[id]end,getScreenHeight', 'isDoingTextEntry=function()return false end,getKey=function(self,id)return bindings[id]end,getScreenHeight')
s=s.replace('local savedCore=getCore;function getCore()lookups=lookups+1;return savedCore()end', 'local savedCore=getCore;function getCore()local core=savedCore();local original=core.getKey;core.getKey=function(self,id)if id~="MELEE" then lookups=lookups+1 end;return original(self,id)end;return core end')
marker='local Q=ProjectYakuza.Quicksteps\n'
if 'function p:isAuthorizeMeleeAction()' not in s:
 s=s.replace(marker,marker+'function p:isAuthorizeMeleeAction()return self.testShoveAuthorization~=false end\nfunction p:setAuthorizeMeleeAction(value)self.testShoveAuthorization=value end\n',1)
p.write_text(s,encoding='utf-8')
