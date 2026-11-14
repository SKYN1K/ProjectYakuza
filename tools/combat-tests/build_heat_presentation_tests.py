from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;lua=root/'combat/ProjectYakuza/42/media/lua'
subprocess.run([sys.executable,str(w/'build_heat_rush_tests.py')],check=True)
s=(w/'heat-rush-tests.lua').read_text(encoding='utf-8').rsplit("return true,'PASS ",1)[0]
s+='\ndo\n'+(lua/'client/ProjectYakuza/HeatPresentationData.lua').read_text(encoding='utf-8')+'\nend\n'
s+='\ndo\n'+(lua/'client/ProjectYakuza/OpenGrabHeatPresentation.lua').read_text(encoding='utf-8')+'\nend\n'
s+='\ndo\n'+(lua/'client/ProjectYakuza/HeatActionPresentation.lua').read_text(encoding='utf-8')+'\nend\n'
s+=(w/'heat-presentation-test-fixture.lua').read_text(encoding='utf-8')
(w/'heat-presentation-tests.lua').write_text(s,encoding='utf-8')
