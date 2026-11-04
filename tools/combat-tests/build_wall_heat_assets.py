from pathlib import Path
import sys,json,hashlib,struct
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
from paired_paths import bridge_scene_cuts
from mathutils import Quaternion
mod=root/'combat/ProjectYakuza';srcRoot=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/wall-heat-build'");grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['knife'];records=[]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if not (root/'extracted/grab-wall-080/wall-knock/000.par/h2000_000_2.gmt').exists():
 import extract_grab_wall_assets
jobs=[('ProjectYakuza_DD_WallHeat','extracted/grab-wall-080/wall-knock/000.par/h2000_000_2.gmt'),('ProjectYakuza_DD_WallHeatVictim','extracted/grab-wall-080/wall-knock/000.par/h2000_000_4.gmt')]
converter=converter.replace(' tg={}', ' ab=a.bones.get("vector_c_n");vq=SCENE_ROTATION@sample(ab.rotation if ab else None,f,Quaternion((1,0,0,0)),True)\n sg={n:vq.to_matrix().to_4x4()@mat for n,mat in sg.items()}\n tg={}')
converter=converter.replace("world.y=sg['ketu_c_n'].translation.y*scale","world.y=(sg['ketu_c_n'].translation.y+sample(a.bones['vector_c_n'].location,f,Vector((0,0,0))).y)*scale")
scene_rotation=None

poses=[];vectors=[]
for name,source in jobs:
 src=root/source;sys.argv=['convert','--',name,str(src)]
 if scene_rotation is None:
  package=__import__('types').ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
  from yk.gmt_lib import read_gmt
  first=read_gmt(str(src)).animation.bones['vector_c_n'].rotation;first.fill_channels();v=first.keyframes[0].value;scene_rotation=Quaternion((v[3],*v[:3])).inverted()
 ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x','SCENE_ROTATION':scene_rotation};exec(compile(converter,'retarget_heat_rush','exec'),ns)
 raw=root/('tools/wall-heat-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(frames,anim,t)for t in times];output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(frames,values,times,grip),name)
 records.append({'animation':name,'source':str(src),'sourceSha256':sha(src),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retargetSha256':sha(raw),'frames':count,'fps':30})
 poses.append(ns['srcposes'])
 ab=ns['a'].bones.get('vector_c_n');vs=[ns['sample'](ab.location,f,ns['Vector']((0,0,0)))for f in range(count)];vectors.append(vs)
anchor=vectors[0][0];factor=float(ns['scale'])*1.5
raw_paths=[[[float((scene_rotation@(v-anchor)).z*factor),float((scene_rotation@(v-anchor)).x*factor)]for v in values]for values in vectors]
paths,cuts=bridge_scene_cuts(raw_paths)
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/hact/h2000_knock_wall_l.par')
scene=root/'extracted/grab-wall-080/wall-knock/cmn.par/cmn.bin';data=scene.read_bytes()
import re
soundFrames={}
for match in re.finditer(rb'SE_HACT_H2000[^\0]+',data):
    start,end=struct.unpack_from('<ff',data,match.start()+36);soundFrames[match.group().decode()]={'startFrame':start,'endFrame':end}
report={'authorization':'User approved original paired grab and wall Heat Action conversion on 2026-11-04.','operation':'All original frames and source vector rotations retained through existing non-AI retargeting. Native PZ hand-to-prop grip preserved. No invented body motion, image, audio or model artwork.','archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'actorAssignment':'Original cmn.bin binds m_kiryu at 0x73c to h2000_000_2 at 0x7cc; enemy at 0x12c8 binds h2000_000_4 at 0x1358.','soundFrames':soundFrames,'contactFrames':[1,28,73],'contactsOperation':'Original repeated-strike, final-strike and body-fall scene sound starts supply presentation timings. Damage is applied at the final fall contact to preserve the full paired victim motion. The last recovery remains original.','nativeGrip':grip,'pathScale':factor,'paths':paths,'rawPaths':raw_paths,'sceneCuts':cuts,'sceneRotation':list(scene_rotation),'rootHeightOperation':'Original vector_c_n elevation is added to the retarget root; the scene is normalized to the attacker initial heading. Code-side paths remove shared camera-stage translations and bridge relative cut changes over six source frames.','clips':records}
def literal(value):
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return format(value,'.9f')
code='require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_wall={fps=30,duration='+str((count-1)/30)+',actorAnimation="ProjectYakuza_DD_WallHeat",targetAnimation="ProjectYakuza_DD_WallHeatVictim",actor='+literal(paths[0])+',victim='+literal(paths[1])+'}\n'
(mod/'42/media/lua/shared/ProjectYakuza/WallHeatPaths.lua').write_bytes(code.encode())
(mod/'docs/wall-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('WALL_ASSETS',len(records),'original paired clips,',count,'source frames; maximum separation',max(((a[0]-b[0])**2+(a[1]-b[1])**2)**.5 for a,b in zip(paths[0],paths[1])))

path=mod/"42/media/lua/shared/ProjectYakuza/WallHeatPaths.lua"
path.write_text(path.read_text()+"\nProjectYakuza.PairedMotions.dod_wall.wallDepth="+str(max(v[0]for path in paths for v in path)+.15)+"\n",encoding="utf-8")
