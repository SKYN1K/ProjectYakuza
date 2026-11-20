# Low-health combat feedback

Dragon of Dojima warns at 30% overall body health. The existing health-bar frame gains a gentle red pulse. At 15% or lower the pulse becomes stronger/faster. No LOW HEALTH or CRITICAL text is displayed. Healing to 35% clears the warning with a short fade; the separate recovery threshold avoids flickering around 30%. No full-screen filter, camera shake, health modification or combat advantage is applied.

During confirmed hits, guard contact, supported player-damage events or native chasing/nearby-visible zombie threats, the local player hears a quiet heartbeat. It stops after six quiet seconds. Merely swinging into empty air does not start it. The heartbeat uses the installed PZ `Character/Foley/Heartbeat` event already declared in `media/scripts/generated/sounds/player/sounds_player_foley.txt`. The mod registers its own `ProjectYakuza_LowHealthHeartbeat` sound name, rather than modifying the base `HeartBeat` sound. Sounds volume controls it; Voices and combat music remain separate. Advanced audio settings label it Low-health heartbeat.

The emitter is private, non-spatial, explicitly unregistered from world emitters and configured to send no remote events. No network command or zombie-attracting world sound is emitted. An audible vanilla heartbeat takes precedence so both cannot intentionally stack. Native panic and sound volume distinguish it from a retained muted handle. Short source events cannot repeat faster than the current warning period (850–1130 ms). Healing, pause, sleep, vehicles, death, style changes and world/save cleanup stop the owned handle. A missing audio event retries only after 30 seconds. The HUD can still warn quietly outside combat. No breathing or Kiryu voice recording is added.

## Framework configuration

Only styles that supply a valid `lowHealthFeedback` table opt in. Omit it or set false to disable the feature. Equipped weapon views inherit their owning style's configuration.

```lua
lowHealthFeedback={
    threshold=30,
    recover=35,
    critical=15,
    volume=.18,
    quietMs=6000,
    soundKey="lowHealth",
    hud=true,
    enabled=true,
},
```

These are also the defaults for an empty table. Thresholds use native overall health percentages: `0 < threshold < recover <= 100`, with `0 <= critical < threshold`. Gain is 0–1 and quiet timeout is 500–30000 ms. Boolean enabled/hud values, namespaced sound-key strings and numeric fields are validated on style registration. Unknown keys are rejected. Configure custom thresholds together when the default critical/recovery values would no longer fit.

The sound key resolves through the style's `sounds` table. Supply a registered native sound backed by existing approved assets. `soundKey=false` or `volume=0` gives silent feedback; `hud=false` suppresses the stock warning and UI pulse value. DoD's sound is a code registration referencing the existing PZ event, with no copied or converted audio file.

Client code can call `ProjectYakuza.LowHealthFeedback.sample(player)` for pulse strength 0–1, the critical flag and sampled health while a visible warning exists. A custom style UI provider receives the same strength in `context.lowHealth`. The events `lowHealthStarted(player,health)` and `lowHealthEnded(player)` report lifecycle transitions; an end also covers interruption/unequip rather than only healing. `LowHealthRules.forStyle(style)` exposes the resolved configuration and re-registration invalidates its cache.

## Runtime cost and multiplayer

Only local, living, equipped players are sampled. Health and existing native threat counters are polled at most every 250 ms. There are no zombie square scans. Healthy/disabled players allocate no audio emitter or active tick hook. The active warning uses a cached style configuration, owned sound handle and existing HUD render path; it creates no additional UI panel and does not consume mouse input. Animation and audio are pause-aware.

Each client computes its own warning from native player health. Remote players and dedicated-server Lua do not create this client effect, and no new packets or server polling are added. Existing HUD texture and all audio/motion asset files are unchanged. Native API/sound-parser checks and offline tests cover the lifecycle, privacy, recovery, volume group and rendering bounds; live audio/GPU appearance remains untested until restart.

The B42 OnPlayerGetDamage event is not player-exclusive: native weapon hits also deliver zombie victims. All low-health entry paths therefore check the IsoPlayer type and local ownership before using player methods. Zombie WEAPONHIT events are ignored; they do not poll health, allocate audio or alter warning state. Confirmed mod combatHit events still mark the actual local attacker normally.
