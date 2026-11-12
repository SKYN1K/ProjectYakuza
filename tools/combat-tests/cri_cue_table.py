import struct

def sheet_names(data):
    assert data[:4]==b'armp'and struct.unpack_from('<HH',data,8)==(12,1)
    main=struct.unpack_from('<I',data,16)[0]
    count,columns=struct.unpack_from('<II',data,main)
    assert columns==0 and count<100000 and struct.unpack_from('<I',data,main+48)[0]==0
    table=struct.unpack_from('<I',data,main+16)[0]
    assert table and table+count*4<=len(data)
    names={}
    for index in range(count):
        start=struct.unpack_from('<I',data,table+index*4)[0]
        end=data.index(b'\0',start)
        names[index]=data[start:end].decode('ascii')
    return names

def read_utf(data):
    assert data[:4]==b'@UTF'
    size,version,rowsOffset,stringsOffset,blobOffset,nameOffset,columns,width,count=struct.unpack_from('>IHHIIIHHI',data,4)
    assert size+8<=len(data)and count<=100000 and columns<=256
    stringsOffset+=8;blobOffset+=8;rowsOffset+=8
    def string(offset):
        start=stringsOffset+offset;end=data.index(b'\0',start);return data[start:end].decode('utf-8')
    formats={0:'B',1:'b',2:'H',3:'h',4:'I',5:'i',6:'Q',7:'q',8:'f',9:'d',10:'I',11:'II'}
    def value(kind,pos):
        fmt='>'+formats[kind];values=struct.unpack_from(fmt,data,pos);result=values[0]
        if kind==10:result=string(result)
        if kind==11:
            offset,length=values;result=data[blobOffset+offset:blobOffset+offset+length]
        return result,struct.calcsize(fmt)
    schema=[];pos=32
    for i in range(columns):
        flags,name=struct.unpack_from('>BI',data,pos);pos+=5;storage=flags&0xf0;kind=flags&15;constant=None
        if storage==0x30:constant,length=value(kind,pos);pos+=length
        assert storage in[0x10,0x30,0x50],hex(flags)
        schema.append((string(name),storage,kind,constant))
    rows=[]
    for row in range(count):
        pos=rowsOffset+row*width;entry={}
        for name,storage,kind,constant in schema:
            if storage==0x50:result,length=value(kind,pos);pos+=length
            else:result=constant if storage==0x30 else b''if kind==11 else''if kind==10 else 0
            entry[name]=result
        assert pos==rowsOffset+(row+1)*width
        rows.append(entry)
    return rows

def cue_names(data):
    header=read_utf(data)[0];names=read_utf(header['CueNameTable']);cues=read_utf(header['CueTable']);result={}
    for row in names:
        cue=cues[row['CueIndex']];result[cue['CueId']]=row['CueName']
    return result
