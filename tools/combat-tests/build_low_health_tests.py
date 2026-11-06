from pathlib import Path
from fixture_markers import fixture_marker,module_source
w=Path(__file__).parent;root=w.parents[1];lua=root/'combat/ProjectYakuza/42/media/lua'
s=(w/'low-health-test-fixture.lua').read_text()
for marker,path in [('REGISTRY','shared/ProjectYakuza/Registry.lua'),('WEAPONS','shared/ProjectYakuza/Weapons.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('LOW','client/ProjectYakuza/LowHealthFeedback.lua'),('HUD','client/ProjectYakuza/HeatUI.lua')]:s=s.replace(fixture_marker(marker),'do\n'+module_source(lua/path)+'\nend\n')
(w/'low-health-tests.lua').write_text(s)
