from pathlib import Path
import sys,json,hashlib,math,subprocess,struct
root=Path(__file__).resolve().parents[2];here=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
if '--inside-blender'not in sys.argv:
    result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0 and 'PASS original grab/wall source'in result.stdout,result.stderr
    report=json.loads((mod/'docs/grab-strike-assets.json').read_text());wall=json.loads((mod/'docs/wall-heat-assets.json').read_text());clips=report['clips']+wall['clips'];java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe';cp='.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*'
    for args in [['AnimationProbe',*[str(mod/c['output'])for c in clips]],['PropAttachmentProbe',str(here/'grab-prop-contract.tsv')],['GrabAssetProbe',str(mod/'42/media/AnimSets')]]:subprocess.run([java,'-cp',cp,*args],cwd=here,check=True)
    raise SystemExit(0)
sys.path.insert(0,str(here));from locomotion_math import read,locals_at,world
report=json.loads((mod/'docs/grab-strike-assets.json').read_text());wall=json.loads((mod/'docs/wall-heat-assets.json').read_text());grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];contracts=[];samples=0
assert sha(wall['archive'])==wall['archiveSha256']and sha(wall['scene'])==wall['sceneSha256'];assert wall['contactFrames']==[1,28,73]
for record in report['clips']+wall['clips']:
    output=mod/record['output'];raw=Path(record['retarget'])if 'retarget'in record else root/'tools/wall-heat-build/ProjectYakuza/42/media/anims_X/Bob'/output.name
    assert sha(output)==record['sha256']and sha(record['source'])==record['sourceSha256']and sha(raw)==record['retargetSha256']
    _,bones,animation,_=read(output);_,source,curves,_=read(raw);count=record['frames']
    for channels in animation.values():
        for keys in channels.values():assert len(keys)==count and all(t==i*160 and all(math.isfinite(v)for v in values)for i,(t,values)in enumerate(keys))
    for i in range(count):
        actual=locals_at(bones,animation,i*160);expected=locals_at(source,curves,i*160)
        for name in actual:
            if name in ['Bip01_Prop1','Bip01_Prop2']:continue
            assert max(abs(actual[name][a][b]-expected[name][a][b])for a in range(4)for b in range(4))<.00001,(output,name,i);samples+=1
    currentGrip=wall['nativeGrip']if record in wall['clips']else grip
    offsets=[','.join(str(v)for row in currentGrip['nativeOffsets'][prop]for v in row)for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(output),*offsets,str(count)]))
for move in report['moves']:
    assert sha(move['bep'])==move['bepSha256'];b=Path(move['bep']).read_bytes();pos=16;contacts=[]
    while pos+80<=len(b):
        section,kind,size=struct.unpack_from('<HHI',b,pos+64);data=b[pos+80:pos+80+size]
        if section==12 and kind==68:contacts.append(int(struct.unpack_from('<f',data,4)[0]))
        pos+=80+size
    assert contacts==[move['contactFrame']]and abs(move['contactMs']-move['contactFrame']/30*1000)<1e-8
assert all(len(path)==141 and all(math.isfinite(v)for row in path for v in row)for path in wall['paths'])
from paired_paths import bridge_scene_cuts
paths,cuts=bridge_scene_cuts(wall['rawPaths']);assert paths==wall['paths']and cuts==wall['sceneCuts']
assert max(math.dist(a,b)for path in paths for a,b in zip(path,path[1:]))<.25
assert max(math.dist(a,b)for path in paths for a,b in zip(path,path[1:]))<=max(math.dist(a,b)for path in wall['rawPaths']for a,b in zip(path,path[1:]))+1e-9
_,bones,curves,_=read(mod/wall['clips'][1]['output']);pose=world(bones,locals_at(bones,curves,0));assert pose['Bip01'].translation.y>.4,'wall victim must start standing'
(here/'grab-prop-contract.tsv').write_text('\n'.join(contracts),encoding='utf-8')
print('PASS original grab/wall source archives, paired roles, source contact frames,',samples,'preserved retarget body samples and continuous standing-victim paths')
