# Style-owned encounter intros (0.54.0)

Dragon of Dojima now shows a brief Yakuza 6-inspired on-screen encounter title. This is a HUD animation, not a character animation: it does not move/lock the player, disable attacks, pause the world, change cameras or grant protection. Its full-viewport panel explicitly disables mouse events and is removed when finished.

The supplied Edo SZ HQ font is directly rasterized into a glyph atlas at 128 pixels, then drawn at or below its raster resolution. Source outlines, advances and kerning are preserved. No AI or invented glyphs. The original Yakuza 6 btl_flush texture provides the moving flare; its RGBA pixels and dimensions are unchanged. Entrance, settle, sweep and fade timing are recreated in Lua, rather than imported as a Dragon Engine UI animation. No global PZ font is replaced. See encounter-intro-assets.json for user authorization, glyph metrics and provenance.

## Requested titles

Live, loaded zombies on the player's floor are counted within a 12-tile circular radius, including the exact boundary. Dead zombies, other floors and farther zombies are excluded. The centre is captured when the encounter begins.

| Nearby zombies | Edo SZ title |
| --- | --- |
| 0Ã¢â‚¬â€œ10 | A bunch of brain eaters |
| 11Ã¢â‚¬â€œ39 | Zombies |
| 40+ | The Horde |

The count selects the title once by visiting nearby grid squares, ordered near to far, rather than traversing the loaded zombie list. Each tick visits at most 256 squares and reads at most 192 moving objects, filtering only live zombies in the captured circular radius/floor. It stops at 40 for DoD. Ordinary 12-tile fixtures complete in at most three ticks; larger addon radii or dense non-zombie objects can take longer. The capped count is a lower bound. Dynamic moving-object lists can affect membership during the short count; actors are deduplicated. No zombie count runs throughout the encounter or idle state.

Native player threat counters are checked at most once per 400 ms while the style is equipped. Chasing zombies, or visible very-close zombies, start an encounter; a confirmed damaging combat hit also starts one. Continued threats/hits keep it active. After 12 quiet seconds a new encounter may trigger another intro. This is a local threat heuristic, not a global PZ battle state or a timer-based zombie wave detector. Remote players do not broadcast screen overlays: each local player uses their own equipped style, viewport and nearby crowd.

The animation lasts 2.3 seconds. It freezes during pause and cleans up on style disable/change, provider removal, death, vehicle entry, save or exit. The temporary tick hook exists only while counting or displaying an intro. The separate style-selection character entry is restored for supported armed equipment; it does not trigger this title.

## Register a custom style intro

Styles opt in independently. There is no default intro on styles that omit encounterIntro. Dragon of Dojima does not donate its font, title rules or effects to other styles. Register a renderer with ProjectYakuza.registerStyleUI and name it in style.ui.encounter. The same create/update/render/destroy lifecycle and blend restoration used by other UI channels applies.

```lua
ProjectYakuza.registerStyleUI("MyStyle.encounter", {
    create=function(c,s)
        s.image=c.texture("media/textures/MyStyle/SuppliedIntro.png")
    end,
    render=function(c,s)
        c.panel:drawTextureScaled(s.image,40,40,400,100,1,1,1,1)
        return true
    end,
    destroy=function(c,s)
        s.image=nil
    end,
})
```

Add these fields to your own registered style definition:

```lua
ui={encounter="MyStyle.encounter"},
encounterIntro={
    enabled=true,
    radius=12,
    durationMs=2300,
    quietMs=12000,
    pollMs=400,
    titles={
        {max=10,text="Small group"},
        {max=39,text="Group"},
        {text="Horde"},
    },
},
```

Each maximum is inclusive and strictly increasing; only the final entry omits max. The final entry is required. Bounds: radius 1Ã¢â‚¬â€œ30, duration 100Ã¢â‚¬â€œ10,000 ms, quiet interval 1,000Ã¢â‚¬â€œ120,000 ms, poll interval 100Ã¢â‚¬â€œ5,000 ms. Disabled/false configurations do not run detection. A provider must be registered before detection can begin. Set ui.encounter=false or omit the config to keep a style silent.

A renderer receives normal StyleUI context plus c.extra.title, count, capped, radius, elapsed, duration, reason and style. Time values in extra are seconds. count is capped when the highest title tier is established. Use capped to avoid displaying that lower bound as an exact total. The supplied renderer uses original flare/explosion/shock textures and Edo glyphs; your provider may use entirely different supplied textures, native text and animation logic. No style or builtin provider is inherited automatically.

Optional soundKey refers to a key in that style's sounds table; soundVolume accepts 0Ã¢â‚¬â€œ2. Playback uses existing Feedback and the mod Sounds volume grouping. DoD has no new intro sound. Only provide existing registered sound assets; no voices or audio files are generated by this feature.

## Helpers and lifecycle events

ProjectYakuza.EncounterIntro.request(player,reason) requests the style's intro/count and returns ok/reason. It refuses unavailable, paused or already-active encounters. clear(player,reason) cancels/reset that player's encounter; omitting player clears all. title(config,count) resolves the configured inclusive tier. These are client presentation helpers, not combat damage or network APIs.

Events: encounterIntroStarted(player,style,context) fires after counting when a panel is created; encounterIntroEnded(player,style,context,reason) fires when that panel closes; encounterEnded(player,style,reason) fires after quiet time or explicit cleanup. They use the existing ProjectYakuza.on/off event bus. Use provider.destroy or encounterEnded to release resources on cancellation as well as completion.

layoutText(fontData,text) and drawText(panel,fontData,layout,texture,x,y,scale,alpha,r,g,b) provide bitmap glyph measurement/drawing with advances, offsets and kerning. The bundled atlas includes printable ASCII only, covering the requested titles; the simple helper reads byte codes with a question-mark fallback. Other languages can use a custom provider/font renderer without changing the encounter system. Fonts, extra images and sound assets must be supplied by the style author.

No game was launched. Live appearance and multiplayer threat-counter behavior require user assessment after restarting matching installations; see VALIDATION_0.72.0.md for offline checks.

## Landing presentation (0.53.0)

The title flies into the screen centre over 0.30 seconds. A brief cool filter and dark edge bands frame the landing; the intro graphics jitter by at most five horizontal/three vertical pixels for 0.26 seconds. The world camera and aiming coordinates stay fixed. One source explosion animates behind the title at up to 520px, replacing the three staggered draws, with the original radial shock texture fading outward. See encounter-impact-assets.json for unchanged DDS-to-PNG pixels, grid and hashes. No new art was drawn.

Timing and screen treatment are recreated in Lua using the user description and publicly indexed gameplay references, rather than importing or claiming a frame-perfect Dragon Engine UI scene: [Yakuza 6 gameplay](https://www.jeuxvideo.com/videos/812597/yakuza-6-the-song-of-life-kazuma-kiryu-face-aux-triades.htm) and [Dynamic intro reference](https://www.youtube.com/watch?v=KM8Xqx7oa0A). Reference videos were located, not decoded for frame-by-frame comparison. Live appearance needs assessment in PZ after restarting.

## Style-owned triggers and sizing (0.54.0)

A style must explicitly supply both encounterIntro.enabled=true and ui.encounter naming its renderer. There is no automatic DoD intro on another style. Existing styles without triggers retain threat/hit behavior; an explicit triggers table enables only its true entries. All enabled triggers and the custom detector are OR conditions. minZombies is a separate gate applied after counting to every request, including manual requests.

| Field | Meaning |
| --- | --- |
| minZombies | Minimum live nearby zombie count required to show the intro; integer 0–1000, default 0 |
| countZombies | Default true; false skips the grid count entirely and supplies count=0; requires minZombies=0 |
| triggers.threat | Native zombie threat counters |
| triggers.hit | Confirmed damaging hit on a zombie |
| triggers.playerHit | Confirmed native weapon hit on another player, or an equivalent combatHit event |
| triggers.visiblePlayer | Local player has another living player in range, facing cone and line of sight |
| triggers.seenByPlayer | Another living player has the local player in its facing cone/line of sight |
| playerRadius | Player detection distance 1–100 tiles; defaults to radius |
| playerFov | Facing cone in degrees, 1–360; default 140 |
| detector | Optional namespaced registered custom detector ID |
| rejectRetryMs | Retry backoff after an insufficient count, 100–30000ms, default 1500; never shorter than pollMs |
| textScale | Stock renderer's preferred source-font scale, 0.1–1, default 1 |
| textWidth | Stock renderer's maximum viewport width fraction, 0.1–1, default 0.88 |

The stock title uses a larger default scale than before and shrinks automatically for longer text or small viewports. Its landing pulse is clamped to the source font's native raster resolution and viewport bounds. This changes draw geometry only; no font/image asset is generated or upscaled.

Player detection checks at most 16 online candidates per poll, resuming its cursor next time, plus up to four local split-screen slots. A still-visible target is checked first without rescanning the list. CanSee supplies native geometric line of sight; the framework adds range, floor and facing-cone checks. These are client-side presentation conditions, not server-authoritative PvP, team/enemy classification, lighting or screen-pixel visibility. Remote facing/perception is limited by replicated state. For hostility or a different definition of visibility, disable those built-ins and use your own bounded detector.

Example fields for a style that reacts to a visible player without counting zombies:

```lua
ui={encounter="myaddon.rivalIntro"},
encounterIntro={
    enabled=true,
    countZombies=false,
    triggers={visiblePlayer=true,playerHit=true},
    playerRadius=18,
    playerFov=140,
    pollMs=400,
    quietMs=12000,
    durationMs=2300,
    textScale=1,
    textWidth=.88,
    titles={{text="A rival appears"}},
},
```

A zombie-focused style can instead set minZombies=8, radius=12, triggers={threat=true,hit=true} and its own ordered titles. Rejected counts do not latch an encounter or display a panel; automatic retries respect the rejection backoff. Once an encounter starts, configured detection/hits refresh it until quietMs elapses. DoD keeps its existing zombie-only defaults and title thresholds.

## Custom detection and effects

ProjectYakuza.registerEncounterDetector(id,fn) installs a namespaced function. It receives player, the selected style/equipment view, and a context containing inEncounter, lastThreat and target. Return true and an optional target object to trigger/refresh the encounter. Returning false/nil means no detection. The callback runs only for styles explicitly naming its ID, at their pollMs interval. Keep your own work bounded. A missing detector causes no fallback. A failing function is quarantined for that state and emits encounterDetectorFailed(player,style,id,error) once; registering a replacement function or clearing the state allows recovery.

```lua
ProjectYakuza.registerEncounterDetector("myaddon.special",function(player,style,context)
    local data=player:getModData()
    return data.MyAddonEncounterReady==true
end)
```

Set encounterIntro.detector="myaddon.special" and triggers={} for detector-only operation. The author controls when the condition becomes false so the encounter can rearm after quietMs. unregisterEncounterDetector(id,fn) removes a matching function, or omit fn to remove the current registration.

ProjectYakuza.EncounterIntro.request(player,reason,target) now accepts an optional target reference. Intro context and renderer c.extra expose target, reason, title, count, capped and config. A custom renderer can use that target's name, style-specific supplied textures/sounds, timing and any effects supported by its create/update/render/destroy lifecycle. The existing encounterIntroStarted/Ended events remain available for scoped world effects; release their resources on completion and cancellation. Custom provider code may ignore the stock text-size fields and implement its own layout. The bundled Edo atlas supports printable ASCII; another font/language needs supplied assets or a custom native-font renderer.

encounterRejected(player,style,count,minimum,reason) reports an insufficient count without starting an intro. Detectors and presentation are local only; this update adds no network packets, combat damage, protection, music changes or generated assets.

A minimal animated custom renderer, using a texture supplied by the addon author and PZ's existing font:

```lua
ProjectYakuza.registerStyleUI("myaddon.rivalIntro",{
    create=function(c,s)
        s.image=c.texture("media/textures/MyAddon/ExistingIntro.png")
    end,
    render=function(c,s)
        local t=c.extra.elapsed
        local fade=math.min(1,t/.2,math.max(0,(c.extra.duration-t)/.3))
        local size=128+64*math.min(1,t/.3)
        if s.image then
            c.panel:drawTextureScaled(s.image,(c.viewport.width-size)/2,
                c.viewport.height*.4-size/2,size,size,fade,1,1,1)
        end
        c.panel:drawTextCentre(c.extra.title,c.viewport.width/2,
            c.viewport.height*.5,1,1,1,fade,UIFont.Large)
        return true
    end,
    destroy=function(c,s)
        s.image=nil
    end,
})
```

The texture path is an example dependency supplied by that addon; the framework does not create it. Use a provider-specific font/layout for other typography, and c.extra.target for an optional encountered character. For stock Y6 visuals with only different rules/text, explicitly choose ui.encounter="ProjectYakuza.y6Encounter" instead.
