<#
.SYNOPSIS
    Validate, tag and publish an OPTY release on GitHub (tag + release + OPTY.bat asset).

.DESCRIPTION
    OPTY self-updates by downloading the OPTY.bat asset attached to the "latest"
    GitHub release. That asset is byte-preserved by GitHub, so it MUST already be
    CRLF: CMD computes the return address of `call :label` / `goto :eof` as a byte
    offset assuming 2-byte CRLF line endings. A single LF-only file silently drifts
    the return address and makes execution jump into the wrong section.

    This script therefore refuses to publish unless OPTY.bat passes every integrity
    gate, and it re-downloads the published asset afterwards to prove it is intact.

.PARAMETER Version
    Version to publish, e.g. "05.0". Defaults to the value of `set current_version=`
    inside OPTY.bat, which is the single source of truth.

.PARAMETER Notes
    Release notes (markdown). If omitted, they are generated from the git log since
    the previous tag.

.PARAMETER ValidateOnly
    Run every integrity check and stop. Changes nothing, touches no remote.

.PARAMETER DryRun
    Validate + show exactly what would be pushed/created, without doing it.

.EXAMPLE
    .\tools\Release-OPTY.ps1 -ValidateOnly
.EXAMPLE
    .\tools\Release-OPTY.ps1 -DryRun
.EXAMPLE
    .\tools\Release-OPTY.ps1
#>
[CmdletBinding()]
param(
    [string]$Version,
    [string]$Notes,
    [switch]$ValidateOnly,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Repo = 'YannD-Deltagon/OPTY'

function Write-Step { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok   { param($m) Write-Host "    OK   $m" -ForegroundColor Green }
function Write-Warn { param($m) Write-Host "    WARN $m" -ForegroundColor Yellow }
function Fail       { param($m) Write-Host "    FAIL $m" -ForegroundColor Red; throw $m }

# ---------------------------------------------------------------- locate repo
$RepoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $RepoRoot) { Fail 'Not inside a git repository.' }
$RepoRoot = $RepoRoot.Trim()
$Bat = Join-Path $RepoRoot 'OPTY.bat'
if (-not (Test-Path $Bat)) {
    Fail "OPTY.bat not found at $Bat. (OPTY relocates itself to C:\OPTY_by-YannD and deletes the original - run 'git restore OPTY.bat'.)"
}

# ------------------------------------------------------------ integrity gates
Write-Step 'Validating OPTY.bat integrity'
$bytes = [IO.File]::ReadAllBytes($Bat)
$text  = [IO.File]::ReadAllText($Bat)

# 1. no BOM - a UTF-8 BOM is emitted before `@echo off` and breaks the first command
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    Fail 'OPTY.bat starts with a UTF-8 BOM. Re-save as "UTF-8" (not "UTF-8 with BOM").'
}
Write-Ok 'no BOM'

# 2. CRLF everywhere - the critical one
$loneLf = 0
for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($bytes[$i] -eq 10 -and ($i -eq 0 -or $bytes[$i - 1] -ne 13)) { $loneLf++ }
}
if ($loneLf -gt 0) {
    Fail "$loneLf LF-only line ending(s). CMD needs CRLF or call/goto returns drift. Fix: VS Code status bar -> CRLF, or `git add --renormalize .` (see .gitattributes)."
}
Write-Ok 'CRLF only'

# 3. every goto target resolves (a missing label crashes CMD at runtime)
$labels = [Collections.Generic.HashSet[string]]::new()
foreach ($m in [regex]::Matches($text, '(?m)^:([A-Za-z0-9_\-]+)')) { [void]$labels.Add($m.Groups[1].Value.ToLower()) }
$missing = @()
foreach ($m in [regex]::Matches($text, 'goto[:\s]+([A-Za-z0-9_\-]+)')) {
    $g = $m.Groups[1].Value.ToLower()
    if ($g -ne 'eof' -and -not $labels.Contains($g)) { $missing += $g }
}
if ($missing.Count) { Fail ('unresolved goto target(s): ' + (($missing | Sort-Object -Unique) -join ', ')) }
Write-Ok "$($labels.Count) labels, every goto resolves"

# 4. every `call :sub` resolves too
$missingCalls = @()
foreach ($m in [regex]::Matches($text, '(?m)call\s+:([A-Za-z0-9_\-]+)')) {
    $c = $m.Groups[1].Value.ToLower()
    if (-not $labels.Contains($c)) { $missingCalls += $c }
}
if ($missingCalls.Count) { Fail ('unresolved call target(s): ' + (($missingCalls | Sort-Object -Unique) -join ', ')) }
Write-Ok 'every call resolves'

# 5. version marker
$vm = [regex]::Match($text, '(?m)^set current_version=([0-9.]+)\s*$')
if (-not $vm.Success) { Fail 'could not read "set current_version=" from OPTY.bat' }
$fileVersion = $vm.Groups[1].Value
Write-Ok "version in file: $fileVersion"

if (-not $Version) { $Version = $fileVersion }
if ($Version -ne $fileVersion) {
    Fail "requested version '$Version' != version in OPTY.bat '$fileVersion'. Edit `set current_version=` first - it is the single source of truth."
}
$Tag = "V$Version"

if ($ValidateOnly) {
    Write-Host ''
    Write-Host "All integrity gates passed. Would publish tag $Tag." -ForegroundColor Green
    return
}

# ----------------------------------------------------------------- git checks
Write-Step 'Checking git state'
$branch = (& git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne 'master' -and $branch -ne 'main') { Write-Warn "on branch '$branch' (releases normally come from master)" }
$dirty = (& git status --porcelain)
if ($dirty) { Fail "working tree not clean - commit or stash first:`n$dirty" }
Write-Ok "clean tree on '$branch'"

& git fetch origin --tags --quiet 2>$null
$existing = (& git tag -l $Tag)
if ($existing) { Fail "tag $Tag already exists. Bump `set current_version=` in OPTY.bat." }
Write-Ok "tag $Tag is free"

# ------------------------------------------------------------- release notes
if (-not $Notes) {
    $prev = (& git tag --sort=-v:refname | Where-Object { $_ -match '^V' } | Select-Object -First 1)
    $range = if ($prev) { "$prev..HEAD" } else { 'HEAD' }
    $log = (& git log --no-merges --pretty=format:'- %s' $range) -join "`n"
    $Notes = "## OPTY $Tag`n`n$log`n`n---`nDownload **OPTY.bat** below, right-click -> Run as administrator."
    if ($prev) { $Notes += "`n`nFull changelog: https://github.com/$Repo/compare/$prev...$Tag" }
}

# -------------------------------------------------------------------- dry run
if ($DryRun) {
    Write-Host ''
    Write-Host "DRY RUN - nothing was changed." -ForegroundColor Yellow
    Write-Host "  tag        : $Tag"
    Write-Host "  branch     : $branch"
    Write-Host "  asset      : OPTY.bat ($($bytes.Length) bytes, CRLF, no BOM)"
    Write-Host "  notes      :"
    Write-Host ($Notes -split "`n" | ForEach-Object { "      $_" }) -Separator "`n"
    return
}

# ----------------------------------------------------------------- gh token
Write-Step 'Getting GitHub token from Git Credential Manager'
$cred = ("protocol=https`nhost=github.com`n`n" | & git credential fill) 2>$null
$token = ($cred | Select-String '^password=').ToString() -replace '^password=', ''
if (-not $token) { Fail 'no GitHub token available from git credential fill. Run a `git push` once to prime the credential manager.' }
Write-Ok 'token acquired (never printed)'
$hdr = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2022-11-28' }

# --------------------------------------------------------------- tag + push
Write-Step "Creating and pushing tag $Tag"
& git tag -a $Tag -m "OPTY $Tag"
& git push origin $Tag 2>&1 | Out-Null
Write-Ok "tag $Tag pushed"

# ----------------------------------------------------------------- release
Write-Step "Creating GitHub release $Tag"
$body = @{ tag_name = $Tag; name = $Tag; body = $Notes; draft = $false; prerelease = $false } | ConvertTo-Json -Depth 3
$rel = Invoke-RestMethod -Method Post -Uri "https://api.github.com/repos/$Repo/releases" -Headers $hdr -Body $body -ContentType 'application/json'
Write-Ok "release created: $($rel.html_url)"

# ------------------------------------------------------------------- asset
Write-Step 'Uploading OPTY.bat asset (byte-preserved)'
$uploadUrl = ($rel.upload_url -replace '\{.*$', '') + '?name=OPTY.bat'
$assetHdr = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
$asset = Invoke-RestMethod -Method Post -Uri $uploadUrl -Headers $assetHdr -Body $bytes -ContentType 'application/octet-stream'
Write-Ok "asset uploaded ($($asset.size) bytes)"

# --------------------------------------------------- verify what users get
Write-Step 'Verifying the published asset (this is what OPTY self-update downloads)'
$tmp = Join-Path $env:TEMP "opty_asset_check_$Tag.bat"
Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest/download/OPTY.bat" -OutFile $tmp -UseBasicParsing
$dl = [IO.File]::ReadAllBytes($tmp)
$dlLoneLf = 0
for ($i = 0; $i -lt $dl.Length; $i++) {
    if ($dl[$i] -eq 10 -and ($i -eq 0 -or $dl[$i - 1] -ne 13)) { $dlLoneLf++ }
}
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
if ($dl.Length -ne $bytes.Length) { Write-Warn "size differs: local $($bytes.Length) vs published $($dl.Length)" }
if ($dlLoneLf -gt 0) { Fail "PUBLISHED ASSET HAS $dlLoneLf LF-only endings - self-update would corrupt. Delete the release and investigate." }
Write-Ok 'published asset is byte-identical CRLF - self-update is safe'

Write-Host ''
Write-Host "Released $Tag  ->  $($rel.html_url)" -ForegroundColor Green
