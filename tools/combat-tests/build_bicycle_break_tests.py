from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent;root=w.parents[1];source=root/'combat/ProjectYakuza/42/media/lua/client/ProjectYakuza/BicycleBreak.lua';fixture=(w/'bicycle-break-test-fixture.lua').read_text();fixture=fixture.replace(fixture_marker('BICYCLE_BREAK'),source.read_text());(w/'bicycle-break-tests.lua').write_text(fixture)
