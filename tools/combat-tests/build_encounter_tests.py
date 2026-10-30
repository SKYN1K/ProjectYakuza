from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent
m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'encounter-test-fixture.lua').read_text(encoding='utf-8')
modules=[('REGISTRY','shared/ProjectYakuza/Registry.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('UI','client/ProjectYakuza/StyleUI.lua'),('ENCOUNTER','client/ProjectYakuza/EncounterIntro.lua'),('FONT','client/ProjectYakuza/EncounterFont.lua'),('Y6','client/ProjectYakuza/EncounterIntroY6.lua')]
for marker,path in modules:
 source=(m/path).read_text(encoding='utf-8')
 s=s.replace(fixture_marker(marker),'do local moduleResult=(function()\n'+source+'\nend)() end\n')
(w/'encounter-tests.lua').write_text(s,encoding='utf-8')
