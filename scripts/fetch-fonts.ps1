# ---------------------------------------------------------------------------
# Download the Open Sans woff2 subsets that assets/head.html expects.
#
# A PowerShell port of scripts/fetch-fonts.R, for the common case where R is
# installed but Rscript.exe is not on PATH. Fetching four files from Google
# Fonts is not an R task; it only lived in R because the rest of the project
# does. This version needs nothing but PowerShell 5.1, which ships with
# Windows.
#
# Usage, from the repository root:
#     powershell -ExecutionPolicy Bypass -File scripts/fetch-fonts.ps1
#
# Options:
#     -Force      re-download files that already exist
#     -DryRun     report what would be fetched, write nothing
#
# The four files are gitignored by nothing: COMMIT THEM. The GitHub Actions
# runner has no R and no PowerShell step, so anything not committed is simply
# absent from the deployed site, and the fallback stack is silent enough that
# local preview will look correct while the live site does not.
# ---------------------------------------------------------------------------
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$root    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$fontDir = Join-Path $root 'assets\fonts'

# Google serves one file per (style, unicode-range) pair. latin-ext is not
# optional: it carries n, l, a, e, s, z and z with diacritics, so without it
# "Guminska", "Kozminski" and "Poznan" change typeface mid-word.
$targets = @(
    @{ Style = 'normal'; Subset = 'latin';     File = 'open-sans-latin.woff2' }
    @{ Style = 'normal'; Subset = 'latin-ext'; File = 'open-sans-latin-ext.woff2' }
    @{ Style = 'italic'; Subset = 'latin';     File = 'open-sans-latin-italic.woff2' }
    @{ Style = 'italic'; Subset = 'latin-ext'; File = 'open-sans-latin-ext-italic.woff2' }
)

# Must stay in step with the `font-weight: 300 800` ranges in assets/head.html.
$cssUrl = 'https://fonts.googleapis.com/css2' +
          '?family=Open+Sans:ital,wght@0,300..800;1,300..800&display=swap'

# Google content-negotiates on User-Agent: an old or unknown client gets TTF,
# a modern one gets woff2. Without this the script silently downloads files
# three times larger that the woff2-only @font-face rules will reject.
$ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ' +
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

# TLS 1.2 for PowerShell 5.1, whose default can still be TLS 1.0.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Fetching stylesheet..."
$css = (Invoke-WebRequest -Uri $cssUrl -UserAgent $ua -UseBasicParsing).Content

# Each @font-face block is preceded by a comment naming its subset:
#     /* latin-ext */
#     @font-face { font-style: normal; ... src: url(...woff2) format('woff2'); }
# Split on the comment so the label and the block that follows stay together.
$parsed = @()
$chunks = [regex]::Split($css, '/\*\s*') | Where-Object { $_ -match '@font-face' }

foreach ($chunk in $chunks) {
    $subset = if ($chunk -match '^([a-z0-9\-\[\]]+)\s*\*/') { $Matches[1] } else { $null }
    $style  = if ($chunk -match 'font-style:\s*(\w+)')      { $Matches[1] } else { 'normal' }
    $url    = if ($chunk -match '(https://[^\)\s]+\.woff2)') { $Matches[1] } else { $null }
    if ($subset -and $url) {
        $parsed += [pscustomobject]@{ Subset = $subset; Style = $style; Url = $url }
    }
}

if ($parsed.Count -eq 0) {
    throw "Found no woff2 URLs. Google may have changed the response; check the User-Agent."
}
Write-Host ("Parsed {0} font-face blocks." -f $parsed.Count)

if (-not $DryRun -and -not (Test-Path $fontDir)) {
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
}

$missing = @()
foreach ($t in $targets) {
    $hit = $parsed | Where-Object { $_.Subset -eq $t.Subset -and $_.Style -eq $t.Style } |
           Select-Object -First 1

    if (-not $hit) {
        $missing += "$($t.Style)/$($t.Subset)"
        continue
    }

    $dest = Join-Path $fontDir $t.File

    if ((Test-Path $dest) -and -not $Force) {
        Write-Host ("  keeping     {0}  (exists; -Force to replace)" -f $t.File)
        continue
    }
    if ($DryRun) {
        Write-Host ("  would fetch {0}  <- {1}" -f $t.File, $hit.Url)
        continue
    }

    Invoke-WebRequest -Uri $hit.Url -UserAgent $ua -OutFile $dest -UseBasicParsing

    # A woff2 file starts with the ASCII signature "wOF2". Anything else means
    # content negotiation handed back TTF, which the @font-face rules reject
    # with no error message anywhere.
    $magic = [System.IO.File]::ReadAllBytes($dest)[0..3]
    $sig   = -join ($magic | ForEach-Object { [char]$_ })
    if ($sig -ne 'wOF2') {
        Remove-Item $dest -Force
        throw "$($t.File) was not woff2 (signature '$sig'). Removed it. Check the User-Agent."
    }

    $kb = [math]::Round((Get-Item $dest).Length / 1KB, 1)
    Write-Host ("  fetched     {0}  ({1} KB)" -f $t.File, $kb)
}

if ($missing.Count -gt 0) {
    throw ("No match in the stylesheet for: {0}" -f ($missing -join ', '))
}

Write-Host ""
Write-Host "Done. Now COMMIT assets/fonts/ ; the CI runner cannot regenerate it."
