from pathlib import Path
import ast
import hashlib
import io
import json
import re
import subprocess
import sys
import tokenize

ROOT=Path(__file__).resolve().parents[2]

def blank(text):
    return " " + "\n"*text.count("\n")

def parts(text,kind):
    result=[];i=0;start=0
    def emit(tag,end):
        nonlocal i,start
        if start<i:result.append(("code",text[start:i]))
        result.append((tag,text[i:end]));i=end;start=i
    while i<len(text):
        if kind=="lua":
            if text.startswith("--",i):
                match=re.match(r"\[(=*)\[",text[i+2:])
                if match:
                    close="]"+match[1]+"]";end=text.find(close,i+2+len(match[0]))
                    if end<0:raise ValueError("unclosed Lua comment")
                    emit("comment",end+len(close))
                else:
                    end=text.find("\n",i);emit("comment",len(text) if end<0 else end)
                continue
            match=re.match(r"\[(=*)\[",text[i:])
            if match:
                close="]"+match[1]+"]";end=text.find(close,i+len(match[0]))
                if end<0:raise ValueError("unclosed Lua string")
                emit("string",end+len(close));continue
        elif kind=="ps1":
            if text.startswith("<#",i):
                end=text.find("#>",i+2)
                if end<0:raise ValueError("unclosed PowerShell comment")
                emit("comment",end+2);continue
            if text[i]=="#":
                end=text.find("\n",i);emit("comment",len(text) if end<0 else end);continue
        elif kind=="c":
            if text.startswith("//",i):
                end=text.find("\n",i);emit("comment",len(text) if end<0 else end);continue
            if text.startswith("/*",i):
                end=text.find("*/",i+2)
                if end<0:raise ValueError("unclosed block comment")
                emit("comment",end+2);continue
        if text[i] in ("\"","'"):
            quote=text[i];end=i+1
            while end<len(text):
                if kind=="ps1" and quote=="'" and text.startswith("''",end):end+=2;continue
                if text[end]==("`" if kind=="ps1" else "\\"):end+=2;continue
                if text[end]==quote:end+=1;break
                end+=1
            emit("string",end);continue
        i+=1
    if start<len(text):result.append(("code",text[start:]))
    return result

def signature(tokens):
    return hashlib.sha256("".join(value if tag=="string" else re.sub(r"\s+","",value) for tag,value in tokens if tag!="comment").encode()).hexdigest()

def strip_lexical(text,kind):
    tokens=parts(text,kind);count=sum(tag=="comment" for tag,_ in tokens)
    output="".join(blank(value) if tag=="comment" else value for tag,value in tokens)
    output="".join(re.sub(r"\n[ \t]*\n(?:[ \t]*\n)+","\n\n",value) if tag=="code" else value for tag,value in parts(output,kind))
    assert signature(tokens)==signature(parts(output,kind)),"non-comment tokens changed"
    return output,count

def strip_python(text):
    lines=text.splitlines(keepends=True);offsets=[0]
    for line in lines:offsets.append(offsets[-1]+len(line))
    spans=[]
    for token in tokenize.generate_tokens(io.StringIO(text).readline):
        if token.type==tokenize.COMMENT:spans.append((offsets[token.start[0]-1]+token.start[1],offsets[token.end[0]-1]+token.end[1],""))
    try:tree=ast.parse(text)
    except SyntaxError:tree=None
    if tree:
        for node in ast.walk(tree):
            if isinstance(node,(ast.Module,ast.ClassDef,ast.FunctionDef,ast.AsyncFunctionDef)) and node.body:
                first=node.body[0]
                if isinstance(first,ast.Expr) and isinstance(first.value,ast.Constant) and isinstance(first.value.value,str):
                    start=offsets[first.lineno-1]+len(lines[first.lineno-1].encode("utf-8")[:first.col_offset].decode("utf-8"))
                    end=offsets[first.end_lineno-1]+len(lines[first.end_lineno-1].encode("utf-8")[:first.end_col_offset].decode("utf-8"))
                    spans.append((start,end,"pass" if len(node.body)==1 and not isinstance(node,ast.Module) else ""))
    output=text
    for start,end,replacement in sorted(spans,reverse=True):output=output[:start]+replacement+blank(output[start:end])+output[end:]
    ast.parse(output)
    return output,len(spans)

def kind_for(path):
    name=path.name
    if name.endswith((".lua",".lua.example")):return "lua"
    if name.endswith((".xml",".xml.example")):return "xml"
    if name.endswith(".java"):return "c"
    if name.endswith(".py"):return "python"
    if name.endswith((".ps1",".ps1.example")):return "ps1"
    if "media/scripts/" in path.as_posix() and name.endswith((".txt",".txt.example")):return "c"
    if "media/lua/shared/Translate/" in path.as_posix() and name.endswith(".txt"):return "lua"

def tidy(text,kind):
    if kind=="xml":return re.sub(r"[ \t]+(?=\r?\n)","",text)
    if kind=="python":
        lines=text.splitlines(keepends=True);offsets=[0]
        for line in lines:offsets.append(offsets[-1]+len(line))
        tokens=[];start=0
        for token in tokenize.generate_tokens(io.StringIO(text).readline):
            if token.type==tokenize.STRING:
                left=offsets[token.start[0]-1]+token.start[1];right=offsets[token.end[0]-1]+token.end[1]
                tokens.append(("code",text[start:left]));tokens.append(("string",text[left:right]));start=right
        tokens.append(("code",text[start:]))
    else:tokens=parts(text,kind)
    return "".join(re.sub(r"[ \t]+(?=\r?\n)","",value) if tag=="code" else value for tag,value in tokens)

def clean(text,kind):
    if kind=="python":output,count=strip_python(text)
    elif kind=="xml":
        pattern=r"<!\[CDATA\[.*?\]\]>|<!--.*?-->"
        matches=list(re.finditer(pattern,text,re.S))
        output=re.sub(pattern,lambda m:blank(m[0]) if m[0].startswith("<!--") else m[0],text,flags=re.S)
        count=sum(m[0].startswith("<!--") for m in matches)
    else:output,count=strip_lexical(text,kind)
    return tidy(output,kind),count

def main():
    write="--strip" in sys.argv
    names=subprocess.check_output(["git","ls-files","--cached","--others","--exclude-standard"],cwd=ROOT,text=True).splitlines()
    changed=[];total=0;checked=0
    for name in sorted(set(names)):
        path=ROOT/name
        if not path.is_file():continue
        kind=kind_for(Path(name))
        if not kind:
            if path.suffix!=".md":continue
            text=path.read_text(encoding="utf-8");count=0
            def block(match):
                nonlocal count
                language=match[2].lower().strip()
                codekind={"lua":"lua","python":"python","py":"python","powershell":"ps1","ps1":"ps1","java":"c","xml":"xml"}.get(language)
                if not codekind:return match[0]
                output,found=clean(match[3],codekind);count+=found
                return match[1]+match[2]+"\n"+output+match[4]
            output=re.sub(r"(^```)([^\n]*)\n(.*?)(^```[ \t]*$)",block,text,flags=re.M|re.S)
            if count:total+=count;changed.append({"path":name,"comments":count})
            if write and output!=text:path.write_text(output,encoding="utf-8")
            continue
        checked+=1;text=path.read_text(encoding="utf-8-sig");output,count=clean(text,kind)
        if count:total+=count;changed.append({"path":name,"comments":count})
        if write and output!=text:path.write_text(output,encoding="utf-8")
    report={"source_files":checked,"comments":total,"changed":changed,"stripped":write}
    if write:(ROOT/"tools/comment-cleanup-046.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k!="changed"}))
    if total and not write:raise SystemExit(1)

if __name__=="__main__":main()
