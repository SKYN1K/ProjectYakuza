require "ProjectYakuza/EncounterIntro"
local PY=ProjectYakuza
require "ProjectYakuza/EncounterFont"
local font=PY.EncounterFont
local function clamp(x)return math.max(0,math.min(1,x))end
PY.registerStyleUI("ProjectYakuza.y6Encounter",{
    create=function(c,s)
        s.font=c.texture(font.path);s.flare=c.texture("media/textures/ProjectYakuza/EncounterFlare.png")
        s.explosion=c.texture("media/textures/ProjectYakuza/EncounterExplosion.png")
        s.shock=c.texture("media/textures/ProjectYakuza/EncounterShock.png")
        s.layout=PY.EncounterIntro.layoutText(font,c.extra.title)
    end,
    render=function(c,s)
        local t=c.extra.elapsed;local duration=c.extra.duration;local panel=c.panel
        local enter=clamp(t/.30);local settle=1-(1-enter)^3
        local leave=clamp((duration-t)/.35);local alpha=enter*leave
        local width,height=c.viewport.width,c.viewport.height
        local age=t-.30;local impact=age>=0 and clamp(1-age/.26) or 0
        local shakeX=math.sin(math.max(0,age)*95)*5*impact*impact
        local shakeY=math.cos(math.max(0,age)*73)*3*impact*impact
        local scale=math.min(.72,width*.78/math.max(1,s.layout.width))*(.58+.42*settle+.08*impact)
        local centerX=width/2-width*.72*(1-settle)+(1-leave)*width*.035+shakeX
        local centerY=height*.47-height*.20*(1-settle)+shakeY
        local x=centerX-s.layout.width*scale/2;local y=centerY-font.lineHeight*scale/2
        local renderer=SpriteRenderer.instance;renderer:setDoAdditive(false)
        local filter=clamp(t/.12)*clamp((1.4-t)/.6)
        panel:drawRect(0,0,width,height,.30*filter,.04,.07,.11)
        panel:drawRect(0,0,width,height*.08,.12*filter,0,0,0)
        panel:drawRect(0,height*.92,width,height*.08,.12*filter,0,0,0)
        if age>=0 and age<.85 then
            local wave=clamp(age/.30)
            if s.shock then
                local size=180+320*wave
                panel:drawTextureScaled(s.shock,centerX-size/2,centerY-size/2,size,size,(1-wave)*.36,1,.92,.88)
            end
            if s.explosion then
                for i=1,3 do
                    local localAge=age-(i-1)*.035
                    if localAge>=0 and localAge<.72 then
                        local frame=math.min(63,math.floor(localAge/.72*64))
                        local size=math.min(260,width*.22)
                        local bx=centerX+(i-2)*math.min(s.layout.width*scale*.24,180)
                        panel:drawSubTexture(s.explosion,(frame%8)*128,math.floor(frame/8)*128,128,128,
                            bx-size/2,centerY-size*.45,size,size,clamp((.72-localAge)/.20)*.65,1,1,1)
                    end
                end
            end
        end
        if s.flare then
            local flash=clamp(1-math.abs(t-.32)/.12)*.44
            local size=420
            panel:drawTextureScaled(s.flare,centerX-size/2,centerY-size/2,size,size,flash,.95,.18,.12)
            local sweep=clamp((t-.12)/.50)
            if sweep>0 and sweep<1 then
                local fx=x+s.layout.width*scale*sweep
                panel:drawTextureScaled(s.flare,fx-110,centerY-110,220,220,alpha*.16,1,.75,.55)
            end
        end
        PY.EncounterIntro.drawText(panel,font,s.layout,s.font,x+3,y+4,scale,alpha*.85,0,0,0)
        PY.EncounterIntro.drawText(panel,font,s.layout,s.font,x,y,scale,alpha,1,.97,.95)
        return true
    end,
})
