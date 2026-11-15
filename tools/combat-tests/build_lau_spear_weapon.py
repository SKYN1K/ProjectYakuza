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
from spear_uv_tiles import split_tiles
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza 3/data/reactive_obj/object_hires.par');work=root/'extracted/lau-spear-weapon';work.mkdir(exist_ok=True)
source=work/'o_ay_spear_rhau.gmd';raw,modelSource=entry(archive,source.name);source.write_bytes(raw);diffuse,textureSource=entry(archive,'o_ay_spear_rhau_d.dds');(work/'o_ay_spear_rhau_d.dds').write_bytes(diffuse)
error=LenientErrorReporter({});version,header,filedata=read_gmd_structures(source,error);scene=read_abstract_scene_from_filedata_object(version,FileImportMode.UNSKINNED,VertexImportMode.IMPORT_VERTICES,filedata,error)
transforms={};vertices=[];normals=[];uv=[];faces=[];parts=[]
for node in scene.overall_hierarchy:
    local=Matrix.Translation(node.pos.xyz)@node.rot.to_matrix().to_4x4()@Matrix.Diagonal((*node.scale.xyz,1));transform=transforms[node.parent.name]@local if node.parent else local;transforms[node.name]=transform
    for mesh in getattr(node,'mesh_list',[]):
        assert mesh.attribute_set.texture_diffuse=='o_ay_spear_rhau_d';data=mesh.vertices_data;first=len(vertices);normal=transform.to_3x3().inverted().transposed()
        vertices.extend(tuple(transform@Vector(tuple(p[:3])))for p in data.pos);normals.extend(tuple((normal@Vector(tuple(n[:3]))).normalized())for n in data.normal);uv.extend(tuple(p)for p in data.uvs[0]);faces.extend(tuple(first+i for i in mesh.triangles.triangle_list[k:k+3])for k in range(0,len(mesh.triangles.triangle_list),3));parts.append({'node':node.name,'vertices':len(data.pos),'triangles':len(mesh.triangles.triangle_list)//3})
reference=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/weapons/2handed/SpearCrafted.x');text=reference.read_text();match=re.search(r'\bMesh\s+\w*\s*\{\s*(\d+);',text);points=[tuple(map(float,p))for p in re.findall(r'([-+\d.eE]+);\s*([-+\d.eE]+);\s*([-+\d.eE]+);',text[match.end():])[:int(match[1])]]
nativeMin=min(p[1]for p in points);nativeMax=max(p[1]for p in points);sourceMin=min(p[1]for p in vertices);sourceMax=max(p[1]for p in vertices);scale=(nativeMax-nativeMin)/(sourceMax-sourceMin);offset=nativeMin-sourceMin*scale
original=vertices;vertices=[(x*scale,y*scale+offset,z*scale)for x,y,z in original]
assert len(vertices)==605 and len(faces)==621 and abs(min(p[1]for p in vertices)-nativeMin)<1e-8 and abs(max(p[1]for p in vertices)-nativeMax)<1e-8
sourceOutputVertices=vertices;sourceNormals=normals;sourceUV=uv;sourceFaces=faces
partition=split_tiles(vertices,normals,uv,faces)
vertices=partition['vertices'];normals=partition['normals'];uv=partition['uv'];faces=partition['faces']

def array(rows,fmt):return ',\n'.join(fmt(row)for row in rows)+';'
body='xof 0303txt 0032\nMesh LauSpear {\n'+str(len(vertices))+';\n'+array(vertices,lambda p:';'.join(f'{v:.9f}'for v in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda p:'3;'+','.join(map(str,p))+';')+'\nMeshNormals {\n'+str(len(normals))+';\n'+array(normals,lambda p:';'.join(f'{v:.9f}'for v in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda p:'3;'+','.join(map(str,p))+';')+'\n}\nMeshTextureCoords {\n'+str(len(uv))+';\n'+array(uv,lambda p:f'{p[0]:.9f};{p[1]:.9f};')+'\n}\nMeshMaterialList {\n1;\n'+str(len(faces))+';\n'+','.join('0'for _ in faces)+';\nMaterial {1;1;1;1;;\n1;\n0;0;0;;\n0;0;0;;\nTextureFilename {"ProjectYakuza_LauSpear.png";}\n}\n}\n}\n'
output=mod/'42/media/models_X/Static/ProjectYakuza_LauSpear.x'
if validate:assert output.read_bytes()==body.encode()
else:output.write_bytes(body.encode())
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report={'operation':'Original Yakuza 3 Lau spear matching the supplied reference. Original blade and shaft surfaces are partitioned only at original repeating-UV tile boundaries. Barycentric interpolation preserves position and normals; per-source-face areas remain unchanged. Coordinates map into a source-only 510-pixel interior with one-pixel wrapped border, remaining strictly within the 512 texture under PZ blood/tint edge clamping. Original source UV orientation, native spear hand/world calibration and item balance are retained. No new shape, painted texels, animation, voice or synthesized assets.','modelSource':modelSource,'textureSource':textureSource,'nativeReference':{'path':str(reference),'sha256':sha(reference),'boundsY':[nativeMin,nativeMax]},'scale':scale,'offsetY':offset,'sourceParts':parts,'sourceVertexCount':len(original),'sourceTriangleCount':len(sourceFaces),'vertices':len(vertices),'triangles':len(faces),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'sourceVertices':original,'sourceOutputVertices':sourceOutputVertices,'sourceNormals':sourceNormals,'sourceUV':sourceUV,'sourceFaces':sourceFaces,'surfacePartition':{'origins':partition['origins'],'sourceAreas':partition['sourceAreas'],'interior':510,'border':1},'outputVertices':vertices,'normals':normals,'uv':uv,'faces':faces}
manifest=mod/'docs/lau-spear-weapon-model.json'
if validate:assert json.loads(manifest.read_text())==json.loads(json.dumps(report,default=lambda v:v.item()))
else:manifest.write_text(json.dumps(report,indent=2,default=lambda v:v.item())+'\n')
(Path(__file__).parent/'lau-spear-uv.tsv').write_text('\n'.join('\t'.join(str(float(v))for v in [*p,*t])for p,t in zip(vertices,uv)))
print('PASS original Yakuza 3 Lau spear:',len(sourceFaces),'source triangles,',len(faces),'area-preserving tile triangles,',len(vertices),'vertices and strictly interior UVs; native hand/world fit retained')
