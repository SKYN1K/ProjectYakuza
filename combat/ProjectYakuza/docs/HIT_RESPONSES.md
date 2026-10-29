# Move-specific hit responses — 0.40.0

Dragon of Dojima now separates standing-target responses:

| Move | Response | Native hit force |
| --- | --- | ---: |
| Lights 1–4 | Existing supplied Y6 enemy flinch clips | .25 |
| First finishers | PZ backward stagger | .65 |
| Double finishers | PZ stagger/fall knockdown | .85 |
| Partial charged heavy/finisher | PZ backward stagger | .75 |
| Full charged heavy/finisher | PZ knockdown | 1.0 |

Full charge means chargePower >= .999 (rounding tolerance). Actual position displacement, direction-specific stagger/fall animation, ragdoll behavior and recovery are controlled by the installed PZ engine/settings. This is not a ragdoll-force bridge. Existing native deaths and downed/floor states take priority; the mod never stands a victim back up. Ground attacks, running/quickstep attacks, Tiger Drop, damage, heat and attack timing retain their existing behavior.

## Authoring

Styles opt in with an optional profile table. Styles without it retain their existing reactions and do not inherit DoD's profiles.

```lua
hitResponses = {
    light = {kind="flinch", force=.25},
    finisher = {kind="stagger", force=.65},
    doubleFinisher = {kind="knockdown", force=.85},
    chargedHeavy = {
        kind="stagger", force=.75,
        fullChargeAt=.999, fullChargeKind="knockdown", fullChargeForce=1,
    },
    customKick = {kind="stagger", force=.7},
},
```

Default lookup precedence is chargedHeavy, doubleFinisher, finisher (afterLight), then a matching light attack. A move can set hitResponse="customKick" to select a profile, or hitResponse=false to opt out. Ground attacks are always excluded. Valid kinds are flinch/stagger/knockdown; force is finite 0..1.5. Full-charge fields must be supplied together with threshold 0..1. Style registration validates these fields. Flinch presentation uses the move's existing reaction clip and the style's enemyReactions setting; no new animation name is invented.

ProjectYakuza.HitResponses.resolve(style,move) returns a fresh {kind,force} table or nil. The charged move's chargePower must be the captured release fraction. apply(attacker,zombie,response) applies direction/force and native stagger/fall flags to a live, standing target; it never calls Hit/Kill, changes health, moves XY, scans for targets or forces a state transition. Addons should normally use the standard hit pipeline instead of calling apply themselves.

## Native timing and ownership

Native OnWeaponHitCharacter is emitted before final damage and force calculation. The local response controller captures the move and stages SP flags until the next tick; it requires health loss before applying. Same-swing duplicate events are ignored. Native Hit remains responsible for damage. The response tick hook is removed when no victims/jobs remain.

In MP, the existing validated impact command locks the move and charge power per swing. Primary responses are applied on the next server tick (up to the existing 100ms tick interval), then returned in the existing impact packet. Supplemental victims receive one native server Hit followed by the same response policy. Optional responseKind/responseForce fields in impact/damage packets reach the attacker and observers; clients mirror native flags, never add damage. The owner's impact visual is not duplicated. Existing per-swing target caps, ranges, walls, duplicate IDs and observer health synchronization remain in force. The server primary-response queue is capped at 128 entries; overflow retains hit feedback without applying a new forced response. Pending unloaded/stale jobs expire.

MP remains the existing client-owned native primary-hit architecture: this feature is not a claim of server verification of the complete attack animation/hold duration. All peers should run the same mod release.

## Assets and limits

No asset was added or altered. The four Y6 flinch clips retain their original provenance in enemy-reaction-conversion-report.json. Heavier responses use existing PZ staggerback and staggerback-knockeddown transitions/clips. Native public setters and transition conditions were inspected offline; final motion and live multiplayer appearance require gameplay testing. No game/client/server was launched.
