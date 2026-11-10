from fixture_markers import module_source
from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent
m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
s=(w/"style-entry-test-fixture.lua").read_text(encoding="utf-8")
for marker,module in [("BINDINGS","shared/ProjectYakuza/Bindings.lua"),("REGISTRY","shared/ProjectYakuza/Registry.lua"),("STYLE","shared/ProjectYakuza/Styles/DragonOfDojima.lua"),("ENTRY","client/ProjectYakuza/StyleEntry.lua")]:
 s=s.replace(fixture_marker(marker),"do\n"+module_source(m/module)+"\nend\n")
(w/"style-entry-tests.lua").write_text(s,encoding="utf-8")
