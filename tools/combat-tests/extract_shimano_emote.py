from pathlib import Path
import hashlib,json,struct
from y5_source_assets import unpack
from extract_majima_bat_emote import read_scene,resource

root=Path(__file__).resolve().parents[2];archive=Path('F:/SteamLibrary/steamapps/common/Yakuza Kiwami/media/data/auth_w64_e/main03_s05.par');folder=root/'extracted/shimano-emote/main03_s05';sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dialogue(path,nodes):
    data=Path(path).read_bytes();node=next(n for n in nodes if n['name']=='字幕');payload=data[node['offset']+80:node['offset']+80+node['size']];count=struct.unpack_from('>I',payload,36)[0];assert len(payload)==56+count*272*2;lines=[]
    for index in range(count,2*count):
        offset=56+index*272;first,last=struct.unpack_from('>2f',payload,offset);text=payload[offset+16:offset+272].split(b'\0')[0].decode('utf-8');lines.append({'firstFrame':first,'lastFrame':last,'text':text})
    return lines
def extract():
    if not(folder/'source-index.json').exists():
        index=unpack(archive,folder);(folder/'source-index.json').write_text(json.dumps(index,indent=2)+'\n')
    scene=folder/'cmn.par/cmn.bin';data=scene.read_bytes();nodes=read_scene(scene);actor=next(n for n in nodes if n['type']==5 and n['name']=='c_am_shimano_U1_S195');motion=next(n for n in nodes if n['parent']==actor['offset']and n['type']==6);line=next(line for line in dialogue(scene,nodes)if line['text']=='Shut the fuck up!')
    pointer=struct.unpack_from('>I',data,28)[0];count=struct.unpack_from('>I',data,pointer)[0];boundaries=list(struct.unpack_from('>'+str(count+1)+'f',data,pointer+12));assert boundaries[0]==0 and boundaries[-1]==struct.unpack_from('>f',data,12)[0]
    dialogueCut=next(i for i,(a,b)in enumerate(zip(boundaries,boundaries[1:]))if a<=line['firstFrame']and line['lastFrame']<=b);cut=7;resources=folder/(f'{cut:03}.par')/'res.bin';name=resource(resources,motion['guid']);source=resources.parent/(name+'.gmt')
    assert dialogueCut==9 and boundaries[cut]==1558 and line['firstFrame']==1948 and line['lastFrame']==2020 and name=='main03_007_12'
    selection={'archive':str(archive),'archiveSha256':sha(archive),'scene':str(scene),'sceneSha256':sha(scene),'resources':str(resources),'resourcesSha256':sha(resources),'actor':actor,'motion':motion,'resource':name,'source':str(source),'sourceSha256':sha(source),'firstFrame':60,'lastFrame':169,'fps':30,'sceneCutStartFrame':boundaries[cut],'cut':cut,'dialogueCut':dialogueCut,'cutBoundaries':boundaries,'dialogue':[line],'basis':'Original Kiwami Tojo HQ patriarch meeting, main03_s05, Shimano actor cut 007, source frames 60..169. This is the preceding furniture strike and seated-to-standing action, rather than the already-standing shot during the CMN subtitle at frames 1948..2020 in cut 009. A short source lead-in, strike, full rise and standing recovery are retained at original speed. Original native animation identifier is preserved as the asset name.'}
    (folder.parent/'selection.json').write_text(json.dumps(selection,indent=2,ensure_ascii=True)+'\n');print('PASS exact Kiwami Tojo HQ Shimano line, CMN cut boundaries and actor/resource GUID; native main03_007_12 strike-and-rise frames 60..169')
if __name__=='__main__':extract()
