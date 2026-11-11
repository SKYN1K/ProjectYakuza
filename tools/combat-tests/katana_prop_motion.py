from mathutils import Matrix,Vector,Quaternion
from locomotion_math import locals_at,world
from weapon_hold_geometry import source_pose

def grip_frames(context,prop,frames,animation,grip,count):
    sample=context['sample'];actor=context['a'];mirror=Matrix.Diagonal((1,1,-1,1));track=prop.bones['anm_root'];stageTrack=actor.bones['vector_c_n'];reference=None;result=[];source=[];hands=[]
    shaft=grip.to_quaternion()@Vector((0,1,0));gripPoint=Vector((0,-grip.translation.dot(shaft),0));palm=grip@gripPoint;bind=context['bind']
    neutral=bind['Bip01_R_Forearm'].to_quaternion().inverted()@bind['Bip01_R_Hand'].to_quaternion()
    for frame in range(count):
        pose=source_pose(context,frame)
        stage=Matrix.Translation(sample(stageTrack.location,frame,Vector((0,0,0))))@sample(stageTrack.rotation,frame,Quaternion((1,0,0,0)),True).to_matrix().to_4x4()
        sword=Matrix.Translation(sample(track.location,frame,Vector((0,0,0))))@sample(track.rotation,frame,Quaternion((1,0,0,0)),True).to_matrix().to_4x4()
        relative=mirror@((stage@pose['ude3_r_n']).inverted()@sword)@mirror
        if reference is None:reference=relative.copy()
        native=world(frames,locals_at(frames,animation,frame*160));hand=native['Bip01_R_Hand']
        chest=(mirror@pose['mune_c_n']@mirror).to_quaternion()@bind['Bip01_Spine1'].to_quaternion();adapt=native['Bip01_Spine1'].to_quaternion()@chest.inverted()
        sourceFore=(mirror@pose['ude2_r_n']@mirror).to_quaternion();sourceHand=(mirror@pose['ude3_r_n']@mirror).to_quaternion()
        originalHand=(adapt@(sourceHand@sourceFore.inverted())@adapt.inverted())@native['Bip01_R_Forearm'].to_quaternion()@neutral
        rotation=originalHand.inverted()@adapt@sourceHand@relative.to_quaternion()
        axis=rotation@Vector((0,1,0));target=shaft*(1 if frame<49 else -1);fitted=axis.rotation_difference(target)@rotation
        distance=(relative.translation-reference.translation).length;held=max(0,min(1,1-(distance-.005)/.08))
        constrained=originalHand@rotation@fitted.inverted();newHand=originalHand.slerp(constrained,held);weapon=originalHand@rotation
        translation=hand.translation+newHand@palm-weapon@gripPoint+(adapt@sourceHand@(relative.translation-reference.translation))*context['scale']
        matrix=weapon.to_matrix().to_4x4();matrix.translation=translation;result.append(matrix);source.append(relative);hands.append(newHand)
    return result,source,hands

def prop_offsets(context,prop,frames,animation,grip,count):
    poses,source,_=grip_frames(context,prop,frames,animation,grip,count);offsets=[]
    for frame,pose in enumerate(poses):
        native=world(frames,locals_at(frames,animation,frame*160));offsets.append(native['Bip01_R_Hand'].inverted()@pose)
    return offsets,source
