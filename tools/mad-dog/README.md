# Mad Dog build and offline checks

All extraction, previews, compiled classes, game libraries and fixtures belong outside Git. Runtime output lives in `styles/ProjectYakuzaMadDog`; framework changes are limited to the optional style `weaponSprite` field and its client/server equipment preparation.

Tools used for this export:

- Blender 3.6.23.
- [Fronkln/yakuza-gmt-blender](https://github.com/Fronkln/yakuza-gmt-blender) at `5266985a0b9e8a7307f4e3641c917b51ee9311a5`, including recursive submodules (`gmt_lib` at `ccb43850f60314812ec7298b8a0e8b4203ea9256`).
- [yk_gmd_io](https://github.com/theturboturnip/yk_gmd_io) at `32016a1441d263e7af63140fb667f4cf9e5d7ae4`.
- [Yakuza-PAR-py](https://github.com/SutandoTsukai181/Yakuza-PAR-py) for extraction.
- A Java 17+ JDK and the installed PZ 42.21 JAR/native libraries. Nothing here starts the game.

Use your own absolute paths in the examples below; `SCRATCH` must be outside the repository. `PZ` is the game directory containing `projectzomboid.jar`, `stdlib.lua` and the native importer library (on macOS, the app's `Contents/Java` directory).

```sh
python3 tools/mad-dog/extract_sources.py --game "$YAKUZA0" --par-tool "$PAR_TOOL" --output "$SCRATCH/source"

"$BLENDER" --background --threads 2 --python tools/mad-dog/convert_motions.py -- \
  --source "$SCRATCH/source" --gmd "$SCRATCH/source/c_cm_majima_origin.gmd" \
  --gmt-importer "$GMT_IMPORTER" --pz-media "$PZ/media" \
  --output styles/ProjectYakuzaMadDog/42/media/anims_X/Bob --samples "$SCRATCH/poses"

python3 tools/mad-dog/build_nodes.py
python3 tools/mad-dog/validate_assets.py
python3 tools/mad-dog/build_tests.py "$SCRATCH/mad-dog-tests.lua"
python3 tools/combat-tests/build_mp_tests.py
python3 tools/combat-tests/build_style_entry_tests.py
python3 tools/combat-tests/build_extension_api_tests.py
cp "$PZ/stdlib.lua" "$SCRATCH/stdlib.lua"
cp tools/combat-tests/mp-tests.lua tools/combat-tests/style-entry-tests.lua \
  tools/combat-tests/extension-api-tests.lua tools/combat-tests/addon-starter-tests.lua "$SCRATCH/"
javac --release 17 -cp "$PZ/projectzomboid.jar" -d "$SCRATCH" \
  tools/mad-dog/MadDogProbe.java tools/mad-dog/MadDogRigProbe.java tools/mad-dog/CompileLua.java tools/combat-tests/LuaRunner.java
```

Run the native check from the repository root:

```sh
java -Djava.library.path="$PZ" -cp "$SCRATCH:$PZ/projectzomboid.jar" \
  MadDogProbe styles/ProjectYakuzaMadDog combat/ProjectYakuza
```

Run Lua checks from `SCRATCH` so Kahlua finds the original game's `stdlib.lua`:

```sh
java -cp ".:$PZ/projectzomboid.jar" LuaRunner \
  mad-dog-tests.lua mad-dog-entry-tests.lua mp-tests.lua style-entry-tests.lua \
  extension-api-tests.lua addon-starter-tests.lua
java -cp ".:$PZ/projectzomboid.jar" CompileLua \
  "$REPO/combat/ProjectYakuza/42/media/lua" "$REPO/styles/ProjectYakuzaMadDog/42/media/lua"
```

Use `;` instead of `:` in Java classpaths on Windows. PZ may print missing GUID-table messages in the offline native selector harness; any parser/selection failure still fails the process. Never run the release publisher for this PR: it must remain unmerged while the other changes are pending.


## Direction and actual Human-rig regression

The importer now uses GMT/GMD FK directly and the true target skin bind. The GMD
Blender UI importer is no longer required. A Z reflection changes handedness while
retaining anatomical left/right; rotating the character 180 degrees would swap sides.

Run from the repository root (use the platform's importer library filename):

```sh
for BODY in MaleBody FemaleBody; do
  java -cp "$SCRATCH:$PZ/projectzomboid.jar" \
    zombie.core.skinnedmodel.model.jassimp.MadDogRigProbe \
    "$PZ/libjassimp.dylib" "$PZ/media/models_X/Skinned/$BODY.x" \
    styles/ProjectYakuzaMadDog/42/media/anims_X/Bob "$SCRATCH/runtime/$BODY"
done
"$BLENDER" --background --threads 2 --python tools/mad-dog/check_directions.py -- \
  --gmt-importer "$GMT_IMPORTER" --gmd "$SCRATCH/source/c_cm_majima_origin.gmd" \
  --sources "$SCRATCH/source" --runtime "$SCRATCH/runtime" --pz-media "$PZ/media" \
  --report "$SCRATCH/direction-validation.json"
```

This checks every source frame against engine-computed limb directions without
using exporter reference poses. The old installed clips were run as a negative
control and failed all body/clip pairs; 0.1.1 passes 28,824 segment comparisons.


Optional independent source-reader audit, using the pinned GMD Blender importer:

```sh
"$BLENDER" --background --threads 2 --python tools/mad-dog/check_source_reader.py -- \
  --sources "$SCRATCH/source" --gmd "$SCRATCH/source/c_cm_majima_origin.gmd" \
  --gmt-importer "$GMT_IMPORTER" --gmd-importer "$GMD_IMPORTER"
```

The audit sets linear source key interpolation explicitly and removes only actor
planar travel when comparing; the actual source limb motion and root heights must
agree with GMTImporter to 0.0001 source units.
