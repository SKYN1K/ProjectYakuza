[CmdletBinding()]
param(
    [string]$Version,
    [string]$Repo = 'SKYN1K/ProjectYakuza',
    [string]$GhPath = 'gh',
    [string]$PythonPath = 'python'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$mod = Join-Path $root 'emotes/ProjectYakuzaEmotes'
$sourceVersion = (Get-Content -LiteralPath (Join-Path $mod '42/mod.info') | Where-Object { $_ -match '^version=' }).Substring(8).Trim()
if (-not $Version) { $Version = $sourceVersion }
if ($Version -ne $sourceVersion -or $Version -notmatch '^\d+\.\d+\.\d+$') { throw 'Release version must match standalone mod.info.' }
$tag = 'emotes-v' + $Version
$notes = Join-Path $mod 'docs/RELEASE_NOTES.md'
if (-not (Test-Path -LiteralPath $notes)) { throw 'Standalone release notes are required.' }
Push-Location $root
try {
    $references = & $GhPath api ("repos/$Repo/git/matching-refs/tags/$tag") --jq length
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify unused standalone tag.' }
    if ($references -ne '0') { throw "Tag $tag already exists. Published versions are not overwritten." }
    & $PythonPath (Join-Path $root 'tools/combat-tests/validate_emote_split.py')
    if ($LASTEXITCODE -ne 0) { throw 'Standalone split validation failed.' }
    & $PythonPath (Join-Path $root 'tools/combat-tests/check_source_comments.py')
    if ($LASTEXITCODE -ne 0) { throw 'Source-comment validation failed.' }
    $dist = Join-Path $root 'dist'
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    $archive = Join-Path $dist ('ProjectYakuzaEmotes-B42-v' + $Version + '.zip')
    $temporaryArchive = Join-Path $dist ('emotes-' + [guid]::NewGuid().ToString() + '.zip')
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($mod, $temporaryArchive, [IO.Compression.CompressionLevel]::Optimal, $true)
    Move-Item -LiteralPath $temporaryArchive -Destination $archive -Force
    & git add -A -- .gitignore .gitattributes README.md AGENTS.md emotes tools/Publish-EmoteRelease.ps1 tools/combat-tests/validate_emote_split.py tools/combat-tests/build_emote_tests.py tools/combat-tests/emote-test-fixture.lua tools/combat-tests/emote-menu-test-fixture.lua tools/combat-tests/README.md tools/combat-tests/MajimaEmoteProbe.java tools/combat-tests/StepUpMotionProbe.java tools/combat-tests/build_majima_bat_emote.py tools/combat-tests/validate_majima_bat_emote.py tools/combat-tests/extract_majima_bat_emote.py tools/combat-tests/build_lau_spear_emote.py tools/combat-tests/validate_lau_spear_emote.py tools/combat-tests/extract_lau_spear_emote.py tools/combat-tests/build_kiryu_bad_luck_emote.py tools/combat-tests/validate_kiryu_bad_luck_emote.py tools/combat-tests/extract_kiryu_bad_luck_emote.py tools/combat-tests/extract_kiryu_step_up_emote.py tools/combat-tests/build_kiryu_step_up_emote.py tools/combat-tests/validate_kiryu_step_up_emote.py
    if ($LASTEXITCODE -ne 0) { throw 'Standalone git add failed.' }
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        & git commit -m ("Release " + $tag)
        if ($LASTEXITCODE -ne 0) { throw 'Standalone git commit failed.' }
    } elseif ($LASTEXITCODE -ne 0) { throw 'Cannot inspect standalone staged changes.' }
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw 'Standalone git push failed.' }
    $revision = (& git rev-parse HEAD).Trim()
    & $GhPath release create $tag $archive --repo $Repo --target $revision --title ("Project Yakuza Emotes " + $Version) --notes-file $notes --latest=false
    if ($LASTEXITCODE -ne 0) { throw 'Standalone release creation failed; pushed commit and ZIP are preserved.' }
    & $GhPath release view $tag --repo $Repo --json url,tagName,assets
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify published standalone release.' }
} finally { Pop-Location }
