> Historical implementation note: controls and APIs may be superseded. Use the [current manual](INDEX.md) and [API reference](API_REFERENCE.md) for addon development.

# Attack recovery restored, 0.14.4

The v0.14.3 recovery-crossfade changes are reverted at the user's request. All 28 melee/native-stomp XML nodes match the v0.14.2 archive byte-for-byte. Longer default fades and custom guard/chain transition entries from v0.14.3 are removed. See stance-rollback.json for hashes. Hit markers, animation clips, damage and Lua combat logic remain unchanged.
