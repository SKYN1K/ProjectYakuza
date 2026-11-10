from mathutils import Matrix,Vector,Quaternion
from locomotion_math import locals_at,world
from weapon_hold_geometry import source_pose

def prop_offsets(context,prop,frames,animation,grip,count):
    sample=context['sample'];actor=context['a'];mirror=Matrix.Diagonal((1,1,-1,1))
    track=prop.bones['anm_root'];stageTrack=actor.bones['vector_c_n'];reference=None;offsets=[];source=[]
    for frame in range(count):
        pose=source_pose(context,frame)
        stage=Matrix.Translation(sample(stageTrack.location,frame,Vector((0,0,0))))@sample(stageTrack.rotation,frame,Quaternion((1,0,0,0)),True).to_matrix().to_4x4()
        sword=Matrix.Translation(sample(track.location,frame,Vector((0,0,0))))@sample(track.rotation,frame,Quaternion((1,0,0,0)),True).to_matrix().to_4x4()
        relative=mirror@((stage@pose['ude3_r_n']).inverted()@sword)@mirror
        if reference is None:reference=relative.copy()
        native=world(frames,locals_at(frames,animation,frame*160));hand=native['Bip01_R_Hand']
        chest=(mirror@pose['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion()
        adapt=native['Bip01_Spine1'].to_quaternion()@chest.inverted()
        basis=hand.to_quaternion().inverted()@adapt@(mirror@pose['ude3_r_n']@mirror).to_quaternion()
        delta=relative.to_quaternion()@reference.to_quaternion().inverted()
        rotation=basis@delta@basis.inverted()@grip.to_quaternion()
        offset=rotation.to_matrix().to_4x4()
        offset.translation=grip.translation+(basis@(relative.translation-reference.translation))*context['scale']
        offsets.append(offset);source.append(relative)
    return offsets,source
