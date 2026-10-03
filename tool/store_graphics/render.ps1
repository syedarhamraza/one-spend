<#
.SYNOPSIS
  Renders the Google Play graphics from template.html with headless Chrome.

.DESCRIPTION
  Writes to store/play/:
    screenshots/1-subscriptions.png … 6-backup.png  (1080 x 1920)
    feature-graphic.png                             (1024 x 500)
    icon-512.png                                    (512 x 512, from the app logo)

  To refresh after UI changes: recapture the screens on a phone (see README in this
  folder), replace the files in captures/, then run this script.
#>
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$repo = Split-Path (Split-Path $here -Parent) -Parent
$out = Join-Path $repo 'store/play'
New-Item -ItemType Directory -Force (Join-Path $out 'screenshots') | Out-Null

$chrome = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'Chrome or Edge is needed to render the graphics.' }

$template = ([Uri](Join-Path $here 'template.html')).AbsoluteUri

function Render([string]$hash, [string]$file, [int]$w, [int]$h) {
  $tmp = Join-Path $env:TEMP "onespend-render-$hash.png"
  # Start-Process keeps Chrome's harmless stderr chatter from failing the script.
  $chromeArgs = @('--headless=new', '--disable-gpu', '--hide-scrollbars', '--force-device-scale-factor=1',
    '--virtual-time-budget=8000', '--allow-file-access-from-files',
    "--window-size=$w,$h", "--screenshot=$tmp", "$template#$hash")
  Start-Process -FilePath $chrome -ArgumentList $chromeArgs -Wait -NoNewWindow `
    -RedirectStandardError (Join-Path $env:TEMP 'onespend-render.log')
  if (-not (Test-Path $tmp)) { throw "Rendering #$hash failed." }
  Move-Item -Force $tmp $file
  Write-Host "  $file"
}

$names = @('1-subscriptions', '2-upcoming', '3-trends', '4-categories', '5-savings', '6-backup')
Write-Host 'Rendering store graphics...'
# "-full" = the whole phone under a short one-line headline. Drop it for the close-up layout
# (bigger phone running off the bottom, two-line headline).
$layout = '-full'
for ($i = 0; $i -lt $names.Count; $i++) {
  Render "$($i + 1)$layout" (Join-Path $out "screenshots/$($names[$i]).png") 1080 1920
}
Render 'feature' (Join-Path $out 'feature-graphic.png') 1024 500

# Play wants opaque PNGs for screenshots and the feature graphic, and a 512 px icon.
python (Join-Path $here 'finish.py') $out (Join-Path $here 'captures/logo.png')
