from pathlib import Path
from fixture_markers import fixture_marker
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent
source=(root/'combat/ProjectYakuza/42/media/lua/client/ProjectYakuza/Locomotion.lua').read_text()
s=(w/'locomotion-test-fixture.lua').read_text().replace(fixture_marker('LOCOMOTION'),'do\n'+source+'\nend\n')
(w/'locomotion-tests.lua').write_text(s,newline='\n')
