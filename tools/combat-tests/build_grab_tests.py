from pathlib import Path
from fixture_markers import fixture_marker,module_source
w=Path(__file__).parent;m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
s=(w/'weapon-test-fixture.lua').read_text().split('local W=PY.Weapons;')[0]+(w/'grab-test-fixture.lua').read_text()
for marker,path in [('REGISTRY','shared/ProjectYakuza/Registry.lua'),('WEAPONS','shared/ProjectYakuza/Weapons.lua'),('COMBO','shared/ProjectYakuza/Combo.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('HEAT','shared/ProjectYakuza/Heat.lua'),('RUNTIME','client/ProjectYakuza/Runtime.lua'),('QUICKSTEPS','client/ProjectYakuza/Quicksteps.lua'),('MULTIHIT','client/ProjectYakuza/MultiHit.lua'),('MENU_EQUIP','client/ProjectYakuza/Menu.lua'),('GRAB_RULES','shared/ProjectYakuza/GrabRules.lua'),('RUSH_RULES','shared/ProjectYakuza/HeatRushRules.lua'),('HEAT_ACTIONS','shared/ProjectYakuza/HeatActions.lua'),('DEFENSE','client/ProjectYakuza/Defense.lua'),('RUSH','client/ProjectYakuza/HeatRush.lua'),('GRAB_COMBAT','client/ProjectYakuza/GrabCombat.lua')]:
 s=s.replace(fixture_marker(marker),'do local result=(function()\n'+module_source(m/path)+'\nend)()end\n')
(w/'grab-tests.lua').write_text(s,encoding='utf-8')

source=(m/'client/ProjectYakuza/AttackEffects.lua').read_text(encoding='utf-8')
function=source[source.index('function F.findTrack'):source.index('function F.attachmentWeight')]
track_test="""local F={}
"""+function+"""
local tracks={{name='strike',time=.03,weight=.08},{name='strike',time=.86,weight=.92}}
local p={dbgGetAnimTrackName=function(_,layer,slot)return layer==0 and tracks[slot+1]and tracks[slot+1].name or ''end,dbgGetAnimTrackTime=function(_,layer,slot)return tracks[slot+1].time end,dbgGetAnimTrackWeight=function(_,layer,slot)return tracks[slot+1].weight end}
assert(F.findTrack(p,'strike')==.03,'ordinary effects retain earliest-track policy')
assert(F.findTrack(p,'strike',nil,true)==.86,'grab strikes prefer the visible track over a faint restarted track')
tracks[1].weight=.96;tracks[2].weight=.04
assert(F.findTrack(p,'strike',nil,true)==.03,'new visible track wins after the old track fades')
tracks[1].weight=.01
assert(F.findTrack(p,'strike',nil,true)==nil,'fully faded tracks cannot drive a grab strike')
return 'PASS 4 dominant grab-track selection and existing-policy assertions'
"""
(w/'grab-track-tests.lua').write_text(track_test,encoding='utf-8')
