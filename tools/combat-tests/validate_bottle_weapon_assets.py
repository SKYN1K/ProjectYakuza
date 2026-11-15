from pathlib import Path
import sys,json,subprocess,hashlib
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/bottle-weapon-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
 command=['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'];r=subprocess.run(command,capture_output=True,text=True);print(r.stdout);assert r.returncode==0 and'PASS dedicated bottle'in r.stdout,r.stderr
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';prefix=[java,'-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*']
 for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'bottle-weapon-props.tsv')],['BottleItemProbe',str(mod/'42/media/scripts/ProjectYakuza_Bottles.txt')],['WeaponMotionProbe',str(mod/'42/media')]]:subprocess.run(prefix+args,cwd=w,check=True)
 raise SystemExit(0)
sys.path.insert(0,str(w))
from mathutils import Vector
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part
body=load_body(report['nativeBody']);assert sha(body['path'])==report['nativeBodySha256'];contracts=[];total=0
for clip in report['clips']:
 assert sha(clip['source'])==clip['sourceSha256']and sha(clip['retarget'])==clip['retargetSha256']and sha(mod/clip['output'])==clip['sha256'];_,bones,animation,_=read(mod/clip['output']);_,rb,ra,_=read(clip['retarget']);offsets=[[],[]]
 if not clip.get('attachmentOnly'):assert 'WPN_'in clip['source']
 for frame in range(clip['frames']):
  poseLocal=locals_at(bones,animation,frame*160);old=locals_at(rb,ra,frame*160);pose=world(bones,poseLocal)
  for name in poseLocal:
   if name=='Bip01_Prop1':continue
   assert max(abs(poseLocal[name][a][b]-old[name][a][b])for a in range(4)for b in range(4))<.00001
  points=skin_part(body,pose,['Bip01_R_Hand']);palm=sum(points,Vector())/len(points);assert(pose['Bip01_Prop1'].translation-palm).length<.00001
  for i,(hand,prop)in enumerate([('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]):offsets[i].append(pose[hand].inverted()@pose[prop])
  total+=1
 encoded=[';'.join(','.join(str(v)for row in matrix for v in row)for matrix in values)for values in offsets];contracts.append('\t'.join([str(mod/clip['output']),*encoded,str(clip['frames'])]))
for model in report['models']:assert sha(model['mesh'])==model['meshSha256']
(w/'bottle-weapon-props.tsv').write_text('\n'.join(contracts));print('PASS dedicated bottle:',total,'source body/hand-palm samples; original meshes unchanged and three neck anchors recorded')
