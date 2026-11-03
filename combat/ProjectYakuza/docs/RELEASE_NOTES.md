# Project Yakuza 0.76.0

- Repaired the supplied Yakuza 6 bat, katana, bottle and crate ready/idle/walking motion for PZ's skeleton. Source shoulder/elbow/wrist directions now fit PZ bone lengths relative to the chest, and wrist articulation follows the source forearm. The Yakuza hold clips remain selected; walking legs retain native movement.
- Corrected the katana grip attachment for the repaired poses and their run/sprint transitions. Original attack/guard motion, gait cadence and movement speed remain unchanged.
- Added the missing katana/bottle Heat Action contact voice assignments and punch sound lookup. Heat Actions explicitly load the existing feedback/voice adapters and resolve a heavy-impact fallback for missing optional cue keys.
- Heat Action feedback plays on the owner's source-animation contact in MP, with session/action/contact deduplication for server confirmations. Damage remains server authoritative. Existing world-effect routing is preserved.
- Late contact processing tolerates up to the existing server's 650 ms grace, fixing dropped presentation on delayed frames. QTE input windows remain unchanged.
- Replaced text-only QTE/Heat Action input prompts with original Yakuza 6 PC mouse icons and keyboard keycap art. Keyboard names track the actual binding and fit the frame; the shared renderer supports addon bindings and custom style UI. Original 84-pixel artwork is cropped without resizing or altered pixels.
- Busy CVF contact voices retry for at most 600 ms within the owning action, respecting provider exclusivity, volume and recording availability. Completion, cancellation, replacement and expiry discard pending speech.

Only supplied motion is repaired and existing sounds/voices are used. No generated artwork/audio, AI, upscaling or voice-pack edits. Project Zomboid was not launched. See [validation](VALIDATION_0.76.0.md). Restart PZ and install matching server/client versions.
