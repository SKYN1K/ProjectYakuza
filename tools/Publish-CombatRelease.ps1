[CmdletBinding()]
param(
    [string]$Version,
    [string]$Repo = 'SKYN1K/ProjectYakuza',
    [string]$GhPath = 'gh'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$mod = Join-Path $root 'combat/ProjectYakuza'
$versionLine = Get-Content -LiteralPath (Join-Path $mod '42/mod.info') | Where-Object { $_ -match '^version=' }
$installedVersion = $versionLine.Substring(8).Trim()
if (-not $Version) { $Version = $installedVersion }
if ($Version -ne $installedVersion -or $Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Release version must match mod.info.' }
$notes = Join-Path $mod 'docs/RELEASE_NOTES.md'
if (-not (Test-Path -LiteralPath $notes)) { throw 'Release notes are required.' }
$tag = 'v' + $Version
Push-Location $root
try {
    & $GhPath release view $tag --repo $Repo *> $null
    if ($LASTEXITCODE -eq 0) { throw "Release $tag already exists. Use a new version; published tags are not overwritten." }
    $dist = Join-Path $root 'dist'
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    $archive = Join-Path $dist ('ProjectYakuza-B42-v' + $Version + '.zip')

    $temporaryArchive = Join-Path $dist ('release-' + [guid]::NewGuid().ToString() + '.zip')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($mod, $temporaryArchive, [IO.Compression.CompressionLevel]::Optimal, $true)
    Move-Item -LiteralPath $temporaryArchive -Destination $archive -Force
    & git add -A -- .gitignore .gitattributes README.md AGENTS.md combat tools/Publish-CombatRelease.ps1 tools/build_mp_visuals.py tools/combat-tests/build_mp_tests.py tools/combat-tests/mp-test-fixture.lua tools/combat-tests/build_style_entry_tests.py tools/combat-tests/style-entry-test-fixture.lua tools/combat-tests/build_extension_api_tests.py tools/combat-tests/extension-api-test-fixture.lua tools/combat-tests/test_style_observer_builder.py tools/combat-tests/build_taunt_tests.py tools/combat-tests/taunt-test-fixture.lua tools/combat-tests/NativeAuraTextureProbe.java tools/combat-tests/validate_extreme_assets.py tools/combat-tests/build_heat_audio_tests.py tools/combat-tests/heat-audio-test-fixture.lua tools/combat-tests/build_heat_shove_tests.py tools/combat-tests/heat-shove-test-fixture.lua tools/combat-tests/build_quickstep_once_tests.py tools/combat-tests/quickstep-once-test-fixture.lua tools/combat-tests/validate_mp_nodes.py tools/combat-tests/MPObserverProbe.java tools/combat-tests/LuaRunner.java tools/combat-tests/README.md tools/combat-tests/build_charged_ui_tests.py tools/combat-tests/charged-ui-test-fixture.lua tools/combat-tests/ChargeAssetProbe.java tools/combat-tests/OutlineProbe.java tools/combat-tests/validate_finisher_reference_assets.py tools/combat-tests/validate_effect_loader_paths.py tools/combat-tests/validate_charge_source_timing.py tools/combat-tests/PunchTrackProbe.java tools/combat-tests/DetachedEffectProbe.java tools/combat-tests/ChargeTrackProbe.java tools/combat-tests/validate_charge_limb_tracks.py tools/combat-tests/build_weapon_tests.py tools/combat-tests/weapon-test-fixture.lua tools/combat-tests/build_weapon_mp_tests.py tools/combat-tests/weapon-mp-test-fixture.lua tools/combat-tests/WeaponAssetProbe.java tools/combat-tests/validate_weapon_assets.py tools/combat-tests/fixture_markers.py tools/combat-tests/check_source_comments.py tools/combat-tests/test_source_comments.py tools/combat-tests/build_punch_effects_tests.py tools/combat-tests/punch-effects-test-fixture.lua tools/combat-tests/build_style_item_tests.py tools/combat-tests/style-item-test-fixture.lua tools/combat-tests/build_style_selector_tests.py tools/combat-tests/style-selector-test-fixture.lua tools/combat-tests/PropAttachmentProbe.java tools/combat-tests/StyleItemProbe.java tools/combat-tests/validate_prop_attachments.py tools/combat-tests/build_blood_tests.py tools/combat-tests/blood-test-fixture.lua tools/combat-tests/validate_blood_assets.py tools/combat-tests/BloodAssetProbe.java tools/combat-tests/build_extreme_attack_tests.py tools/combat-tests/extreme-attack-test-fixture.lua tools/combat-tests/validate_extreme_attacks.py tools/combat-tests/ExtremeAttackProbe.java
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        & git commit -m ("Release " + $tag)
        if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
    } elseif ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged changes.' }
    & git branch -M main
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw 'git push failed.' }
    $revision = (& git rev-parse HEAD).Trim()
    & $GhPath release create $tag $archive --repo $Repo --target $revision --title $tag --notes-file $notes
    if ($LASTEXITCODE -ne 0) { throw 'GitHub release creation failed; the pushed commit and ZIP are preserved.' }
    & $GhPath release view $tag --repo $Repo --json url,tagName,assets
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify published release.' }
} finally { Pop-Location }
