# Project Yakuza 0.63.0

- Optimized MP state authorization with cached style/weapon animation support and action-kind indexes, invalidated by official registration. Server snapshots reuse their validated equipment-view move.
- Reworked path traversal to avoid repeatedly reading the same tiles while retaining the same wall/diagonal checks. Zombie-ID searches inspect nearby tiles first, with the existing full search limit and no persistent target cache.
- Replaced concatenated client state signatures with typed comparisons, including ground changes. Unchanged inactive clients send three-second heartbeats; active combat and changed/forced updates retain their existing timing.
- Reduced unchanged protection-hook scans, idle deferred-queue allocation and repeated sender-coordinate reads. Replay batches skip entries removed during lifecycle cleanup.
- Removed unused internal attached-sprite search/removal helpers and stale barrage documentation. Preserved disabled grabs, retained assets, future-style hooks, gameplay tuning, weapon poses and the separate voice pack. Made the no-code-comments rule explicit in AGENTS.md.

Offline operation-count, authority and regression checks pass. No game/FPS or live MP benchmark was run; PZ stayed closed. No graphical/audio/animation assets or native selector definitions changed. See PERFORMANCE.md and VALIDATION_0.63.0.md. Restart with matching server/client installations.
