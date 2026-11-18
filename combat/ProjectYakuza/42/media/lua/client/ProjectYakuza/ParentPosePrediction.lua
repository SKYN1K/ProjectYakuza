require "ProjectYakuza/ParentPoseTracks"
local P={}
ProjectYakuza.ParentPosePrediction=P
function P.slerp(a,b,t,out)
    local dot=0;for i=4,7 do dot=dot+a[i]*b[i]end
    local sign=dot<0 and -1 or 1;dot=math.min(1,math.abs(dot))
    local x,y=1-t,t*sign
    if dot<.9995 then local angle=math.acos(dot);local d=math.sin(angle);x=math.sin((1-t)*angle)/d;y=math.sin(t*angle)/d*sign end
    for i=1,3 do out[i]=a[i]+(b[i]-a[i])*t end
    local length=0;for i=4,7 do out[i]=a[i]*x+b[i]*y;length=length+out[i]^2 end
    length=math.sqrt(length);for i=4,7 do out[i]=out[i]/length end
    return out
end
function P.sample(track,time,bone,out)
    local rows=track.bones[bone];local frame=math.max(0,math.min(#rows-1,time*track.fps));local index=math.floor(frame)
    return P.slerp(rows[index+1],rows[math.min(index+2,#rows)],frame-index,out)
end
function P.matrix(p)
    local x,y,z,w=p[4],p[5],p[6],p[7]
    return {1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w),p[1],2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w),p[2],2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y),p[3]}
end
function P.multiply(a,b)
    local out={}
    for row=0,2 do
        local i=row*4
        for col=1,3 do out[i+col]=a[i+1]*b[col]+a[i+2]*b[col+4]+a[i+3]*b[col+8]end
        out[i+4]=a[i+1]*b[4]+a[i+2]*b[8]+a[i+3]*b[12]+a[i+4]
    end
    return out
end
function P.parent(track,time,count)
    local matrix,pose=nil,{}
    for bone=1,count do local localMatrix=P.matrix(P.sample(track,time,bone,pose));matrix=matrix and P.multiply(matrix,localMatrix)or localMatrix end
    return matrix
end
function P.base(p,count)
    local active={};local total=0
    for slot=0,7 do
        local name=p:dbgGetAnimTrackName(0,slot);if not name or name==""then break end
        local track=ProjectYakuza.ParentPoseTracks[name];local weight=p:dbgGetAnimTrackWeight(0,slot)
        if track and weight>.001 then active[#active+1]={track=track,time=p:dbgGetAnimTrackTime(0,slot),weight=weight};total=total+weight end
    end
    if total<=.001 then return end
    local matrix;local sample,pose={},{}
    for bone=1,count do
        local sum=0
        for i,entry in ipairs(active)do
            P.sample(entry.track,entry.time,bone,sample)
            if i==1 then for j=1,7 do pose[j]=sample[j]end else P.slerp(pose,sample,entry.weight/(sum+entry.weight),pose)end
            sum=sum+entry.weight
        end
        local localMatrix=P.matrix(pose);matrix=matrix and P.multiply(matrix,localMatrix)or localMatrix
    end
    return matrix
end
function P.correction(p,animation,time)
    local count=ProjectYakuza.ParentPoseMasks[animation];local track=count and ProjectYakuza.ParentPoseTracks[animation]
    if not track then return end
    local base=P.base(p,count);if not base then return end
    local original=P.parent(track,time,count);local inverse={}
    for row=0,2 do
        local i=row*4
        for col=1,3 do inverse[i+col]=original[(col-1)*4+row+1]end
        inverse[i+4]=-(inverse[i+1]*original[4]+inverse[i+2]*original[8]+inverse[i+3]*original[12])
    end
    return P.multiply(base,inverse)
end
function P.point(matrix,x,y,z)
    return matrix[1]*x+matrix[2]*y+matrix[3]*z+matrix[4],matrix[5]*x+matrix[6]*y+matrix[7]*z+matrix[8],matrix[9]*x+matrix[10]*y+matrix[11]*z+matrix[12]
end
