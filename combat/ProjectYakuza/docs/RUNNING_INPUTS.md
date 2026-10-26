> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Running refinements, 0.11.2

LMB is randomized equally among left side kick, right side kick and jumping knee on each accepted click; no screen/world key decides the variant. MMB selects dropkick for every running direction. Actual displacement supplies facing and continues to guard against walking or wall-running.

Only the jumping knee slows from 1.6x to 1.2x (full duration 1.0417s -> 1.3889s). Heat applies its normal multiplier. Side kicks and dropkick keep their former speeds.

LMB attacks support movement recovery at 78% for the side kicks and 80% for the knee, gated by the current hit marker. Held rebound movement keys count. Without movement input the clip plays fully. Dropkick retains full recovery even if a stale recovery marker is present. Native damage remains a single collision per attack.

Validation includes random-roll coverage independent of each movement key, cardinal-direction dropkicks, current-hit/late-marker/movement requirements, duplicate-exit prevention, full dropkick recovery, native mask expansion excluding both leg chains, and normal/Extreme speed validation.
