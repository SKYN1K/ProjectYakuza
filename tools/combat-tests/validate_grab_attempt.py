from pathlib import Path
import hashlib,json,subprocess,sys,math,struct

ROOT=Path(__file__).resolve().parents[2];W=Path(__file__).parent;MOD=ROOT/'combat/ProjectYakuza'
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    print(result.stdout);assert result.returncode==0 and 'PASS original attempt'in result.stdout,result.stderr
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    subprocess.run([java,'-Xmx192m','-XX:ActiveProcessorCount=2','-cp',cp,'AnimationProbe',str(MOD/'42/media/anims_X/Bob/ProjectYakuza_DD_GrabAttempt.x')],cwd=W,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(W))
from locomotion_math import read,locals_at
report=json.loads((MOD/'docs/grab-attempt-assets.json').read_text(encoding='utf-8'))
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for field,digest in [('source','sourceSha256'),('bep','bepSha256'),('retarget','retargetSha256')]:assert sha(report[field])==report[digest]
output=MOD/report['output'];assert sha(output)==report['sha256']and report['frames']==49 and report['fps']==30 and report['duration']==1.6
_,bones,curves,_=read(output);_,old,source,_=read(report['retarget']);samples=0
for channels in curves.values():
    for keys in channels.values():assert len(keys)==49 and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
for frame in range(49):
    actual=locals_at(bones,curves,frame*160);expected=locals_at(old,source,frame*160)
    for name in actual:
        if name in ['Bip01_Prop1','Bip01_Prop2']:continue
        assert max(abs(actual[name][i][j]-expected[name][i][j])for i in range(4)for j in range(4))<.00001,(frame,name)
        samples+=1
b=Path(report['bep']).read_bytes();pos=16;windows=[]
while pos+80<=len(b):
    section,kind,size=struct.unpack_from('<HHI',b,pos+64);data=b[pos+80:pos+80+size]
    if section==12 and kind in [75,77]:windows.append({'kind':kind,'fromFrame':struct.unpack_from('<f',data,4)[0],'toFrame':struct.unpack_from('<f',data,8)[0]})
    pos+=80+size
assert windows==report['windows']and windows[0]=={'kind':77,'fromFrame':10.0,'toFrame':12.0}
print('PASS original attempt source/BEP hashes, 49 preserved frames, 1.6-second timing and',samples,'retarget body transforms')
