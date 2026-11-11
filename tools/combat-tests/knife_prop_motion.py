from mathutils import Matrix,Vector
from locomotion_math import locals_at,world

def grip_frames(context,bones,animation,grip,count):
    mirror=Matrix.Diagonal((1,1,-1,1));weapons=[];relative=[];hands=[];reference=None;shaft=grip.to_quaternion()@Vector((0,1,0));hilt=Vector((0,-grip.translation.dot(shaft),0));palm=grip@hilt
    for frame in range(count):
        source=context['srcposes'][frame];offset=mirror@(source['ude3_r_n'].inverted()@source['buki1_r_n'])@mirror
        if reference is None:reference=offset.copy()
        native=world(bones,locals_at(bones,animation,frame*160));hand=native['Bip01_R_Hand'];chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=native['Bip01_Spine1'].to_quaternion()@chest.inverted();weapon=adapt@(mirror@source['buki1_r_n']@mirror).to_quaternion()
        sourceFore=(mirror@source['ude2_r_n']@mirror).to_quaternion();sourceHand=(mirror@source['ude3_r_n']@mirror).to_quaternion();bind=context['bind'];neutral=bind['Bip01_R_Forearm'].to_quaternion().inverted()@bind['Bip01_R_Hand'].to_quaternion();original=(adapt@(sourceHand@sourceFore.inverted())@adapt.inverted())@native['Bip01_R_Forearm'].to_quaternion()@neutral
        sign=1 if(offset.to_quaternion()@Vector((0,1,0))).dot(reference.to_quaternion()@Vector((0,1,0)))>=0 else -1;correction=(original@shaft*sign).rotation_difference(weapon@Vector((0,1,0)));departure=offset.translation-reference.translation;held=max(0,min(1,1-(departure.length-.005)/.08));fitted=original.slerp(correction@original,held)
        value=weapon.to_matrix().to_4x4();value.translation=hand.translation+fitted@palm-weapon@hilt+(adapt@sourceHand@departure)*context['scale'];weapons.append(value);relative.append(offset);hands.append(fitted)
    return weapons,relative,hands

def prop_offsets(context,bones,animation,count):
    import json
    from pathlib import Path
    root=Path(__file__).resolve().parents[2];grip=Matrix(json.loads((root/'combat/ProjectYakuza/docs/prop-attachment-repair.json').read_text())['nativeGrips']['knife']['authoredOffsets']['Bip01_Prop1']);poses,relative,_=grip_frames(context,bones,animation,grip,count);result=[]
    for frame,pose in enumerate(poses):
        native=world(bones,locals_at(bones,animation,frame*160));result.append(native['Bip01_R_Hand'].inverted()@pose)
    return result,relative
