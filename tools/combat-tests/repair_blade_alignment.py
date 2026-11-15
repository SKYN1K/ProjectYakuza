from pathlib import Path
import sys,json,hashlib,zipfile,math
from mathutils import Matrix,Vector

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w))
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import fit_arms,source_pose

mod=root/'combat/ProjectYakuza';media=mod/'42/media';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();baseline=root/'dist/ProjectYakuza-B42-v0.115.0.zip';work=root/'tools/blade-alignment-0116';work.mkdir(exist_ok=True);records=[]

def rotate_bone(bones,local,name,rotation):
 pose=world(bones,local);parent=bones[name]['parent'];desired=rotation.to_matrix().to_4x4();value=pose[parent].inverted()@desired if parent else desired;value.translation=local[name].translation;local[name]=value

def reach(bones,local,target,rotation):
 pose=world(bones,local);upper='Bip01_R_UpperArm';fore='Bip01_R_Forearm';hand='Bip01_R_Hand';u,e,h=[pose[n].translation for n in [upper,fore,hand]];a=(e-u).length;b=(h-e).length;delta=target-u;distance=min(delta.length,a+b-.00001);direction=delta.normalized();pole=(e-u)-direction*(e-u).dot(direction)
 if pole.length<.00001:pole=direction.cross(Vector((0,1,0)))
 pole.normalize();along=(a*a-b*b+distance*distance)/(2*distance);elbow=u+direction*along+pole*math.sqrt(max(0,a*a-along*along));wrist=u+direction*distance
 rotate_bone(bones,local,upper,(e-u).rotation_difference(elbow-u)@pose[upper].to_quaternion());rotate_bone(bones,local,fore,(h-e).rotation_difference(wrist-elbow)@pose[fore].to_quaternion());rotate_bone(bones,local,hand,rotation)
 for iteration in range(128):
  for joint in [fore,upper,'Bip01_R_Clavicle']+(['Bip01_Spine1']if iteration>=16 else[]):
   pose=world(bones,local);origin=pose[joint].translation;current=pose[hand].translation-origin;desired=target-origin
   if current.length>.00001 and desired.length>.00001:rotate_bone(bones,local,joint,current.rotation_difference(desired)@pose[joint].to_quaternion())
  if(world(bones,local)[hand].translation-target).length<.00005:break
 rotate_bone(bones,local,hand,rotation);return(world(bones,local)[hand].translation-target).length

with zipfile.ZipFile(baseline)as archive:
 for key,first,last in [('knife',40,130),('katana',64,140)]:
  report=json.loads((mod/'docs'/(key+'-heat-assets.json')).read_text());actor,victim=report['clips'];original=work/(key+'-original.x');original.write_bytes(archive.read('ProjectYakuza/'+actor['output']));text,bones,animation,spans=read(original);_,vb,va,_=read(mod/victim['output']);paths=report['paths'];values=[];errors=[]
  def victim_pose(frame):
   ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));return Matrix.Translation(shift)@world(vb,locals_at(vb,va,frame*160))['Bip01_Spine1']
  initial=world(bones,locals_at(bones,animation,first*160));anchor=victim_pose(first).inverted()@initial['Bip01_Prop1'];grip=initial['Bip01_Prop1'].inverted()@initial['Bip01_R_Hand']
  for frame in range(actor['frames']):
   local=locals_at(bones,animation,frame*160);pose=world(bones,local);prop=pose['Bip01_Prop1'].copy()
   if first-4<=frame<=last:
    target=victim_pose(frame)@anchor;t=max(0,min(1,(frame-(first-4))/4));t=t*t*(3-2*t);rotation=prop.to_quaternion().slerp(target.to_quaternion(),t);position=prop.translation.lerp(target.translation,t);desired=rotation.to_matrix().to_4x4();desired.translation=position
    originalGrip=prop.inverted()@pose['Bip01_R_Hand'];held=(originalGrip.translation-grip.translation).length<.12 and frame<=(53 if key=='knife'else last)
    if held:
     hand=desired@grip;errors.append(reach(bones,local,hand.translation,hand.to_quaternion()))
    pose=world(bones,local);local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@desired
   values.append(local)
  output=mod/actor['output'];selected={n:spans[n]for n in ['Bip01_Spine1','Bip01_R_Clavicle','Bip01_R_UpperArm','Bip01_R_Forearm','Bip01_R_Hand','Bip01_Prop1']};changes=blocks(bones,values,[i*160 for i in range(actor['frames'])],None);write(output,text,selected,{n:changes[n]for n in selected},Path(actor['output']).stem);actor['sha256']=sha(output);lock={'first':first,'last':last,'blendFirst':first-4,'victimBone':'Bip01_Spine1','relativeTransform':[list(r)for r in anchor],'original':str(original),'originalSha256':sha(original),'maxGripReachError':max(errors,default=0)};report['contactLock']=lock;(mod/'docs'/(key+'-heat-assets.json')).write_text(json.dumps(report,indent=2)+'\n');records.append({'kind':key,'output':actor['output'],'sha256':sha(output),**lock});print('LOCKED',key,'maximum grip reach error',lock['maxGripReachError'])
 converter=(w/'retarget_locomotion.py').read_text().split('poses=[];srcposes=[]')[0];manifest=json.loads((mod/'docs/blade-assets.json').read_text());grip=Matrix(json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['knife']['authoredOffsets']['Bip01_Prop1'])
 for record in manifest['clips']:
  if record['profile']!='knife' or record['label']not in ['Light01','Light02','Light03','Heavy','Ground']:continue
  original=work/Path(record['output']).name;original.write_bytes(archive.read('ProjectYakuza/'+record['output']));text,bones,animation,spans=read(original);sys.argv=['convert','--','InspectKnife',record['source']];context={};exec(compile(converter,'supplied_knife_source_context','exec'),context);count=record['sourceFrames'][1]+1;fingers={n:v for n,v in locals_at(bones,animation,0).items()if '_Finger'in n};values=[]
  for frame in range(count):
   local=locals_at(bones,animation,frame*160);local,_=fit_arms(bones,local,source_pose(context,frame),context['bind'],fingers);pose=world(bones,local);local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@pose['Bip01_R_Hand']@grip;values.append(local)
  hit={'Light01':9,'Light02':12,'Light03':13,'Heavy':11,'Ground':13}[record['label']];pose=world(bones,values[hit]);tip=pose['Bip01_Prop1']@Vector((0,.22,0));pivot=pose['Bip01_Spine1'].translation;delta=tip-pivot;yaw=math.atan2(delta.x,-delta.z)
  for frame,local in enumerate(values):
   weight=min(1,frame/max(1,hit),(count-1-frame)/max(1,count-1-hit));weight=weight*weight*(3-2*weight);pose=world(bones,local);turn=Matrix.Rotation(yaw*weight,3,'Y').to_quaternion();rotate_bone(bones,local,'Bip01_Spine1',turn@pose['Bip01_Spine1'].to_quaternion());pose=world(bones,local);local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@pose['Bip01_R_Hand']@grip
  output=mod/record['output'];write(output,text,spans,blocks(bones,values,[i*160 for i in range(count)],None),output.stem);record['sha256']=sha(output);pose=world(bones,values[hit]);tip=pose['Bip01_Prop1']@Vector((0,.22,0));residual=tip.x-pose['Bip01_Spine1'].translation.x;records.append({'kind':'ordinaryKnife','output':record['output'],'sha256':sha(output),'original':str(original),'originalSha256':sha(original),'contactFrame':hit,'yawCalibration':yaw,'lateralContactResidual':residual});print('CENTRED',record['label'],residual)
 (mod/'docs/blade-assets.json').write_text(json.dumps(manifest,indent=2)+'\n')
(mod/'docs/blade-contact-repair.json').write_text(json.dumps({'operation':'Native anatomy/attachment calibration of supplied original motion. Embedded knife and final katana thrust follow the victim torso rigidly; held wrists use native arm lengths, source release/regrip before contact stays unchanged. Ordinary knife arms are fitted to the original source directions; a contact-derived torso yaw centres the retained original swing at its unchanged native hit frame. No new source frames, model geometry, pixels or sound.','baseline':str(baseline),'baselineSha256':sha(baseline),'clips':records},indent=2)+'\n')
