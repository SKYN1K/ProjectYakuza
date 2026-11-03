require=function()end
local checks=0
local function check(v,message)checks=checks+1;assert(v,message)end
Events={OnMainMenuEnter={Add=function()end}}
local names={[34]='G',[37]='K',[57]='Space',[14]='Backspace',[29]='Left Ctrl',[100]='Numpad Comma'}
local queries=0;getKeyName=function(key)queries=queries+1;return names[key]or tostring(key)end
UIFont={Large=1,Medium=2,Small=3}
getTextManager=function()return {MeasureStringX=function(_,font,text)return #text*(font==3 and 6 or 9)end,getFontHeight=function(_,font)return font==3 and 14 or 20 end}end
local loaded={};getTexture=function(path)loaded[path]=(loaded[path]or 0)+1;return {path=path}end
do local _="ProjectYakuzaFixture:BINDINGS" end
do local _="ProjectYakuzaFixture:INPUT_PROMPTS" end
local B,I=ProjectYakuza.Bindings,ProjectYakuza.InputPrompts
local values={};B.options={getOption=function(_,id)local value=values[id];if value~=nil then return {getValue=function()return value end}end end}
local panel={images={},labels={}}
function panel:drawSubTexture(texture,sx,sy,sw,sh,x,y,w,h,alpha,r,g,b)self.images[#self.images+1]={texture=texture.path,sx=sx,sy=sy,sw=sw,sh=sh,x=x,y=y,w=w,h=h,alpha=alpha}end
function panel:drawTextCentre(text,x,y,r,g,b,alpha,font)self.labels[#self.labels+1]={text=text,x=x,y=y,alpha=alpha,font=font}end
local function reset()panel.images={};panel.labels={}end
for mode,kind in ipairs({'Left','Right','Middle'})do
 reset();values.input_light=mode;local input=I.draw(panel,'light',100,200,64,.7)
 check(input.mode==mode and #panel.images==1 and #panel.labels==0,'mouse prompt uses only its original icon '..kind)
 local image=panel.images[1];check(image.texture:find('InputMouse'..kind,1,true)and image.sw==84 and image.sh==84 and image.w==64 and image.h==64 and image.alpha==.7,'mouse crop and source dimensions match '..kind)
end
values.input_light=4;values.key_light=37;reset();local key=I.draw(panel,'light',100,200,64,.8)
check(key.label=='K'and key.kind=='key'and #panel.images==9 and #panel.labels==1,'keyboard name appears over the original key frame')
check(panel.labels[1].text=='K'and panel.labels[1].x==100 and panel.labels[1].y==190,'keyboard label is centered using the native font height')
for _,image in ipairs(panel.images)do
 check(image.texture:find('InputKeycap',1,true)and image.w>0 and image.h>0,'keyboard pieces use positive game-art regions')
 local intersects=image.sx<64 and image.sx+image.sw>20 and image.sy<68 and image.sy+image.sh>20
 check(not intersects,'runtime frame never samples the original baked A legend')
end
local before=queries
for n=1,100 do check(I.describe('light')==key,'same binding reuses its descriptor')end
check(queries==before,'unchanged key prompts avoid repeated key-name lookups')
values.key_light=34;reset();I.draw(panel,'light',100,200,44,1);check(panel.labels[1].text=='G','rebinding updates the key name immediately')
values.key_light=100;reset();I.draw(panel,'light',100,200,44,1);check(panel.labels[1].text=='Numpad Comma'and panel.labels[1].font==UIFont.Small,'long key names use a readable fitting font')
values.key_light=0;reset();I.draw(panel,'light',100,200,44,1);check(panel.labels[1].text=='Unbound'and panel.images[1].alpha==.5,'unbound inputs are explicit and visually subdued')
reset();I.draw(panel,'light',100,200,44,0);check(#panel.images==0 and #panel.labels==0,'fully faded prompts do not draw')
check(I.describe('unknown.binding')==nil,'unknown binding cannot fabricate a prompt')
local options=B.options;B.options=nil;B.register({id='addon.special',name='Special',mode=4,code=29});B.options=options
reset();I.draw(panel,'addon.special',100,200,64,1);check(panel.labels[1].text=='Left Ctrl','addon bindings use the same keycap renderer')
for path,count in pairs(loaded)do check(count==1,'input textures are cached '..path)end
I.clear();local retained=0;for _ in pairs(I.cache)do retained=retained+1 end;for _ in pairs(I.textures)do retained=retained+1 end;check(retained==0,'menu cleanup releases prompt caches')
return true,'PASS '..checks..' original input icon, keyboard legend, rebinding, layout, fade, addon and cache checks'
