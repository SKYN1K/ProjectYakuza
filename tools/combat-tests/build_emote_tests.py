from pathlib import Path
from check_source_comments import clean
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent
source=(root/'combat/ProjectYakuza/42/media/lua/client/ProjectYakuza/Emotes.lua').read_text(encoding='utf-8')
fixture=(w/'emote-test-fixture.lua').read_text(encoding='utf-8');assert fixture.count('"ProjectYakuzaFixture:EMOTES"')==1
(w/'emote-tests.lua').write_text(fixture.replace('"ProjectYakuzaFixture:EMOTES"',source),encoding='utf-8')
native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/lua/client/ISUI/ISEmoteRadialMenu.lua').read_text(encoding='utf-8')
cvf=(root/'tools/cvf-emote-reference/mods__CustomVoiceFramework__42__media__lua__client__CustomVoiceFramework__CVF_EmoteMenu.lua').read_text(encoding='utf-8')
integration=(w/'emote-menu-test-fixture.lua').read_text(encoding='utf-8')
for order,providers in [('first',[source,cvf]),('last',[cvf,source])]:
    text=integration.replace('"ProjectYakuzaFixture:NATIVE_MENU"',native).replace('"ProjectYakuzaFixture:PROVIDERS"','\n'.join('do\n'+provider+'\nend'for provider in providers)).replace('ProjectYakuzaFixture:ORDER',order)
    text,_=clean(text,'lua')
    target=w/('emote-menu-'+order+'-tests.lua');target.write_text(text,encoding='utf-8')
