from pathlib import Path
import sys,json,subprocess,hashlib
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/crate-heat-assets.json').read_text())
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python-exit-code','1','--python',str(Path(__file__).resolve()),'--','--inside-blender'],capture_output=True,text=True);print(r.stdout);assert r.returncode==0 and'PASS beercase head'in r.stdout,r.stderr
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';subprocess.run([java,'-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','AnimationProbe',*[str(mod/c['output'])for c in report['clips']]],cwd=w,check=True);raise SystemExit(0)
sys.path.insert(0,str(w))
from mathutils import Vector
from locomotion_math import read,locals_at,world
from native_body_geometry import load_body,skin_part,validate_bind
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();assert sha(report['nativeBody'])==report['nativeBodySha256'];body=load_body(report['nativeBody']);validate_bind(body);samples=0
assert report['archive'].endswith('h3000_beercase.par')and report['objectSource'].endswith('h3000_000_7.gmt')
for clip in report['clips']:
 if clip['role']!=0:continue
 assert sha(mod/clip['output'])==clip['sha256'];_,bones,animation,_=read(mod/clip['output']);victim=next(c for c in report['clips']if c['role']==1 and c['ending']==clip['ending']);_,vb,va,_=read(mod/victim['output']);paths=report['endingPaths']if clip['ending']else report['paths']
 for frame,sourceFrame in enumerate(clip['sourceFrames']):
  if not 50<=sourceFrame<=454:continue
  pose=world(bones,locals_at(bones,animation,frame*160));v=world(vb,locals_at(vb,va,frame*160));ap,vp=paths[0][frame],paths[1][frame];shift=Vector(((vp[1]-ap[1])/1.5,0,-(vp[0]-ap[0])/1.5));prop=pose['Bip01_Prop1'];head=[prop.inverted()@(p+shift)for p in skin_part(body,v,['Bip01_Head'])];seat=report['headSeat'];assert abs(min(p.y for p in head)-seat['roof'])<.00003
  for axis in [0,2]:assert abs((min(p[axis]for p in head)+max(p[axis]for p in head))/2-seat['centre'][axis])<.00003
  if sourceFrame==60:assert(prop.to_quaternion()@Vector((0,1,0))).y<-.99
  samples+=1
print('PASS beercase head:',samples,'source spin samples centred inside opening-down crate; native head geometry and source hashes verified')
