from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent
m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'blood-test-fixture.lua').read_text(encoding='utf-8')
for marker,path in [('WORLD','WorldEffects.lua'),('BLOOD','BloodEffects.lua'),('HITS','HitEffects.lua')]:
 s=s.replace(fixture_marker(marker),'do\n'+(m/'client/ProjectYakuza'/path).read_text(encoding='utf-8')+'\nend\n')
(w/'blood-tests.lua').write_text(s,encoding='utf-8')
