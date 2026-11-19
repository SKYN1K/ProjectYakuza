from pathlib import Path
import json,math,subprocess,sys,hashlib
from phone_source_assets import entry
ROOT=Path(__file__).resolve().parents[2];W=Path(__file__).parent;MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');WORK=ROOT/'tools/phone-dev-build';WORK.mkdir(exist_ok=True)
subprocess.run([sys.executable,str(W/'build_phone_dev_assets.py'),'--validate'],check=True)
subprocess.run([sys.executable,str(W/'build_phone_font.py'),'--validate'],check=True)
subprocess.run([sys.executable,str(W/'build_phone_presentation_assets.py'),'--validate'],check=True)
subprocess.run([sys.executable,str(W/'build_phone_material.py'),'--validate'],check=True)
scene=json.loads((MOD/'docs/items-source.json').read_text())
for record in scene['sources']:
 raw,actual=entry(Path('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data')/record['archive'],record['entry']);assert actual==record
assert scene['rootOpacity']['in']==[[0,0],[10,1]]and scene['rootOpacity']['out']==[[0,1],[10,0]]
d=json.loads((MOD/'docs/assets.json').read_text());contract=WORK/'vertices.tsv';contract.write_text(''.join('\t'.join(str(x)for x in p+n+uv)+'\n'for p,n,uv in zip(d['exportedPositions'],d['exportedNormals'],d['uv'])))
inputs=[];cases=[]
points=[[-.3905,5.7124272,-3.2274276],[-.3905,5.7124272,3.2274276],[-.3905,-5.7664201,3.2274276],[-.3905,-5.7664201,-3.2274276]]
for index in range(9):
 column=index%3;row=index//3;u=(57+column*103)/320;v=(202+row*111)/568;points.append([-.3905,5.7124272-11.4788473*v,-3.2274276+6.4548552*u])
for width,height in [(336,480),(600,900),(756,1080)]:
 for opening in [0,.25,.5,.75,1]:
  for px in [-1,0,1]:
   for py in [-1,0,1]:
    for reduce in [False,True]:
     amount=0 if reduce else 1-opening;x=0 if reduce else px;y=0 if reduce else py
     pose={'rx':math.radians(4+y*3-55*amount),'ry':math.radians(6+x*6-35*amount),'rz':math.radians(10+x*1.5+12*amount),'scale':1-.5*amount,'x':0,'y':-14*amount,'z':-.6*amount}
     for point in points:
      inputs.append([width,height,pose['rx'],pose['ry'],pose['rz'],pose['scale'],pose['x'],pose['y'],pose['z'],*point]);cases.append({'width':width,'height':height,'pose':pose,'point':point,'open':opening,'px':px,'py':py,'reduce':reduce})
listing=WORK/'projections.tsv';listing.write_text(''.join('\t'.join(str(v)for v in row)+'\n'for row in inputs));output=WORK/'projections.json'
java=[str(GAME/'jre64/bin/java.exe'),'-Xms16m','-Xmx384m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;'+str(GAME/'*')]
subprocess.run([*java,'PhoneDevNativeProbe',str((MOD/'42/media').resolve()),str(contract.resolve()),str(listing.resolve()),str(output.resolve())],cwd=W,check=True)
references=json.loads(output.read_text());assert len(cases)==len(references)
for case,reference in zip(cases,references):case['native']=reference
(WORK/'cases.json').write_text(json.dumps(cases,separators=(',',':')))
subprocess.run([*java,'AttackEffectProbe',*[str(p.resolve())for p in sorted((MOD/'42/media/textures').rglob('*.png'))],str(ROOT/'combat/ProjectYakuza/42/media/textures/ProjectYakuza/HeatHUD/OriginalDragonAtlas.png')],cwd=W,check=True)
heart=json.loads((MOD/'docs/favorite-icon-source.json').read_text());assert hashlib.sha256((MOD/'42/media/textures/ProjectYakuzaPhoneDev/FavoriteHeart.png').read_bytes()).hexdigest()==heart['sha256']
assert heart['author']=='Anggara'and'flaticon.com/free-icon/heart_'in heart['source']
required=MOD/'42/mod.info';assert 'require=ProjectYakuza'in required.read_text()and'version=0.1.6'in required.read_text()
for name,row in d['images'].items():assert hashlib.sha256((MOD/row['output']).read_bytes()).hexdigest()==row['sha256']
print('PASS phone dev source assets, original pixels, native geometry/UVs and',len(cases),'projection references; separate shared-combat dependency')
