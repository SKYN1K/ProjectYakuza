from pathlib import Path
import sys,json,hashlib,subprocess,math,uuid

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
 result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and'PASS contact repairs'in result.stdout,result.stderr
 report=json.loads((mod/'docs/blade-contact-repair.json').read_text());paths=[str(mod/c['output'])for c in report['clips']];holds=json.loads((mod/'docs/crate-hold-assets.json').read_text());paths.extend(str(mod/c['output'])for c in holds['clips']);grab=json.loads((mod/'docs/open-grab-heat-assets.json').read_text());paths.extend(str(mod/c['output'])for c in grab['clips']);prefix=['F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe','-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'];subprocess.run(prefix+['AnimationProbe',*paths],cwd=w,check=True);subprocess.run(prefix+['PropAttachmentProbe',str(w/'contact-repair-props.tsv')],cwd=w,check=True);subprocess.run(prefix+['BottleGripProbe',str(mod/'42/media/scripts/ProjectYakuza_BottleModels.txt'),'F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X'],cwd=w,check=True);subprocess.run(prefix+['OpenGrabHeatProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_Idle.x',*[str(mod/c['output'])for c in grab['clips']],str(mod/'42/media/AnimSets')],cwd=w,check=True);raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part
from y5_source_assets import entry
from read_heat_scene import read_scene
from scene_resource import resource

contracts=[];samples=0;body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');repair=json.loads((mod/'docs/blade-contact-repair.json').read_text());assert sha(repair['baseline'])==repair['baselineSha256']
for c in repair['clips']:
 output=mod/c['output'];assert sha(output)==c['sha256']and sha(c['original'])==c['originalSha256'];_,bones,animation,_=read(output);_,ob,oa,_=read(c['original']);count=len(animation['Bip01_R_Hand'][0]);offsets=[[],[]]
 report=json.loads((mod/'docs'/(c['kind']+'-heat-assets.json')).read_text())if c['kind']in ['knife','katana']else None
 if report:
  assert sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256'];_,vb,va,_=read(mod/report['clips'][1]['output']);assert c['maxGripReachError']<.003,c['maxGripReachError']
 for frame in range(count):
  local=locals_at(bones,animation,frame*160);old=locals_at(ob,oa,frame*160);pose=world(bones,local)
  for name in local:
   if name=='Bip01_Prop1':continue
   assert(local[name].translation-old[name].translation).length<.00001,(c['output'],frame,name,'native bone length changed')
   if name=='Bip01_Prop1':continue
   if report and name in ['Bip01_Spine1','Bip01_R_Clavicle','Bip01_R_UpperArm','Bip01_R_Forearm','Bip01_R_Hand']:continue
   if not report and(name.startswith('Bip01_L_')and any(n in name for n in ['Clavicle','UpperArm','Forearm','Hand','Finger'])or name.startswith('Bip01_R_')and any(n in name for n in ['Clavicle','UpperArm','Forearm','Hand','Finger'])or name=='Bip01_Spine1'):continue
   assert max(abs(local[name][a][b]-old[name][a][b])for a in range(4)for b in range(4))<.00001,(c['output'],frame,name)
  if report and c['first']<=frame<=c['last']:
   ap,vp=report['paths'][0][frame],report['paths'][1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));victim=Matrix.Translation(shift)@world(vb,locals_at(vb,va,frame*160))[c['victimBone']];relative=victim.inverted()@pose['Bip01_Prop1'];expected=Matrix(c['relativeTransform']);assert max(abs(relative[a][b]-expected[a][b])for a in range(4)for b in range(4))<.00002,(c['kind'],frame,'embedded blade drift')
  if not report and frame==c['contactFrame']:
   tip=pose['Bip01_Prop1']@Vector((0,.22,0));assert abs(tip.x-pose['Bip01_Spine1'].translation.x)<.00001
  for i,(hand,prop)in enumerate([('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]):offsets[i].append(pose[hand].inverted()@pose[prop])
  samples+=1
 encoded=[';'.join(','.join(str(v)for row in matrix for v in row)for matrix in matrices)for matrices in offsets];contracts.append('\t'.join([str(output),*encoded,str(count)]))
holds=json.loads((mod/'docs/crate-hold-assets.json').read_text())
for row in holds['archiveEntries']:
 data,actual=entry(row['archive'],row['name']);assert actual==row
for c in holds['clips']:
 assert sha(c['source'])==c['sourceSha256']and sha(mod/c['output'])==c['sha256']
 if 'nativeBase'not in c:continue
 assert sha(c['nativeBase'])==c['nativeBaseSha256'];_,bones,animation,_=read(mod/c['output']);_,nb,na,_=read(c['nativeBase']);end=max(t for channels in na.values()for keys in channels.values()for t,_ in keys)
 for frame in range(c['frames']):
  t=frame*160;local=locals_at(bones,animation,t);expected=locals_at(nb,na,t%end if Path(c['output']).stem.endswith(('Ready','RelaxedIdle'))else t)
  for name in local:
   if any(part in name for part in ['Clavicle','UpperArm','Forearm','Hand','Finger','Prop']):continue
   assert max(abs(local[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<.00001,(c['output'],frame,name,'native walking/deferred channel')
crate=json.loads((mod/'docs/crate-heat-assets.json').read_text());assert math.dist(crate['paths'][0][0],crate['paths'][0][25])>.30
for frame in range(41):assert math.dist(crate['paths'][0][frame],crate['sourcePaths'][0][frame])<.00001
actor,victim=[c for c in crate['clips']if not c['ending']];_,ab,aa,_=read(mod/actor['output']);_,vb,va,_=read(mod/victim['output'])
for frame in range(455):
 pose=world(ab,locals_at(ab,aa,frame*160));prop=pose['Bip01_Prop1']
 if frame<=40:
  palm=skin_part(body,pose,['Bip01_R_Hand']);assert(prop.translation-sum(palm,Vector())/len(palm)).length<.00002
 if frame>=51:
  ap,vp=crate['paths'][0][frame],crate['paths'][1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));head=[prop.inverted()@(p+shift)for p in skin_part(body,world(vb,locals_at(vb,va,frame*160)),['Bip01_Head'])];assert abs(min(p.y for p in head)-crate['headSeat']['roof'])<.00004
grab=json.loads((mod/'docs/open-grab-heat-assets.json').read_text());assert sha(grab['archive'])==grab['archiveSha256']and sha(grab['scene'])==grab['sceneSha256'];scene=read_scene(grab['scene']);assert scene['version']==10 and scene['end']==200 and[n['element']['start']for n in scene['nodes']if'damage'in n]==[78]
for c,selection in zip(grab['clips'],grab['selection']):
 assert c['frames']==201 and sha(mod/c['output'])==c['sha256']and sha(c['source'])==c['sourceSha256'];assert resource(grab['resources'],uuid.UUID(selection['motion']).bytes_le.hex())==selection['resource']
ground=json.loads((mod/'docs/ground-heat-assets.json').read_text());scene=read_scene(ground['scene']);assert sha(ground['archive'])==ground['archiveSha256']and scene['sha256']==ground['sceneSha256'];assert[n['motion']['end']for n in scene['nodes']if'motion'in n]==[110,110];assert[(n['element']['start'],n['sound']['cueSheet'],n['sound']['cueId'])for n in scene['nodes']if'sound'in n]==[(0,512,0)];assert not any('damage'in n for n in scene['nodes'])
(w/'contact-repair-props.tsv').write_text('\n'.join(contracts));print('PASS contact repairs:',samples,'native source/pose samples, exact embedded victim locks, centred knife swings, retained native crate travel/legs, held startup crate and opening-down head contact; original Y5 grab CMN and stomp bindings verified')
