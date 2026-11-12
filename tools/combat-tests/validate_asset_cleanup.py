from pathlib import Path
import argparse,hashlib,json,re,zipfile,xml.etree.ElementTree as E

parser=argparse.ArgumentParser()
parser.add_argument('--baseline-audit',action='store_true')
parser.add_argument('--prune',action='store_true')
args=parser.parse_args()
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';media=mod/'42/media';report=json.loads((mod/'docs/asset-cleanup.json').read_text(encoding='utf-8'))
retired={r['path']:r for r in report['assets']};assert len(retired)==len(report['assets'])and retired
for name,row in retired.items():
    target=(mod/name).resolve();assert target.is_relative_to(mod.resolve())and target!=mod.resolve()
    if args.prune and target.exists():
        assert target.is_file()and hashlib.sha256(target.read_bytes()).hexdigest()==row['sha256'],'retired output differs from its audited source: '+name
        target.unlink()
    assert not target.exists(),'retired asset restored: '+name
lua=list((media/'lua').rglob('*.lua'));luaText='\n'.join(p.read_text(encoding='utf-8')for p in lua)
for p in lua:
    for name in re.findall(r'\brequire\s*[\( ]*"(ProjectYakuza/[^"\n]+)"',p.read_text(encoding='utf-8')):
        assert any((media/'lua'/side/(name+'.lua')).is_file()for side in ['shared','client','server']),(p,name)
animations=set();xml=list((media/'AnimSets').rglob('*.xml'))
for p in xml:
    node=E.parse(p).getroot()
    assert not any(c.findtext('m_Name')in ['ProjectYakuzaCustomWeaponPoses','ProjectYakuzaCustomWalk']for c in node.findall('m_Conditions')),'obsolete pose gate: '+str(p)
    for element in node.iter('m_AnimName'):
        name=element.text
        if name and name.startswith('ProjectYakuza'):
            assert (media/'anims_X/Bob'/(name+'.x')).is_file(),(p,name)
            animations.add(name)
clips=list((media/'anims_X').rglob('*.x'))
for p in clips:assert p.stem in animations or p.stem in luaText,'unreferenced animation: '+str(p)
scripts=list((media/'scripts').glob('*.txt'));scriptText='\n'.join(p.read_text(encoding='utf-8')for p in scripts)
runtime=luaText+'\n'+scriptText+'\n'+'\n'.join(p.read_text(encoding='utf-8')for p in (media/'models_X').rglob('*.x'))
sequences={f'HeatWisp_{kind}_{i}.png'for kind in ['a','b','c']for i in range(32)}|{f'ExtremeHeat_{kind}_{i}.png'for kind in ['flame','smoke']for i in range(64)}|{f'Blood_splash_{i}.png'for i in range(16)}
for name in sequences:assert (media/'textures/ProjectYakuza'/name).is_file(),name
textures=list((media/'textures').rglob('*.png'))
for p in textures:
    icon=p.stem.removeprefix('Item_')
    assert p.name in runtime or p.name in sequences or p.stem in scriptText or re.search(r'\bIcon\s*=\s*'+re.escape(icon)+r'\s*,',scriptText),'unreferenced texture: '+str(p)
for name in re.findall(r'["\'](media/[^"\'\n]+\.(?:png|wav|ogg))["\']',luaText):assert (mod/'42'/name).is_file(),name
soundFiles=set(re.findall(r'\bfile\s*=\s*(media/sound/[^,\r\n]+)',scriptText))
sounds=[p for p in (media/'sound').rglob('*')if p.is_file()]
for name in soundFiles:assert (mod/'42'/name.strip()).is_file(),name
for p in sounds:assert p.relative_to(mod/'42').as_posix()in soundFiles,'unreferenced sound: '+str(p)
assert 'ProjectYakuza_Y6_ChargeEnd'not in scriptText
for name in re.findall(r'\bGameSound_(ProjectYakuza_\w+)\s*=',(media/'lua/shared/Translate/EN/GameSound_EN.txt').read_text(encoding='utf-8')):
    assert re.search(r'\bsound\s+'+re.escape(name)+r'\s*\{',scriptText),'unused sound label: '+name
assert 'dd_light_01'not in (media/'lua/client/ProjectYakuza/AttackTracks.lua').read_text()
if args.baseline_audit:
    baseline=root/'dist/ProjectYakuza-B42-v0.100.0.zip'
    with zipfile.ZipFile(baseline)as archive:
        for name,row in retired.items():
            original=archive.read('ProjectYakuza/'+name);assert len(original)==row['bytes']and hashlib.sha256(original).hexdigest()==row['sha256'],name
        for p in clips+textures+sounds+xml+list((media/'models_X').rglob('*.x'))+list((media/'actiongroups').rglob('*.xml')):
            name=p.relative_to(mod).as_posix();assert p.read_bytes()==archive.read('ProjectYakuza/'+name),'retained media changed: '+name
print('PASS cleanup:',len(retired),'retired assets absent;',len(clips),'referenced clips;',len(textures),'textures;',len(sounds),'audio files; Lua requires, selectors and dynamic sequences verified'+('; retained media bytes match v0.100.0'if args.baseline_audit else''))
