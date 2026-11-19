from pathlib import Path
import json
from fixture_markers import fixture_marker
ROOT=Path(__file__).resolve().parents[2];W=Path(__file__).parent;MOD=ROOT/'phone-dev/ProjectYakuzaPhoneDev/42/media/lua/client/ProjectYakuzaPhoneDev'
s=(W/'phone-dev-test-fixture.lua').read_text()
for key,name in [('PHONEASSETS','Assets'),('PHONEMATH','PhoneMath'),('PHONEDATA','PhoneData'),('PHONEFONT','PhoneFont'),('PHONEITEMS','PhoneItems'),('PHONEPANEL','PhonePanel'),('PHONEBOOT','PhoneDev')]:s=s.replace(fixture_marker(key),'do\n'+(MOD/(name+'.lua')).read_text()+'\nend\n')
def lua(v):
 if isinstance(v,bool):return str(v).lower()
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,list):return '{'+','.join(lua(x)for x in v)+'}'
 if isinstance(v,dict):return '{'+','.join('['+lua(k)+']='+lua(x)for k,x in v.items())+'}'
 return format(v,'.12g')
s=s.replace('"ProjectYakuzaFixture:PHONEREFS"',lua(json.loads((ROOT/'tools/phone-dev-build/cases.json').read_text())))
(W/'phone-dev-tests.lua').write_text(s,newline='\n')
