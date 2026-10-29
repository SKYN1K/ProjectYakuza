# Validation — 0.40.0

No PZ client/server was launched. Live reaction timing, native displacement/fall presentation and multiplayer behavior remain unverified.

Fourteen Kahlua fixtures pass 4,014 assertions: framework 2,647; charge/UI 181; quickstep 71; MP/reactions 149; extension 42; starter 9; heat/shove 23; heat audio 35; entry 21; taunt 198; CVF 63; selector 50; settings 94; limb effects 431. All 40 production Lua files compile.

Forty-five new checks cover default light/finisher/double/partial/full-charge policies, nonfinite values, profile validation, addon isolation, explicit profile and opt-out, deferred native-event application, blocked/no-health-loss hits, dead/floor targets, no Hit/Kill/teleport, duplicate same-swing events, pause/resume, expiration and idle-hook cleanup. Actual client/server handlers exercise captured partial charge despite later full-power snapshots, primary and extra victims, server-resolved packet fields, owner response without duplicate VFX, invalid-force rejection, duplicate packet suppression and observer absolute-health knockdown without another Hit.

Native MPObserverProbe reflects IsoZombie.setStaggerBack, setKnockedDown, setFallOnFront, setHitForce, getHitDir and setHitReaction. The installed B42 bytecode shows OnWeaponHitCharacter before final native Hit processing. Read-only inspection of zombie/hitreaction and walktoward action transitions confirms bStaggerBack/bKnockedDown select native stagger/fall states; runtime code does not force changeState or write position. This proves API/transition availability, not live motion quality.

Full native/source validation retains observer parsing/selection, punch FK, detached sprite contracts, 226 aura/copy PNG decodes, 325 native effect paths, original source charge timing/poses, flame/smoke/HUD pixel provenance and exact approved taunt colour mapping. All 551 existing animation/image/audio files are unchanged from v0.39.0; no assets were added.

The scoped installer preflights against v0.39.0 and backs up only modified installed files, then verifies complete installed bytes. Publication uses a unique v0.40.0 ZIP/release; source/install/ZIP bytes and the remote asset digest are compared afterward.
