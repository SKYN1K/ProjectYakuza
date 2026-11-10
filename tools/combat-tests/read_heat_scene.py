from pathlib import Path
import hashlib,struct,uuid
from read_katana_scene import read_scene as read_de_scene

def read_scene(path):
    path=Path(path);data=path.read_bytes();version=struct.unpack_from('<I',data)[0]
    if version==18:
        scene=read_de_scene(path);endian='<';header=80;elementHeader=32
    else:
        version=struct.unpack_from('>I',data)[0];assert version==10,'only verified CMN10/CMN18 layouts are supported'
        start,end=struct.unpack_from('>ff',data,8);root=struct.unpack_from('>I',data,32)[0];rows=[];endian='>';header=64;elementHeader=16
        def node(pos,parent=None,depth=0):
            assert depth<64 and len(rows)<10000 and pos+64<=len(data)
            raw,size,count,flags,priority=struct.unpack_from('>5I',data,pos+16);category={7:9,9:10,10:11,11:12}.get(raw,raw);payload=pos+64;stop=payload+size*4
            assert count<=4096 and stop<=len(data)
            row={'offset':pos,'guid':str(uuid.UUID(bytes_le=data[pos:pos+16])),'category':category,'rawCategory':raw,'name':data[pos+48:pos+64].split(b'\0')[0].decode('cp932','replace'),'size':size*4,'parent':parent,'depth':depth};rows.append(row)
            if category==6:
                a,b=struct.unpack_from('>ff',data,payload);row['motion']={'start':a,'end':b,'motionFrame':0}
            if category==12:
                kind,a,b,v=struct.unpack_from('>IffI',data,payload);row['element']={'kind':kind,'start':a,'end':b,'version':v};p=payload+16
                if kind==0x20:
                    _,_,damage,dead,vanish,noDead=struct.unpack_from('>HHiiiI',data,p);row['damage']={'damage':damage,'forceDead':dead,'vanish':vanish,'noDead':noDead}
                if kind==2:row['particle']={'id':struct.unpack_from('>I',data,p)[0],'flags':struct.unpack_from('>I',data,p+4)[0],'matrix':list(struct.unpack_from('>16f',data,p+16)),'scale':list(struct.unpack_from('>3f',data,p+80))}
                row['payloadHex']=data[p:stop].hex()
            for i in range(count):stop=node(stop,pos,depth+1)
            return stop
        stop=node(root);assert stop==len(data)
        scene={'source':str(path),'sha256':hashlib.sha256(data).hexdigest(),'parserReference':'https://github.com/Fronkln/HActLib','version':version,'start':start,'end':end,'stop':stop,'nodes':rows}
    byOffset={n['offset']:n for n in scene['nodes']};characters=[n['offset']for n in scene['nodes']if n['category']==5]
    for row in scene['nodes']:
        current=row;role='scene';bone=None
        while current:
            if current['category']==11 and bone is None:
                if version==18:bone=data[current['offset']+header+2:current['offset']+header+current['size']].split(b'\0')[0].decode('ascii','replace')
                else:bone=current['name'].split('(')[0]
            if current['offset']in characters:
                role='actor'if current['offset']==characters[0]else'victim';break
            current=byOffset.get(current['parent'])
        row['role']=role
        if bone:row['bone']=bone
        element=row.get('element')
        if element and element['kind']==(26 if version==18 else 0x21):
            payload=row['offset']+header+elementHeader
            if version==18:
                cue,sheet=struct.unpack_from('<HH',data,payload+4);fighter=bool(cue&0x8000);cue&=0x7fff
            else:sheet,cue=struct.unpack_from('>HH',data,payload);fighter=0x8000<=sheet<0x9000
            row['sound']={'cueSheet':sheet,'soundIndex':cue,'cueId':cue-1 if version==18 else cue,'fighter':fighter}
    scene['byteOrder']='little'if endian=='<'else'big'
    return scene
