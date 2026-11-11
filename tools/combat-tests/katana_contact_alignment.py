from pathlib import Path
from mathutils import Vector
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part,contact_pair,validate_bind

def align_contacts(actor,victim,paths):
    _,ab,aa,_=read(actor);_,vb,va,_=read(victim);native=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');bindError=validate_bind(native);anchors=[]
    for frame,kind,bone in [(23,'blade','Bip01_Spine1'),(44,'fist','Bip01_Head'),(62,'blade','Bip01_Spine'),(64,'blade','Bip01_Spine')]:
        a=world(ab,locals_at(ab,aa,frame*160));v=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5))
        if kind=='blade':
            prop=a['Bip01_Prop1'];axis=prop.to_quaternion()@Vector((0,1,0));target=v[bone].translation
            t=(target.y-prop.translation.y)/axis.y if abs(axis.y)>.0001 else (target+shift-prop.translation).dot(axis)
            t=max(.1307,min(.576296,t));point=prop@Vector((0,t,0));target=target.copy();extra={'bladeParameter':t}
        else:
            hand=skin_part(native,a,['Bip01_R_Hand','Bip01_R_Finger']);head=[p+shift for p in skin_part(native,v,['Bip01_Head'])];point,target=contact_pair(hand,head);target-=shift;extra={'nativeSkinBindError':bindError}
        required=[ap[0]+(target.z-point.z)*1.5,ap[1]+(point.x-target.x)*1.5];delta=[required[i]-vp[i]for i in range(2)]
        anchors.append({'frame':frame,'kind':kind,'bone':bone,'actorPoint':list(point),'victimPoint':list(target),'delta':delta,'verticalResidual':abs(point.y-target.y),**extra})
    thrust=[sum(a['delta'][i]for a in anchors[-2:])/2 for i in range(2)]
    for anchor in anchors[-2:]:anchor['requiredDelta']=anchor['delta'];anchor['delta']=list(thrust)
    knots=[{'frame':0,'delta':[0.,0.]},*anchors,{'frame':140,'delta':[0.,0.]}];result=[[list(p)for p in row]for row in paths]
    for frame in range(141):
        left,right=next((a,b)for a,b in zip(knots,knots[1:])if a['frame']<=frame<=b['frame']);t=(frame-left['frame'])/(right['frame']-left['frame']);weight=t*t*(3-2*t)
        for axis in range(2):result[1][frame][axis]+=left['delta'][axis]*(1-weight)+right['delta'][axis]*weight
    report={'operation':'Native anatomy retarget alignment: original slash at frame23, actual native fist/head surfaces at44, and a common torso-volume offset through blade entry/recovery at62/64. A shared thrust offset avoids pulling the victim after the moving blade. Smooth victim staging only; source body poses, times, ground height and airborne weapon motion retained.','knots':knots,'anchors':anchors,'nativeBody':native['path']}
    return result,report
