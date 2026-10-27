"""Verify source BEP charge markers/hit windows, looping holds and true-alpha flame speed."""
from pathlib import Path
import struct,json,hashlib,xml.etree.ElementTree as E,re
from PIL import Image
mod=Path(__file__).resolve().parents[2]/'combat/ProjectYakuza'
timing=json.loads((mod/'docs/y6-charge-timing.json').read_text(encoding='utf-8'))
for row in timing['branches']:
    b=Path(row['bep']).read_bytes();assert hashlib.sha256(b).hexdigest()==row['sha256']
    pos=16;charge=[];hit=[]
    while pos+80<=len(b):
        section,kind,size=struct.unpack_from('<HHI',b,pos+64);payload=b[pos+80:pos+80+size]
        assert len(payload)==size
        if section==12 and kind in (206,77):
            (charge if kind==206 else hit).append(list(struct.unpack_from('<ff',payload,4)))
        pos+=80+size
    assert pos==len(b) and charge==[[row['charge_frame'],row['charge_frame']]] and hit==row['native_hit_windows']
    i=row['branch'];node=E.parse(mod/f'42/media/AnimSets/player/actions/ProjectYakuza_DD_ChargeHold0{i}.xml').getroot()
    assert node.findtext('m_Looped')=='true' and node.findtext('m_SpeedScale')=='1'
    assert node.findtext('m_Conditions/m_Value')==f'ProjectYakuza_DD_ChargeHold0{i}'
    assert not any(e.findtext('m_EventName')=='AttackCollisionCheck' for e in node.findall('m_Events'))
    strike=E.parse(mod/f'42/media/AnimSets/player/melee/ProjectYakuza_DD_ChargedFinisher0{i}.xml').getroot()
    assert strike.findtext('m_SpeedScale')=='1'
print('PASS original BEP pause markers 6/7/6/5, source hit windows, persistent event-free holds and source 1x strike playback')
report=json.loads((mod/'docs/extreme-heat-assets.json').read_text(encoding='utf-8'))
assert report['sources'][0]['entry']=='e_j_0076_aura_gA8L8.dds'
for row in report['frames']:
    if 'flame' not in row['output']:continue
    pixels=Image.open(mod/'42/media/textures/ProjectYakuza'/row['output']).convert('RGBA')
    assert not any(a>32 and max(r,g,b)<16 for r,g,b,a in pixels.getdata()),row['output']
source=(mod/'42/media/lua/client/ProjectYakuza/HeatAura.lua').read_text(encoding='utf-8')
for seconds in ['.65','.73','.81','.59']:assert f'speed=.55*64/({seconds}*60)' in source
print('PASS original alpha-bearing flames contain no visible black matte and use exactly .55 of prior frame speed')
