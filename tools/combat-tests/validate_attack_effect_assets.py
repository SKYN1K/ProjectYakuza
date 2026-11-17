from pathlib import Path
import hashlib,json,re,struct,subprocess
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
MOD=ROOT/'combat/ProjectYakuza'
WORK=Path(__file__).parent
GAME=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
report=json.loads((MOD/'docs/attack-effect-assets.json').read_text())
outputs=[]
for item in report['assets']:
    source=ROOT/item['decodedOriginal'];dds=ROOT/item['dds'];output=MOD/item['output'];raw=dds.read_bytes()
    assert hashlib.sha256(raw).hexdigest()==item['ddsSha256']
    assert hashlib.sha256(output.read_bytes()).hexdigest()==item['sha256']and output.read_bytes()==source.read_bytes()
    actual=Image.open(output).convert('RGBA')
    try:expected=Image.open(dds).convert('RGBA')
    except NotImplementedError:
        flags,bits,*masks=struct.unpack_from('<6I',raw,80);assert bits==16 and flags&0x20000
        expected=Image.frombytes('LA',actual.size,raw[128:128+actual.width*actual.height*2]).convert('RGBA')
    assert actual.size==tuple(item['size'])and actual.tobytes()==expected.tobytes()
    outputs.append(str(output.resolve()))
smoke=json.loads((MOD/'docs/extreme-smoke-assets.json').read_text())
source=Path(smoke['source']);assert hashlib.sha256(source.read_bytes()).hexdigest()==smoke['source_sha256']
original=Image.open(source).convert('RGBA');assert len(smoke['frames'])==64
for row in smoke['frames']:
    output=MOD/row['output'];pixels=Image.open(output).convert('RGBA')
    assert hashlib.sha256(output.read_bytes()).hexdigest()==row['sha256']
    assert pixels.size==tuple(row['size'])and pixels.tobytes()==original.crop(row['crop']).tobytes()
    outputs.append(str(output.resolve()))
subprocess.run([str(GAME/'jre64/bin/java.exe'),'-Xms16m','-Xmx256m','-XX:ActiveProcessorCount=2','--enable-native-access=ALL-UNNAMED','-cp','.;'+str(GAME/'*'),'AttackEffectProbe',*outputs],cwd=WORK,check=True)
catalog=json.loads((MOD/'docs/attack-trail-catalog.json').read_text())
code=(MOD/catalog['catalog']).read_bytes();assert hashlib.sha256(code).hexdigest()==catalog['sha256']
rows=catalog['clips'];assert len(rows)==95 and sum(len(r['windows'])for r in rows)==121
for row in rows:
    assert hashlib.sha256((MOD/row['clip']).read_bytes()).hexdigest()==row['clipSha256']
    assert row['samples']==round(row['duration']*120)+1
    for window in row['windows']:
        assert window['from']<=window['contact']<=window['to']and window['to']-window['from']<=.18000001
        if row['profile']!='unarmed':assert window['limb']=='rightArm'
clips={r['animation'].removeprefix('ProjectYakuza_DD_'):r for r in rows}
assert [r['limb']for r in clips['WallHeat']['windows']]==['rightArm','rightLeg']
assert clips['GroundHeat']['windows'][0]['limb']=='rightLeg'
assert clips['OpenGrabHeat']['windows'][0]['limb']=='rightLeg'
assert 1.4<clips['OpenGrabHeat']['windows'][0]['contact']<2.2
assert clips['Throw']['windows'][0]['limb']=='leftArm'and clips['Throw']['windows'][0]['contact']<.8
assert clips['HeatRushFail']['windows'][0]['index']==13 and clips['CrateHeatFail']['windows'][0]['index']==6
lua=(MOD/'42/media/lua/client/ProjectYakuza/HitEffects.lua').read_text()
assert re.search(r'if not guard and ProjectYakuza.AttackEffects.*\.hit\(player,victim,strong,charged,anchor\)',lua)
print('PASS unchanged original source pixels, 95 native clip hashes, 121 short contact windows, all weapon arms, paired/failure body parts and confirmed non-guard spark integration')
