require "ProjectYakuza/Registry"
ProjectYakuza.registerStyle({
    id = "dragon_of_dojima",
    name = "Dragon of Dojima",
    description = "Kiryu's Yakuza 6 four-hit light chain.",
    heat=true,
    tigerDrop=true,
    combatVoiceVolume=2.25,
    quickstepVoices=false,
    attackSpeed=1.6,
    runningKneeSpeed=1.2,
    heatHud="yakuza6",
    heatAura="kiryu",
    hitEffects="yakuza6",
    sounds={
        punchImpact="ProjectYakuza_Y6_PunchImpact",kickImpact="ProjectYakuza_Y6_KickImpact",heatImpact="ProjectYakuza_Y6_HeatImpact",
        punchSwing="ProjectYakuza_Y6_PunchSwing",kickSwing="ProjectYakuza_Y6_KickSwing",finisher="ProjectYakuza_Y6_Finisher",
        grab="ProjectYakuza_Y6_Grab",throwImpact="ProjectYakuza_Y6_ThrowImpact",guardHit="ProjectYakuza_Y6_PunchImpact",guardBreak="ProjectYakuza_Y6_GuardBreak",
        heatGain="ProjectYakuza_Y6_HeatGain",heatFull="ProjectYakuza_Y6_HeatFull",heatStart="ProjectYakuza_Y6_ChargeStart",
        heatOnA="ProjectYakuza_Y6_HeatOnA",heatOnB="ProjectYakuza_Y6_HeatOnB",heatOff="ProjectYakuza_Y6_HeatOff",
    },
    music={
        {sound="ProjectYakuza_FunkGoesOn",title="Funk Goes On"},
        {sound="ProjectYakuza_BringItOn",title="Bring It On"},
        {sound="ProjectYakuza_ReceiveYouVer7",title="Receive You Ver. 7"},
        {sound="ProjectYakuza_FlirtWithBomb",title="Flirt With Bomb"},
        {sound="ProjectYakuza_SonOfAGun",title="Son of a Gun"},
        {sound="ProjectYakuza_PushMeUnderWater",title="Push Me Under Water"},
        {sound="ProjectYakuza_OutlawsLullaby",title="Outlaw's Lullaby"},
        {sound="ProjectYakuza_FunkGoesOnKiwami",title="Funk Goes On ÃƒÆ’Ã‚Â¦Ãƒâ€šÃ‚Â¥Ãƒâ€šÃ‚Âµ"},
        {sound="ProjectYakuza_PushMeDeepUnderwater",title="Push Me Deep Underwater"},
        {sound="ProjectYakuza_LullabyOfOutlaws",title="Lullaby of Outlaws"},
        {sound="ProjectYakuza_ReceiveAndBelieveYou",title="Receive and Believe You"},
        {sound="ProjectYakuza_Bruise",title="Bruise"},
        {sound="ProjectYakuza_CrushAndStrike",title="Crush & Strike"},
        {sound="ProjectYakuza_D2A",title="D 2 A"},
        {sound="ProjectYakuza_RyuKyuHumming",title="Ryu-Kyu Humming"},
        {sound="ProjectYakuza_TheMyth",title="The Myth"},
        {sound="ProjectYakuza_IsolatedFight",title="Isolated Fight"},
        {sound="ProjectYakuza_TownBully",title="Town Bully"},
        {sound="ProjectYakuza_KamuroAgain",title="KAMURO again"},
    },
    comboResetMs = 400,

    lightBufferLimit = 1,
    quickstepCancelLights=true,
    enemyReactions = true,
    hitResponses={
        light={kind="flinch",force=.25},
        finisher={kind="stagger",force=.65},
        doubleFinisher={kind="knockdown",force=.85},
        chargedHeavy={kind="stagger",force=.75,fullChargeAt=.999,fullChargeKind="knockdown",fullChargeForce=1.0},
    },
    lightAttacks = {
        { animation="ProjectYakuza_DD_Light01", nodeValue="dd_light_01", quickstepCancelAt=0.233333333333, damageMultiplier=0.75, duration=1.0/1.6, speed=1.6, impact=0.20, chainAt=0.58, reaction="enemy_01", attackEffects={track="dd_light_01",from=2/30,to=14/30,swingFrame=3,verticalOffset=2.5} },
        { animation="ProjectYakuza_DD_Light02", nodeValue="dd_light_02", quickstepCancelAt=0.191489361702, damageMultiplier=0.75, duration=(47/30)/1.6, speed=1.6, impact=8/47, chainAt=0.58, reaction="enemy_02" },
        { animation="ProjectYakuza_DD_Light03", nodeValue="dd_light_03", quickstepCancelAt=0.285714285714, damageMultiplier=0.75, duration=1.4/1.6, speed=1.6, impact=11/42, chainAt=0.58, reaction="enemy_03" },
        { animation="ProjectYakuza_DD_Light04", nodeValue="dd_light_04", quickstepCancelAt=0.255319148936, damageMultiplier=0.75, duration=(47/30)/1.6, speed=1.6, impact=11/47, chainAt=0.58, reaction="enemy_04" },
    },
    groundAttacks = {
        {animation="ProjectYakuza_DD_GroundStomp01",nodeValue="dd_ground_01",duration=1.8/1.6,speed=1.6,impact=0.25925925925925924,groundAttack=true,fullBody=true},
        {animation="ProjectYakuza_DD_GroundStomp02",nodeValue="dd_ground_02",duration=1.8/1.6,speed=1.6,impact=0.25925925925925924,groundAttack=true,fullBody=true},
    },
    actions = {
        heavyCharge={enabled=true,holdMs=350,variants={
            default={animation="ProjectYakuza_DD_ChargeLoop",duration=3.5,minChargeMs=350,maxHoldMs=1200},
            after_1={animation="ProjectYakuza_DD_ChargeWindup01",holdAnimation="ProjectYakuza_DD_ChargeHold01",duration=3.5,holdMs=200.000000,windupMs=200.000000,minChargeMs=200.000000,maxHoldMs=1200,chargeBranch=1},
            after_2={animation="ProjectYakuza_DD_ChargeWindup02",holdAnimation="ProjectYakuza_DD_ChargeHold02",duration=3.5,holdMs=233.333333,windupMs=233.333333,minChargeMs=233.333333,maxHoldMs=1200,chargeBranch=2},
            after_3={animation="ProjectYakuza_DD_ChargeWindup03",holdAnimation="ProjectYakuza_DD_ChargeHold03",duration=3.5,holdMs=200.000000,windupMs=200.000000,minChargeMs=200.000000,maxHoldMs=1200,chargeBranch=3},
            after_4={animation="ProjectYakuza_DD_ChargeWindup04",holdAnimation="ProjectYakuza_DD_ChargeHold04",duration=3.5,holdMs=166.666667,windupMs=166.666667,minChargeMs=166.666667,maxHoldMs=1200,chargeBranch=4},
        }},
        chargedHeavy={enabled=true,speed=1,variants={
            default={animation="ProjectYakuza_DD_ChargeEnd",nodeValue="dd_charged_heavy",duration=55/30,speed=1,impact=12/55,damageMultiplier=2,minChargedDamageMultiplier=1,chargedHeavy=true,fullBody=true,reaction="enemy_01"},
            after_1={animation="ProjectYakuza_DD_ChargedFinisher01",nodeValue="dd_charged_finisher_01",duration=1.700000000,speed=1,impact=0.235294118,damageMultiplier=2,minChargedDamageMultiplier=1.25,chargedHeavy=true,chargedFinisher=true,chargeBranch=1,fullBody=true,reaction="enemy_01"},
            after_2={animation="ProjectYakuza_DD_ChargedFinisher02",nodeValue="dd_charged_finisher_02",duration=1.533333333,speed=1,impact=0.260869565,damageMultiplier=2,minChargedDamageMultiplier=1.25,chargedHeavy=true,chargedFinisher=true,chargeBranch=2,fullBody=true,reaction="enemy_02"},
            after_3={animation="ProjectYakuza_DD_ChargedFinisher03",nodeValue="dd_charged_finisher_03",duration=1.833333333,speed=1,impact=0.163636364,damageMultiplier=2,minChargedDamageMultiplier=1.25,chargedHeavy=true,chargedFinisher=true,chargeBranch=3,fullBody=true,reaction="enemy_03"},
            after_4={animation="ProjectYakuza_DD_ChargedFinisher04",nodeValue="dd_charged_finisher_04",duration=1.833333333,speed=1,impact=0.236363636,damageMultiplier=2,minChargedDamageMultiplier=1.25,chargedHeavy=true,chargedFinisher=true,chargeBranch=4,fullBody=true,reaction="enemy_04"},
        }},
        styleEntry = {enabled=true,animation="ProjectYakuza_DD_StyleEntry",duration=50/30},
        taunt = {enabled=true,animation="ProjectYakuza_DD_Taunt01",duration=55/30},
        finisher = { enabled=true, variants={
            after_1={enabled=true,afterLight=1,animation="ProjectYakuza_DD_Finisher01",nodeValue="dd_finisher_01",damageMultiplier=1.25,duration=1.9/1.6,speed=1.6,impact=0.2807017543859649,reaction="enemy_01",fullBody=true,doubleLinkFrame=25,doubleLinkEndFrame=28},
            after_2={enabled=true,afterLight=2,animation="ProjectYakuza_DD_Finisher02",nodeValue="dd_finisher_02",damageMultiplier=1.25,duration=1.7666666666666666/1.6,speed=1.6,impact=0.4528301886792453,reaction="enemy_02",fullBody=true,doubleLinkFrame=31,doubleLinkEndFrame=34},
            after_3={enabled=true,afterLight=3,animation="ProjectYakuza_DD_Finisher03",nodeValue="dd_finisher_03",damageMultiplier=1.25,duration=2.033333333333333/1.6,speed=1.6,impact=0.32786885245901637,reaction="enemy_03",fullBody=true,doubleLinkFrame=26,doubleLinkEndFrame=29},
            after_4={enabled=true,afterLight=4,animation="ProjectYakuza_DD_Finisher04",nodeValue="dd_finisher_04",damageMultiplier=1.25,duration=2/1.6,speed=1.6,impact=0.4,reaction="enemy_04",fullBody=true,doubleLinkFrame=26,doubleLinkEndFrame=29},
            double_after_1={enabled=true,afterLight=1,animation="ProjectYakuza_DD_DoubleFinisher01",nodeValue="dd_double_01",damageMultiplier=1.25,duration=2.7333333333333334/1.6,speed=1.6,impact=0.34146341463414637,reaction="enemy_01",fullBody=true,double=true},
            double_after_2={enabled=true,afterLight=2,animation="ProjectYakuza_DD_DoubleFinisher02",nodeValue="dd_double_02",damageMultiplier=1.25,duration=2.7/1.6,speed=1.6,impact=0.345679012345679,reaction="enemy_02",fullBody=true,double=true},
            double_after_3={enabled=true,afterLight=3,animation="ProjectYakuza_DD_DoubleFinisher03",nodeValue="dd_double_03",damageMultiplier=1.25,duration=2.033333333333333/1.6,speed=1.6,impact=0.39344262295081966,reaction="enemy_03",fullBody=true,double=true},
            double_after_4={enabled=true,afterLight=4,animation="ProjectYakuza_DD_DoubleFinisher04",nodeValue="dd_double_04",damageMultiplier=1.25,duration=2.3666666666666667/1.6,speed=1.6,impact=0.36619718309859156,reaction="enemy_04",fullBody=true,double=true},
        } },
        grab = {enabled=false,reason="Temporarily disabled",requiresTarget=true,animation="ProjectYakuza_DD_Grab",targetAnimation="ProjectYakuza_DD_GrabVictimEnter",holdMs=3500},
        parry = {enabled=true,animation="ProjectYakuza_DD_TigerDrop",nodeValue="dd_tiger_drop",duration=1.1,speed=1,requiresTarget=true,targetAnimation="Zombie_ShotBelly",cooldownMs=60000,windowMs=200},
        block = {enabled=true,animation="ProjectYakuza_DD_Guard",staminaPerHit=.08},
        heatActivation = {enabled=true,variants={
            ["1"]={animation="ProjectYakuza_DD_HeatActivate01",duration=1.5},
            ["2"]={animation="ProjectYakuza_DD_HeatActivate02",duration=55/30},
            ["3"]={animation="ProjectYakuza_DD_HeatActivate03",duration=2},
            ["4"]={animation="ProjectYakuza_DD_HeatActivate04",duration=68/30},
        }},
        quickstep = {enabled=true,cooldownMs=180,variants={
            forward={enabled=true,direction="forward",animation="ProjectYakuza_DD_Quickstep01",nodeValue="dd_quickstep_01",duration=(22/30)/1.6875,speed=1.6875,distance=1.2,fullBody=true},
            backward={enabled=true,direction="backward",animation="ProjectYakuza_DD_Quickstep02",nodeValue="dd_quickstep_02",duration=(22/30)/1.6875,speed=1.6875,distance=1.2,fullBody=true},
            left={enabled=true,direction="left",animation="ProjectYakuza_DD_Quickstep03",nodeValue="dd_quickstep_03",duration=(22/30)/1.6875,speed=1.6875,distance=1.2,fullBody=true},
            right={enabled=true,direction="right",animation="ProjectYakuza_DD_Quickstep04",nodeValue="dd_quickstep_04",duration=(22/30)/1.6875,speed=1.6875,distance=1.2,fullBody=true},
        }},
        quickstepAttack = {enabled=true,variants={
            forward={enabled=true,direction="forward",animation="ProjectYakuza_DD_QuickstepAttack01",nodeValue="dd_quickattack_01",duration=1.4666666666666666/1.6,speed=1.6,impact=0.25,reaction="enemy_01",fullBody=true,quickstepAttack=true},
            backward={enabled=true,direction="backward",animation="ProjectYakuza_DD_QuickstepAttack02",nodeValue="dd_quickattack_02",duration=2.3/1.6,speed=1.6,impact=0.2463768115942029,reaction="enemy_02",fullBody=true,quickstepAttack=true},
            left={enabled=true,direction="left",animation="ProjectYakuza_DD_QuickstepAttack03",nodeValue="dd_quickattack_03",duration=1.5666666666666667/1.6,speed=1.6,impact=0.23404255319148937,reaction="enemy_03",fullBody=true,quickstepAttack=true},
            right={enabled=true,direction="right",animation="ProjectYakuza_DD_QuickstepAttack04",nodeValue="dd_quickattack_04",duration=1.9/1.6,speed=1.6,impact=0.24561403508771928,reaction="enemy_04",fullBody=true,quickstepAttack=true},
        }},
        runningAttack = {enabled=true,runupMs=250,variants={
            left={enabled=true,variant="left",animation="ProjectYakuza_DD_RunningAttack01",nodeValue="dd_run_01",duration=1.8333333333333333/1.6,speed=1.6,impact=0.18181818181818182,distance=0.9,reaction="enemy_01",fullBody=true,runningAttack=true},
            right={enabled=true,variant="right",animation="ProjectYakuza_DD_RunningAttack02",nodeValue="dd_run_02",duration=2.6666666666666665/1.6,speed=1.6,impact=0.225,distance=0.9,reaction="enemy_02",fullBody=true,runningAttack=true},
            knee={enabled=true,variant="knee",animation="ProjectYakuza_DD_RunningAttack03",nodeValue="dd_run_03",duration=1.6666666666666667/1.2,speed=1.2,impact=0.24,distance=1,reaction="enemy_03",fullBody=true,runningAttack=true},
            dropkick={enabled=true,variant="dropkick",animation="ProjectYakuza_DD_RunningAttack04",nodeValue="dd_run_04",duration=2.1333333333333333/1.6,speed=1.6,impact=0.21875,distance=1.2,reaction="enemy_04",fullBody=true,runningAttack=true},
        }},
        heatAction = { enabled=false, requiresTarget=true, heatStocks=1, reason="Requires paired clips, environment checks and a cinematic handler" },
    },
})

if ProjectYakuza.Weapons then
    local base=ProjectYakuza.getStyle("dragon_of_dojima")
    local sounds={};for k,v in pairs(base.sounds) do if k:match("^heat") then sounds[k]=v end end
    ProjectYakuza.Weapons.register(base.id,{
        id="bat",attackSpeed=1.4,quickstepCancelLights=true,standaloneHeavy=true,
        items={"Base.BaseballBat","Base.BaseballBat_Crafted","Base.BaseballBat_Metal","Base.BaseballBat_Nails",
            "Base.ShortBat","Base.ShortBat_Nails","Base.Nightstick","Base.MetalBar","Base.MetalPipe",
            "Base.BoneClub","Base.LargeBoneClub","Base.LongSpikedClub"},
        sounds=sounds,
        lightAttacks={
            {animation="ProjectYakuza_DD_BatLight01",nodeValue="dd_bat_light_01",duration=40/30/1.4,speed=1.4,impact=11/40,chainAt=24/40,quickstepCancelAt=12/40,damageMultiplier=1,hitResponse=false},
            {animation="ProjectYakuza_DD_BatLight02",nodeValue="dd_bat_light_02",duration=35/30/1.4,speed=1.4,impact=13/35,chainAt=25/35,quickstepCancelAt=14/35,damageMultiplier=1,hitResponse=false},
            {animation="ProjectYakuza_DD_BatLight03",nodeValue="dd_bat_light_03",duration=47/30/1.4,speed=1.4,impact=15/47,chainAt=26/47,quickstepCancelAt=16/47,damageMultiplier=1,hitResponse=false},
        },
        groundAttacks={{animation="ProjectYakuza_DD_BatGround",nodeValue="dd_bat_ground",duration=55/30/1.4,speed=1.4,impact=10/55,groundAttack=true,hitResponse=false}},
        actions={
            finisher={enabled=true,variants={default={enabled=true,animation="ProjectYakuza_DD_BatHeavy",nodeValue="dd_bat_heavy",duration=53/30/1.4,speed=1.4,impact=14/53,damageMultiplier=1.25,hitResponse=false}}},
            block={enabled=true,animation="ProjectYakuza_DD_BatGuard",staminaPerHit=.08},
            quickstep=base.actions.quickstep,
        },
    })
end

if ProjectYakuza.Weapons then
    local base=ProjectYakuza.getStyle("dragon_of_dojima")
    local sounds={};for k,v in pairs(base.sounds) do if k:match("^heat") then sounds[k]=v end end
    ProjectYakuza.Weapons.register(base.id,{
        id="knife",attackSpeed=1.5,standaloneHeavy=true,quickstepCancelLights=true,
        items={"Base.HuntingKnife","Base.HuntingKnifeForged","Base.KitchenKnife","Base.KitchenKnifeForged","Base.SteakKnife","Base.BreadKnife","Base.FightingKnife","Base.KnifeButterfly","Base.KnifeFillet","Base.KnifeParing","Base.KnifePocket","Base.KnifeShiv","Base.KnifeSushi","Base.LargeKnife","Base.LargeKnife_Scrap","Base.SmallKnife","Base.SwitchKnife","Base.CrudeKnife","Base.LongCrudeKnife","Base.MacheteKnife","Base.StoneKnifeLong","Base.FlintKnife","Base.RailroadSpikeKnife"},
        sounds=sounds,
        lightAttacks={{animation="ProjectYakuza_DD_KnifeLight01",nodeValue="dd_knife_light_01",duration=40/30/1.5,speed=1.5,impact=9/40,hitResponse=false,chainAt=23/40,quickstepCancelAt=10/40,damageMultiplier=1},{animation="ProjectYakuza_DD_KnifeLight02",nodeValue="dd_knife_light_02",duration=40/30/1.5,speed=1.5,impact=12/40,hitResponse=false,chainAt=26/40,quickstepCancelAt=13/40,damageMultiplier=1},{animation="ProjectYakuza_DD_KnifeLight03",nodeValue="dd_knife_light_03",duration=45/30/1.5,speed=1.5,impact=13/45,hitResponse=false,chainAt=23/45,quickstepCancelAt=14/45,damageMultiplier=1}},
        groundAttacks={{animation="ProjectYakuza_DD_KnifeGround",nodeValue="dd_knife_ground",duration=52/30/1.5,speed=1.5,impact=13/52,hitResponse=false,groundAttack=true}},
        actions={
            finisher={enabled=true,variants={default={animation="ProjectYakuza_DD_KnifeHeavy",nodeValue="dd_knife_heavy",duration=45/30/1.5,speed=1.5,impact=11/45,hitResponse=false,enabled=true,damageMultiplier=1.25}}},
            quickstep=base.actions.quickstep,
        },
    })
    ProjectYakuza.Weapons.register(base.id,{
        id="blade",attackSpeed=1.4,standaloneHeavy=true,quickstepCancelLights=true,
        items={"Base.Katana","Base.Machete","Base.Machete_Crude","Base.MacheteForged","Base.ShortSword","Base.ShortSword_Scrap","Base.Sword","Base.Sword_Scrap","Base.CrudeShortSword","Base.CrudeSword","Base.MeatCleaver","Base.MeatCleaverForged","Base.MeatCleaver_Scrap"},
        sounds=sounds,
        lightAttacks={{animation="ProjectYakuza_DD_BladeLight01",nodeValue="dd_blade_light_01",duration=58/30/1.4,speed=1.4,impact=15/58,hitResponse=false,chainAt=31/58,quickstepCancelAt=16/58,damageMultiplier=1},{animation="ProjectYakuza_DD_BladeLight02",nodeValue="dd_blade_light_02",duration=48/30/1.4,speed=1.4,impact=22/48,hitResponse=false,chainAt=37/48,quickstepCancelAt=23/48,damageMultiplier=1},{animation="ProjectYakuza_DD_BladeLight03",nodeValue="dd_blade_light_03",duration=61/30/1.4,speed=1.4,impact=16/61,hitResponse=false,chainAt=32/61,quickstepCancelAt=17/61,damageMultiplier=1}},
        groundAttacks={{animation="ProjectYakuza_DD_BladeGround",nodeValue="dd_blade_ground",duration=58/30/1.4,speed=1.4,impact=13/58,hitResponse=false,groundAttack=true}},
        actions={
            finisher={enabled=true,variants={default={animation="ProjectYakuza_DD_BladeHeavy",nodeValue="dd_blade_heavy",duration=70/30/1.4,speed=1.4,impact=22/70,hitResponse=false,enabled=true,damageMultiplier=1.25}}},
            quickstep=base.actions.quickstep,
            block={enabled=true,animation="ProjectYakuza_DD_BladeGuard",staminaPerHit=.08},
        },
    })
end
