from pathlib import Path
import sys,json,hashlib,math,subprocess
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/('tools/katana-scene-candidate-093/ProjectYakuza'if '--stage'in sys.argv else'combat/ProjectYakuza')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender',*(['--stage']if '--stage'in sys.argv else[])],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
    if r.returncode or 'PASS katana source'not in r.stdout:raise SystemExit(r.stderr or 'source checks failed')
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    report=json.loads((mod/'docs/katana-heat-assets.json').read_text(encoding='utf-8'))
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'katana-heat-prop-contract.tsv')],['KatanaHeatProbe',str(root/'combat/ProjectYakuza/42/media/AnimSets')]]:subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','-cp',cp,*args],cwd=w,check=True)
    import zipfile
    with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.93.1.zip')as archive:
        old=w/'katana-old-grip.x';old.write_bytes(archive.read('ProjectYakuza/'+report['clips'][0]['output']))
    row=(w/'katana-heat-prop-contract.tsv').read_text().splitlines()[0].split('\t');row[0]=str(old)
    samples=row[1].split(';');static=','.join(str(v)for r in report['nativeGrip']['nativeOffsets']['Bip01_Prop1']for v in r);samples[:44]=[static]*44;row[1]=';'.join(samples)
    negative=w/'katana-old-grip-contract.tsv';negative.write_text('\t'.join(row))
    result=subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','-cp',cp,'PropAttachmentProbe',str(negative)],cwd=w,capture_output=True,text=True)
    assert result.returncode!=0 and'prop detached'in result.stderr and'frame=44'in result.stderr,'previous rigid grip must fail at the source release frame'
    print('PASS previous rigid katana grip fails the native animated-prop regression')
    raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at,world
report=json.loads((mod/'docs/katana-heat-assets.json').read_text(encoding='utf-8'))
assert len(report['clips'])==2 and sha(report['archive'])==report['archiveSha256']and sha(report['scene'])==report['sceneSha256']
assert report['contactFrames']==[24,44,64]
contracts=[];samples=0;contexts={};worst=0
from weapon_hold_geometry import source_pose
from mathutils import Matrix,Vector
import zipfile
from katana_prop_motion import prop_offsets
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.93.1.zip')as archive:
    baseline={record['animation']:archive.read('ProjectYakuza/'+record['output']).decode()for record in report['clips']}
mirror=Matrix.Diagonal((1,1,-1,1));prefix=(w/'retarget_locomotion.py').read_text().split('poses=[];srcposes=[]')[0]

for record in report['clips']:
    output=mod/record['output'];raw=root/'tools/katana-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
    assert sha(output)==record['sha256']and sha(record['source'])==record['sourceSha256']and sha(raw)==record['retargetSha256']
    _,bones,anim,_=read(output);_,original,curves,_=read(raw);frames=record['frames'];assert frames==141
    for bone,channels in anim.items():
        for kind,keys in channels.items():assert len(keys)==frames and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    saved=sys.argv;sys.argv=['validate','--','source',record['source']];context={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(prefix,'source_pose_contract','exec'),context);sys.argv=saved
    for i in range(frames):
        actual=locals_at(bones,anim,i*160);expected=locals_at(original,curves,i*160)
        originalPose=source_pose(context,i);aw=world(bones,actual);rw=world(original,expected);bind=context['bind'];chest=(mirror@originalPose['mune_c_n']@mirror).to_quaternion()@bind['Bip01_Spine1'].to_quaternion();adapt=rw['Bip01_Spine1'].to_quaternion()@chest.inverted();modified=set()
        for side in ['L','R']:
            suffix='_'+side.lower()+'_n'
            for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
                n='Bip01_'+side+'_'+bone;ch='Bip01_'+side+'_'+child;direction=(adapt@(mirror@(originalPose[sc+suffix].translation-originalPose[sb+suffix].translation))).normalized();actualDirection=(aw[ch].translation-aw[n].translation).normalized();error=math.acos(max(-1,min(1,direction.dot(actualDirection))));worst=max(worst,error);assert error<.001,(record['animation'],i,n,error);modified.add(n)
                assert(actual[n].translation-expected[n].translation).length<1e-6
            hand='Bip01_'+side+'_Hand';fore='Bip01_'+side+'_Forearm';modified.add(hand)
            sourceFore=(mirror@originalPose['ude2'+suffix]@mirror).to_quaternion();sourceHand=(mirror@originalPose['ude3'+suffix]@mirror).to_quaternion();neutral=bind[fore].to_quaternion().inverted()@bind[hand].to_quaternion();wrist=adapt@(sourceHand@sourceFore.inverted())@adapt.inverted()@aw[fore].to_quaternion()@neutral
            assert 1-abs(wrist.dot(aw[hand].to_quaternion()))<.00002
        fingerPose=locals_at(original,curves,0)
        for bone in actual:
            if '_Finger'in bone:assert max(abs(actual[bone][a][b]-fingerPose[bone][a][b])for a in range(4)for b in range(4))<.00001

        for bone in actual:
            if bone in modified or '_Finger'in bone:continue
            if bone in ['Bip01_Prop1','Bip01_Prop2']:continue
            assert max(abs(actual[bone][a][b]-expected[bone][a][b])for a in range(4)for b in range(4))<.00001,(output,bone,i);samples+=1
    grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']]
    if record['animation']=='ProjectYakuza_DD_KatanaHeat':
        from yk.gmt_lib import read_gmt
        metadata=report['propMotion'];assert sha(metadata['source'])==metadata['sourceSha256']and sha(metadata['sourceRig'])==metadata['sourceRigSha256']and sha(metadata['nativeMesh'])==metadata['nativeMeshSha256'];prop=read_gmt(metadata['source']).animation
        assert prop.end_frame==140 and prop.frame_rate==30 and metadata['releaseFrame']==44 and metadata['catchFrame']==54
        for bone in prop.bones.values():
            for curve in bone.curves:
                if int(curve.type)in(0,1):curve.fill_channels()
        expected,sourceOffsets=prop_offsets(context,prop,bones,anim,Matrix(grip['authoredOffsets']['Bip01_Prop1']),frames)
        offsets[0]=';'.join(','.join(str(v)for row in m for v in row)for m in expected)
        for frame,matrix in enumerate(expected):
            native=world(bones,locals_at(bones,anim,frame*160));relative=native['Bip01_R_Hand'].inverted()@native['Bip01_Prop1']
            assert max(abs(relative[a][b]-matrix[a][b])for a in range(4)for b in range(4))<1e-5,frame
        assert(sourceOffsets[48].translation-sourceOffsets[0].translation).length>.5
        assert(sourceOffsets[54].translation-sourceOffsets[0].translation).length<.001
        assert math.degrees(sourceOffsets[54].to_quaternion().rotation_difference(sourceOffsets[0].to_quaternion()).angle)>170
        def without_prop(text):
            from locomotion_math import read,brace
            import re
            match=re.search(r'Animation\s*\{\s*\{\s*Bip01_Prop1\s*\}',text);return text[:match.start()]+text[brace(text,text.index('{',match.start())):]
        assert without_prop(output.read_bytes().decode())==without_prop(baseline[record['animation']]),'body, fingers and left prop must retain previous bytes'
        native=world(bones,locals_at(bones,anim,64*160));target=Vector(report['effectPoints'][2]['point']);ap=report['paths'][0][64];vp=report['paths'][1][64];target.x+=(vp[1]-ap[1])/1.5;target.z-=(vp[0]-ap[0])/1.5
        sword=native['Bip01_Prop1'];toward=(target-sword.translation).normalized();sharp=sword.to_quaternion()@Vector((0,1,0));assert sharp.dot(toward)>.9,'sharp end must face the final thrust victim'
        old=native['Bip01_R_Hand']@Matrix(grip['authoredOffsets']['Bip01_Prop1']);assert(old.to_quaternion()@Vector((0,1,0))).dot((target-old.translation).normalized())<0,'old rigid grip must point the sharp end away'
        import re
        mesh=Path(metadata['nativeMesh']).read_text();start=re.search(r'\bMesh\s+Katana\s*\{\s*(\d+)\s*;',mesh);points=[list(map(float,p))for p in re.findall(r'([-+\d.eE]+);\s*([-+\d.eE]+);\s*([-+\d.eE]+);',mesh[start.end():])[:int(start[1])]]
        extents=[max(p[i]for p in points)-min(p[i]for p in points)for i in range(3)];assert extents[1]>8*max(extents[0],extents[2])and max(p[1]for p in points)>.5 and metadata['nativeSharpAxis']==[0,1,0]
        print('PASS original release/catch and reverse grip; native sharp-axis final-thrust alignment',sharp.dot(toward))
    else:assert output.read_bytes().decode()==baseline[record['animation']],'victim clip must remain byte-identical'
    contracts.append('\t'.join([str(output),*offsets,str(frames)]))
(w/'katana-heat-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
assert all(len(path)==141 and all(math.isfinite(v)for row in path for v in row)for path in report['paths'])
from types import ModuleType
package=ModuleType('yk');package.__path__=['C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/addons/yakuza_gmt_blender'];sys.modules['yk']=package
from yk.gmt_lib import read_gmt
from mathutils import Vector,Quaternion
animations=[read_gmt(c['source']).animation for c in report['clips']]
for a in animations:
    for curve in a.bones['vector_c_n'].curves:
        if int(curve.type)==1:curve.fill_channels()
anchor=Vector(animations[0].bones['vector_c_n'].location.keyframes[0].value);rotation=Quaternion(report['sceneRotation'])
for a,path in zip(animations,report['rawPaths']):
    keys=a.bones['vector_c_n'].location.keyframes
    def sample(f):
        if f<=keys[0].frame:return Vector(keys[0].value)
        for left,right in zip(keys,keys[1:]):
            if f<=right.frame:return Vector(left.value).lerp(Vector(right.value),(f-left.frame)/(right.frame-left.frame))
        return Vector(keys[-1].value)
    for i,row in enumerate(path):
        v=rotation@(sample(i)-anchor);assert abs(row[0]-v.z*report['pathScale'])<1e-8 and abs(row[1]-v.x*report['pathScale'])<1e-8
from paired_paths import bridge_scene_cuts
expected,cuts=bridge_scene_cuts(report['rawPaths']);assert cuts==report['sceneCuts']
correction=report['nativeSkeletonCorrection']
for f in range(25,64):
 t=(f-24)/20 if f<=44 else (64-f)/20;weight=t*t*(3-2*t)
 for axis in range(2):expected[1][f][axis]+=correction['delta'][axis]*weight
assert expected==report['paths']
_,ab,aa,_=read(mod/report['clips'][0]['output']);hand=world(ab,locals_at(ab,aa,44*160))['Bip01_R_Hand'].translation;face=report['effectPoints'][1]['point'];ap=report['paths'][0][44];vp=report['paths'][1][44]
assert math.dist([ap[0]-hand.z*1.5,ap[1]+hand.x*1.5],[vp[0]-face[2]*1.5,vp[1]+face[0]*1.5])<1e-6

assert max(__import__('math').dist(a,b)for path in report['paths']for a,b in zip(path,path[1:]))<.06
_,bones,curves,_=read(mod/report['clips'][1]['output']);local=locals_at(bones,curves,0);world={}
for bone,frame in bones.items():world[bone]=world[frame['parent']]@local[bone]if frame['parent']else local[bone]
assert world['Bip01'].translation.y>.4,'victim must start at native standing pelvis height'
print('PASS katana source archive/GMT/scene hashes, 141 retained frames,',samples,'unchanged non-arm body samples, original source arm directions within',math.degrees(worst),'degrees, native punch alignment and continuous paired paths with native standing victim height')
