from pathlib import Path
import sys,re,json,hashlib
from mathutils import Matrix,Vector
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,world

def geometry(path):
 s=path.read_text(encoding='utf-8');m=re.search(r'\bMesh Body\s*{\s*(\d+);',s);count=int(m[1]);numbers=r'([-+0-9.eE]+)'
 vertices=[Vector(tuple(float(x)for x in v))for v in re.findall(numbers+';'+numbers+';'+numbers+';',s[m.end():])[:count]]
 groups={}
 for match in re.finditer(r'SkinWeights\s*{\s*"(Bip01_(?:Head|R_Foot|R_Toe0))";\s*(\d+);(.*?)\n\s*}',s,re.S):
  pieces=match[3].split(';');indices=[int(v)for v in re.findall(r'\d+',pieces[0])];weights=[float(v)for v in pieces[1].split(',')if v.strip()];values=[float(v)for v in pieces[2].split(',')if v.strip()];matrix=Matrix([values[i:i+4]for i in range(0,16,4)]).transposed()
  groups[match[1]]=[(matrix@vertices[i],weight)for i,weight in zip(indices,weights)if weight>.8]
 return groups

def run():
 mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/ground-heat-assets.json').read_text());poses=[]
 for c in report['clips']:
  _,bones,curves,_=read(mod/c['output']);poses.append(world(bones,locals_at(bones,curves,30*160)))
 heads=[];feet=[];sources=[]
 for name in ['MaleBody.x','FemaleBody.x']:
  p=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned')/name;groups=geometry(p)
  hs=[poses[1]['Bip01_Head']@point for point,weight in groups['Bip01_Head']];head=sum(hs,Vector())/len(hs)
  fs=[poses[0][bone]@point for bone in ['Bip01_R_Foot','Bip01_R_Toe0']for point,weight in groups.get(bone,[])]
  low=min(v.y for v in fs);sole=[v for v in fs if v.y<=low+.025];foot=sum(sole,Vector())/len(sole)
  heads.append(head);feet.append(foot);sources.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'head':list(head),'sole':list(foot),'headVertices':len(hs),'soleVertices':len(sole)})
 foot=sum(feet,Vector())/2;head=sum(heads,Vector())/2;a,v=report['paths'][0][30],report['paths'][1][30]
 offset=[a[0]-foot.z*1.5-(v[0]-head.z*1.5),a[1]+foot.x*1.5-(v[1]+head.x*1.5)]
 p=mod/'42/media/lua/shared/ProjectYakuza/GroundHeatPaths.lua';s=p.read_text();marker='ProjectYakuza.PairedMotions.dod_ground.contactOffset='
 if marker in s:s=s[:s.index(marker)]
 p.write_text(s.rstrip()+'\n'+marker+'{forward='+format(offset[0],'.12f')+',right='+format(offset[1],'.12f')+'}\n',encoding='utf-8')
 alignment={'operation':'Code-only paired-origin calibration at source impact frame 30. Original actor/victim clips and root paths remain unchanged. Native male/female PZ head mesh centroids and right-foot sole vertices determine a constant victim translation, applied from frame zero in all headings.','frame':30,'modelToTileScale':1.5,'forwardAxis':'-model Z','rightAxis':'+model X','sources':sources,'offset':offset,'actorSole':list(foot),'victimHead':list(head),'clips':[{'path':c['output'],'sha256':c['sha256']}for c in report['clips']]}
 (mod/'docs/ground-contact-alignment.json').write_text(json.dumps(alignment,indent=2)+'\n',encoding='utf-8');print('PASS native head/sole calibration',offset)
if __name__=='__main__':run()
