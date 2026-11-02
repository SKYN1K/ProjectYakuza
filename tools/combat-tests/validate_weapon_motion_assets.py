from pathlib import Path
import sys,json,hashlib,subprocess,re,math,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    r=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(r.stdout)
    if r.returncode or'PASS weapon source composites'not in r.stdout:raise SystemExit(r.stderr or'source validation failed')
    java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    for args in [['AnimationProbe',*[str(mod/c['output'])for name in ['weapon-motion-assets','style-travel-assets']for c in json.loads((mod/'docs'/(name+'.json')).read_text())['clips']]],['PropAttachmentProbe',str(w/'weapon-motion-prop-contract.tsv')],['WeaponMotionProbe',str(mod/'42/media')]]:
        result=subprocess.run([java,'-cp',cp,*args],cwd=w,capture_output=True,text=True,encoding='utf-8',errors='replace')
        if result.returncode:print(result.stdout);raise SystemExit(result.stderr)
        print(result.stdout.splitlines()[-1])
    raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,locals_at,world
from mathutils import Matrix,Vector,Euler
d=json.loads((mod/'docs/weapon-motion-assets.json').read_text());assert len(d['clips'])==42 and sha(d['rig'])==d['rigSha256'];samples=0;contracts=[];worst=0;clearance=10
mesh=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/weapons/2handed/Katana.x').read_text();match=re.search(r'Mesh Katana\s*{\s*(\d+);(.*?)\n\s*(\d+);(.*?)MeshNormals',mesh,re.S);vertices=[Vector(tuple(map(float,x)))for x in re.findall(r'([-\d.]+);([-\d.]+);([-\d.]+);',match[2])];faces=[tuple(map(int,x))for x in re.findall(r'3;(\d+),(\d+),(\d+);',match[4])];edges=set(tuple(sorted((f[i],f[(i+1)%3])))for f in faces for i in range(3));attachment=Euler(tuple(math.radians(x)for x in [-23.8537,-86.6222,-22.0887]),'XYZ').to_matrix().to_4x4();attachment.translation=Vector((-.013,.0001,.0025))

def distance(p,a,b):
    v=b-a;t=max(0,min(1,(p-a).dot(v)/v.length_squared))if v.length_squared else 0
    return(p-(a+v*t)).length

for record in d['clips']:
    assert sha(record['source'])==record['sourceSha256']and sha(record['retarget'])==record['retargetSha256']and sha(mod/record['output'])==record['sha256']and sha(record['fingerSource'])==record['fingerSha256']
    _,f,a,_=read(mod/record['output']);_,sf,sa,_=read(record['retarget']);end=(record['frames']-1)*160;grip=d['grips'][record['grip']];assert sha(grip['source'])==grip['sha256'];assert all(all(math.isfinite(v)for v in values)for c in a.values()for keys in c.values()for t,values in keys)
    if record['kind']=='worldArmComposite':
        assert sha(record['native'])==record['nativeSha256'];_,nf,na,_=read(record['native']);assert set(f)==set(nf)
    else:assert record['frames']>1
    for i in range(record['frames']):
        t=i*160;actual=locals_at(f,a,t)
        if record['kind']=='worldArmComposite':
            expected=locals_at(nf,na,t);source=world(sf,locals_at(sf,sa,t/end*(record['sourceFrames']-1)*160));actualWorld=world(f,actual)
            for bone in actual:
                if bone in['Bip01_Prop1','Bip01_Prop2']:continue
                if bone in record['upperBones']and bone in source:
                    error=1-abs(actualWorld[bone].to_quaternion().dot(source[bone].to_quaternion()))
                else:error=max(abs(actual[bone][x][y]-expected[bone][x][y])for x in range(4)for y in range(4))
                worst=max(worst,error);assert error<.00002,(record['name'],i,bone,error);samples+=1
            if record['name'].startswith('ProjectYakuza_DD_Blade'):
                for transform in [attachment,attachment.inverted()]:
                    model=actualWorld['Bip01_Prop1']@transform;vs=[model@v for v in vertices]
                    for bone in ['Bip01_Neck','Bip01_Head']:
                        point=actualWorld[bone].translation;near=min(distance(point,vs[a],vs[b])for a,b in edges);clearance=min(clearance,near)
        else:
            expected=locals_at(sf,sa,t)
            for bone in actual:
                if bone in['Bip01_Prop1','Bip01_Prop2']:continue
                error=max(abs(actual[bone][x][y]-expected[bone][x][y])for x in range(4)for y in range(4));assert error<.00001;samples+=1
    offsets=[','.join(str(x)for row in grip['nativeOffsets'][prop]for x in row)for prop in['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(mod/record['output']),*offsets,str(record['frames'])]))
    if 'bep'in record:
        assert sha(record['bep'])==record['bepSha256'];node=E.parse(mod/('42/media/AnimSets/player/melee/'+record['name']+'.xml')).getroot();contacts=[e for e in node.findall('m_Events')if e.findtext('m_EventName')=='AttackCollisionCheck'];assert len(contacts)==1 and abs(float(contacts[0].findtext('m_TimePc'))*(record['frames']-1)-record['contactFrame'])<.00001
blendClearance=10;ready=next(c for c in d['clips']if c['name']=='ProjectYakuza_DD_BladeReady');_,bf,ba,_=read(mod/ready['output']);start=locals_at(bf,ba,0)
for record in d['clips']:
    if not record['name'].startswith('ProjectYakuza_DD_BladeRelaxed'):continue
    _,tf,ta,_=read(mod/record['output'])
    for phase in [0,.25,.5,.75,1]:
        target=locals_at(tf,ta,phase*(record['frames']-1)*160)
        for blend in [.1,.25,.5,.75,.9]:
            mixed={}
            for bone in bf:
                a=start[bone];b=target.get(bone,a);rotation=a.to_quaternion().slerp(b.to_quaternion(),blend).to_matrix().to_4x4();rotation.translation=a.translation.lerp(b.translation,blend);mixed[bone]=rotation
            actual=world(bf,mixed)
            for transform in[attachment,attachment.inverted()]:
                model=actual['Bip01_Prop1']@transform;vs=[model@v for v in vertices]
                for bone in['Bip01_Neck','Bip01_Head']:blendClearance=min(blendClearance,min(distance(actual[bone].translation,vs[a],vs[b])for a,b in edges))
assert min(clearance,blendClearance)>.045,('katana neck/head mesh-edge clearance',clearance,blendClearance)
(w/'weapon-motion-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
travel=json.loads((mod/'docs/style-travel-assets.json').read_text())
for record in travel['clips']:
    for key,digest in [('source','sourceSha256'),('retarget','retargetSha256'),('native','nativeSha256')]:assert sha(record[key])==record[digest]
    assert sha(mod/record['output'])==record['sha256'];_,f,a,_=read(mod/record['output']);_,sf,sa,_=read(record['retarget']);_,nf,na,_=read(record['native']);end=max(t for c in na.values()for ks in c.values()for t,v in ks)
    assert abs(record['duration']-end/4800)<1e-9 and len(record['times'])==record['sourceFrames']
    for i,t in enumerate(record['times']):
        actual=locals_at(f,a,t);expected=locals_at(sf,sa,i*160);native=locals_at(nf,na,t)
        for bone in actual:
            target=expected[bone]if bone in expected and bone not in['Body','Translation_Data']else native[bone];assert max(abs(actual[bone][x][y]-target[x][y])for x in range(4)for y in range(4))<.00002,(record['name'],i,bone);samples+=1
    assert(locals_at(f,a,end)['Translation_Data'].translation-locals_at(f,a,0)['Translation_Data'].translation).length>.1
for record in d['selectors']+travel['selectors']:
    p=mod/record['path'];assert sha(p)==record['sha256'];n=E.parse(p).getroot();c={e.findtext('m_Name'):e.findtext('m_Value')for e in n.findall('m_Conditions')};assert c['ProjectYakuzaStyle']=='dragon_of_dojima'
    if '/aim'in record['path']:assert float(n.findtext('m_maxTorsoTwist'))==0
print('PASS weapon source composites',samples,'source/native samples; worst error',worst,'katana neck/head mesh-edge clearance',clearance,'blend clearance',blendClearance,'native units; source attack contacts and retimed travel verified')

