from pathlib import Path
from fixture_markers import fixture_marker
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';lua=root/'combat/ProjectYakuza/42/media/lua';text=(w/'input-prompts-test-fixture.lua').read_text(encoding='utf-8')
for key,path in [('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('INPUT_PROMPTS','client/ProjectYakuza/InputPrompts.lua')]:text=text.replace(fixture_marker(key),'do\n'+(lua/path).read_text(encoding='utf-8')+'\nend\n')
(w/'input-prompts-tests.lua').write_text(text,encoding='utf-8')
