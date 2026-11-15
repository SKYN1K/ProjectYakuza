from pathlib import Path
import hashlib,json,math
from PIL import Image

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';report=json.loads((mod/'docs/lau-spear-weapon-model.json').read_text());texture=json.loads((mod/'docs/lau-spear-weapon-texture.json').read_text())
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(mod/report['output'])==report['sha256']and sha(mod/texture['output'])==texture['sha256']
assert report['sourceVertexCount']==605 and report['sourceTriangleCount']==621 and report['triangles']==721 and report['vertices']==736
assert all(1/512-1e-10<=v<=511/512+1e-10 for point in report['uv']for v in point)
def area(points):
    a,b,c=points;u=[b[k]-a[k]for k in range(3)];v=[c[k]-a[k]for k in range(3)];return math.sqrt(sum(x*x for x in [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]))*.5
accumulated=[0.]*621;sourceImage=Image.open(texture['source']).convert('RGBA');interior=sourceImage.resize((510,510),Image.Resampling.NEAREST);output=Image.open(mod/texture['output']).convert('RGBA');assert output.size==(512,512)and output.crop((1,1,511,511)).tobytes()==interior.tobytes()
for y in range(512):
    for x in [0,511]:assert output.getpixel((x,y))==interior.getpixel(((x-1)%510,(y-1)%510))
for x in range(512):
    for y in [0,511]:assert output.getpixel((x,y))==interior.getpixel(((x-1)%510,(y-1)%510))
def sample(image,uv,wrap):
    width,height=image.size;x,y=uv[0]*width-.5,uv[1]*height-.5;i,j=math.floor(x),math.floor(y);a,b=x-i,y-j;result=[0.]*4
    for dx,dy,weight in [(0,0,(1-a)*(1-b)),(1,0,a*(1-b)),(0,1,(1-a)*b),(1,1,a*b)]:
        p=((i+dx)%width,(j+dy)%height)if wrap else(max(0,min(width-1,i+dx)),max(0,min(height-1,j+dy)));pixel=image.getpixel(p)
        for k in range(4):result[k]+=pixel[k]*weight
    return result
worst=0.;oldWorst=0.;samples=0
for face,origin in zip(report['faces'],report['surfacePartition']['origins']):
    sourceFace=report['sourceFaces'][origin['sourceFace']];tile=origin['tile'];outPoints=[report['outputVertices'][i]for i in face];accumulated[origin['sourceFace']]+=area(outPoints)
    for index,weights in zip(face,origin['weights']):
        assert abs(sum(weights)-1)<1e-8 and all(-1e-9<=w<=1+1e-9 for w in weights)
        position=[sum(weights[i]*report['sourceOutputVertices'][sourceFace[i]][k]for i in range(3))for k in range(3)];normal=[sum(weights[i]*report['sourceNormals'][sourceFace[i]][k]for i in range(3))for k in range(3)];length=math.sqrt(sum(v*v for v in normal));normal=[v/length for v in normal]
        assert max(abs(a-b)for a,b in zip(position,report['outputVertices'][index]))<1e-8 and max(abs(a-b)for a,b in zip(normal,report['normals'][index]))<1e-8
        uv=[sum(weights[i]*report['sourceUV'][sourceFace[i]][k]for i in range(3))for k in range(2)];rebuilt=[(uv[k]-tile[k])*510/512+1/512 for k in range(2)]
        assert max(abs(a-b)for a,b in zip(rebuilt,report['uv'][index]))<1e-8
    for weights in [(1/3,1/3,1/3),(.02,.49,.49),(.49,.02,.49)]:
        normalized=[sum(weights[i]*report['uv'][face[i]][k]for i in range(3))for k in range(2)];sourceUV=[(normalized[k]*512-1)/510+tile[k]for k in range(2)];expected=sample(interior,sourceUV,True);actual=sample(output,normalized,False);broken=sample(interior,sourceUV,False);worst=max(worst,max(abs(a-b)for a,b in zip(expected,actual)));oldWorst=max(oldWorst,max(abs(a-b)for a,b in zip(expected,broken)));samples+=1
for i,face in enumerate(report['sourceFaces']):assert abs(accumulated[i]-area([report['sourceOutputVertices'][j]for j in face]))<1e-9
assert worst<1e-7 and oldWorst>20 and samples==2163
print('PASS 621 original surfaces preserved across 721 tile triangles; native positions/normals/barycentric source UVs, all source texels/borders and',samples,'bilinear edge-clamp samples; corrected maximum error',worst,'versus legacy clamp error',oldWorst)

