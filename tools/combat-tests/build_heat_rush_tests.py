from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent;m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'weapon-test-fixture.lua').read_text(encoding='utf-8').split('local W=PY.Weapons;')[0]+(w/'heat-rush-test-fixture.lua').read_text(encoding='utf-8')
for marker,path in [('REGISTRY','shared/ProjectYakuza/Registry.lua'),('WEAPONS','shared/ProjectYakuza/Weapons.lua'),('COMBO','shared/ProjectYakuza/Combo.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('HEAT','shared/ProjectYakuza/Heat.lua'),('RUNTIME','client/ProjectYakuza/Runtime.lua'),('QUICKSTEPS','client/ProjectYakuza/Quicksteps.lua'),('MULTIHIT','client/ProjectYakuza/MultiHit.lua'),('PATHS','shared/ProjectYakuza/HeatRushPaths.lua'),('KATANA_PATHS','shared/ProjectYakuza/KatanaHeatPaths.lua'),('BOTTLE_PATHS','shared/ProjectYakuza/BottleHeatPaths.lua'),('RUSH_RULES','shared/ProjectYakuza/HeatRushRules.lua'),('HEAT_ACTIONS','shared/ProjectYakuza/HeatActions.lua'),('QTE_FEEDBACK','client/ProjectYakuza/QTEFeedback.lua'),('RUSH','client/ProjectYakuza/HeatRush.lua'),('RUSH_UI','client/ProjectYakuza/HeatRushUI.lua')]:
 s=s.replace(fixture_marker(marker),'do local result=(function()\n'+(m/path).read_text(encoding='utf-8')+'\nend)()end\n')
s=s.replace(fixture_marker('INPUT_PROMPTS'),'do\n'+(m/'client/ProjectYakuza/InputPrompts.lua').read_text(encoding='utf-8')+'\nend\n')
menu=(m/'client/ProjectYakuza/Menu.lua').read_text(encoding='utf-8').split('local function disable')[0];s=s.replace(fixture_marker('MENU_EQUIP'),'do\n'+menu+'\nend\n')
(w/'heat-rush-tests.lua').write_text(s,encoding='utf-8')
