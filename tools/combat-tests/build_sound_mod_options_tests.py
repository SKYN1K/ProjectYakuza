from fixture_markers import module_source
from pathlib import Path
from fixture_markers import fixture_marker
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/PZAPI/ModOptions.lua')
paths=[m/'shared/ProjectYakuza/Bindings.lua',m/'shared/ProjectYakuza/Registry.lua',m/'shared/ProjectYakuza/Styles/DragonOfDojima.lua',native,m/'client/ProjectYakuza/SoundSettings.lua']
s=(w/'sound-mod-options-fixture.lua').read_text(encoding='utf-8')
s=s.replace(fixture_marker('PRODUCTION_MODULES'),'\n'.join('do\n'+module_source(p)+'\nend' for p in paths)+'\n')
(w/'sound-mod-options-tests.lua').write_text(s,encoding='utf-8')
