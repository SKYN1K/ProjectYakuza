from pathlib import Path
import hashlib,json,math,re,struct,subprocess,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2]
mod=root/'combat/ProjectYakuza'
w=root/'tools/combat-tests'
d=json.loads((mod/'docs/extreme-attack-assets.json').read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert len(d['clips'])==9 and len(d['links'])==4
for rig in d['rigInputs']:assert sha(Path(rig['path']))==rig['sha256']
command=Path(d['commandSource']);assert sha(command)==d['commandSha256']
for label,name in d['commandMappings'].items():assert (label+'\0'+name+'\0').encode() in command.read_bytes()
def keys(text):
 result={}
 for match in re.finditer(r'Animation\s*\{\s*\{\s*(\w+)\s*\}',text):
  start=text.index('{',match.start());end=start+1;depth=1
  while depth:
   depth+=(text[end]=='{')-(text[end]=='}');end+=1
  curves={}
  for c in re.finditer(r'AnimationKey\s+\w+\s*\{\s*([012]);\s*(\d+);(.*?)\n\s*\}',text[match.end():end],re.S):
   rows=re.findall(r'(\d+);(\d+);([^;]+);;',c[3]);assert len(rows)==int(c[2])
   curves[int(c[1])]=[(int(t),[float(x) for x in v.split(',')]) for t,n,v in rows]
  result[match[1]]=curves
 return result
contracts=[];samples=0;curvesByVariant={}
for r in d['clips']:
 path=mod/r['output'];assert sha(path)==r['sha256'] and sha(Path(r['source']))==r['sourceSha256'] and sha(Path(r['bep']))==r['bepSha256']
 data=Path(r['bep']).read_bytes();pos=16;contacts=[]
 while pos+80<=len(data):
  section,kind,size=struct.unpack_from('<HHI',data,pos+64);payload=data[pos+80:pos+80+size];assert len(payload)==size
  if section==12 and kind==68:contacts.append(struct.unpack_from('<f',payload,4)[0])
  pos+=80+size
 assert len(contacts)==1 and contacts[0]-r['frames'][0]==r['contactFrame']
 text=path.read_text(encoding='utf-8');curves=keys(text);count=r['frames'][1]-r['frames'][0]+1
 assert len(curves)==35 and not re.search(r'\b(?:nan|inf)\b',text,re.I)
 for bone,channels in curves.items():
  assert len(channels)==3
  for kind,rows in channels.items():
   assert len(rows)==count
   for frame,(tick,values) in enumerate(rows):
    assert tick==frame*160 and all(math.isfinite(x) for x in values)
    if kind==0:assert abs(sum(x*x for x in values)-1)<.00001
    if kind==1:assert values==[1,1,1]
  samples+=count
 raw=root/f'tools/charge-build/ProjectYakuza/42/media/anims_X/Bob/{r["animation"]}.x'
 if raw.is_file():
  original=keys(raw.read_text(encoding='utf-8'))
  for bone,channels in curves.items():
   if bone in ['Bip01_Prop1','Bip01_Prop2']:continue
   for kind,rows in channels.items():assert [v for t,v in rows]==[v for t,v in original[bone][kind][r['frames'][0]:r['frames'][1]+1]]
 node=E.parse(mod/f'42/media/AnimSets/player/melee/{r["animation"]}.xml').getroot()
 hit=[e for e in node.findall('m_Events') if e.findtext('m_EventName')=='AttackCollisionCheck']
 assert len(hit)==1 and abs(float(hit[0].findtext('m_TimePc'))*(count-1)-r['contactFrame'])<1e-8
 markers={e.findtext('m_ParameterValue'):e for e in node.findall('m_Events')}
 if 'doubleLinkFrame' in r:
  for value,frame in [(r['nodeValue'],r['doubleLinkFrame']),('',r['doubleLinkEndFrame'])]:assert abs(float(markers['ProjectYakuzaDoubleReady='+value].findtext('m_TimePc'))*(count-1)-frame)<1e-8
 else:assert not any(k and 'DoubleReady' in k for k in markers)
 assert all(not c.findtext('m_Name')=='ProjectYakuzaExtreme' for c in node.findall('m_Conditions'))
 matrices=[','.join(str(x) for row in d['nativeGrip']['nativeOffsets'][prop] for x in row) for prop in ['Bip01_Prop1','Bip01_Prop2']]
 contracts.append('\t'.join([str(path),*matrices,str(count)]));curvesByVariant[r['variant']]=curves
for link in d['links']:
 first=curvesByVariant['extreme_after_'+str(link['branch'])];second=curvesByVariant['extreme_double_after_'+str(link['branch'])];angles=[]
 for bone in first:
  if any(k in bone for k in ['Dummy','Prop','Finger','Body']):continue
  a=first[bone][0][link['firstExitFrame']][1];b=second[bone][0][0][1]
  dot=abs(sum(x*y for x,y in zip(a,b)))/math.sqrt(sum(x*x for x in a)*sum(x*x for x in b));angles.append(math.degrees(2*math.acos(min(1,dot))))
 a=first['Bip01'][2][link['firstExitFrame']][1];b=second['Bip01'][2][0][1]
 gap=math.sqrt(sum((x-y)**2 for x,y in zip(a,b)));assert abs(gap-link['rootPositionGap'])<1e-9 and gap<.02
 rms=math.sqrt(sum(x*x for x in angles)/len(angles));assert rms<5 and abs(rms-link['localBoneRmsDegrees'])<.005
contract=w/'extreme-prop-contract.tsv';contract.write_text('\n'.join(contracts),encoding='utf-8')
java='F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe'
for args in [['PropAttachmentProbe',str(contract)],['ExtremeAttackProbe',str(mod/'42/media/AnimSets/player/melee')]]:
 subprocess.run([java,'-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',*args],cwd=w,check=True)
print('PASS 9 supplied Extreme Heat GMT/BEP contacts, '+str(samples)+' finite bone samples, retained source poses, command mappings and four source-only paired handoffs below 5 degrees RMS')
