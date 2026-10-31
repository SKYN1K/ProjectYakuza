from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
def embed(paths):return '\n'.join('do\n'+(m/p).read_text(encoding='utf-8')+'\nend' for p in paths)
s=(w/'weapon-mp-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace(fixture_marker('SHARED_AND_SERVER').rstrip("\n"),embed(['shared/ProjectYakuza/Registry.lua','shared/ProjectYakuza/Weapons.lua','shared/ProjectYakuza/Juggling.lua','shared/ProjectYakuza/Styles/DragonOfDojima.lua','shared/ProjectYakuza/NetworkCatalog.lua','shared/ProjectYakuza/NetworkExtensions.lua','shared/ProjectYakuza/NetworkProtocol.lua','shared/ProjectYakuza/BarrageRules.lua','shared/ProjectYakuza/TauntReactions.lua','server/ProjectYakuza/NetworkServer.lua']))
s=s.replace(fixture_marker('CLIENT_MODULE').rstrip("\n"),embed(['client/ProjectYakuza/NetworkClient.lua']))
s=s.replace(fixture_marker('STYLE_ITEM_POLICY'),'do\n'+(m/'shared/ProjectYakuza/StyleItemPolicy.lua').read_text(encoding='utf-8')+'\nend\n')
(w/'weapon-mp-tests.lua').write_text(s,encoding='utf-8')
