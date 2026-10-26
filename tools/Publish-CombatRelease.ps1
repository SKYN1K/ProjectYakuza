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
    # Build a fresh artifact without deleting any source/install folder.
    $temporaryArchive = Join-Path $dist ('release-' + [guid]::NewGuid().ToString() + '.zip')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($mod, $temporaryArchive, [IO.Compression.CompressionLevel]::Optimal, $true)
    Move-Item -LiteralPath $temporaryArchive -Destination $archive -Force
    & git add -A -- .gitignore .gitattributes README.md AGENTS.md combat tools/Publish-CombatRelease.ps1 tools/build_mp_visuals.py tools/combat-tests/build_mp_tests.py tools/combat-tests/mp-test-fixture.lua tools/combat-tests/build_style_entry_tests.py tools/combat-tests/style-entry-test-fixture.lua tools/combat-tests/build_extension_api_tests.py tools/combat-tests/extension-api-test-fixture.lua tools/combat-tests/test_style_observer_builder.py tools/combat-tests/build_taunt_tests.py tools/combat-tests/taunt-test-fixture.lua tools/combat-tests/validate_mp_nodes.py tools/combat-tests/MPObserverProbe.java tools/combat-tests/LuaRunner.java tools/combat-tests/README.md
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
