from mathutils import Matrix,Vector,Quaternion
from locomotion_math import world

def source_pose(context,frame):
    result={};sample=context['sample'];animation=context['a'];bones=context['sb']
    for bone in bones:
        track=animation.bones.get(bone.name);position=sample(track.location if track else None,frame,Vector(bone.local_pos[:3]));rotation=sample(track.rotation if track else None,frame,Quaternion((bone.local_rot[3],*bone.local_rot[:3])),True)
        if bone.name=='center_c_n':position=Vector((0,0,0))
        local=Matrix.Translation(position)@rotation.to_matrix().to_4x4();result[bone.name]=result[bones[bone.parent_index].name]@local if bone.parent_index>=0 else local
    return result

def fit_arms(frames,local,source,bind,fingers):
    mirror=Matrix.Diagonal((1,1,-1,1));base=world(frames,local);sourceChest=(mirror@source['mune_c_n']@mirror).to_quaternion();desiredChest=sourceChest@bind['Bip01_Spine1'].to_quaternion();adapt=base['Bip01_Spine1'].to_quaternion()@desiredChest.inverted();rotations={};names={};directions={}
    for side in ['L','R']:
        suffix='_'+side.lower()+'_n'
        for bone,child,sourceBone,sourceChild in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
            name='Bip01_'+side+'_'+bone;nextName='Bip01_'+side+'_'+child;seed=adapt@(mirror@source[sourceBone+suffix]@mirror).to_quaternion()@bind[name].to_quaternion();direction=(adapt@(mirror@(source[sourceChild+suffix].translation-source[sourceBone+suffix].translation))).normalized();offset=local[nextName].translation;rotation=(seed@offset).rotation_difference(direction)@seed;rotations[name]=rotation;directions[name]=direction;names[name]=nextName
        fore='Bip01_'+side+'_Forearm';hand='Bip01_'+side+'_Hand';sourceFore=(mirror@source['ude2'+suffix]@mirror).to_quaternion();sourceHand=(mirror@source['ude3'+suffix]@mirror).to_quaternion();wrist=adapt@(sourceHand@sourceFore.inverted())@adapt.inverted();neutral=bind[fore].to_quaternion().inverted()@bind[hand].to_quaternion();rotations[hand]=wrist@rotations[fore]@neutral
    actual={}
    for name,data in frames.items():
        parent=data['parent']
        if name in rotations:
            rotation=rotations[name].to_matrix().to_4x4();value=actual[parent].inverted()@rotation if parent else rotation;value.translation=local[name].translation;local[name]=value
        elif '_Finger'in name and name in fingers:local[name]=fingers[name].copy()
        actual[name]=actual[parent]@local[name]if parent else local[name]
    return local,{'directions':directions,'children':names,'adapt':adapt}
