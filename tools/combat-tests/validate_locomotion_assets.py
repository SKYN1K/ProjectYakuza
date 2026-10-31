from pathlib import Path
import sys,json,hashlib,re,subprocess,math,zipfile
root=Path(__file__).resolve().parents[2];w=root/'tools/combat-tests';mod=root/'combat/ProjectYakuza'
if '--inside-blender' not in sys.argv:
 result=subprocess.run(['F:/SteamLibrary/steamapps/common/Blender/blender.exe','-b','--python',str(Path(__file__).resolve()),'--','--inside-blender'],cwd=root,capture_output=True,text=True,encoding='utf-8',errors='replace')
 print(result.stdout)
 if result.returncode or 'PASS locomotion source samples' not in result.stdout:raise SystemExit(result.stderr or 'Blender source checks failed')
 for probe,args in [('PropAttachmentProbe',[str(w/'locomotion-prop-contract.tsv')]),('LocomotionAssetProbe',[str(mod/'42/media')])]:
  subprocess.run(['F:/SteamLibrary/steamapps/common/ProjectZomboid/jre64/bin/java.exe','-cp','.;F:/SteamLibrary/steamapps/common/ProjectZomboid/*',probe,*args],cwd=w,check=True)
 raise SystemExit(0)
sys.path.insert(0,str(w));from locomotion_math import read,pose,locals_at
from mathutils import Matrix
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
d=json.loads((mod/'docs/locomotion-assets.json').read_text());assert sha(d['rig'])==d['rigSha256'];contracts=[];count=0;worst=0;loop=0
for r in d['clips']:
 path=mod/r['output'];assert sha(path)==r['sha256'];s,frames,anim,spans=read(path);times=[f*160 for f in range(r['frames'])]
 if r['grip']:
  g=d['nativeGrips'][r['grip']];assert sha(g['source'])==g['sha256'];matrices=[','.join(str(x) for row in g['nativeOffsets'][prop] for x in row) for prop in ['Bip01_Prop1','Bip01_Prop2']];contracts.append('\t'.join([str(path.resolve()),*matrices,str(r['frames'])]))
 if r['kind'] in ['source','sourceRunNativeTravel']:
  assert sha(r['source'])==r['sourceSha256'] and sha(r['fingerSource'])==r['fingerSha256']
  scratch=root/('tools/locomotion-build/ProjectYakuza/42/media/anims_X/Bob/'+r['name']+'.x');assert sha(scratch)==r['retargetSha256'];_,ff,aa,_=read(scratch)
  if r['kind']=='sourceRunNativeTravel':
   with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.54.0.zip')as previous:before=previous.read('ProjectYakuza/'+r['output']).decode('utf-8').replace('\r\n','\n')
   def without_travel(text):
    match=re.search(r'Animation\s*\{\s*\{\s*Translation_Data\s*\}',text);assert match;start=text.index('{',match.start());end=start+1;depth=1
    while depth:depth+=(text[end]=='{')-(text[end]=='}');end+=1
    return text[:match.start()]+text[end:]
   assert without_travel(before)==without_travel(s),'running body/finger/prop bytes must remain unchanged'
 else:
  assert sha(r['native'])==r['nativeSha256'];_,ff,aa,_=read(r['native'])
  if r['kind']=='stableCarryComposite':
   assert set(frames)==set(ff),'native carry hierarchy must be preserved'
   assert sha(r['armSource'])==r['armSourceSha256'];_,cf,ca,_=read(r['armSource'])
  else:
   assert sha(mod/r['carry'])==r['carrySha256'];_,cf,ca,_=read(mod/r['carry']);ce=max(t for c in ca.values() for keys in c.values() for t,v in keys)
 for t in times:
  actual=locals_at(frames,anim,t);expected=locals_at(ff,aa,t)
  if r['kind']=='sourceRunNativeTravel':
   assert sha(r['native'])==r['nativeSha256'];_,nf,na,_=read(r['native']);ne=max(k for c in na.values() for keys in c.values() for k,v in keys);nativeExpected=locals_at(nf,na,t/times[-1]*ne);nativeExpected['Translation_Data'].translation*=r.get('nativeTravelScale',1);nativeExpected.update({n:v for n,v in expected.items() if n not in ['Body','Translation_Data']});expected=nativeExpected
   assert r['nativeTravelScale']*r['runSpeedScale']==1.28 and r['runSpeedScale']==1
  if r['kind']=='stableCarryComposite':
   hold=locals_at(cf,ca,0)
   for n in r['upperBones']:expected[n]=hold[n]
  if r['kind']=='nativeLegComposite':
   hold=locals_at(cf,ca,t/times[-1]*ce)
   for n in r['upperBones']:expected[n]=hold[n]
  for n in actual:
   if n in ['Bip01_Prop1','Bip01_Prop2']:continue
   error=max(abs(actual[n][i][j]-expected[n][i][j]) for i in range(4) for j in range(4));worst=max(worst,error);assert error<.00001,(r['name'],t,n,error);count+=1
 first=locals_at(frames,anim,0);last=locals_at(frames,anim,times[-1])
 seamBones=[n for n in first if n!='Translation_Data']
 delta=max(abs(first[n][i][j]-last[n][i][j]) for n in seamBones for i in range(4) for j in range(4));loop=max(loop,delta)
 if r['kind'] in ['source','sourceRunNativeTravel']:assert delta<.0001,(r['name'],'source loop seam',delta)
 else:
  nf=locals_at(ff,aa,0);nl=locals_at(ff,aa,times[-1]);baseline=max(abs(nf[n][i][j]-nl[n][i][j]) for n in seamBones if n not in r['upperBones'] for i in range(4) for j in range(4));assert delta<=baseline+.00001,(r['name'],'native seam worsened',delta,baseline)
 if r['name']=='ProjectYakuza_DD_Run':
  for foot in ['Bip01_L_Foot','Bip01_R_Foot']:
   values=[pose(frames,anim,f)[foot].translation.y for f in range(r['frames'])];print('RUN foot minimum',foot,values.index(min(values)),min(values),'range',max(values)-min(values))
(w/'locomotion-prop-contract.tsv').write_text('\n'.join(contracts)+'\n',encoding='utf-8')
nodeData=json.loads((mod/'docs/locomotion-nodes.json').read_text());import xml.etree.ElementTree as E
assert len(nodeData['nodes'])==10
for name in nodeData['nodes']:
 n=E.parse(mod/name).getroot();assert n.findtext('m_BlendTime')=='.25' or float(n.findtext('m_BlendTime'))==.25
 assert n.findtext('m_Looped')=='true'
 assert not any(e.findtext('m_EventName') not in ['Footstep'] for e in n.findall('m_Events'))
 for e in n.findall('m_2DBlends'):
  clip=e.findtext('m_AnimName');assert (mod/('42/media/anims_X/Bob/'+clip+'.x')).exists() or Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/'+clip+'.x').exists(),clip
print('PASS locomotion source samples',count,'unchanged source/native local samples; max matrix error',worst,'max loop seam',loop)
