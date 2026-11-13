from pathlib import Path
import sys,json,hashlib,subprocess,struct,math

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'emotes/ProjectYakuzaEmotes';report=json.loads((mod/'docs/lau-spear-emote-assets.json').read_text(encoding='utf-8'));sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    from y5_source_assets import entry,namespace
    def nested(data,name):
        dirs,_,count,entries=struct.unpack_from('>4I',data,16);names=[data[32+dirs*64+i*64:32+dirs*64+(i+1)*64].split(b'\0')[0].decode('ascii')for i in range(count)];flags,plain,size,offset=struct.unpack_from('>4I',data,entries+names.index(name)*32);packed=data[offset:offset+size];content=namespace['sllz'](packed)if flags else packed;assert len(content)==plain;return content
    contract=report['selection']
    for segment in contract['segments']:
        data,_=entry(contract['archive'],segment['cut']+'.par')
        for role in ['actor','spear']:
            record=segment['selection'][role];assert nested(data,record['resource']+'.gmt')==Path(record['path']).read_bytes()
        assert nested(data,'res.bin')==Path(segment['resources']).read_bytes()
    scene,_=entry(contract['archive'],'cmn.par');assert nested(scene,'cmn.bin')==Path(contract['scene']).read_bytes();rig,_=entry('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/chara_common/bone.par','c_cm_bone.gmd');assert rig==Path(report['rig']).read_bytes()
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True);print(result.stdout,flush=True);assert result.returncode==0 and'PASS original Lau'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';prefix=[java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*']
    subprocess.run(prefix+['PropAttachmentProbe',str(w/'lau-emote-props.tsv')],cwd=w,check=True)
    for output in report['outputs']:
        for args in [['AnimationProbe',str(mod/output['output'])],['MajimaEmoteProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x',str(mod/output['output']),str(mod/output['selector']),'154',output['clip']]]:
            result=subprocess.run(prefix+args,cwd=w,capture_output=True,text=True);assert result.returncode==0,result.stdout+result.stderr
        print('PASS native Human / 154 keys / 5.1 seconds / selector and MP state:',output['item'],flush=True)
    print('PASS fresh original Kiwami cuts 007/008, seamless 75-frame extension and all 22 native spear imports')
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose,fit_arms
from native_body_geometry import load_body,skin_part
from extract_majima_bat_emote import read_scene,resource
from extract_lau_spear_emote import native_profiles,mesh_vertices
from build_lau_spear_emote import context_for
from yk.gmt_lib import read_gmt
assert sha(report['rig'])==report['rigSha256']
for row in report['provenance']+report['retargets']:assert sha(row['path'])==row['sha256']
selection=report['selection'];assert sha(selection['archive'])==selection['archiveSha256']and sha(selection['scene'])==selection['sceneSha256'];rows=read_scene(selection['scene'])
for segment in selection['segments']:
    assert sha(segment['resources'])==segment['resourcesSha256']
    for role in ['actor','spear']:
        record=segment['selection'][role];assert record['node']in rows and record['motion']in rows and record['motion']['parent']==record['node']['offset']and resource(segment['resources'],record['motion']['guid'])==record['resource']and sha(record['path'])==record['sha256']
assert [(s['cut'],s['firstFrame'],s['lastFrame'])for s in selection['segments']]==[('007',112,190),('008',1,75)]
expected=[{'segment':0,'frame':i}for i in range(112,191)]+[{'segment':1,'frame':i}for i in range(1,76)];assert report['sourceSamples']==expected and report['frames']==154 and report['fps']==30 and report['duration']==5.1 and report['extensionSeconds']==2.5
assert json.loads(json.dumps(native_profiles()))==selection['nativeProfiles'];profiles=selection['nativeProfiles']['items'];assert len(profiles)==len(report['outputs'])==22
contexts=[context_for(True,i)for i in range(2)];raws=[read(r['path'])for r in report['retargets']];props=[read_gmt(s['selection']['spear']['path']).animation.bones['anm_root']for s in selection['segments']]
for prop in props:prop.rotation.fill_channels();prop.location.fill_channels()
left=source_pose(contexts[0],190);right=source_pose(contexts[1],0);seam=max(abs(left[n][i][j]-right[n][i][j])for n in left for i in range(4)for j in range(4));assert seam<.0001,seam
for kind,default,rot in [('location',Vector((0,0,0)),False),('rotation',Quaternion((1,0,0,0)),True)]:
    a=contexts[0]['sample'](getattr(props[0],kind),190,default,rot);b=contexts[1]['sample'](getattr(props[1],kind),0,default,rot);assert (1-abs(a.dot(b))if rot else(a-b).length)<.0001
mirror=Matrix.Diagonal((1,1,-1,1));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');grip=report['grip'];base=[];directions=[];weapons=[];bones=raws[0][1]
for sample in expected:
    frame=sample['frame'];segment=sample['segment'];context=contexts[segment];prop=props[segment];raw=raws[segment];local=locals_at(raw[1],raw[2],frame*160);source=source_pose(context,frame);center=context['sample'](context['a'].bones['center_c_n'].location,frame,Vector((0,0,0)));q=context['sample'](prop.rotation,frame,Quaternion((1,0,0,0)),True);sourceProp=Matrix.Translation(context['sample'](prop.location,frame,Vector((0,0,0))))@q.to_matrix().to_4x4();originalGrip=sourceProp.inverted()@(source['ude3_r_n'].translation+center);assert(originalGrip-Vector(grip['sourceShaftPoints'][len(base)])).length<.00001;source={n:Quaternion(report['sourceYaw']).to_matrix().to_4x4()@m for n,m in source.items()};fingers={n:v.copy()for n,v in local.items()if '_Finger'in n};fitted,fit=fit_arms(bones,{n:m.copy()for n,m in local.items()},source,context['bind'],fingers);base.append(world(bones,fitted));directions.append(fit['directions']);weapons.append(fit['adapt']@(mirror@(Quaternion(report['sourceYaw'])@q).to_matrix().to_4x4()@mirror).to_quaternion())
rowsTSV=[];tested=0;maxLift=0;maximumContact=0
for profile,output in zip(profiles,report['outputs']):
    assert profile['item']==output['item']and profile['clip']==output['clip']and sha(mod/output['output'])==output['sha256']and sha(mod/output['selector'])==output['selectorSha256']
    for variant in profile['variants']:assert sha(variant['mesh'])==variant['meshSha256']
    _,bones,animation,_=read(mod/output['output']);encoded=[];vertices=[Vector(v)for v in mesh_vertices(profile['mesh'])]
    for channels in animation.values():
        for keys in channels.values():assert len(keys)==154 and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for i,sample in enumerate(expected):
        local=locals_at(bones,animation,i*160);pose=world(bones,local);original=locals_at(raws[sample['segment']][1],raws[sample['segment']][2],sample['frame']*160);lift=output['armLift'][i];assert 0<=lift<.12;maxLift=max(maxLift,lift);changed={'Bip01','Bip01_Prop1','Bip01_Prop2'}|{'Bip01_'+side+'_'+bone for side in ['L','R']for bone in ['Clavicle','UpperArm','Forearm','Hand']}
        for n in local:
            if n not in changed:assert max(abs(local[n][a][b]-original[n][a][b])for a in range(4)for b in range(4))<.00001
        target=base[i]['Bip01_R_Hand'].translation.copy();target.y=pose['Bip01_Spine1'].translation.y-base[i]['Bip01_Spine1'].translation.y+target.y+lift;assert(pose['Bip01_R_Hand'].translation-target).length<.00003
        for side in ['L','R']:
            for bone,child in [('Clavicle','UpperArm'),('UpperArm','Forearm'),('Forearm','Hand')]:
                n='Bip01_'+side+'_'+bone;c='Bip01_'+side+'_'+child;actual=pose[c].translation-pose[n].translation;expectedLength=(base[i][c].translation-base[i][n].translation).length;assert abs(actual.length-expectedLength)<.00002
                if side=='L'or lift<.0000001:assert 1-actual.normalized().dot(directions[i][n])<.000002
        prop=pose['Bip01_Prop1'];assert 1-abs(prop.to_quaternion().dot(weapons[i]))<.00001 and 1-abs(pose['Bip01_R_Hand'].to_quaternion().dot(weapons[i]@Matrix(grip['offsets']['Bip01_Prop1']).to_quaternion().inverted()))<.00001
        palm=pose['Bip01_R_Hand']@Vector(grip['palm']);shaft=prop@Vector((0,output['shaftY'][i],0));assert(palm-shaft).length<.00002 and output['shaftRange'][0]-.00001<=output['shaftY'][i]<=output['shaftRange'][1]+.00001
        assert abs(min(p.y for p in skin_part(body,pose,report['ground']['feet']))-report['ground']['floor'])<.00002
        bottom=min((prop@v).y for v in vertices);assert bottom>=report['ground']['floor']-.00002,(profile['item'],i,bottom)
        if i==9:maximumContact=max(maximumContact,abs(bottom-report['ground']['floor']));assert abs(bottom-report['ground']['floor'])<.00002
        offset=pose['Bip01_R_Hand'].inverted()@prop;assert max(abs(offset[a][b]-output['nativeOffsets'][i][a][b])for a in range(4)for b in range(4))<.00002;encoded.append(','.join(str(v)for row in offset for v in row));tested+=1
    leftOffset=','.join(str(v)for row in grip['offsets']['Bip01_Prop2']for v in row);rowsTSV.append('\t'.join([str(mod/output['output']),';'.join(encoded),leftOffset,'154']))
(w/'lau-emote-props.tsv').write_text('\n'.join(rowsTSV),encoding='utf-8')
print('PASS original Lau CMN cuts 007/008, matching source seam',seam,'; 75 original continuation frames / +2.5 seconds; all 22 native spear meshes /',tested,'frame checks; source wrist/weapon rotation, native bone lengths, shaft grips, soles and floor contact; max arm clearance',maxLift,'; max contact error',maximumContact)
