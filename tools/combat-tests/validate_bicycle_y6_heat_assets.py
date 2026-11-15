from pathlib import Path
import sys,json,hashlib,subprocess,math,re,uuid,zipfile

root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report=json.loads((mod/'docs/bicycle-heat-assets.json').read_text())
java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True)
    print(result.stdout);assert result.returncode==0 and'PASS recovery rotation role 1'in result.stdout,result.stderr
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'bicycle-heat-prop-contract.tsv')],['BicycleHeatProbe',str(mod/'42/media/AnimSets')]]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    preserved=0
    with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.110.0.zip')as archive:
        for name in archive.namelist():
            path=mod/name.removeprefix('ProjectYakuza/')
            bicycleMotion='Bicycle'in path.name and('/media/anims_X/'in name or'/media/AnimSets/player/'in name or path.suffix in ['.png','.x'])
            if not name.endswith('/')and'/media/'in name and path.suffix in ['.x','.xml','.png','.wav','.ogg']and not bicycleMotion and not(path.suffix=='.xml'and'HeatRush'in path.name):
                assert path.read_bytes()==archive.read(name),name;preserved+=1
    print('PASS',preserved,'other published media payloads remain byte-identical, including all non-bicycle models, pixels, sounds and selectors')
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector,Quaternion
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
from mathutils.geometry import closest_point_on_tri
nativeBody=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');bicycleModel=json.loads((mod/'docs/bicycle-model-assets.json').read_text());meshVertices=[Vector(v)*report['propMotion']['modelScale']for v in bicycleModel['vertices']];triangles=[tuple(meshVertices[i]for i in face)for face in bicycleModel['faces']]

from read_heat_scene import read_scene
from paired_paths import bridge_scene_cuts

assert sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']
retired=report['retiredAudio'];assert sha(retired['baseline'])==retired['sha256']and len(retired['files'])==3
with zipfile.ZipFile(retired['baseline'])as archive:
    for row in retired['files']:
        data=archive.read('ProjectYakuza/'+row['path']);assert len(data)==row['bytes']and hashlib.sha256(data).hexdigest()==row['sha256']and not(mod/row['path']).exists()
for provenance in report['retargetProvenance']:assert sha(provenance['path'])==provenance['sha256']
scene=read_scene(report['scene']);resources=(Path(report['scene']).parents[1]/'000.par/res.bin').read_bytes()
bindings={str(uuid.UUID(bytes_le=resources[m.start()-28:m.start()-12])):m.group().decode()for m in re.finditer(rb'(?:h24110_000_\d|m_kiryu|c_ea_)[ -~]*',resources)}
for n in report['actorAssignment']['nodes']:assert bindings[n['guid']]==n['resource']and any(row['guid']==n['guid']and row['offset']==n['offset']for row in scene['nodes'])
assert [c['source'].split('h24110_000_')[-1]for c in report['clips']]==['4.gmt','6.gmt']
assert [(n['element']['start'],n['damage']['damage'])for n in scene['nodes']if 'damage'in n and n['role']=='victim']==[(29,500),(70,1500)]
prefix=(w/'retarget_locomotion.py').read_text().split('poses=[];srcposes=[]')[0];contracts=[];vectors=[];worst=0;samples=0
rotation=Quaternion(report['sceneRotation']);mirror=Matrix.Diagonal((1,1,-1,1))
recovery=report['recoveryStageRotation'];assert recovery['frame']==97 and recovery['actorEndFrame']==150 and recovery['referenceFrames']==[96,97]
_,referenceBones,referenceAnimation,_=read(root/'tools/bicycle-heat-build/ProjectYakuza/42/media/anims_X/Bob/ProjectYakuza_DD_BicycleHeatVictim.x');referenceBefore=world(referenceBones,locals_at(referenceBones,referenceAnimation,96*160))['Bip01'].to_quaternion();referenceAfter=world(referenceBones,locals_at(referenceBones,referenceAnimation,97*160))['Bip01'].to_quaternion();referenceDelta=(referenceAfter@referenceBefore.inverted()).to_matrix();stageYaw=math.atan2(referenceDelta[0][2],referenceDelta[2][2]);assert abs(stageYaw-recovery['radians'])<.000001 and 32<recovery['degrees']<35
for role,c in enumerate(report['clips']):
    output=mod/c['output'];raw=root/'tools/bicycle-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
    assert sha(output)==c['sha256']and sha(c['source'])==c['sourceSha256']and sha(raw)==c['retargetSha256']
    text,bones,animation,_=read(output);_,original,curves,_=read(raw);count=c['frames'];assert count==151 and c['fps']==30
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
            if name=='Bip01'and frame>=recovery['frame']:
                phase=(frame-recovery['frame'])/(count-1-recovery['frame']);weight=1-phase*phase*(3-2*phase)if role==0 else 1;sourceWorld=world(original,expected);sourceRoot=sourceWorld[name];corrected=Matrix.Rotation(-stageYaw*weight,4,'Y')@sourceRoot;corrected.translation=sourceRoot.translation;parent=original[name]['parent'];expected[name]=sourceWorld[parent].inverted()@corrected if parent else corrected
            assert max(abs(actual[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<1e-5,(name,frame);samples+=1
        for name in actual:
            if '_Finger'in name:assert max(abs(actual[name][a][b]-locals_at(original,curves,0)[name][a][b])for a in range(4)for b in range(4))<1e-5
    grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']]
    if c['animation']=='ProjectYakuza_DD_BicycleHeat':
        front=context['bind']['Bip01_Spine1'].to_quaternion().inverted()@Vector((0,0,1));fitted=[];gaps={'R':0,'L':0}
        for frame in range(count):
            native=world(bones,locals_at(bones,animation,frame*160));actual=native['Bip01_R_Hand'].inverted()@native['Bip01_Prop1']
            fitted.append(actual);hands={}
            for side in ['R','L']:
                points=skin_part(nativeBody,native,['Bip01_'+side+'_Hand']);palm=sum(points,Vector())/len(points);point=native['Bip01_Prop1'].inverted()@palm;gap=min((point-closest_point_on_tri(point,*tri)).length for tri in triangles);gaps[side]=max(gaps[side],gap);assert gap<.00001,(frame,side,gap);hands[side]=palm;gripPoint=Vector(report['propMotion']['gripPoints'][frame]['right'if side=='R'else'left'])*report['propMotion']['modelScale'];assert (point-gripPoint).length<.00001,(frame,side,'authored surface grip')
            axis=(hands['L']-hands['R']).normalized();normal=native['Bip01_Spine1'].to_quaternion()@front;normal-=axis*normal.dot(axis)
            plane=native['Bip01_Prop1'].to_quaternion()@Vector((1,0,0));plane-=axis*plane.dot(axis)
            if normal.length>.05 and plane.length>.05:assert plane.normalized().dot(normal.normalized())>.9999,(frame,'bicycle plane')
        offsets[0]=';'.join(','.join(str(v)for row in matrix for v in row)for matrix in fitted);print('PASS actual bicycle heat palm/surface gaps',gaps)
    contracts.append('\t'.join([str(output),*offsets,str(count)]))
(w/'bicycle-heat-prop-contract.tsv').write_text('\n'.join(contracts))
anchor=vectors[0][0];raw=[[[float((rotation@(v-anchor)).z*report['pathScale']),float((rotation@(v-anchor)).x*report['pathScale'])]for v in values]for values in vectors]
paths,cuts=bridge_scene_cuts(raw)
assert [(r['actor'],r['frame'],r['blendFrames'])for r in report['individualSceneCuts']]==[(0,50,6)]
for cut in report['individualSceneCuts']:
    actor,frame=cut['actor'],cut['frame'];before=paths[actor][frame-1];after=paths[actor][frame];shift=[after[axis]-before[axis]for axis in range(2)];assert shift==cut['translation']
    for age in range(cut['blendFrames']):
        t=age/cut['blendFrames'];fade=1-t*t*(3-2*t);paths[actor][frame+age]=[paths[actor][frame+age][axis]-shift[axis]*fade for axis in range(2)]
assert paths==report['paths']and cuts==report['sceneCuts']and raw==report['rawPaths']
assert all(len(p)==151 and max(math.dist(a,b)for a,b in zip(p,p[1:]))<.23 for p in paths)
assert report['actorAssignment']['weaponBone']=='buki1_r_n'and report['propMotion']['sourceBone']=='buki1_r_n'
assert 'objectSource'not in report and len([n for n in scene['nodes']if n['category']==5])==2
print('PASS source bicycle Y6 CMN/resource roles, 302 original samples,',samples,'unchanged non-arm samples, source arms within',math.degrees(worst),'degrees and original held heavy-weapon motion')
from native_body_geometry import load_body,skin_part
model=json.loads((mod/'docs/bicycle-model-assets.json').read_text());mesh=[Vector(v)*report['propMotion']['modelScale']for v in model['vertices']];_,ab,aa,_=read(mod/report['clips'][0]['output']);_,vb,va,_=read(mod/report['clips'][1]['output']);frame=70;a=world(ab,locals_at(ab,aa,frame*160));v=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');points=[p+shift for p in skin_part(body,v,['Bip01'])];distance=min((a['Bip01_Prop1']@m-p).length for m in mesh for p in points);assert distance<.08,distance
feet=['Bip01_L_Foot','Bip01_R_Foot'];initial=world(ab,locals_at(ab,aa,0));airborne=world(ab,locals_at(ab,aa,67*160));rise=min(p.y for p in skin_part(body,airborne,feet))-min(p.y for p in skin_part(body,initial,feet));assert rise>.4,rise
assert sha(mod/report['bicycleModel']['path'])==report['bicycleModel']['sha256']==model['sha256']
print('PASS retained native airborne foot rise:',rise,'and frame-50 camera-stage cut bridged without flattening source flight')
print('PASS native bicycle mesh / skinned victim contact at original heavy-object damage frame70:',distance)
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.109.0.zip')as archive:
    for role,clip in enumerate(report['clips']):
        previous=w/('bicycle-recovery-before-'+str(role)+'.x');previous.write_bytes(archive.read('ProjectYakuza/'+clip['output']));_,pb,pa,_=read(previous);_,nb,na,_=read(mod/clip['output']);turns=[];yawTurns=[]
        for name in pa:
            if name=='Bip01':assert pa[name][0][:97]==na[name][0][:97]and pa[name][1]==na[name][1]and pa[name][2]==na[name][2]
            elif not(role==0 and name=='Bip01_Prop1'):assert pa[name]==na[name],(role,name,'original channel values changed')
        if role==0:assert pa['Bip01'][0][-1]==na['Bip01'][0][-1]
        assert all(sum(x*y for x,y in zip(a[1],b[1]))>0 for a,b in zip(na['Bip01'][0],na['Bip01'][0][1:])),(role,'root quaternion hemisphere continuity')
        for frame in range(151):
            old=locals_at(pb,pa,frame*160);new=locals_at(nb,na,frame*160)
            for name in old:
                if name=='Bip01'and frame>=97:assert (old[name].translation-new[name].translation).length<.000001
                elif not(role==0 and name=='Bip01_Prop1'):assert max(abs(old[name][a][b]-new[name][a][b])for a in range(4)for b in range(4))<.00001,(role,frame,name)
            if frame>=97:
                prior=world(nb,locals_at(nb,na,(frame-1)*160))['Bip01'].to_quaternion().normalized();current=world(nb,new)['Bip01'].to_quaternion().normalized();turns.append(math.degrees(2*math.acos(min(1,abs(prior.dot(current))))));delta=(current@prior.inverted()).to_matrix();yawTurns.append(abs(math.degrees(math.atan2(delta[0][2],delta[2][2]))))
        assert yawTurns[0]<(2 if role==0 else .01)and max(turns)<(8 if role==0 else .35),(role,yawTurns[0],max(turns))
        if role==0:assert max(abs(old['Bip01'][a][b]-new['Bip01'][a][b])for a in range(4)for b in range(4))<.000001
        print('PASS recovery rotation role',role,'frame-97 yaw',yawTurns[0],'degrees, maximum recovery turn',max(turns),'degrees; original child-local channels and pre-cut samples retained')

with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.110.0.zip')as archive:
    for role,clip in enumerate(report['clips']):
        previous=w/('bicycle-grip-before-'+str(role)+'.x');previous.write_bytes(archive.read('ProjectYakuza/'+clip['output']));_,_,old,_=read(previous);_,_,current,_=read(mod/clip['output'])
        for name in old:
            if role==0 and name=='Bip01_Prop1':continue
            assert old[name]==current[name],(role,name,'0.110 body or recovery regression')
print('PASS exact 0.110 body, recovery, victim and timing channels; only attacker bicycle attachment changed')
