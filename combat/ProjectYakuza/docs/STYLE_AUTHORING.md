# Create a fighting-style addon

A style is a shared definition plus native animation nodes and optional client/server code. A move is a configured animation within it. An action kind is the controller/lifecycle for a class of moves. A table entry alone does not implement input, collision, playback or network authority.

## 1. Activate the starter

Copy `templates/StyleSubmod` to your own mod folder; keep common/. Rename mod.info.example and its two Lua/two XML examples to their runtime extensions. Leave the music script inactive until recordings exist. Change example IDs consistently before publishing.

The starter has a damaging light using an existing PZ punch and a separate **non-damaging flourish** using the same existing clip. The custom flourish starts unbound: assign it in Mods settings. It demonstrates lifecycle/input/observer integration, not another damaging strike. No new media is supplied or generated.

Shared registration is `ExampleStyle_Style.lua`; the client explicitly requires it. Shared definitions also load on the server. Native timed actions/UI belong under client/.

## 2. Register a style

```lua
require "ProjectYakuza/Registry"
local PY=ProjectYakuza
assert(PY.API_VERSION>=2,"My addon requires API 2")
PY.registerStyle({
    id="my_mod.my_style", name="My Style",
    attackSpeed=1, comboResetMs=500, lightBufferLimit=1,
    lightAttacks={
        {animation="Bob_AttackPunch01_Hit",nodeValue="my_mod_light_01",
         duration=1,impact=.25,chainAt=.65,damageMultiplier=1},
    },
    actions={},heat=false,music=false,sounds=false,
})
```

Copy the starter melee XML and match its style ID, move nodeValue, markers and clip. Duration must match actual playback speed. GMT files must be retargeted/imported first; the framework cannot play raw GMT.

Registered styles appear automatically in the inventory menu and assignment list; they do not inherit DoD assets or automatically occupy a slot. `selectStyle` selects; client `equipStyle` also provisions the recognized token and requests an opted-in entry.

## 3. Opt into features

| Feature | Configuration | Additional work |
| --- | --- | --- |
| Lights | lightAttacks array | Matching native melee nodes/collision markers |
| Ground strikes | groundAttacks array | Floor-target melee/stomp nodes |
| Finishers/doubles | actions.finisher.variants | after_N/double_after_N and pose-link markers |
| Dashes/dash strikes | quickstep/quickstepAttack | Four directional variants and native marker protocol |
| Running strikes | runningAttack | left/right/knee/dropkick, travel and recovery nodes |
| Walking guard | block | Enter/hold/hit/exit nodes and native-leg mask |
| Tiger Drop | tigerDrop=true and parry | Existing counter timing/target/animation protocol |
| Taunt | taunt | Start/end markers; heat for reward |
| Selection entry | styleEntry | Full-body entry markers; vulnerable movement/attack lock |
| Extreme Heat | heat=true and heatActivation variants | Activation markers/clips and protection cleanup |
| New move type | Namespaced kind + scoped handler | Lifecycle, input, native playback and server logic as needed |
| Audio/visuals | Explicit style profiles | Supplied assets and scoped presentation hooks |
| MP playback | Registered catalog + observers | Same addon on server and clients |

Built-in controllers retain their established conventions; arbitrary clips may need a different handler. Grabs are globally disabled even if an addon enables its slot. heatAction has no bundled cinematic implementation. See [API](API_REFERENCE.md), [Actions](ACTIONS.md) and [Animations](ANIMATIONS.md).

## 4. Add a new move type

Register its kind in shared code before the style, then register its scoped handler/controls in client code. Custom kinds consume normal framework combat routing while active and deny native attacks by default. Optional update(context) uses the existing local-player update path. The style input callback can still handle release/cancellation. Use the starter flourish rather than changing DoD or replacing every style's handler.

## 5. Build MP presentation and distribute

```text
python ProjectYakuza/tools/build_style_observers.py --mod-root MyStyleAddon --style-id my_mod.my_style --prefix MyStyle_ --dry-run
python ProjectYakuza/tools/build_style_observers.py --mod-root MyStyleAddon --style-id my_mod.my_style --prefix MyStyle_
```

The prefix must match owner XML names and the shared `MyStyle_Style.lua` module. The builder writes XML/Lua code only. It registers presentation, not custom damage/physics. Follow [Multiplayer](MULTIPLAYER.md) and [Testing](TESTING.md). Package only your addon with `require=ProjectYakuza`; do not bundle a second framework or the separate voice pack.

## Custom presentation and charged heavies (API 3)

Declare `ui={heat="my_mod.heat",selectorSlot="my_mod.slot"}` in the shared definition and register the renderers from client code. Omit any channel to keep its default. See the full [UI contract and example](STYLE_UI.md). UI cannot award heat or cause attack collisions.

For a native charged heavy, opt into both `actions.heavyCharge` and `actions.chargedHeavy`, supply native action/melee nodes and register observer entries. See [charged heavy contracts](CHARGED_HEAVY.md). These are built-in action kinds with dedicated controllers; custom move types still use the normal action-kind extension API.
