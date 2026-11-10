from fixture_markers import module_source
from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua'
s=(w/'taunt-test-fixture.lua').read_text(encoding='utf-8-sig')
for mark,file in [('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('REGISTRY','shared/ProjectYakuza/Registry.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('TAUNTS','client/ProjectYakuza/Taunts.lua'),('OUTLINE','client/ProjectYakuza/HeatOutline.lua'),('AURA','client/ProjectYakuza/HeatAura.lua'),('CATALOG','shared/ProjectYakuza/NetworkCatalog.lua'),('PROTOCOL','shared/ProjectYakuza/NetworkProtocol.lua')]:
 s=s.replace(fixture_marker(mark),'do\n'+module_source(m/file)+'\nend\n')
(w/'taunt-tests.lua').write_text(s,encoding='utf-8')
