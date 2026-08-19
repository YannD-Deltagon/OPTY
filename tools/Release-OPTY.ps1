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

# --- gate 10: no stray control bytes ---------------------------------------
# A NUL or other control byte in a .bat can truncate how CMD reads the file,
# and it is invisible in every editor. This has already happened twice here,
# both times from the SAME cause: generating batch through Python string
# literals, where "\4" and "\0000" are read as OCTAL escapes rather than as a
# backslash followed by digits. "Documents\4 - VSC" became "Documents<0x04>",
# and a registry subkey "...\0000" became "...<0x00>0".
# Writing the generator carefully is not a defence - it was written carefully
# the second time, by someone who had just documented the first. Hence a gate.
$ctrl = @{}
for ($i = 0; $i -lt $bytes.Length; $i++) {
    $b = $bytes[$i]
    if ($b -lt 9 -or ($b -gt 10 -and $b -lt 13) -or ($b -gt 13 -and $b -lt 32)) {
        if (-not $ctrl.ContainsKey($b)) { $ctrl[$b] = $i }
    }
}
if ($ctrl.Count) {
    $msg = @()
    foreach ($b in ($ctrl.Keys | Sort-Object)) {
        $off = $ctrl[$b]
        $from = [Math]::Max(0, $off - 40)
        $ctx = [Text.Encoding]::ASCII.GetString($bytes, $from, [Math]::Min(70, $bytes.Length - $from)) -replace '[^\x20-\x7E]', '?'
        $msg += ("byte 0x{0:X2} at offset {1} - near: {2}" -f $b, $off, $ctx)
    }
    Fail ("control byte(s) in OPTY.bat:`n      " + ($msg -join "`n      "))
}
Write-Ok 'no stray control bytes'

# --- CODE ONLY: strip '::' lines before looking for goto/call targets.
# A '::' line is a label CMD never executes, so it is where comments and (soon)
# the bilingual card text live. That prose legitimately contains things like
# "call :label" and "goto the next step", which the regexes below would
# otherwise extract as real targets and fail on. This gate is about executable
# code, so it must only look at executable code.
$codeLines = ($text -split "`r`n") | Where-Object { $_ -notmatch '^\s*::' }
$code = $codeLines -join "`n"

# 3. every goto target resolves (a missing label crashes CMD at runtime)
$labels = [Collections.Generic.HashSet[string]]::new()
foreach ($m in [regex]::Matches($text, '(?m)^:([A-Za-z0-9_\-]+)')) { [void]$labels.Add($m.Groups[1].Value.ToLower()) }
$missing = @()
foreach ($m in [regex]::Matches($code, 'goto[:\s]+([A-Za-z0-9_\-]+)')) {
    $g = $m.Groups[1].Value.ToLower()
    if ($g -ne 'eof' -and -not $labels.Contains($g)) { $missing += $g }
}
if ($missing.Count) { Fail ('unresolved goto target(s): ' + (($missing | Sort-Object -Unique) -join ', ')) }
Write-Ok "$($labels.Count) labels, every goto resolves"

# 4. every `call :sub` resolves too
$missingCalls = @()
foreach ($m in [regex]::Matches($code, '(?m)call\s+:([A-Za-z0-9_\-]+)')) {
    $c = $m.Groups[1].Value.ToLower()
    if (-not $labels.Contains($c)) { $missingCalls += $c }
}
if ($missingCalls.Count) { Fail ('unresolved call target(s): ' + (($missingCalls | Sort-Object -Unique) -join ', ')) }
Write-Ok 'every call resolves'

# 5. no line long enough to be truncated by the CRLF self-heal
# The startup self-heal and the post-download normaliser both run
# `type file | find /v ""`. Measured on this machine: `find` copies lines up to
# 2048 characters intact, but a 4095-character line comes back truncated and
# anything longer is capped at 4095. A single over-long line would therefore be
# silently mangled the first time an LF copy repaired itself. 1000 is a wide
# margin - today's longest line is 696.
$long = @()
$n = 0
foreach ($line in ($text -split "`r`n")) {
    $n++
    if ($line.Length -gt 1000) { $long += "line ${n}: $($line.Length) chars" }
}
if ($long.Count) {
    Fail ("line(s) over 1000 chars - `find /v ''` would truncate them during CRLF self-heal: " + ($long -join '; '))
}
Write-Ok 'no line over 1000 chars (self-heal safe)'

# --- gate 9: no reading a subroutine's output inside the same parenthesised block
# CMD parses a whole "if ... ( ... )" block BEFORE running any of it, so a
# %VAR% written by a `call` inside the block is expanded to its OLD value - for
# a variable the call is meant to create, that is the empty string, every time.
# It is valid batch, it passes every other gate, and it silently does nothing.
# The GPU section shipped with exactly this shape in its first draft:
#     if defined GPUAMD (
#         call :ask "gpu.ulps" 5
#         if "%ANSWER%"=="1" reg add ...        <-- ANSWER is always empty here
#     )
# The fix is always the same: flatten it with goto, or use delayed expansion.
$setters = @{
    'ask'      = @('ANSWER')
    'profval'  = @('PROFVAL')
    'stepmeta' = @('STEPMEM', 'STEPLBL')
    'regset'   = @('RESULT')
    'svcset'   = @('RESULT')
    'pwrread'  = @('PWAC', 'PWDC')
    'cp_read'  = @('CURCP')
    'isrunning' = @('RUNNING')
}
$depth = 0
$pending = @{}
$blockBugs = @()
$n = 0
foreach ($line in $codeLines) {
    $n++
    # Count only STRUCTURAL parentheses. Two things must go first or the depth
    # counter is nonsense: 'echo(' is this file's safe-echo idiom and is not a
    # block opener, and parentheses inside "quoted strings" are data. Without
    # this the gate fired 17 times on correct code, every one a false positive
    # from echo( - a gate that cries wolf is worse than no gate at all.
    $struct = $line -replace '"[^"]*"', '' -replace '(?i)echo\(', 'echo '
    $opens  = ([regex]::Matches($struct, '\(')).Count
    $closes = ([regex]::Matches($struct, '\)')).Count
    # a call that populates a variable, seen while inside a block
    if ($depth -gt 0) {
        foreach ($sub in $setters.Keys) {
            if ($line -match "(?i)call\s+:$sub\b") {
                foreach ($v in $setters[$sub]) { $pending[$v] = $n }
            }
        }
        foreach ($v in @($pending.Keys)) {
            # the same block later reads it with %VAR% - too late, already expanded
            if ($line -match "%$v%" -and $n -gt $pending[$v]) {
                $blockBugs += "line ${n}: reads %$v% inside the same ( ) block that called the subroutine setting it (line $($pending[$v])) - it will be empty"
                $pending.Remove($v)
            }
        }
    }
    $depth += $opens - $closes
    if ($depth -le 0) { $depth = 0; $pending = @{} }
}
if ($blockBugs.Count) { Fail ("parenthesised-block expansion bug(s):`n      " + ($blockBugs -join "`n      ")) }
Write-Ok 'no subroutine output read inside its own ( ) block'

# --- gate 11: no recursive delete of a folder that holds user data --------
# The one absolute rule here is that cleanup never removes configuration,
# saved logins, cookies, history or entitlements. It shipped broken twice,
# and neither time was visible in a diff, because both paths read like cache:
#   del /F /S /Q "%LOCALAPPDATA%\Steam\htmlcache\*"
#       htmlcache is Steam's whole CEF user-data directory - Cookies, Login
#       Data, Preferences, History, Web Data all sat inside it.
#   del /F /S /Q "...\Ubisoft Game Launcher\cache\*"
#       cache\ownership and cache\activations are entitlement state.
# So the gate matches on the CONTAINER, not on the word cache: these roots
# may only be deleted one disposable subfolder at a time.
$userDataRoots = @(
    'htmlcache\*',
    'User Data\*',
    'Ubisoft Game Launcher\cache\*',
    'EA Desktop\cache\*'
)
# Individual files that are user data wherever they appear.
$userDataFiles = @(
    'Login Data', 'Cookies', 'Web Data', 'Bookmarks', 'Secure Preferences'
)
$udBugs = @()
$n = 0
foreach ($line in $codeLines) {
    $n++
    if ($line -notmatch '(?i)^\s*(if [^&]*)?(del|rd|rmdir)\s') { continue }
    foreach ($root in $userDataRoots) {
        # The closing quote is load-bearing: without it PowerShell reads the
        # trailing star of the pattern as a wildcard, so cache\http2\* matches
        # cache\* and every correctly-narrowed line is flagged. Four of the six
        # first hits were exactly that.
        if ($line.Contains($root + [char]34)) {
            $udBugs += "line ${n}: recursive delete of ${root} - that container holds user data, target its disposable subfolders instead"
        }
    }
    foreach ($f in $userDataFiles) {
        if ($line.Contains([char]92 + $f)) {
            $udBugs += "line ${n}: deletes ${f}, which is user data, not cache"
        }
    }
}
if ($udBugs.Count) { Fail ("user-data deletion:`n      " + ($udBugs -join "`n      ")) }
Write-Ok 'no recursive delete of a user-data folder'
# --- gate 6: every card exists in BOTH languages, and every ::P| has a card ---
# A missing translation is invisible until a French user hits that one question
# and gets a blank screen with a prompt under it.
$lines = $text -split "`r`n"
$cardIds = @{}
$profIds = @{}
foreach ($line in $lines) {
    # Greedy id capture, then the sequence token. The sequence has no fixed
    # width - a one-char alphabet silently truncated long cards - so the id is
    # 'everything up to the LAST dot', not 'everything up to a single char'.
    if ($line -match '^::T\|(FR|EN)\|(.+)\.[0-9a-z]+\|') {
        $key = $matches[2]
        if (-not $cardIds.ContainsKey($key)) { $cardIds[$key] = @{} }
        $cardIds[$key][$matches[1]] = $true
    }
    if ($line -match '^::P\|([a-z0-9_.]+)\|') { $profIds[$matches[1]] = $true }
}
$cardProblems = @()
foreach ($id in $cardIds.Keys) {
    if (-not $cardIds[$id].ContainsKey('FR')) { $cardProblems += "$id has EN text but no FR" }
    if (-not $cardIds[$id].ContainsKey('EN')) { $cardProblems += "$id has FR text but no EN" }
}
foreach ($id in $profIds.Keys) {
    if (-not $cardIds.ContainsKey($id)) { $cardProblems += "$id has a ::P| profile row but no ::T| card text" }
}
# findstr matches by PREFIX, so a card id that is a prefix of another id
# would render BOTH cards as one blob. It costs nothing to forbid now and is
# invisible until someone adds the colliding id months later.
foreach ($a in $cardIds.Keys) {
    foreach ($b in $cardIds.Keys) {
        if ($a -ne $b -and $b.StartsWith("$a.")) {
            $cardProblems += "card id '$a' is a prefix of '$b' - findstr would render both as one"
        }
    }
}
if ($cardProblems.Count) { Fail ("card table problems:`n      " + ($cardProblems -join "`n      ")) }
if ($cardIds.Count) { Write-Ok "$($cardIds.Count) card(s), all bilingual, $($profIds.Count) with a profile row" }

# --- gate 12: every profile column must be a value the engine can write ------
# A column is what :askreg passes to :regset. Prose there means the source
# described the setting instead of deciding one, and :askreg refuses it - so the
# card renders, the user answers, and nothing happens. Six cards shipped that
# way, all six of them on/off PAIRS from the model the 5-profile scale replaced:
# a pair cannot express "what should this be on a laptop", so every column came
# back REVIEW or a sentence like "0 on all eight".
# A literal value is short and has no spaces. SKIP, DELETE, KEEP, ASK, RUN,
# RESTART, APPLY and REVIEW are the accepted keywords; REVIEW is rejected here
# precisely because it means "not decided yet".
$profBad = @()
$n = 0
foreach ($line in $lines) {
    $n++
    if ($line -notmatch '^::P\|([a-z0-9_.]+)\|(.+)\|\s*$') { continue }
    $cid = $matches[1]
    $cols = $matches[2] -split '\|'
    if ($cols.Count -ne 5) {
        $profBad += "line ${n}: ${cid} has $($cols.Count) profile columns, expected 5"
        continue
    }
    foreach ($c in $cols) {
        $v = $c.Trim()
        if ($v -eq '')        { $profBad += "line ${n}: ${cid} has an empty profile column"; continue }
        if ($v -eq 'REVIEW')  { $profBad += "line ${n}: ${cid} still says REVIEW - the value was never decided, so the question does nothing"; continue }
        if ($v -match '\s')   { $profBad += "line ${n}: ${cid} profile column is prose, not a value: '$v'" }
    }
}
if ($profBad.Count) { Fail ("unusable profile column(s):`n      " + ($profBad -join "`n      ")) }
Write-Ok 'every profile column is a writable value'

# --- gate 7: no "!" in card text ------------------------------------------
# The ASCII fallback renders cards under `setlocal enabledelayedexpansion`,
# where "!" is an expansion delimiter and is eaten. The UTF-8 path shows it and
# the ASCII path silently drops it, so the bug only appears on the machines
# least able to diagnose it.
$bang = @()
$n = 0
foreach ($line in $lines) {
    $n++
    if ($line -match '^::[TX]\|' -and $line.Contains('!')) { $bang += "line ${n}: $($line.Substring(0, [Math]::Min(70, $line.Length)))" }
}
if ($bang.Count) { Fail ("card text contains '!' - delayed expansion eats it in the ASCII path:`n      " + ($bang -join "`n      ")) }
Write-Ok 'no "!" in card text'

# --- gate 8: CLEAN step membership declared exactly once ---------------
# Membership used to live only in scattered "if /i %autoclean% == N goto x"
# lines, with nothing tying them to what the manual menu told the user. This
# gate recomputes membership FROM THE CODE and fails when it disagrees with
# the ::S| table, so the table cannot rot silently.
$tableRows = @{}
$ignored = @()
foreach ($line in ($text -split "`r`n")) {
    if ($line -match '^::S\|IGNORE\|([^|]*)\|') { $ignored = $matches[1].Trim() -split '\s+'; continue }
    if ($line -match '^::S\|([^|]+)\|([^|]*)\|([^|]*)\|') {
        $tableRows[$matches[3].Trim().ToLower()] = @{ Id = $matches[1].Trim(); Mem = $matches[2].Trim() }
    }
}
if ($tableRows.Count -eq 0) { Fail 'no ::S| CLEAN membership table found' }

# autoclean 1 = Auto lite, 2 = Auto full. A step belongs to a mode if a gate
# jumps to it in that mode, or if the mode selector enters it directly.
$fullFromCode = [Collections.Generic.HashSet[string]]::new()
$liteFromCode = [Collections.Generic.HashSet[string]]::new()
foreach ($m in [regex]::Matches($code, '(?im)if\s+/i\s+%autoclean%\s*==\s*([12])\s+goto\s+([A-Za-z0-9_\-]+)')) {
    $t = $m.Groups[2].Value.ToLower()
    if ($m.Groups[1].Value -eq '2') { [void]$fullFromCode.Add($t) } else { [void]$liteFromCode.Add($t) }
}
foreach ($m in [regex]::Matches($code, '(?im)set\s+"autoclean=([12])"[^\r\n]*?goto\s+([A-Za-z0-9_\-]+)')) {
    $t = $m.Groups[2].Value.ToLower()
    if ($m.Groups[1].Value -eq '2') { [void]$fullFromCode.Add($t) } else { [void]$liteFromCode.Add($t) }
}

$drift = @()
foreach ($lbl in $tableRows.Keys) {
    $mem = $tableRows[$lbl].Mem
    $id  = $tableRows[$lbl].Id
    $sayFull = $mem -like '*F*'
    $sayLite = $mem -like '*L*'
    if ($sayFull -and -not $fullFromCode.Contains($lbl)) { $drift += "$id claims Auto-full but no code path reaches :$lbl in mode 2" }
    if ($sayLite -and -not $liteFromCode.Contains($lbl)) { $drift += "$id claims Auto-lite but no code path reaches :$lbl in mode 1" }
    if (-not $sayFull -and $fullFromCode.Contains($lbl)) { $drift += "$id claims NOT Auto-full but the code jumps to :$lbl in mode 2" }
    if (-not $sayLite -and $liteFromCode.Contains($lbl)) { $drift += "$id claims NOT Auto-lite but the code jumps to :$lbl in mode 1" }
}
$reached = @($fullFromCode) + @($liteFromCode) | Sort-Object -Unique
foreach ($t in $reached) {
    if (-not $tableRows.ContainsKey($t) -and $ignored -notcontains $t) {
        $drift += "code reaches :$t in an auto mode but no ::S| row declares it (add a row, or list it in ::S|IGNORE|)"
    }
}
if ($drift.Count) { Fail ("CLEAN membership drift between the ::S| table and the code:`n      " + ($drift -join "`n      ")) }
Write-Ok "$($tableRows.Count) CLEAN steps, table matches the code"

# 6. version marker
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

