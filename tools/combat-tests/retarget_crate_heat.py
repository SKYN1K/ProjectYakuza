from pathlib import Path
import sys,json,types,hashlib
from mathutils import Matrix,Vector,Quaternion
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'));from locomotion_math import read,locals_at,world,blocks,write
p=types.ModuleType('yk');p.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=p
from yk.gmt_lib import read_gmt
from yk.read_gmd import read_gmd_bones
bonePath=root/'extracted/crate-beercase-0114/c_cm_bone.gmd';sb=read_gmd_bones(str(bonePath));bind={}
for b in sb:
 local=Matrix.Translation(Vector(b.local_pos[:3]))@Quaternion((b.local_rot[3],*b.local_rot[:3])).to_matrix().to_4x4();bind[b.name]=bind[sb[b.parent_index].name]@local if b.parent_index>=0 else local

converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/crate-beercase-retarget'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(bonePath))).replace('scale=bind[\'Bip01_Pelvis\'].translation.y/1.14','scale=bind[\'Bip01_Pelvis\'].translation.y/SOURCE_PELVIS_HEIGHT')
for name in ['center','ketu','kosi','mune','kubi','face']:converter=converter.replace(name+'_c_n',name+'_n')
converter=converter.replace('face_n','face')
converter=converter.replace("if b.name=='center_n':loc=Vector((0,0,0))","if b.name=='center_n':loc=Vector((0,loc.y,0))")
roles=[];grip=json.loads((root/'combat/ProjectYakuza/docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat']
for role,stem in [('actor','h3000_000_1'),('victim','h3000_000_3')]:
 src=root/'extracted/crate-beercase-0114/000.par'/(stem+'.gmt');name='ProjectYakuza_DD_CrateHeat'+('Victim'if role=='victim'else'');sys.argv=['convert','--',name,str(src)];ns={'SOURCE_PELVIS_HEIGHT':bind['ketu_n'].translation.y,'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_supplied_y5_beercase','exec'),ns)
 raw=root/'tools/crate-beercase-retarget/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,b,c,spans=read(raw);times=[f*160 for f in range(635)];values=[locals_at(b,c,t)for t in times];write(raw,text,spans,blocks(b,values,times,grip),name)
 centre=ns['a'].bones['center_n'].location;vectors=[ns['sample'](centre,f,Vector((0,0,0)))for f in range(635)];w=[world(b,v)for v in values];roles.append({'role':role,'file':str(raw),'vectors':[list(v)for v in vectors],'scale':float(ns['scale']),'bones':b,'worlds':w})
actor,victim=roles;scale=actor['scale']*1.5;anchor=Vector(actor['vectors'][0]);rows=[]
for frame in range(635):
 av=Vector(actor['vectors'][frame])-anchor;vv=Vector(victim['vectors'][frame])-anchor
 def point(role,offset,bone):
  v=role['worlds'][frame][bone].translation;return Vector((offset.z*scale-v.z*1.5,offset.x*scale+v.x*1.5,v.y*1.5))
 hand=point(actor,av,'Bip01_R_Hand');targets=[point(victim,vv,b)for b in ['Bip01_Head','Bip01_Spine1']];rows.append(min((hand-v).length for v in targets))
print('RIGHT_CONTACT_MINIMA',[(i,round(d,4))for i,d in enumerate(rows)if 1<i<633 and d<rows[i-1]and d<rows[i+1]])
print('HAND_DIST',[(i,round(rows[i],3))for i in range(0,130,5)])
(root/'tools/crate-original-retarget-0114.json').write_text(json.dumps({'scale':scale,'roles':[{k:v for k,v in r.items()if k not in ['bones','worlds']}for r in roles],'distance':rows},indent=2))
