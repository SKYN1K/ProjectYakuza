# Combat voice-pack entries

Merge the `lines` array from lines.json into your existing CVF source manifest.json, preserving packId, voices and all other fields. Use the definitions exactly (including cooldown, label and wheel=false) so multiple packs register the same reserved entries consistently.

Place supplied recordings inside each voice's existing audio folder, using `DragonCombatFramework.CombatLightAttack_01.ogg`, `DragonCombatFramework.CombatHeavyAttack_01.ogg`, and the same pattern for each ID. .wav and additional _02/_03 takes are supported by CVF's own builder. Run that framework's tools/New-VoicePack.ps1 against your pack source folder. No recordings are included here; missing events remain silent. Do not point these slots at placeholder or unrelated recordings.

The namespace is DragonCombatFramework. All eight IDs begin Combat. Leave wheel false: these lines are owned by the combat integration, not the generic voice wheel or automatic vanilla pools. A voice-only combat taunt is available through Combat styles when its recording exists.
