from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent;mod=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'heat-damage-test-fixture.lua').read_text(encoding='utf-8').replace(fixture_marker('HEAT_ACTIONS'),'do\n'+(mod/'shared/ProjectYakuza/HeatActions.lua').read_text(encoding='utf-8')+'\nend\n')
(w/'heat-damage-tests.lua').write_text(s,encoding='utf-8')
