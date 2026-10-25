# Multiplayer synchronization 0.23.0

Install and enable DragonCombatFramework on the server and every client, with matching style add-ons and versions. The normal PZ launcher is retained. No game JAR edits, Java bridge, new visual/audio assets or physics-force extension is included.

## Transport and ownership

Owner clients send their selected style, equipped state, heat/fuel, Extreme Heat flag, current move and observer clip. Changed states are sampled at most every 100 ms; unchanged states heartbeat every second. The server binds packets to the authenticated command sender, filters registered styles/clips and finite values, and forwards them only within 60 tiles / nearby floors. Session sequence IDs reject old snapshots. Observers clear stale state after four seconds, including aura and timed-action overrides. Positions/facing for normal movement and quicksteps retain native PZ replication.

73 observer XML nodes reference the existing animation clips and retain original blend settings, playback scales and bone masks. They contain zero animation events or collision markers. Melee/stomp observers run in native attack groups; timed observers use the same PerformingAction/IsPerformingAnAction variables as BaseAction. Remote copies never run input controllers or Lua timed-action damage logic. Aura emitters now render all tracked actors; hit particles and zombie reaction variables are relayed by validated victim ID, with bounded short-lived caches for death/streaming races. Music, HUD and style-slot assignments remain local preferences; spatial combat sounds retain PZ's normal sound networking.

## Damage and paired actions

Native primary hits remain native; reporting one never calls Hit again on the server. Supplemental victims share a three-target per-swing cap and deduplicate targets, with distance/facing/swept collision checks. Server item data supplies their base damage and native Hit calculations. Extra hits have their own server result packets; observers apply absolute results without calling Hit or Kill. This avoids multiplying damage by the number of clients. Supplemental damage can differ from the native primary roll because it uses server weapon data, not a client-supplied damage value.

G requests a server grab lease before starting. Only one player may claim a zombie. Server pairing follows the replicated player facing/position through collision checks and sends walking phase/direction updates. Throw damage is issued once against that lease. Release, death, missing heartbeat, disconnect, collision failure and an eight-second ceiling restore captured zombie AI/movement settings. Server claims include late-observer restoration information. Client paired root/animation alignment retains the existing native-leg presentation.

Tiger Drop still uses the local animation's final 0.2-second input window. The server independently checks attack target/state, range, target count and a 60-second cooldown. Exact 200 ms agreement across latency is not guaranteed; timing is not a server rewind system. Its existing Lua-only hit force is retained, without additional ragdoll physics APIs. Guard cancellation is checked against the player's block clip and nearby attacker. Extreme Heat activation gets a bounded server ghost/invincible lease, restores the previous flags afterward, and tells nearby zombie-owning clients to suppress queued attacks. Heat and move timing are still owner-driven; this is not a complete anti-cheat or server-side heat simulation.

## Audio settings

Options → Mods → Dragon Combat Framework → Audio has Combat music volume and Combat hit volume (0–200%; zero mutes). They apply to registered style playlists and punch/kick/heat/finisher/throw/guard impact groups and persist through PZAPI.ModOptions. Orb-gain and activation effects retain independent Advanced Audio user levels. The punch -15% and orb +30% clip gains are unchanged. No third-party Mod Options dependency is required in this installed B42 build.

## Style authors

Registered styles retain independent music/heat/effect profiles. For custom observer animation support, provide `DragonCombat.NetworkCatalog[styleId]` as a priority-sorted array of entries `{id, animation, group, conditions={{name,value}}, priority, loop}` and corresponding observer XML nodes. Group is melee, stomp or actions. Observer conditions are DCFRemoteObserver=true and DCFRemoteClip=entry.id; strip every event and preserve the original clip and bone mask. Supply entries through shared Lua so the server can validate IDs. Conditions in the catalogue describe the owner's original animation node, not the observer node. The included build_mp_visuals.py is a developer example for extracting this metadata from the current style's XML; do not reuse Kiryu clips for unrelated styles implicitly.

## Validation and practical limits

Offline checks exercise sender binding, malformed/stale packets, duplicate native/extra hits, target caps, walls/range, grab contention, throw deduplication, leases/disconnect restoration, counter cooldowns, protected activation timeouts, observer cleanup, throttling and command/result flow. The native B42 animation parser selects all observer nodes only for their matching remote clip; none contain events. Existing single-player and selector regressions also pass.

No game or dedicated server was launched. Real two-client validation is still required for network-owned zombie death/corpse behavior, walking/throw alignment, native action transitions and high latency. No PvP combat synchronization, split-screen interface overhaul, client rollback or segmented music synchronization was added.
