from pathlib import Path
import sys,json,hashlib,subprocess,math
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';here=Path(__file__).parent
if '--inside-blender'not in sys.argv:
 r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0 and 'PASS preserved'in r.stdout,r.stderr
 reports=[json.loads((mod/'docs'/name).read_text())for name in ['grab-escape-assets.json','crate-heat-assets.json']];clips=[v for report in reports for v in report['clips']]
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
 for args in [['AnimationProbe',*[str(mod/v['output'])for v in clips]],['GrabAssetProbe',str(mod/'42/media/AnimSets')]]:
  r=subprocess.run([java,'-cp',cp,*args],cwd=here,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout);assert r.returncode==0,r.stderr
 raise SystemExit(0)
sys.path.insert(0,str(here));from locomotion_math import read,locals_at,world
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();samples=0;reports={}
for name in ['grab-escape-assets.json','crate-heat-assets.json']:
 report=json.loads((mod/'docs'/name).read_text());reports[name]=report
 for record in report['clips']:
  output=mod/record['output'];raw=Path(record['retarget']);assert sha(output)==record['sha256']and sha(raw)==record['retargetSha256']and sha(record['source'])==record['sourceSha256']
  _,bones,curves,_=read(output);_,old,source,_=read(raw)
  for curve in curves.values():
   for keys in curve.values():assert len(keys)==record['frames']and all(t==i*160 and all(math.isfinite(v)for v in row)for i,(t,row)in enumerate(keys))
  for i,f in enumerate(record.get('sourceFrames',range(record['frames']))):
   actual=locals_at(bones,curves,i*160);expected=locals_at(old,source,f*160)
   for bone in actual:
    if bone in ['Bip01_Prop1','Bip01_Prop2']:continue
    assert max(abs(actual[bone][r][c]-expected[bone][r][c])for r in range(4)for c in range(4))<.00001,(record['output'],i,bone);samples+=1
  if record['role']in [1,'victim']and not record.get('ending'):assert world(bones,locals_at(bones,curves,0))['Bip01'].translation.y>.3,'victim root height must not be underground'
escape=reports['grab-escape-assets.json'];assert all(v['frames']==71 for v in escape['clips']);assert max(abs(x)for path in escape['paths']for row in path for x in row)<.00001
crate=reports['crate-heat-assets.json'];assert sha(crate['archive'])==crate['archiveSha256']and sha(crate['objectSource'])==crate['objectSha256'];assert crate['qteFrames']==[63,93,123]and crate['contactFrames']==[13,44,74,104,142]
assert all(len(path)==190 for path in crate['paths'])and all(len(path)==67 for path in crate['endingPaths'])
for path in crate['paths']+crate['endingPaths']:assert max(math.dist(a,b)for a,b in zip(path,path[1:]))<.3
actor=next(v for v in crate['clips']if v['role']==0 and not v['ending']);_,bones,curves,_=read(mod/actor['output']);dist=[]
for i in [40,44,50,70,74,80,100,104,110]:
 w=world(bones,locals_at(bones,curves,i*160));dist.append((w['Bip01_Prop1'].translation-w['Bip01_R_Hand'].translation).length)
assert max(dist)-min(dist)>.1,'crate prop must follow original object motion rather than remain glued to punching hand'
print('PASS preserved',samples,'original body transforms, complete escape pair, original-speed finite crate sections, source prop motion and standing victim root height; no game launch')
