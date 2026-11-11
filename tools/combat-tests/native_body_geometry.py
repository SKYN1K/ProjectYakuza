from pathlib import Path
import re,json
from mathutils import Matrix,Vector
from locomotion_math import read,locals_at,world

number=r'[-+]?(?:\d*\.\d+|\d+\.?\d*)(?:[eE][-+]?\d+)?'

def load_body(path):
    text=Path(path).read_text();match=re.search(r'\bMesh\s+\w+\s*\{\s*(\d+)\s*;',text);count=int(match[1]);body=text[match.end():]
    points=[Vector(tuple(map(float,p)))for p in re.findall('('+number+r');\s*('+number+r');\s*('+number+r');',body)[:count]]
    weights=[[]for _ in points]
    for match in re.finditer(r'SkinWeights\s*\{\s*"([^"]+)"\s*;\s*(\d+)\s*;([^}]+)\}',text):
        bone=match[1];n=int(match[2]);values=[float(x)for x in re.findall(number,match[3])];indices=[int(x)for x in values[:n]];amounts=values[n:2*n];offset=Matrix([values[2*n+i*4:2*n+(i+1)*4]for i in range(4)]).transposed()
        for index,weight in zip(indices,amounts):weights[index].append((bone,weight,offset))
    assert all(abs(sum(w for _,w,_ in row)-1)<.0001 for row in weights)
    return {'points':points,'weights':weights,'path':str(path)}

def skin_part(mesh,pose,prefixes):
    result=[]
    for point,weights in zip(mesh['points'],mesh['weights']):
        if sum(weight for bone,weight,_ in weights if any(bone.startswith(prefix)for prefix in prefixes))<.6:continue
        value=Vector((0,0,0))
        for bone,weight,offset in weights:value+=(pose[bone]@offset@point)*weight
        result.append(value)
    return result

def contact_pair(hand,head):
    best=None
    for a in hand:
        for b in head:
            vertical=abs(a.y-b.y)
            if vertical>.012:continue
            distance=(a-b).length_squared;score=distance+vertical*vertical*4
            if best is None or score<best[0]:best=(score,a,b)
    assert best is not None,'native fist/head surfaces must overlap in height'
    return best[1].copy(),best[2].copy()

def validate_bind(mesh):
    pose={n:Matrix(v['mat'])for n,v in json.loads(Path('C:/Users/Nik/Documents/Codex/2026-10-19/wo/work/bind.json').read_text()).items()};worst=0
    for point,weights in zip(mesh['points'],mesh['weights']):
        actual=Vector((0,0,0))
        for bone,weight,offset in weights:actual+=(pose[bone]@offset@point)*weight
        worst=max(worst,(actual-point).length)
    assert worst<.0001,worst
    return worst
