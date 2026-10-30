from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua'
modules=['shared/ProjectYakuza/Bindings.lua','shared/ProjectYakuza/Registry.lua','shared/ProjectYakuza/StyleSlots.lua','client/ProjectYakuza/StyleUI.lua','client/ProjectYakuza/StyleSelector.lua']
s=(w/'style-selector-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace(fixture_marker('MODULES'),'\n'.join('do\n'+(m/p).read_text(encoding='utf-8')+'\nend' for p in modules)+'\n')
(w/'style-selector-tests.lua').write_text(s,encoding='utf-8')
