from pathlib import Path
import sys,json,hashlib,subprocess
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';w=Path(__file__).parent
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0 and 'PASS source-pose'in r.stdout,r.stderr
 report=json.loads((mod/'docs/rush-twohit-sections.json').read_text());args=['F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','AnimationProbe',*[str(mod/v['output'])for v in report['clips']]]
 r=subprocess.run(args,cwd=w,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0,r.stderr
 raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at
from mathutils import Matrix
report=json.loads((mod/'docs/rush-twohit-sections.json').read_text());samples=0
for record in report['clips']:
 output=mod/record['output'];source=Path(record['source']);assert hashlib.sha256(output.read_bytes()).hexdigest()==record['sha256'];assert hashlib.sha256(source.read_bytes()).hexdigest()==record['sourceSha256']
 _,bones,curves,_=read(output);_,old,original,_=read(source)
 for bone,channels in curves.items():
  for kind,keys in channels.items():assert len(keys)==record['frames']and all(t==i*160 for i,(t,v)in enumerate(keys))
 for frame,sourceFrame in enumerate(record['sourceFrames']):
  a=locals_at(bones,curves,frame*160);b=locals_at(old,original,sourceFrame*160)
  seam=next((v for v in record.get('seamBlends',[])if v['frame']<=frame<v['frame']+v['frames']),None)
  if seam:
   previous=locals_at(old,original,seam['sourcePrevious']*160);weight=(frame-seam['frame']+1)/4;weight=weight*weight*(3-2*weight)
   for bone in b:
    p0,q0,s0=previous[bone].decompose();p1,q1,s1=b[bone].decompose();b[bone]=Matrix.LocRotScale(p0.lerp(p1,weight),q0.slerp(q1,weight),s0.lerp(s1,weight))
  for bone in a:
   assert max(abs(a[bone][x][y]-b[bone][x][y])for x in range(4)for y in range(4))<.00001,(record['output'],frame,bone);samples+=1
assert report['qteFrames']==[69,88,107,126,145,164]and len(report['contactFrames'])==13
for i,deadline in enumerate(report['qteFrames']):
 hits=report['contactFrames'][2*i:2*i+2];assert all(deadline-19<h<deadline for h in hits)
for cut in report['stagingCuts']:
 for path in report['paths']:assert max(abs(path[cut['frame']][a]-path[cut['frame']-1][a])for a in range(2))<.00000001
assert report['contactFrames'][-1]==190 and all(len(p)==271 for p in report['paths'])
print('PASS source-pose split/replay provenance, verified original/blended 30-fps pose/grip samples',samples,'six nineteen-frame two-hit sections at unchanged 1x speed and original automatic kick; source-pose seam crossfades verified')
