require=function()end
local checks=0;local function check(v,m)checks=checks+1;assert(v,m)end
local function near(a,b)return math.abs(a-b)<.00001 end
ProjectYakuza={};IsoDirections={N=0};local creates=0;local draws={};local blend=false
IsoSprite={CreateSprite=function()creates=creates+1;local sprite={texture={ready=true,isReady=function(self)return self.ready end}};function sprite:LoadFramesNoDirPageSimple(path)self.texture.path=path end;function sprite:getTextureForFrame()return self.texture end;return sprite end}
IsoUtils={XToScreenExact=function(x,y,z)return(x-y)*64-32 end,YToScreenExact=function(x,y,z)return(x+y)*32-z*192+16 end}
SpriteRenderer={instance={setDoAdditive=function(_,v)blend=v end,renderPoly=function(_,texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,a)draws[#draws+1]={texture=texture,x1=x1,y1=y1,x2=x2,y2=y2,x3=x3,y3=y3,x4=x4,y4=y4,r=r,g=g,b=b,a=a,additive=blend}end}}
do local _="ProjectYakuzaFixture:SPARKRENDER" end
local S=ProjectYakuza.SparkEffects;S.load();S.load();check(creates==3,'three supplied textures are loaded once')
local assets={};local clockwise,counterclockwise=0,0
for seed=1,1000 do
 local point=S.assign({},seed*97);assets[point.spark]=true
 if point.spin>0 then clockwise=clockwise+1 else counterclockwise=counterclockwise+1 end
 check(math.abs(point.spin)>=7 and math.abs(point.spin)<=31 and point.angle>=0 and point.angle<math.pi*2,'spin has a finite random direction/rate and starting angle')
end
local count=0;for _ in pairs(assets)do count=count+1 end
check(count==3 and clockwise>300 and counterclockwise>300,'ordinary emission seeds select all textures and both spin directions')
for _,asset in ipairs(S.assets)do for degrees=0,360,15 do
 local x1,y1,x2,y2,x3,y3,x4,y4=S.quad(123,234,asset.width,asset.height,asset.px,asset.py,.2,math.rad(degrees))
 local px=x1+(x2-x1)*asset.px/asset.width+(x4-x1)*asset.py/asset.height
 local py=y1+(y2-y1)*asset.px/asset.width+(y4-y1)*asset.py/asset.height
 check(near(px,123)and near(py,234),'rotation preserves the authored spark head pivot')
 check(near((x2-x1)*(x4-x1)+(y2-y1)*(y4-y1),0),'rotating quads remain rectangular')
end end
local color={getR=function()return .94 end,getG=function()return .97 end,getB=function()return 1 end}
local point={randomSeed=31517};S.fly(point,{},0,1,2,.5,.2,.48,color,2)
local originX,originY,angle=point.x,point.y,point.angle
local seed=point.randomSeed;S.fly(point,{},40,21,22,.5,.2,.48,color,2)
check(point.x==originX and point.y==originY and point.randomSeed==seed,'flying particles keep their launch origin as the hand moves')
local first=draws[#draws];S.fly(point,{},40,101,102,.5,.2,.48,color,2);local paused=draws[#draws]
check(near(first.x1,paused.x1)and near(first.y1,paused.y1),'a frozen source clock freezes trajectory and spin')
check(point.spin~=0 and #draws==3 and first.r==.94 and first.g==.97,'particles spin while preserving the actual limb colour')
S.fly(point,{},300,21,22,.5,.2,.48,color,2)
check(point.born==300 and point.x==21 and point.y==22 and point.life>=100 and point.life<=270,'expired particles relaunch from the current limb with bounded random lifetimes')
local before=#draws;point.spark.texture.ready=false;S.render(point,1,2,.5,.2,0,.5,color,2);check(#draws==before,'unready source textures never draw placeholders');point.spark.texture.ready=true
for i,asset in ipairs(S.assets)do point.spark=asset;S.render(point,1,2,.5,.2,1,.48,color,2);check(draws[#draws].additive==(i~=3),'black-backed source uses additive blending and transparent Gaiden source uses alpha')end
return 'PASS '..checks..' original spark texture variety, true rotated geometry, pivots, independent random flight/spin, pause, readiness and blend checks'
