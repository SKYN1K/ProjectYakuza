local count=0
local function check(ok,msg)count=count+1;if not ok then error(msg)end end
require=function()end
local translations={UI_ProjectYakuza_OptionsTitle='Project Yakuza',UI_ProjectYakuza_AudioTitle='Audio',UI_ProjectYakuza_MusicVolume='Music',UI_ProjectYakuza_HitVolume='Sounds',UI_ProjectYakuza_VoiceVolume='Voices',UI_ProjectYakuza_AudioDescription='Zero mutes a group.'}
getText=function(s,...)
 check(not string.find(s,'%%'),'literal format strings must never be passed as translation keys')
 local text=translations[s]or s;if select('#',...)>0 then return string.format(text,...)end;return text
end
getKeyName=function()return 'G'end
ISDuplicateKeybindDialog={createChildren=function(self)self.label={name='native label'}end,nextDuplicate=function(self)self.label.name='native next'end}
translations.UI_ProjectYakuza_Key_grab='Grab / Throw keyboard bind';translations.UI_optionscreen_keyAlreadyBinded='%s is already assigned to %s'
local startup={};Events={OnGameStart={Add=function(fn)startup[#startup+1]=fn end}}
SystemDisabler={setEnableAdvancedSoundOptions=function(v)SystemDisabler.enabled=v end}
local levels={};local saved=0
GameSounds={getSound=function(name)return {setUserVolume=function(_,v)levels[name]=v end}end,saveINI=function()saved=saved+1 end}
local inputLines={'slider|ProjectYakuza|musicVolume|65','slider|ProjectYakuza|hitVolume|120'}
getFileReader=function()local i=0;return {readLine=function()i=i+1;return inputLines[i]end,close=function()end}end
local writes={}
getFileWriter=function()return {write=function(_,s)writes[#writes+1]=s end,close=function()end}end
luautils={split=function(s,delimiter)
 local result={};local start=1
 while true do local pos=string.find(s,delimiter,start,true);if not pos then result[#result+1]=string.sub(s,start);break end
 result[#result+1]=string.sub(s,start,pos-1);start=pos+string.len(delimiter) end
 return result
end}
do local _="ProjectYakuzaFixture:PRODUCTION_MODULES" end
local api=PZAPI.ModOptions;local options=api:getOptions('ProjectYakuza')
check(SystemDisabler.enabled and options.name=='Project Yakuza','registered native Mods entry and Advanced compatibility')
for _,opt in ipairs(options.data)do if opt.type=='slider' then check(translations[opt.name]~=nil,'slider name is a registered translation key');getText(opt.name) end end
local controlCount=0
for _,opt in ipairs(options.data)do
 if opt.type=='combobox' or opt.type=='keybind' then
  controlCount=controlCount+1
  check(not string.find(opt.name,'UI_ProjectYakuza_',1,true),'native settings receive readable captions without unresolved translation keys')
 end
end
check(controlCount==18,'nine actions have one binding type and one keyboard row each')
check(options:getOption('input_light').name=='Light Attack keybind type' and options:getOption('key_light').name=='Light Attack keyboard bind','exact requested naming style works without a loaded translation')
check(options:getOption('input_finisher').name=='Heavy Attack / Finisher keybind type','combined heavy control has a readable caption')
for _,id in ipairs({'runningLight','dropkick','quickstepAttack','counter'})do
 check(options:getOption('input_'..id)==nil and options:getOption('key_'..id)==nil,'context action has no dedicated setting '..id)
end
local intro=options:getOption('encounterIntro')
check(intro.type=='tickbox' and intro.name=='Zombie Encounter Intro' and intro:getValue() and ProjectYakuza.isEncounterIntroEnabled(),'readable encounter toggle defaults to enabled')
inputLines[#inputLines+1]='tickbox|ProjectYakuza|encounterIntro|false'
for _,fn in ipairs(startup)do fn()end
check(not intro:getValue() and not ProjectYakuza.isEncounterIntroEnabled(),'native Mods settings restore disabled intro preference')
intro:setValue(true);options:apply();check(ProjectYakuza.isEncounterIntroEnabled(),'checkbox re-enables the intro')
local introCleared=false;ProjectYakuza.EncounterIntro={clear=function(_,reason)introCleared=reason=='disabled'end}
intro:setValue(false);options:apply();check(introCleared,'applying the disabled preference closes an active intro immediately')
check(options:getOption('musicVolume'):getValue()==65 and options:getOption('hitVolume'):getValue()==120,'native ini restores grouped sliders')
for _,track in ipairs(ProjectYakuza.styles.dragon_of_dojima.music)do check(levels[track.sound]==1,'music group applies to supplied style tracks')end
for _,cue in ipairs({'PunchImpact','KickImpact','HeatImpact','Finisher','ThrowImpact','GuardBreak'})do check(levels['ProjectYakuza_Y6_'..cue]==1.2,'hit group applies to impacts')end
check(levels.ProjectYakuza_Y6_HeatGain==1.2 and levels.ProjectYakuza_Y6_HeatOnA==1.2,'Sounds covers orb and activation SFX as well')
check(levels.ProjectYakuza_LowHealthHeartbeat==1.2 and levels.HeartBeat==nil,'mod heartbeat follows Sounds without changing the vanilla heartbeat event volume')
options:getOption('hitVolume'):setValue(0);options:apply();check(levels.ProjectYakuza_Y6_PunchImpact==0 and levels.ProjectYakuza_FunkGoesOn==1,'zero mutes hits without muting music')
check(levels.ProjectYakuza_LowHealthHeartbeat==0,'zero Sounds also mutes the mod low-health heartbeat')
options:getOption('musicVolume'):setValue(500);options:apply();check(ProjectYakuza.SoundSettings.musicLevel()==2 and levels.ProjectYakuza_FunkGoesOn==1,'saved malformed values clamp to 200 percent')
ProjectYakuza.registerStyle({id='addon.volume',name='Volume Addon',lightAttacks={{animation='Native',nodeValue='volume',duration=1}},music={{sound='AddonMusic'}},sounds={punchImpact='AddonImpact'}})
check(levels.AddonMusic==1 and ProjectYakuza.SoundSettings.musicLevel()==2 and levels.AddonImpact==0,'late registered styles join grouped controls')
api:save();local text=table.concat(writes,'')
check(string.find(text,'tickbox|ProjectYakuza|encounterIntro|false',1,true)~=nil,'disabled intro preference is persisted')
check(string.find(text,'hitVolume|0',1,true)~=nil and saved>0,'native ModOptions persistence and GameSounds persistence used')
local conflict={key=34,keybind2Name='UI_ProjectYakuza_Key_grab'};ISDuplicateKeybindDialog.createChildren(conflict);check(conflict.label.name=='G is already assigned to Grab / Throw keyboard bind','native mod-binding conflicts use readable translated labels');conflict.keybind2Name='Grab / Throw keyboard bind';ISDuplicateKeybindDialog.nextDuplicate(conflict);check(conflict.label.name=='G is already assigned to Grab / Throw keyboard bind','subsequent native conflicts resolve translated captions too');conflict.keybind2Name='Foreign action';ISDuplicateKeybindDialog.nextDuplicate(conflict);check(conflict.label.name=='native next','foreign binding conflicts remain delegated')
return 'PASS '..count..' native Mods slider, persistence, grouping and late-style checks'
