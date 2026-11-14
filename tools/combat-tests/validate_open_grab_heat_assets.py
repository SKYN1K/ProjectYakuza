from pathlib import Path
import sys,json,hashlib,subprocess,struct,uuid,math,wave,zipfile,xml.etree.ElementTree as E

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/open-grab-heat-assets.json').read_text(encoding='utf-8'));selection=report['actorAssignment'];sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    from y5_source_assets import entry,namespace
    def nested(data,name):
        dirs,_,count,entries=struct.unpack_from('>4I',data,16);names=[data[32+dirs*64+i*64:32+dirs*64+(i+1)*64].split(b'\0')[0].decode('ascii')for i in range(count)];flags,plain,size,offset=struct.unpack_from('>4I',data,entries+names.index(name)*32);packed=data[offset:offset+size];content=namespace['sllz'](packed)if flags else packed;assert len(content)==plain;return content
    rig,_=entry('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/chara.par','c_man_bone.gmd');assert rig==Path('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd').read_bytes()
    data,_=entry(selection['archive'],'000.par');scene,_=entry(selection['archive'],'cmn.par');assert nested(scene,'cmn.bin')==Path(selection['scene']).read_bytes()and nested(data,'res.bin')==Path(selection['resources']).read_bytes()
    for record in selection['selection']:assert nested(data,record['resource']+'.gmt')==Path(record['path']).read_bytes()
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True);print(result.stdout,flush=True);assert result.returncode==0 and'PASS original open grab'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';prefix=[java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*']
    for args in [['AnimationProbe',*[str(mod/r['output'])for r in report['clips']]],['PropAttachmentProbe',str(w/'open-grab-props.tsv')],['OpenGrabHeatProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x',*[str(mod/r['output'])for r in report['clips']],str(mod/'42/media/AnimSets')],['PairedPlaybackClockProbe','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x',str(mod/report['clips'][1]['output']),str(mod/'42/media/AnimSets/zombie/idle/ProjectYakuza_DD_OpenGrabHeatVictim.xml'),str(mod/'42/media/AnimSets')]]:subprocess.run(prefix+args,cwd=w,check=True)
    audio=json.loads((mod/'docs/open-grab-heat-scene.json').read_text(encoding='utf-8'));assert len(audio['sounds'])==9;folder=root/'tools/open-grab-audio-verify';folder.mkdir(exist_ok=True)
    for sound in audio['sounds']:
        bank,record=entry(sound['archive'],sound['entry']);assert hashlib.sha256(bank).hexdigest()==sound['entrySha256'];source=folder/sound['entry'];source.write_bytes(bank);decoded=folder/(str(sound['streamIndex'])+'.wav');subprocess.run([str(root/'tools/vgmstream/vgmstream-cli.exe'),'-s',str(sound['streamIndex']),'-i','-o',str(decoded),str(source)],check=True,capture_output=True);assert decoded.read_bytes()==(mod/sound['output']).read_bytes()and sha(mod/sound['output'])==sound['sha256']
        with wave.open(str(decoded))as stream:assert(stream.getframerate(),stream.getnchannels(),stream.getnframes())==(sound['sampleRate'],sound['channels'],sound['samples'])
    for row in audio['provenance']:assert sha(row['path'])==row['sha256']
    assert [d['frame']for d in audio['scenes'][0]['damage']]==[117,167]and abs(sum(c['damageMultiplier']for c in audio['scenes'][0]['definitions'][0]['contacts'])-5)<.000001
    presentation=json.loads((mod/'docs/open-grab-heat-presentation.json').read_text(encoding='utf-8'));assert sha(mod/presentation['output'])==presentation['sha256']and [round(c['atMs']*.03)for c in presentation['contacts']]==[117,167]
    for row in presentation['provenance']:assert sha(row['path'])==row['sha256']
    clockNodes=0
    with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.108.0.zip')as archive:
        checked=0
        for name in archive.namelist():
            path=mod/name.removeprefix('ProjectYakuza/')
            if not name.endswith('/')and path.suffix in ['.x','.xml','.png','.wav','.ogg']and '/media/'in name:
                if path.name in ['ProjectYakuza_DD_BicycleHeat.x','ProjectYakuza_DD_BicycleHeatVictim.x']or path.name.startswith('HeatScene_bicycle_'):continue
                current=path.read_bytes();prior=archive.read(name)
                if path.suffix=='.xml'and'OpenGrabHeat'in path.name:
                    tree=E.fromstring(current);clock=tree.find('m_TrackTimeToVariable');expected='ProjectYakuzaHeatVictimPhase'if'Victim'in path.name else'ProjectYakuzaHeatActorPhase';assert clock is not None and clock.text==expected;tree.remove(clock);assert E.canonicalize(E.tostring(tree,encoding='unicode'),strip_text=True)==E.canonicalize(prior,strip_text=True),name;clockNodes+=1
                else:assert current==prior,name
                checked+=1
    assert clockNodes==6
    print('PASS original scene contacts, nine freshly decoded supplied audio streams, native presentation anchors, six isolated paired-clock selectors and',checked,'existing media payloads unchanged')
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part
from weapon_hold_geometry import source_pose
from paired_paths import bridge_scene_cuts
from read_heat_scene import read_scene
from extract_majima_bat_emote import resource
for row in report['provenance']:assert sha(row['path'])==row['sha256']
assert sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']and selection['frames']==225 and selection['contactFrames']==[117,167]
scene=read_scene(report['scene']);assert len([n for n in scene['nodes']if n['category']==5])==2 and [n['element']['start']for n in scene['nodes']if 'damage'in n]==[117,167]
contracts=[];vectors=[];preserved=0;worst=0;poses=[];floor=report['ground']['floor'];body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x')
for record,sourceRecord in zip(report['clips'],selection['selection']):
    assert sha(mod/record['output'])==record['sha256']and sha(record['source'])==record['sourceSha256']and resource(selection['resources'],uuid.UUID(sourceRecord['motion']['guid']).bytes_le.hex())==sourceRecord['resource']
    converter=(w/'retarget_locomotion.py').read_text(encoding='utf-8').split('poses=[];srcposes=[]')[0];saved=sys.argv;sys.argv=['convert','--',record['animation'],record['source']];context={};exec(compile(converter,'source_context_only','exec'),context);sys.argv=saved;assert context['a'].frame_rate==30 and context['a'].end_frame==224;vector=context['a'].bones['vector_c_n'];vectors.append([context['sample'](vector.location,f,Vector((0,0,0)))for f in range(225)])
    raw=root/'tools/open-grab-heat-build/ProjectYakuza/42/media/anims_X/Bob'/Path(record['output']).name;assert sha(raw)==record['retargetSha256'];_,bones,animation,_=read(mod/record['output']);_,rb,ra,_=read(raw);values=[]
    for channels in animation.values():
        for keys in channels.values():assert len(keys)==225 and all(t==i*160 and all(math.isfinite(v)for v in val)for i,(t,val)in enumerate(keys))
    for i in range(225):
        local=locals_at(bones,animation,i*160);original=locals_at(rb,ra,i*160);pose=world(bones,local);expected=world(rb,original);changed={'Bip01','Bip01_Prop1','Bip01_Prop2'}|{'Bip01_'+s+'_'+n for s in ['L','R']for n in ['Clavicle','UpperArm','Forearm','Hand']}
        for n in local:
            if n not in changed:assert max(abs(local[n][a][b]-original[n][a][b])for a in range(4)for b in range(4))<.00001;preserved+=1
        delta=pose['Bip01'].translation-expected['Bip01'].translation;assert abs(delta.x)<.00002 and abs(delta.z)<.00002 and abs(delta.y-report['ground']['sharedRootCorrection'][i]-record['nativeFloorLift'][i])<.00002
        rawPose=source_pose(context,i);q=Quaternion(report['sceneRotation'])@context['sample'](vector.rotation,i,Quaternion((1,0,0,0)),True);source={n:q.to_matrix().to_4x4()@m for n,m in rawPose.items()};mirror=Matrix.Diagonal((1,1,-1,1));chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted()
        for side in ['L','R']:
            suffix='_'+side.lower()+'_n'
            for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
                desired=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();actual=(pose['Bip01_'+side+'_'+child].translation-pose['Bip01_'+side+'_'+bone].translation).normalized();error=math.acos(max(-1,min(1,actual.dot(desired))));worst=max(worst,error);assert error<.001
        if len(poses)==0:assert abs(min(v.y for v in skin_part(body,pose,report['ground']['feet']))-floor)<.00002
        else:assert min(v.y for v in skin_part(body,pose,['Bip01']))>=floor-.00002
        values.append(pose)
    poses.append(values);offsets=[','.join(str(v)for row in report['nativeGrip']['nativeOffsets'][n]for v in row)for n in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(mod/record['output']),*offsets,'225']))
anchor=vectors[0][0];rotation=Quaternion(report['sceneRotation']);rawPaths=[[[float((rotation@(v-anchor)).z*report['pathScale']),float((rotation@(v-anchor)).x*report['pathScale'])]for v in values]for values in vectors];paths,cuts=bridge_scene_cuts(rawPaths);assert paths==report['paths']and cuts==report['sceneCuts']
(w/'open-grab-props.tsv').write_text('\n'.join(contracts),encoding='utf-8');print('PASS original open grab pair / 225 samples each,',preserved,'preserved body samples, source arm error',math.degrees(worst),'degrees; grounded actor soles, flat-ground victim trajectory, native floor clearance and original paired paths')
