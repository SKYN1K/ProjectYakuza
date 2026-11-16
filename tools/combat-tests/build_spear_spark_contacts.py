from pathlib import Path
import json,hashlib,shutil
from mathutils import Vector
from locomotion_math import read,world,locals_at
from extract_lau_spear_emote import mesh_vertices
root=Path(__file__).resolve().parents[2]
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def head_indices(model,vertices=None):
    if vertices is None:
        first=model['sourceParts'][0]['triangles'];indices=sorted({v for face,origin in zip(model['faces'],model['surfacePartition']['origins'])if origin['sourceFace']>=first for v in face});return indices,'original blade mesh part'
    low=min(p[1]for p in vertices);high=max(p[1]for p in vertices);return [i for i,p in enumerate(vertices)if p[1]>=high-(high-low)*.25],'native distal weapon head'

def build_spear_sparks(mod,source,model,name):
    floor=source['ground']['floor'];base=source['outputs'][0]['spearMinY'];entries=[i for i in range(1,len(base))if base[i]<=floor+.001 and base[i-1]>floor+.001];first=entries[-1];records=source['outputs']+[{'clip':name,'output':'42/media/anims_X/Bob/'+name+'.x'}];impacts={};references=[]
    for record in records:
        clip=record['clip'];path=mod/record['output'];_,bones,animation,_=read(path);custom=clip==name;mesh=root/'combat/ProjectYakuza'/model['output']if custom else Path(next(p['mesh']for p in source['selection']['nativeProfiles']['items']if p['clip']==clip));vertices=model['outputVertices']if custom else mesh_vertices(mesh);indices,part=head_indices(model,None if custom else vertices);head={i:Vector(vertices[i])for i in indices};tolerance=.0005 if custom else .01
        def sample(time):
            matrix=world(bones,locals_at(bones,animation,time*4800))['Bip01_Prop1'];index=min(indices,key=lambda i:(matrix@head[i]).y);return index,matrix@head[index]
        touch=None
        for tick in range(first*4,91*4):
            index,point=sample(tick/120)
            if point.y<=floor+tolerance:touch=tick/120;break
        assert touch is not None,(clip,'blade does not reach the final ground contact',min((sample(t/120)[1].y,t/4)for t in range(first*4,91*4)))
        samples=[]
        for tick in range(16):
            time=touch+tick/120;index,point=sample(time);samples.append({'time':time,'vertex':index,'localVertex':list(head[index]),'point':list(point)})
        impacts[clip]={'at':touch,'fps':120,'part':part,'floorTolerance':tolerance,'vertexIndices':indices,'mesh':str(mesh),'meshSha256':sha(mesh),'samples':samples};references.append({'path':str(mesh),'sha256':sha(mesh)});print('BLADE',clip,'contact source-frame',touch*30,'at',touch,'seconds',flush=True)
    shared=mod/'42/media/lua/shared/ProjectYakuzaEmotes/EmoteSpears.lua';version=next(line.split('=',1)[1]for line in(mod/'42/mod.info').read_text().splitlines()if line.startswith('version='));items=source['selection']['nativeProfiles']['items'];code='ProjectYakuzaEmotes=ProjectYakuzaEmotes or {}\nProjectYakuzaEmotes.VERSION='+json.dumps(version)+'\nProjectYakuzaEmotes.EmoteSpears={'+','.join('['+json.dumps(p['item'])+']=true'for p in items)+'}\nProjectYakuzaEmotes.SpearClips={'+','.join('['+json.dumps(p['item'])+']='+json.dumps(p['clip'])for p in items)+',["ProjectYakuza.LauKaLongSpear"]="'+name+'"}\nProjectYakuzaEmotes.SpearImpacts={'+','.join('['+json.dumps(clip)+']={at='+format(v['at'],'.12g')+',fps=120,points={'+','.join('{'+','.join(format(n,'.10g')for n in p['point'])+'}'for p in v['samples'])+'}}'for clip,v in impacts.items())+'}\n';shared.write_text(code)
    combat=root/'combat/ProjectYakuza';sparkSource=combat/'42/media/textures/ProjectYakuza/ChargeSpark.png';spark=mod/'42/media/textures/ProjectYakuzaEmotes/e_f_0006_spark01.png';spark.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(sparkSource,spark);original=json.loads((combat/'docs/charged-heavy-assets.json').read_text())['spark'];assert sha(sparkSource)==original['output_sha256']
    return {'output':spark.relative_to(mod).as_posix(),'sha256':sha(spark),'source':original,'impacts':impacts,'searchFirstFrame':first,'operation':'Unchanged supplied Yakuza 6 spark. Contact and late-observation paths use the actual Lau blade part or native distal weapon head; shaft/butt vertices are excluded. No new image or motion assets.','provenance':references+[{'path':str(Path(__file__)),'sha256':sha(Path(__file__))}]}
