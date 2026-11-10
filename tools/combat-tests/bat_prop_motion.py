from mathutils import Matrix
from locomotion_math import locals_at,world

def prop_offsets(context,bones,animation,count):
    mirror=Matrix.Diagonal((1,1,-1,1));offsets=[];source=[]
    for frame in range(count):
        pose=context['srcposes'][frame]
        relative=mirror@(pose['ude3_r_n'].inverted()@pose['buki1_r_n'])@mirror
        native=world(bones,locals_at(bones,animation,frame*160));hand=native['Bip01_R_Hand']
        chest=(mirror@pose['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion()
        adapt=native['Bip01_Spine1'].to_quaternion()@chest.inverted()
        weapon=(mirror@pose['buki1_r_n']@mirror).to_quaternion()
        result=(hand.to_quaternion().inverted()@adapt@weapon).to_matrix().to_4x4()
        result.translation=hand.to_quaternion().inverted()@(adapt@(mirror@(pose['buki1_r_n'].translation-pose['ude3_r_n'].translation)))*context['scale']
        offsets.append(result);source.append(relative)
    return offsets,source
