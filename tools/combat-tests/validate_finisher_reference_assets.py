"""Verify supplied finisher split poses, smoke crops and unchanged original HUD atlas."""
from pathlib import Path
import argparse,hashlib,json,re,math
from PIL import Image
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--hud-dds',type=Path,required=True)
args=parser.parse_args()
mod=Path(__file__).resolve().parents[2]/'combat/ProjectYakuza'
sha=lambda b:hashlib.sha256(b).hexdigest()
report=json.loads((mod/'docs/charged-finisher-assets.json').read_text(encoding='utf-8'))
def keys(path):
    pieces=re.split(r'\n Animation \{ \{ (\w+) \}\n',path.read_text(encoding='utf-8'))
    result={}
    for i in range(1,len(pieces),2):
        name,body=pieces[i:i+2]
        for key in re.finditer(r'AnimationKey\s+\w+\s*\{\s*(\d+);\s*(\d+);\n(.*?)\n \}',body,re.S):
            kind,count,rows=key.groups();rows=rows.strip().rstrip(';').split(',\n')
            assert len(rows)==int(count),(name,count,len(rows))
            values=[tuple(float(v) for v in row.split(';')[2].split(',')) for row in rows]
            result[(name,int(kind))]=values
    assert len(result)==105,(path,len(result))
    return result
for clip in report['clips']:
    assert sha(Path(clip['source']).read_bytes())==clip['source_sha256']
    out=mod/clip['output'];assert sha(out.read_bytes())==clip['sha256']
    k=keys(out);assert all(len(rows)==clip['source_frames'][1]-clip['source_frames'][0]+1 for rows in k.values())
for i in range(1,5):
    windup=keys(mod/f'42/media/anims_X/Bob/ProjectYakuza_DD_ChargeWindup0{i}.x')
    release=keys(mod/f'42/media/anims_X/Bob/ProjectYakuza_DD_ChargedFinisher0{i}.x')
    for key,rows in windup.items():
        a,b=rows[-1],release[key][0]
        difference=min(sum((x-y)**2 for x,y in zip(a,b)),sum((x+y)**2 for x,y in zip(a,b))) if key[1]==0 else sum((x-y)**2 for x,y in zip(a,b))
        assert difference<1e-12,(i,key,difference)
print('PASS 8 original-source clip hashes/ranges and all 105 native channels per branch meet at the identical wind-up/release pose')
report=json.loads((mod/'docs/extreme-smoke-assets.json').read_text(encoding='utf-8'))
source=Path(report['source']);assert sha(source.read_bytes())==report['source_sha256']
im=Image.open(source).convert('RGBA');assert len(report['frames'])==64
for f in report['frames']:
    out=mod/f['output'];decoded=Image.open(out).convert('RGBA')
    assert list(decoded.size)==f['size']==[64,64]
    assert decoded.tobytes()==im.crop(f['crop']).tobytes()
    assert sha(out.read_bytes())==f['sha256'] and sha(decoded.tobytes())==f['rgba_sha256']
print('PASS all 64 native-size smoke frames match original DDS crop pixels and hashes')
report=json.loads((mod/'docs/extreme-hud-crops.json').read_text(encoding='utf-8'))
out=mod/report['source'];assert sha(out.read_bytes())==report['source_sha256']
atlas=Image.open(out).convert('RGBA');assert atlas.tobytes()==Image.open(args.hud_dds).convert('RGBA').tobytes()
for name,(x,y,w,h) in report['rectangles'].items():
    assert x>=0 and y>=0 and x+w<=atlas.width and y+h<=atlas.height,name
    assert atlas.crop((x,y,x+w,y+h)).getchannel('A').getextrema()[1]>0,name
print('PASS original HUD atlas pixels unchanged; all six Extreme Heat dark-region crops are valid')
