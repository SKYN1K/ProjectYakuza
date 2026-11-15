from pathlib import Path
import sys,json,hashlib,uuid
from mathutils import Vector

root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w))
from y5_retarget import convert
from read_heat_scene import read_scene
from extract_majima_bat_emote import resource
from locomotion_math import read,locals_at,world,blocks,write
from native_body_geometry import load_body,skin_part
from paired_paths import bridge_scene_cuts

mod=root/'combat/ProjectYakuza';folder=root/'extracted/grab-y5-0116'
if not(folder/'source-index.json').exists():
 from extract_open_grab_heat_assets import extract
 extract()
scene=read_scene(folder/'cmn.par/cmn.bin');characters=[n for n in scene['nodes']if n['category']==5];sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();assert len(characters)==2 and scene['end']==200
contacts=[n['element']['start']for n in scene['nodes']if 'damage'in n and n['role']=='victim'];assert contacts==[78];records=[];paths=[];selection=[]
body=load_body('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/models_X/Skinned/MaleBody.x');_,ib,ia,_=read('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob/Bob_Idle.x');floor=min(p.y for p in skin_part(body,world(ib,locals_at(ib,ia,0)),['Bip01_L_Foot','Bip01_R_Foot','Bip01_L_Toe0','Bip01_R_Toe0']))
for role,character in enumerate(characters):
 motion=next(n for n in scene['nodes']if n['category']==6 and n['parent']==character['offset']);stem=resource(folder/'000.par/res.bin',uuid.UUID(motion['guid']).bytes_le.hex());source=folder/'000.par'/(stem+'.gmt');name='ProjectYakuza_DD_OpenGrabHeat'+('Victim'if role else'');output=mod/'42/media/anims_X/Bob'/(name+'.x');context,raw=convert(name,source,output);text,bones,animation,spans=read(output);count=context['a'].end_frame+1;assert count==201;values=[];lifts=[]
 for frame in range(count):
  value=locals_at(bones,animation,frame*160);pose=world(bones,value);lift=max(0,floor-min(p.y for p in skin_part(body,pose,['Bip01'])));parent=bones['Bip01']['parent'];correction=Vector((0,lift,0));value['Bip01'].translation+=pose[parent].inverted().to_3x3()@correction if parent else correction;values.append(value);lifts.append(lift)
 write(output,text,spans,blocks(bones,values,[i*160 for i in range(count)],None),name);centre=context['a'].bones['center_n'];paths.append([context['sample'](centre.location,f,Vector((0,0,0)))for f in range(count)]);records.append({'animation':name,'source':str(source),'sourceSha256':sha(source),'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':count,'fps':30,'nativeFloorLift':lifts});selection.append({'character':character['guid'],'motion':motion['guid'],'resource':stem,'sourceSha256':sha(source)})
origin=paths[0][0];scale=float(context['scale'])*1.5;rawPaths=[[[float((p-origin).z*scale),float((p-origin).x*scale)]for p in row]for row in paths];paths,cuts=bridge_scene_cuts(rawPaths)

def literal(value):
 if isinstance(value,str):return json.dumps(value)
 if isinstance(value,(float,int)):return format(value,'.9g')
 if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
 return '{'+','.join(k+'='+literal(v)for k,v in value.items())+'}'

motion={'fps':30,'duration':200/30,'actorAnimation':'ProjectYakuza_DD_OpenGrabHeat','targetAnimation':'ProjectYakuza_DD_OpenGrabHeatVictim','actor':paths[0],'victim':paths[1],'victimFacing':{'forward':-1,'right':0}}
(mod/'42/media/lua/shared/ProjectYakuza/OpenGrabHeatPaths.lua').write_text('require "ProjectYakuza/Registry"\nProjectYakuza.PairedMotions=ProjectYakuza.PairedMotions or {}\nProjectYakuza.PairedMotions.dod_grab_open='+literal(motion)+'\n')
path=mod/'42/media/lua/shared/ProjectYakuza/GrabMoves.lua';path.write_text(path.read_text().replace('motionId="dod_grab_open",duration=224/30','motionId="dod_grab_open",duration=200/30'))
index=json.loads((folder/'source-index.json').read_text());report={'operation':'Original Yakuza 5 front-grab sacrifice throw, h11240_tomoenage. All 201 source samples and CMN victim impact frame 78 retained at original 30 fps; native arm lengths fitted to source directions and native floor penetration corrected. Original scene resources bind one player and one victim; no wall, prop or second target.','archive':index['archive'],'archiveSha256':index['archiveSha256'],'scene':str(folder/'cmn.par/cmn.bin'),'sceneSha256':scene['sha256'],'resources':str(folder/'000.par/res.bin'),'selection':selection,'contactFrames':contacts,'pathScale':scale,'paths':paths,'rawPaths':rawPaths,'sceneCuts':cuts,'floor':floor,'clips':records};(mod/'docs/open-grab-heat-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS original Yakuza 5 grabbed-target sacrifice throw, 201 paired samples, CMN contact frame 78')
