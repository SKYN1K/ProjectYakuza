from pathlib import Path
import json,hashlib,shutil,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];SRC=ROOT/'previews/y6-phone-menu';MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev';validate='--validate'in sys.argv
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
source=SRC/'source-animation/a00_21z_smrt_ph_xpra52bl.gmd';record=json.loads((SRC/'source-animation/xperia-model-index.json').read_text());assert sha(source)==record['sha256']=='62d7a9d4e214fa0190f28b905183b8b1e3f976d701f7e3c33bd197b7ddc632bb'
d=json.loads((SRC/'source-animation/xperia-mesh.json').read_text());assert d['sha256']==sha(source);mesh=d['meshes'][0];assert len(d['meshes'])==1 and mesh['diffuse']=='r_tu_xpra_blu1_ay_d'
positions=[[-(p[1]-.0041)*100,-p[2]*100,p[0]*100]for p in mesh['pos']];normals=[[-n[1],-n[2],n[0]]for n in mesh['normal']];uv=mesh['uvLayers'][1];faces=[mesh['indices'][i:i+3]for i in range(0,len(mesh['indices']),3)];assert len(positions)==3162 and len(faces)==4316
array=lambda rows,fmt:',\n'.join(fmt(r)for r in rows)+';'
text='xof 0303txt 0032\nMesh Xperia {\n'+str(len(positions))+';\n'+array(positions,lambda p:';'.join(format(n,'.9f')for n in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\nMeshNormals {\n'+str(len(normals))+';\n'+array(normals,lambda p:';'.join(format(n,'.9f')for n in p)+';')+'\n'+str(len(faces))+';\n'+array(faces,lambda f:'3;'+','.join(map(str,f))+';')+'\n}\nMeshTextureCoords {\n'+str(len(uv))+';\n'+array(uv,lambda p:format(p[0],'.9f')+';'+format(p[1],'.9f')+';')+'\n}\nMeshMaterialList {\n1;\n'+str(len(faces))+';\n'+','.join('0'for _ in faces)+';\nMaterial {1;1;1;1;;\n1;\n0;0;0;;\n0;0;0;;\nTextureFilename {"ProjectYakuzaPhoneDev/Xperia.png";}\n}\n}\n}\n'
model=MOD/'42/media/models_X/Static/ProjectYakuzaPhoneDev_Xperia.x';model.parent.mkdir(parents=True,exist_ok=True)
if validate:assert model.read_text()==text
else:model.write_text(text,newline='\n')
textures=MOD/'42/media/textures/ProjectYakuzaPhoneDev';textures.mkdir(parents=True,exist_ok=True);images={}
sourceDiffuse=SRC/'source-animation/r_tu_xpra_blu1_ay_d.dds';assert sha(sourceDiffuse)=='6708ebdd01bfa8e6627e0b0c18286da86fdd703bf4e43129cb60564c1b0c6e45';expected=Image.open(sourceDiffuse).convert('RGBA');diffuse=SRC/'source-animation/xperia-diffuse.png';assert Image.open(diffuse).convert('RGBA').tobytes()==expected.tobytes()
for name,src in {**{n:SRC/(n+'.png')for n in ['styles','equipment','combat','audio','effects','grabs','controls','settings','battery','signal']},'Pixel':SRC/'pause_cursor.png','Xperia':diffuse}.items():
 output=textures/(name+'.png')
 if validate:assert output.read_bytes()==src.read_bytes()
 else:shutil.copyfile(src,output)
 image=Image.open(output).convert('RGBA');bbox=image.getchannel('A').getbbox();images[name]={'source':str(src.relative_to(ROOT)),'sourceSha256':sha(src),'output':str(output.relative_to(MOD)),'sha256':sha(output),'size':list(image.size),'alphaBounds':list(bbox)}
heat=ROOT/'combat/ProjectYakuza/42/media/textures/ProjectYakuza/HeatActionIconAtlas.png';flame=Image.open(heat).convert('RGBA').crop((64,0,128,80));output=textures/'heat.png'
if validate:assert Image.open(output).convert('RGBA').tobytes()==flame.tobytes()
else:flame.save(output)
images['heat']={'source':str(heat.relative_to(ROOT)),'sourceSha256':sha(heat),'crop':[64,0,128,80],'output':str(output.relative_to(MOD)),'sha256':sha(output),'size':list(flame.size),'alphaBounds':list(flame.getchannel('A').getbbox())}
assets='ProjectYakuza=ProjectYakuza or {}\nProjectYakuza.PhoneDev=ProjectYakuza.PhoneDev or {}\nProjectYakuza.PhoneDev.VERSION="0.1.0"\nProjectYakuza.PhoneDev.requiredCombatVersion="0.127.0"\nProjectYakuza.PhoneDev.assets={'+','.join('['+json.dumps(n)+']={path='+json.dumps('media/textures/ProjectYakuzaPhoneDev/'+n+'.png')+',width='+str(v['size'][0])+',height='+str(v['size'][1])+',bounds={'+','.join(map(str,v['alphaBounds']))+'}}'for n,v in sorted(images.items()))+'}\n'
p=MOD/'42/media/lua/client/ProjectYakuzaPhoneDev/Assets.lua'
if validate:assert p.read_text()==assets
else:p.write_text(assets,newline='\n')
report={'authorization':'User approved conversion of supplied original Xperia assets for the separate phone dev build. No new artwork or sound.','modelSource':record,'sourceMeshSha256':sha(SRC/'source-animation/xperia-mesh.json'),'model':str(model.relative_to(MOD)),'modelSha256':sha(model),'vertices':3162,'triangles':4316,'uvLayer':1,'operation':'All original vertices, normals and triangles retained. Original UV layer 1 serialized without V inversion so the native static importer retains original sampling. Rigid source-to-native-UI reorientation plus unit conversion only: (-(y-.0041),-z,x)*100. Native UI camera Right then restores the reference-facing model. No topology synthesis or resampling.','images':images,'textureDDS':{'sha256':sha(sourceDiffuse),'size':list(expected.size)},'screenPlane':{'x':-.3905,'top':5.7124272,'bottom':-5.7664201,'left':-3.2274276,'right':3.2274276},'exportedPositions':positions,'exportedNormals':normals,'uv':uv,'faces':faces}
p=MOD/'docs/assets.json'
if not validate:p.write_text(json.dumps(report,indent=2)+'\n',newline='\n')
print('PASS original Xperia: 3162 vertices / 4316 triangles, UV layer 1, exact 1024x1024 diffuse and original centred UI icons; no new artwork')
