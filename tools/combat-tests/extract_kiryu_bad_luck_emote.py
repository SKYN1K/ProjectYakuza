from pathlib import Path
import hashlib,json,struct
from y5_source_assets import unpack
from extract_majima_bat_emote import read_scene,resource

root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/auth_w64_e/main06_s01.par');folder=root/'extracted/kiryu-dog-emote/main06_s01';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()

def subtitles(path,rows):
    data=Path(path).read_bytes();node=next(r for r in rows if r['name']=='\u5b57\u5e55');start=node['offset']+80;payload=data[start:start+node['size']];count=struct.unpack_from('>I',payload,36)[0];assert count==12 and len(payload)==56+count*272*2
    result=[]
    for index in range(count,2*count):
        offset=56+index*272;first,last=struct.unpack_from('>2f',payload,offset);text=payload[offset+16:offset+272].split(b'\0')[0].decode('utf-8');result.append({'firstFrame':first,'lastFrame':last,'text':text})
    return result

def extract():
    index=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(index,indent=2)+'\n',encoding='utf-8');scene=folder/'cmn.par/cmn.bin';rows=read_scene(scene);actor=next(r for r in rows if r['type']==5 and r['name']=='c_at_kiryu_U1_S185');motion=next(r for r in rows if r['parent']==actor['offset']and r['type']==6);resources=folder/'006.par/res.bin';name=resource(resources,motion['guid']);source=folder/'006.par'/(name+'.gmt');dialogue=subtitles(scene,rows);line=next(r for r in dialogue if r['text'].startswith('So this whole mess'))
    assert name=='main06_006_9'and line['firstFrame']==1544 and line['lastFrame']==1646
    result={'archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'resources':str(resources),'resourcesSha256':sha(resources),'actor':actor,'motion':motion,'resource':name,'source':str(source),'sourceSha256':sha(source),'firstFrame':90,'lastFrame':444,'fps':30,'sceneCutStartFrame':1202,'dialogue':[r for r in dialogue if 1327<=r['firstFrame']<=1544],'basis':'Original Kiwami puppy-rescue main06_s01, Kiryu cut 006. The scene subtitle track identifies the rough-day, pissed-off and bad-luck lines. Contiguous original neck/head gesture and closing lean, with lead-in, at source speed.'}
    (folder.parent/'selection.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print('PASS supplied puppy-rescue Kiryu GUID/resource and original subtitle bindings; source 90..444')

if __name__=='__main__':extract()
