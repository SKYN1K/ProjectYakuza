from pathlib import Path
import sys,json,hashlib,subprocess,struct,math,zipfile

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'emotes/ProjectYakuzaEmotes';report=json.loads((mod/'docs/kiryu-step-up-emote-assets.json').read_text(encoding='utf-8'));sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    from y5_source_assets import entry,namespace
    def nested(data,name):
        dirs,_,count,entries=struct.unpack_from('>4I',data,16);names=[data[32+dirs*64+i*64:32+dirs*64+(i+1)*64].split(b'\0')[0].decode('ascii')for i in range(count)];flags,plain,size,offset=struct.unpack_from('>4I',data,entries+names.index(name)*32);packed=data[offset:offset+size];content=namespace['sllz'](packed)if flags else packed;assert len(content)==plain;return content
    contract=report['selection'];data,_=entry(contract['archive'],'012.par');assert nested(data,contract['resource']+'.gmt')==Path(report['source']).read_bytes();assert nested(data,'res.bin')==Path(contract['resources']).read_bytes();scene,_=entry(contract['archive'],'cmn.par');assert nested(scene,'cmn.bin')==Path(contract['scene']).read_bytes();rig,_=entry('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/chara_common/bone.par','c_cm_bone.gmd');assert rig==Path(report['rig']).read_bytes()
    print('PASS freshly extracted supplied final-chapter crowd challenge scene, resource table, original Kiryu motion and Kiwami skeleton bytes',flush=True)
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and'PASS original Kiryu'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
    for args in [['AnimationProbe',str(mod/report['output'])],['MajimaEmoteProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x',str(mod/report['output']),str(mod/report['selector']),str(report['frames']),'ProjectYakuza_KiryuStepUp']]:subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.105.0.zip')as archive:
        checked=0
        for name in archive.namelist():
            if name.endswith('/ProjectYakuza_LauSpearGround.x'):continue
            path=root/'combat'/name
            if not path.exists():path=mod/name.removeprefix('ProjectYakuza/')
            if '/media/'in name and path.suffix in ['.x','.xml','.png','.wav','.ogg']and not name.endswith('/'):
                assert path.read_bytes()==archive.read(name),name;checked+=1
    print('PASS',checked,'existing motion/selector/model/texture/audio bytes unchanged from v0.105.0')
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
from extract_majima_bat_emote import read_scene,resource
from extract_kiryu_step_up_emote import subtitles
from build_kiryu_step_up_emote import context_for
from yk.gmt_lib import read_gmt
for key in ['source','rig','retarget']:assert sha(report[key])==report[key+'Sha256']
assert sha(mod/report['output'])==report['sha256']and sha(mod/report['selector'])==report['selectorSha256']
for row in report['provenance']:assert sha(row['path'])==row['sha256']
selection=report['selection'];assert sha(selection['archive'])==selection['archiveSha256']and sha(selection['scene'])==selection['sceneSha256']and sha(selection['resources'])==selection['resourcesSha256'];rows=read_scene(selection['scene']);assert selection['actor']in rows and selection['motion']in rows and selection['motion']['parent']==selection['actor']['offset']and resource(selection['resources'],selection['motion']['guid'])==selection['resource'];dialogue=subtitles(selection['scene'],rows)
assert selection['dialogue']==[r for r in dialogue if r['firstFrame']>=2640]
cutStart=sum(read_gmt(r['path']).animation.end_frame for r in selection['timeline'][:-1]);assert all(sha(r['path'])==r['sha256']for r in selection['timeline']);assert cutStart==selection['sceneCutStartFrame']==2609 and selection['dialogue'][-1]['lastFrame']==2820 and cutStart+219==2828
assert report['sourceFrames']==list(range(0,220))and report['frames']==220 and report['fps']==30 and report['duration']==7.3
_,bones,animation,_=read(mod/report['output']);_,rawBones,raw,_=read(report['retarget']);context=context_for(True);mirror=Matrix.Diagonal((1,1,-1,1));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');worst=0;headError=0;samples=0;headRotations=[];hands=[]
for channels in animation.values():
    for keys in channels.values():assert len(keys)==220 and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
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
    headRotations.append((pose['Bip01_Spine1'].inverted()@pose['Bip01_Head']).to_quaternion());hands.append((pose['Bip01_Spine1'].inverted()@pose['Bip01_L_Hand']).translation);assert abs(min(p.y for p in skin_part(body,pose,report['ground']['feet']))-report['ground']['floor'])<.00002;originalWorld=world(rawBones,original);assert abs(pose['Bip01'].translation.x-originalWorld['Bip01'].translation.x)<.00001 and abs(pose['Bip01'].translation.z-originalWorld['Bip01'].translation.z)<.00001
assert (hands[-1]-hands[0]).length>.04
print('PASS original Kiryu subtitle/cut binding, 220 contiguous samples,',samples,'preserved body/finger samples; head/neck quaternion error',headError,'; source arm error',math.degrees(worst),'degrees; every native sole grounded, in-place root and original arm/hand challenge movement')
