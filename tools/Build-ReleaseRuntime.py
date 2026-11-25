from pathlib import Path
import re,json
ROOT=Path(__file__).resolve().parents[1]
CUSTOM=re.compile(r'bottle|crate|bicycle|lau_?spear',re.I)
MODULES={'Y5ObjectMoves','BottleMoves','BottleHeatPaths','BicycleMoves','BicycleHeatPaths','CrateHeatMove','BicycleBreak'}
SCRIPTS={'ProjectYakuza_Bottles.txt','ProjectYakuza_BottleModels.txt','ProjectYakuza_BeerCrate.txt','ProjectYakuza_Bicycle.txt','ProjectYakuza_BicycleFragments.txt','ProjectYakuza_LauSpear.txt','ProjectYakuza_ObjectSounds.txt'}

def closing(text,start):
    depth=0;quote=None;escape=False
    for pos in range(start,len(text)):
        c=text[pos]
        if quote:
            if escape:escape=False
            elif c=='\\':escape=True
            elif c==quote:quote=None
        elif c in '\"\'':quote=c
        elif c=='{':depth+=1
        elif c=='}':
            depth-=1
            if depth==0:return pos+1
    raise AssertionError('unclosed source table')

def cut(text,spans):
    for start,end in sorted(spans,reverse=True):text=text[:start]+text[end:]
    return text

def keyed(text):
    spans=[]
    for m in re.finditer(r'\["([^"\n]+)"\]\s*=\s*',text):
        if not CUSTOM.search(m[1]):continue
        start=m.end()
        if text[start]=='{':end=closing(text,start)
        elif text[start]=='"':end=re.compile(r'"(?:\\.|[^"\\])*"').match(text,start).end()
        else:
            value=re.match(r'[-+0-9.eE]+|true|false|nil',text[start:])
            if not value:continue
            end=start+value.end()
        if text[end:end+1]==',':end+=1
        spans.append((m.start(),end))
    return cut(text,spans)

def named_blocks(text):
    spans=[]
    for m in re.finditer(r'\b(?:model|sound|item)\s+(\w+)\s*\{',text):
        if CUSTOM.search(m[1]):spans.append((m.start(),closing(text,m.end()-1)))
    return cut(text,spans)

def tracks(text):
    spans=[]
    for m in re.finditer(r'(?m)^T\["([^"\n]+)"\]=\(function\(\)',text):
        if CUSTOM.search(m[1]):
            end=text.index('end)()',m.end())+6
            spans.append((m.start(),end))
    text=cut(text,spans)
    return '\n'.join(line for line in text.splitlines()if not(line.startswith('C[')and CUSTOM.search(line)))+'\n'

def transform(name,text):
    if '/Translate/'in name and name.endswith('.json'):
        values=json.loads(text);values={key:value for key,value in values.items()if not(CUSTOM.search(key)and'ProjectYakuza'in key)}
        return json.dumps(values,ensure_ascii=False,indent=4)+'\n'
    original=text
    stem=Path(name).stem
    if stem=='DragonOfDojima':
        marker='if ProjectYakuza.Weapons then\n    local base=ProjectYakuza.getStyle("dragon_of_dojima")\n    local function objectSounds'
        assert marker in text;text=text.split(marker)[0]
    text='\n'.join(line for line in text.splitlines()if not any(line.strip()=='require "ProjectYakuza/'+m+'"'for m in MODULES))+'\n'
    if stem in {'AttackTrailCatalog','ParentPoseTracks'}:text=keyed(tracks(text))
    if stem in {'HeatSceneData','HeatPresentationData'}:text=keyed(text)
    if stem=='NetworkCatalog':
        spans=[]
        for m in re.finditer(r'\{\["id"\]="([^"\n]+)"',text):
            if CUSTOM.search(m[1]):
                end=closing(text,m.start())
                if text[end:end+1]==',':end+=1
                spans.append((m.start(),end))
        text=cut(text,spans)
    if stem=='TextureWarmup':text='\n'.join(line for line in text.splitlines()if not CUSTOM.search(line))+'\n'
    if stem=='Weapons':
        text=text.replace('    W.movement(p)\n','')
        start=text.index('W.carry=');end=text.index('PY.on("styleRegistered"',start);text=text[:start]+text[end:]
    if stem=='HeatActions':text=text.replace(' or item:getFullType()~="ProjectYakuza.Bicycle"',' ').replace('or item:getFullType()~="ProjectYakuza.Bicycle"',' ')
    if stem=='HeatRush':
        text='\n'.join(line for line in text.splitlines()if 'PY.BicycleBreak'not in line)+'\n'
        start=text.index('    else\n        local item=p:getPrimaryHandItem()',text.index('function H.applyBreak'))
        end=text.index('\nend\nfunction H.receive',start)
        text=text[:start]+'    end'+text[end:]
    if name.endswith('/ProjectYakuza_Models.txt')or name.endswith('/ProjectYakuza_HeatScenes.txt'):text=named_blocks(text)
    if '/Translate/'in name:text='\n'.join(line for line in text.splitlines()if not(CUSTOM.search(line)and'ProjectYakuza'in line))+'\n'
    return original if text.rstrip('\n')==original.rstrip('\n')else text

def release_files(mod,files):
    cache=ROOT/'tools/release-runtime'/mod.name;result={}
    for name,source in files.items():
        path=Path(name)
        if path.name in SCRIPTS or path.stem in MODULES:continue
        if path.suffix.lower()in {'.xml','.x','.png','.wav','.ogg','.mp3'}and CUSTOM.search(path.name):continue
        if path.suffix.lower()in {'.lua','.txt','.json'}:
            original=source.read_text(encoding='utf-8');updated=transform(name,original)
            if updated!=original:
                target=cache/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(updated,encoding='utf-8',newline='\n');result[name]=target;continue
        result[name]=source
    assert all(not CUSTOM.search(Path(n).name)for n in result if Path(n).suffix.lower()in {'.xml','.x','.png','.wav','.ogg','.mp3'})
    return result
