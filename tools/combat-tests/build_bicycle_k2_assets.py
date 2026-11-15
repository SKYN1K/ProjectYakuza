from pathlib import Path
import sys,json,hashlib,struct,xml.etree.ElementTree as E
from mathutils import Vector
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;sys.path.insert(0,str(w))
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import fit_arms,source_pose
from native_body_geometry import load_body
from bicycle_grip import palm_offsets,grip_rail,fit_prop
mod=root/'combat/ProjectYakuza';media=mod/'42/media';source=root/'extracted/bicycle-k2-0111';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media');body=load_body(native/'models_X/Skinned/MaleBody.x');model=json.loads((mod/'docs/bicycle-model-assets.json').read_text());rail=grip_rail(model);scale=.44308598137428024;grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[];moves={'lightAttacks':[],'groundAttacks':[]};sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
converter=(w/'retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/bicycle-k2-build'").replace("r'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'",repr(str(source/'c_man_bone.gmd')))
def put(node,key,value):
    child=node.find(key)
    if child is None:child=E.SubElement(node,key)
    child.text=str(value).lower()if isinstance(value,bool)else str(value)
def literal(v):
    if isinstance(v,str):return json.dumps(v)
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(int,float)):return format(v,'.12g')
    if isinstance(v,list):return '{'+','.join(literal(x)for x in v)+'}'
    return '{'+','.join('['+json.dumps(k)+']='+literal(x)for k,x in sorted(v.items()))+'}'
walkBases={'Walk':'Bob_WalkBat','WalkSlow':'Bob_WalkSlow_Bat','WalkLightLimpR':'Bob_WalkLightLimpR_Bat','WalkLightLimpL':'Bob_WalkLightLimpL_Bat','WalkHeavyLimpR':'Bob_WalkHeavyLimpR_Bat','WalkHeavyLimpL':'Bob_WalkHeavyLimpL_Bat'}
jobs=[(label,'P_KRU_BTL_WPC_'+suffix,None)for label,suffix in [('Light01','ath_01_md'),('Light02','ath_02_md'),('Light03','ath_03_md'),('Heavy','ath_hvy_md'),('Ground','ath_dwn_md'),('Ready','stdA_lp'),('RelaxedIdle','stdB_lp')]]+[(label,'P_KRU_MOV_wlk_ftl_wpc',base)for label,base in walkBases.items()]
for label,stem,walkBase in jobs:
    name='ProjectYakuza_DD_Bicycle'+label;path=source/(stem+'.gmt');sys.argv=['convert','--',name,str(path)];context={'FINGER_SOURCE':'Bob_AttackBat01_Hit.x'};exec(compile(converter,'supplied_kiwami2_bicycle_motion','exec'),context);raw=root/'tools/bicycle-k2-build/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');text,bones,animation,spans=read(raw);sourceCount=context['a'].end_frame+1;count=sourceCount;assert context['a'].frame_rate==30;fingers={n:v.copy()for n,v in locals_at(bones,animation,0).items()if '_Finger'in n};values=[];base=None
    if label in ['Ready','RelaxedIdle']or walkBase:
        base=native/'anims_X/Bob'/((walkBase or('Bob_IdleAimBat'if label=='Ready'else'Bob_IdleBat'))+'.x');text,bones,animation,spans=read(base);baseEnd=max(t for c in animation.values()for keys in c.values()for t,_ in keys)
        if walkBase:count=round(baseEnd/160)+1;assert baseEnd==(count-1)*160
    times=[f*160 for f in range(count)];sourceFrames=[frame*(sourceCount-1)/(count-1)if walkBase else frame for frame in range(count)]
    front=context['bind']['Bip01_Spine1'].to_quaternion().inverted()@Vector((0,0,1))
    for frame,t in enumerate(times):
        local=locals_at(bones,animation,t if walkBase or not base else t%baseEnd);local,_=fit_arms(bones,local,source_pose(context,sourceFrames[frame])if walkBase else context['srcposes'][frame],context['bind'],fingers);values.append(local)
    output=media/'anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(bones,values,times,grip),name);text,bones,animation,spans=read(output);palms=palm_offsets(body,world(bones,locals_at(bones,animation,0)));values=[];gripRows=[]
    for frame,t in enumerate(times):
        local=locals_at(bones,animation,t);pose=world(bones,local);prop,row=fit_prop(pose,pose['Bip01_Prop1'],palm_offsets(body,pose),rail,scale,normal=pose['Bip01_Spine1'].to_quaternion()@front);local['Bip01_Prop1']=pose[bones['Bip01_Prop1']['parent']].inverted()@prop;values.append(local);gripRows.append({'right':list(row['modelRight']),'left':list(row['modelLeft'])})
    changes=blocks(bones,values,times,None);write(output,text,{'Bip01_Prop1':spans['Bip01_Prop1']},{'Bip01_Prop1':changes['Bip01_Prop1']},name);record={'label':label,'source':str(path),'sourceSha256':sha(path),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retarget':str(raw),'retargetSha256':sha(raw),'frames':count,'fps':30,'palmOffsets':{k:list(v)for k,v in palms.items()},'palmSampling':'Actual skinned palm centroid resampled at every source frame','gripPoints':gripRows,'nativeBase':str(base)if base else None,'nativeBaseSha256':sha(base)if base else None}
    if walkBase:
        record.update(sourceFrames=sourceCount,sourceFrameMap=sourceFrames,nativeBaseMode='cycle')
    elif base:
        groups=['aim','aim-strafe']if label=='Ready'else['idle']
        for group in groups:
            node=E.Element('animNode')
            for key,value in [('m_Name','ProjectYakuza_DD_Bicycle'+('Idle'if label=='Ready'else'RelaxedIdle')),('m_AnimName',name),('m_Priority',4),('m_ConditionPriority',180),('m_BlendTime',.16),('m_BlendOutTime',.18),('m_SpeedScale',1),('m_Looped',True),('m_SyncTrackingEnabled',False),('m_maxTorsoTwist',0)]:put(node,key,value)
            for bone in ['Bip01_Spine1','Bip01_Prop1','Bip01_Prop2']:
                child=E.SubElement(node,'m_SubStateBoneWeights');put(child,'boneName',bone);put(child,'weight',1);put(child,'includeDescendants',True)
            for key,kind,value in [('ProjectYakuzaActive','BOOL',True),('ProjectYakuzaStyle','STRING','dragon_of_dojima'),('ProjectYakuzaWeaponProfile','STRING','bicycle')]:
                child=E.SubElement(node,'m_Conditions');put(child,'m_Name',key);put(child,'m_Type',kind);put(child,'m_Value',value)
            destination=media/'AnimSets/player'/group/(node.findtext('m_Name')+'.xml');E.indent(node,space='  ');E.ElementTree(node).write(destination,encoding='utf-8',xml_declaration=True)
    else:
        bep=path.with_suffix('.bep');data=bep.read_bytes();pos=16;contacts=[]
        while pos+80<=len(data):
            section,kind,size=struct.unpack_from('<HHI',data,pos+64);payload=data[pos+80:pos+80+size]
            if section==12 and kind==68:contacts.append(round(struct.unpack_from('<f',payload,4)[0]))
            pos+=80+size
        assert contacts and all(0<c<count-1 for c in contacts),(name,contacts);contact=contacts[0];end=count-1;chain=min(end-1,max(contact+5,round(end*.68)));nodeValue='dd_bicycle_'+('light_'+label[-2:]if label.startswith('Light')else label.lower());move={'animation':name,'nodeValue':nodeValue,'duration':end/30,'speed':1,'impact':contact/end,'hitResponse':False,'damageMultiplier':1.25 if label=='Heavy'else 1}
        if label.startswith('Light'):move.update(chainAt=chain/end,quickstepCancelAt=(contacts[-1]+1)/end);moves['lightAttacks'].append(move)
        elif label=='Ground':move['groundAttack']=True;moves['groundAttacks'].append(move)
        else:move['enabled']=True;moves['finisher']={'enabled':True,'variants':{'default':move}}
        destination=media/'AnimSets/player/melee'/(name+'.xml');node=E.parse(destination).getroot()
        for event in node.findall('m_Events'):
            kind=event.findtext('m_EventName');parameter=event.findtext('m_ParameterValue')or''
            if kind=='AttackCollisionCheck':put(event,'m_TimePc',contact/end)
            if kind=='SetVariable':
                key=parameter.split('=')[0]
                if key=='ProjectYakuzaHitMarker':put(event,'m_TimePc',contact/end)
                if key=='ProjectYakuzaChainReady':put(event,'m_TimePc',chain/end)
                if key=='ProjectYakuzaQuickstepCancelReady':put(event,'m_TimePc',(contacts[-1]+1)/end)
        E.indent(node,space='  ');E.ElementTree(node).write(destination,encoding='utf-8',xml_declaration=True);record.update(bep=str(bep),bepSha256=sha(bep),sourceContactFrames=contacts,contactFrame=contact,chainFrame=chain)
    records.append(record);print('BUILT',name,count,'source samples',record.get('sourceContactFrames',[]),flush=True)
node=E.parse(native/'AnimSets/player/movement/defaultWalk.xml').getroot();put(node,'m_Name','ProjectYakuza_DD_BicycleWalk');put(node,'m_ConditionPriority',180);put(node,'m_Looped',True);put(node,'m_BlendTime',.2);put(node,'m_BlendOutTime',.2);mapping={base:'ProjectYakuza_DD_Bicycle'+label for label,base in walkBases.items()};mapping.update({'Bob_Walk':'ProjectYakuza_DD_BicycleWalk','Bob_WalkSlow':'ProjectYakuza_DD_BicycleWalkSlow'})
for target in node.iter('m_AnimName'):
    if target.text in mapping:target.text=mapping[target.text]
    elif target.text.startswith('Bob_WalkLightLimp')or target.text.startswith('Bob_WalkHeavyLimp'):target.text=mapping[target.text+'_Bat']
for transition in node.findall('m_Transitions'):
    for target in list(transition.findall('m_AnimName')):transition.remove(target)
for key,kind,value in [('ProjectYakuzaActive','BOOL',True),('ProjectYakuzaStyle','STRING','dragon_of_dojima'),('ProjectYakuzaWeaponProfile','STRING','bicycle'),('Aim','BOOL',False),('sneaking','BOOL',False),('inTrees','BOOL',False)]:
    child=E.SubElement(node,'m_Conditions');put(child,'m_Name',key);put(child,'m_Type',kind);put(child,'m_Value',value)
destination=media/'AnimSets/player/movement/ProjectYakuza_DD_BicycleWalk.xml';destination.parent.mkdir(parents=True,exist_ok=True);E.indent(node,space='  ');E.ElementTree(node).write(destination,encoding='utf-8',xml_declaration=True)
(media/'lua/shared/ProjectYakuza/BicycleMoves.lua').write_text('require "ProjectYakuza/Registry"\nProjectYakuza.BicycleMoves='+literal(moves)+'\n')
report={'operation':'Original Kiwami 2 WPC three-hit chain, heavy attack, floor attack, ready/relaxed holds and original wlk_ftl_wpc walking arms. Six walking composites retain native normal/slow/injured leg, torso and deferred travel channels, source arm directions phase-mapped to each native cycle. All source frames retained at 30 fps and base speed 1. The first original BEP collision frame drives the existing one-damage-event PZ swing; all authored hitbox starts are recorded and quickstep cancellation waits for the last one. Native combo release policy and damage balance retained. Holds fit original source arm directions onto unchanged native idle body/legs. The supplied bicycle mesh is fitted to native skinned palm centres using model-surface frame grips. No new models, pixels, sound or source body poses.','archiveEntries':json.loads((source/'index.json').read_text()),'rig':str(source/'c_man_bone.gmd'),'rigSha256':sha(source/'c_man_bone.gmd'),'modelScale':scale,'modelSha256':model['sha256'],'railVertexIndices':rail['indices'],'clips':records,'provenance':[{'path':str(p),'sha256':sha(p)}for p in [Path(__file__),w/'extract_bicycle_k2_assets.py',w/'bicycle_grip.py',w/'weapon_hold_geometry.py',w/'retarget_locomotion.py',native/'models_X/Skinned/MaleBody.x']]}
(mod/'docs/bicycle-k2-assets.json').write_text(json.dumps(report,indent=2)+'\n');print('PASS thirteen original Kiwami 2 bicycle attack/hold/walk composites and source event timing')
