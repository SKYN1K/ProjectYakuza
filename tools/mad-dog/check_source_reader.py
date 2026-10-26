"""Independent check against GMTImporter, with linear key sampling and planar root removed."""
import bpy,sys,types,importlib.util,bisect,json,argparse
from pathlib import Path
from mathutils import Matrix,Quaternion,Vector
p=argparse.ArgumentParser()
for key in ['sources','gmd','gmd-importer','gmt-importer']:p.add_argument('--'+key,type=Path,required=True)
a=p.parse_args(sys.argv[sys.argv.index('--')+1:])
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(a.gmd_importer))
import yk_gmd_blender
yk_gmd_blender.register()
spec=importlib.util.spec_from_file_location('probe_gmt',a.gmt_importer/'__init__.py',submodule_search_locations=[str(a.gmt_importer)]);m=importlib.util.module_from_spec(spec);sys.modules[spec.name]=m;spec.loader.exec_module(m)
from probe_gmt.blender.importer import GMTImporter
from probe_gmt.read_gmd import read_gmd_bones
from probe_gmt.gmt_lib import read_gmt
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gmd_skinned(filepath=str(a.gmd),strict=False,logging_categories='')
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE');bpy.context.view_layer.objects.active=rig;rig.select_set(True)
bones=read_gmd_bones(str(a.gmd))
def q(v):return Quaternion((v[3],v[0],v[1],v[2])).normalized()
def eval_key(c,t,default,rot=False):
 if not c or not c.keyframes:return default.copy()
 c.fill_channels();keys=c.keyframes;i=max(0,bisect.bisect_right([x.frame for x in keys],t)-1);f=q if rot else Vector;x=f(keys[i].value)
 if i+1==len(keys) or t<=keys[i].frame:return x
 y=f(keys[i+1].value);factor=(t-keys[i].frame)/(keys[i+1].frame-keys[i].frame)
 return x.slerp(y,factor) if rot else x.lerp(y,factor)
conversion=Matrix(((-1,0,0),(0,0,1),(0,1,0)))
manifest=json.loads((ROOT/'styles/ProjectYakuzaMadDog/docs/motion-provenance.json').read_text());worst=0;checks=0
names=['center_c_n','ketu_c_n','mune_c_n','ude1_l_n','ude1_r_n','ude2_l_n','ude2_r_n','ude3_l_n','ude3_r_n','asi1_l_n','asi1_r_n','asi2_l_n','asi2_r_n','asi3_l_n','asi3_r_n','face_c_n']
for clip in manifest['clips']:
 path=a.sources/clip['source'];original=read_gmt(str(path)).animation
 GMTImporter(bpy.context,str(path),{'merge_vector_curves':True,'is_auth':False,'import_as_path':False}).read()
 for fc in rig.animation_data.action.fcurves:
  for key in fc.keyframe_points:key.interpolation='LINEAR'
 for t in range(original.end_frame+1):
  bpy.context.scene.frame_set(t);world={}
  for b in bones:
   keys=original.bones.get(b.name);rot=eval_key(keys.rotation if keys else None,t,q(b.local_rot),True);pos=eval_key(keys.location if keys else None,t,Vector(b.local_pos[:3]));mat=Matrix.LocRotScale(pos,rot,Vector((1,1,1)))
   world[b.name]=(world[bones[b.parent_index].name] if b.parent_index>=0 else Matrix.Identity(4)) @ mat
  for n in names:
   raw_root=conversion @ world['center_c_n'].translation
   imported_root=rig.pose.bones['center_c_n'].matrix.translation
   raw_relative=conversion @ (world[n].translation-world['center_c_n'].translation)
   imported_relative=rig.pose.bones[n].matrix.translation-imported_root
   error=max((raw_relative-imported_relative).length,abs(raw_root.z-imported_root.z))
   worst=max(worst,error);checks+=1
   if error>.0001:raise AssertionError((clip['name'],t,n,error))
print('SOURCE_READER_PASS',checks,'in-place original joint samples/root heights agree with GMTImporter; max error',worst)
