from pathlib import Path
import sys,json,subprocess,hashlib,zipfile,re

root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/crate-head-alignment.json').read_text());sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],capture_output=True,text=True);print(r.stdout);assert r.returncode==0 and'PASS crate head'in r.stdout,r.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],['PropAttachmentProbe',str(w/'crate-head-prop.tsv')]]:subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(w))
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world,brace
from native_body_geometry import load_body,skin_part,validate_bind
assert sha(report['baseline'])==report['baselineSha256']and sha(report['nativeBody'])==report['nativeBodySha256'];body=load_body(report['nativeBody']);validate_bind(body);model=json.loads((mod/'docs/beer-crate-assets.json').read_text());assert model['sha256']==report['modelSha256'];vertices=[Vector(v)*report['modelScale']for v in model['vertices']];scene=json.loads((mod/'docs/crate-heat-assets.json').read_text());contracts=[];seated=0
def without_prop(text):
    match=re.search(r'Animation\s*\{\s*\{\s*Bip01_Prop1\s*\}',text);return text[:match.start()]+text[brace(text,text.index('{',match.start())):]
with zipfile.ZipFile(report['baseline'])as archive:
    for record in report['clips']:
        clip=next(c for c in scene['clips']if c['output']==record['output']);output=mod/clip['output'];assert sha(output)==record['sha256']==clip['sha256'];old=w/('crate-head-old-'+str(clip['ending'])+'.x');old.write_bytes(archive.read('ProjectYakuza/'+clip['output']));text,bones,animation,_=read(output);previous,ob,oa,_=read(old);assert without_prop(text)==without_prop(previous),'only right prop can change';victim=next(c for c in scene['clips']if c['role']==1 and c['ending']==clip['ending']);_,vb,va,_=read(mod/victim['output']);paths=scene['endingPaths']if clip['ending']else scene['paths'];offsets=[[],[]]
        for frame,sourceFrame in enumerate(clip['sourceFrames']):
            native=world(bones,locals_at(bones,animation,frame*160));prior=world(ob,locals_at(ob,oa,frame*160));victimPose=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));head=[p+shift for p in skin_part(body,victimPose,['Bip01_Head'])];prop=native['Bip01_Prop1'];calibrated=prior['Bip01_Prop1']@Matrix(report['calibration']);assert 1-abs(prop.to_quaternion().dot(calibrated.to_quaternion()))<.00001
            if sourceFrame>=13:
                localHead=[prop.inverted()@point for point in head];assert abs(min(point.y for point in localHead)-report['roofInteriorY'])<.00002
                for axis in [0,2]:assert abs((min(point[axis]for point in localHead)+max(point[axis]for point in localHead))/2-report['modelCentre'][axis])<.00002
                seated+=1
            for i,(hand,bone)in enumerate([('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]):offsets[i].append(native[hand].inverted()@Matrix(record['frames'][frame]['propWorld'])if i==0 else prior[hand].inverted()@prior[bone])
        encoded=[';'.join(','.join(str(v)for row in matrix for v in row)for matrix in values)for values in offsets];contracts.append('\t'.join([str(output),*encoded,str(clip['frames'])]))
(w/'crate-head-prop.tsv').write_text('\n'.join(contracts));assert seated==244
print('PASS crate head alignment:',seated,'main/ending samples centred inside correctly oriented crate, inner roof at head crown, unchanged body/fingers and calibrated source rotations and two actor prop contracts')
