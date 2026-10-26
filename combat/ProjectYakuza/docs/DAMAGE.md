> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Damage multipliers, 0.12.2

Dragon of Dojima light attacks 1-4: damageMultiplier=0.75. First and double finishers: damageMultiplier=1.25. Other attacks keep the default 1.0. The underlying weapon script range remains 0.35-0.65 so unmodified moves retain their previous balance. The new normal ranges are 0.2625-0.4875 for lights and 0.4375-0.8125 for finishers, before native combat modifiers.

Heat.onSwing applies the style move's factor after handling Extreme Heat fuel, using native weapon minimum and maximum damage. It first restores any previous move factor. Extreme Heat keeps its 1.5 multiplier, so the relative factors compose multiplicatively. Heat ending during an attack reapplies the current non-heat move factor rather than losing it. Runtime floor routing resets the move factor to the stomp's default.

OnPlayerAttackFinished, reset and action cancellation restore the exact pre-move weapon values through a retained item reference, including unequip cases. Persistent original values are unwound before saved Extreme Heat originals on reload. No post-hit extra damage, second hit or target scan was added.

The 571 Kahlua checks include all four light moves, all eight first/double finishers, repeated-swing non-compounding, normal restoration, running/ground isolation, heat composition and depletion during an active swing, interruption and saved-modifier restoration. Animation assets and input timings are unchanged.
