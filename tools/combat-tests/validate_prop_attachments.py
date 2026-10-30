from pathlib import Path
import hashlib,json,re,subprocess,zipfile,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2]
w=root/'tools/combat-tests'
mod=root/'combat/ProjectYakuza'
data=json.loads((mod/'docs/prop-attachment-repair.json').read_text())
assert len(data['clips'])==31
def digest(b):return hashlib.sha256(b).hexdigest()
def without_props(b):
 s=b.decode('utf-8');edits=[]
 for m in re.finditer(r'Animation\s*\{\s*\{\s*Bip01_Prop[12]\s*\}',s):
  start=s.index('{',m.start());depth=1;i=start+1
  while depth:
   depth+=(s[i]=='{')-(s[i]=='}');i+=1
  edits.append((m.start(),i))
 assert len(edits)==2
 for start,end in reversed(edits):s=s[:start]+s[end:]
 return s
lines=[]
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.46.0.zip') as old:
 for row in data['clips']:
  path=mod/row['path'];content=path.read_bytes();assert digest(content)==row['sha256']
  name='ProjectYakuza/'+row['path']
  if name in old.namelist():
   before=old.read(name);assert digest(before)==row['beforeSha256']
   assert without_props(before)==without_props(content),path
  grip=data['nativeGrips'][row['grip']]
  assert digest(Path(grip['source']).read_bytes())==grip['sha256']
  matrices=[','.join(str(x) for r in grip['nativeOffsets'][prop] for x in r) for prop in ['Bip01_Prop1','Bip01_Prop2']]
  lines.append('\t'.join([str(path),*matrices,str(row['frames'])]))
 contract=w/'prop-contract.tsv';contract.write_text('\n'.join(lines))
 java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
 args=[java,'-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*','PropAttachmentProbe',str(contract)]
 subprocess.run(args,cwd=w,check=True)
 old_path=w/'old-detached-prop.x';old_path.write_bytes(old.read('ProjectYakuza/42/media/anims_X/Bob/ProjectYakuza_DD_BatLight01.x'))
 source=next(line for line in lines if 'DD_BatLight01.x' in line)
 negative=w/'prop-negative.tsv';negative.write_text(str(old_path)+'\t'+source.split('\t',1)[1])
 failed=subprocess.run(args[:-1]+[str(negative)],cwd=w,capture_output=True,text=True)
 assert failed.returncode!=0 and 'prop detached' in failed.stderr
heavy=json.loads((mod/'docs/normal-heavy-assets.json').read_text())
for source,key in [('source','sourceSha256'),('bep','bepSha256')]:assert digest(Path(heavy[source]).read_bytes())==heavy[key]
assert digest((mod/heavy['output']).read_bytes())==heavy['sha256']
assert heavy['frames']==[0,50] and heavy['fps']==30
node=E.parse(mod/'42/media/AnimSets/player/melee/ProjectYakuza_DD_Heavy.xml').getroot()
contacts=[e for e in node.findall('m_Events') if e.findtext('m_EventName')=='AttackCollisionCheck']
assert len(contacts)==1 and float(contacts[0].findtext('m_TimePc'))==9/50
assert not any('DoubleReady' in (e.findtext('m_ParameterValue') or '') for e in node.findall('m_Events'))
print('PASS original body/finger bytes, native prop offsets, detached-prop negative regression and supplied heavy provenance/contact')
