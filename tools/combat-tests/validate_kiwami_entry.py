from pathlib import Path
import sys,json,subprocess,hashlib,math

root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/kiwami-entry-assets.json').read_text());java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],capture_output=True,text=True);print(r.stdout);assert r.returncode==0 and 'PASS Kiwami'in r.stdout,r.stderr
    selectors=json.loads((mod/'docs/vanilla-pose-fallback.json').read_text())['selectors'];(w/'entry-vanilla-gates.tsv').write_text('\n'.join(str(mod/c['path'])+'\t'+c['gate']for c in selectors))
    for args in [['AnimationProbe',str(mod/report['output'])],['PropAttachmentProbe',str(w/'kiwami-entry-prop.tsv')],['KiwamiEntryProbe',str(mod/report['selector']),'F:/SteamLibrary/steamapps/common/ProjectZomboid/media/AnimSets/player/idle/Idle.xml','F:/SteamLibrary/steamapps/common/ProjectZomboid/media/AnimSets/player/aim/aim_1handed.xml',str(mod/'42/media')],['VanillaPoseProbe',str(w/'entry-vanilla-gates.tsv')]]:
        subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp',str(w)+';F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')if args[0]=='KiwamiEntryProbe'else w,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(w))
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world
from weapon_hold_geometry import source_pose
from build_kiwami_entry import context_for
from y5_source_assets import entry
for record in report['archiveEntries']:assert entry(record['archive'],record['name'])[1]==record
for record in report['retargetProvenance']:assert sha(record['path'])==record['sha256']
for key in ['source','rig','retarget','selector']:assert sha(mod/report[key]if key=='selector'else report[key])==report[key+'Sha256']
assert sha(mod/report['output'])==report['sha256']and report['frames']==46 and report['duration']==1.5
_,bones,animation,_=read(mod/report['output']);_,old,raw,_=read(report['retarget']);context=context_for(True);mirror=Matrix.Diagonal((1,1,-1,1));samples=0;worst=0
for channels in animation.values():
    for keys in channels.values():assert len(keys)==46 and all(t==i*160 and all(math.isfinite(v)for v in row)for i,(t,row)in enumerate(keys))
for frame in range(46):
    local=locals_at(bones,animation,frame*160);expected=locals_at(old,raw,frame*160);pose=world(bones,local);source=source_pose(context,frame);chest=(mirror@source['mune_c_n']@mirror).to_quaternion()@context['bind']['Bip01_Spine1'].to_quaternion();adapt=pose['Bip01_Spine1'].to_quaternion()@chest.inverted();modified=set()
    for side in ['L','R']:
        for bone,child,sb,sc in [('Clavicle','UpperArm','kata','ude1'),('UpperArm','Forearm','ude1','ude2'),('Forearm','Hand','ude2','ude3')]:
            name='Bip01_'+side+'_'+bone;child='Bip01_'+side+'_'+child;suffix='_'+side.lower()+'_n';direction=(adapt@(mirror@(source[sc+suffix].translation-source[sb+suffix].translation))).normalized();error=math.acos(max(-1,min(1,direction.dot((pose[child].translation-pose[name].translation).normalized()))));assert error<.001;worst=max(worst,error);modified.add(name)
        modified.add('Bip01_'+side+'_Hand')
    for name in local:
        if name in modified or name in ['Bip01_Prop1','Bip01_Prop2']:continue
        assert max(abs(local[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<1e-5;samples+=1
grip=report['nativeGrip'];offsets=[','.join(str(v)for row in grip['nativeOffsets'][p]for v in row)for p in ['Bip01_Prop1','Bip01_Prop2']];(w/'kiwami-entry-prop.tsv').write_text('\t'.join([str(mod/report['output']),*offsets,'46']))
print('PASS Kiwami 1 source provenance, 46 original full-body frames,',samples,'unchanged native body/finger samples and original arm directions within',math.degrees(worst),'degrees')
