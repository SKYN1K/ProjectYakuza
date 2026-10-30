from pathlib import Path
import json,hashlib,zipfile,re,subprocess
from PIL import Image
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';w=root/'tools/combat-tests'
sha=lambda b:hashlib.sha256(b).hexdigest()
d=json.loads((mod/'docs/encounter-impact-assets.json').read_text(encoding='utf-8'))
for r in d['assets']:
 source=Path(r['source']);path=mod/r['output'];assert sha(source.read_bytes())==r['sourceSha256'] and sha(path.read_bytes())==r['sha256']
 original=Image.open(source).convert('RGBA');output=Image.open(path)
 assert list(output.size)==r['size'] and output.mode=='RGBA' and original.tobytes()==output.tobytes()
 assert sha(output.tobytes())==r['rgbaSha256']
 assert output.getchannel('A').getextrema()[0]==0
d=json.loads((mod/'docs/style-entry-prop-repair.json').read_text(encoding='utf-8'));path=mod/d['output'];assert sha(path.read_bytes())==d['sha256']
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.50.0.zip') as z:before=z.read('ProjectYakuza/'+d['output'])
assert sha(before)==d['beforeSha256']
def remove_props(b):
 s=b.decode('utf-8');edits=[]
 for match in re.finditer(r'Animation\s*\{\s*\{\s*Bip01_Prop[12]\s*\}',s):
  start=s.index('{',match.start());end=start+1;depth=1
  while depth:
   depth+=(s[end]=='{')-(s[end]=='}');end+=1
  edits.append((match.start(),end))
 assert len(edits)==2
 for start,end in reversed(edits):s=s[:start]+s[end:]
 return s
assert remove_props(before)==remove_props(path.read_bytes())
matrices=[','.join(str(x) for row in d['nativeGrip']['nativeOffsets'][prop] for x in row) for prop in ['Bip01_Prop1','Bip01_Prop2']]
contract=w/'entry-prop-contract.tsv';contract.write_text('\t'.join([str(path),*matrices,str(d['frames'])]),encoding='utf-8')
subprocess.run(['F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','PropAttachmentProbe',str(contract)],cwd=w,check=True)
print('PASS exact original impact pixels and stance-entry prop-only repair with unchanged body/fingers/hierarchy/timing')
