from pathlib import Path
import sys,json,hashlib,zipfile,math
from mathutils import Matrix,Vector
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world,blocks,write
from native_body_geometry import load_body
from bicycle_grip import palm_offsets
MOD=ROOT/'combat/ProjectYakuza';OUT=ROOT/'previews/grab-grip-1.0.14';SOURCE=OUT/'source';SOURCE.mkdir(parents=True,exist_ok=True)
GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');ANIMS=MOD/'42/media/anims_X/Bob'
names=['GrabHold','GrabWalk','GrabVictimHoldNative']+['GrabVictimWalk'+d for d in ['Forward','Backward','Left','Right']]
with zipfile.ZipFile(ROOT/'dist/ProjectYakuza-B42-v1.0.13.zip')as archive:
    for name in names:(SOURCE/('ProjectYakuza_DD_'+name+'.x')).write_bytes(archive.read('ProjectYakuza/42/media/anims_X/Bob/ProjectYakuza_DD_'+name+'.x'))
body=load_body(GAME/'models_X/Skinned/MaleBody.x');_,nativeBones,nativeCurves,_=read(GAME/'anims_X/Bob/Bob_IdleAim1Hand.x');native=locals_at(nativeBones,nativeCurves,0)
_,vb,vc,_=read(SOURCE/'ProjectYakuza_DD_GrabVictimHoldNative.x');vlocal=locals_at(vb,vc,0);victim=world(vb,vlocal);chest=victim['Bip01_Spine1'].copy()
point=body['points'][6];collar=sum(((victim[bone]@offset@point)*weight for bone,weight,offset in body['weights'][6]),Vector())
_,ab,ac,_=read(SOURCE/'ProjectYakuza_DD_GrabHold.x');original=world(ab,locals_at(ab,ac,0));palm=palm_offsets(body,original)['L'];handRotation=original['Bip01_L_Hand'].to_quaternion()
distance=.42;lateral=.019354;target=Vector((lateral/1.5-collar.x,collar.y,-distance/1.5-collar.z));wrist=target-handRotation@palm
nativeGrip=json.loads((MOD/'docs/prop-attachment-repair.json').read_text(encoding='utf-8'))['nativeGrips']['bat']
records=[];worst=0;minBend=math.pi
def solve(local,bones):
    global worst,minBend
    pose=world(bones,local);shoulder=pose['Bip01_L_UpperArm'].translation;elbow=pose['Bip01_L_Forearm'].translation
    upper=local['Bip01_L_Forearm'].translation.length;lower=local['Bip01_L_Hand'].translation.length;axis=wrist-shoulder;length=axis.length
    assert abs(upper-lower)+.0001<length<upper+lower-.0001,('unreachable collar',length,upper+lower)
    axis.normalize();pole=elbow-shoulder;pole-=axis*pole.dot(axis);pole.normalize()
    along=(upper*upper-lower*lower+length*length)/(2*length);height=math.sqrt(max(0,upper*upper-along*along));desiredElbow=shoulder+axis*along+pole*height
    for name,child,targetPoint in [('Bip01_L_UpperArm','Bip01_L_Forearm',desiredElbow),('Bip01_L_Forearm','Bip01_L_Hand',wrist)]:
        pose=world(bones,local);rotation=pose[name].to_quaternion();oldDirection=rotation@local[child].translation;newDirection=targetPoint-pose[name].translation;rotation=oldDirection.rotation_difference(newDirection)@rotation
        value=pose[bones[name]['parent']].inverted()@rotation.to_matrix().to_4x4();value.translation=local[name].translation;local[name]=value
    pose=world(bones,local);value=pose[bones['Bip01_L_Hand']['parent']].inverted()@handRotation.to_matrix().to_4x4();value.translation=local['Bip01_L_Hand'].translation;local['Bip01_L_Hand']=value
    pose=world(bones,local);error=(pose['Bip01_L_Hand']@palm-target).length;worst=max(worst,error);assert error<.000002,error
    minBend=min(minBend,math.acos(max(-1,min(1,(upper*upper+lower*lower-length*length)/(2*upper*lower)))))
    return local
for name in names:
    path=SOURCE/('ProjectYakuza_DD_'+name+'.x');text,bones,curves,spans=read(path);count=len(curves['Bip01'][0]);values=[]
    for frame in range(count):
        local=locals_at(bones,curves,frame*160)
        if name in ['GrabHold','GrabWalk']:
            for key in ['Bip01','Bip01_Pelvis','Bip01_Spine']:local[key]=native[key].copy()
            local=solve(local,bones)
        else:
            pose=world(bones,local);local['Bip01_Spine1']=pose[bones['Bip01_Spine1']['parent']].inverted()@chest
        values.append(local)
    output=ANIMS/path.name if '--write'in sys.argv else OUT/path.name;changes=blocks(bones,values,[i*160 for i in range(count)],nativeGrip);write(output,text,spans,changes,path.stem)
    records.append({'clip':path.stem,'inputSha256':hashlib.sha256(path.read_bytes()).hexdigest(),'outputSha256':hashlib.sha256(output.read_bytes()).hexdigest(),'frames':count,'fps':30,'output':output.relative_to(ROOT).as_posix()})
report={'version':'1.0.14','authorization':'User approved reworking original grab data and rendering an offline grip preview on 2026-11-25.','operation':'Native PZ reference torso parents stabilize the holding frame. Original torso/right-arm motion remains; a fixed native palm/collar surface contact determines the left two-bone arm fit. Held victim chest remains in its original frame-zero grip pose while original walking legs remain. No AI art/audio or additional source frames.','distance':distance,'lateral':lateral,'collarVertex':6,'collarModelPoint':list(collar),'collarLocalPoint':list(chest.inverted()@collar),'palmLocalPoint':list(palm),'palmTarget':list(target),'maxPalmErrorModel':worst,'minimumElbowAngleRadians':minBend,'clips':records,'nativeBodySha256':hashlib.sha256((GAME/'models_X/Skinned/MaleBody.x').read_bytes()).hexdigest()}
(MOD/'docs/grab-grip-1.0.14.json'if '--write'in sys.argv else OUT/'grip.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('PASS original grab surface fit:',worst,'model units maximum palm error;',len(records),'clips')
