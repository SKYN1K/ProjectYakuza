from pathlib import Path
import sys,json,hashlib,subprocess,struct,math

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/lau-spear-emote-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    from y5_source_assets import entry,namespace
    def nested(data,name):
        dirs,_,count,entries=struct.unpack_from('>4I',data,16);names=[data[32+dirs*64+i*64:32+dirs*64+(i+1)*64].split(b'\0')[0].decode('ascii')for i in range(count)];flags,plain,size,offset=struct.unpack_from('>4I',data,entries+names.index(name)*32);packed=data[offset:offset+size];content=namespace['sllz'](packed)if flags else packed;assert len(content)==plain;return content
    contract=report['selection'];data,_=entry(contract['archive'],'007.par')
    for role in ['actor','spear']:
        record=contract['selection'][role];assert nested(data,record['resource']+'.gmt')==Path(record['path']).read_bytes()
    assert nested(data,'res.bin')==Path(contract['resources']).read_bytes();scene,_=entry(contract['archive'],'cmn.par');assert nested(scene,'cmn.bin')==Path(contract['scene']).read_bytes();rig,_=entry('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/chara_common/bone.par','c_cm_bone.gmd');assert rig==Path(report['rig']).read_bytes()
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and'PASS original Lau'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
    for args in [['AnimationProbe',str(mod/report['output'])],['PropAttachmentProbe',str(w/'lau-emote-props.tsv')],['MajimaEmoteProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x',str(mod/report['output']),str(mod/report['selector']),'79','ProjectYakuza_LauSpearGround']]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    print('PASS fresh original Kiwami cutscene, actor, spear, resources and skeleton archive bytes')
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
from extract_majima_bat_emote import read_scene,resource
from extract_lau_spear_emote import native_profiles,mesh_vertices
from build_lau_spear_emote import context_for
from yk.gmt_lib import read_gmt
for key in ['source','propSource','rig','retarget']:assert sha(report[key])==report[key+'Sha256']
assert sha(mod/report['output'])==report['sha256']and sha(mod/report['selector'])==report['selectorSha256']
for row in report['provenance']:assert sha(row['path'])==row['sha256']
selection=report['selection'];assert sha(selection['archive'])==selection['archiveSha256']and sha(selection['scene'])==selection['sceneSha256']and sha(selection['resources'])==selection['resourcesSha256'];rows=read_scene(selection['scene'])
for key in ['actor','spear']:
    entry=selection['selection'][key];assert entry['node']in rows and entry['motion']in rows and resource(selection['resources'],entry['motion']['guid'])==entry['resource'];assert sha(entry['path'])==entry['sha256']
assert report['sourceFrames']==list(range(112,191))and report['frames']==79 and report['fps']==30 and report['duration']==78/30
assert json.loads(json.dumps(native_profiles()))==selection['nativeProfiles']
profiles=selection['nativeProfiles']['items'];assert len(profiles)==8
for entry in profiles:assert sha(entry['mesh'])==entry['meshSha256']
_,bones,animation,_=read(mod/report['output']);_,rawBones,raw,_=read(report['retarget']);context=context_for(True);mirror=Matrix.Diagonal((1,1,-1,1));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');propTrack=read_gmt(report['propSource']).animation.bones['anm_root'];propTrack.rotation.fill_channels();propTrack.location.fill_channels();meshes={p['item']:[Vector(v)for v in mesh_vertices(p['mesh'])]for p in profiles};worst=0;samples=0;minimum=100;contact=[];grip=report['grip'];encoded=[]
for channels in animation.values():
    for keys in channels.values():assert len(keys)==79 and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
for i,frame in enumerate(report['sourceFrames']):
    local=locals_at(bones,animation,i*160);original=locals_at(rawBones,raw,frame*160);pose=world(bones,local);source=source_pose(context,frame);q=context['sample'](propTrack.rotation,frame,Quaternion((1,0,0,0)),True);center=context['sample'](context['a'].bones['center_c_n'].location,frame,Vector((0,0,0)));sourceProp=Matrix.Translation(context['sample'](propTrack.location,frame,Vector((0,0,0))))@q.to_matrix().to_4x4();originalGrip=sourceProp.inverted()@(source['ude3_r_n'].translation+center);assert (originalGrip-Vector(grip['sourceShaftPoints'][i])).length<.00001;source={n:Quaternion(report['sourceYaw']).to_matrix().to_4x4()@m for n,m in source.items()};chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();changed={'Bip01','Bip01_Prop1','Bip01_Prop2'}
    for side in ['L','R']:
        for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
            name='Bip01_'+side+'_'+bone;childName='Bip01_'+side+'_'+child;suffix='_'+side.lower()+'_n';expected=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();actual=(pose[childName].translation-pose[name].translation).normalized();error=math.acos(max(-1,min(1,expected.dot(actual))));worst=max(worst,error);assert error<.001;changed.add(name)
        changed.add('Bip01_'+side+'_Hand')
    for name in local:
        if name in changed or '_Finger'in name:continue
        assert max(abs(local[name][a][b]-original[name][a][b])for a in range(4)for b in range(4))<.00001;samples+=1
    assert abs(min(p.y for p in skin_part(body,pose,report['ground']['feet']))-report['ground']['floor'])<.00002
    sourceWeapon=Quaternion(report['sourceYaw'])@q;expectedWeapon=adapt@(mirror@sourceWeapon.to_matrix().to_4x4()@mirror).to_quaternion();prop=pose['Bip01_Prop1'];assert 1-abs(prop.to_quaternion().dot(expectedWeapon))<.00001
    palm=pose['Bip01_R_Hand']@Vector(grip['palm']);shaft=prop@Vector((0,grip['shaftY'][i],0));assert (palm-shaft).length<.00002;assert -.02<grip['shaftY'][i]<min(p['bounds'][1][1]for p in profiles)-.04
    expectedOffset=pose['Bip01_R_Hand'].inverted()@prop;assert max(abs(expectedOffset[a][b]-grip['nativeOffsets'][i][a][b])for a in range(4)for b in range(4))<.00002;encoded.append(','.join(str(v)for row in expectedOffset for v in row))
    for item,vertices in meshes.items():
        bottom=min((prop@v).y for v in vertices);minimum=min(minimum,bottom);assert bottom>=report['ground']['floor']-.006,(item,frame,bottom)
        if frame==selection['contactFrame']:contact.append(abs(bottom-report['ground']['floor']));assert contact[-1]<.006,(item,bottom)
assert max(abs(v)for v in grip['floorSlideCorrection'])<.13
left=','.join(str(v)for row in grip['offsets']['Bip01_Prop2']for v in row);(w/'lau-emote-props.tsv').write_text('\t'.join([str(mod/report['output']),';'.join(encoded),left,'79']))
print('PASS original Lau CMN/resource roles, 79 contiguous source samples,',samples,'unchanged body samples, source arms within',math.degrees(worst),'degrees, independent spear rotation, grounded soles and calibrated sliding palm; all 8 native spear models contact floor within',max(contact),'and minimum height',minimum)
