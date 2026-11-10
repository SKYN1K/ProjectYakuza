from fixture_markers import module_source
from pathlib import Path
from check_source_comments import strip_lexical
w=Path(__file__).parent;m=w.parent.parent/'combat/ProjectYakuza/42/media/lua';cvf=w.parent.parent/'framework/mods/CustomVoiceFramework/42/media/lua'
def blocks(paths):return '\n'.join('do\n'+strip_lexical(module_source(p)if p.is_relative_to(m)else p.read_text(encoding='utf-8'),'lua')[0]+'\nend' for p in paths)
s=(w/'cvf-combat-test-fixture.lua').read_text(encoding='utf-8')
s=s.replace('do local _="ProjectYakuzaFixture:CVF_PROJECT" end',blocks([m/'shared/ProjectYakuza/Registry.lua',m/'shared/ProjectYakuza/Weapons.lua',m/'shared/ProjectYakuza/Styles/DragonOfDojima.lua',m/'shared/ProjectYakuza/CVFCombatLines.lua',m/'client/ProjectYakuza/CombatVoices.lua']))
s=s.replace('do local _="ProjectYakuzaFixture:CVF_UPSTREAM" end',blocks([cvf/'shared/CustomVoiceFramework/CVF_Core.lua',cvf/'shared/CustomVoiceFramework/CVF_Suffixes.lua',cvf/'shared/CustomVoiceFramework/CVF_Lines.lua',cvf/'client/CustomVoiceFramework/CVF_Playback.lua']))
present=(m/'client/ProjectYakuza/HeatRush.lua').read_text(encoding='utf-8');present=present[present.index('function H.present('):present.index('function A:contact(')]
s=s.replace('do local _="ProjectYakuzaFixture:HEAT_FEEDBACK" end',blocks([m/'shared/ProjectYakuza/SoundVariety.lua',m/'client/ProjectYakuza/Feedback.lua',m/'shared/ProjectYakuza/HeatRushRules.lua'])+'\ndo local PY=ProjectYakuza;local R=PY.HeatRushRules;local H={};PY.HeatRush=H\n'+present+'\nend\n')
scene=(m/'client/ProjectYakuza/HeatActionPresentation.lua').read_text();scene=scene[scene.index('function C.authoredEvents('):scene.index('function C.tick(')]
s=s.replace('do local _="ProjectYakuzaFixture:SCENE_VOICES" end','do local PY=ProjectYakuza;local C={lateMs=100};PY.HeatSceneVoiceProbe=C\n'+scene+'\nend\n')
(w/'cvf-combat-tests.lua').write_text(s,encoding='utf-8')
