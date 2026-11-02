from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua'
def embed(paths):return '\n'.join('do\n'+(m/p).read_text(encoding='utf-8')+'\nend' for p in paths)
s=(w/'mp-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace(fixture_marker('SHARED_AND_SERVER').rstrip("\n"),embed(['shared/ProjectYakuza/Registry.lua','shared/ProjectYakuza/Weapons.lua','shared/ProjectYakuza/Juggling.lua','shared/ProjectYakuza/Styles/DragonOfDojima.lua','shared/ProjectYakuza/NetworkCatalog.lua','shared/ProjectYakuza/NetworkProtocol.lua','shared/ProjectYakuza/TauntReactions.lua','shared/ProjectYakuza/SoundVariety.lua','shared/ProjectYakuza/HeatRushPaths.lua','shared/ProjectYakuza/KatanaHeatPaths.lua','shared/ProjectYakuza/BottleHeatPaths.lua','shared/ProjectYakuza/HeatRushRules.lua','shared/ProjectYakuza/HeatActions.lua','server/ProjectYakuza/NetworkServer.lua','server/ProjectYakuza/HeatRushServer.lua']))
s=s.replace(fixture_marker('CLIENT_MODULE').rstrip("\n"),embed(['client/ProjectYakuza/NetworkClient.lua']))
s=s.replace(fixture_marker('REACTIONS_MODULE').rstrip("\n"),embed(['client/ProjectYakuza/Reactions.lua']))
(w/'mp-tests.lua').write_text(s,encoding='utf-8')
