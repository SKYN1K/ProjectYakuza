from fixture_markers import module_source
from fixture_markers import fixture_marker
from pathlib import Path
w=Path(__file__).parent;m=w.parents[1]/'combat/ProjectYakuza/42/media/lua'
prefix=(w/'quickstep-once-test-fixture.lua').read_text(encoding='utf-8').split("for _,direction in ipairs")[0]
s=prefix+(w/'charged-ui-test-fixture.lua').read_text(encoding='utf-8')
for marker,path in [('REGISTRY','shared/ProjectYakuza/Registry.lua'),('COMBO','shared/ProjectYakuza/Combo.lua'),('STYLE','shared/ProjectYakuza/Styles/DragonOfDojima.lua'),('BINDINGS','shared/ProjectYakuza/Bindings.lua'),('RUNTIME','client/ProjectYakuza/Runtime.lua'),('QUICKSTEPS','client/ProjectYakuza/Quicksteps.lua'),('CHARGE','client/ProjectYakuza/ChargedHeavy.lua'),('UI','client/ProjectYakuza/StyleUI.lua'),('OUTLINE','client/ProjectYakuza/HeatOutline.lua'),('WORLD','client/ProjectYakuza/WorldEffects.lua'),('ATTACKTRACKS','client/ProjectYakuza/AttackTracks.lua'),('ATTACKEFFECTS','client/ProjectYakuza/AttackEffects.lua'),('CHARGETRACKS','client/ProjectYakuza/ChargeTracks.lua'),('SPARKS','client/ProjectYakuza/ChargeEffects.lua'),('HITS','client/ProjectYakuza/HitEffects.lua'),('HEATUI','client/ProjectYakuza/HeatUI.lua')]:
 s=s.replace(fixture_marker(marker),'do local moduleResult=(function()\n'+module_source(m/path)+'\nend)() end\n')
(w/'charged-ui-tests.lua').write_text(s,encoding='utf-8')
