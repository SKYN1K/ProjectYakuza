[CmdletBinding()]
param(
    [string]$Version = '0.1.5',
    [string]$Repo = 'SKYN1K/ProjectYakuza',
    [string]$GhPath = 'gh',
    [string]$PythonPath = 'python',
    [string]$GamePath = 'F:/SteamLibrary/steamapps/common/ProjectZomboid',
    [switch]$SkipLocalInstall
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$tag = 'phone-dev-v' + $Version
Push-Location $root
try {
    & $GhPath release view $tag --repo $Repo *> $null
    if ($LASTEXITCODE -eq 0) { throw 'This phone dev tag is already published. Choose a new version.' }
    & $PythonPath tools/combat-tests/check_source_comments.py
    if ($LASTEXITCODE -ne 0) { throw 'Source comment validation failed.' }
    & $PythonPath tools/combat-tests/validate_phone_dev.py
    if ($LASTEXITCODE -ne 0) { throw 'Phone native asset/projection validation failed.' }
    & $PythonPath tools/combat-tests/build_phone_dev_tests.py
    if ($LASTEXITCODE -ne 0) { throw 'Phone interaction fixture failed to build.' }
    Push-Location tools/combat-tests
    try {
        & (Join-Path $GamePath 'jre64/bin/java.exe') -Xms16m -Xmx384m -XX:ActiveProcessorCount=2 -cp ".;$GamePath/*" LuaRunner phone-dev-tests.lua
        if ($LASTEXITCODE -ne 0) { throw 'Phone interaction checks failed.' }
        & (Join-Path $GamePath 'jre64/bin/java.exe') -Xms16m -Xmx384m -XX:ActiveProcessorCount=2 -cp ".;$GamePath/*" CompileCombatLua '../../phone-dev/ProjectYakuzaPhoneDev/42/media/lua'
        if ($LASTEXITCODE -ne 0) { throw 'Phone Lua compilation failed.' }
    } finally { Pop-Location }
    & git diff --quiet -- combat/ProjectYakuza
    if ($LASTEXITCODE -ne 0) { throw 'The phone dev release must preserve the current combat source.' }
    $build = @('tools/Build-PhoneDev.py', '--version', $Version)
    if (-not $SkipLocalInstall) { $build += '--install' }
    & $PythonPath @build
    if ($LASTEXITCODE -ne 0) { throw 'Phone runtime package or installation failed.' }
    & git add -A -- .gitignore phone-dev/ProjectYakuzaPhoneDev tools/Build-PhoneDev.py tools/Import-PhonePreview.py tools/Publish-PhoneDevRelease.ps1 tools/combat-tests/build_phone_dev_assets.py tools/combat-tests/build_phone_font.py tools/combat-tests/build_phone_presentation_assets.py tools/combat-tests/build_phone_material.py tools/combat-tests/phone-material-runtime.lua tools/combat-tests/phone_source_assets.py tools/combat-tests/validate_phone_dev.py tools/combat-tests/PhoneDevNativeProbe.java tools/combat-tests/build_phone_dev_tests.py tools/combat-tests/phone-dev-test-fixture.lua tools/combat-tests/AttackEffectProbe.java
    if ($LASTEXITCODE -ne 0) { throw 'Phone git staging failed.' }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Phone staged whitespace validation failed.' }
    & git diff --cached --quiet
    if ($LASTEXITCODE -eq 1) {
        & git commit -m ('Phone dev v' + $Version)
        if ($LASTEXITCODE -ne 0) { throw 'Phone commit failed.' }
    } elseif ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged phone changes.' }
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) { throw 'Phone push failed.' }
    $revision = (& git rev-parse HEAD).Trim()
    $archive = Join-Path $root ('dist/ProjectYakuzaPhoneDev-B42-v' + $Version + '.zip')
    & $GhPath release create $tag $archive --repo $Repo --target $revision --title ('Phone dev ' + $Version) --prerelease --latest=false --notes-file phone-dev/ProjectYakuzaPhoneDev/docs/RELEASE_NOTES.md
    if ($LASTEXITCODE -ne 0) { throw 'Phone prerelease creation failed; pushed source and ZIP are preserved.' }
    & $GhPath release view $tag --repo $Repo --json url,tagName,isPrerelease,assets
    if ($LASTEXITCODE -ne 0) { throw 'Phone prerelease verification failed.' }
} finally { Pop-Location }
