from pathlib import Path
import sys,json,hashlib,subprocess,math,struct,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/bicycle-k2-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    from y5_source_assets import entry
    for row in report['archiveEntries']:
        data,actual=entry(row['archive'],row['name']);assert actual=={k:v for k,v in row.items()if k!='path'}and data==Path(row['path']).read_bytes()
    command=['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'];result=subprocess.run(command,cwd=root,capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and'PASS seven original Kiwami 2'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';prefix=[java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*']
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'bicycle-k2-props.tsv')],['BicycleK2Probe',str(mod/'42/media/AnimSets/player')]]:subprocess.run(prefix+args,cwd=w,check=True)
    print('PASS fresh Kiwami 2 archive/BEP provenance, native importer and bicycle-only selectors');raise SystemExit(0)
sys.path.insert(0,str(w))
from mathutils import Matrix,Vector
from mathutils.geometry import closest_point_on_tri
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
for row in report['provenance']:assert sha(row['path'])==row['sha256']
assert sha(report['rig'])==report['rigSha256'];model=json.loads((mod/'docs/bicycle-model-assets.json').read_text());assert model['sha256']==report['modelSha256']==sha(mod/model['output']);vertices=[Vector(v)*report['modelScale']for v in model['vertices']];triangles=[tuple(vertices[i]for i in face)for face in model['faces']];body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');mirror=Matrix.Diagonal((1,1,-1,1));worst=0;gaps={'R':0,'L':0};contracts=[];total=0
prefix=(w/'retarget_locomotion.py').read_text().split('poses=[];srcposes=[]')[0].replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(report['rig']))
for clip in report['clips']:
    assert sha(clip['source'])==clip['sourceSha256']and sha(clip['retarget'])==clip['retargetSha256']and sha(mod/clip['output'])==clip['sha256'];_,bones,animation,_=read(mod/clip['output']);_,rb,ra,_=read(clip['nativeBase']or clip['retarget']);baseEnd=max(t for c in ra.values()for keys in c.values()for t,_ in keys);sys.argv=['source','--','verify',clip['source']];context={};exec(compile(prefix,'original_kiwami2_source_context','exec'),context);assert context['a'].frame_rate==30 and context['a'].end_frame+1==clip['frames'];offsets={'Bip01_Prop1':[],'Bip01_Prop2':[]}
    for channels in animation.values():
        for keys in channels.values():assert len(keys)==clip['frames']and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for frame in range(clip['frames']):
        local=locals_at(bones,animation,frame*160);pose=world(bones,local);original=locals_at(rb,ra,frame*160%baseEnd if clip['nativeBase']else frame*160);source=source_pose(context,frame);chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();modified=set()
        for side in ['L','R']:
            for b,c,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
                name='Bip01_'+side+'_'+b;child='Bip01_'+side+'_'+c;suffix='_'+side.lower()+'_n';expected=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();actual=(pose[child].translation-pose[name].translation).normalized();error=math.acos(max(-1,min(1,actual.dot(expected))));worst=max(worst,error);assert error<.001;(modified.add(name))
                assert (local[name].translation-original[name].translation).length<.000001
            modified.add('Bip01_'+side+'_Hand');points=skin_part(body,pose,['Bip01_'+side+'_Hand']);palm=sum(points,Vector())/len(points);modelPalm=pose['Bip01_Prop1'].inverted()@palm;gap=min((modelPalm-closest_point_on_tri(modelPalm,*tri)).length for tri in triangles);gaps[side]=max(gaps[side],gap);assert gap<.00001,(clip['label'],frame,side,gap)
        for name in local:
            if name in modified or '_Finger'in name or name in ['Bip01_Prop1','Bip01_Prop2']:continue
            assert max(abs(local[name][a][b]-original[name][a][b])for a in range(4)for b in range(4))<.00001,(clip['label'],frame,name)
        for hand,prop in [('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]:offsets[prop].append(pose[hand].inverted()@pose[prop])
        total+=1
    if 'bep'in clip:
        assert sha(clip['bep'])==clip['bepSha256'];data=Path(clip['bep']).read_bytes();pos=16;contacts=[]
        while pos+80<=len(data):
            section,kind,size=struct.unpack_from('<HHI',data,pos+64)
            if section==12 and kind==68:contacts.append(round(struct.unpack_from('<f',data,pos+84)[0]))
            pos+=80+size
        assert contacts==clip['sourceContactFrames']and clip['contactFrame']==contacts[0];node=E.parse(mod/'42/media/AnimSets/player/melee'/Path(clip['output']).with_suffix('.xml').name).getroot();events=[e for e in node.findall('m_Events')if e.findtext('m_EventName')=='AttackCollisionCheck'];assert len(events)==1 and abs(float(events[0].findtext('m_TimePc'))*(clip['frames']-1)-contacts[0])<.000001
    contract=[';'.join(','.join(str(v)for row in matrix for v in row)for matrix in offsets[name])for name in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(mod/clip['output']),*contract,str(clip['frames'])]))
(w/'bicycle-k2-props.tsv').write_text('\n'.join(contracts));assert len(report['clips'])==7;print('PASS seven original Kiwami 2 motions,',total,'source samples, native source-arm error',math.degrees(worst),'degrees and palm/surface gaps',gaps)
