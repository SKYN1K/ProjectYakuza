from fixture_markers import fixture_marker
from pathlib import Path
import json,subprocess
w=Path(__file__).resolve().parent;root=w.parents[1];mod=root/'combat/ProjectYakuza'
game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
native=w/'punch-track-native.json'
subprocess.run([str(game/'jre64/bin/java.exe'),'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','-cp',str(w)+';'+str(game/'*'),'PunchTrackProbe',str(mod/'42/media/anims_X/Bob/ProjectYakuza_DD_Light01.x'),str(native)],check=True)
d=json.loads(native.read_text())
import re
style=(mod/'42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua').read_text(encoding='utf-8')
explicit=re.findall(r'attackEffects=\{track="([^"]+)"',style)
assert explicit==['dd_trail_light01_1'],'built-in first-light override must use an existing generated track'
code=(mod/'42/media/lua/client/ProjectYakuza/AttackTrailCatalog.lua').read_text(encoding='utf-8').split('T["dd_trail_light01_1"]=',1)[1].split('}}end)()',1)[0]
import re,hashlib
rows=[[float(x) for x in line.split(',')] for line in re.findall(r'^    \{([^{}]+)\},',code.split('upperFrames=')[0],re.M)]
assert len(rows)==31
for actual,frame in zip(rows,d['frames']):
 expected=sum(frame[:3],[])
 assert len(actual)==9 and all(abs(a-b)<1e-8 for a,b in zip(actual,expected)),(actual,expected)
upper=code.split('upperFrames={',1)[1]
upper_rows=[[float(x)for x in line.split(',')]for line in re.findall(r'^    \{([^{}]+)\},',upper,re.M)]
assert len(upper_rows)==len(d['frames'])
for actual,frame in zip(upper_rows,d['frames']):assert len(actual)==3 and all(abs(a-b)<1e-8 for a,b in zip(actual,frame[6]))
report=json.loads((mod/'docs/punch-effect-assets.json').read_text(encoding='utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(mod/report['clip']['path'])==report['clip']['sha256']
assert sha(mod/report['track']['path'])==report['track']['sha256']
for f in report['reused_textures']:assert sha(mod/f['path'])==f['sha256']
for f in report['reused_sounds']:assert sha(mod/'42'/f['output'])==f['sha256']
print('PASS 31 native shoulder/forearm/hand/knuckle FK samples, 66 unchanged texture hashes and original Y6 whoosh hashes')
m=mod/'42/media/lua/client/ProjectYakuza'
s=(w/'punch-effects-test-fixture.lua').read_text(encoding='utf-8')
for marker,name in [('WORLD','WorldEffects'),('TRACKS','AttackTracks'),('CATALOG','AttackTrailCatalog'),('EFFECTS','AttackEffects'),('CHARGELIMBTRACKS','ChargeTracks'),('CHARGELIMBEFFECTS','ChargeEffects'),('FEEDBACK','Feedback')]:s=s.replace(fixture_marker(marker),'do\n'+(m/(name+'.lua')).read_text(encoding='utf-8')+'\nend\n')
s=s.replace('"ProjectYakuzaFixture:PROJECTION"','{'+','.join('{'+','.join(str(x) for x in row)+'}' for row in d['projection'])+'}')
(w/'punch-effects-tests.lua').write_text(s,encoding='utf-8')
