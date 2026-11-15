from pathlib import Path
import sys,json,hashlib,subprocess,struct,math
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'emotes/ProjectYakuzaEmotes';report=json.loads((mod/'docs/shimano-emote-assets.json').read_text(encoding='utf-8'));sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    assert 'PASS original Shimano'in result.stdout,result.stdout
    print(result.stdout.strip());raise SystemExit(0)
sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
from extract_majima_bat_emote import read_scene,resource
from extract_shimano_emote import dialogue
from build_shimano_emote import context_for
from yk.gmt_lib import read_gmt
for key in ['source','rig','retarget']:assert sha(report[key])==report[key+'Sha256']
assert sha(mod/report['output'])==report['sha256']and sha(mod/report['selector'])==report['selectorSha256']
for row in report['provenance']:assert sha(row['path'])==row['sha256']
selection=report['selection'];assert sha(selection['archive'])==selection['archiveSha256']and sha(selection['scene'])==selection['sceneSha256']and sha(selection['resources'])==selection['resourcesSha256'];rows=read_scene(selection['scene']);assert selection['actor']in rows and selection['motion']in rows and selection['motion']['parent']==selection['actor']['offset']and resource(selection['resources'],selection['motion']['guid'])==selection['resource'];lines=dialogue(selection['scene'],rows)
assert selection['dialogue']==[r for r in lines if r['text']=='Shut the fuck up!']
data=Path(selection['scene']).read_bytes();pointer=struct.unpack_from('>I',data,28)[0];count=struct.unpack_from('>I',data,pointer)[0];cuts=list(struct.unpack_from('>'+str(count+1)+'f',data,pointer+12));assert cuts==selection['cutBoundaries']and cuts[9]==selection['sceneCutStartFrame']==1883
assert selection['dialogue'][0]=={'firstFrame':1948.0,'lastFrame':2020.0,'text':'Shut the fuck up!'}
assert report['sourceFrames']==list(range(167))and report['frames']==167 and report['fps']==30 and report['duration']==166/30
_,bones,animation,_=read(mod/report['output']);_,rawBones,raw,_=read(report['retarget']);context=context_for(True);mirror=Matrix.Diagonal((1,1,-1,1));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');worst=0;headError=0;samples=0;headRotations=[]
for channels in animation.values():
    for keys in channels.values():assert len(keys)==167 and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
for i,frame in enumerate(report['sourceFrames']):
    local=locals_at(bones,animation,i*160);original=locals_at(rawBones,raw,frame*160);pose=world(bones,local);source=source_pose(context,frame);source={n:Quaternion(report['sourceYaw']).to_matrix().to_4x4()@m for n,m in source.items()};chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();changed={'Bip01'}
    for side in ['L','R']:
        for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
            name='Bip01_'+side+'_'+bone;childName='Bip01_'+side+'_'+child;suffix='_'+side.lower()+'_n';expected=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();actual=(pose[childName].translation-pose[name].translation).normalized();error=math.acos(max(-1,min(1,expected.dot(actual))));worst=max(worst,error);assert error<.001;changed.add(name)
        changed.add('Bip01_'+side+'_Hand')
    for name in local:
        if name in changed:continue
        assert max(abs(local[name][a][b]-original[name][a][b])for a in range(4)for b in range(4))<.00001;samples+=1
    for name,sb in [('Bip01_Head','face_c_n'),('Bip01_Neck','kubi_c_n')]:
        expected=(mirror@source[sb]@mirror).to_quaternion()@context['bind'][name].to_quaternion();error=1-abs(expected.dot(pose[name].to_quaternion()));headError=max(headError,error);assert error<.00001
    headRotations.append((pose['Bip01_Spine1'].inverted()@pose['Bip01_Head']).to_quaternion());assert abs(min(p.y for p in skin_part(body,pose,report['ground']['feet']))-report['ground']['floor'])<.00002;originalWorld=world(rawBones,original);assert abs(pose['Bip01'].translation.x-originalWorld['Bip01'].translation.x)<.00001 and abs(pose['Bip01'].translation.z-originalWorld['Bip01'].translation.z)<.00001
print('PASS original Shimano subtitle/cut/resource binding, 167 contiguous source samples,',samples,'preserved body/finger samples; original head/neck rotations and arm directions, native proportions, grounded soles and in-place root')
