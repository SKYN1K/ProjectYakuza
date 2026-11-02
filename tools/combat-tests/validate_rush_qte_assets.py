from pathlib import Path
import hashlib,json,struct,io
from PIL import Image
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza'
sha=lambda data:hashlib.sha256(data).hexdigest()
def sllz(data):
    assert data[:6] == b'SLLZ\0\1', 'Unsupported SLLZ variant'
    header, expected, stored = struct.unpack_from('<HII', data, 6)
    assert stored <= len(data) and expected < 16_000_000
    pos = header
    flag = data[pos]; pos += 1; bits = 8
    out = bytearray()
    while len(out) < expected:
        copy = flag & 0x80
        flag <<= 1; bits -= 1
        if bits == 0:
            flag = data[pos]; pos += 1; bits = 8
        if copy:
            token = int.from_bytes(data[pos:pos+2], 'little'); pos += 2
            distance, count = 1 + (token >> 4), 3 + (token & 15)
            assert distance <= len(out) and len(out) + count <= expected
            for _ in range(count):out.append(out[-distance])
        else:
            out.append(data[pos]); pos += 1
    assert len(out) == expected
    return out
r=json.loads((mod/'docs/heat-rush-qte-assets.json').read_text())
c,size,stored,offset,attr,ext,stamp=r['archiveMeta']
with Path(r['archive']).open('rb')as f:
    f.seek(offset+(ext<<32));data=f.read(stored if c else size)
dds=sllz(data)if c else data
assert len(dds)==size and sha(dds)==r['ddsSha256']
original=Image.open(io.BytesIO(dds)).convert('RGBA');supplied=Image.open(r['source']).convert('RGBA');output=Image.open(mod/r['output']).convert('RGBA')
assert original.size==output.size==supplied.size==(256,256)
assert original.tobytes()==supplied.tobytes()==output.tobytes()and sha(output.tobytes())==r['rgbaSha256']
assert sha((mod/r['output']).read_bytes())==r['sha256']
print('PASS original ui.par DDS bytes and all 65536 unchanged RGBA pixels; runtime quarter rotations use original resolution')
