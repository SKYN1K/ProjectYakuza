# 0.27.1 - Multiplayer equipment, quicksteps and hit reactions

- Fix the rejected native AttackCollisionCheckPacket / PlayerHitZombie packets whose weapon field resolved to null in the co-op log. Multiplayer equip now issues/reuses the style token on the server, synchronizes its inventory ID and hands through B42's native packets, and waits for client inventory delivery plus an acknowledgement before allowing combat. Saved client-only tokens trigger the same repair path on reconnect. Single-player equip retains its normal local path.
- Relay quickstep position/facing every 50 ms and always relay the terminal sample. Interpolate observers without changing the owning client's position. Enforce registered move distance, wall/floor path, finite coordinates, sequence order, a bounded lifetime and the three-per-15-seconds quota on the server. The exposed IsoPlayer.setIgnoreMovement method also requests a native reliable position update during these scripted steps.
- Replace the server's 50 ms state-discard gate with a bounded per-second budget. New swing and timed-action serials restart repeated observer animations through alternating XML nodes referencing the existing supplied clips. Both serials changing together still restart the clip.
- Enter the native zombie hit-reaction state when replaying a validated custom reaction, include the native repeat-hit group, and retry streamed-out victims for up to 750 ms. Observers do not call Hit or Kill to replay an effect, and native primary damage is never applied a second time.
- Network protocol is now v2. Restart the server and all clients with the same 0.27.1 files. No motion, image or audio data changed.

## Validation

3,083 offline Kahlua assertions passed across nine suites, including 91 multiplayer checks using the production client/server/protocol/reaction modules. Added cases cover separate server/client inventories, delayed native item arrival, stale equip replies, same-tick state changes, repeated actions, simultaneous action/swing serials, wall/distance/quota checks, reordered and missing step samples, zombie streaming retries, and exposed native position-update calls. All 31 production Lua files compile with PZ's bundled Kahlua compiler. PZ's native animation parser/selector accepts 148 event-free player observer nodes; their clip names, speeds, blends and bone masks match the originals. Four repeat-hit nodes reference the same supplied zombie clips. B42 Weapon, EquipPacket, Lua globals and IsoPlayer methods were inspected directly from the installed game JAR to verify inventory-ID lookup, server-only inventory/equip send functions and Lua API availability. No game was launched. Two-client visual/timing verification remains outstanding.

# 0.27.0 - Controls, taunt particles and audio

- Rebuild the completed-taunt flash with five short-lived upper-body wisps/sparks taken directly from Kiwami 2. Original texture dimensions and pixels; blue tint and movement supplied at render time. No generated artwork or audio. Burst duration: 260 ms.
- Support the CombatExtremeHeatActivation CVF entry on actual activation start. Retry transient provider busy/cooldown for up to 1.5 seconds while the same activation remains active; discard cancelled activation voices. Existing supplied Kiryu boost_on recordings remain usable.
- Fill the Dragon of Dojima selector circle with an original Kiwami crop at 1:1 pixel size; no upscaling.
- Limit quicksteps to three actual starts within a rolling 15-second window, persisted per character. Blocked or rejected requests do not consume a step.
- Remove Shift quicksteps. Space is the default quickstep key; all thirteen combat action inputs can be changed in Options > Mods > Dragon Combat Framework, with mouse-button or keyboard choices.
- Audio sliders are Music, Sounds and Voices. Sounds controls this mod's SFX; Voices controls only CVF combat lines requested by this mod, preserving normal voice settings and style voice mix.
- Preserve the current Kiwami 2 taunt, relaxed combat idle, damage, heat rules, music playlist and existing multiplayer synchronization.

## Default controls

Aim/movement/run use native PZ controls. While aiming: LMB light attack, MMB finisher or Tiger Drop; X block, G grab/release, MMB throw while grabbing, Q taunt, N Extreme Heat. Space quickstep; LMB during quickstep attacks. Running LMB attack, running MMB dropkick. Hold Z to select styles. Each action has its own binding in Mods settings; Shift remains native run input.

## Validation

3,046 Lua assertions passed across combat lifecycle, native attack authorization, bindings/rolling quota, taunt particles, actual CVF playback, native ModOptions persistence, style selection and MP protocol. The old broad movement fixture isolates movement from quota; the new quota fixture checks the actual three/15-second limit independently. All Lua sources compile in the bundled PZ compiler. Original particle PNGs decode pixel-identically to their source DDS files. No live game was launched; subjective appearance and two-client input/latency still need an in-game check.
