from pathlib import Path
import sys,types,hashlib
from mathutils import Matrix,Vector,Quaternion

root=Path(__file__).resolve().parents[2]
package=types.ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from yk.read_gmd import read_gmd_bones
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import fit_arms

def provenance():
    paths=[root/'tools/combat-tests'/name for name in ['y5_retarget.py','retarget_locomotion.py','weapon_hold_geometry.py','locomotion_math.py']]+[root/'extracted/bicycle-heat-097/c_cm_bone.gmd']
    return [{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in paths]

def source_context(name,source,prefix=False):
    bonePath=root/'extracted/bicycle-heat-097/c_cm_bone.gmd';sourceBones=read_gmd_bones(str(bonePath));bind={}
    for b in sourceBones:
        local=Matrix.Translation(Vector(b.local_pos[:3]))@Quaternion((b.local_rot[3],*b.local_rot[:3])).to_matrix().to_4x4();bind[b.name]=bind[sourceBones[b.parent_index].name]@local if b.parent_index>=0 else local
    converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/y5-097-retarget'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(bonePath))).replace("scale=bind['Bip01_Pelvis'].translation.y/1.14","scale=bind['Bip01_Pelvis'].translation.y/SOURCE_PELVIS_HEIGHT")
    for part in ['center','ketu','kosi','mune','kubi','face']:converter=converter.replace(part+'_c_n',part+'_n')
    converter=converter.replace('face_n','face').replace("if b.name=='center_n':loc=Vector((0,0,0))","if b.name=='center_n':loc=Vector((0,loc.y,0))")
    if prefix:converter=converter.split('poses=[];srcposes=[]')[0]
    sys.argv=['convert','--',name,str(source)];context={'SOURCE_PELVIS_HEIGHT':bind['ketu_n'].translation.y,'FINGER_SOURCE':'Bob_AttackBat01_Hit.x'};exec(compile(converter,'supplied_y5_retarget','exec'),context)
    return context

def convert(name,source,out):
    context=source_context(name,source)
    raw=root/'tools/y5-097-retarget/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw);count=context['a'].end_frame+1;times=[f*160 for f in range(count)];values=[locals_at(bones,animation,t)for t in times];fingers={n:v.copy()for n,v in values[0].items()if '_Finger'in n}
    for frame in range(count):
        pose=dict(context['srcposes'][frame])
        for old,new in [('mune_n','mune_c_n'),('ketu_n','ketu_c_n'),('kosi_n','kosi_c_n'),('face','face_c_n')]:pose[new]=pose[old]
        values[frame],_=fit_arms(bones,values[frame],pose,context['bind'],fingers)
    out=Path(out);out.parent.mkdir(parents=True,exist_ok=True);write(out,text,spans,blocks(bones,values,times,None),name)
    return context,raw
