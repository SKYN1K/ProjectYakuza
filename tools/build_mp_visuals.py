from pathlib import Path
import xml.etree.ElementTree as E,copy,json
w=Path(__file__).parent;m=w.parent/'combat/DragonCombatFramework';root=m/'42/media'
records=[]
for group in ['melee','stomp','actions']:
 for p in sorted((root/'AnimSets/player'/group).glob('DCF_DD_*.xml')):
  n=E.parse(p).getroot();conds=[{'name':c.findtext('m_Name'),'value':c.findtext('m_Value')} for c in n.findall('m_Conditions')]
  priority=int(n.findtext('m_ConditionPriority') or 0)
  entry={'id':n.findtext('m_Name'),'animation':n.findtext('m_AnimName'),'loop':n.findtext('m_Looped')=='true','conditions':conds,'priority':priority,'group':group}
  records.append(entry)
  observer=copy.deepcopy(n)
  for tag in ['m_Conditions','m_Events','m_2DBlends']:
   for child in list(observer.findall(tag)):observer.remove(child)
  observer.find('m_Name').text='DCF_MP_'+entry['id'];observer.find('m_Priority').text='9';observer.find('m_ConditionPriority').text='500'
  for name,value in [('DCFRemoteObserver','true'),('DCFRemoteClip',entry['id'])]:
   c=E.SubElement(observer,'m_Conditions')
   for k,v in [('m_Name',name),('m_Type','BOOL' if name=='DCFRemoteObserver' else 'STRING'),('m_Value',value)]:E.SubElement(c,k).text=v
  dest=root/'AnimSets/player/actions'/('DCF_MP_'+p.name);E.ElementTree(observer).write(dest,encoding='utf-8',xml_declaration=True)
  if group in ('melee','stomp'):
   native=copy.deepcopy(observer)
   for child in list(native.findall('m_Conditions')):native.remove(child)
   native.find('m_Name').text='DCF_MP_Native_'+entry['id']
   for name,typ,value in [('DCFRemoteObserver','BOOL','true'),('DCFRemoteClip','STRING',entry['id'])]:
    c=E.SubElement(native,'m_Conditions')
    for k,v in [('m_Name',name),('m_Type',typ),('m_Value',value)]:E.SubElement(c,k).text=v
   E.ElementTree(native).write(root/'AnimSets/player'/group/('DCF_MP_'+p.name),encoding='utf-8',xml_declaration=True)

# Two event-free nodes let the same clip restart on a new network action/swing
# serial. Merely assigning the same DCFRemoteClip string leaves the old node live.
for p in (root/'AnimSets/player').rglob('DCF_MP_*.xml'):
 if '_Cycle1' in p.stem:continue
 node=E.parse(p).getroot()
 c=E.SubElement(node,'m_Conditions')
 for k,v in [('m_Name','DCFRemoteCycle'),('m_Type','STRING'),('m_Value','0')]:E.SubElement(c,k).text=v
 E.ElementTree(node).write(p,encoding='utf-8',xml_declaration=True)
 other=copy.deepcopy(node);other.find('m_Name').text += '_Cycle1'
 other.findall('m_Conditions')[-1].find('m_Value').text='1'
 E.ElementTree(other).write(p.with_stem(p.stem+'_Cycle1'),encoding='utf-8',xml_declaration=True)

# B42 changes from hitreaction to hitreaction-hit on another wasHit event.
# Keep the supplied reaction clips available in that native repeat-hit group.
repeat=root/'AnimSets/zombie/hitreaction-hit';repeat.mkdir(exist_ok=True)
for p in (root/'AnimSets/zombie/hitreaction').glob('DCF_EnemyHit*.xml'):
 E.ElementTree(E.parse(p).getroot()).write(repeat/p.name,encoding='utf-8',xml_declaration=True)
def lua(value):
 if isinstance(value,bool):return 'true' if value else 'false'
 if isinstance(value,str):return json.dumps(value)
 if isinstance(value,(int,float)):return str(value)
 if isinstance(value,list):return '{'+','.join(lua(v) for v in value)+'}'
 return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
records.sort(key=lambda r:-r['priority'])
dest=root/'lua/shared/DCF/NetworkCatalog.lua'
dest.write_text('require "DCF/Registry"\nDragonCombat.NetworkCatalog=DragonCombat.NetworkCatalog or {}\nDragonCombat.NetworkCatalog.dragon_of_dojima='+lua(records)+'\n',encoding='utf-8')
(m/'docs/mp-observer-nodes.json').write_text(json.dumps(records,indent=2))
print('Built',len(records),'observer animation nodes with zero collision/animation events; no animation assets changed')
