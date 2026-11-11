from pathlib import Path
import sys,json,hashlib,struct,zipfile,xml.etree.ElementTree as E
from mathutils import Matrix

root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,world,blocks,write
from weapon_hold_geometry import source_pose,fit_arms
mod=root/'combat/ProjectYakuza';media=mod/'42/media';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/anims_X/Bob');sources=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack')
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/weapon-motion-build'")
records=[];selectors=[];grips={};moves={};contexts={}

def convert(name,stem,finger):
    src=sources/'gmt'/(stem+'.gmt');sys.argv=['convert','--',name,str(src)];ns={'FINGER_SOURCE':finger};exec(compile(converter,'retarget_weapon_motion','exec'),ns)
    path=root/'tools/weapon-motion-build/ProjectYakuza/42/media/anims_X/Bob'/(name+'.x')
    contexts[path]=ns
    return path,{'source':str(src),'sourceSha256':sha(src),'retarget':str(path),'retargetSha256':sha(path),'frames':ns['a'].end_frame+1,'fps':30,'fingerSource':str(native/finger),'fingerSha256':sha(native/finger)}

def native_grip(tag,filename):
    path=native/(filename+'.x');_,f,a,_=read(path);w=world(f,locals_at(f,a,0));offsets={}
    for hand,prop in [('Bip01_R_Hand','Bip01_Prop1'),('Bip01_L_Hand','Bip01_Prop2')]:offsets[prop]=[list(row)for row in w[hand].inverted()@w[prop]]
    grips[tag]={'source':str(path),'sha256':sha(path),'frame':0,'authoredOffsets':offsets,'nativeOffsets':offsets}

for tag,filename in [('bat','Bob_IdleBat'),('blade','Bob_IdleBat'),('bottle','Bob_IdleNoAim1Hand'),('crate','Bob_IdleBat')]:native_grip(tag,filename)

def put(n,k,v):
    e=n.find(k)
    if e is None:e=E.SubElement(n,k)
    e.text=str(v).lower()if isinstance(v,bool)else str(v)

def save(n,path):
    if path.parent.name in ['melee','actions']:put(n,'m_BlendTime',.14);put(n,'m_BlendOutTime',.20)
    E.indent(n,space='  ');E.ElementTree(n).write(path,encoding='utf-8',xml_declaration=True)
    selectors.append({'path':path.relative_to(mod).as_posix(),'sha256':sha(path)})

for family,sourceFamily,grip in [('Bat','WPA','bat'),('Blade','WPD','blade'),('Bottle','WPA','bottle'),('Crate','WPC','crate')]:
    finger='Bob_AttackBat01_Hit.x'if family in ['Bat','Blade','Crate']else'Bob_AttackKnife01_Hit.x'
    inputs={}
    for key,stem in [('Ready','P_KRU_BTL_'+sourceFamily+'_stdA_lp'),('Relaxed','P_KRU_BTL_'+sourceFamily+'_stdB_lp'),('Walk','P_KRU_MOV_wlk_ftl_wpd'if family=='Blade'else'P_KRU_MOV_wlk_ftl_wpc'if family=='Crate'else'P_KRU_MOV_wlk_ftl_btl'),('Run','P_KRU_MOV_run_ftl_wpd'if family=='Blade'else'P_KRU_MOV_run_ftl')]:
        name='ProjectYakuza_DD_'+family+key;path,record=convert(name,stem,finger);inputs[key]=(path,record)
    for label,baseName,hold in [('Ready','Bob_IdleAimBat'if family!='Bottle'else'Bob_IdleAim1Hand','Ready'),('RelaxedIdle','Bob_IdleBat'if family!='Bottle'else'Bob_Idle','Relaxed'),('RelaxedWalk','Bob_WalkBat'if family!='Bottle'else'Bob_Walk','Walk'),('RelaxedSlow','Bob_WalkSlow_Bat'if family!='Bottle'else'Bob_WalkSlow','Walk'),('RelaxedRun','ProjectYakuza_DD_Run','Run'),('RelaxedSprint','ProjectYakuza_DD_Sprint','Run')]:
        armPath,sourceRecord=inputs[hold];_,af,aa,_=read(armPath);armEnd=(sourceRecord['frames']-1)*160
        base=(media/'anims_X/Bob'if baseName.startswith('Project')else native)/(baseName+'.x');text,f,a,spans=read(base);nativeEnd=max(t for c in a.values()for keys in c.values()for t,v in keys);end=armEnd if label in ['Ready','RelaxedIdle']else nativeEnd
        times=list(range(0,end+1,160));upper=set(['Bip01_L_Clavicle','Bip01_R_Clavicle'])
        for n,d in f.items():
            if d['parent']in upper:upper.add(n)
        values=[];fitted=label in ['Ready','RelaxedIdle','RelaxedWalk','RelaxedSlow']
        for t in times:
            bodyTime=t%nativeEnd if t<end else nativeEnd;local=locals_at(f,a,bodyTime);sourceWorld=world(af,locals_at(af,aa,t/end*armEnd));target={}
            if fitted:
                frame=t/end*(sourceRecord['frames']-1);source=source_pose(contexts[armPath],frame);fingers=locals_at(af,aa,t/end*armEnd);local,geometry=fit_arms(f,local,source,contexts[armPath]['bind'],fingers);values.append(local);continue
            for n,d in f.items():
                parent=d['parent']
                if n in upper and n in sourceWorld:
                    rotation=sourceWorld[n].to_quaternion().to_matrix().to_4x4()
                    value=target[parent].inverted()@rotation if parent else rotation
                    value.translation=local[n].translation;local[n]=value
                target[n]=target[parent]@local[n]if parent else local[n]
            values.append(local)
        name='ProjectYakuza_DD_'+family+label;output=media/'anims_X/Bob'/(name+'.x');write(output,text,spans,blocks(f,values,times,grips[grip]),name)
        records.append({**sourceRecord,'name':name,'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'frames':len(times),'sourceFrames':sourceRecord['frames'],'native':str(base),'nativeSha256':sha(base),'nativeCycleTicks':nativeEnd,'duration':end/4800,'upperBones':sorted(upper),'grip':grip,'kind':'fittedArmComposite'if fitted else'worldArmComposite'})
    if family not in ['Bottle','Crate']:continue
    moves[family]=[]
    for label,suffix in [('Light01','ath_01_md'),('Light02','ath_02_md'),('Light03','ath_03_md'),('Heavy','ath_hvy_md'),('Ground','ath_dwn_md'),('GuardEnter','grd_st'),('GuardLoop','grd_lp'),('GuardHit','grd_rct_f'),('GuardExit','grd_en')]:
        name='ProjectYakuza_DD_'+family+label;path,r=convert(name,'P_KRU_BTL_'+sourceFamily+'_'+suffix,finger);text,f,a,spans=read(path);times=[i*160 for i in range(r['frames'])];values=[locals_at(f,a,t)for t in times];out=media/'anims_X/Bob'/(name+'.x');write(out,text,spans,blocks(f,values,times,grips[grip]),name)
        if label.startswith('Guard'):
            records.append({**r,'name':name,'output':out.relative_to(mod).as_posix(),'sha256':sha(out),'kind':'sourceGuard','grip':grip})
            template=media/'AnimSets/player/actions'/('ProjectYakuza_DD_Bat'+label+'.xml');n=E.parse(template).getroot();put(n,'m_Name',name);put(n,'m_AnimName',name)
            for c in n.findall('m_Conditions'):
                if c.findtext('m_Name')=='ProjectYakuzaWeaponProfile':put(c,'m_Value',family.lower())
                if c.findtext('m_Name')=='PerformingAction':put(c,'m_Value','ProjectYakuza_DD_'+family+'Guard')
            save(n,media/'AnimSets/player/actions'/(name+'.xml'));continue
        bep=sources/'bep'/('P_KRU_BTL_'+sourceFamily+'_'+suffix+'.bep');b=bep.read_bytes();pos=16;contacts=[]
        while pos+80<=len(b):
            section,kind,size=struct.unpack_from('<HHI',b,pos+64);data=b[pos+80:pos+80+size]
            if section==12 and kind==68:contacts.append(int(struct.unpack_from('<f',data,4)[0]))
            pos+=80+size
        assert contacts,(name,contacts)
        end=r['frames']-1;contact=contacts[0];chain=min(end-1,max(contact+5,round(end*.65)));node='dd_'+family.lower()+'_'+('light_'+label[-2:]if label.startswith('Light')else label.lower())
        moves[family].append({'animation':name,'nodeValue':node,'frames':end,'contact':contact,'chain':chain,'label':label})
        records.append({**r,'name':name,'output':out.relative_to(mod).as_posix(),'sha256':sha(out),'kind':'sourceAttack','grip':grip,'bep':str(bep),'bepSha256':sha(bep),'contactFrame':contact,'sourceContactFrames':contacts})
        template=media/'AnimSets/player/melee'/('ProjectYakuza_DD_Bat'+label+'.xml');n=E.parse(template).getroot();put(n,'m_Name',name);put(n,'m_AnimName',name)
        for c in n.findall('m_Conditions'):
            key=c.findtext('m_Name')
            if key=='ProjectYakuzaWeaponProfile':put(c,'m_Value',family.lower())
            if key=='ProjectYakuzaMove':put(c,'m_Value',node)
        for e in n.findall('m_Events'):
            event=e.findtext('m_EventName');value=e.findtext('m_ParameterValue')or''
            if event=='AttackCollisionCheck':put(e,'m_TimePc',contact/end)
            if event=='SetVariable':
                key=value.split('=')[0];put(e,'m_ParameterValue',key+'='+node)
                if key=='ProjectYakuzaHitMarker':put(e,'m_TimePc',contact/end)
                if key=='ProjectYakuzaChainReady':put(e,'m_TimePc',chain/end)
                if key=='ProjectYakuzaQuickstepCancelReady':put(e,'m_TimePc',(contact+1)/end)
        save(n,media/'AnimSets/player/melee'/(name+'.xml'))

for family in ['Bat','Blade','Bottle','Crate']:
    for group in ['aim','aim-strafe']:
        path=media/'AnimSets/player'/group/('ProjectYakuza_DD_'+family+'Idle.xml');template=path if path.exists()else media/'AnimSets/player'/group/'ProjectYakuza_DD_BatIdle.xml';n=E.parse(template).getroot();put(n,'m_Name','ProjectYakuza_DD_'+family+'Idle');put(n,'m_AnimName','ProjectYakuza_DD_'+family+'Ready');put(n,'m_maxTorsoTwist',0)
        for c in n.findall('m_Conditions'):
            if c.findtext('m_Name')=='ProjectYakuzaWeaponProfile':put(c,'m_Value',family.lower())
        save(n,path)
    for group,kind,suffix in [('idle','Carry','Idle'),('movement','Walk','Walk'),('run','Run','Run'),('sprint','Sprint','Sprint')]:
        name='ProjectYakuza_DD_Locomotion'+family+kind;path=media/'AnimSets/player'/group/(name+'.xml');template=path if path.exists()else media/'AnimSets/player'/group/('ProjectYakuza_DD_LocomotionSprint.xml'if kind=='Sprint'else'ProjectYakuza_DD_LocomotionBat'+kind+'.xml');n=E.parse(template).getroot();put(n,'m_Name',name);put(n,'m_AnimName','ProjectYakuza_DD_'+family+'Relaxed'+suffix)
        for c in n.findall('m_Conditions'):
            if c.findtext('m_Name')=='ProjectYakuzaWeaponProfile':put(c,'m_Value',family.lower())
        for b in n.findall('m_2DBlends'):
            clip=b.findtext('m_AnimName')
            if clip in ['Bob_Walk','Bob_WalkBat','Bob_WalkSlow','Bob_WalkSlow_Bat','Bob_Run','Bob_RunBat']or clip.startswith('ProjectYakuza_DD_'):
                label='Sprint'if'Sprint'in clip else'Run'if 'Run'in clip else'Slow'if'Slow'in clip else'Walk';put(b,'m_AnimName','ProjectYakuza_DD_'+family+'Relaxed'+label)
                if label=='Run':put(b,'m_SpeedScale',1)
        if group=='run':
            for i,e in enumerate(n.findall('m_Events')):put(e,'m_TimePc',.03+i*.5)
        save(n,path)

with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.75.0.zip')as previous:
    for record in records:record['beforeSha256']=hashlib.sha256(previous.read('ProjectYakuza/'+record['output'])).hexdigest()
report={'authorization':'User approved original bottle/crate, bat/katana conversions and repairs on 2026-11-03; requested continued Yakuza 6 motion with PZ skeleton adaptation.','operation':'Original WPA/WPC/WPD motions remain selected. Ready, relaxed idle and walking fit source shoulder/elbow/wrist segment directions relative to the source chest onto PZ chest orientation and anatomical bone lengths. Original wrist articulation is transferred relative to the forearm; native finger grip channels and prop offsets fit PZ hands. This corrects rest-axis and torso-basis mismatch without replacing the supplied hold animations. Native walking legs/head/torso remain unchanged. Katana grip uses the existing one-handed native bat carry attachment offset to clear its model from the neck. Attack body clips and running arm motion are unchanged; katana running prop offsets match the repaired hold grip. No AI, invented motion, artwork or sound.','geometryHelper':'tools/combat-tests/weapon_hold_geometry.py','geometrySha256':sha(root/'tools/combat-tests/weapon_hold_geometry.py'),'rig':'E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd','rigSha256':sha('E:/Blender/Yakuza Rips/yakuza6/chara.par.unpack/bone/c_man_bone.gmd'),'clips':records,'grips':grips,'selectors':selectors,'moves':moves}
(mod/'docs/weapon-motion-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print('BUILT',len(records),'source weapon motions;',len(selectors),'selectors')



from vanilla_pose_fallback import apply
apply()

import runpy
runpy.run_path(str(root/'tools/combat-tests/build_y5_object_attacks.py'),run_name='__main__')
