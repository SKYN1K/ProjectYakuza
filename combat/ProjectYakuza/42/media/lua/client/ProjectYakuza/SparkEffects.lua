require "ProjectYakuza/WorldEffects"
local PY=ProjectYakuza
local S={serial=0}
PY.SparkEffects=S
function S.load()
    if S.assets then return end
    S.assets={}
    for _,source in ipairs({{"media/textures/ProjectYakuza/ChargeSpark.png",16,32,8,16,true,.65},{"media/textures/ProjectYakuza/AttackFX/e_j_0361_spark_b.png",32,64,16,16,true,.45},{"media/textures/ProjectYakuza/AttackFX/e_f_d0004_spark.png",64,64,32,32,false,.62}})do
        local sprite=IsoSprite.CreateSprite(nil);sprite:LoadFramesNoDirPageSimple(source[1])
        S.assets[#S.assets+1]={sprite=sprite,texture=sprite:getTextureForFrame(0,IsoDirections.N),width=source[2],height=source[3],px=source[4],py=source[5],additive=source[6],gain=source[7]}
    end
end
function S.random(point)
    point.randomSeed=(point.randomSeed or 1)*48271%2147483647
    return point.randomSeed/2147483647
end
function S.assign(point,seed)
    S.load();S.serial=S.serial+1
    point.randomSeed=math.max(1,math.floor((seed or S.serial*7919)%2147483646)+1)
    S.random(point);S.random(point)
    point.spark=S.assets[math.floor(S.random(point)*#S.assets)+1]
    point.angle=S.random(point)*math.pi*2
    point.spin=(S.random(point)<.5 and -1 or 1)*(7+S.random(point)*24)
    point.sparkScale=.72+S.random(point)*.55
    return point
end
function S.quad(x,y,width,height,px,py,scale,angle)
    local c,s=math.cos(angle)*scale,math.sin(angle)*scale
    local ax,ay=x-px*c+py*s,y-px*s-py*c
    local bx,by=ax+width*c,ay+width*s
    return ax,ay,bx,by,bx-height*s,by+height*c,ax-height*s,ay+height*c
end
function S.render(point,x,y,z,scale,angle,alpha,color,drop)
    local asset=point.spark;local texture=asset and asset.texture
    if not texture or texture.isReady and not texture:isReady()or alpha<=.001 then return end
    local sx,sy=IsoUtils.XToScreenExact(x,y,z,0),IsoUtils.YToScreenExact(x,y,z,0)+(drop or 0)
    local factor=scale*point.sparkScale*32/math.max(asset.width,asset.height)
    local x1,y1,x2,y2,x3,y3,x4,y4=S.quad(sx,sy,asset.width,asset.height,asset.px,asset.py,factor,angle)
    SpriteRenderer.instance:setDoAdditive(asset.additive)
    local r,g,b=color.getR and color:getR()or color.r,color.getG and color:getG()or color.g,color.getB and color:getB()or color.b
    SpriteRenderer.instance:renderPoly(texture,x1,y1,x2,y2,x3,y3,x4,y4,r,g,b,alpha*asset.gain)
end
function S.fly(point,p,clock,x,y,z,scale,alpha,color,drop)
    if not point.born or clock<point.born or clock-point.born>=point.life then
        S.assign(point,point.randomSeed or clock+S.serial*7919)
        point.born=clock;point.life=100+S.random(point)*170
        point.x,point.y,point.z=x,y,z
        local angle=S.random(point)*math.pi*2;local speed=.35+S.random(point)*1.1
        point.vx,point.vy,point.vz=math.cos(angle)*speed,math.sin(angle)*speed,.15+S.random(point)*.8
        point.drag=.4+S.random(point)*2.3;point.gravity=1.1+S.random(point)*2;point.curve=(S.random(point)-.5)*4
    end
    local t=(clock-point.born)*.001;local age=(clock-point.born)/point.life
    local travel=t/(1+point.drag*t);local bend=point.curve*t*t
    S.render(point,point.x+point.vx*travel-point.vy*bend,point.y+point.vy*travel+point.vx*bend,math.max(math.floor(point.z)+.005,point.z+point.vz*t-point.gravity*t*t),scale*(1-.45*age),point.angle+point.spin*t,alpha*(1-age)^1.25,color,drop)
end
if PY.TextureWarmup and PY.TextureWarmup.add then PY.TextureWarmup.add("spark textures",S.load)end
