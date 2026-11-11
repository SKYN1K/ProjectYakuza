from fixture_markers import module_source
from fixture_markers import fixture_marker
from pathlib import Path
import xml.etree.ElementTree as E
w=Path(__file__).parent;m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
s=(w/"weapon-test-fixture.lua").read_text(encoding="utf-8")
for marker,path in [("REGISTRY","shared/ProjectYakuza/Registry.lua"),("WEAPONS","shared/ProjectYakuza/Weapons.lua"),("COMBO","shared/ProjectYakuza/Combo.lua"),("STYLE","shared/ProjectYakuza/Styles/DragonOfDojima.lua"),("BINDINGS","shared/ProjectYakuza/Bindings.lua"),("HEAT","shared/ProjectYakuza/Heat.lua"),("RUNTIME","client/ProjectYakuza/Runtime.lua"),("QUICKSTEPS","client/ProjectYakuza/Quicksteps.lua"),("MULTIHIT","client/ProjectYakuza/MultiHit.lua")]:
 s=s.replace(fixture_marker(marker),"do local moduleResult=(function()\n"+module_source(m/path)+"\nend)() end\n")
menu=(m/'client/ProjectYakuza/Menu.lua').read_text(encoding='utf-8').split('local function disable')[0]
s=s.replace(fixture_marker('MENU_EQUIP'),'do\n'+menu+'\nend\n')
timelines=[]
for label in ['Light01','Light02','Light03']:
 node=E.parse(m.parent/'AnimSets/player/melee'/('ProjectYakuza_DD_Bottle'+label+'.xml')).getroot()
 times={e.findtext('m_ParameterValue').split('=')[0]:float(e.findtext('m_TimePc'))for e in node.findall('m_Events')if e.findtext('m_TimePc')and '='in (e.findtext('m_ParameterValue')or'')}
 timelines.append('{hit='+str(times['ProjectYakuzaHitMarker'])+',chain='+str(times['ProjectYakuzaChainReady'])+'}')
s=s.replace(fixture_marker('BOTTLE_TIMELINE'),'local bottleTimelines={'+','.join(timelines)+'}\n')
(w/"weapon-tests.lua").write_text(s,encoding="utf-8")
