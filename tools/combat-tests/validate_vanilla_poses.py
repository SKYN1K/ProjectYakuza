from pathlib import Path
import json,hashlib,zipfile,xml.etree.ElementTree as E,subprocess
root=Path(__file__).resolve().parents[2];mod=root/'combat/ProjectYakuza';here=Path(__file__).parent;game=Path('F:/SteamLibrary/steamapps/common/ProjectZomboid')
report=json.loads((mod/'docs/vanilla-pose-fallback.json').read_text());assert len(report['selectors'])==30
rows=[]
for entry in report['selectors']:
    p=mod/entry['path'];assert hashlib.sha256(p.read_bytes()).hexdigest()==entry['sha256']
    rows.append(str(p)+'\t'+entry['gate'])
for p in (mod/'42/media/lua').rglob('*.lua'):
    text=p.read_text(encoding='utf-8');assert 'ProjectYakuzaCustomWeaponPoses'not in text and 'ProjectYakuzaCustomWalk'not in text,'unexpected pose-gate producer'
for group in ['idle','movement','run','sprint','aim','aim-strafe']:
    for p in (mod/'42/media/AnimSets/player'/group).glob('ProjectYakuza_DD_*.xml'):
        n=E.parse(p).getroot();conditions={e.findtext('m_Name'):e.findtext('m_Value')for e in n.findall('m_Conditions')}
        if conditions.get('ProjectYakuzaWeaponProfile'):assert conditions.get('ProjectYakuzaCustomWeaponPoses')=='true',p
        if group=='movement':assert conditions.get('ProjectYakuzaCustomWalk')=='true' or conditions.get('ProjectYakuzaCustomWeaponPoses')=='true',p
n=E.parse(mod/'42/media/AnimSets/player/run/ProjectYakuza_DD_LocomotionRun.xml').getroot();clips=[e.text for e in n.iter('m_AnimName')];assert 'Bob_Walk'in clips and 'ProjectYakuza_DD_Walk'not in clips
with zipfile.ZipFile(root/'dist/ProjectYakuza-B42-v0.77.0.zip')as archive:
    checked=0
    for name in archive.namelist():
        relative=name.split('/',1)[1]if '/'in name else ''
        if relative.endswith('/')or not relative:continue
        if relative.startswith('42/media/anims_X/')or any(relative.startswith('42/media/AnimSets/player/'+g+'/')for g in ['melee','stomp','actions']):
            actual=(mod/relative).read_bytes();original=archive.read(name)
            remixed={v['output']:v for v in json.loads((mod/'docs/rush-twohit-sections.json').read_text())['clips']}
            if relative in remixed:
                assert hashlib.sha256(actual).hexdigest()==remixed[relative]['sha256'];continue
            if relative.endswith('.xml')and ('StyleEntry'in relative or E.fromstring(actual).findtext('m_AnimName')in ['ProjectYakuza_DD_HeatRush','ProjectYakuza_DD_HeatRushVictim']):
                node=E.fromstring(actual);old=E.fromstring(original);node.find('m_BlendOutTime').text=old.findtext('m_BlendOutTime')
                if node.findtext('m_AnimName')in ['ProjectYakuza_DD_HeatRush','ProjectYakuza_DD_HeatRushVictim']:node.find('m_SpeedScale').text=old.findtext('m_SpeedScale')
                early=node.find('m_EarlyTransitionOut')
                if early is not None:node.remove(early)
                for tree in [node,old]:
                    for item in tree.iter():item.text=item.text.strip()if item.text else None;item.tail=None
                assert E.tostring(node)==E.tostring(old),relative
            else:assert actual==original,relative;checked+=1
(here/'vanilla-pose-contract.tsv').write_text('\n'.join(rows),encoding='utf-8')
r=subprocess.run([str(game/'jre64/bin/java.exe'),'-cp','.;'+str(game/'*'),'VanillaPoseProbe','vanilla-pose-contract.tsv'],cwd=here,capture_output=True,text=True);print(r.stdout);assert r.returncode==0,r.stderr
print('PASS all 30 disabled pose selectors, absent Lua producers, native walking run-blend and',checked,'unchanged motion/combat XML files')
