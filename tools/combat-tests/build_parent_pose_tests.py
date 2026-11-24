from pathlib import Path
import json,subprocess
W=Path(__file__).parent;ROOT=W.parents[1];MOD=ROOT/'combat/ProjectYakuza';GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid');cache=W/'parent-poses-native'
report=json.loads((MOD/'docs/parent-pose-prediction.json').read_text());sources={r['animation']:r['source']for r in report['clips']}
attacks=['Light01','BladeLight01','KnifeLight01','BatLight01','BottleLight01','BoostLight01','GrabStrike01','GrabStrike02','GrabStrike03','GrabStrike04'];bases=['Bob_Idle','Bob_Walk','ProjectYakuza_DD_CrateWalk'];jobs=[]
for a in attacks:
 name='ProjectYakuza_DD_'+a;xml=next((MOD/'42/media/AnimSets/player').rglob(name+'.xml'))
 for b in bases:jobs.append('\t'.join([sources[b],sources[name],str(xml.resolve())]))
for a in attacks:
 name='ProjectYakuza_DD_'+a;xml=next((MOD/'42/media/AnimSets/player').rglob(name+'.xml'));jobs.append('\t'.join([sources['Bob_Idle'],sources[name],str(xml.resolve()),sources['Bob_Walk']]))
listing=cache/'masked-jobs.tsv';listing.write_text('\n'.join(jobs)+'\n');masked=cache/'masked-reference.json'
subprocess.run([str(GAME/'jre64/bin/java.exe'),'-Xms16m','-Xmx384m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;'+str(GAME/'*'),'MaskedLimbPoseProbe',str(listing.resolve()),str(masked.resolve())],cwd=W,check=True)
ref=[]
for clip in report['clips']:
 d=json.loads((cache/(clip['animation']+'.json')).read_text());size=len(d['frames'])
 for frame in sorted({0,size//4,size//2,size*3//4,size-1}):
  ref.append([clip['animation'],frame/30,d['reference'][frame]])
num=lambda x:format(x,'.10g')
def lua(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
 if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x)for k,x in v.items())+'}'
 return num(v)
cases=json.loads(masked.read_text())
for row in cases:
 d=json.loads((W/'all-trail-native120'/(row['animation']+'.json')).read_text());frame=row['time']*120;i=int(frame);t=frame-i
 row['raw']=[[a+(b-a)*t for a,b in zip(d['frames'][i][bone],d['frames'][min(i+1,len(d['frames'])-1)][bone])]for bone in [12,0,1,2,13,3,4,5]]
s='require=function()end\nProjectYakuza={}\n'
for name in ['ParentPoseTracks','ParentPosePrediction']:s+='do\n'+(MOD/'42/media/lua/client/ProjectYakuza'/(name+'.lua')).read_text()+'\nend\n'
s+='local P=ProjectYakuza.ParentPosePrediction;local checks=0;local worst=0;local rawWorst=0\nlocal function check(v,m)checks=checks+1;assert(v,m)end\n'
s+='local refs='+lua(ref)+'\n'
s+='''for _,r in ipairs(refs)do for bone=1,4 do
 local actual=P.parent(ProjectYakuza.ParentPoseTracks[r[1]],r[2],bone)
 for i=1,12 do check(math.abs(actual[i]-r[3][bone][i])<.00004,'native parent matrix '..r[1])end
end end
'''
s+='local cases='+lua(cases)+'\n'
s+='''for _,row in ipairs(cases)do
 local p={dbgGetAnimTrackName=function(_,layer,slot)if layer~=0 then return ''end;return slot==0 and row.base or slot==1 and row.base2 or ''end,dbgGetAnimTrackTime=function()return row.baseTime end,dbgGetAnimTrackWeight=function(_,layer,slot)return row.base2 and(slot==0 and .35 or .65)or 1 end}
 local correction=P.correction(p,row.animation,row.time);check(correction~=nil,'masked attack resolves actual standing/walking parent')
 for i,raw in ipairs(row.raw)do
  local x,y,z=P.point(correction,raw[1],raw[2],raw[3]);local expected=row.points[i]
  local error=math.sqrt((x-expected[1])^2+(y-expected[2])^2+(z-expected[3])^2);worst=math.max(worst,error)
  check(error<.00006,'actual native masked limb '..row.animation..' / '..row.base)
  local uncorrected=math.sqrt((raw[1]-expected[1])^2+(raw[2]-expected[2])^2+(raw[3]-expected[3])^2);rawWorst=math.max(rawWorst,uncorrected)
 end
end
check(rawWorst>.1,'regression reproduces substantial original full-body mismatch')
check(ProjectYakuza.ParentPoseMasks.ProjectYakuza_DD_BicycleHeat==nil,'full-body Heat Actions keep their source pose')
local unknown={dbgGetAnimTrackName=function()return 'UnknownModPose'end,dbgGetAnimTrackTime=function()return 0 end,dbgGetAnimTrackWeight=function()return 1 end}
check(P.correction(unknown,'ProjectYakuza_DD_Light01',.2)==nil,'unknown base safely preserves the source pose')
return 'PASS '..checks..' native parent/masked limb assertions; corrected max model error '..worst..'; original max offset '..rawWorst
'''
(W/'parent-pose-tests.lua').write_text(s,newline='\n');print('PASS fixture contains',len(ref),'native parent poses and',len(cases),'actual layered AnimationPlayer poses')
