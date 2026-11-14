from pathlib import Path
import sys,json,hashlib,struct,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
from paired_paths import bridge_scene_cuts
from mathutils import Quaternion,Vector
from weapon_hold_geometry import fit_arms
from native_body_geometry import load_body,skin_part
from locomotion_math import world
mod=root/'combat/ProjectYakuza';converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/open-grab-heat-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['knife'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if not (root/'extracted/open-grab-heat-0108/shoulder-throw/selection.json').exists():
 from extract_open_grab_heat_assets import extract
 extract()
jobs=[('ProjectYakuza_DD_OpenGrabHeat','extracted/open-grab-heat-0108/shoulder-throw/000.par/h23600_000_2.gmt'),('ProjectYakuza_DD_OpenGrabHeatVictim','extracted/open-grab-heat-0108/shoulder-throw/000.par/h23600_000_4.gmt')]
converter=converter.replace(' tg={}', ' ab=a.bones.get("vector_c_n");vq=SCENE_ROTATION@sample(ab.rotation if ab else None,f,Quaternion((1,0,0,0)),True)\n sg={n:vq.to_matrix().to_4x4()@mat for n,mat in sg.items()}\n tg={}')
converter=converter.replace("world.y=sg['ketu_c_n'].translation.y*scale","world.y=(sg['ketu_c_n'].translation.y+sample(a.bones['vector_c_n'].location,f,Vector((0,0,0))).y)*scale")
scene_rotation=None

vectors=[]
for name,source in jobs:
 src=root/source;sys.argv=['convert','--',name,str(src)]
 if scene_rotation is None:
  package=__import__('types').ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
  from yk.gmt_lib import read_gmt
  first=read_gmt(str(src)).animation.bones['vector_c_n'].rotation;first.fill_channels();v=first.keyframes[0].value;scene_rotation=Quaternion((v[3],*v[:3])).inverted()
 ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x','SCENE_ROTATION':scene_rotation};exec(compile(converter,'retarget_heat_rush','exec'),ns)
 raw=root/('tools/open-grab-heat-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times];fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n}
 for f in range(count):values[f],_=fit_arms(frames,values[f],ns['srcposes'][f],ns['bind'],fingers)
 output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(frames,values,times,grip),name)
 records.append({'animation':name,'source':str(src),'sourceSha256':sha(src),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
 ab=ns['a'].bones.get('vector_c_n');vs=[ns['sample'](ab.location,f,ns['Vector']((0,0,0)))for f in range(count)];vectors.append(vs)
native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');body=load_body(native/'models_X/Skinned/MaleBody.x');_,ib,ia,_=read(native/'anims_X/Bob/Bob_Idle.x');feet=['Bip01_L_Foot','Bip01_R_Foot','Bip01_L_Toe0','Bip01_R_Toe0'];floor=min(p.y for p in skin_part(body,world(ib,locals_at(ib,ia,0)),feet));parsed=[read(mod/r['output'])for r in records];ground=[]
for i in range(count):
 actor=world(parsed[0][1],locals_at(parsed[0][1],parsed[0][2],i*160));ground.append(floor-min(p.y for p in skin_part(body,actor,feet)))
for record,(text,bones,anim,spans)in zip(records,parsed):
 values=[];lifts=[]
 for i in range(count):
  value=locals_at(bones,anim,i*160);pose=world(bones,value);parent=bones['Bip01']['parent'];value['Bip01'].translation+=pose[parent].inverted().to_3x3()@Vector((0,ground[i],0))if parent else Vector((0,ground[i],0));lift=0
  if 'Victim'in record['animation']:
   pose=world(bones,value);lift=max(0,floor-min(p.y for p in skin_part(body,pose,['Bip01'])));assert lift<.3;value['Bip01'].translation+=pose[parent].inverted().to_3x3()@Vector((0,lift,0))if parent else Vector((0,lift,0))
  lifts.append(lift);values.append(value)
 write(mod/record['output'],text,spans,blocks(bones,values,times,grip),record['animation']);record['sha256']=sha(mod/record['output']);record['nativeFloorLift']=lifts
anchor=vectors[0][0];factor=float(ns['scale'])*1.5
raw_paths=[[[float((scene_rotation@(v-anchor)).z*factor),float((scene_rotation@(v-anchor)).x*factor)]for v in values]for values in vectors]
paths,cuts=bridge_scene_cuts(raw_paths)
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h23600_seoi_oi.par')
scene=root/'extracted/open-grab-heat-0108/shoulder-throw/cmn.par/cmn.bin';data=scene.read_bytes()
import re
soundFrames={}
for match in re.finditer(rb'SE_HACT_H23600[^\0]+',data):
    start,end=struct.unpack_from('<ff',data,match.start()+36);soundFrames[match.group().decode()]={'startFrame':start,'endFrame':end}
assert count==225 and all(len(v)==225 for v in paths)
report={'authorization':'User requested a grabbed-target Heat Action in open space on 2026-11-14.','operation':'All original frames and source vector rotations retained through existing non-AI retargeting. Original arm directions fitted to native segment lengths and supplied fist fingers retained. Shared actor sole grounding plus native victim-surface floor clearance preserve the original body rotations and flight while preventing the shorter native body from penetrating the ground. Native PZ hand-to-prop grip is preserved. No new motion samples, pixels, models or audio are synthesized.','archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'actorAssignment':json.loads((root/'extracted/open-grab-heat-0108/shoulder-throw/selection.json').read_text(encoding='utf-8')),'soundFrames':soundFrames,'contactFrames':[117,167],'contactsOperation':'Original CMN victim damage starts at frames 117 and 167. The existing canonical five-times unarmed Heat Action multiplier is retained, with lethal damage deferred until paired playback finishes. Source force-death is not applied.','ground':{'floor':floor,'feet':feet,'sharedRootCorrection':ground},'nativeGrip':grip,'pathScale':factor,'paths':paths,'rawPaths':raw_paths,'sceneCuts':cuts,'sceneRotation':list(scene_rotation),'rootHeightOperation':'Original vector_c_n elevation is added to the retarget root; the scene is normalized to the attacker initial heading. Code-side paths remove shared camera-stage translations and bridge relative cut changes over six source frames.','clips':records}
def literal(value):
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return format(value,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_grab_open={fps=30,duration='+str((count-1)/30)+',actorAnimation="ProjectYakuza_DD_OpenGrabHeat",targetAnimation="ProjectYakuza_DD_OpenGrabHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza/OpenGrabHeatPaths.lua').write_bytes(code.encode())
(mod/'docs/open-grab-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('OPEN_GRAB_ASSETS',len(records),'original paired clips,',count,'source frames; maximum separation',max(((a[0]-b[0])**2+(a[1]-b[1])**2)**.5 for a,b in zip(paths[0],paths[1])))


media=mod/'42/media'
for group in ['player/actions','zombie/idle','zombie/hitreaction','zombie/hitreaction-hit']:
    path=media/'AnimSets'/group/('ProjectYakuza_DD_WallHeat.xml'if group=='player/actions'else'ProjectYakuza_DD_WallHeatVictim.xml');destination=path.with_name(path.name.replace('WallHeat','OpenGrabHeat'));destination.write_text(path.read_text(encoding='utf-8').replace('WallHeat','OpenGrabHeat'),encoding='utf-8');tree=E.parse(destination)
    for weight in tree.getroot().findall('m_SubStateBoneWeights'):E.SubElement(weight,'includeDescendants').text='true'
    E.indent(tree,space='  ');tree.write(destination,encoding='utf-8',xml_declaration=True)
report['provenance']=[{'path':str(p),'sha256':sha(p)}for p in [Path(__file__),root/'tools/combat-tests/extract_open_grab_heat_assets.py',root/'tools/combat-tests/retarget_locomotion.py',root/'tools/combat-tests/paired_paths.py',root/'tools/combat-tests/weapon_hold_geometry.py',root/'tools/combat-tests/native_body_geometry.py',native/'models_X/Skinned/MaleBody.x',native/'anims_X/Bob/Bob_Idle.x',Path('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json')]]
(mod/'docs/open-grab-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
