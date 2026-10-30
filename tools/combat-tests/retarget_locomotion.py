import sys,types,json,re,math
from pathlib import Path
import bpy
from mathutils import Matrix,Vector,Quaternion
ROOT=Path('C:\\Users\\Nik\\Documents\\Codex\\2026-10-19\\wo\\work')
DEST=Path('C:\\Users\\Nik\\Documents\\ChatGPT\\Zomboid Yakuza Combat')
OUT=DEST/'tools/locomotion-build'
GAME=Path(r'F:/SteamLibrary/steamapps/common/ProjectZomboid')
p=types.ModuleType('yk');p.__path__=[str(ROOT/'addons/yakuza_gmt_blender')];sys.modules['yk']=p
from yk.gmt_lib import read_gmt
from yk.read_gmd import read_gmd_bones
ANIMNAME=sys.argv[sys.argv.index('--')+1]
src=sys.argv[sys.argv.index('--')+2]
a=read_gmt(src).animation
sb=read_gmd_bones(r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd')
for b in a.bones.values():
 for c in b.curves:
  if int(c.type) in (0,1):c.fill_channels()
s=(GAME/'media/models_X/Skinned/MaleBody.x').read_text()
def endbrace(s,start):
 d=1;i=start+1
 while d:
  if s[i]=='{':d+=1
  if s[i]=='}':d-=1
  i+=1
 return i
frames={};stack=[]
for m in re.finditer(r'\bFrame\s+(\w+)\s*\{',s):
 end=endbrace(s,m.end()-1)
 while stack and stack[-1][1]<m.start():stack.pop()
 mm=re.match(r'\s*FrameTransformMatrix\s*\{([^}]+)',s[m.end():]);v=[float(n) for n in re.findall(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?',mm[1])]
 mat=Matrix([v[i:i+4] for i in range(0,16,4)]).transposed()
 frames[m[1]]={'parent':stack[-1][0] if stack else None,'local':mat}
 stack.append((m[1],end))
bind={n:Matrix(v['mat']) for n,v in json.loads((ROOT/'bind.json').read_text()).items()}
bind['Dummy01']=frames['Dummy01']['local']
bind['Bip01']=bind['Bip01_Pelvis']@frames['Bip01_Pelvis']['local'].inverted()
for n,f in frames.items():
 if n not in bind:bind[n]=(bind[f['parent']]@f['local']) if f['parent'] else f['local']
rest={n:(bind[f['parent']].inverted()@bind[n] if f['parent'] else bind[n]) for n,f in frames.items()}
mp={'Bip01':'ketu_c_n','Bip01_Pelvis':'ketu_c_n','Bip01_Spine':'kosi_c_n','Bip01_Spine1':'mune_c_n','Bip01_Neck':'kubi_c_n','Bip01_Head':'face_c_n'}
for side in ['L','R']:
 for t,u in [('Clavicle','kata'),('UpperArm','ude1'),('Forearm','ude2'),('Hand','ude3'),('Thigh','asi1'),('Calf','asi2'),('Foot','asi3'),('Toe0','asi4')]:mp['Bip01_'+side+'_'+t]=u+'_'+side.lower()+'_n'
C=Matrix.Diagonal((1,1,-1,1)); scale=bind['Bip01_Pelvis'].translation.y/1.14

def sample(c,f,default,rot=False):
 if c is None or not c.keyframes:return default.copy()
 ks=c.keyframes
 def val(k):return Quaternion((k.value[3],*k.value[:3])).normalized() if rot else Vector(k.value)
 if f<=ks[0].frame:return val(ks[0])
 for l,r in zip(ks,ks[1:]):
  if f<=r.frame:
   fac=(f-l.frame)/(r.frame-l.frame);return val(l).slerp(val(r),fac) if rot else val(l).lerp(val(r),fac)
 return val(ks[-1])
fist={}
punch=(GAME/'media/anims_X/Bob'/globals().get('FINGER_SOURCE','Bob_AttackBat01_Hit.x')).read_text()
for mm in re.finditer(r'Animation\s*\{\s*\{\s*(Bip01_[LR]_Finger[01])\s*\}',punch):
 block=punch[mm.end():endbrace(punch,mm.start()+mm[0].index('{'))]
 rr=re.search(r'AnimationKey R\s*\{\s*0;\s*\d+;\s*\d+;4;([^;]+)',block)
 if rr:
  w,x,y,z=map(float,rr[1].split(','));fist[mm[1]]=Quaternion((-w,x,y,z))
poses=[];srcposes=[]
for f in range(a.end_frame+1):
 sg={}
 for b in sb:
  ab=a.bones.get(b.name);loc=sample(ab.location if ab else None,f,Vector(b.local_pos[:3]));q=sample(ab.rotation if ab else None,f,Quaternion((b.local_rot[3],*b.local_rot[:3])),True)

  if b.name=='center_c_n':loc=Vector((0,0,0))
  local=Matrix.Translation(loc)@q.to_matrix().to_4x4();sg[b.name]=(sg[sb[b.parent_index].name]@local if b.parent_index>=0 else local)
 tg={}
 for n,d in frames.items():
  par=d['parent'];local=rest[n].copy()
  if n in mp:
   q=(C@sg[mp[n]]@C).to_quaternion();desired=q.to_matrix().to_4x4()@bind[n].to_quaternion().to_matrix().to_4x4()
   local=(tg[par].inverted()@desired) if par else desired
   local.translation=rest[n].translation
   if n=='Bip01':

    world=bind[n].translation.copy();world.y=sg['ketu_c_n'].translation.y*scale
    local.translation=(tg[par].inverted()@world) if par else world
  if n in fist:
   tr=local.translation.copy();local=fist[n].to_matrix().to_4x4();local.translation=tr
  tg[n]=(tg[par]@local) if par else local
 poses.append(tg);srcposes.append(sg)

header=s[:re.search(r'(?m)^Material\s+\w+',s).start()]
def fmtmat(m):return ','.join(f'{v:.9f}' for row in m.transposed() for v in row)+';;'
def frame_text(n,indent=''):
 t=indent+'Frame '+n+' {\n'+indent+' FrameTransformMatrix { '+fmtmat(rest[n])+' }\n'
 for ch,d in frames.items():
  if d['parent']==n:t+=frame_text(ch,indent+' ')
 return t+indent+'}\n'
x=header+"Material Y6_Default {\n 1.0;1.0;1.0;1.0;;\n 1.0;\n 0.0;0.0;0.0;;\n 0.0;0.0;0.0;;\n}\n"+''.join(frame_text(n) for n,d in frames.items() if not d['parent'])+"Mesh Y6_ImportSupport {\n3;\n0.0;0.0;0.0;,\n0.001;0.0;0.0;,\n0.0;0.001;0.0;;\n1;\n3;0,1,2;;\nMeshMaterialList {\n1;\n1;\n0;;\n{ Y6_Default }\n}\nXSkinMeshHeader { 1; 3; 1; }\nSkinWeights {\n\"Bip01\";\n3;\n0,1,2;\n1.0,1.0,1.0;\n1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0,0.0,0.0,0.0,0.0,1.0;;\n}\n}\n"+'AnimTicksPerSecond { 4800; }\nAnimationSet ProjectYakuza_DD_TigerDrop {\n'
for n,d in frames.items():
 if n=='Body':continue
 vals=[(p[d['parent']].inverted()@p[n]) if d['parent'] else p[n] for p in poses]
 x+=' Animation { { '+n+' }\n'
 for typ,label in [(0,'R'),(1,'S'),(2,'T')]:
  rows=[];last=None
  for f,m in enumerate(vals):
   if typ==0:
    q=m.to_quaternion().normalized()
    if last and q.dot(last)<0:q.negate()
    last=q.copy();v=(-q.w,q.x,q.y,q.z)
   elif typ==1:v=(1,1,1)
   else:v=tuple(m.translation)
   rows.append(str(f*160)+';'+str(len(v))+';'+','.join(f'{k:.9f}' for k in v)+';;')
  x+='  AnimationKey '+label+' { '+str(typ)+'; '+str(len(rows))+';\n'+',\n'.join(rows)+';\n }\n'
 x+=' }\n'
x+='}\n'
mod=OUT/'ProjectYakuza'/'42';x=x.replace('ProjectYakuza_DD_TigerDrop',ANIMNAME);anim=mod/f'media/anims_X/Bob/{ANIMNAME}.x';anim.parent.mkdir(parents=True,exist_ok=True);anim.write_text(x)
import hashlib
report={'source':src,'sha256':hashlib.sha256(Path(src).read_bytes()).hexdigest(),'clip':ANIMNAME,'fps':a.frame_rate,'end_frame':a.end_frame,'duration':a.end_frame/a.frame_rate,'roots':[{'x':float(g['ketu_c_n'].translation.x),'y':float(g['ketu_c_n'].translation.y),'z':float(g['ketu_c_n'].translation.z),'q':list(g['ketu_c_n'].to_quaternion())} for g in srcposes]}
(DEST/'tools'/(ANIMNAME+'-source.json')).write_text(json.dumps(report,indent=2))
report['hands']=[{'left':list(g['ude3_l_n'].translation),'right':list(g['ude3_r_n'].translation)} for g in srcposes] if 'ude3_l_n' in srcposes[0] else []; (DEST/'tools'/(ANIMNAME+'-source.json')).write_text(json.dumps(report,indent=2)); print('CONVERTED',ANIMNAME,report['duration'])