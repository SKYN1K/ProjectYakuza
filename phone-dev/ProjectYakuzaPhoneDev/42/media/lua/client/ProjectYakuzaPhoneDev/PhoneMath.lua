require "ProjectYakuzaPhoneDev/Assets"
local D=ProjectYakuza.PhoneDev
local M={width=320,height=568}
D.Math=M
function M.clamp(v,a,b)return math.max(a,math.min(b,v))end
function M.ease(v)v=M.clamp(v,0,1);return 1-(1-v)^3 end
function M.pose(open,px,py,reduce,tilt)
    local amount=reduce and 0 or 1-open
    local x,y=0,0
    if tilt and not reduce then x=M.clamp(px,-1,1);y=M.clamp(py,-1,1)end
    return {rx=math.rad(4+y*3-55*amount),ry=math.rad(6+x*6-35*amount),rz=math.rad(10+x*1.5+12*amount),scale=1-.5*amount,x=0,y=-14*amount,z=-.6*amount}
end
function M.transform(pose,x,y,z)
    x,y,z=x*pose.scale,y*pose.scale,z*pose.scale
    local a,b,c=-pose.rz,pose.ry,pose.rx
    local cc,sc=math.cos(c),math.sin(c);x,y=x*cc-y*sc,x*sc+y*cc
    local cb,sb=math.cos(b),math.sin(b);x,z=x*cb+z*sb,-x*sb+z*cb
    local ca,sa=math.cos(a),math.sin(a);y,z=y*ca-z*sa,y*sa+z*ca
    return x+pose.x,y+pose.y,z+pose.z
end
function M.screenPoint(pose,u,v)
    return M.transform(pose,-.3905,5.7124272-11.4788473*v,-3.2274276+6.4548552*u)
end
function M.project(pose,width,height,quad)
    quad=quad or {{},{},{},{}}
    local mult=math.exp(.2)*160/1.82*width/1366
    for i,p in ipairs({{0,0},{1,0},{1,1},{0,1}})do
        local x,y,z=M.screenPoint(pose,p[1],p[2]);quad[i][1]=width/2+z*mult;quad[i][2]=height/2-y*mult
    end
    return quad
end
function M.point(q,u,v)
    return q[1][1]+(q[2][1]-q[1][1])*u+(q[4][1]-q[1][1])*v,q[1][2]+(q[2][2]-q[1][2])*u+(q[4][2]-q[1][2])*v
end
function M.unproject(q,x,y)
    local ax,ay=q[2][1]-q[1][1],q[2][2]-q[1][2];local bx,by=q[4][1]-q[1][1],q[4][2]-q[1][2]
    local det=ax*by-ay*bx;if math.abs(det)<.001 then return end
    local dx,dy=x-q[1][1],y-q[1][2]
    return (dx*by-dy*bx)/det,(ax*dy-ay*dx)/det
end
function M.appRect(index)
    local column=(index-1)%3;local row=math.floor((index-1)/3)
    return 25+column*103,168+row*111,64,68
end
function M.hit(q,x,y)
    local u,v=M.unproject(q,x,y);if not u or u<0 or v<0 or u>1 or v>1 then return end
    x,y=u*M.width,v*M.height
    for i=1,9 do local ax,ay,aw,ah=M.appRect(i);if x>=ax-7 and x<=ax+aw+7 and y>=ay-9 and y<=ay+ah+31 then return i end end
end
function M.iconRect(asset,cx,cy,size)
    local b=asset.bounds;local scale=math.min(size/(b[3]-b[1]),size/(b[4]-b[2]))
    return cx-(b[1]+b[3])*scale/2,cy-(b[2]+b[4])*scale/2,asset.width*scale,asset.height*scale
end
