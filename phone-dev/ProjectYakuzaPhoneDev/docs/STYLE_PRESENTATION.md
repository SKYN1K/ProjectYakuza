# Style themes and previews

The optional phone reads each registered style's full definition through ProjectYakuza.getStyle. Creators can add phoneMenu to their style definition before registration. No combat framework changes or dependency on the phone are required for the fighting style to work.

The theme applies to the selected style page: highlights, borders, header, buttons, background and text. Colours accept RGB values from 0 to 1 or a #RRGGBB string. Unspecified colours have readable defaults. Dragon of Dojima defaults to light blue with its supplied image, without preview tabs. Other styles default to neutral grey until their creators provide a theme.

Set this on the creator's existing style definition:

```lua
style.phoneMenu = {
    theme = {
        accent = "#DD3366",
        background = {0.03, 0.01, 0.02},
        text = {0.98, 0.94, 0.95}
    },
    previews = {
        {
            label = "Overview",
            image = "media/textures/MyStyle/Overview.png"
        },
        {
            label = "Rush combo",
            animation = require "MyStyle/PhonePreviews/RushCombo"
        }
    }
}
```

One preview shows without tabs. Two to eight previews show labelled buttons above the preview, arranged into rows when necessary. Click a button or press Tab/Y to change the preview. Each entry supplies either an image or an animation. Images retain their aspect ratio. The existing style.previewImage field still supplies a single image when phoneMenu.previews is absent. All runtime texture paths must be relative media/...png paths.

The only actions below the image are Assign to 1st slot and Assign to 2nd slot. Left/right chooses the slot; Enter assigns without equipping or closing. Up/down selects styles. Wheel over the right pane scrolls long descriptions; wheel over the left pane scrolls styles. Escape/B returns to the phone.

## Import an author-supplied GIF

PZ's normal texture loader does not play raw GIF files. The import tool converts an existing GIF to a native PNG frame sequence and a Lua timing descriptor. It retains the GIF's composited logical canvas, frame delays and loop count. It does not synthesize imagery. Keep the original GIF outside the runtime mod folder.

From the project workspace:

```powershell
python tools/Import-PhonePreview.py --gif "D:/MyStyle/RushCombo.gif" --mod-root "D:/MyStyle/MyStyleMod" --namespace MyStyle --name RushCombo
```

The mod root must already contain 42/mod.info. The tool writes frames to 42/media/textures/MyStyle/PhonePreviews and the descriptor to 42/media/lua/client/MyStyle/PhonePreviews/RushCombo.lua. A provenance report goes under docs. Existing different files are never overwritten. The output can be referenced with require as shown above; ship the generated PNGs and Lua descriptor in the creator's mod.

Previews support up to 120 frames, a maximum 512-pixel edge, and a 32 MiB decoded frame budget. The importer downscales only when needed for those limits. GIF delays are clamped to 10-60000 ms; zero or unspecified delays use 100 ms. A GIF without loop metadata plays once. An infinite GIF loops indefinitely; finite counts preserve their total number of plays. Raw files are limited to 20 MiB. Long previews should be shortened or optimized before importing.

Creators may also supply an existing frame sequence directly:

```lua
animation = {
    frames = {
        "media/textures/MyStyle/Frame01.png",
        "media/textures/MyStyle/Frame02.png"
    },
    durations = {80, 120},
    loops = 0
}
```

Durations are per-frame milliseconds. loops is the total number of plays, with 0 meaning infinite. Frames load through PZ's native texture cache; an unready frame keeps the last ready image rather than displaying a missing-texture placeholder. Switching styles or tabs resets that preview's clock. No GIF is bundled for Dragon of Dojima.
