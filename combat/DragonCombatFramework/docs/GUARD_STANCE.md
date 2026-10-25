# Stance rollback, 0.14.4

At the user's request, the v0.14.1 arm pose, slower guard blends and custom turn nodes are reverted. The original DCF_DD_CombatIdleLoop.x, two aim/aim-strafe XML nodes and combat-idle-report.json are restored byte-for-byte from v0.14.0. Native leg motion remains preserved. The four generated GuardTurn nodes are removed from source and installation. The old arm-spacing and turn-layer modifications are no longer active.

The 28 melee/stomp nodes are restored byte-for-byte from v0.14.2, before the v0.14.3 recovery-crossfade changes. Attack entry/recovery and combo transition metadata return to their original values. No attack clips, damage, heat or input logic are reverted.

stance-rollback.json records each restored file's release and SHA256, plus removed file paths. Packaging checks every hash and confirms turn overrides are absent. The installer backs up the four installed custom turn files before removing those exact files. Native lower-body/loop validation still passes.
