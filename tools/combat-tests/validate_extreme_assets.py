
from pathlib import Path
import argparse
import hashlib
import json
from PIL import Image

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-dir',type=Path,required=True)
args=parser.parse_args()
mod=Path(__file__).resolve().parents[2]/'combat/ProjectYakuza'
report=json.loads((mod/'docs/extreme-heat-assets.json').read_text(encoding='utf-8'))
sha=lambda data:hashlib.sha256(data).hexdigest()
sources={}
for row in report['sources']:
    path=args.source_dir/row['entry']
    assert sha(path.read_bytes())==row['sha256'],path
    sources[row['entry']]=Image.open(path).convert('RGBA')
assert len(report['frames'])==66
for row in report['frames']:
    output=mod/'42/media/textures/ProjectYakuza'/row['output']
    original=sources[row['source']].crop(row['crop'])
    decoded=Image.open(output).convert('RGBA')
    assert list(decoded.size)==row['size'] and decoded.size==original.size
    assert decoded.tobytes()==original.tobytes()
    assert sha(output.read_bytes())==row['sha256']
    assert sha(decoded.tobytes())==row['rgba_sha256']
print('PASS all 66 supplied atlas/wisp crops match source RGBA pixels and provenance hashes; no resizing or generated pixels')
