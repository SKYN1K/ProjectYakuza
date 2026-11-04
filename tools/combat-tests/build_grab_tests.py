from pathlib import Path
from fixture_markers import fixture_marker,module_source
w=Path(__file__).parent;m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'weapon-test-fixture.lua').read_text().split('local W=PY.Weapons;')[0]+(w/'grab-test-fixture.lua').read_text()
for marker,path in [('REGISTRY','shared/ProjectYakuza/Registry.lua'),('WEAPONS','shared/ProjectYakuza/Weapons.lua'),('COMBO','shared/ProjectYakuza/Combo.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('HEAT','shared/ProjectYakuza/Heat.lua'),('RUNTIME','client/ProjectYakuza/Runtime.lua'),('QUICKSTEPS','client/ProjectYakuza/Quicksteps.lua'),('MULTIHIT','client/ProjectYakuza/MultiHit.lua'),('MENU_EQUIP','client/ProjectYakuza/Menu.lua'),('GRAB_RULES','shared/ProjectYakuza/GrabRules.lua'),('RUSH_RULES','shared/ProjectYakuza/HeatRushRules.lua'),('HEAT_ACTIONS','shared/ProjectYakuza/HeatActions.lua'),('DEFENSE','client/ProjectYakuza/Defense.lua'),('RUSH','client/ProjectYakuza/HeatRush.lua'),('GRAB_COMBAT','client/ProjectYakuza/GrabCombat.lua')]:
 s=s.replace(fixture_marker(marker),'do local result=(function()\n'+module_source(m/path)+'\nend)()end\n')
(w/'grab-tests.lua').write_text(s,encoding='utf-8')
