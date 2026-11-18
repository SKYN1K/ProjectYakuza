from pathlib import Path
import hashlib,json,subprocess,sys,xml.etree.ElementTree as E
ROOT=Path(__file__).resolve().parents[2];WORK=Path(__file__).parent;MOD=ROOT/'combat/ProjectYakuza';GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');OUT=WORK/'parent-poses-native';OUT.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
files={f.stem:f for part in ('Bob','Kate','Zombie')for f in (GAME/'media/anims_X'/part).rglob('*.x')};files.update({f.stem:f for f in (MOD/'42/media/anims_X/Bob').glob('*.x')})
names=set();boundaries={};nodes=[]
for base in [GAME/'media/AnimSets/player',MOD/'42/media/AnimSets/player']:
 for p in sorted(base.rglob('*.xml')):
  node=E.parse(p).getroot();masks=node.findall('m_SubStateBoneWeights');animation=node.findtext('m_AnimName');rel=p.relative_to(base).parts[0]
  if base==MOD/'42/media/AnimSets/player' or any(k in rel.lower()for k in ('idle','movement','turn','aim','run'))or rel=='walk.xml':
   names.update(n.text for n in node.iter('m_AnimName')if n.text in files)
  if base==MOD/'42/media/AnimSets/player' and p.name.startswith('ProjectYakuza_DD_') and animation:
   bones={m.findtext('boneName')for m in masks}
   if masks and 'Bip01' not in bones and 'Bip01_Pelvis' not in bones:
    parent=3 if 'Bip01_Spine'in bones else 4
    old=boundaries.setdefault(animation,parent);assert old==parent
    nodes.append({'path':str(p.relative_to(ROOT)),'sha256':sha(p),'animation':animation,'parent':parent})
paths={name:files[name]for name in sorted(names)}
listing=OUT/'inputs.tsv';listing.write_text(''.join(str(p.resolve())+'\t'+str((OUT/(name+'.json')).resolve())+'\n'for name,p in paths.items()))
index=OUT/'cache-index.json';probe=sha(WORK/'PoseParentProbe.java');native={'probeSha256':probe,'importerSha256':sha(WORK/'LimbImpactProbe.java'),'gameJarSha256':sha(GAME/'projectzomboid.jar'),'humanRigSha256':sha(GAME/'media/models_X/Skinned/MaleBody.x')}
if '--reuse-native'not in sys.argv:
 subprocess.run([str(GAME/'jre64/bin/java.exe'),'-Xms16m','-Xmx384m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;'+str(GAME/'*'),'PoseParentProbe',str(listing)],cwd=WORK,check=True)
 index.write_text(json.dumps(native))
else:assert json.loads(index.read_text())==native
code=['ProjectYakuza=ProjectYakuza or {}','local T={};ProjectYakuza.ParentPoseTracks=T'];rows=[]
fmt=lambda a:'{'+','.join(format(v,'.9g')for v in a)+'}'
for name,path in paths.items():
 d=json.loads((OUT/(name+'.json')).read_text());assert d['sha256']==sha(path);curves=[]
 for bone in range(4):
  values=[r[bone]for r in d['frames']]
  if max(abs(x-y)for a in values for x,y in zip(a,values[0]))<1e-7:values=values[:1]
  curves.append('{'+','.join(fmt(v)for v in values)+'}')
 code.append('T['+json.dumps(name)+']=(function()return {fps=30,duration='+format(d['duration'],'.9g')+',bones={'+','.join(curves)+'}}end)()')
 rows.append({'animation':name,'source':str(path),'sha256':sha(path),'samples':len(d['frames'])})
code.append('ProjectYakuza.ParentPoseMasks={'+','.join('['+json.dumps(n)+']='+str(p)for n,p in sorted(boundaries.items()))+'}')
text='\n'.join(code)+'\n';target=MOD/'42/media/lua/client/ProjectYakuza/ParentPoseTracks.lua'
report={'version':next(line.split('=',1)[1]for line in (MOD/'42/mod.info').read_text().splitlines()if line.startswith('version=')),'operation':'Numeric parent-bone PRS samples from original installed Human animations; no model, motion, texture, audio or preview generated. Parent masks follow actual mod XML. Runtime replaces the raw attack pelvis/spine parent with the current layer-zero standing/walking pose.','fps':30,'native':native,'clips':rows,'masks':nodes,'output':str(target.relative_to(MOD)),'sha256':hashlib.sha256(text.encode()).hexdigest()}
if '--write'in sys.argv:target.write_text(text,newline='\n');(MOD/'docs/parent-pose-prediction.json').write_text(json.dumps(report,indent=2)+'\n',newline='\n')
else:assert target.read_text()==text
print('PASS',len(rows),'original parent-pose clips;',len(boundaries),'masked clips;',len(text),'bytes of numeric code')
