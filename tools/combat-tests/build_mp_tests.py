from pathlib import Path
w=Path(__file__).parent;m=w.parent.parent/'combat/DragonCombatFramework/42/media/lua'
def embed(paths):return '\n'.join('do\n'+(m/p).read_text(encoding='utf-8')+'\nend' for p in paths)
s=(w/'mp-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace('-- SHARED_AND_SERVER',embed(['shared/DCF/Registry.lua','shared/DCF/Styles/DragonOfDojima.lua','shared/DCF/NetworkCatalog.lua','shared/DCF/NetworkProtocol.lua','server/DCF/NetworkServer.lua']))
s=s.replace('-- CLIENT_MODULE',embed(['client/DCF/NetworkClient.lua']))
s=s.replace('-- REACTIONS_MODULE',embed(['client/DCF/Reactions.lua']))
(w/'mp-tests.lua').write_text(s,encoding='utf-8')
