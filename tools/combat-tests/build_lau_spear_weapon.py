from pathlib import Path
import hashlib,json,re,sys,types
from mathutils import Matrix,Vector

root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';validate='--validate'in sys.argv
package=types.ModuleType('yk_gmd_blender');package.__path__=[str(root/'tools/vendor-yk-gmd-073/yk_gmd_blender')];sys.modules['yk_gmd_blender']=package
from yk_gmd_blender.gmdlib.io import read_gmd_structures,read_abstract_scene_from_filedata_object
from yk_gmd_blender.gmdlib.converters.common.to_abstract import FileImportMode,VertexImportMode
from yk_gmd_blender.gmdlib.errors.error_reporter import LenientErrorReporter
sys.path.insert(0,str(Path(__file__).parent))
from y5_source_assets import entry
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/reactorpar/reactor_w64.par');work=root/'extracted/lau-spear-weapon';work.mkdir(exist_ok=True)
source=work/'wecim7210_spr_rhau.gmd';raw,modelSource=entry(archive,source.name);source.write_bytes(raw);diffuse,textureSource=entry(archive,'o_ayam_spr_rhau_d.dds');(work/'o_ayam_spr_rhau_d.dds').write_bytes(diffuse)
error=LenientErrorReporter({});version,header,filedata=read_gmd_structures(source,error);scene=read_abstract_scene_from_filedata_object(version,FileImportMode.UNSKINNED,VertexImportMode.IMPORT_VERTICES,filedata,error)
transforms={};vertices=[];normals=[];uv=[];faces=[];parts=[]
for node in scene.overall_hierarchy:
    local=Matrix.Translation(node.pos.xyz)@node.rot.to_matrix().to_4x4()@Matrix.Diagonal((*node.scale.xyz,1));transform=transforms[node.parent.name]@local if node.parent else local;transforms[node.name]=transform
    for mesh in getattr(node,'mesh_list',[]):
        assert mesh.attribute_set.texture_diffuse=='o_ayam_spr_rhau_d';data=mesh.vertices_data;first=len(vertices);normal=transform.to_3x3().inverted().transposed()
        vertices.extend(tuple(transform@Vector(tuple(p[:3])))for p in data.pos);normals.extend(tuple((normal@Vector(tuple(n[:3]))).normalized())for n in data.normal);uv.extend(tuple(p)for p in data.uvs[0]);faces.extend(tuple(first+i for i in mesh.triangles.triangle_list[k:k+3])for k in range(0,len(mesh.triangles.triangle_list),3));parts.append({'node':node.name,'vertices':len(data.pos),'triangles':len(mesh.triangles.triangle_list)//3})
reference=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/weapons/2handed/SpearCrafted.x');text=reference.read_text();match=re.search(r'\bMesh\s+\w*\s*\{\s*(\d+);',text);points=[tuple(map(float,p))for p in re.findall(r'([-+\d.eE]+);\s*([-+\d.eE]+);\s*([-+\d.eE]+);',text[match.end():])[:int(match[1])]]
nativeMin=min(p[1]for p in points);nativeMax=max(p[1]for p in points);sourceMin=min(p[1]for p in vertices);sourceMax=max(p[1]for p in vertices);scale=(nativeMax-nativeMin)/(sourceMax-sourceMin);offset=nativeMin-sourceMin*scale
original=vertices;vertices=[(x*scale,y*scale+offset,z*scale)for x,y,z in original]
assert len(vertices)==605 and len(faces)==621 and abs(min(p[1]for p in vertices)-nativeMin)<1e-8 and abs(max(p[1]for p in vertices)-nativeMax)<1e-8
def array(rows,fmt):return ',\n'.join(fmt(row)for row in rows)+';'
body='xof 0303txt 0032\nMesh LauSpear {\n'+str(len(vertices))+';\n'+array(vertices,lambda p:';'.join(f'{v:.9f}'for v in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda p:'3;'+','.join(map(str,p))+';')+'\nMeshNormals {\n'+str(len(normals))+';\n'+array(normals,lambda p:';'.join(f'{v:.9f}'for v in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda p:'3;'+','.join(map(str,p))+';')+'\n}\nMeshTextureCoords {\n'+str(len(uv))+';\n'+array(uv,lambda p:f'{p[0]:.9f};{1-p[1]:.9f};')+'\n}\nMeshMaterialList {\n1;\n'+str(len(faces))+';\n'+','.join('0'for _ in faces)+';\nMaterial {1;1;1;1;;\n1;\n0;0;0;;\n0;0;0;;\nTextureFilename {"ProjectYakuza_LauSpear.png";}\n}\n}\n}\n'
output=mod/'42/media/models_X/Static/ProjectYakuza_LauSpear.x'
if validate:assert output.read_bytes()==body.encode()
else:output.write_bytes(body.encode())
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report={'operation':'Original Kiwami Lau Ka Long spear grip and blade, combined without topology changes. Source hierarchy transforms, normals and UVs retained. A single uniform scale and shaft translation match native SpearCrafted butt/tip coordinates, native two-hand grips and the standalone emote fallback. Original diffuse decoded separately. No generated geometry, animation or sounds.','modelSource':modelSource,'textureSource':textureSource,'nativeReference':{'path':str(reference),'sha256':sha(reference),'boundsY':[nativeMin,nativeMax]},'scale':scale,'offsetY':offset,'sourceParts':parts,'vertices':len(vertices),'triangles':len(faces),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'sourceVertices':original,'outputVertices':vertices,'normals':normals,'uv':uv,'faces':faces}
manifest=mod/'docs/lau-spear-weapon-model.json'
if validate:assert json.loads(manifest.read_text())==json.loads(json.dumps(report,default=lambda v:v.item()))
else:manifest.write_text(json.dumps(report,indent=2,default=lambda v:v.item())+'\n')
print('PASS original Kiwami Lau spear: 605 vertices, 621 triangles, retained source normals/UVs, uniform native spear fit and exact source entry hashes')
