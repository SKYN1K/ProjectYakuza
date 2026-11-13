from pathlib import Path
import sys,json,hashlib,subprocess,math,struct

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/majima-bat-emote-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    from y5_source_assets import entry,namespace
    def nested(data,name):
        dirs,_,count,entries=struct.unpack_from('>4I',data,16);names=[data[32+dirs*64+i*64:32+dirs*64+(i+1)*64].split(b'\0')[0].decode('ascii')for i in range(count)];flags,plain,size,offset=struct.unpack_from('>4I',data,entries+names.index(name)*32);packed=data[offset:offset+size];content=namespace['sllz'](packed)if flags else packed;assert len(content)==plain;return content
    contract=report['selection'];data,_=entry(contract['archive'],'009.par')
    for role in ['actor','bat']:
        record=contract['selection'][role];assert nested(data,record['resource']+'.gmt')==Path(record['path']).read_bytes()
    assert nested(data,'res.bin')==Path(contract['resources']).read_bytes();scene,_=entry(contract['archive'],'cmn.par');assert nested(scene,'cmn.bin')==Path(contract['scene']).read_bytes();rig,_=entry('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/chara_common/bone.par','c_cm_bone.gmd');assert rig==Path(report['rig']).read_bytes()
    print('PASS freshly extracted original scene, resource bindings, actor, independent bat and Kiwami skeleton bytes')
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and'PASS original Majima'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
    for args in [['AnimationProbe',str(mod/report['output'])],['PropAttachmentProbe',str(w/'majima-emote-props.tsv')],['MajimaEmoteProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x',str(mod/report['output']),str(mod/report['selector'])]]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
from extract_majima_bat_emote import read_scene,resource
from build_majima_bat_emote import context_for
from yk.gmt_lib import read_gmt
for key in ['source','propSource','rig','retarget']:assert sha(report[key])==report[key+'Sha256']
assert sha(mod/report['output'])==report['sha256']and sha(mod/report['selector'])==report['selectorSha256']
for row in report['provenance']:assert sha(row['path'])==row['sha256']
selection=report['selection'];assert sha(selection['archive'])==selection['archiveSha256']and sha(selection['scene'])==selection['sceneSha256']and sha(selection['resources'])==selection['resourcesSha256'];rows=read_scene(selection['scene'])
for key in ['actor','bat']:
    entry=selection['selection'][key];assert entry['node']in rows and entry['motion']in rows and resource(selection['resources'],entry['motion']['guid'])==entry['resource'];assert sha(entry['path'])==entry['sha256']
assert report['sourceFrames']==list(range(170,322))and report['frames']==152 and report['fps']==30 and report['duration']==151/30
_,bones,animation,_=read(mod/report['output']);_,rawBones,raw,_=read(report['retarget']);context=context_for(True);mirror=Matrix.Diagonal((1,1,-1,1));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');worst=0;samples=0;pointing=[]
propTrack=read_gmt(report['propSource']).animation.bones['anm_root'];propTrack.rotation.fill_channels();propTrack.location.fill_channels()
for channels in animation.values():
    for keys in channels.values():assert len(keys)==152 and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
for i,frame in enumerate(report['sourceFrames']):
    local=locals_at(bones,animation,i*160);original=locals_at(rawBones,raw,frame*160);pose=world(bones,local);source=source_pose(context,frame);center=context['sample'](context['a'].bones['center_c_n'].location,frame,Vector((0,0,0)));originalHand=source['ude3_r_n'].translation+center;originalProp=context['sample'](propTrack.location,frame,Vector((0,0,0)));assert (originalHand-originalProp).length<.1;source={n:Quaternion(report['sourceYaw']).to_matrix().to_4x4()@m for n,m in source.items()};chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();changed={'Bip01','Bip01_Prop1','Bip01_Prop2'}
    for side in ['L','R']:
        for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
            name='Bip01_'+side+'_'+bone;childName='Bip01_'+side+'_'+child;suffix='_'+side.lower()+'_n';expected=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();actual=(pose[childName].translation-pose[name].translation).normalized();error=math.acos(max(-1,min(1,expected.dot(actual))));worst=max(worst,error);assert error<.001;changed.add(name)
        changed.add('Bip01_'+side+'_Hand')
    for name in local:
        if name in changed or '_Finger'in name:continue
        assert max(abs(local[name][a][b]-original[name][a][b])for a in range(4)for b in range(4))<.00001;samples+=1
    for name in local:
        if '_Finger'in name:assert max(abs(local[name][a][b]-locals_at(rawBones,raw,170*160)[name][a][b])for a in range(4)for b in range(4))<.00001
    assert abs(min(p.y for p in skin_part(body,pose,report['ground']['feet']))-report['ground']['floor'])<.00002
    originalWeapon=Quaternion(report['sourceYaw'])@context['sample'](propTrack.rotation,frame,Quaternion((1,0,0,0)),True);expectedWeapon=adapt@(mirror@originalWeapon.to_matrix().to_4x4()@mirror).to_quaternion();prop=pose['Bip01_Prop1'];assert 1-abs(prop.to_quaternion().dot(expectedWeapon))<.00001 and 1-abs(expectedWeapon.dot(Quaternion(report['weaponRotations'][i])))<.00001
    if 210<=frame<=255:pointing.append((prop.to_quaternion()@Vector((0,1,0))).dot(Vector((0,0,-1))))
assert min(pointing)>.75,min(pointing)
grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][name]for v in row)for name in ['Bip01_Prop1','Bip01_Prop2']];(w/'majima-emote-props.tsv').write_text('\t'.join([str(mod/report['output']),*offsets,'152']))
print('PASS original Majima scene/resource bindings, 152 contiguous samples,',samples,'preserved body samples, source arm error',math.degrees(worst),'degrees, all grounded soles and source-directed bat point; minimum forward dot',min(pointing))
