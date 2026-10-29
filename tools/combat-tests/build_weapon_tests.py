from pathlib import Path
w=Path(__file__).parent;m=w.parents[1]/"combat/ProjectYakuza/42/media/lua"
s=(w/"weapon-test-fixture.lua").read_text(encoding="utf-8")
for marker,path in [("REGISTRY","shared/ProjectYakuza/Registry.lua"),("WEAPONS","shared/ProjectYakuza/Weapons.lua"),("COMBO","shared/ProjectYakuza/Combo.lua"),("STYLE","shared/ProjectYakuza/Styles/DragonOfDojima.lua"),("BINDINGS","shared/ProjectYakuza/Bindings.lua"),("HEAT","shared/ProjectYakuza/Heat.lua"),("RUNTIME","client/ProjectYakuza/Runtime.lua"),("QUICKSTEPS","client/ProjectYakuza/Quicksteps.lua")]:
 s=s.replace("-- "+marker+"\n","do local moduleResult=(function()\n"+(m/path).read_text(encoding="utf-8")+"\nend)() end\n")
menu=(m/'client/ProjectYakuza/Menu.lua').read_text(encoding='utf-8').split('local function disable')[0]
s=s.replace('-- MENU_EQUIP\n','do\n'+menu+'\nend\n')
(w/"weapon-tests.lua").write_text(s,encoding="utf-8")
