# Original scene contracts

The reference import pipeline reads original CMN character-motion bindings, victim damage, sound starts, voice labels and blood attachments. Retargeted actor/victim clips, paired paths, resource payment and presentation each retain explicit ownership. A scene's sound or particle start is not automatically its damage contact.

## Retained v1 scenes

| Scene | Original victim damage frames at 30 fps | Current main-clip contact frames |
| --- | --- | --- |
| Knife | 40.0, 90.0 | 40, 90 |
| Extreme Heat rush | 56.0, 68.0, 78.0, 90.0, 102.0, 114.0, 144.0 | 41, 53, 59, 71, 78, 90, 98, 110, 116, 128, 135, 147, 175 |
| Wall | 12.0, 48.0 | 12, 48 |
| Ground trample | No damage nodes | 30 |
| Katana | 24.0, 44.0, 64.0 | 24, 44, 64 |
| Bat | 14.0, 50.0 | 14, 50 |
| Open-space grab | 78.0 | 78 |

The Extreme Heat rush uses the shortened lead-in and bounded two-hit source sections. Its damage, limb windows, sound/voice events and blood anchors use the same current source-frame map. Main playback retains 1x speed; failure uses its separate original ending. The ground scene has no original damage/blood nodes, so the reference implementation uses its verified frame-30 sole/head contact and one existing impact effect.

Katana's original three contacts remain at frames 24/44/64; its middle punch tracks the left arm. Knife contacts remain at 40/90, with the second contact tracking the right kick. Weapon sounds and blood events follow their own authored source starts rather than being collapsed onto these contacts.

## Extending the framework

A new paired action needs explicit actor/victim assignments, native clips/nodes, a path registration, canonical contacts and server validation. Keep original sound/voice/effect starts separate when the source supplies them. Bind particles to sampled victim points and select striking limbs per contact; a weapon-equipped scene can contain kicks or off-hand punches.

The built-in extraction scripts demonstrate specific CMN10/CMN18 sources and are not universal scene converters. New source formats, native skeletons or cinematic controllers require their own importer/adaptation. The runtime cannot play raw scene binaries.

[heat-scenes.json](heat-scenes.json) records the full development import, including custom-object scenes excluded from v1. [heat-scene-effects.json](heat-scene-effects.json) records original attachment transforms. [Presentation](HEAT_ACTION_PRESENTATION.md), [Damage](HEAT_ACTION_DAMAGE.md) and [Heat Actions](HEAT_ACTIONS.md) define the runtime contracts.
