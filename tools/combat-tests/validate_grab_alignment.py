from pathlib import Path
import sys,re,json,hashlib
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(Path(__file__).parent))
from locomotion_math import read,locals_at,world
mod=root/'combat/ProjectYakuza';clips=mod/'42/media/anims_X/Bob';style=(mod/'42/media/lua/shared/ProjectYakuza/Styles/DragonOfDojima.lua').read_text();moves=(mod/'42/media/lua/shared/ProjectYakuza/GrabMoves.lua').read_text();records=[]
def bone(name,frame,key):
 p=clips/('ProjectYakuza_DD_'+name+'.x');_,b,c,_=read(p)
 return list(world(b,locals_at(b,c,frame*160))[key].translation),hashlib.sha256(p.read_bytes()).hexdigest()
def verify(actor,victim,frame,actual):
 hand,ah=bone(actor,frame,'Bip01_L_Hand');neck,vh=bone(victim,frame,'Bip01_Neck');expected=[-1.5*(hand[2]+neck[2]),1.5*(hand[0]+neck[0])]
 assert max(abs(a-b)for a,b in zip(expected,actual))<.000002,(actor,expected,actual)
 records.append({'actor':actor,'victim':victim,'frame':frame,'actorSha256':ah,'victimSha256':vh,'hand':hand,'neck':neck,'expected':expected,'configured':actual})
hold=re.search(r'grab = \{enabled=true,distance=([\d.]+),lateral=([\d.]+)',style);verify('GrabHold','GrabVictimHoldNative',0,[float(v)for v in hold.groups()])
throw=re.search(r'throwOffset=\{forward=([\d.]+),right=([\d.]+)',style);verify('Throw','ThrowVictim',0,[float(v)for v in throw.groups()])
for i,row in enumerate(re.finditer(r'pairOffset=\{forward=([\d.-]+),right=([\d.-]+)\},animation="ProjectYakuza_DD_GrabStrike(\d+)"',moves),1):
 assert int(row[3])==i
 verify('GrabStrike%02d'%i,'GrabStrikeVictim%02d'%i,7 if i==1 else 17,[float(row[1]),float(row[2])])
assert len(records)==6
print(json.dumps({'operation':'Code-only root staging from existing converted PZ skeleton left-hand and victim neck transforms; source clips unchanged. Forward=-modelZ*1.5; right=modelX*1.5; victim faces actor, so horizontal coordinates sum. No motion, visual or audio files created.','pairs':records},indent=2))
print('PASS six native-skeleton grab/strike/throw offsets within 0.000002 tiles; no animation files modified')
