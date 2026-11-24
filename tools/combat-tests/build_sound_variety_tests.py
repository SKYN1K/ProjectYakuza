from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent;m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'heat-audio-test-fixture.lua').read_text(encoding='utf-8').split(fixture_marker('FEEDBACK').strip())[0]+(w/'sound-variety-test-fixture.lua').read_text(encoding='utf-8')
for marker,path in [('VARIETY','shared/ProjectYakuza/SoundVariety.lua'),('FEEDBACK','client/ProjectYakuza/Feedback.lua'),('STATUSHUD','client/ProjectYakuza/HUD.lua')]:s=s.replace(fixture_marker(marker),'do\n'+(m/path).read_text(encoding='utf-8')+'\nend\n')
(w/'sound-variety-tests.lua').write_text(s,encoding='utf-8')
