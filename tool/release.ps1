<#
.SYNOPSIS
  Bumps the OneSpend version, adds its What's new entry, builds for Google Play, commits and tags.

.DESCRIPTION
  pubspec.yaml is the one place the version lives:

      version: MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE

  The name (before +) is what users see. CODE (after +) is the Android versionCode;
  every run of this script (except -Debug) raises it by one, so each upload is accepted.

  Run it from a clean working tree, only when you are about to upload to Play Console.
  Day-to-day development stays `flutter run`.

.EXAMPLE
  ./tool/release.ps1 -Bump minor -Pre beta   # 1.0.0         -> 1.1.0-beta.1   (start a feature version in beta)
.EXAMPLE
  ./tool/release.ps1 -Pre beta               # 1.1.0-beta.1  -> 1.1.0-beta.2   (next beta; alpha.N -> beta.1)
.EXAMPLE
  ./tool/release.ps1 -Promote                # 1.1.0-beta.2  -> 1.1.0          (the real release)
.EXAMPLE
  ./tool/release.ps1 -Bump patch             # 1.1.0         -> 1.1.1          (bug-fix release)
.EXAMPLE
  ./tool/release.ps1 -Rebuild                # same name, new build number      (re-upload)
.EXAMPLE
  ./tool/release.ps1 -Debug                  # debug APK of the current version; changes nothing
#>
param(
  [ValidateSet('major', 'minor', 'patch')]
  [string]$Bump,
  [ValidateSet('alpha', 'beta')]
  [string]$Pre,
  [switch]$Promote,
  [switch]$Rebuild,
  [switch]$Debug,
  [ValidateSet('appbundle', 'apk')]
  [string]$Target,
  # Don't pause for release notes (they must already be written).
  [switch]$Yes,
  # Bump, commit and tag without building (for trying the script out).
  [switch]$SkipBuild,
  [switch]$Help
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$pubspecPath = 'pubspec.yaml'
$changelogPath = 'lib/core/config/changelog.dart'
$utf8 = New-Object System.Text.UTF8Encoding $false

function Show-Usage {
  Write-Host @'

OneSpend release  -  version lives in pubspec.yaml as MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE

  ./tool/release.ps1 -Bump minor -Pre beta   start a new feature version as beta.1
  ./tool/release.ps1 -Bump major|minor|patch new release (add -Pre alpha|beta for a pre-release)
  ./tool/release.ps1 -Pre beta               next beta of the same version (or alpha -> beta)
  ./tool/release.ps1 -Promote                turn the alpha/beta into the real release
  ./tool/release.ps1 -Rebuild                same version, new build number (re-upload)
  ./tool/release.ps1 -Debug [-Target apk]    debug build of the current version (no bump)

  Extra: -Yes (don't pause for release notes), -SkipBuild (bump/commit/tag only)

  MAJOR = big redesigns or breaking changes, MINOR = new features, PATCH = fixes only.
  alpha -> Play "Internal/Closed testing", beta -> "Open testing", no suffix -> "Production".
'@
}

function Fail([string]$message) {
  Write-Host "`n$message" -ForegroundColor Red
  exit 1
}

function Read-Version {
  $line = (Get-Content $pubspecPath | Where-Object { $_ -match '^version:' } | Select-Object -First 1)
  if ($line -notmatch '^version:\s*(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta)\.(\d+))?\+(\d+)\s*$') {
    Fail "pubspec.yaml has '$line', expected version: MAJOR.MINOR.PATCH[-alpha.N|-beta.N]+CODE"
  }
  $preNumber = 0
  if ($Matches[5]) { $preNumber = [int]$Matches[5] }
  return [pscustomobject]@{
    Major = [int]$Matches[1]; Minor = [int]$Matches[2]; Patch = [int]$Matches[3]
    Pre = $Matches[4]; PreNumber = $preNumber; Code = [int]$Matches[6]
  }
}

function Get-Name($v) {
  $name = "$($v.Major).$($v.Minor).$($v.Patch)"
  if ($v.Pre) { $name = "$name-$($v.Pre).$($v.PreNumber)" }
  return $name
}

function Invoke-Checked([string]$what, [scriptblock]$command) {
  & $command
  if ($LASTEXITCODE -ne 0) { Fail "$what failed (exit $LASTEXITCODE)." }
}

if ($Help) { Show-Usage; exit 0 }

$current = Read-Version
$sha = (git rev-parse --short HEAD).Trim()

# --- Debug build: nothing changes -------------------------------------------------
if ($Debug) {
  if (-not $Target) { $Target = 'apk' }
  if (git status --porcelain) { $sha = "$sha-dirty" }
  Write-Host "Debug $Target of $(Get-Name $current)+$($current.Code) from $sha"
  Invoke-Checked 'flutter build' { flutter build $Target --debug "--dart-define=GIT_SHA=$sha" }
  exit 0
}

# --- Work out the next version ----------------------------------------------------
$modes = @($Bump, $Promote, $Rebuild) | Where-Object { $_ }
if ($modes.Count -eq 0 -and $Pre) { $modes = @('pre') }
if ($modes.Count -ne 1 -or ($Pre -and ($Promote -or $Rebuild))) { Show-Usage; exit 1 }

$next = $current.PSObject.Copy()
$next.Code = $current.Code + 1

if ($Bump) {
  switch ($Bump) {
    'major' { $next.Major++; $next.Minor = 0; $next.Patch = 0 }
    'minor' { $next.Minor++; $next.Patch = 0 }
    'patch' { $next.Patch++ }
  }
  $next.Pre = $null; $next.PreNumber = 0
  if ($Pre) { $next.Pre = $Pre; $next.PreNumber = 1 }
}
elseif ($Promote) {
  if (-not $current.Pre) { Fail "$(Get-Name $current) is already a release. Use -Bump to start the next version." }
  $next.Pre = $null; $next.PreNumber = 0
}
elseif ($Pre) {
  if (-not $current.Pre) { Fail "$(Get-Name $current) is a release. Start the next one with -Bump patch|minor|major -Pre $Pre." }
  if ($current.Pre -eq $Pre) { $next.PreNumber++ }
  elseif ($current.Pre -eq 'alpha' -and $Pre -eq 'beta') { $next.Pre = 'beta'; $next.PreNumber = 1 }
  else { Fail "Can't go from beta back to alpha. Use -Pre beta or -Promote." }
}
# -Rebuild keeps the name.

$oldName = Get-Name $current
$newName = Get-Name $next
$newVersion = "$newName+$($next.Code)"

# --- Safety checks ----------------------------------------------------------------
if (git status --porcelain) { Fail 'Commit or stash your changes first; a release is built from a clean tree.' }
$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'main') { Write-Host "Note: releasing from '$branch', not main." -ForegroundColor Yellow }
if (git tag --list "v$newName") {
  if (-not $Rebuild) { Fail "Tag v$newName already exists." }
}
if (-not $SkipBuild -and -not (Test-Path 'android/key.properties')) {
  Write-Host 'Warning: android/key.properties is missing, so this build is signed with the DEBUG key.' -ForegroundColor Yellow
  Write-Host '         Google Play will reject it. See README "Releasing" to set up your upload key.' -ForegroundColor Yellow
}

Write-Host "`n$oldName+$($current.Code)  ->  $newVersion`n" -ForegroundColor Cyan

# --- pubspec.yaml -----------------------------------------------------------------
$pubspec = [System.IO.File]::ReadAllText((Resolve-Path $pubspecPath), $utf8)
$pubspec = [regex]::Replace($pubspec, '(?m)^version:.*?(\r?)$', "version: $newVersion`$1")
[System.IO.File]::WriteAllText((Resolve-Path $pubspecPath), $pubspec, $utf8)

# --- What's new -------------------------------------------------------------------
$month = (Get-Date).ToString('MMM yyyy', [Globalization.CultureInfo]::InvariantCulture)
$changelog = [System.IO.File]::ReadAllText((Resolve-Path $changelogPath), $utf8)
$nl = "`n"
if ($changelog.Contains("`r`n")) { $nl = "`r`n" }
$entryPattern = "version: '" + [regex]::Escape($newName) + "',(\s*)date: '[^']*'"
if ([regex]::IsMatch($changelog, $entryPattern)) {
  # The entry exists (e.g. written while "In development"): stamp this month.
  $changelog = [regex]::Replace($changelog, $entryPattern, "version: '$newName',`$1date: '$month'")
}
else {
  $entry = "    ChangelogEntry($nl      version: '$newName',$nl      date: '$month',$nl      changes: [$nl        'TODO: what changed',$nl      ],$nl    ),$nl"
  $marker = 'static const List<ChangelogEntry> entries = ['
  $at = $changelog.IndexOf($marker)
  if ($at -lt 0) { Fail "Couldn't find the entries list in $changelogPath." }
  $insertAt = $changelog.IndexOf($nl, $at) + $nl.Length
  $changelog = $changelog.Insert($insertAt, $entry)
}
[System.IO.File]::WriteAllText((Resolve-Path $changelogPath), $changelog, $utf8)

function Restore-Files {
  git checkout -- $pubspecPath $changelogPath | Out-Null
}

if ((Get-Content $changelogPath -Raw).Contains("'TODO: what changed'")) {
  if ($Yes) { Restore-Files; Fail "Release notes for $newName are still TODO. Write them in $changelogPath first." }
  Write-Host "Write the release notes for $newName in $changelogPath (replace the TODO line)," -ForegroundColor Yellow
  Read-Host 'then save the file and press Enter'
  if ((Get-Content $changelogPath -Raw).Contains("'TODO: what changed'")) {
    Restore-Files
    Fail 'The release notes are still TODO, so nothing was changed. Run the script again when ready.'
  }
}

# The version tests check pubspec and What's new agree.
Invoke-Checked 'Version check' { flutter test test/features/app_version_test.dart --reporter compact }

# --- Commit, build, tag -----------------------------------------------------------
git add $pubspecPath $changelogPath
Invoke-Checked 'git commit' { git commit -q -m "chore(release): $newName ($($next.Code))" }
$sha = (git rev-parse --short HEAD).Trim()

if (-not $SkipBuild) {
  if (-not $Target) { $Target = 'appbundle' }
  # One universal APK, so its versionCode matches the bundle's (split APKs add 1000 * ABI).
  $buildArgs = @($Target, '--release', "--dart-define=GIT_SHA=$sha")
  Write-Host "`nBuilding $Target for $newVersion ($sha)..."
  flutter build @buildArgs
  if ($LASTEXITCODE -ne 0) {
    git reset -q --soft HEAD~1
    Fail 'The build failed. The release commit was undone; your version changes are still staged.'
  }
}

if (-not (git tag --list "v$newName")) { git tag -a "v$newName" -m "OneSpend $newName" }

# --- Next steps -------------------------------------------------------------------
$track = 'Production'
if ($next.Pre -eq 'beta') { $track = 'Open testing' }
if ($next.Pre -eq 'alpha') { $track = 'Internal or Closed testing' }
Write-Host "`nDone: OneSpend $newName (build $($next.Code))" -ForegroundColor Green
if (-not $SkipBuild) {
  if ($Target -eq 'appbundle') { Write-Host '  1. Upload build/app/outputs/bundle/release/app-release.aab' }
  else { Write-Host '  1. APKs are in build/app/outputs/flutter-apk/' }
  Write-Host "     to Play Console > $track."
}
Write-Host '  2. Push the release commit and tag:  git push --follow-tags'
