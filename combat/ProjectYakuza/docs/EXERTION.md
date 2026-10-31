# Attack exertion (0.60.0)

Dragon of Dojima attacks spend PZ's physical ENDURANCE stat. This feeds the normal exertion moodle and native exhaustion penalties/recovery; it does not increase sleepiness/FATIGUE. Costs occur when an attack commits, including misses. Rejected input, merely queued attacks and cancelled charge holds do not spend the attack cost.

## Default additional costs

| Attack | Endurance before fitness/traits |
| --- | ---: |
| Light, including Extreme Heat rush lights | 0.003 (0.3%) |
| Directional light | 0.004 (0.4%) |
| Quickstep attack | 0.006 (0.6%) |
| Ground attack/stomp | 0.008 (0.8%) |
| Running sidekick or knee | 0.009 (0.9%) |
| Dropkick or neutral heavy | 0.012 (1.2%) |
| First finisher, including reverse | 0.015 (1.5%) |
| Second finisher, including reverse | 0.0175 (1.75%) |
| Charged attack or Tiger Drop | 0.020 (2%) |
| Entire paired Heat Rush finish | 0.025 (2.5%) |

Multiply by the character's native getFatigueMod fitness factor and getTraitEnduranceLossModifier trait factor. At Fitness 5 with a neutral trait factor, a light adds 0.255% and a first finisher 1.275%. Each individual Extreme Heat light costs endurance; the paired finish adds one separate cost for the whole sequence, regardless of QTE successes or victims.

These are additional style costs. PZ still calculates its normal weapon swing, encumbrance and other endurance changes. The mod does not replay that native weapon calculation or change weapon EnduranceMod. Supported bats, clubs and blades inherit the style cost table, preserving their native costs as well. Attacks in other styles are unaffected unless those styles opt in. Existing guard/grab expenditure is unchanged; movement-only quicksteps and non-attack entry/taunt/activation actions do not receive an attack cost.

Payment is per committed attack stamp, never per combatHit or replicated hit result. Automatic ground routing charges the ground category once, not both light and ground. Costs are capped at available endurance and native Stats.remove retains its own clamp. Zero endurance never becomes negative. Unlimited-endurance mode, remote observers and dead players are skipped. There is no new tick hook or endurance network command; the owning client uses native player stats.

## Framework configuration

A style opts in with exertion={}; omitted categories use ProjectYakuza.Exertion.defaults. Set exertion=false or omit it to leave the extra costs disabled. Valid keys are light, directional, quickstepAttack, ground, running, dropkick, heavy, finisher, double, charged, counter and heatAction. Each value must be finite and between 0 and 0.1. A weapon profile may replace exertion with its own table or false; otherwise it inherits the base style configuration.

A move can set enduranceCost within 0..0.1 to override its category, including 0 for no additional cost. This still requires the style to opt in. It changes neither damage nor the native weapon cost.

The built-in Runtime publishes attackCommitted(player,style,move,stamp,kind) on the real native swing. Ground routing publishes it separately only when no native swing was already recorded. Tiger Drop publishes one commitment after its queued counter is accepted and effects commit; the paired action publishes one when its timed motion starts. Multi-target hits and QTE contacts do not republish it.

Custom handlers may publish attackCommitted with a unique table stamp when their own attack actually commits. Reuse the same stamp for duplicate notifications belonging to that attack. Use kind=parry for the counter category or kind=heatAction for a paired sequence; custom move types can supply enduranceCost explicitly. Do not emit it for ordinary hit feedback, observer playback or queued-but-unstarted actions.

ProjectYakuza.Exertion.cost(player,style,move,kind) resolves the configured unscaled cost/category; commit(player,style,move,stamp,kind) applies it once on the local owner. attackEnduranceSpent(player,style,move,category,amount) reports only a positive actual amount removed, after native modifiers and the available-endurance cap. The weak stamp history clears on save/menu; it does not store or reset endurance itself.
