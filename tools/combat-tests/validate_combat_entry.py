from pathlib import Path
import sys,json,subprocess,hashlib,math,zipfile

root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/combat-entry-assets.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],capture_output=True,text=True);print(result.stdout);assert result.returncode==0 and 'PASS LJ'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
    for args in [['AnimationProbe',str(mod/report['output'])],['PropAttachmentProbe',str(w/'lj-entry-prop.tsv')],['CombatEntryProbe',str(mod/report['selector']),str(mod/'42/media')]]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp',str(w)+';F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd='F:/SteamLibrary/steamapps/common/ProjectZomboid'if args[0]=='CombatEntryProbe'else w,check=True)
    raise SystemExit(0)

sys.path.insert(0,str(w))
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from native_body_geometry import load_body,skin_part
from build_lj_entry import context_for
for row in report['retargetProvenance']:assert sha(row['path'])==row['sha256']
for key in ['source','retarget','selector']:assert sha(mod/report[key]if key=='selector'else report[key])==report[key+'Sha256']
assert sha(mod/report['output'])==report['sha256']and report['frames']==151 and report['fps']==60 and report['duration']==2.5
_,bones,animation,_=read(mod/report['output']);_,rawBones,raw,_=read(report['retarget']);context=context_for(True);mirror=Matrix.Diagonal((1,1,-1,1));body=load_body(report['ground']['body']);worst=0;samples=0;rootMinimum=100
for channels in animation.values():
    for keys in channels.values():assert len(keys)==151 and all(t==i*80 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
for frame in range(151):
    local=locals_at(bones,animation,frame*80);expected=locals_at(rawBones,raw,frame*80);pose=world(bones,local);rawPose=world(rawBones,expected);source=source_pose(context,frame);chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();modified=set()
    for side in ['L','R']:
        for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
            name='Bip01_'+side+'_'+bone;child='Bip01_'+side+'_'+child;suffix='_'+side.lower()+'_n';direction=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();error=math.acos(max(-1,min(1,direction.dot((pose[child].translation-pose[name].translation).normalized()))));assert error<.001;worst=max(worst,error);modified.add(name)
        modified.add('Bip01_'+side+'_Hand')
    for name in local:
        if name in modified or name in ['Bip01','Bip01_Prop1','Bip01_Prop2']:continue
        assert max(abs(local[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<1e-5;samples+=1
    assert 1-abs(local['Bip01'].to_quaternion().dot(expected['Bip01'].to_quaternion()))<1e-5
    offset=pose['Bip01'].translation-rawPose['Bip01'].translation;assert abs(offset.x)<.000002 and abs(offset.z)<.000002 and abs(offset.y-report['ground']['corrections'][frame])<.000002
    minimum=min(p.y for p in skin_part(body,pose,report['ground']['bones']));assert abs(minimum-report['ground']['nativeFloor'])<.000002,(frame,minimum)
    rootMinimum=min(rootMinimum,pose['Bip01_Pelvis'].translation.y)
assert rootMinimum>.4,rootMinimum
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.98.0.zip')as archive:
    for row in report['restoredIdle']:assert sha(mod/row['path'])==row['sha256']and (mod/row['path']).read_bytes()==archive.read('ProjectYakuza/'+row['path'])
grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][p]for v in row)for p in ['Bip01_Prop1','Bip01_Prop2']];(w/'lj-entry-prop.tsv').write_text('\t'.join([str(mod/report['output']),*offsets,'151']))
print('PASS LJ original source, 151 samples / 60 fps,',samples,'unchanged body/finger samples; native skinned soles grounded every frame; pelvis minimum',rootMinimum,'source arm angle',math.degrees(worst),'degrees; exact prior RMB selectors')
