# Aura fade-in

Every new character-aura appearance fades from transparent to full opacity over 350 ms, using smoothstep easing. At 175 ms it is at half opacity. The fade pauses with the game and does not restart when heat eligibility is polled or heat increases while the aura remains active. Disabling and re-enabling the aura starts a fresh fade.

Opacity is applied through native IsoSpriteInstance.SetAlpha and SetTargetAlpha so character target-alpha copying cannot override it. Native opacity setters are called only when the fade value changes. The existing render hook, sprite pooling and cleanup remain; no idle update hook is added. Textures, size, color, anchors, animation timing and the HUD are unchanged.

Validation: 862 native Kahlua assertions, including fade timing, pause, repeated heat updates, reappearance, cached opacity and existing combat/effects behavior. Native Build 42 sprite methods also pass a direct opacity-control probe. Live visual timing still needs an in-game check.
