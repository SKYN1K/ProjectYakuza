# 0.29.0 - Style selection combat entry

- Selecting or reselecting Dragon of Dojima plays Kiryu’s supplied Kiwami 2 fast entry, M_KRU_TLK_stand_to_btl_fast.gmt, at its original speed (50/30 seconds).
- Full-body, in-place entry locks walking, running, quicksteps and attacks until completion. Held/pressed attacks during entry are discarded. There is no invulnerability; a hit reaction interrupts entry and restores control.
- CombatStanceEntry voices now play when this entry starts. Raising RMB no longer triggers them. The separate voice pack is unchanged.
- Multiplayer starts the entry after explicit style-selection equipment acknowledgement; automatic repairs and stale acknowledgements do not replay it. Remote players receive event-free observer playback.
- Other styles can opt into actions.styleEntry with their own supplied clip. Styles without an entry remain unchanged; grabs remain disabled.

## Validation

3,122 Kahlua assertions pass across combat, input authorization, quicksteps, taunts, voice routing, selector, settings, heat, MP, namespace and entry lifecycle fixtures. All 32 production Lua files compile. PZ’s native importer accepts the 1.6667-second, 35-channel entry with 51 hand keys; 150 native observer selectors pass both playback cycles. The shipped entry retains the retargeted source motion numerically. Existing visual/audio assets remain byte-identical. No game was launched; no visual/audio asset was generated. Local installation backs up only changed files and verifies every source file against its installed bytes.
