from pathlib import Path
import sys,json,hashlib,copy,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';media=mod/'42/media';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob');sources=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack/gmt');sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/style-travel-build'");records=[];selectors=[]
for label,stem,nativeName,cycles in [('Walk','P_KRU_MOV_wlk_ftl','Bob_Walk',1),('WalkSlow','P_KRU_MOV_wlk_ftl','Bob_WalkSlow',1),('Sprint','P_KRU_MOV_run_ftl_ex','Bob_Sprint',1)]:
    name='ProjectYakuza_DD_'+label;src=sources/(stem+'.gmt');sys.argv=['convert','--',name,str(src)];ns={'FINGER_SOURCE':'Bob_Run.x'};exec(compile(converter,'retarget_style_travel','exec'),ns)
    raw=root/'tools/style-travel-build/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x');_,sf,sa,_=read(raw);base=native/(nativeName+'.x');text,f,a,spans=read(base);end=max(t for c in a.values()for ks in c.values()for t,v in ks);count=66 if label.startswith('Walk')else ns['a'].end_frame+1;times=[round(i*end*cycles/(count-1))for i in range(count)];values=[]
    for i,t in enumerate(times):
        local=locals_at(f,a,t%end if t<end*cycles else end);source=locals_at(sf,sa,i*160)
        for n,v in source.items():
            if n not in ['Body','Translation_Data']:local[n]=v
        cycle=min(cycles-1,t//end);phase=t-cycle*end;travel=locals_at(f,a,phase)['Translation_Data'];delta=locals_at(f,a,end)['Translation_Data'].translation-locals_at(f,a,0)['Translation_Data'].translation;travel.translation+=delta*cycle;local['Translation_Data']=travel;values.append(local)
    out=media/'anims_X/Bob'/(name+'.x');write(out,text,spans,blocks(f,values,times,None),name)
    records.append({'name':name,'source':str(src),'sourceSha256':sha(src),'retarget':str(raw),'retargetSha256':sha(raw),'native':str(base),'nativeSha256':sha(base),'output':out.relative_to(mod).as_posix(),'sha256':sha(out),'sourceFrames':count,'sourceFps':30,'nativeCycles':cycles,'duration':end*cycles/4800,'times':times})

def put(n,k,v):
    e=n.find(k)
    if e is None:e=E.SubElement(n,k)
    e.text=str(v).lower()if isinstance(v,bool)else str(v)

for group,label,template in [('movement','Walk','defaultWalk'),('sprint','Sprint','defaultSprint')]:
    n=E.parse(Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/AnimSets/player')/group/(template+'.xml')).getroot();name='ProjectYakuza_DD_Locomotion'+label;put(n,'m_Name',name);put(n,'m_AnimName','ProjectYakuza_DD_'+label)
    for c in list(n.findall('m_Conditions')):n.remove(c)
    for key,typ,value in [('ProjectYakuzaActive','BOOL','true'),('ProjectYakuzaStyle','STRING','dragon_of_dojima'),('ProjectYakuzaWeaponProfile','STRING',''),('Aim','BOOL','false'),('isTurningAround','BOOL','false'),('inTrees','BOOL','false'),('WalkInjury','EQU','0'),('isOverEncumbered','BOOL','false'),('sneaking','BOOL','false')]:
        c=E.SubElement(n,'m_Conditions');put(c,'m_Name',key);put(c,'m_Type',typ);put(c,'m_Value',value)
    put(n,'m_ConditionPriority',160);put(n,'m_BlendTime',.25);put(n,'m_BlendOutTime',.25);put(n,'m_Looped',True);put(n,'m_SyncTrackingEnabled',True)
    for b in n.findall('m_2DBlends'):
        clip=b.findtext('m_AnimName')
        if clip=='Bob_Walk':put(b,'m_AnimName','ProjectYakuza_DD_Walk')
        if clip=='Bob_WalkSlow':put(b,'m_AnimName','ProjectYakuza_DD_WalkSlow')
        if clip=='Bob_Sprint':put(b,'m_AnimName','ProjectYakuza_DD_Sprint')
        if clip=='Bob_Run'and group=='sprint':put(b,'m_AnimName','ProjectYakuza_DD_Run');put(b,'m_SpeedScale',1)
    for e in n.findall('m_Transitions'):
        a=e.find('m_AnimName')
        if a is not None:e.remove(a)
    if label=='Walk':
        for e in list(n.findall('m_Events')):n.remove(e)
        for i in range(2):
            e=E.SubElement(n,'m_Events');put(e,'m_EventName','Footstep');put(e,'m_TimePc',.2+i*.5);put(e,'m_ParameterValue','walk')
    else:
        for i,e in enumerate(n.findall('m_Events')):put(e,'m_TimePc',.03+i*.5)
    out=media/'AnimSets/player'/group/(name+'.xml');out.parent.mkdir(parents=True,exist_ok=True);E.indent(n,space='  ');E.ElementTree(n).write(out,encoding='utf-8',xml_declaration=True);selectors.append({'path':out.relative_to(mod).as_posix(),'sha256':sha(out)})
report={'authorization':'User approved original Kiryu walk/sprint conversion and movement-speed matching on 2026-11-03.','operation':'Kiryu normal walk uses the first complete 65-frame gait cycle of the supplied eight-cycle loop; supplied run_ftl_ex is retimed for PZ sprint. Source samples are retimed to native B42 gait-cycle durations, retaining native travel distances and per-second speed. Existing native injury/tree/turn/sneak fallbacks remain. No AI or invented motion, artwork or sound.','clips':records,'selectors':selectors}
(mod/'docs/style-travel-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('BUILT source walk/sprint with native cadence and travel')

