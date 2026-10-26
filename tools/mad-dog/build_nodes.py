"""Build addon nodes/catalogue from the exported original-motion manifest."""
from pathlib import Path
import copy
import json
import xml.etree.ElementTree as E

ROOT=Path(__file__).resolve().parents[2]
ADDON=ROOT/'styles/ProjectYakuzaMadDog'
MEDIA=ADDON/'42/media'
STYLE='project_yakuza.mad_dog_of_shimano'
CLIPS=json.loads((ADDON/'docs/motion-provenance.json').read_text())['clips']
records=[]

def lua(value,indent=0):
    if isinstance(value,bool):return 'true' if value else 'false'
    if isinstance(value,str):return json.dumps(value)
    if isinstance(value,(int,float)):return f'{value:.12g}'
    if value is None:return 'nil'
    items=enumerate(value) if isinstance(value,list) else value.items()
    body=[]
    for k,v in items:
        prefix='' if isinstance(value,list) else f'[{lua(k)}]='
        body.append(' '*(indent+4)+prefix+lua(v,indent+4)+',')
    return '{\n'+'\n'.join(body)+'\n'+' '*indent+'}'

def field(n,k,v):E.SubElement(n,k).text=str(v).lower() if isinstance(v,bool) else str(v)
def cond(n,key,value,typ='STRING'):
    c=E.SubElement(n,'m_Conditions')
    for k,v in [('m_Name',key),('m_Type',typ),('m_Value',value)]:field(c,k,v)
def event(n,key,value,when='Start'):
    e=E.SubElement(n,'m_Events');field(e,'m_EventName',key)
    field(e,'m_Time' if isinstance(when,str) else 'm_TimePc',when);field(e,'m_ParameterValue',value)
def mask(n,bone):
    b=E.SubElement(n,'m_SubStateBoneWeights');field(b,'boneName',bone);field(b,'weight',1);field(b,'includeDescendants',True)
def node(c,group,name=None):
    n=E.Element('animNode');field(n,'m_Name',name or c['name']);field(n,'m_AnimName',c['name'])
    field(n,'m_Priority',5);field(n,'m_ConditionPriority',220)
    field(n,'m_Looped',c['kind']=='idle' or c.get('phase')=='hold')
    field(n,'m_SpeedScale','ProjectYakuzaCombatSpeed' if group in ('melee','stomp') else 1.35 if c['kind']=='quickstep' else 1)
    field(n,'m_BlendTime',.10 if c['kind']=='idle' else .07);field(n,'m_BlendOutTime',.10)
    field(n,'m_EarlyTransitionOut',True);field(n,'m_SyncTrackingEnabled',False)
    cond(n,'ProjectYakuzaStyle',STYLE);cond(n,'ProjectYakuzaActive','true','BOOL')
    return n

def save(n,group):
    dest=MEDIA/'AnimSets/player'/group/(n.findtext('m_Name')+'.xml');dest.parent.mkdir(parents=True,exist_ok=True)
    E.indent(n);E.ElementTree(n).write(dest,encoding='utf-8',xml_declaration=True)

def publish(n,group):
    save(n,group)
    if group not in ('melee','stomp','actions'):return
    conditions=[{'name':c.findtext('m_Name'),'value':c.findtext('m_Value')} for c in n.findall('m_Conditions')]
    record={'id':n.findtext('m_Name'),'animation':n.findtext('m_AnimName'),'group':group,
            'priority':220,'loop':n.findtext('m_Looped')=='true','conditions':conditions}
    records.append(record)
    for observer_group in ({'actions',group}):
        for cycle in (0,1):
            o=copy.deepcopy(n)
            for tag in ['m_Conditions','m_Events']:
                for c in o.findall(tag):o.remove(c)
            o.find('m_Name').text='ProjectYakuza_MD_MP_'+record['id']+f'_Cycle{cycle}'
            o.find('m_Priority').text='9';o.find('m_ConditionPriority').text='500'
            cond(o,'ProjectYakuzaRemoteObserver','true','BOOL')
            cond(o,'ProjectYakuzaRemoteClip',record['id']);cond(o,'ProjectYakuzaRemoteCycle',str(cycle))
            save(o,observer_group)

for c in CLIPS:
    kind=c['kind'];name=c['name'];i=c.get('index',1)
    if kind in ('light','finisher','quickstepAttack','runningAttack','ground'):
        value={'light':f'md_light_{i:02}','finisher':f'md_finisher_{i:02}',
               'quickstepAttack':f'md_quickattack_{i:02}','runningAttack':'md_run_slash','ground':'md_ground_slash'}[kind]
        groups=['melee','stomp'] if kind=='ground' else ['melee']
        for group in groups:
            n=node(c,group,name+('_NativeStomp' if group=='stomp' else ''))
            if kind=='ground':
                cond(n,'DFCGroundEnabled','true','BOOL');cond(n,'ProjectYakuzaStompVariant','1')
                cond(n,'AimFloorAnim','true','BOOL')
            else:cond(n,'ProjectYakuzaMove',value);cond(n,'AimFloorAnim','false','BOOL')
            if kind!='light':
                event(n,'BlockMovement','TRUE');event(n,'BlockMovement','FALSE','End')
            attack='StompAnim' if group=='stomp' else 'AttackAnim'
            event(n,attack,'TRUE');event(n,attack,'FALSE','End')
            event(n,'SetVariable','ProjectYakuzaClipStarted='+value)
            contact=c['impact_frame']/c['frames']
            event(n,'SetVariable','ProjectYakuzaHitMarker='+value,contact)
            event(n,'SetVariable','ZombieHitReaction='+('Floor' if kind=='ground' else 'HeadLeft'),.05)
            event(n,'AttackCollisionCheck','Stomp' if group=='stomp' else 'MeleeToFloor' if kind=='ground' else 'MeleeSwing',contact)
            event(n,'SetMeleeDelay','0','End');mask(n,'Bip01')
            if kind=='light':event(n,'SetVariable','ProjectYakuzaChainReady='+value,.62)
            if kind=='runningAttack':
                for step in range(11):event(n,'SetVariable',f'ProjectYakuzaRunProgress={step/10}',step/10*.4)
            publish(n,group)
    elif kind=='quickstep':
        n=node(c,'actions');cond(n,'PerformingAction',name);mask(n,'Bip01')
        value=f'md_quickstep_{i:02}'
        event(n,'SetVariable','ProjectYakuzaQuickstepStarted='+value)
        event(n,'SetVariable','ProjectYakuzaQuickstepDone='+value,'End')
        for step in range(13):event(n,'SetVariable',f'ProjectYakuzaQuickstepProgress={step/12}',step/12*.75)
        publish(n,'actions')
    elif kind=='idle':
        for group in ('aim','aim-strafe'):
            n=node(c,group);cond(n,'Aim','true','BOOL');cond(n,'Weapon','1handed')
            field(n,'m_maxTorsoTwist',45)
            for bone in ('Bip01_Spine1','Bip01_Prop1','Bip01_Prop2'):mask(n,bone)
            publish(n,group)
    elif kind=='guard':
        n=node(c,'actions');phase=c['phase']
        cond(n,'PerformingAction','ProjectYakuza_MD_Guard');cond(n,'ProjectYakuzaDefensePhase',phase)
        event(n,'SetVariable',f'ProjectYakuzaDefenseMarker={phase}_started')
        if phase!='hold':event(n,'SetVariable',f'ProjectYakuzaDefenseMarker={phase}_'+('done' if phase=='exit' else 'ready'),.9)
        for bone in ('Bip01_Spine1','Bip01_Prop1','Bip01_Prop2'):mask(n,bone)
        publish(n,'actions')
    else:
        n=node(c,'actions');cond(n,'PerformingAction',name);mask(n,'Bip01')
        marker='ProjectYakuzaTaunt' if kind=='taunt' else 'ProjectYakuzaHeatActivation'
        event(n,'SetVariable',marker+'=started');event(n,'SetVariable',marker+'=done','End')
        if kind=='heatActivation':event(n,'SetVariable',marker+'=flare',.55)
        publish(n,'actions')

records.sort(key=lambda r:-r['priority'])
shared=MEDIA/'lua/shared/ProjectYakuzaMadDog'
(shared/'NetworkCatalog.lua').write_text('require "ProjectYakuza/NetworkCatalog"\nProjectYakuza.NetworkCatalog["'+STYLE+'"]='+lua(records)+'\n')
motions={c['name'].replace('ProjectYakuza_MD_',''):{'animation':c['name'],'duration':c['duration'],
    **({'impact':c['impact_frame']/c['frames']} if c['impact_frame'] is not None else {})} for c in CLIPS}
(shared/'Motions.lua').write_text('-- Original Yakuza 0 clip timings. Rebuild with tools/mad-dog/build_nodes.py.\nreturn '+lua(motions)+'\n')
(ADDON/'docs/observer-nodes.json').write_text(json.dumps(records,indent=2)+'\n')
print('Built',len(records),'owner nodes, event-free observers for both network cycles, and motion timings.')
