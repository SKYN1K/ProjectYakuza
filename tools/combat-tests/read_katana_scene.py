from pathlib import Path
import json,struct,uuid,hashlib,sys

def read_scene(path):
 data=Path(path).read_bytes();rows=[]
 assert len(data)>=44,'truncated CMN header'
 version,flags,start,end,draw=struct.unpack_from('<IIffI',data);pointers=struct.unpack_from('<6I',data,20)
 assert version==18,'this reader handles verified Yakuza 6 CMN18 scenes only'
 def node(pos,parent=None,depth=0):
  assert depth<64 and len(rows)<10000 and pos+80<=len(data),'invalid CMN tree bounds'
  guid=str(uuid.UUID(bytes_le=data[pos:pos+16]));category,size,count,flags,priority=struct.unpack_from('<5I',data,pos+16);name=data[pos+48:pos+80].split(b'\0')[0].decode('cp932','replace');payload=pos+80
  assert count<=4096 and payload+size*4<=len(data),'invalid CMN node size'
  row={'offset':pos,'guid':guid,'category':category,'name':name,'size':size*4,'parent':parent,'depth':depth};rows.append(row)
  if category==6:
   f,s,e,t=struct.unpack_from('<4I',data,payload);row['motion']={'flags':f,'start':s/100,'end':e/100,'motionFrame':t/100,'previousMatrix':list(struct.unpack_from('<16f',data,payload+16))}
  if category==12:
   kind,s,e,v,flag,play,update,_=struct.unpack_from('<IffIIIII',data,payload);row['element']={'kind':kind,'start':s,'end':e,'version':v,'flags':flag,'play':play,'update':update};p=payload+32
   if kind==0x61:row['damage']=dict(zip(['damage','forceDead','noDead','vanish'],struct.unpack_from('<4I',data,p)))
   if kind==0x5f:row['speed']={'type':struct.unpack_from('<I',data,p)[0],'max':struct.unpack_from('<f',data,p+4)[0],'min':struct.unpack_from('<f',data,p+8)[0],'frames':struct.unpack_from('<I',data,p+12)[0],'curve':list(struct.unpack_from('<32f',data,p+32))}
   if kind==0x13:row['particle']={'id':struct.unpack_from('<I',data,p)[0],'flags':struct.unpack_from('<I',data,p+4)[0],'matrix':list(struct.unpack_from('<16f',data,p+16)),'scale':list(struct.unpack_from('<3f',data,p+80))}
   row['payloadHex']=data[payload+32:payload+size*4].hex()
  nextPos=payload+size*4
  for i in range(count):nextPos=node(nextPos,pos,depth+1)
  return nextPos
 stop=node(pointers[-1]);report={'source':str(path),'sha256':hashlib.sha256(data).hexdigest(),'parserReference':'https://github.com/Fronkln/HActLib','version':version,'start':start,'end':end,'pointers':pointers,'stop':stop,'nodes':rows}
 return report

if __name__=="__main__":
 print(json.dumps(read_scene(sys.argv[1]),indent=2))
