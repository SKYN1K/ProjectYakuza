from pathlib import Path
import sys,types,json,hashlib
from mathutils import Matrix,Vector

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';validate='--validate'in sys.argv
package=types.ModuleType('yk_gmd_blender');package.__path__=[str(root/'tools/vendor-yk-gmd-073/yk_gmd_blender')];sys.modules['yk_gmd_blender']=package
from yk_gmd_blender.gmdlib.io import read_gmd_structures,read_abstract_scene_from_filedata_object
from yk_gmd_blender.gmdlib.converters.common.to_abstract import FileImportMode,VertexImportMode
from yk_gmd_blender.gmdlib.errors.error_reporter import LenientErrorReporter
sys.path.insert(0,str(Path(__file__).parent))
from y5_retarget import read_gmt
source=root/'extracted/bicycle-heat-097/models/wemap0006_bicycle_low.gmd';error=LenientErrorReporter({});v,h,f=read_gmd_structures(source,error);scene=read_abstract_scene_from_filedata_object(v,FileImportMode.UNSKINNED,VertexImportMode.IMPORT_VERTICES,f,error)
nodes=[n for n in scene.overall_hierarchy if getattr(n,'mesh_list',[])];assert len(nodes)==1;node=nodes[0];mesh=node.mesh_list[0];assert mesh.attribute_set.texture_diffuse=='s_bsom_bicycle_blue_d'
data=mesh.vertices_data;motion=read_gmt(str(root/'extracted/bicycle-heat-097/h11010_jitensha/000.par/h11010_000_7.gmt')).animation;curve=motion.bones['rhpos001'].location;curve.fill_channels();anchor=Vector(curve.keyframes[0].value)
verts=[tuple(Vector(tuple(p))-anchor)for p in data.pos];normals=[tuple(p[:3])for p in data.normal];uv=[tuple(v)for v in data.uvs[0]];faces=[tuple(mesh.triangles.triangle_list[i:i+3])for i in range(0,len(mesh.triangles.triangle_list),3)]
def array(rows,fmt):return ',\n'.join(fmt(row)for row in rows)+';'
body='xof 0303txt 0032\nMesh Bicycle {\n'+str(len(verts))+';\n'+array(verts,lambda p:';'.join(f'{x:.9f}'for x in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\nMeshNormals {\n'+str(len(normals))+';\n'+array(normals,lambda p:';'.join(f'{x:.9f}'for x in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\n}\nMeshTextureCoords {\n'+str(len(uv))+';\n'+array(uv,lambda p:f'{p[0]:.9f};{1-p[1]:.9f};')+'\n}\nMeshMaterialList {\n1;\n'+str(len(faces))+';\n'+','.join('0'for _ in faces)+';\nMaterial {1;1;1;1;;\n1;\n0;0;0;;\n0;0;0;;\nTextureFilename {"ProjectYakuza_Bicycle.png";}\n}\n}\n}\n'
output=mod/'42/media/models_X/Static/ProjectYakuza_Bicycle.x'
if validate:assert output.read_text()==body
else:output.write_text(body,encoding='utf-8')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report={'source':str(source),'sourceSha256':sha(source),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'sourceNode':node.name,'sourceAnchor':list(anchor),'vertices':verts,'normals':normals,'uv':uv,'faces':faces,'operation':'Original supplied Y5 low-detail bicycle, 397 vertices and 250 triangles. No topology edits. Original normals/UVs retained; rebase to original right-hand attachment. Whole-bicycle source motion drives the static low-detail model; individual wheel/pedal animation and physics fragments are not recreated.','archiveEntries':json.loads((source.parent/'index.json').read_text())}
path=mod/'docs/bicycle-model-assets.json'
if validate:assert json.loads(path.read_text())==json.loads(json.dumps(report,default=lambda v:v.item()))
else:path.write_text(json.dumps(report,indent=2,default=lambda v:v.item())+'\n')
print('PASS original Y5 bicycle:',len(verts),'vertices,',len(faces),'triangles; no generated geometry')
