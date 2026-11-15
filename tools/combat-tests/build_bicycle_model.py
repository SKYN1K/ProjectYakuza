from pathlib import Path
import sys,types,json,hashlib,re
from mathutils import Matrix,Vector

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';validate='--validate'in sys.argv
package=types.ModuleType('yk_gmd_blender');package.__path__=[str(root/'tools/vendor-yk-gmd-073/yk_gmd_blender')];sys.modules['yk_gmd_blender']=package
from yk_gmd_blender.gmdlib.io import read_gmd_structures,read_abstract_scene_from_filedata_object
from yk_gmd_blender.gmdlib.converters.common.to_abstract import FileImportMode,VertexImportMode
from yk_gmd_blender.gmdlib.errors.error_reporter import LenientErrorReporter
sys.path.insert(0,str(Path(__file__).parent))
source=root/'extracted/bicycle-model-y6-0112/bik2020_bicycle_b.gmd';error=LenientErrorReporter({});v,h,f=read_gmd_structures(source,error);scene=read_abstract_scene_from_filedata_object(v,FileImportMode.UNSKINNED,VertexImportMode.IMPORT_VERTICES,f,error);transforms={};nodes=[]
for node in scene.overall_hierarchy:
    local=Matrix.Translation(node.pos.xyz)@node.rot.to_matrix().to_4x4()@Matrix.Diagonal((*node.scale.xyz,1));transforms[node.name]=transforms[node.parent.name]@local if node.parent else local
    if node.name.startswith('[l2]')and getattr(node,'mesh_list',[]):nodes.append(node)
anchor=transforms['rhpos'].translation;left=transforms['lhpos'].translation;verts=[];normals=[];uv=[];faces=[];parts=[]
for node in nodes:
    transform=transforms[node.name];normalTransform=transform.to_3x3().inverted().transposed()
    for mesh in node.mesh_list:
        assert mesh.attribute_set.texture_diffuse=='r_oj_bicy_b00_tt_d';offset=len(verts);data=mesh.vertices_data;verts.extend(tuple(transform@Vector(tuple(p))-anchor)for p in data.pos);normals.extend(tuple((normalTransform@Vector(tuple(n[:3]))).normalized())for n in data.normal);uv.extend(tuple(p)for p in data.uvs[0]);faces.extend(tuple(offset+i for i in mesh.triangles.triangle_list[k:k+3])for k in range(0,len(mesh.triangles.triangle_list),3));parts.append({'node':node.name,'vertices':len(data.pos),'triangles':len(mesh.triangles.triangle_list)//3})
points=[Vector(p)for p in verts];rightIndex=min(range(len(points)),key=lambda i:points[i].length_squared);leftIndex=min(range(len(points)),key=lambda i:(points[i]-(left-anchor)).length_squared);direction=(points[leftIndex]-points[rightIndex]).normalized();farIndex=max(range(len(points)),key=lambda i:(points[i]-points[rightIndex]).dot(direction));indices=[rightIndex,leftIndex,farIndex]

def array(rows,fmt):return ',\n'.join(fmt(row)for row in rows)+';'
body='xof 0303txt 0032\nMesh Bicycle {\n'+str(len(verts))+';\n'+array(verts,lambda p:';'.join(f'{x:.9f}'for x in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\nMeshNormals {\n'+str(len(normals))+';\n'+array(normals,lambda p:';'.join(f'{x:.9f}'for x in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\n}\nMeshTextureCoords {\n'+str(len(uv))+';\n'+array(uv,lambda p:f'{p[0]:.9f};{1-p[1]:.9f};')+'\n}\nMeshMaterialList {\n1;\n'+str(len(faces))+';\n'+','.join('0'for _ in faces)+';\nMaterial {1;1;1;1;;\n1;\n0;0;0;;\n0;0;0;;\nTextureFilename {"ProjectYakuza_Bicycle.png";}\n}\n}\n}\n'
output=mod/'42/media/models_X/Static/ProjectYakuza_Bicycle.x'
if validate:assert output.read_text()==body
else:output.write_text(body,encoding='utf-8')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
worldAttachment=[(min(p[k]for p in verts)+max(p[k]for p in verts))/2 if k!=1 else min(p[k]for p in verts)for k in range(3)];script=mod/'42/media/scripts/ProjectYakuza_Bicycle.txt';original=script.read_text();updated=original.replace('Bicycle (Yakuza 5)','Bicycle (Yakuza 6)');updated=re.sub(r'(attachment world\s*\{\s*offset = )[^,]+',lambda m:m[1]+' '.join(format(v,'.12g')for v in worldAttachment),updated)
if validate:assert original==updated
else:script.write_text(updated)
report={'source':str(source),'sourceSha256':sha(source),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'sourceParts':parts,'sourceAnchor':list(anchor),'sourceLeftHand':list(left),'worldAttachment':worldAttachment,'provenance':[{'path':str(p),'sha256':sha(p)}for p in [Path(__file__),Path(__file__).with_name('extract_y6_bicycle_model.py')]],'vertices':verts,'normals':normals,'uv':uv,'faces':faces,'gripRailVertexIndices':indices,'operation':'Original supplied Y6 bicycle B. All nine original lowest-detail l2 parts combined with original triangles, normals and UVs. No topology synthesis or LOD mixing. Original hierarchy transforms baked and original rhpos rebased to the held origin. Grip rail uses mesh vertices nearest original rhpos/lhpos plus the farthest continuation. Whole object is rigid while carried; individual wheel/pedal physics fragments are not recreated.','archiveEntries':json.loads((source.parent/'index.json').read_text())}

path=mod/'docs/bicycle-model-assets.json'
if validate:assert json.loads(path.read_text())==json.loads(json.dumps(report,default=lambda v:v.item()))
else:path.write_text(json.dumps(report,indent=2,default=lambda v:v.item())+'\n')
print('PASS original Y6 bicycle B:',len(verts),'vertices,',len(faces),'triangles; no generated geometry')
