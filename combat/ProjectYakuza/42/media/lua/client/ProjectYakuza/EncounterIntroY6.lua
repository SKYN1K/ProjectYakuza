require "ProjectYakuza/EncounterIntro"
local PY=ProjectYakuza
require "ProjectYakuza/EncounterFont"
local font=PY.EncounterFont
local function clamp(x)return math.max(0,math.min(1,x))end
PY.registerStyleUI("ProjectYakuza.y6Encounter",{
    create=function(c,s)
        s.font=c.texture(font.path);s.flare=c.texture("media/textures/ProjectYakuza/EncounterFlare.png")
        s.layout=PY.EncounterIntro.layoutText(font,c.extra.title)
    end,
    render=function(c,s)
        local t=c.extra.elapsed;local duration=c.extra.duration;local panel=c.panel
        local enter=clamp(t/.24);local settle=1-(1-enter)^3
        local leave=clamp((duration-t)/.35);local alpha=enter*leave
        local width,height=c.viewport.width,c.viewport.height
        local scale=math.min(.72,width*.78/math.max(1,s.layout.width))*(1+.16*(1-settle))
        local centerX=width/2-width*.08*(1-settle)+(1-leave)*width*.035
        local centerY=height*.47
        local x=centerX-s.layout.width*scale/2;local y=centerY-font.lineHeight*scale/2
        local renderer=SpriteRenderer.instance;renderer:setDoAdditive(false)
        if s.flare then
            local flash=clamp(1-math.abs(t-.22)/.22)*.32
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
