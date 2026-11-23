from pathlib import Path
from fixture_markers import fixture_marker
root=Path(__file__).resolve().parents[2];w=Path(__file__).parent;lua=root/'combat/ProjectYakuza/42/media/lua/client/ProjectYakuza'
for fixture,marker,module in [('spark-effects','SPARKRENDER','SparkEffects'),('heat-screen','HEATSCREEN','HeatScreenEffects')]:
 text=(w/(fixture+'-test-fixture.lua')).read_text(encoding='utf-8').replace(fixture_marker(marker),'do\n'+(lua/(module+'.lua')).read_text(encoding='utf-8')+'\nend\n');(w/(fixture+'-tests.lua')).write_text(text,encoding='utf-8',newline='\n')
