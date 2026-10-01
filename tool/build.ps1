<#
.SYNOPSIS
  Builds OneSpend with an automatic build number and the git commit baked in.

.DESCRIPTION
  - Version name comes from pubspec.yaml (`version: x.y.z+n`; the +n part is ignored).
  - Build number (Android versionCode) = number of commits on HEAD, so every
    build from a newer commit is a higher number and installs as an update.
  - The short commit is passed as GIT_SHA and shown on Settings > About in
    debug builds.

.EXAMPLE
  ./tool/build.ps1                 # release app bundle for Play
  ./tool/build.ps1 -Target apk     # release APKs, one per ABI (smaller sideloads)
  ./tool/build.ps1 -Debug          # debug APK with the commit shown in About
#>
param(
  [ValidateSet('appbundle', 'apk')]
  [string]$Target = 'appbundle',
  [switch]$Debug
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$buildNumber = (git rev-list --count HEAD).Trim()
$sha = (git rev-parse --short HEAD).Trim()
if (git status --porcelain) { $sha = "$sha-dirty" }

$mode = if ($Debug) { '--debug' } else { '--release' }
$buildArgs = @($Target, $mode, "--build-number=$buildNumber", "--dart-define=GIT_SHA=$sha")
if ($Target -eq 'apk' -and -not $Debug) { $buildArgs += '--split-per-abi' }

Write-Host "Building $Target ($mode) build $buildNumber from $sha"
flutter build @buildArgs
