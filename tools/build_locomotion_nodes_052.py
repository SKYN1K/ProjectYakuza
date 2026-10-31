from pathlib import Path
import xml.etree.ElementTree as E,json
root=Path.cwd();mod=root/'combat/ProjectYakuza';media=mod/'42/media';native=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid/media/AnimSets/player');records=[]
def put(n,k,v):
 e=n.find(k)
 if e is None:e=E.SubElement(n,k)
 e.text=str(v).lower() if isinstance(v,bool) else str(v)
def cond(n,k,v,t='STRING'):
 e=E.SubElement(n,'m_Conditions');put(e,'m_Name',k);put(e,'m_Type',t);put(e,'m_Value',v)
def save(n,group,name):
 p=media/'AnimSets/player'/group/(name+'.xml');p.parent.mkdir(parents=True,exist_ok=True);E.indent(n,space='  ');E.ElementTree(n).write(p,encoding='utf-8',xml_declaration=True)
 records.append(p.relative_to(mod).as_posix())
def scoped(n,family):
 for e in list(n.findall('m_Conditions')):n.remove(e)
 cond(n,'ProjectYakuzaActive',True,'BOOL');cond(n,'ProjectYakuzaStyle','dragon_of_dojima');cond(n,'ProjectYakuzaWeaponProfile',family.lower())
 cond(n,'Aim',False,'BOOL');cond(n,'isTurningAround',False,'BOOL');cond(n,'inTrees',False,'BOOL');cond(n,'WalkInjury',0,'EQU');cond(n,'isOverEncumbered',False,'BOOL');cond(n,'sneaking',False,'BOOL')
 put(n,'m_ConditionPriority',160);put(n,'m_BlendTime',.25);put(n,'m_BlendOutTime',.25);put(n,'m_Looped',True)
 for e in n.findall('m_Transitions'):
  a=e.find('m_AnimName')
  if a is not None:e.remove(a)
 for f in ['','Bat','Knife','Blade']:
  for suffix in ['Run','Carry','Walk']:
   if not f and suffix!='Run':continue
   e=E.SubElement(n,'m_Transitions');put(e,'m_Target','ProjectYakuza_DD_Locomotion'+f+suffix);put(e,'m_blendInTime',.25);put(e,'m_blendOutTime',.25)
 for f in ['Bat','Knife','Blade']:
  e=E.SubElement(n,'m_Transitions');put(e,'m_Target','ProjectYakuza_DD_'+f+'Idle');put(e,'m_blendInTime',.25);put(e,'m_blendOutTime',.25)
for family in ['','Bat','Knife','Blade']:
 n=E.parse(native/'run/defaultRun.xml').getroot();name='ProjectYakuza_DD_Locomotion'+family+'Run';put(n,'m_Name',name);put(n,'m_AnimName','ProjectYakuza_DD_'+family+'Run');scoped(n,family)
 for b in n.findall('m_2DBlends'):
  if b.findtext('m_AnimName')=='Bob_Run':put(b,'m_AnimName','ProjectYakuza_DD_'+family+'Run');put(b,'m_SpeedScale',1.0)
  elif b.findtext('m_AnimName')=='Bob_Walk' and family:put(b,'m_AnimName','Bob_Walk'if family=='Knife'else'Bob_WalkBat')
 put(n,'m_SyncTrackingEnabled',True)
 for i,e in enumerate(n.findall('m_Events')):put(e,'m_TimePc',.03+i*.5)
 save(n,'run',name)
 if not family:continue
 n=E.parse(native/'idle/Idle.xml').getroot();name='ProjectYakuza_DD_Locomotion'+family+'Carry';put(n,'m_Name',name);put(n,'m_AnimName','Bob_Idle'if family=='Knife'else'Bob_IdleBat');scoped(n,family);cond(n,'isTurning90',False,'BOOL')
 for tag in ['m_2DBlends','m_2DBlendTri','m_Scalar','m_Scalar2']:
  for e in list(n.findall(tag)):n.remove(e)
 put(n,'m_SpeedScale',1);save(n,'idle',name)
 n=E.parse(native/'movement/defaultWalk.xml').getroot();name='ProjectYakuza_DD_Locomotion'+family+'Walk';put(n,'m_Name',name);put(n,'m_AnimName','Bob_Walk'if family=='Knife'else'Bob_WalkBat');scoped(n,family)
 for b in n.findall('m_2DBlends'):
  old=b.findtext('m_AnimName')
  if old in ['Bob_Walk','Bob_WalkSlow']:put(b,'m_AnimName',old if family=='Knife'else'Bob_WalkSlow_Bat'if old=='Bob_WalkSlow'else'Bob_WalkBat')
 save(n,'movement',name)
(mod/'docs/locomotion-nodes.json').write_text(json.dumps({'nodes':records,'blendSeconds':.25,'runHealthySpeedScale':1.0,'nativeTravelScale':1.28,'nativeRunCycleSeconds':2/3,'sourceRunCycleSeconds':32/30,'operation':'DoD-only non-aimed run and unlocked weapon carry selectors. Existing injury, tree, overburdened and turn nodes remain native. Carry-walk lower body uses existing native walking. No actor displacement or speed changes.'},indent=2)+'\n',encoding='utf-8')
print('BUILT',len(records),'isolated locomotion selectors')
