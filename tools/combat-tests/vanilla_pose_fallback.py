from pathlib import Path
import xml.etree.ElementTree as E,json,hashlib
root=Path(__file__).resolve().parents[2]
mod=root/'combat/ProjectYakuza'
def apply():
    records=[]
    for group in ['idle','movement','run','sprint','aim','aim-strafe']:
        for path in sorted((mod/'42/media/AnimSets/player'/group).glob('ProjectYakuza_DD_*.xml')):
            n=E.parse(path).getroot()
            conditions={c.findtext('m_Name'):c.findtext('m_Value')for c in n.findall('m_Conditions')}
            profile=conditions.get('ProjectYakuzaWeaponProfile')
            gate='ProjectYakuzaCustomWeaponPoses'if profile else 'ProjectYakuzaCustomWalk'if group=='movement'else None
            if not gate:continue
            text=path.read_text(encoding='utf-8')
            if gate not in conditions:
                condition='  <m_Conditions><m_Name>'+gate+'</m_Name><m_Type>BOOL</m_Type><m_Value>true</m_Value></m_Conditions>\n'
                path.write_text(text.replace('</animNode>',condition+'</animNode>'),encoding='utf-8')
            records.append({'path':path.relative_to(mod).as_posix(),'gate':gate,'profile':profile or '', 'animation':n.findtext('m_AnimName'),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    path=mod/'42/media/AnimSets/player/run/ProjectYakuza_DD_LocomotionRun.xml'
    text=path.read_text(encoding='utf-8').replace('<m_AnimName>ProjectYakuza_DD_Walk</m_AnimName>','<m_AnimName>Bob_Walk</m_AnimName>')
    path.write_text(text,encoding='utf-8')
    for name in ['weapon-motion-assets.json','style-travel-assets.json']:
        path=mod/'docs'/name;data=json.loads(path.read_text(encoding='utf-8'))
        for entry in data['selectors']:entry['sha256']=hashlib.sha256((mod/entry['path']).read_bytes()).hexdigest()
        data['runtimeStatus']='Custom weapon poses and ordinary custom walking are disabled by unproduced animation gates as of 0.78.0, at user request. Motion clips are retained as dormant source conversions. See vanilla-pose-fallback.json.'
        path.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
    report={'version':'0.78.0','operation':'Vanilla weapon idle, aim, walk, run and sprint selection is restored by disabling the DoD overrides. Ordinary unarmed walking uses vanilla selection too; the unarmed running blend now references Bob_Walk. Custom motion files remain dormant and unchanged. These opt-in animation gate names have no Lua producer or user option, so they default false on owners and observers. No graphics/audio asset conversion or creation.','selectors':records}
    (mod/'docs/vanilla-pose-fallback.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print('PASS dormant pose gates applied to',len(records),'selectors; native walking blend restored')
if __name__=='__main__':apply()
