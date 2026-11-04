from pathlib import Path
import sys,json,hashlib,subprocess,math,re
root=Path(__file__).resolve().parents[2];here=Path(__file__).parent;mod=root/'combat/ProjectYakuza';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report=json.loads((mod/'docs/ground-heat-assets.json').read_text())
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0 and 'PASS original ground pair'in r.stdout,r.stderr
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
 for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(here/'ground-prop-contract.tsv')],['GrabAssetProbe',str(mod/'42/media/AnimSets')]]:subprocess.run([java,'-cp',cp,*args],cwd=here,check=True)
 raise SystemExit(0)
sys.path.insert(0,str(here));from locomotion_math import read,locals_at,world
from paired_paths import bridge_scene_cuts
assert sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']
scene=Path(report['scene']).read_bytes();resources=(Path(report['scene']).parents[1]/'000.par/res.bin').read_bytes()
for model,clip in [(b'm_kiryu',b'h1500_000_2'),(b'm_com_suit_01',b'h1500_000_4')]:
 modelAt=resources.index(model);clipAt=resources.index(clip);modelGuid=resources[modelAt-28:modelAt-12];clipGuid=resources[clipAt-28:clipAt-12]
 assert scene.index(clipGuid)-scene.index(modelGuid)==0x90
contracts=[];samples=0
for c in report['clips']:
 output=mod/c['output'];raw=root/'tools/ground-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
 assert sha(output)==c['sha256']and sha(c['source'])==c['sourceSha256']and sha(raw)==c['retargetSha256']and c['frames']==111
 _,bones,curves,_=read(output);_,source,original,_=read(raw)
 for i in range(111):
  actual=locals_at(bones,curves,i*160);expected=locals_at(source,original,i*160)
  for name in actual:
   if name in ['Bip01_Prop1','Bip01_Prop2']:continue
   assert max(abs(actual[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<.00001;samples+=1
 offsets=[','.join(str(v)for row in report['nativeGrip']['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(output),*offsets,'111']))
 if 'Victim'in c['animation']:assert world(bones,locals_at(bones,curves,0))['Bip01'].translation.y<.4
 else:assert world(bones,locals_at(bones,curves,25*160))['Bip01_R_Foot'].translation.y-world(bones,locals_at(bones,curves,30*160))['Bip01_R_Foot'].translation.y>.3
paths,cuts=bridge_scene_cuts(report['rawPaths']);assert paths==report['paths']and cuts==report['sceneCuts']and report['contactFrames']==[30]
assert all(len(path)==111 and all(math.isfinite(v)for point in path for v in point)for path in paths)
(here/'ground-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
print('PASS original ground pair GUID roles, archive/clip hashes, 111 source frames, motion-derived stomp contact and',samples,'preserved body samples; no invented motion')

alignment=json.loads((mod/'docs/ground-contact-alignment.json').read_text())
for source in alignment['sources']:assert sha(source['path'])==source['sha256']
actor,victim=report['paths'][0][30],report['paths'][1][30];foot=alignment['actorSole'];head=alignment['victimHead'];delta=alignment['offset']
for angle in range(0,360,45):
 c,s=math.cos(math.radians(angle)),math.sin(math.radians(angle))
 af,ar=actor[0]-foot[2]*1.5,actor[1]+foot[0]*1.5;vf,vr=victim[0]-head[2]*1.5+delta[0],victim[1]+head[0]*1.5+delta[1]
 assert math.hypot(c*(af-vf)+s*(ar-vr),s*(af-vf)-c*(ar-vr))<.000001
code=(mod/'42/media/lua/shared/ProjectYakuza/GroundHeatPaths.lua').read_text();assert 'contactOffset='in code
print('PASS native male/female head and foot-sole calibration meets at impact in all eight headings; original motion unchanged')
