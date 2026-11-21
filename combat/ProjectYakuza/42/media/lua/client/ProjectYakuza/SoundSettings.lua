

SystemDisabler.setEnableAdvancedSoundOptions(true)
require "PZAPI/ModOptions"
require "ISUI/ISDuplicateKeybindDialog"
require "ProjectYakuza/Registry"
require "ProjectYakuza/Bindings"
local options=PZAPI.ModOptions:create("ProjectYakuza",getText("UI_ProjectYakuza_OptionsTitle"))
options:addTitle(getText("UI_ProjectYakuza_AudioTitle"))
local music=options:addSlider("musicVolume","UI_ProjectYakuza_MusicVolume",0,200,5,100)
local hits=options:addSlider("hitVolume","UI_ProjectYakuza_HitVolume",0,200,5,100)
local voices=options:addSlider("voiceVolume","UI_ProjectYakuza_VoiceVolume",0,200,5,100)
options:addDescription("UI_ProjectYakuza_AudioDescription")
ProjectYakuza.SoundSettings={
    voiceLevel=function()return math.max(0,math.min(2,(tonumber(voices:getValue()) or 100)/100))end,
    musicLevel=function()return math.max(0,math.min(2,(tonumber(music:getValue()) or 100)/100))end,
}
options:addTitle("Presentation")
local encounterIntro=options:addTickBox("encounterIntro","Zombie Encounter Intro",true,"Show the animated encounter title and its sound when a fight starts.")
function ProjectYakuza.isEncounterIntroEnabled()return encounterIntro:getValue()~=false end
ProjectYakuza.Bindings.configure(options)
local impacts={punchImpact=true,kickImpact=true,heatImpact=true,finisher=true,doubleFinisher=true,throwImpact=true,guardHit=true,guardBreak=true}
function options:apply()
    if not ProjectYakuza.isEncounterIntroEnabled()and ProjectYakuza.EncounterIntro then ProjectYakuza.EncounterIntro.clear(nil,"disabled")end
    local musicNames,hitNames={},{ProjectYakuza_QTEAppear=true,ProjectYakuza_QTEPress=true,ProjectYakuza_QTEFail=true}
    for _,style in pairs(ProjectYakuza.styles) do
        if type(style.music)=="table" then for _,track in ipairs(style.music) do musicNames[track.sound]=true end end
        if type(style.sounds)=="table" then for _,name in pairs(style.sounds) do if type(name)=="string" then hitNames[name]=true end end end
    end
    local function setGroup(names,value)
        local level=math.max(0,math.min(2,(tonumber(value) or 100)/100))
        for name in pairs(names) do local sound=GameSounds.getSound(name);if sound then sound:setUserVolume(level) end end
    end
    setGroup(musicNames,100);setGroup(hitNames,hits:getValue())
    GameSounds.saveINI()
end
Events.OnGameStart.Add(function()PZAPI.ModOptions:load();options.loaded=true;options:apply()end)
ProjectYakuza.on("styleRegistered",function()if options.loaded then options:apply() end end)
