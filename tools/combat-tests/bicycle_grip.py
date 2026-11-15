import bisect
from mathutils import Matrix,Vector
from mathutils.geometry import closest_point_on_tri
from native_body_geometry import skin_part

def palm_offsets(body,pose):
    result={}
    for side in ['R','L']:
        name='Bip01_'+side+'_Hand';points=skin_part(body,pose,[name]);assert points;result[side]=pose[name].inverted()@(sum(points,Vector())/len(points))
    return result

def grip_rail(model):
    vertices=[Vector(p)for p in model['vertices']];triangles=[tuple(vertices[i]for i in face)for face in model['faces']];indices=model['gripRailVertexIndices'];guides=[vertices[i]for i in indices];anchor=guides[0];samples=[]
    for a,b in zip(guides,guides[1:]):
        for i in range(129):
            point=a.lerp(b,i/128);point=min((closest_point_on_tri(point,*triangle)for triangle in triangles),key=lambda p:(p-point).length_squared);radius=(point-anchor).length
            if not samples or radius>samples[-1][0]+.000001:samples.append((radius,point))
    return {'anchor':anchor,'samples':samples,'radii':[r for r,_ in samples],'indices':indices,'triangles':triangles}

def rail_point(rail,radius):
    samples=rail['samples'];index=bisect.bisect_left(rail['radii'],radius)
    if index==0:preferred=samples[0][1].copy()
    elif index==len(samples):preferred=samples[-1][1].copy()
    else:
        a,p=samples[index-1];b,q=samples[index];preferred=p.lerp(q,(radius-a)/(b-a))
    anchor=rail['anchor'];candidates=[]
    for triangle in rail['triangles']:
        a,b,c=triangle;normal=(b-a).cross(c-a)
        if normal.length_squared<1e-16:continue
        normal.normalize();distance=(anchor-a).dot(normal);square=radius*radius-distance*distance
        if square<0:continue
        centre=anchor-normal*distance;direction=preferred-centre;direction-=normal*direction.dot(normal)
        if direction.length_squared>1e-16:
            point=centre+direction.normalized()*square**.5
            if (point-closest_point_on_tri(point,*triangle)).length<1e-6:candidates.append(point)
        for start,end in [(a,b),(b,c),(c,a)]:
            edge=end-start;relative=start-anchor;aa=edge.length_squared
            if aa<1e-16:continue
            bb=2*relative.dot(edge);cc=relative.length_squared-radius*radius;discriminant=bb*bb-4*aa*cc
            if discriminant<0:continue
            for t in [(-bb-discriminant**.5)/(2*aa),(-bb+discriminant**.5)/(2*aa)]:
                if 0<=t<=1:candidates.append(start+edge*t)
    return min(candidates,key=lambda p:(p-preferred).length_squared)if candidates else preferred

def fit_prop(pose,seed,palms,rail,scale,weight=1,normal=None):
    right=pose['Bip01_R_Hand']@palms['R'];left=pose['Bip01_L_Hand']@palms['L'];axis=left-right;point=rail_point(rail,axis.length/scale);localAxis=point-rail['anchor'];rotation=seed.to_quaternion().normalized()
    if axis.length>.001 and localAxis.length>.001:
        aligned=(rotation@localAxis).rotation_difference(axis)@rotation;rotation=rotation.slerp(aligned,weight).normalized()
        if normal is not None:
            u=axis.normalized();v=normal-u*normal.dot(u);localU=localAxis.normalized();localV=Vector((1,0,0))-localU*localU.x
            if v.length>.05 and localV.length>.05:
                v.normalize();localV.normalize();target=Matrix((u,v,u.cross(v))).transposed();source=Matrix((localU,localV,localU.cross(localV))).transposed();rotation=(target@source.transposed()).to_quaternion().normalized()
    result=rotation.to_matrix().to_4x4();result.translation=right-rotation@(rail['anchor']*scale)
    return result,{'right':right,'left':left,'modelRight':rail['anchor'].copy(),'modelLeft':point,'leftWeight':weight}
