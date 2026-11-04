from pathlib import Path
import sys,json,hashlib,struct,xml.etree.ElementTree as E
root=Path(__file__).resolve().parents[2];sys.path.insert(0,str(root/'tools/combat-tests'))
from locomotion_math import read,locals_at,blocks,write
mod=root/'combat/ProjectYakuza';src=Path('E:/Blender/Yakuza Rips/yakuza6/motion.par.unpack');grip=json.loads((mod/'docs/prop-attachment-repair.json').read_text())['nativeGrips']['bat'];records=[];moves=[]
converter=(root/'tools/combat-tests/retarget_locomotion.py').read_text().replace("OUT=DEST/'tools/locomotion-build'","OUT=DEST/'tools/grab-strike-build'")
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
for index in range(1,5):
    pair=[]
    for role in [0,1]:
        name='ProjectYakuza_DD_GrabStrike'+('Victim'if role else '')+f'{index:02}'
        source=src/'gmt'/f'P_KRU_BTL_SUD_sy{role}_gsp_{index:02}.gmt';sys.argv=['convert','--',name,str(source)];ns={'FINGER_SOURCE':'Bob_AttackPunch01_Hit.x'};exec(compile(converter,'retarget_original_grab_strike','exec'),ns)
        raw=root/('tools/grab-strike-build/ProjectYakuza/42/media/anims_X/Bob/'+name+'.x');text,f,a,spans=read(raw);count=ns['a'].end_frame+1;times=[i*160 for i in range(count)];values=[locals_at(f,a,t)for t in times];output=mod/('42/media/anims_X/Bob/'+name+'.x');write(output,text,spans,blocks(f,values,times,grip),name)
        records.append({'name':name,'source':str(source),'sourceSha256':sha(source),'output':output.relative_to(mod).as_posix(),'sha256':sha(output),'retarget':str(raw),'retargetSha256':sha(raw),'frames':count,'fps':30});pair.append(count)
    assert pair[0]==pair[1],pair
    bep=src/'bep'/f'P_KRU_BTL_SUD_sy0_gsp_{index:02}.bep';b=bep.read_bytes();pos=16;contacts=[]
    while pos+80<=len(b):
        section,kind,size=struct.unpack_from('<HHI',b,pos+64);data=b[pos+80:pos+80+size]
        if section==12 and kind==68:contacts.append(int(struct.unpack_from('<f',data,4)[0]))
        pos+=80+size
    assert len(contacts)==1
    moves.append({'animation':f'ProjectYakuza_DD_GrabStrike{index:02}','targetAnimation':f'ProjectYakuza_DD_GrabStrikeVictim{index:02}','duration':(pair[0]-1)/30,'contactMs':contacts[0]/30*1000,'contactFrame':contacts[0],'bep':str(bep),'bepSha256':sha(bep),'damageMultiplier':.65})
report={'authorization':'User approved non-AI conversion of original paired grab animations on 2026-11-04.','operation':'Complete matching sy0 attacker and sy1 victim gsp_01..04 clips retargeted with existing PZ skeleton conversion. No source motion is invented. Original BEP collision frames define damage timing.','clips':records,'moves':moves}
(mod/'docs/grab-strike-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('GRAB_STRIKE_ASSETS',len(records),'source clips',[(m['duration'],m['contactFrame'])for m in moves])
