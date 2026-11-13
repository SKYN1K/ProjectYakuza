from pathlib import Path
import hashlib,json,re,zipfile,xml.etree.ElementTree as E

root=Path(__file__).resolve().parents[2];main=root/'combat/ProjectYakuza';addon=root/'emotes/ProjectYakuzaEmotes';media=addon/'42/media';lau=json.loads((addon/'docs/lau-spear-emote-assets.json').read_text(encoding='utf-8'));names=['ProjectYakuza_MajimaBatPoint','ProjectYakuza_KiryuBadLuck','ProjectYakuza_KiryuStepUp']+[o['clip']for o in lau['outputs']];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();clips=list((media/'anims_X').rglob('*.x'));selectors=list((media/'AnimSets').rglob('*.xml'));assert len(names)==25 and {p.stem for p in clips}==set(names)and {p.stem for p in selectors}==set(names)
for name in names:
    for relative in [f'42/media/anims_X/Bob/{name}.x',f'42/media/AnimSets/player/emote/{name}.xml']:assert not(main/relative).exists()
    node=E.parse(media/f'AnimSets/player/emote/{name}.xml').getroot();assert node.findtext('m_AnimName')==name and node.findtext('m_Conditions/m_Value')==name
for kind in ['majima-bat','lau-spear','kiryu-bad-luck','kiryu-step-up']:
    report=json.loads((addon/'docs'/(kind+'-emote-assets.json')).read_text(encoding='utf-8'))
    for output in report.get('outputs',[report]):assert sha(addon/output['output'])==output['sha256']and sha(addon/output['selector'])==output['selectorSha256']
    for row in report['provenance']:assert sha(Path(row['path']))==row['sha256'],row['path']
assert not(main/'42/media/lua/client/ProjectYakuza/Emotes.lua').exists()and not(main/'42/media/lua/shared/ProjectYakuza/EmoteSpears.lua').exists()
for path in (main/'42/media/lua').rglob('*'):
    if path.is_file():
        text=path.read_text(encoding='utf-8');assert not any(token in text for token in names+['ProjectYakuza_Emotes','IGUI_ProjectYakuza_Emote','ProjectYakuza/Emotes','ProjectYakuza/EmoteSpears','ProjectYakuzaEmotes']),str(path)
for path in (media/'lua').rglob('*.lua'):
    text=path.read_text(encoding='utf-8');assert 'require "ProjectYakuza/'not in text and 'PY.activeActions'not in text
    for module in re.findall(r'require\s+"(ProjectYakuzaEmotes/[^"\n]+)"',text):assert any((media/'lua'/side/(module+'.lua')).is_file()for side in ['shared','client','server'])
info=(addon/'42/mod.info').read_text(encoding='utf-8');assert 'id=ProjectYakuzaEmotes'in info and 'version=0.2.0'in info and not re.search(r'^require\s*=',info,re.M)
assert 'id=ProjectYakuza\n'in(main/'42/mod.info').read_text()and 'version=0.107.0'in(main/'42/mod.info').read_text()
assert not list(media.rglob('*.png'))and not list(media.rglob('*.ogg'))and not list(media.rglob('*.wav'))and not(media/'models_X').exists()
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.106.0.zip')as archive:
    retained=0
    for name in archive.namelist():
        if name.endswith('/')or '/media/'not in name:continue
        path=main/name.removeprefix('ProjectYakuza/')
        if path.suffix not in ['.x','.xml','.png','.wav','.ogg']or not path.exists():continue
        assert path.read_bytes()==archive.read(name),name;retained+=1
with zipfile.ZipFile(root/'dist/ProjectYakuzaEmotes-B42-v0.1.0.zip')as archive:
    checked=0
    for name in archive.namelist():
        if name.endswith('/')or Path(name).suffix not in ['.x','.xml']:continue
        path=addon/name.removeprefix('ProjectYakuzaEmotes/');assert path.read_bytes()==archive.read(name),name;checked+=1
assert 'ProjectYakuzaEmotes.VERSION="0.2.0"'in(media/'lua/shared/ProjectYakuzaEmotes/EmoteSpears.lua').read_text(encoding='utf-8')
print('PASS standalone isolation: 25 clips/selectors;',checked,'existing emote media byte-identical;',retained,'combat media unchanged; separate IDs, standalone require graph and no new textures/models/audio')
