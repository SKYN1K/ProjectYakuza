import math

def split_tiles(positions,normals,uvs,triangles,interior=510,border=1):
    positions=[[float(v)for v in p]for p in positions];normals=[[float(v)for v in n]for n in normals];uvs=[[float(v)for v in uv]for uv in uvs]
    output=[];outNormals=[];outUV=[];faces=[];origins=[];lookup={};areas=[]
    def area(points):
        a,b,c=points;u=[b[i]-a[i]for i in range(3)];v=[c[i]-a[i]for i in range(3)];return math.sqrt(sum(x*x for x in [u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]))*.5
    for faceIndex,triangle in enumerate(triangles):
        points=[positions[i]for i in triangle];tex=[uvs[i]for i in triangle];normal=[normals[i]for i in triangle];total=0
        def coordinate(weights,axis):return sum(weights[i]*tex[i][axis]for i in range(3))
        limits=[(math.floor(min(t[k]for t in tex)),math.ceil(max(t[k]for t in tex))-1)for k in range(2)]
        for tileU in range(limits[0][0],max(limits[0])+1):
            for tileV in range(limits[1][0],max(limits[1])+1):
                polygon=[(1.,0.,0.),(0.,1.,0.),(0.,0.,1.)]
                for axis,bound,sign in [(0,tileU,1),(0,tileU+1,-1),(1,tileV,1),(1,tileV+1,-1)]:
                    clipped=[]
                    for previous,current in zip(polygon[-1:]+polygon[:-1],polygon):
                        a=(coordinate(previous,axis)-bound)*sign;b=(coordinate(current,axis)-bound)*sign
                        if (a>=-1e-10)!=(b>=-1e-10):
                            fraction=a/(a-b);clipped.append(tuple(previous[i]+fraction*(current[i]-previous[i])for i in range(3)))
                        if b>=-1e-10:clipped.append(current)
                    polygon=clipped
                    if len(polygon)<3:break
                for k in range(1,len(polygon)-1):
                    weights=[polygon[0],polygon[k],polygon[k+1]];vertices=[tuple(sum(w[i]*points[i][j]for i in range(3))for j in range(3))for w in weights];size=area(vertices)
                    if size<1e-14:continue
                    indices=[]
                    for w,p in zip(weights,vertices):
                        n=[sum(w[i]*normal[i][j]for i in range(3))for j in range(3)];length=math.sqrt(sum(v*v for v in n));n=tuple(v/length for v in n)
                        uv=[max(0,min(1,coordinate(w,j)-tile))*interior/(interior+2*border)+border/(interior+2*border)for j,tile in enumerate([tileU,tileV])]
                        key=tuple(round(v,10)for v in [*p,*n,*uv]);index=lookup.get(key)
                        if index is None:index=len(output);lookup[key]=index;output.append(p);outNormals.append(n);outUV.append(uv)
                        indices.append(index)
                    faces.append(indices);origins.append({'sourceFace':faceIndex,'tile':[tileU,tileV],'weights':weights});total+=size
        expected=area(points);assert abs(total-expected)<max(1e-10,expected*1e-6),(faceIndex,total,expected);areas.append(expected)
    return {'vertices':output,'normals':outNormals,'uv':outUV,'faces':faces,'origins':origins,'sourceAreas':areas,'interior':interior,'border':border}
