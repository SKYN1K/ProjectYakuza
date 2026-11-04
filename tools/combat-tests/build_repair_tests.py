from fixture_markers import module_source
from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent;m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'weapon-test-fixture.lua').read_text(encoding='utf-8').split('local W=PY.Weapons;')[0]+(w/'repair-test-fixture.lua').read_text(encoding='utf-8')
for marker,path in [('REGISTRY','shared/ProjectYakuza/Registry.lua'),('WEAPONS','shared/ProjectYakuza/Weapons.lua'),('COMBO','shared/ProjectYakuza/Combo.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('HEAT','shared/ProjectYakuza/Heat.lua'),('RUNTIME','client/ProjectYakuza/Runtime.lua'),('QUICKSTEPS','client/ProjectYakuza/Quicksteps.lua'),('MULTIHIT','client/ProjectYakuza/MultiHit.lua'),('TIGER','client/ProjectYakuza/TigerDrop.lua'),('MUSIC','client/ProjectYakuza/CombatMusic.lua')]:
 s=s.replace(fixture_marker(marker),'do local moduleResult=(function()\n'+module_source(m/path)+'\nend)() end\n')
s=s.replace(fixture_marker('MENU_EQUIP'),'')
(w/'repair-tests.lua').write_text(s,encoding='utf-8')
