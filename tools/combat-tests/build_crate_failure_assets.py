from pathlib import Path
import sys,types,json,hashlib,math
from mathutils import Matrix,Vector
r=Path(__file__).resolve().parents[2];validate='--validate'in sys.argv;m=r/'combat/ProjectYakuza';p=types.ModuleType('yk_gmd_blender');p.__path__=[str(r/'tools/vendor-yk-gmd-073/yk_gmd_blender')];sys.modules['yk_gmd_blender']=p
from yk_gmd_blender.gmdlib.io import read_gmd_structures,read_abstract_scene_from_filedata_object
from yk_gmd_blender.gmdlib.converters.common.to_abstract import FileImportMode,VertexImportMode
from yk_gmd_blender.gmdlib.errors.error_reporter import LenientErrorReporter
src=r/'extracted/beer-crate-073/stg0010_beercase_a_na.gmd';error=LenientErrorReporter({});v,h,f=read_gmd_structures(src,error);scene=read_abstract_scene_from_filedata_object(v,FileImportMode.UNSKINNED,VertexImportMode.IMPORT_VERTICES,f,error)
transforms={}
for n in scene.overall_hierarchy:
 local=Matrix.Translation(n.pos.xyz)@n.rot.to_matrix().to_4x4()@Matrix.Diagonal((*n.scale.xyz,1));transforms[n.name]=(transforms[n.parent.name]@local if n.parent else local)
node=next(n for n in scene.overall_hierarchy if n.name=='[l0][normal]0');assert len(node.mesh_list)==1;mesh=node.mesh_list[0];assert mesh.attribute_set.texture_diffuse=='r_pl_beercase1_na_d';data=mesh.vertices_data;matrix=transforms[node.name];hand=transforms['rhpos'].translation
verts=[tuple(matrix@Vector(tuple(p))-hand)for p in data.pos];normals=[tuple((matrix.to_3x3()@Vector(tuple(p[:3]))).normalized())for p in data.normal];uv=[tuple(v)for v in data.uvs[0]];faces=[tuple(mesh.triangles.triangle_list[i:i+3])for i in range(0,len(mesh.triangles.triangle_list),3)]
print('CRATE',len(verts),len(faces),'hand',list(hand),'bounds',[(min(p[i]for p in verts),max(p[i]for p in verts))for i in range(3)])
out=m/'42/media/models_X/Static/ProjectYakuza_BeerCrate.x';texture='ProjectYakuza_BeerCrate.png'
def array(rows,fmt):return ',\n'.join(fmt(row)for row in rows)+';'
body='xof 0303txt 0032\nMesh BeerCrate {\n'+str(len(verts))+';\n'+array(verts,lambda p:';'.join(f'{x:.9f}'for x in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\nMeshNormals {\n'+str(len(normals))+';\n'+array(normals,lambda p:';'.join(f'{x:.9f}'for x in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\n}\nMeshTextureCoords {\n'+str(len(uv))+';\n'+array(uv,lambda p:f'{p[0]:.9f};{1-p[1]:.9f};')+'\n}\nMeshMaterialList {\n1;\n'+str(len(faces))+';\n'+','.join('0'for _ in faces)+';\nMaterial {1;1;1;1;;\n1;\n0;0;0;;\n0;0;0;;\nTextureFilename {"'+texture+'";}\n}\n}\n}\n';None if validate else out.write_text(body,encoding='utf-8')
if validate:assert out.read_text(encoding='utf-8')==body, 'original crate mesh conversion differs'
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
report={'source':str(src),'sourceSha256':sha(src),'output':out.relative_to(m).as_posix(),'sha256':sha(out),'sourceNode':node.name,'vertices':verts,'normals':normals,'uv':uv,'faces':faces,'sourceHandAnchor':list(hand),'operation':'Original intact LOD0 mesh only; preserve topology, normals and UVs; rebase to original rhpos grip. Native model script sets game-unit scale and axis rotation. No generated geometry or artwork.','tool':'https://github.com/theturboturnip/yk_gmd_io','toolCredit':'Yakuza GMD IO by Samuel Stark (TheTurboTurnip)'}
if validate:
 expected=json.loads((m/'docs/beer-crate-assets.json').read_text());actual=json.loads(json.dumps(report,default=lambda v:v.item()));assert all(expected[k]==v for k,v in actual.items())
else:(m/'docs/beer-crate-assets.json').write_text(json.dumps(report,indent=2,default=lambda v:v.item())+'\n')
converter=(r/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/rush-failure-build'");name='ProjectYakuza_DD_HeatRushFail';source='E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack/gmt/P_KRU_BTL_SUD_bct_std_en.gmt';sys.argv=['convert','--',name,source];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_failure','exec'),ns)
sys.path.insert(0,str(r/'tools/combat-tests'));from locomotion_math import read,locals_at,blocks,write
raw=r/('tools/rush-failure-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,frames,anim,spans=read(raw);times=[i*160 for i in range(ns['a'].end_frame+1)];values=[locals_at(frames,anim,t)for t in times];grip=json.loads((m/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];dest=m/('42/media/anims_X/Bob/'+name+'.x');generated=r/'tools/rush-failure-validation.x'if validate else dest;write(generated,text,spans,blocks(frames,values,times,grip),name)
if validate:assert generated.read_bytes()==dest.read_bytes(),'failure clip differs from original retarget'
failure_report={'source':source,'sourceSha256':sha(source),'raw':str(raw),'rawSha256':sha(raw),'output':dest.relative_to(m).as_posix(),'sha256':sha(dest),'frames':len(times),'fps':30,'duration':ns['a'].end_frame/30,'nativeGrip':grip,'operation':'Full original Kiryu bct_std_en Extreme Heat exit/recovery motion, retargeted without invented poses. Used as a short rush-abort recovery; not labelled as an original Dragon Engine QTE-failure branch.'}
if validate:
 expected=json.loads((m/'docs/heat-rush-failure-assets.json').read_text());assert expected==failure_report
else:(m/'docs/heat-rush-failure-assets.json').write_text(json.dumps(failure_report,indent=2)+'\n')
print('PASS source crate topology/UV/grip and all original 21 failure-recovery frames unchanged')

