from fixture_markers import module_source
from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
s=(w/"quickstep-once-test-fixture.lua").read_text(encoding="utf-8")
for marker,path in [("REGISTRY","shared/ProjectYakuza/Registry.lua"),("COMBO","shared/ProjectYakuza/Combo.lua"),("STYLE","shared/ProjectYakuza/Styles/DragonOfDojima.lua"),("BINDINGS","shared/ProjectYakuza/Bindings.lua"),("RUNTIME","client/ProjectYakuza/Runtime.lua"),("QUICKSTEPS","client/ProjectYakuza/Quicksteps.lua")]:
 s=s.replace(fixture_marker(marker),"do local moduleResult=(function()\n"+module_source(m/path)+"\nend)() end\n")
(w/"quickstep-once-tests.lua").write_text(s,encoding="utf-8")
