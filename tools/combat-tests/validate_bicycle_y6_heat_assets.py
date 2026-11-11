from pathlib import Path
import sys,json,hashlib,subprocess,math,re,uuid,zipfile

root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report=json.loads((mod/'docs/bicycle-heat-assets.json').read_text())
java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True)
    print(result.stdout);assert result.returncode==0 and'PASS source bicycle'in result.stdout,result.stderr
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'bicycle-heat-prop-contract.tsv')],['BicycleHeatProbe',str(mod/'42/media/AnimSets')]]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose

from read_heat_scene import read_scene
from paired_paths import bridge_scene_cuts

assert sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']
for provenance in report['retargetProvenance']:assert sha(provenance['path'])==provenance['sha256']
scene=read_scene(report['scene']);resources=(Path(report['scene']).parents[1]/'000.par/res.bin').read_bytes()
bindings={str(uuid.UUID(bytes_le=resources[m.start()-28:m.start()-12])):m.group().decode()for m in re.finditer(rb'(?:h23740_000_\d|m_kiryu|c_ea_)[ -~]*',resources)}
for n in report['actorAssignment']['nodes']:assert bindings[n['guid']]==n['resource']and any(row['guid']==n['guid']and row['offset']==n['offset']for row in scene['nodes'])
assert [c['source'].split('h23740_000_')[-1]for c in report['clips']]==['4.gmt','6.gmt']
assert [(n['element']['start'],n['damage']['damage'])for n in scene['nodes']if 'damage'in n and n['role']=='victim']==[(50,2000)]
prefix=(w/'retarget_locomotion.py').read_text().split('poses=[];srcposes=[]')[0];contracts=[];vectors=[];worst=0;samples=0
rotation=Quaternion(report['sceneRotation']);mirror=Matrix.Diagonal((1,1,-1,1))
for c in report['clips']:
    output=mod/c['output'];raw=root/'tools/bicycle-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
    assert sha(output)==c['sha256']and sha(c['source'])==c['sourceSha256']and sha(raw)==c['retargetSha256']
    text,bones,animation,_=read(output);_,original,curves,_=read(raw);count=c['frames'];assert count==121 and c['fps']==30
    for channels in animation.values():
        for keys in channels.values():assert len(keys)==count and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    sys.argv=['validate','--','source',c['source']];context={'FINGER_SOURCE':'Bob_AttackBat01_Hit.x'};exec(compile(prefix,'supplied_bicycle_pose','exec'),context)
    vector=context['a'].bones['vector_c_n'];vs=[context['sample'](vector.location,f,Vector((0,0,0)))for f in range(count)];vectors.append(vs);context['srcposes']=[]
    for frame in range(count):
        pose=source_pose(context,frame);q=rotation@context['sample'](vector.rotation,frame,Quaternion((1,0,0,0)),True);context['srcposes'].append({n:q.to_matrix().to_4x4()@m for n,m in pose.items()})
        actual=locals_at(bones,animation,frame*160);expected=locals_at(original,curves,frame*160);native=world(bones,actual);src=context['srcposes'][-1]
        chest=(mirror@src['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=native['Bip01_Spine1'].to_quaternion()@chest.inverted();modified=set()
        for side in ['L','R']:
            suffix='_'+side.lower()+'_n'
            for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
                name='Bip01_'+side+'_'+bone;nextName='Bip01_'+side+'_'+child;direction=(adapt@(mirror@(src[sc+suffix].translation-src[sb+suffix].translation))).normalized();actualDirection=(native[nextName].translation-native[name].translation).normalized();error=math.acos(max(-1,min(1,direction.dot(actualDirection))));worst=max(worst,error);assert error<.001,(c['animation'],frame,name,error)
                assert (actual[name].translation-expected[name].translation).length<1e-6;modified.add(name)
            modified.add('Bip01_'+side+'_Hand')
        for name in actual:
            if name in modified or name in ['Bip01_Prop1','Bip01_Prop2']or '_Finger'in name:continue
            assert max(abs(actual[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<1e-5,(name,frame);samples+=1
        for name in actual:
            if '_Finger'in name:assert max(abs(actual[name][a][b]-locals_at(original,curves,0)[name][a][b])for a in range(4)for b in range(4))<1e-5
    grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']]
    if c['animation']=='ProjectYakuza_DD_BicycleHeat':
        from bat_prop_motion import prop_offsets
        expected,_=prop_offsets(context,bones,animation,count)
        assert Matrix(report['propMotion']['calibration'])==Matrix.Identity(4)
        for frame,offset in enumerate(expected):
            native=world(bones,locals_at(bones,animation,frame*160));actual=native['Bip01_R_Hand'].inverted()@native['Bip01_Prop1']
            assert max(abs(actual[a][b]-offset[a][b])for a in range(4)for b in range(4))<.0001,(frame,'source held weapon grip')
        offsets[0]=';'.join(','.join(str(v)for row in matrix for v in row)for matrix in expected)
    contracts.append('\t'.join([str(output),*offsets,str(count)]))
(w/'bicycle-heat-prop-contract.tsv').write_text('\n'.join(contracts))
anchor=vectors[0][0];raw=[[[float((rotation@(v-anchor)).z*report['pathScale']),float((rotation@(v-anchor)).x*report['pathScale'])]for v in values]for values in vectors]
paths,cuts=bridge_scene_cuts(raw);assert paths==report['paths']and cuts==report['sceneCuts']and raw==report['rawPaths']
assert all(len(p)==121 and max(math.dist(a,b)for a,b in zip(p,p[1:]))<.2 for p in paths)
assert report['actorAssignment']['weaponBone']=='buki1_r_n'and report['propMotion']['sourceBone']=='buki1_r_n'
assert 'objectSource'not in report and len([n for n in scene['nodes']if n['category']==5])==2
print('PASS source bicycle Y6 CMN/resource roles, 242 original samples,',samples,'unchanged non-arm samples, source arms within',math.degrees(worst),'degrees and original held heavy-weapon motion')
from native_body_geometry import load_body,skin_part
model=json.loads((mod/'docs/bicycle-model-assets.json').read_text());mesh=[Vector(v)*report['propMotion']['modelScale']for v in model['vertices']];_,ab,aa,_=read(mod/report['clips'][0]['output']);_,vb,va,_=read(mod/report['clips'][1]['output']);frame=50;a=world(ab,locals_at(ab,aa,frame*160));v=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');points=[p+shift for p in skin_part(body,v,['Bip01'])];distance=min((a['Bip01_Prop1']@m-p).length for m in mesh for p in points);assert distance<.08,distance
print('PASS native bicycle mesh / skinned victim contact at original heavy-object damage frame50:',distance)
