from pathlib import Path
import sys,json,hashlib,subprocess,ast,struct
from PIL import Image
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza';game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');java=str(game/'jre64/bin/java.exe');cp='.;'+str(game/'*')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
crate=json.loads((mod/'docs/beer-crate-assets.json').read_text());failure=json.loads((mod/'docs/heat-rush-failure-assets.json').read_text());effects=json.loads((mod/'docs/qte-effects-assets.json').read_text())
code=(w/'validate_rush_qte_assets.py').read_text();node=next(n for n in ast.parse(code).body if isinstance(n,ast.FunctionDef)and n.name=='sllz');ns={'struct':struct};exec(compile(ast.Module(body=[node],type_ignores=[]),'sllz','exec'),ns)
with Path(crate['archive']).open('rb')as stream:
    for row in crate['archiveEntries']:
        c,size,stored,offset,attr,ext,stamp,reserved=row['meta'];stream.seek(offset+(ext<<32));data=stream.read(stored if c else size);data=ns['sllz'](data)if c else data
        assert len(data)==size and hashlib.sha256(data).hexdigest()==row['sha256']
assert len(crate['vertices'])==1004 and len(crate['faces'])==1052 and sha(crate['source'])==crate['sourceSha256']and sha(mod/crate['output'])==crate['sha256']
texture=crate['texture'];original=Image.open(texture['source']).convert('RGBA');decoded=Image.open(mod/texture['output']).convert('RGBA');assert original.size==decoded.size and original.tobytes()==decoded.tobytes()and sha(texture['source'])==texture['sourceSha256']and sha(mod/texture['output'])==texture['sha256']and hashlib.sha256(decoded.tobytes()).hexdigest()==texture['rgbaSha256']
assert sha(effects['dds'])==effects['ddsSha256']and sha(mod/effects['output'])==effects['sha256']and Path(effects['source']).read_bytes()==(mod/effects['output']).read_bytes()
a=Image.open(effects['dds']).convert('RGBA');b=Image.open(mod/effects['output']).convert('RGBA');assert a.size==b.size==(512,512)and a.tobytes()==b.tobytes()
if '--model-only'in sys.argv:
 result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','-t','1','--python',str(w/'build_crate_failure_assets.py'),'--','--validate','--model-only'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0 and 'PASS source crate topology'in result.stdout,result.stderr
 subprocess.run([java,'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp',cp,'CrateAssetProbe',str(mod/crate['output']),str(mod/texture['output']),str(mod/effects['output']),str(mod/'42/media/scripts/ProjectYakuza_BeerCrate.txt'),str(mod/'42/media/scripts/ProjectYakuza_Models.txt')],cwd=w,check=True)
 print('PASS original crate archive entries, topology, diffuse/QTE pixels and native item/model/static imports; current paired endings validated separately');raise SystemExit(0)
assert sha(failure['source'])==failure['sourceSha256']and sha(mod/failure['output'])==failure['sha256']and failure['frames']==21
result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--factory-startup','--python',str(w/'build_crate_failure_assets.py'),'--','--validate'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0 and 'PASS source crate topology'in result.stdout,result.stderr
row=[str(mod/failure['output'])]+[','.join(str(v)for line in failure['nativeGrip']['nativeOffsets'][prop]for v in line)for prop in ['Bip01_Prop1','Bip01_Prop2']]+['21'];contract=w/'rush-failure-prop-contract.tsv';contract.write_text('\t'.join(row),encoding='utf-8')
for args in [['AnimationProbe',str(mod/failure['output'])],['PropAttachmentProbe',str(contract)],['CrateAssetProbe',str(mod/crate['output']),str(mod/texture['output']),str(mod/effects['output']),str(mod/'42/media/scripts/ProjectYakuza_BeerCrate.txt'),str(mod/'42/media/scripts/ProjectYakuza_Models.txt')]]:
 result=subprocess.run([java,'--enable-native-access=ALL-UNNAMED','-cp',cp,*args],cwd=w,capture_output=True,text=True,encoding='utf-8',errors='replace');print(result.stdout);assert result.returncode==0,result.stderr
print('PASS unchanged crate diffuse/QTE atlas RGBA pixels, source model topology/grip, original failure recovery and native B42 imports')
