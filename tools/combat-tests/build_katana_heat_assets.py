from pathlib import Path
import sys,json,hashlib,struct
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write,world
from paired_paths import bridge_scene_cuts
from mathutils import Quaternion,Vector,Matrix
from weapon_hold_geometry import fit_arms
from katana_prop_motion import prop_offsets,grip_frames
staging='--stage'in sys.argv;sourceMod=root/'combat/ProjectYakuza';mod=root/'tools/katana-scene-candidate-093/ProjectYakuza'if staging else sourceMod
(mod/'docs').mkdir(parents=True,exist_ok=True)
srcRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/katana-heat-build'");grip=json.loads((sourceMod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
jobs=[('ProjectYakuza_DD_KatanaHeat','extracted/katana-heat-070/000.par/h23720_000_4.gmt'),('ProjectYakuza_DD_KatanaHeatVictim','extracted/katana-heat-070/000.par/h23720_000_6.gmt')]
converter=converter.replace(' tg={}', ' ab=a.bones.get("vector_c_n");vq=SCENE_ROTATION@sample(ab.rotation if ab else None,f,Quaternion((1,0,0,0)),True)\n sg={n:vq.to_matrix().to_4x4()@mat for n,mat in sg.items()}\n tg={}')
converter=converter.replace("world.y=sg['ketu_c_n'].translation.y*scale","world.y=(sg['ketu_c_n'].translation.y+sample(a.bones['vector_c_n'].location,f,Vector((0,0,0))).y)*scale")
scene_rotation=None

poses=[];vectors=[];native=[];effectPoints=[];propMotion=None
from read_katana_scene import read_scene
sceneData=read_scene(root/"extracted/katana-heat-070/cmn.par/cmn.bin")
particles=[next(r for r in sceneData["nodes"]if r.get("element",{}).get("kind")==0x13 and r["name"].startswith(prefix)and r["element"]["start"]==frame)for prefix,frame in [("YNb0014",20),("YNb0009",43),("YNb0013",62)]]
for name,source in jobs:
 src=root/source;sys.argv=['convert','--',name,str(src)]
 if scene_rotation is None:
  package=__import__('types').ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
  from yk.gmt_lib import read_gmt
  first=read_gmt(str(src)).animation.bones['vector_c_n'].rotation;first.fill_channels();v=first.keyframes[0].value;scene_rotation=Quaternion((v[3],*v[:3])).inverted()
 ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x','SCENE_ROTATION':scene_rotation};exec(compile(converter,'retarget_heat_rush','exec'),ns)
 raw=root/('tools/katana-heat-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times]
 fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n}
 for frame in range(count):values[frame],_=fit_arms(frames,values[frame],ns['srcposes'][frame],ns['bind'],fingers)
 output=mod/('42/media/anims_X/Bob/'+name+'.x');output.parent.mkdir(parents=True,exist_ok=True);write(output,text,spans,blocks(frames,values,times,grip),name)
 if name=='ProjectYakuza_DD_KatanaHeat':
  propSource=root/'extracted/katana-heat-070/000.par/h23720_000_7.gmt';prop=read_gmt(str(propSource)).animation
  for bone in prop.bones.values():
   for curve in bone.curves:
    if int(curve.type)in(0,1):curve.fill_channels()
  current,frames,anim,spans=read(output);weapons,sourceOffsets,hands=grip_frames(ns,prop,frames,anim,Matrix(grip['authoredOffsets']['Bip01_Prop1']),count)
  dynamic=[]
  for frame,(weapon,hand)in enumerate(zip(weapons,hands)):
   pose=locals_at(frames,anim,times[frame]);w=world(frames,pose);parent=frames['Bip01_R_Hand']['parent'];local=w[parent].to_quaternion().inverted()@hand;value=local.to_matrix().to_4x4();value.translation=pose['Bip01_R_Hand'].translation;pose['Bip01_R_Hand']=value;pose['Bip01_Prop1']=w[frames['Bip01_Prop1']['parent']].inverted()@weapon;dynamic.append(pose)
  selected={name:spans[name]for name in ['Bip01_R_Hand','Bip01_Prop1']};changes=blocks(frames,dynamic,times,None);write(output,current,selected,{name:changes[name]for name in selected},name)
  departures=[i for i,m in enumerate(sourceOffsets)if(m.translation-sourceOffsets[0].translation).length>.005]
  flightStart=departures[0];catch=next(i for i in range(flightStart+1,count)if(sourceOffsets[i].translation-sourceOffsets[0].translation).length<.001)
  propMotion={'source':str(propSource),'sourceSha256':sha(propSource),'bone':'anm_root','sourceHand':'ude3_r_n','targetProp':'Bip01_Prop1','frames':count,'fps':30,'referenceFrame':0,'releaseFrame':flightStart,'catchFrame':catch,'retargetScale':float(ns['scale']),'finalThrustFrame':64,'operation':'Native hilt pivot remains at the calibrated palm through regrip; original absolute weapon orientation and airborne translation sampled at every source frame. Actor vector transform is removed, relative release/catch/reverse-grip motion is reflected into native hand coordinates through the existing arm adaptation, and native grip calibration is retained at frame zero. The native right wrist is fitted to the weapon shaft while held. The weapon model hilt pivot stays at the supplied native palm calibration; source airborne motion is retained.'}
  sourceRig=Path('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd');nativeMesh=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/weapons/2handed/Katana.x')
  propMotion.update({'sourceRig':str(sourceRig),'sourceRigSha256':sha(sourceRig),'nativeMesh':str(nativeMesh),'nativeMeshSha256':sha(nativeMesh),'nativeSharpAxis':[0,1,0]})
 records.append({'animation':name,'source':str(src),'sourceSha256':sha(src),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
 native.append([world(frames,v)for v in values])
 if len(native)==2:
  for particle,bone,frame in zip(particles,['Bip01_Spine1','Bip01_Head','Bip01_Spine'],[24,44,64]):
   translation=Vector(particle['particle']['matrix'][12:15]);offset=ns['bind'][bone].to_quaternion().inverted()@(ns['C']@translation*ns['scale']);point=native[1][frame][bone]@offset
   effectPoints.append({'frame':frame,'bone':bone,'point':list(point),'sourceEmitter':particle['name'],'sourceFrame':particle['element']['start'],'sourceLocalOffset':list(translation)})
 poses.append(ns['srcposes'])
 ab=ns['a'].bones.get('vector_c_n');vs=[ns['sample'](ab.location,f,ns['Vector']((0,0,0)))for f in range(count)];vectors.append(vs)
anchor=vectors[0][0];factor=float(ns['scale'])*1.5
raw_paths=[[[float((scene_rotation@(v-anchor)).z*factor),float((scene_rotation@(v-anchor)).x*factor)]for v in values]for values in vectors]
paths,cuts=bridge_scene_cuts(raw_paths)
from katana_contact_alignment import align_contacts
paths,nativeCorrection=align_contacts(mod/'42/media/anims_X/Bob/ProjectYakuza_DD_KatanaHeat.x',mod/'42/media/anims_X/Bob/ProjectYakuza_DD_KatanaHeatVictim.x',paths)

archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23720_buki_e.par')
scene=root/'extracted/katana-heat-070/cmn.par/cmn.bin';data=scene.read_bytes()
import re
soundFrames={}
for match in re.finditer(rb'SE_HACT_H23720[^\0]+',data):
    start,end=struct.unpack_from('<ff',data,match.start()+36);soundFrames[match.group().decode()]={'startFrame':start,'endFrame':end}
report={'authorization':'User approved original katana sound extraction and paired motion repair on 2026-11-07.','operation':'Original 141 frames, source vector rotations and frame timing retained. Native arm-segment directions follow original source joints while retaining native PZ lengths, source wrist articulation, native fingers and hand-to-prop grip. No AI, invented motion or artwork.','archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'actorAssignment':'cmn.bin binds res.bin m_kiryu GUID at 0x18d0 to h23720_000_4 GUID at 0x1960; enemy model at 0x1dec binds h23720_000_6 at 0x1e7c. Katana prop h23720_000_7 identifies bs_e000_type_e_tachi_1 and the scene attaches it to buki1_r_n.','soundFrames':soundFrames,'contactFrames':[24,44,64],'contactsOperation':'Original CMN NodeBattleDamage starts define the three hits. Sound cue starts are independent timeline events. First two damage nodes set NoDead; the framework retains lethal damage until full recovery by explicit user requirement.','nativeSkeletonCorrection':nativeCorrection,'effectPoints':effectPoints,'nativeGrip':grip,'pathScale':factor,'paths':paths,'rawPaths':raw_paths,'sceneCuts':cuts,'sceneRotation':list(scene_rotation),'rootHeightOperation':'Original vector_c_n elevation is added to the retarget root; the scene is normalized to the attacker initial heading. Code-side paths remove shared camera-stage translations and bridge relative cut changes over six source frames.','clips':records}
report['propMotion']=propMotion
dependencies=[root/'tools/combat-tests'/p for p in ['retarget_locomotion.py','weapon_hold_geometry.py','locomotion_math.py','katana_prop_motion.py','katana_contact_alignment.py','native_body_geometry.py']]+[Path(nativeCorrection['nativeBody']),Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json')]
report['retargetProvenance']=[{'path':str(p),'sha256':sha(p)}for p in dependencies]
report['authorization']='User requested restoration of the original katana airborne grip change and sharp-end final thrust; supplied source motion conversion only.'
report['operation']='Original 141 body frames, arm adaptation, source vector rotations and frame timing retained. The actor right prop follows the original independent sword track, including release, catch and reversed grip, instead of a rigid hand lock. No AI, invented motion or artwork.'
def literal(value):
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return format(value,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_katana={fps=30,duration=140/30,actorAnimation="ProjectYakuza_DD_KatanaHeat",targetAnimation="ProjectYakuza_DD_KatanaHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza').mkdir(parents=True,exist_ok=True);(mod/'42/media/lua/shared/ProjectYakuza/KatanaHeatPaths.lua').write_bytes(code.encode())
(mod/'docs/katana-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('KATANA_ASSETS',len(records),'original paired clips,',count,'source frames; maximum separation',max(((a[0]-b[0])**2+(a[1]-b[1])**2)**.5 for a,b in zip(paths[0],paths[1])))
