Material.maxFaces=224
function Material:refresh()
    local pose=self.host.pose;local last=self.lastPose
    if last and last.rx==pose.rx and last.ry==pose.ry and last.rz==pose.rz and last.scale==pose.scale and last.y==pose.y and last.z==pose.z then return end
    self.lastPose={rx=pose.rx,ry=pose.ry,rz=pose.rz,scale=pose.scale,y=pose.y,z=pose.z};self.draws={}
    local mult=math.exp(.2)*160/1.82*self.width/1366
    for _,face in ipairs(Material.faces)do
        local nx,ny,nz=M.transform(pose,face[1],face[2],face[3]);nx,ny,nz=(nx-pose.x)/pose.scale,(ny-pose.y)/pose.scale,(nz-pose.z)/pose.scale
        if nx<-.015 and #self.draws<Material.maxFaces then
            local entry={points={},depth=0};local diffuse=math.max(0,-.45*nx+.75*ny+.48*nz)
            entry.shade=M.clamp(.48-.48*diffuse,.05,.45)
            local roughness=M.clamp(face[5]+face[6]*.15,.2,.85)
            entry.specular=math.min(1,math.max(0,-.852*nx+.441*ny+.281*nz))^(8+(1-roughness)*32)*(.09+.17*face[4])
            for i=1,4 do local base=7+(i-1)*3;local x,y,z=M.transform(pose,face[base],face[base+1],face[base+2]);entry.depth=entry.depth+x;entry.points[i]={self.width/2+z*mult,self.height/2-y*mult}end
            local winding=0
            for i=1,4 do local first,second=entry.points[i],entry.points[i%4+1];winding=winding+first[1]*second[2]-second[1]*first[2]end
            if winding<0 then entry.points[2],entry.points[4]=entry.points[4],entry.points[2]end
            self.draws[#self.draws+1]=entry
        end
    end
    table.sort(self.draws,function(a,b)return a.depth>b.depth end)
end
function Material:prerender()
    local host=self.host
    if not host.modelReady or host.open<=.005 then return end
    local texture=host.textures.Pixel;if not texture or not texture:isReady()then return end
    self:refresh()
    self:setStencilRect(0,0,self.width,self.height)
    for _,entry in ipairs(self.draws)do
        local q=entry.points;local a=host.open
        local dark=a*entry.shade;local shine=entry.specular>.005 and a*entry.specular or 0
        local alpha=dark+shine*(1-dark);local light=alpha>0 and shine/alpha or 0
        self:drawTextureAllPoint(texture,q[1][1],q[1][2],q[2][1],q[2][2],q[3][1],q[3][2],q[4][1],q[4][2],.82*light,.91*light,light,alpha)
    end
    self:clearStencilRect()
end
