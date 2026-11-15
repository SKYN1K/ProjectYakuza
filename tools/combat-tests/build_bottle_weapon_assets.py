from pathlib import Path
import sys,json,hashlib,struct,zipfile,re,xml.etree.ElementTree as E
from mathutils import Matrix,Vector
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w))
from locomotion_math import read,locals_at,world,blocks,write
from native_body_geometry import load_body,skin_part
mod=root/'combat/ProjectYakuza';media=mod/'42/media';source=root/'extracted/bottle-y6-0114';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');body=load_body(native/'models_X/Skinned/MaleBody.x');sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest();records=[];moves={'lightAttacks':[],'groundAttacks':[]}
converter=(w/'retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/bottle-weapon-build'")
def literal(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,(int,float)):return format(v,'.12g')
 if isinstance(v,list):return '{'+','.join(literal(x)for x in v)+'}'
 return '{'+','.join('['+json.dumps(k)+']='+literal(x)for k,x in sorted(v.items()))+'}'
def put(n,k,v):
 child=n.find(k)
 if child is None:child=E.SubElement(n,k)
 child.text=str(v).lower()if isinstance(v,bool)else str(v)
for label,suffix in [('Light01','ath_01_md'),('Light02','ath_02_md'),('Light03','ath_03_md'),('Heavy','ath_hvy_md'),('Ground','ath_dwn_md'),('Ready','stdA_lp'),('RelaxedIdle','stdB_lp')]:
 name='ProjectYakuza_DD_Bottle'+label;path=source/('P_KRU_BTL_WPN_'+suffix+'.gmt');sys.argv=['convert','--',name,str(path)];context={'FINGER_SOURCE':'Bob_AttackKnife01_Hit.x'};exec(compile(converter,'supplied_y6_bottle_weapon_motion','exec'),context);raw=root/'tools/bottle-weapon-build/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw);count=context['a'].end_frame+1;values=[];offsets=[]
 for frame in range(count):
  local=locals_at(bones,animation,frame*160);pose=world(bones,local);hand=pose['Bip01_R_Hand'];points=skin_part(body,pose,['Bip01_R_Hand']);palm=sum(points,Vector())/len(points);offset=hand.inverted()@palm;offsets.append(list(offset));prop=hand.copy();prop.translation=palm;local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@prop;values.append(local)
 output=media/'anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,values,[i*160 for i in range(count)],None),name);record={'label':label,'source':str(path),'sourceSha256':sha(path),'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':count,'fps':30,'palmOffsets':offsets}
 if label not in ['Ready','RelaxedIdle']:
  bep=path.with_suffix('.bep');data=bep.read_bytes();pos=16;contacts=[]
  while pos+80<=len(data):
   section,kind,size=struct.unpack_from('<HHI',data,pos+64)
   if section==12 and kind==68:contacts.append(round(struct.unpack_from('<f',data,pos+84)[0]))
   pos+=80+size
  assert contacts and all(0<c<count-1 for c in contacts),(name,contacts)
  end=count-1;hit=contacts[0];chain=end-1;node='dd_bottle_'+('light_'+label[-2:]if label.startswith('Light')else label.lower());move={'animation':name,'nodeValue':node,'duration':end/30/1.4,'speed':1.4,'impact':hit/end,'hitResponse':False,'damageMultiplier':1.25 if label=='Heavy'else 1}
  if label.startswith('Light'):move.update(chainAt=chain/end,quickstepCancelAt=(contacts[-1]+1)/end);moves['lightAttacks'].append(move)
  elif label=='Ground':move['groundAttack']=True;moves['groundAttacks'].append(move)
  else:move['enabled']=True;moves['finisher']={'enabled':True,'variants':{'default':move}}
  dest=media/'AnimSets/player/melee'/(name+'.xml');nodeXml=E.parse(dest).getroot();put(nodeXml,'m_EarlyTransitionOut',False)
  for event in nodeXml.findall('m_Events'):
   kind=event.findtext('m_EventName');key=(event.findtext('m_ParameterValue')or'').split('=')[0]
   if kind=='AttackCollisionCheck'or key=='ProjectYakuzaHitMarker':put(event,'m_TimePc',hit/end)
   elif key=='ProjectYakuzaChainReady':put(event,'m_TimePc',chain/end)
   elif key=='ProjectYakuzaQuickstepCancelReady':put(event,'m_TimePc',(contacts[-1]+1)/end)
  E.indent(nodeXml,space='  ');E.ElementTree(nodeXml).write(dest,encoding='utf-8',xml_declaration=True);record.update(bep=str(bep),bepSha256=sha(bep),sourceContactFrames=contacts,contactFrame=hit)
 records.append(record)
 for group in (['aim','aim-strafe']if label=='Ready'else['idle']if label=='RelaxedIdle'else[]):
  template=media/'AnimSets/player'/group/('ProjectYakuza_DD_Bicycle'+('Idle'if label=='Ready'else'RelaxedIdle')+'.xml');nodeXml=E.parse(template).getroot();put(nodeXml,'m_Name',name);put(nodeXml,'m_AnimName',name)
  for condition in nodeXml.findall('m_Conditions'):
   if condition.findtext('m_Name')=='ProjectYakuzaWeaponProfile':put(condition,'m_Value','bottle')
  E.indent(nodeXml,space='  ');E.ElementTree(nodeXml).write(template.with_name(name+'.xml'),encoding='utf-8',xml_declaration=True)
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.113.0.zip')as archive:
 for output in sorted((media/'anims_X/Bob').glob('ProjectYakuza_DD_Bottle*.x')):
  if 'Heat'in output.stem or any(c['output']==output.relative_to(mod).as_posix()for c in records):continue
  raw=root/'tools/bottle-weapon-build'/output.name;raw.write_bytes(archive.read('ProjectYakuza/'+output.relative_to(mod).as_posix()));text,bones,animation,spans=read(raw);count=len(animation['Bip01_R_Hand'][0]);values=[];offsets=[]
  for frame in range(count):
   local=locals_at(bones,animation,frame*160);pose=world(bones,local);hand=pose['Bip01_R_Hand'];points=skin_part(body,pose,['Bip01_R_Hand']);palm=sum(points,Vector())/len(points);offsets.append(list(hand.inverted()@palm));prop=hand.copy();prop.translation=palm;local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@prop;values.append(local)
  changes=blocks(bones,values,[i*160 for i in range(count)],None);write(output,text,{'Bip01_Prop1':spans['Bip01_Prop1']},{'Bip01_Prop1':changes['Bip01_Prop1']},output.stem);records.append({'label':output.stem,'attachmentOnly':True,'source':str(raw),'sourceSha256':sha(raw),'retarget':str(raw),'retargetSha256':sha(raw),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':count,'fps':30,'palmOffsets':offsets})
models=[];modelText=[]
for name in ['BeerBottle','RedWineBottle','WhiskeyBottle']:
 path=native/'models_X'/(name+'.x');text=path.read_text();match=re.search(r'\bMesh\s+\w+\s*\{\s*(\d+);',text);vertices=[Vector(tuple(map(float,v)))for v in re.findall(r'([-\d.]+);\s*([-\d.]+);\s*([-\d.]+);',text[match.end():])[:int(match[1])]];height=min(v.y for v in vertices)+.82*(max(v.y for v in vertices)-min(v.y for v in vertices));neck=[v for v in vertices if v.y>=height];point=Vector(((min(v.x for v in neck)+max(v.x for v in neck))/2,height,(min(v.z for v in neck)+max(v.z for v in neck))/2));alias='ProjectYakuza_'+name;modelText.append('    model '+alias+'\n    {\n        mesh = '+name+',\n        texture = '+name+',\n        static = true,\n        scale = 1.0,\n        attachment Bip01_Prop1\n        {\n            offset = '+' '.join(format(v,'.12g')for v in point)+',\n            rotate = 0.0 0.0 0.0,\n        }\n    }');models.append({'name':alias,'mesh':str(path),'meshSha256':sha(path),'neckPoint':list(point)})
(media/'scripts/ProjectYakuza_BottleModels.txt').write_text('module Base\n{\n'+'\n'.join(modelText)+'\n}\n')
items=media/'scripts/ProjectYakuza_Bottles.txt';text=items.read_text()
for name in ['BeerBottle','RedWineBottle','WhiskeyBottle']:
 for key in ['WeaponSprite','StaticModel']:text=text.replace(key+' = '+name+',',key+' = ProjectYakuza_'+name+',')
items.write_text(text)
(media/'lua/shared/ProjectYakuza/BottleMoves.lua').write_text('require "ProjectYakuza/Registry"\nProjectYakuza.BottleMoves='+literal(moves)+'\n')
report={'operation':'All original Yakuza 6 WPN bottle-specific attack and hold frames, original BEP contacts, unchanged native limb lengths and one damage event per swing. The right prop pivot follows the skinned right palm, including existing travel/guard clips with unchanged body channels. Separate native-model definitions put each supplied bottle neck at that pivot. No new mesh, texture or sound.','archiveEntries':json.loads((source/'index.json').read_text()),'nativeBody':body['path'],'nativeBodySha256':sha(body['path']),'clips':records,'models':models}
(mod/'docs/bottle-weapon-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS seven dedicated WPN bottle attacks/holds with skinned-palm attachment')
