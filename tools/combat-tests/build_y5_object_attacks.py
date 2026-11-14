from pathlib import Path
import sys,json,hashlib,math,xml.etree.ElementTree as E

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from mathutils import Matrix
from y5_retarget import provenance,convert
from locomotion_math import read,locals_at,world,blocks,write
mod=root/'combat/ProjectYakuza';media=mod/'42/media';grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[];moves={}
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def put(node,key,value):
    element=node.find(key)
    if element is None:element=E.SubElement(node,key)
    element.text=str(value)

def literal(value):
    if isinstance(value,str):return json.dumps(value)
    if isinstance(value,bool):return str(value).lower()
    if isinstance(value,(int,float)):return format(value,'.12g')
    if isinstance(value,list):return '{'+','.join(literal(v)for v in value)+'}'
    return '{'+','.join('['+json.dumps(k)+']='+literal(v)for k,v in sorted(value.items()))+'}'

for family in ['Crate']:
    result={'lightAttacks':[],'groundAttacks':[]};profile=family.lower()
    for label,stem in [('Light01','P_WPC_CMB_01'),('Light02','P_WPC_CMB_02'),('Light03','P_WPC_CMB_03'),('Heavy','P_WPC_ATK_heavy'),('Ground','P_WPC_ATK_heavy')]:
        name='ProjectYakuza_DD_'+family+label;source=root/'extracted/crate-normal-097'/(stem+'.gmt');output=media/'anims_X/Bob'/(name+'.x');context,raw=convert(name,source,output)
        text,bones,animation,spans=read(output);count=context['a'].end_frame+1;times=[f*160 for f in range(count)];values=[locals_at(bones,animation,t)for t in times];write(output,text,spans,blocks(bones,values,times,grip),name)
        native=[world(bones,v)for v in values];scores=[]
        for frame in range(1,count):scores.append((sum((native[frame][hand].translation-native[frame-1][hand].translation).length for hand in ['Bip01_R_Hand','Bip01_L_Hand']),frame))
        contact=max((row for row in scores if 5<=row[1]<=int((count-1)*.65)),key=lambda row:row[0])[1];end=count-1;chain=min(end-1,max(contact+5,round(end*.68)));nodeValue='dd_'+profile+'_'+('light_'+label[-2:]if label.startswith('Light')else label.lower())
        move={'animation':name,'nodeValue':nodeValue,'duration':end/30/1.4,'speed':1.4,'impact':contact/end,'hitResponse':False,'damageMultiplier':1.25 if label=='Heavy'else 1}
        if label.startswith('Light'):move.update(chainAt=chain/end,quickstepCancelAt=(contact+1)/end);result['lightAttacks'].append(move)
        elif label=='Ground':move['groundAttack']=True;result['groundAttacks'].append(move)
        else:move['enabled']=True;result['finisher']={'enabled':True,'variants':{'default':move}}
        sourceNode=media/'AnimSets/player/melee'/('ProjectYakuza_DD_Crate'+label+'.xml');xml=E.parse(sourceNode).getroot();put(xml,'m_Name',name);put(xml,'m_AnimName',name)
        for condition in xml.findall('m_Conditions'):
            key=condition.findtext('m_Name')
            if key=='ProjectYakuzaWeaponProfile':put(condition,'m_Value',profile)
            if key=='ProjectYakuzaMove':put(condition,'m_Value',nodeValue)
        for event in xml.findall('m_Events'):
            kind=event.findtext('m_EventName');value=event.findtext('m_ParameterValue')or''
            if kind=='AttackCollisionCheck':put(event,'m_TimePc',contact/end)
            if kind=='SetVariable'and '='in value:
                key=value.split('=')[0];put(event,'m_ParameterValue',key+'='+nodeValue)
                if key=='ProjectYakuzaHitMarker':put(event,'m_TimePc',contact/end)
                if key=='ProjectYakuzaChainReady':put(event,'m_TimePc',chain/end)
                if key=='ProjectYakuzaQuickstepCancelReady':put(event,'m_TimePc',(contact+1)/end)
        dest=sourceNode.with_name(name+'.xml');E.indent(xml,space='  ');E.ElementTree(xml).write(dest,encoding='utf-8',xml_declaration=True)
        records.append({'family':profile,'label':label,'source':str(source),'sourceSha256':sha(source),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retarget':str(raw),'retargetSha256':sha(raw),'frames':count,'fps':30,'contactFrame':contact,'chainFrame':chain,'contactCalibration':'Maximum original converted two-hand sweep speed in the committed attack portion, frames 5 through 65 percent. This is a native geometry contact calibration, not a claim of a CMN damage marker.','sourceGroundPolicy':'Original Y5 large-object overhead heavy reused for floor-target attacks.'if label=='Ground'else None})
        print(name,count,'frames; calibrated contact',contact)
    moves[profile]=result
(media/'lua/shared/ProjectYakuza/Y5ObjectMoves.lua').write_text('require "ProjectYakuza/Registry"\nProjectYakuza.Y5ObjectMoves='+literal(moves)+'\n')
report={'operation':'Original Y5 large-object combo and heavy source clips, all frames retained at 30 fps before existing x1.4 combat playback. Native arm lengths and source limb directions retained. Source overhead heavy is reused for ground attacks. No invented body poses, images or audio. Crate model linear scale is reduced to 0.5.','archiveEntries':json.loads((root/'extracted/crate-normal-097/index.json').read_text()),'clips':records,'nativeGrip':grip,'crateScale':.5}
report['retargetProvenance']=provenance()
(mod/'docs/y5-object-attacks.json').write_text(json.dumps(report,indent=2)+'\n')
