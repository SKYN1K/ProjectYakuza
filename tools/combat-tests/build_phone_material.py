from pathlib import Path
import collections,hashlib,io,json,math,sys
from PIL import Image
from y5_source_assets import entry

ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';validate='--validate'in sys.argv
source=json.loads((MOD/'docs/assets.json').read_text());P=source['exportedPositions'];N=source['exportedNormals'];UV=source['uv']
maps={};records=[]
for suffix in ['m','n']:
 name='r_tu_xpra_blu1_ay_'+suffix+'.dds';raw,record=entry('F:/SteamLibrary/steamapps/common/Yakuza 6 - The Song of Life/data/asset.par',name);record['archive']='asset.par';records.append(record);maps[suffix]=Image.open(io.BytesIO(raw)).convert('RGB')
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def sub(a,b):return [x-y for x,y in zip(a,b)]
def cross(a,b):return [a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]]
def unit(a):
 length=math.sqrt(dot(a,a));return [x/length for x in a]
def area(points):return sum(math.sqrt(dot(c,c))/2 for i in range(1,len(points)-1)for c in [cross(sub(points[i],points[0]),sub(points[i+1],points[0]))])
def hull(points,normal):
 axis=max(range(3),key=lambda i:abs(normal[i]));axes=[i for i in range(3)if i!=axis];unique={tuple(round(x,5)for x in p):p for p in points};ordered=sorted(unique.values(),key=lambda p:(p[axes[0]],p[axes[1]]))
 def turn(a,b,c):return (b[axes[0]]-a[axes[0]])*(c[axes[1]]-a[axes[1]])-(b[axes[1]]-a[axes[1]])*(c[axes[0]]-a[axes[0]])
 def half(rows):
  result=[]
  for p in rows:
   while len(result)>1 and turn(result[-2],result[-1],p)<=1e-8:result.pop()
   result.append(p)
  return result
 return half(ordered)[:-1]+half(list(reversed(ordered)))[:-1]
groups=collections.defaultdict(list);omitted=0;sourceArea=0
for face in source['faces']:
 points=[P[i]for i in face];a=area(points)
 if a<1e-7:continue
 average=unit([sum(N[i][k]for i in face)for k in range(3)])
 if average[0]<-.95 and all(-5.767<=p[1]<=5.713 and -3.228<=p[2]<=3.228 for p in points):omitted+=1;continue
 normal=unit(cross(sub(points[1],points[0]),sub(points[2],points[0])))
 if dot(normal,average)<0:normal=[-x for x in normal]
 uv=[sum(UV[i][k]for i in face)/3 for k in range(2)];x=min(1023,max(0,int(uv[0]*1024)));y=min(1023,max(0,int(uv[1]*1024)));m=maps['m'].getpixel((x,y));n=maps['n'].getpixel((x,y))
 material=[m[0]/255,m[1]/255,(abs(n[0]-128)+abs(n[1]-128))/255]
 key=tuple(round(x,3)for x in normal)+tuple([round(dot(normal,points[0]),3)])
 groups[key].append({'p':points,'n':normal,'a':a,'material':material});sourceArea+=a
polygons=[]
for rows in groups.values():
 changed=True
 while changed:
  changed=False;edges=collections.defaultdict(list)
  for i,row in enumerate(rows):
   for j,p in enumerate(row['p']):edges[tuple(sorted((tuple(round(x,5)for x in p),tuple(round(x,5)for x in row['p'][(j+1)%len(row['p'])]))))].append(i)
  used=set();merged=[]
  for indices in edges.values():
   if len(indices)!=2:continue
   i,j=indices
   if i in used or j in used:continue
   first,second=rows[i],rows[j];points=hull(first['p']+second['p'],first['n']);total=first['a']+second['a']
   if len(points)>4 or abs(area(points)-total)>max(.00001,total*.0001):continue
   merged.append({'p':points,'n':first['n'],'a':total,'material':[(first['material'][k]*first['a']+second['material'][k]*second['a'])/total for k in range(3)]});used.update((i,j));changed=True
  rows=[r for i,r in enumerate(rows)if i not in used]+merged
 polygons+=rows
polygons=[r for r in polygons if r['a']>=.025];polygons.sort(key=lambda r:r['a'],reverse=True)
retained=sum(r['a']for r in polygons);assert retained/sourceArea>.9
print('material polygons',len(polygons),'source glass triangles omitted',omitted,'area coverage',retained/sourceArea)
rows=[]
for r in polygons:
 p=r['p'];p=p+[p[-1]]if len(p)==3 else p;values=[*r['n'],*r['material'],*[v for point in p for v in point]];rows.append('{'+','.join(format(x,'.8g')for x in values)+'}')
prefix='require "ProjectYakuzaPhoneDev/PhoneMath"\nrequire "ISUI/ISPanel"\nlocal D=ProjectYakuza.PhoneDev\nlocal M=D.Math\nlocal Material=ISPanel:derive("ProjectYakuzaPhoneDevMaterial")\nD.Material=Material\nMaterial.faces={\n'+',\n'.join(rows)+'}\n'
body=(ROOT/'tools/combat-tests/phone-material-runtime.lua').read_text()
output=MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/PhoneMaterial.lua'
if validate:assert output.read_text()==prefix+body
else:output.write_text(prefix+body,newline='\n')
report={'modelSha256':source['modelSource']['sha256'],'sourceMaterialMaps':records,'sourceTriangles':len(source['faces']),'screenTrianglesOmitted':omitted,'lightingPolygons':len(polygons),'retainedCasingAreaFraction':retained/sourceArea,'runtimeSha256':hashlib.sha256((prefix+body).encode()).hexdigest(),'operation':'Lighting overlays only. Original coplanar adjacent source triangles merge into convex polygons only when their union area is unchanged. No source mesh, normals, UVs or diffuse pixels change. Original m/n maps supply bounded material-response weights; this is an adaptation rather than the original engine shader. Fully screen-covered faces and subpixel patches are omitted. The native model retains all source geometry.'}
p=MOD/'docs/material-source.json'
if validate:assert json.loads(p.read_text())==report
else:p.write_text(json.dumps(report,indent=2)+'\n',newline='\n')
