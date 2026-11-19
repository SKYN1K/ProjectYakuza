from pathlib import Path
import struct,sys
ROOT=Path(__file__).resolve().parents[2];MOD=ROOT/'combat/ProjectYakuza';base=MOD/'42/media'
paths=sorted((base/'textures').rglob('*.png'),key=lambda p:('HeatHUD'not in str(p),'StyleSelector'not in str(p),p.as_posix()))
pixels=sum(struct.unpack_from('>II',p.read_bytes(),16)[0]*struct.unpack_from('>II',p.read_bytes(),16)[1]for p in paths)
assert len(paths)==270 and pixels*4<32*1024*1024
text='require "ProjectYakuza/Registry"\nlocal T={textures={},paths={\n'+''.join('"media/'+p.relative_to(base).as_posix()+'",\n'for p in paths)+'}}\nProjectYakuza.TextureWarmup=T\nfunction T.start()\n    for _,path in ipairs(T.paths)do if not T.textures[path]then T.textures[path]=getTexture(path)end end\nend\nEvents.OnCreatePlayer.Add(T.start)\nEvents.OnGameStart.Add(T.start)\n'
p=base/'lua/client/ProjectYakuza/TextureWarmup.lua'
if '--validate'in sys.argv:assert p.read_text()==text
else:p.write_text(text,newline='\n')
print('PASS 270 runtime texture paths queued at player creation; original RGBA footprint',round(pixels*4/1048576,2),'MiB; no pixel changes')

fixture=(ROOT/'tools/combat-tests/texture-warmup-test-fixture.lua').read_text()
fixture=fixture.replace('do local _="ProjectYakuzaFixture:WARMUP" end',text).replace('do local _="ProjectYakuzaFixture:WORLD" end',(base/'lua/client/ProjectYakuza/WorldEffects.lua').read_text())
(ROOT/'tools/combat-tests/texture-warmup-tests.lua').write_text(fixture)
