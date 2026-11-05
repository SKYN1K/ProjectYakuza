from pathlib import Path
import sys,json,hashlib,subprocess
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';w=Path(__file__).parent
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0 and 'PASS source-pose'in r.stdout,r.stderr
 report=json.loads((mod/'docs/rush-twohit-sections.json').read_text());args=['F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','AnimationProbe',*[str(mod/v['output'])for v in report['clips']]]
 r=subprocess.run(args,cwd=w,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0,r.stderr
 raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at
report=json.loads((mod/'docs/rush-twohit-sections.json').read_text());samples=0
for record in report['clips']:
 output=mod/record['output'];source=Path(record['source']);assert hashlib.sha256(output.read_bytes()).hexdigest()==record['sha256'];assert hashlib.sha256(source.read_bytes()).hexdigest()==record['sourceSha256']
 _,bones,curves,_=read(output);_,old,original,_=read(source)
 for bone,channels in curves.items():
  for kind,keys in channels.items():assert len(keys)==record['frames']and all(t==i*160 for i,(t,v)in enumerate(keys))
 for frame,sourceFrame in enumerate(record['sourceFrames']):
  a=locals_at(bones,curves,frame*160);b=locals_at(old,original,sourceFrame*160)
  for bone in a:
   assert max(abs(a[bone][x][y]-b[bone][x][y])for x in range(4)for y in range(4))<.00001,(record['output'],frame,bone);samples+=1
assert report['qteFrames']==[70,100,130,160,190,220]and len(report['contactFrames'])==13
for i,deadline in enumerate(report['qteFrames']):
 hits=report['contactFrames'][2*i:2*i+2];assert all(deadline-30<h<deadline for h in hits)
for cut in report['stagingCuts']:
 for path in report['paths']:assert max(abs(path[cut['frame']][a]-path[cut['frame']-1][a])for a in range(2))<.00000001
assert report['contactFrames'][-1]==245 and all(len(p)==327 for p in report['paths'])
print('PASS source-pose split/replay provenance, unchanged 30-fps pose/grip samples',samples,'six one-second two-hit sections and original automatic kick; no invented motion')
