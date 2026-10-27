# Per-style UI — Lua API 3

Style addons can replace any framework presentation surface without editing the framework. Assets must already exist: the API does not synthesize artwork, upscale it or turn an arbitrary profile name into a renderer. Existing styles need no changes.

## Shared definition

Add `ui` to your normal `registerStyle` definition:

```lua
ui={
    heat="my_mod.heat",
    status="my_mod.status",
    selectorSlot="my_mod.slot",
    -- selector="my_mod.wheel", setup="my_mod.assignments",
}
```

Each key accepts a client provider ID or `false`. Omit a channel to retain its built-in renderer; false hides its drawing. A missing provider also falls back, so a disabled presentation addon does not disable combat. IDs/configuration are shared; callbacks, textures and UI objects belong in client code. Register before play, with unique namespaced IDs.

| Channel | Host and scope |
| --- | --- |
| heat | Heat panel; invoked even for styles without built-in heatHud, so the addon can supply its own meter/layout |
| status | Bottom combat status/feedback text; active style owns its drawing |
| selector | Whole wheel's drawing, selected from the currently equipped style |
| selectorSlot | Each assigned slot's drawing, selected from that slot's style; receives its position, alpha and selection state |
| setup | Assignment panel's drawing; its existing combo boxes/buttons remain children unless the provider explicitly manages them |

The wheel's top remains reserved and bottom opens assignments. Rendering hooks do not change slot policy or combat inputs. Custom selector graphics must keep those actions understandable. Setup callbacks receive `extra.left` and `extra.right` native combo boxes, plus `extra.message`. Slot callbacks receive `extra.side/x/y/alpha/selected/style`; wheel callbacks receive `extra.side`.

## Client provider example

```lua
require "ProjectYakuza/StyleUI"
local PY=ProjectYakuza
assert(PY.API_VERSION>=3,"This HUD needs Project Yakuza API 3")
PY.registerStyleUI("my_mod.heat",{
    create=function(c,s)
        -- Supply this PNG in your addon. Missing assets must not be generated.
        s.texture=c.texture("media/textures/MyMod/SuppliedHeatAtlas.png")
    end,
    update=function(c,s)
        s.phase=c.time -- seconds; frozen while the game is paused
    end,
    render=function(c,s)
        if not s.texture then return false end -- default HUD fallback
        -- Example atlas crop: use the actual supplied atlas's rectangle.
        local fraction=math.max(0,math.min(1,c.heat/100))
        if fraction>0 then
            c.panel:drawSubTexture(s.texture,0,0,64*fraction,16,
                20,20,64*fraction,16,.8,1,1,1)
        end
        return true -- this channel was fully drawn
    end,
    destroy=function(c,s)
        -- Remove any children/listeners/native resources you created here.
        s.texture=nil
    end,
})
```

The crop values above are code examples, not an included/generated asset. Atlas frame selection, orb/bar counts, colors, opacity, layout, animation timing, labels, icons and tooltips can all be implemented in these callbacks using supplied textures/native ISUI methods. Use `create` to size/position the host or add your own controls when needed; restore any host/input properties you change in `destroy`. Framework panels remain mouse-passive by default. Do not take over the mouse for decorative effects.

## Callback/data contract

All callbacks take `(context,state)`. `state` is a private table per host/channel/slot/provider/player/style. `create` runs once before the first update/render; `update` and `render` run each draw. `destroy` releases resources on provider/style replacement, unregistration, panel closure/hiding, save and menu exit. `render` must return exactly true to suppress the built-in renderer; false/nil allows fallback (or an intentional overlay under the default UI).

Context contains `player`, `style`, native `panel`, `channel`, `extra`, `heat` (0–100, mode fuel during Extreme Heat), `stocks`, `maxStocks`, `extreme`, `action`, `combo`, `viewport={x,y,width,height}`, `dt` (seconds, clamped to .25), `time` (provider active seconds) and `paused`. `texture(path)` caches existing texture handles; `binding(actionId)` reads the configured label. Treat gameplay tables as read-only. Current core HUD/selector hosts serve the first keyboard/mouse local player; viewport data does not add split-screen/gamepad support by itself.

Use `dt/time`, not wall-clock time, for paused HUD animation. Avoid disk reads, texture loads, zombie scans or new event handlers per frame. Draw with panel texture/atlas helpers or existing native text methods; this API does not add shaders. Custom world effects use their own world renderer, not these UI hooks.

Errors are caught once per session, logged and quarantined; built-in rendering resumes. The renderer's additive flag is restored, including failed cleanup. Providers remain responsible for balancing their own stencil/clip state, removing created children/listeners and releasing other native resources. Re-registering with a new provider table resets the session on the next draw. `PY.unregisterStyleUI(id)` immediately destroys matching sessions and restores fallback. No callbacks/state are serialized or sent across MP; clients render from synchronized combat/heat state.
