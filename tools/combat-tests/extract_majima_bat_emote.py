from pathlib import Path
import hashlib,json,struct
from y5_source_assets import unpack

root=Path(__file__).resolve().parents[2]
archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/auth_w64_e/main08_s02.par')
folder=root/'extracted/majima-bat-emote/main08_s02'

def read_scene(path):
    data=Path(path).read_bytes();assert struct.unpack_from('>I',data)[0]==16
    rows=[]
    def node(offset,parent=None,depth=0):
        assert depth<64 and offset+80<=len(data)and len(rows)<10000
        kind,size,count,flags=struct.unpack_from('>4I',data,offset+16);stop=offset+80+size*4
        assert stop<=len(data)and count<4096
        rows.append({'offset':offset,'parent':parent,'guid':data[offset:offset+16].hex(),'type':kind,'size':size*4,'children':count,'name':data[offset+48:offset+80].split(b'\0')[0].decode('cp932','replace')})
        for _ in range(count):stop=node(stop,offset,depth+1)
        return stop
    assert node(struct.unpack_from('>I',data,36)[0])==len(data)
    return rows

def resource(path,guid):
    data=Path(path).read_bytes();needle=bytes.fromhex(guid);assert data.count(needle)==1
    offset=data.index(needle);name=data[offset+28:offset+156].split(b'\0')[0].decode('ascii');assert name and '/'not in name and '\\'not in name
    return name


def greeting(path,rows):
    data=Path(path).read_bytes();node=next(r for r in rows if r['name']=='字幕');payload=data[node['offset']+80:node['offset']+80+node['size']];count=struct.unpack_from('>I',payload,36)[0];assert count==21 and len(payload)==56+count*272*2;result=[]
    for index in range(count,count+2):
        offset=56+index*272;first,last=struct.unpack_from('>2f',payload,offset);text=payload[offset+16:offset+272].split(b'\0')[0].decode('utf-8');result.append({'firstFrame':first,'lastFrame':last,'text':text})
    assert result==[{'firstFrame':404.0,'lastFrame':473.0,'text':"It's been a while..."},{'firstFrame':478.0,'lastFrame':552.0,'text':'Kiryu-chan!'}]
    return result

def extract():
    report=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(report,indent=2)+'\n')
    rows=read_scene(folder/'cmn.par/cmn.bin');actor=next(r for r in rows if r['type']==5 and r['name'].startswith('c_at_majima_'));bat=next(r for r in rows if r['type']==7 and r['name']=='a08_02a_bat_metal_5')
    selected={}
    for key,parent,kind in [('actor',actor,6),('bat',bat,9)]:
        motion=next(r for r in rows if r['parent']==parent['offset']and r['type']==kind);name=resource(folder/'002.par/res.bin',motion['guid']);path=folder/'002.par'/(name+'.gmt')
        selected[key]={'node':parent,'motion':motion,'resource':name,'path':str(path),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
    result={'archive':report['archive'],'archiveSha256':report['archiveSha256'],'scene':str(folder/'cmn.par/cmn.bin'),'sceneSha256':hashlib.sha256((folder/'cmn.par/cmn.bin').read_bytes()).hexdigest(),'resources':str(folder/'002.par/res.bin'),'resourcesSha256':hashlib.sha256((folder/'002.par/res.bin').read_bytes()).hexdigest(),'selection':selected,'cut':'002','firstFrame':70,'lastFrame':160,'pointFrame':110,'fps':30,'sceneCutStartFrame':403,'timeline':[str(folder/'000.par'/'main08_000_12.gmt'),str(folder/'001.par'/'main08_001_6.gmt')],'dialogue':greeting(folder/'cmn.par/cmn.bin',rows),'basis':'Original batting-center main08_s02 scene, Majima actor and independently animated fifth metal bat, opening behind-head point during the Kiryu-chan greeting, continuous frames 70..160 of cut 002 after its internal shot cut.'}
    (folder.parent/'selection.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS original Kiwami batting-center actor/metal-bat bindings and opening greeting and contiguous source frames 70..160')

if __name__=='__main__':extract()
