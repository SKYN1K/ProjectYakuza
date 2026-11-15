from fixture_markers import module_source
from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent
m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
prefix=(w/'weapon-test-fixture.lua').read_text(encoding='utf-8').split('local W=PY.Weapons;')[0]
tail=(w/'style-item-test-fixture.lua').read_text(encoding='utf-8')
s=prefix+tail
modules={'REGISTRY':'shared/ProjectYakuza/Registry.lua','WEAPONS':'shared/ProjectYakuza/Weapons.lua','COMBO':'shared/ProjectYakuza/Combo.lua','STYLE':'shared/ProjectYakuza/Styles/DragonOfDojima.lua','BINDINGS':'shared/ProjectYakuza/Bindings.lua','HEAT':'shared/ProjectYakuza/Heat.lua','RUNTIME':'client/ProjectYakuza/Runtime.lua','QUICKSTEPS':'client/ProjectYakuza/Quicksteps.lua','MULTIHIT':'client/ProjectYakuza/MultiHit.lua','POLICY':'shared/ProjectYakuza/StyleItemPolicy.lua','CLIENT_ITEM':'client/ProjectYakuza/StyleItem.lua'}
modules['UI_AUDIO']='client/ProjectYakuza/UIAudio.lua'
for marker,path in modules.items():
 s=s.replace(fixture_marker(marker),'do local moduleResult=(function()\n'+module_source(m/path)+'\nend)() end\n')
menu=(m/'client/ProjectYakuza/Menu.lua').read_text(encoding='utf-8').split('local function disable')[0]
s=s.replace(fixture_marker('MENU_EQUIP'),'do\n'+menu+'\nend\n')
(w/'style-item-tests.lua').write_text(s,encoding='utf-8')
