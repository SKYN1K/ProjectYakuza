from pathlib import Path

def resource(path,guid):
    data=Path(path).read_bytes();needle=bytes.fromhex(guid);assert data.count(needle)==1
    offset=data.index(needle);name=data[offset+28:offset+156].split(b'\0')[0].decode('ascii');assert name and '/'not in name and '\\'not in name
    return name
