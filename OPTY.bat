:::: OPTY by @YannD-Deltagon (refactor) ::::

@echo off
setlocal EnableExtensions

title OPTY by @YannD-Deltagon

:: ---------------------- CONSTANTS ----------------------
set "current_version=02.3"
set "GitHubRawLink=https://raw.githubusercontent.com/YannD-Deltagon/OPTY/master/resources/"
set "GitHubLatestLink=https://github.com/YannD-Deltagon/OPTY/releases/latest/download/"
set "SELF=%~f0"
set "BASEDIR=%~dp0"
set "LOGDIR=%~dp0logs"

:: ---------------------- LOG INIT -----------------------
if not exist "%LOGDIR%" md "%LOGDIR%" >nul 2>&1

for /f %%i in ('powershell -NoP -C "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "ts=%%i"
set "logs=%LOGDIR%\OPTY_%ts%.log"

:: Keep only 15 newest logs
for /f "skip=15 delims=" %%F in ('dir /b /a-d /o:-d "%LOGDIR%\OPTY_*.log"') do del /f /q "%LOGDIR%\%%F"

echo.                                                           >> "%logs%"
echo ====================== :START SCRIPT ====================== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Script start                                >> "%logs%"

:: ---------------------- ADMIN CHECK ---------------------
echo.                                                           >> "%logs%"
echo ====================== :CHECK_ADMIN ======================   >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Checking admin rights                        >> "%logs%"

:: Method: try a command that requires admin, else UAC re-launch
net session >nul 2>&1
if "%errorlevel%"=="0" (
    echo %date% %time% : Running as ADMIN                         >> "%logs%"
) else (
    echo %date% %time% : Not elevated - trying UAC relaunch        >> "%logs%"
    powershell -NoP -C "Start-Process -FilePath '%SELF%' -Verb RunAs" && exit /b
    echo %date% %time% : UAC relaunch failed; exiting              >> "%logs%"
    echo.
    echo   Not running as administrator
    echo   Please relaunch with admin rights
    echo.
    timeout /t 10 >nul
    exit /b
)

:: ---------------------- RELOCATE (optional) -------------
:shortcut
echo.                                                           >> "%logs%"
echo ====================== :SHORTCUT ======================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :shortcut label                      >> "%logs%"

:: Keep your behavior: centralize in C:\OPTY_by-YannD
if /I not "%~dp0"=="C:\OPTY_by-YannD\" (
    echo %date% %time% : Creating central folder & copying script >> "%logs%"
    md "C:\OPTY_by-YannD" >nul 2>&1
    copy /y "%SELF%" "C:\OPTY_by-YannD\OPTY.bat" >nul
    echo %date% %time% : Starting script from new location         >> "%logs%"
    start "" "C:\OPTY_by-YannD\OPTY.bat"
    echo %date% %time% : Exiting original instance                 >> "%logs%"
    exit /b
)

:: ---------------------- GITHUB CHECK --------------------
:ping_github
echo.                                                           >> "%logs%"
echo ====================== :PING_GITHUB ======================   >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :ping_github label                  >> "%logs%"
set "loop_pinggh=0"
color 60

:ping_github_loop
cls
echo(
echo  Checking GitHub reachability...
echo(
ping -n 1 -l 8 github.com | find "TTL=" >nul
if "%errorlevel%"=="0" (
    echo %date% %time% : Ping GitHub OK                      >> "%logs%"
    color 20
    echo(
    echo  Ping check successful.
    echo(
    goto update_opty
) else (
    echo %date% %time% : Ping GitHub failed attempt %loop_pinggh% >> "%logs%"
    color 40
    echo(
    echo  Ping check failed, retrying...
    echo   error : %errorlevel%
    echo   attempt : %loop_pinggh% (max: 5)
    echo(
    set /a loop_pinggh+=1
    if "%loop_pinggh%"=="5" goto ping_github_failed
    timeout /t 1 >nul
    goto ping_github_loop
)

:ping_github_failed
echo.                                                           >> "%logs%"
echo ====================== :PING_GITHUB_FAILED ================= >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :ping_github_failed label           >> "%logs%"
cls
color c0
echo(
echo  Ping check failed.
echo  Switching to local mode
echo(
timeout /t 3 >nul
goto update_not_available

:: ---------------------- UPDATE CHECK -------------------
:update_opty
color 0E
cls
echo(
echo  Checking for OPTY updates...
echo(

:: Robust JSON parse with PowerShell
set "latest_version="
for /f %%v in ('powershell -NoP -C "(Invoke-RestMethod -UseBasicParsing ''https://api.github.com/repos/YannD-Deltagon/OPTY/releases/latest'').tag_name"') do set "latest_version=%%v"

if not defined latest_version goto update_not_available

:: Strip leading "v" if present
set "latest_version=%latest_version:v=%"

echo %date% %time% : current=%current_version%, latest=%latest_version% >> "%logs%"

if "%current_version%"=="%latest_version%" goto update_not_available

echo %date% %time% : Update found                          >> "%logs%"
color 0E
cls
echo(
echo  A new version of OPTY.bat is available on GitHub.
echo(
echo   Current version: v%current_version%
echo   Latest version : v%latest_version%
echo(
set /p choice=Do you want to update ? Y (Yes) - N (No) :
echo %date% %time% : User choice for update = "%choice%"       >> "%logs%"
if /i "%choice%"=="Y" goto update_found_and_accepted
if /i "%choice%"=="N" goto update_found_and_not_accepted
goto update_not_available

:update_found_and_accepted
echo.                                                           >> "%logs%"
echo ====================== :UPDATE_FOUND_AND_ACCEPTED ======== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :update_found_and_accepted label    >> "%logs%"
cls
color 02
echo(
powershell -NoP -C "Invoke-WebRequest -UseBasicParsing '%GitHubLatestLink%OPTY.bat' -OutFile '%~dp0new_OPTY.bat'" && (
    echo %date% %time% : Downloaded new_OPTY.bat                   >> "%logs%"
    move /y "%~dp0new_OPTY.bat" "%~dp0OPTY.bat" >nul
    echo %date% %time% : Replaced old OPTY.bat with new version     >> "%logs%"
    start "" "%~dp0OPTY.bat"
    echo %date% %time% : Relaunched updated script                  >> "%logs%"
    exit /b
) || (
    echo %date% %time% : Update download failed                     >> "%logs%"
    timeout /t 2 >nul
    goto update_not_available
)

:update_found_and_not_accepted
echo.                                                           >> "%logs%"
echo ====================== :UPDATE_FOUND_AND_NOT_ACCEPTED ===== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :update_found_and_not_accepted label >> "%logs%"
cls
color 04
echo(
echo  The script will continue to run with version %current_version%.
echo(
goto menu

:update_not_available
echo.                                                           >> "%logs%"
echo ====================== :UPDATE_NOT_AVAILABLE =============== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : No update available                         >> "%logs%"
color 30
cls
echo(
echo  You are running the latest version: %current_version%.
echo(
goto menu

:: ====================== MENU ======================
:menu
echo.                                                           >> "%logs%"
echo ====================== :MENU ======================            >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :menu label                          >> "%logs%"
color F1
cls
echo(
echo  WELCOME to OPTY by @YannD-Deltagon
echo(
echo   1. MENU - Clean + Optimization
echo   2. MENU - Re-enable option
echo   3. MENU - Registry profile options
echo(
echo   9. Clean OPTY folder (keep OPTY.bat)
echo(
echo   0. Exit
echo(
set /p choice= Enter action: 
echo %date% %time% : Menu choice "%choice%"                    >> "%logs%"
if "%choice%"=="1" goto mopti
if "%choice%"=="2" goto mreenable
if "%choice%"=="3" goto mregprofil
if "%choice%"=="9" goto Clean_Opty_Curl
if "%choice%"=="0" goto end
if "%choice%"=="." goto update_opty
if "%choice%"=="-" goto mupdate_perso
color 0C
echo Invalid action                                             & echo %date% %time% : Invalid menu choice >> "%logs%"
timeout /t 3 >nul
goto menu

:: ====================== OPTI FLOW ======================
:mopti
echo.                                                           >> "%logs%"
echo ====================== :MOPTI ======================           >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mopti label                           >> "%logs%"

if /i "%AutoOpti_Shutdown%"=="1" (
    echo %date% %time% : AutoOpti_Shutdown flag detected            >> "%logs%"
    goto wupdate
)

color F5
cls
echo(
echo  Choose an option for Optimization cycle:
echo   1. Manual
echo   2. Auto (Lite)
echo   3. Auto (Full)
echo(
echo  Suffix: 2r=AutoLite+reboot, 3s=AutoFull+shutdown, etc.
echo(
echo   0. Menu
echo(
set /p choice= Enter action: 
echo %date% %time% : Opti-mopti "%choice%"                            >> "%logs%"

if /i "%choice%"=="1" set "autoclean=0" & set "autoshutdownreboot=5" & goto mdisenable
if /i "%choice%"=="2" set "autoclean=1" & set "autoshutdownreboot=0" & goto wupdate
if /i "%choice%"=="3" set "autoclean=2" & set "autoshutdownreboot=0" & goto stopapps
if /i "%choice%"=="2s" set "autoclean=1" & set "autoshutdownreboot=1" & goto wupdate
if /i "%choice%"=="3s" set "autoclean=2" & set "autoshutdownreboot=1" & goto stopapps
if /i "%choice%"=="2r" set "autoclean=1" & set "autoshutdownreboot=2" & goto wupdate
if /i "%choice%"=="3r" set "autoclean=2" & set "autoshutdownreboot=2" & goto stopapps
if /i "%choice%"=="0" goto menu

color 0C & echo Invalid action & echo %date% %time% : Invalid option in :mopti >> "%logs%"
timeout /t 3 >nul
goto mopti

:: ====================== ENABLE/DISABLE TWEAKS ======================
:mdisenable
echo.                                                           >> "%logs%"
echo ====================== :MDISENABLE ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mdisenable label                       >> "%logs%"
color F4
cls
echo(
echo  Toggle visual/FS behaviors:
echo   -ani / +ani    : Menu animations OFF/ON
echo   -mov / +mov    : Show window contents while dragging OFF/ON
echo   -fad / +fad    : File access time updates OFF/ON (2=default)
echo   -hbn / +hbn    : Hibernation OFF/ON
echo(
echo  Add "+" or "-" before the action, e.g. "-ani".
echo(
echo   2. Next
echo   0. Menu
echo(
set /p choice= Enter action: 
echo %date% %time% : Opti-mdisenable "%choice%"                         >> "%logs%"

if /i "%choice%"=="-ani" reg add "HKCU\Control Panel\Desktop" /v "MenuAnimate" /t REG_SZ /d "0" /f >nul & echo [OK] MenuAnimate=0>>"%logs%" & pause & goto mdisenable
if /i "%choice%"=="+ani" reg add "HKCU\Control Panel\Desktop" /v "MenuAnimate" /t REG_SZ /d "1" /f >nul & echo [OK] MenuAnimate=1>>"%logs%" & pause & goto mdisenable

if /i "%choice%"=="-mov" reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f >nul & echo [OK] DragFullWindows=0>>"%logs%" & pause & goto mdisenable
if /i "%choice%"=="+mov" reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "1" /f >nul & echo [OK] DragFullWindows=1>>"%logs%" & pause & goto mdisenable

if /i "%choice%"=="-fad" fsutil behavior set disablelastaccess 1 >nul & echo [OK] disablelastaccess=1>>"%logs%" & pause & goto mdisenable
if /i "%choice%"=="+fad" (
    :: Better default is 2 (system-managed) rather than 0
    fsutil behavior set disablelastaccess 2 >nul
    echo [OK] disablelastaccess=2 (system default)>>"%logs%"
    pause & goto mdisenable
)

if /i "%choice%"=="-hbn" powercfg /h off >nul & echo [OK] Hibernation OFF>>"%logs%" & pause & goto mdisenable
if /i "%choice%"=="+hbn" powercfg /h on  >nul & echo [OK] Hibernation ON >>"%logs%" & pause & goto mdisenable

if /i "%choice%"=="2" goto mnetdns
if /i "%choice%"=="0" goto menu

color 0C & echo Invalid action & echo %date% %time% : Invalid option in :mdisenable >> "%logs%"
timeout /t 3 >nul
goto mdisenable

:: ====================== PRE TASKS ======================
:stopapps
echo.                                                           >> "%logs%"
echo ====================== :STOPAPPS ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :stopapps label                        >> "%logs%"
cls
echo Stop your background apps!
pause
if /i "%autoclean%"=="2" goto startready
goto startready

:startready
echo.                                                           >> "%logs%"
echo ====================== :STARTREADY ======================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :startready label                      >> "%logs%"

:: Optional COM re-register (kept OFF by default)
set "C_REGSVR=0"
if "%C_REGSVR%"=="1" (
  regsvr32.exe /s atl.dll   & echo %date% %time% : regsvr32 atl.dll   >> "%logs%"
  regsvr32.exe /s urlmon.dll& echo %date% %time% : regsvr32 urlmon.dll>> "%logs%"
  regsvr32.exe /s mshtml.dll& echo %date% %time% : regsvr32 mshtml.dll>> "%logs%"
)

net stop bits      >nul 2>&1 & echo %date% %time% : Stopped service: bits      >> "%logs%"
net stop wuauserv  >nul 2>&1 & echo %date% %time% : Stopped service: wuauserv  >> "%logs%"
net stop msiserver >nul 2>&1 & echo %date% %time% : Stopped service: msiserver >> "%logs%"
net stop cryptsvc  >nul 2>&1 & echo %date% %time% : Stopped service: cryptsvc  >> "%logs%"
net stop appidsvc  >nul 2>&1 & echo %date% %time% : Stopped service: appidsvc  >> "%logs%"

:: Winget upgrades (silent)
winget upgrade --all --silent --ignore-security-hash >nul 2>&1
if errorlevel 1 (echo %date% %time% : winget upgrade failed or partial >> "%logs%") else (echo %date% %time% : winget upgraded apps >> "%logs%")

if /i "%autoclean%"=="2" goto netdns
timeout /t 2 >nul

:: ====================== NETWORK ======================
:mnetdns
echo.                                                           >> "%logs%"
echo ====================== :MNETDNS ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mnetdns label                          >> "%logs%"
cls
echo Do you want to flush DNS and reset IP (IPCONFIG/NETSH)?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-mnetdns "%choice%"                              >> "%logs%"
if "%choice%"=="1" goto netdns
if "%choice%"=="2" goto mdism
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mnetdns >> "%logs%"
timeout /t 3 >nul
goto mnetdns

:netdns
echo.                                                           >> "%logs%"
echo ====================== :NETDNS ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :netdns label                           >> "%logs%"
ipconfig /flushdns                >> "%logs%" 2>&1
netsh int ip reset                >> "%logs%" 2>&1
netsh winsock reset               >> "%logs%" 2>&1
netsh winsock reset proxy         >> "%logs%" 2>&1
if /i "%autoclean%"=="2" goto dism
timeout /t 2 >nul

:: ====================== DISM / SFC ======================
:mdism
echo.                                                           >> "%logs%"
echo ====================== :MDISM ======================        >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mdism label                            >> "%logs%"
cls
echo Do you want to DISM the Windows image and correct problems?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-mdism "%choice%"                              >> "%logs%"
if "%choice%"=="1" goto dism
if "%choice%"=="2" goto msfc
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mdism >> "%logs%"
timeout /t 3 >nul
goto mdism

:dism
echo.                                                           >> "%logs%"
echo ====================== :DISM ======================        >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :dism label                               >> "%logs%"

set "C_DISM_RESETBASE=0"   :: safer default (0). Set 1 to bake updates.
dism /Online /Cleanup-image /ScanHealth            >> "%logs%" 2>&1
dism /Online /Cleanup-image /CheckHealth           >> "%logs%" 2>&1
dism /Online /Cleanup-image /RestoreHealth         >> "%logs%" 2>&1
if "%C_DISM_RESETBASE%"=="1" (
  dism /Online /Cleanup-image /StartComponentCleanup /ResetBase >> "%logs%" 2>&1
) else (
  dism /Online /Cleanup-image /StartComponentCleanup            >> "%logs%" 2>&1
)
if /i "%autoclean%"=="2" goto sfc
timeout /t 2 >nul

:msfc
echo.                                                           >> "%logs%"
echo ====================== :MSFC ======================        >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :msfc label                               >> "%logs%"
cls
echo Run SFC to verify/fix system files?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-msfc "%choice%"                              >> "%logs%"
if "%choice%"=="1" goto sfc
if "%choice%"=="2" goto mwupdate
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :msfc >> "%logs%"
timeout /t 3 >nul
goto msfc

:sfc
echo.                                                           >> "%logs%"
echo ====================== :SFC ======================         >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :sfc label                                >> "%logs%"
sfc /scannow >> "%logs%" 2>&1
if /i "%autoclean%"=="2" goto wupdate
timeout /t 2 >nul

:: ====================== WU TRIGGER ======================
:mwupdate
echo.                                                           >> "%logs%"
echo ====================== :MWUPDATE ======================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mwupdate label                          >> "%logs%"
cls
echo Trigger Windows Update (USOClient)?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-mwupdate "%choice%"                          >> "%logs%"
if "%choice%"=="1" goto wupdate
if "%choice%"=="2" goto mclean
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mwupdate >> "%logs%"
timeout /t 3 >nul
goto mwupdate

:wupdate
echo.                                                           >> "%logs%"
echo ====================== :WUPDATE ======================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :wupdate label                           >> "%logs%"
usoclient StartScan       >> "%logs%" 2>&1
usoclient RefreshSettings >> "%logs%" 2>&1
usoclient StartInstall    >> "%logs%" 2>&1
if /i "%autoclean%"=="1" goto delete
if /i "%autoclean%"=="2" goto delete
timeout /t 2 >nul

:: ====================== CLEANMGR / SILENTCLEANUP ===========
:mclean
echo.                                                           >> "%logs%"
echo ====================== :MCLEAN ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mclean label                            >> "%logs%"
cls
echo 1) Run Disk Cleanup (cleanmgr)    2) Skip to custom delete
echo 3) Run Windows SilentCleanup (safe OS cleanup)
set /p choice= Select: 
echo %date% %time% : Opti-mclean "%choice%"                            >> "%logs%"
if "%choice%"=="1" goto clean
if "%choice%"=="2" goto mdelete
if "%choice%"=="3" (
  schtasks /Run /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" >> "%logs%" 2>&1
  timeout /t 5 >nul
  goto mdelete
)
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mclean >> "%logs%"
timeout /t 3 >nul
goto mclean

:clean
echo.                                                           >> "%logs%"
echo ====================== :CLEAN ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :clean label                            >> "%logs%"
echo Launching CleanMgr configuration (sageset)...
cleanmgr /sageset:65535
echo %date% %time% : Executed cleanmgr /sageset:65535              >> "%logs%"
pause
cleanmgr /sagerun:65535
echo %date% %time% : Executed cleanmgr /sagerun:65535              >> "%logs%"
timeout /t 2 >nul

:: ====================== DELETE MENU ======================
:mdelete
echo.                                                           >> "%logs%"
echo ====================== :MDELETE ======================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mdelete label                          >> "%logs%"
cls
echo Delete temporary files/caches now?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-mdelete "%choice%"                            >> "%logs%"
if "%choice%"=="1" goto delete
if "%choice%"=="2" goto mdefrag
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mdelete >> "%logs%"
timeout /t 3 >nul
goto mdelete

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: DELETE (SAFE, TOGGLED)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:delete
echo.                                                           >> "%logs%"
echo ====================== :DELETE ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :delete label                      >> "%logs%"

:: ----------------------- SAFETY TOGGLES -----------------------
:: 1 = enabled, 0 = disabled
set "DRYRUN=0"

set "C_SILENTCLEANUP=1"     :: run Windows built-in safe cleanup first

set "C_WINUPDATE=1"
set "C_WER=1"
set "C_EVENTLOGS=0"          :: risky for diagnostics
set "C_USER_TEMP=1"
set "C_WINDOWS_TEMP=1"
set "C_CCM=1"

set "C_BROWSERS=1"
set "C_COMMS=1"
set "C_OFFICE=1"
set "C_CREATIVE=1"
set "C_SPOTIFY=0"

set "C_GAME_LAUNCHERS=1"
set "C_DEVTOOLS=1"

set "C_THUMBS=1"
set "C_D3D_SHADER=1"
set "C_MS_STORE=1"
set "C_SEARCH_REINDEX=0"
set "C_CLIPBOARD=1"
set "C_SPOOLER=0"
set "C_DO=1"
set "C_ESD=1"
set "C_DUMPS=1"
set "C_VSS_OLDEST=0"
set "C_RECYCLEBIN=1"
set "C_DEFENDER_UPDATE=1"
set "C_SYSTEM_LOGS=0"

echo %date% %time% : Toggles set (DRYRUN=%DRYRUN%) >> "%logs%"

:: ---------------- OS SilentCleanup (safe) ---------------------
if "%C_SILENTCLEANUP%"=="1" (
  schtasks /Run /TN "\Microsoft\Windows\DiskCleanup\SilentCleanup" >> "%logs%" 2>&1
  timeout /t 3 >nul
)

:: ---------------- WINDOWS UPDATE CACHE -----------------------
if "%C_WINUPDATE%"=="1" (
  echo %date% %time% : Stopping wuauserv                          >> "%logs%"
  net stop wuauserv >nul 2>&1
  echo %date% %time% : Deleting SoftwareDistribution\Download     >> "%logs%"
  call :SAFEDEL "C:\Windows\SoftwareDistribution\Download\*"
  echo %date% %time% : Restarting wuauserv                        >> "%logs%"
  net start wuauserv >nul 2>&1
)

:: ---------------- WER (user) ----------------------------------
if "%C_WER%"=="1" (
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue\*"
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive\*"
)

:: ---------------- Event Logs (off by default) -----------------
if "%C_EVENTLOGS%"=="1" (
  for /F "tokens=*" %%G in ('wevtutil.exe el') DO wevtutil.exe cl "%%G" 2>nul
  call :SAFEDEL "%WINDIR%\System32\winevt\Logs\*"
)

:: ---------------- TEMP (users + Windows) ----------------------
if "%C_USER_TEMP%"=="1" (
  setlocal
  for /D %%i in ("C:\Users\*") do (
     call :SAFEDEL "%%i\AppData\Local\Temp\*"
  )
  endlocal
)
if "%C_WINDOWS_TEMP%"=="1" (
  call :SAFEDEL "%WINDIR%\Temp\*"
)

:: ---------------- SCCM CCMCache -------------------------------
if "%C_CCM%"=="1" call :SAFEDEL "%WINDIR%\ccmcache\*.*"

:: ---------------- BROWSERS (skip if running) ------------------
if "%C_BROWSERS%"=="1" (
  set "skip_browsers=0"
  tasklist /FI "IMAGENAME eq msedge.exe"  | find /I "msedge.exe"  >nul && set "skip_browsers=1"
  tasklist /FI "IMAGENAME eq chrome.exe"  | find /I "chrome.exe"  >nul && set "skip_browsers=1"
  if "%skip_browsers%"=="1" (
    echo %date% %time% : Edge/Chrome running; skipping browser caches >> "%logs%"
  ) else (
    call :SAFEDEL "%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\cache2\*"
    call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*"
    call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache\*"
    call :SAFEDEL "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*"
    call :SAFEDEL "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache\*"
    call :SAFEDEL "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache\*"
    call :SAFEDEL "%APPDATA%\Opera Software\Opera Stable\Cache\*"
    call :SAFEDEL "%LOCALAPPDATA%\Vivaldi\User Data\Default\Cache\*"
    call :SAFEDEL "%LOCALAPPDATA%\Yandex\YandexBrowser\User Data\Default\Cache\*"
  )
)

:: ---------------- COMMS --------------------------------------
if "%C_COMMS%"=="1" (
  call :SAFEDEL "%APPDATA%\discord\Cache\*"
  call :SAFEDEL "%APPDATA%\discord\Code Cache\*"
  call :SAFEDEL "%APPDATA%\discord\GPUCache\*"
  call :SAFEDEL "%APPDATA%\discord\logs\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Teams\Cache\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Teams\Code Cache\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Teams\GPUCache\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Teams\Service Worker\CacheStorage\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Teams\logs\*"
  call :SAFEDEL "%APPDATA%\Slack\Cache\*"
  call :SAFEDEL "%APPDATA%\Slack\Code Cache\*"
  call :SAFEDEL "%APPDATA%\Slack\GPUCache\*"
  call :SAFEDEL "%APPDATA%\Slack\logs\*"
  call :SAFEDEL "%APPDATA%\Zoom\bin\*"
  call :SAFEDEL "%APPDATA%\Zoom\data\*"
  call :SAFEDEL "%APPDATA%\Zoom\logs\*"
  call :SAFEDEL "%APPDATA%\WhatsApp\Cache\*"
  call :SAFEDEL "%APPDATA%\WhatsApp\logs\*"
  call :SAFEDEL "%APPDATA%\Telegram Desktop\tdata\user_data\*"
  call :SAFEDEL "%APPDATA%\Telegram Desktop\log\*"
)

:: ---------------- OFFICE & FRIENDS ---------------------------
if "%C_OFFICE%"=="1" (
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Windows\Outlook\RoamCache\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Office\Recent\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Word\STARTUP\*"
  call :SAFEDEL "%APPDATA%\Microsoft\Excel\XLSTART\*"
  call :SAFEDEL "%APPDATA%\Microsoft\PowerPoint\STARTUP\*"
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\OneNote\*\cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Outlook\*.tmp"
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\OneDrive\logs\*"
  call :SAFEDEL "%APPDATA%\Dropbox\cache\*"
  call :SAFEDEL "%APPDATA%\Foxit Software\Foxit Reader\cache\*"
  call :SAFEDEL "%APPDATA%\LibreOffice\4\cache\*"
  call :SAFEDEL "%APPDATA%\Kingsoft\Office6\office6\temp\*"
  call :SAFEDEL "%APPDATA%\ONLYOFFICE\*"
  call :SAFEDEL "%APPDATA%\OpenOffice\4\user\temp\*"
  call :SAFEDEL "%APPDATA%\Thunderbird\Profiles\*\cache2\*"
)

:: ---------------- CREATIVE -------------------------------
if "%C_CREATIVE%"=="1" (
  call :SAFEDEL "%APPDATA%\Adobe\Common\Media Cache Files\*"
  call :SAFEDEL "%APPDATA%\Adobe\Common\Media Cache\*"
  call :SAFEDEL "%APPDATA%\Adobe\Acrobat\DC\Cache\*"
  call :SAFEDEL "%APPDATA%\Adobe\Adobe Photoshop*\Temp\*"
  call :SAFEDEL "%APPDATA%\Adobe\Adobe Illustrator*\Temp\*"
  call :SAFEDEL "%APPDATA%\Adobe\After Effects\*\Cache\*"
  call :SAFEDEL "%APPDATA%\Adobe\Premiere Pro\*\Profile-*\Cache\*"
  call :SAFEDEL "%APPDATA%\vlc\*"
  call :SAFEDEL "%LOCALAPPDATA%\paint.net\SessionData\*"
  call :SAFEDEL "%APPDATA%\GIMP\2.10\tmp\*"
  if "%C_SPOTIFY%"=="1" (
    call :SAFEDEL "%APPDATA%\Spotify\Storage\*"
    call :SAFEDEL "%LOCALAPPDATA%\Spotify\Data\*"
    call :SAFEDEL "%APPDATA%\Spotify\Logs\*"
  )
)

:: ---------------- GAME LAUNCHERS -------------------------
if "%C_GAME_LAUNCHERS%"=="1" (
  call :SAFEDEL "%LOCALAPPDATA%\EpicGamesLauncher\Saved\webcache\*"
  call :SAFEDEL "%LOCALAPPDATA%\EpicGamesLauncher\Saved\Logs\*"
  call :SAFEDEL "%PROGRAMDATA%\Battle.net\Cache\*"
  call :SAFEDEL "%PROGRAMDATA%\Battle.net\Logs\*"
  call :SAFEDEL "%PROGRAMFILES(x86)%\Steam\appcache\*"
  call :SAFEDEL "%PROGRAMFILES(x86)%\Steam\logs\*"
  call :SAFEDEL "%PROGRAMFILES(x86)%\Steam\htmlcache\*"
  call :SAFEDEL "%PROGRAMDATA%\Origin\Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Electronic Arts\EA Desktop\Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Electronic Arts\EA Desktop\Logs\*"
  call :SAFEDEL "%LOCALAPPDATA%\Riot Games\Riot Client\Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Riot Games\Riot Client\Logs\*"
  call :SAFEDEL "%PROGRAMDATA%\GOG.com\Galaxy\logs\*"
  call :SAFEDEL "%LOCALAPPDATA%\GOG.com\Galaxy\logs\*"
  call :SAFEDEL "%LOCALAPPDATA%\GOG.com\Galaxy\Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Rockstar Games\Launcher\Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Rockstar Games\Launcher\Logs\*"
  call :SAFEDEL "%PROGRAMFILES(x86)%\Ubisoft\Ubisoft Game Launcher\cache\*"
  call :SAFEDEL "%PROGRAMFILES(x86)%\Ubisoft\Ubisoft Game Launcher\logs\*"
  call :SAFEDEL "%LOCALAPPDATA%\Packages\Microsoft.XboxApp*\LocalCache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Packages\Microsoft.XboxApp*\TempState\*"
)

:: ---------------- DEV TOOLS -----------------------------
if "%C_DEVTOOLS%"=="1" (
  call :SAFEDEL "%APPDATA%\Code\Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Android\Sdk\cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\VisualStudio\*\ComponentModelCache\*"
  call :SAFEDEL "%USERPROFILE%\.Rider*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.PyCharm*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.IntelliJIdea*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.WebStorm*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.PhpStorm*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.CLion*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.DataGrip*\system\caches\*"
  call :SAFEDEL "%USERPROFILE%\.eclipse\*"
  call :SAFEDEL "%USERPROFILE%\AppData\Local\NetBeans\Cache\*"
  call :SAFEDEL "%USERPROFILE%\.AndroidStudio*\system\caches\*"
  call :SAFEDEL "%APPDATA%\7-Zip\Temp\*"
  call :SAFEDEL "%APPDATA%\WinRAR\Temp\*"
  call :SAFEDEL "%APPDATA%\SumatraPDF\cache\*"
  call :SAFEDEL "%APPDATA%\Audacity\SessionData\*"
  call :SAFEDEL "%APPDATA%\MPC-HC\*"
)

:: ---------------- WINDOWS CACHES ------------------------
if "%C_THUMBS%"=="1" call :SAFEDEL "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db"
if "%C_D3D_SHADER%"=="1" (
  call :SAFEDEL "%LOCALAPPDATA%\D3DSCache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Microsoft\DirectX Shader Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\AMD\DxCache\*"
  call :SAFEDEL "%ProgramData%\NVIDIA Corporation\NV_Cache\*"
  call :SAFEDEL "%LOCALAPPDATA%\Intel\ShaderCache\*"
)
if "%C_MS_STORE%"=="1" wsreset.exe

if "%C_SEARCH_REINDEX%"=="1" (
  net stop WSearch >nul 2>&1
  call :SAFEDEL "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.*"
  net start WSearch >nul 2>&1
)

:: ---------------- UTILITIES -----------------------------
if "%C_CLIPBOARD%"=="1" echo off | clip
if "%C_SPOOLER%"=="1" (
  net stop spooler >nul 2>&1
  call :SAFEDEL "%systemroot%\System32\spool\PRINTERS\*.*"
  net start spooler >nul 2>&1
)

:: ---------------- OS Files (DO/ESD/DUMPS/VSS) -----------
if "%C_DO%"=="1" call :SAFEDEL "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache\*"
if "%C_ESD%"=="1" (
  call :SAFEDEL "%SystemDrive%\$WINDOWS.~BT\*.esd"
  call :SAFEDEL "%SystemDrive%\$Windows.~BT\Sources\Panther\*"
)
if "%C_DUMPS%"=="1" (
  call :SAFEDEL "%SystemRoot%\Minidump\*"
  call :SAFEDEL "%SystemRoot%\MEMORY.DMP"
)
if "%C_VSS_OLDEST%"=="1" vssadmin delete shadows /for=%SystemDrive% /oldest >nul 2>&1

:: ---------------- RECYCLE BIN ---------------------------
if "%C_RECYCLEBIN%"=="1" PowerShell.exe -NoProfile -Command "Clear-RecycleBin -Force" 2>nul

:: ---------------- DEFENDER SIGNATURES -------------------
if "%C_DEFENDER_UPDATE%"=="1" "%ProgramFiles%\Windows Defender\MpCmdRun.exe" -SignatureUpdate >nul 2>&1

:: ---------------- SYSTEM LOGS (off by default) ----------
if "%C_SYSTEM_LOGS%"=="1" (
  call :SAFEDEL "%windir%\Logs\CBS\*.log"
  call :SAFEDEL "%windir%\WindowsUpdate.log"
  call :SAFEDEL "%windir%\Logs\DISM\*.log"
  call :SAFEDEL "%SystemDrive%\$WINDOWS.~BT\Sources\Panther\*.log"
  call :SAFEDEL "%ProgramData%\Microsoft\Windows\WER\ReportQueue\*"
  call :SAFEDEL "%ProgramData%\Microsoft\Windows\WER\ReportArchive\*"
)

:: ---------------- NEXT STEPS ----------------------------
if /i "%autoclean%"=="1" goto mshutdownreboot
if /i "%autoclean%"=="2" goto defrag
timeout /t 2 >nul
goto :eof

:: ----------------------- HELPERS -------------------------------
:SAFEDEL
:: Usage: call :SAFEDEL "path-or-glob"
echo %date% %time% [DELETE] %~1                                    >> "%logs%"
if /i "%DRYRUN%"=="1" (echo [DRY-RUN] Skipped %~1>>"%logs%" & goto :eof)
del /S /F /Q %~1 2>nul
goto :eof

:: ====================== DEFRAG / CHKDSK ======================
:mdefrag
echo.                                                           >> "%logs%"
echo ====================== :MDEFRAG ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mdefrag label                          >> "%logs%"
cls
echo Defragment HDD / Optimize SSD (defrag)?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-mdefrag "%choice%"                            >> "%logs%"
if "%choice%"=="1" goto defrag
if "%choice%"=="2" goto mchkdsk
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mdefrag >> "%logs%"
timeout /t 3 >nul
goto mdefrag

:defrag
echo.                                                           >> "%logs%"
echo ====================== :DEFRAG ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :defrag label                          >> "%logs%"
defrag /C /O /U /V /H >> "%logs%" 2>&1
if /i "%autoclean%"=="2" goto endready
timeout /t 2 >nul

:mchkdsk
echo.                                                           >> "%logs%"
echo ====================== :MCHKDSK ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mchkdsk label                          >> "%logs%"
cls
echo Check drive integrity and fix issues (CHKDSK /f /r)?
set /p choice= 1 (Yes) - 2 (No) : 
echo %date% %time% : Opti-mchkdsk "%choice%"                            >> "%logs%"
if "%choice%"=="1" goto chkdsk
if "%choice%"=="2" goto mshutdownreboot
if "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mchkdsk >> "%logs%"
timeout /t 3 >nul
goto mchkdsk

:chkdsk
echo.                                                           >> "%logs%"
echo ====================== :CHKDSK ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :chkdsk label                           >> "%logs%"
chkdsk /f /r >> "%logs%" 2>&1
if /i "%autoclean%"=="2" goto endready
timeout /t 2 >nul

:endready
echo.                                                           >> "%logs%"
echo ====================== :ENDREADY ======================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :endready label                         >> "%logs%"
net start bits      >nul 2>&1 & echo %date% %time% : Started service: bits      >> "%logs%"
net start wuauserv  >nul 2>&1 & echo %date% %time% : Started service: wuauserv  >> "%logs%"
net start msiserver >nul 2>&1 & echo %date% %time% : Started service: msiserver >> "%logs%"
net start cryptsvc  >nul 2>&1 & echo %date% %time% : Started service: cryptsvc  >> "%logs%"
net start appidsvc  >nul 2>&1 & echo %date% %time% : Started service: appidsvc  >> "%logs%"
if /i "%autoclean%"=="2" goto mshutdownreboot
timeout /t 2 >nul

:: ====================== REBOOT / SHUTDOWN ======================
:mshutdownreboot
echo.                                                           >> "%logs%"
echo ====================== :MSHUTDOWNREBOOT ================== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mshutdownreboot label                  >> "%logs%"
cls
if /i "%autoshutdownreboot%"=="0" goto skipshutdownreboot
if /i "%autoshutdownreboot%"=="1" goto shutdown
if /i "%autoshutdownreboot%"=="2" goto reboot
if /i "%autoshutdownreboot%"=="5" goto mshutdownrebootfix

:mshutdownrebootfix
echo.                                                           >> "%logs%"
echo ====================== :MSHUTDOWNREBOOTFIX ================   >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mshutdownrebootfix label               >> "%logs%"
echo Do you want to restart/stop the computer?
set /p choice= R (Reboot) - S (Stop) - 0 (No) : 
echo %date% %time% : Opti-mshutdownrebootfix "%choice%"                   >> "%logs%"
if /i "%choice%"=="R" goto reboot
if /i "%choice%"=="S" goto shutdown
if /i "%choice%"=="0" goto menu
echo Invalid action & echo %date% %time% : Invalid option in :mshutdownrebootfix >> "%logs%"
timeout /t 3 >nul
goto mshutdownreboot

:shutdown
echo.                                                           >> "%logs%"
echo ====================== :SHUTDOWN ======================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :shutdown label                          >> "%logs%"
shutdown /s /f /t 15
echo %date% %time% : Executed shutdown /s /f /t 15                    >> "%logs%"
timeout /t 15 >nul
exit /b

:reboot
echo.                                                           >> "%logs%"
echo ====================== :REBOOT ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :reboot label                            >> "%logs%"
shutdown /r /f /t 15
echo %date% %time% : Executed shutdown /r /f /t 15                    >> "%logs%"
timeout /t 15 >nul
exit /b

:skipshutdownreboot
echo.                                                           >> "%logs%"
echo ====================== :SKIPSHUTDOWNREBOOT ================    >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :skipshutdownreboot label                >> "%logs%"
echo The computer will not restart.
pause
goto menu

:: ====================== RE-ENABLE SECTION ======================
:mreenable
echo.                                                           >> "%logs%"
echo ====================== :MREENABLE ======================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mreenable label                         >> "%logs%"
color F2
cls
echo(
echo   1. Start Office update
echo   2. Enable Chrome updates (Policy)
echo   3. Enable Windows Update (Policy)
echo   0. Menu
echo(
set /p choice= Enter action: 
echo %date% %time% : ReEnable choice "%choice%"                     >> "%logs%"
if "%choice%"=="1" goto office_update
if "%choice%"=="2" goto enable_google_update
if "%choice%"=="3" goto enable_windows_update
if "%choice%"=="0" goto menu
color 0C & echo Invalid action & echo %date% %time% : Invalid option in :mreenable >> "%logs%"
timeout /t 3 >nul
goto mreenable

:office_update
echo.                                                           >> "%logs%"
echo ====================== :OFFICE_UPDATE ====================== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :office_update label                    >> "%logs%"
cls
echo Microsoft Office update...
"C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user
echo %date% %time% : Launched OfficeC2RClient.exe /update user   >> "%logs%"
pause
goto mreenable

:enable_google_update
echo.                                                           >> "%logs%"
echo ====================== :ENABLE_GOOGLE_UPDATE ================= >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :enable_google_update label             >> "%logs%"
cls
taskkill /f /im chrome.exe >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Google\Update" /v "UpdateDefault" /t REG_DWORD /d 1 /f >nul
echo %date% %time% : Set Google UpdateDefault=1                     >> "%logs%"
start "" chrome.exe
echo %date% %time% : Launched Chrome                                >> "%logs%"
echo Go to .../help/about to start the update.
pause
goto mreenable

:enable_windows_update
echo.                                                           >> "%logs%"
echo ====================== :ENABLE_WINDOWS_UPDATE ============== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :enable_windows_update label          >> "%logs%"
cls
net stop wuauserv >nul 2>&1
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 0 /f >nul
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d 0 /f >nul
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer" /t REG_DWORD /d 0 /f >nul
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 0 /f >nul
net start wuauserv >nul 2>&1
echo %date% %time% : Windows Update policies restored               >> "%logs%"
pause
goto mreenable

:: ====================== REGISTRY PROFILES ======================
:mregprofil
echo.                                                           >> "%logs%"
echo ====================== :MREGPROFIL ======================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mregprofil label                       >> "%logs%"
color FC
cls
echo(
echo   1. Mouse and power only
echo   10. Mouse and power only-
echo   0. Menu
echo(
set /p choice= Enter action: 
echo %date% %time% : RegProfil choice "%choice%"              >> "%logs%"
if "%choice%"=="1" goto map_only
if "%choice%"=="10" goto map_only-
if "%choice%"=="0" goto menu
color 0C & echo Invalid action & echo %date% %time% : Invalid option in :mregprofil >> "%logs%"
timeout /t 3 >nul
goto mregprofil

:map_only
echo.                                                           >> "%logs%"
echo ====================== :MAP_ONLY ======================       >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :map_only label                         >> "%logs%"
cls
:: NOTE: Disabling Prefetcher/Superfetch can hurt general UX; keep in this profile only.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_SZ /d "00000000" /f >nul
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul
powercfg /h off >nul
timeout /t 2 >nul
goto regsc_map_only

:regsc_map_only
echo.                                                           >> "%logs%"
echo ====================== :REGSC_MAP_ONLY ==================== >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :regsc_map_only label                   >> "%logs%"
sc stop WSearch   >nul 2>&1
sc stop SysMain   >nul 2>&1
sc stop WerSvc    >nul 2>&1
sc stop Spooler   >nul 2>&1
sc stop DPS       >nul 2>&1
sc stop TabletInputService >nul 2>&1
sc config "WSearch" start= demand   >nul 2>&1
sc config "SysMain" start= demand   >nul 2>&1
sc config "WerSvc" start= demand    >nul 2>&1
sc config "Spooler" start= demand   >nul 2>&1
sc config "DPS" start= demand       >nul 2>&1
sc config "TabletInputService" start= disabled >nul 2>&1
pause
goto mregpowercfg

:map_only-
echo.                                                           >> "%logs%"
echo ====================== :MAP_ONLY- ======================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :map_only- label                         >> "%logs%"
cls
:: Same as map_only (kept for compatibility)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_SZ /d "00000000" /f >nul
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul
powercfg /h off >nul
timeout /t 2 >nul
goto regsc_map_only-

:regsc_map_only-
echo.                                                           >> "%logs%"
echo ====================== :REGSC_MAP_ONLY- ==================  >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :regsc_map_only- label                  >> "%logs%"
pause
goto mregpowercfg

:mregpowercfg
echo.                                                           >> "%logs%"
echo ====================== :MREGPOWERCFG ======================    >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mregpowercfg label                    >> "%logs%"
color FC
cls
echo(
echo  Create and activate "Ultimate Performance" power plan?
echo   1. Create + Activate
echo   2. Skip
echo   0. Menu
set /p choice= Enter action: 
echo %date% %time% : mregpowercfg choice "%choice%"           >> "%logs%"
if "%choice%"=="1" goto powercfg
if "%choice%"=="2" goto mregmouse
if "%choice%"=="0" goto menu
color 0C & echo Invalid action & echo %date% %time% : Invalid option in :mregpowercfg >> "%logs%"
timeout /t 3 >nul
goto mregpowercfg

:powercfg
echo.                                                           >> "%logs%"
echo ====================== :POWERCFG ======================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :powercfg label                         >> "%logs%"
for /f %%g in ('powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61') do set "GUID_NEW=%%g"
if defined GUID_NEW powercfg -setactive %GUID_NEW%
echo %date% %time% : Ultimate Performance duplicated/activated       >> "%logs%"
powercfg.cpl
pause
goto mregmouse

:: ====================== MOUSE 1:1 ======================
:mregmouse
echo.                                                           >> "%logs%"
echo ====================== :MREGMOUSE ======================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mregmouse label                        >> "%logs%"
color FC
cls
echo Optimize mouse (1:1, no EPP)?
echo   1. Yes
echo   2. No
echo   0. Menu
set /p choice= Enter action: 
echo %date% %time% : RegProfil-mregmouse "%choice%"             >> "%logs%"
if "%choice%"=="1" goto mouseantilag
if "%choice%"=="2" goto menu
if "%choice%"=="0" goto menu
color 0C & echo Invalid action & echo %date% %time% : Invalid option in :mregmouse >> "%logs%"
timeout /t 3 >nul
goto mregmouse

:mouseantilag
echo.                                                           >> "%logs%"
echo ====================== :MOUSE_1TO1 ===================      >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mouseantilag label                >> "%logs%"

set "MOUSE_REG=HKCU\Control Panel\Mouse"

for %%V in (MouseSpeed MouseThreshold1 MouseThreshold2 MouseSensitivity) do (
  for /f "tokens=2,*" %%a in ('reg query "%MOUSE_REG%" /v %%V ^| find /I "%%V"') do (
    echo %date% %time% [BEFORE] %%V=%%b>>"%logs%"
  )
)

reg add "%MOUSE_REG%" /v "MouseSpeed" /t REG_SZ /d "0"  /f >nul
reg add "%MOUSE_REG%" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "%MOUSE_REG%" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
reg add "%MOUSE_REG%" /v "MouseSensitivity" /t REG_SZ /d "10" /f >nul

for %%V in (MouseSpeed MouseThreshold1 MouseThreshold2 MouseSensitivity) do (
  for /f "tokens=2,*" %%a in ('reg query "%MOUSE_REG%" /v %%V ^| find /I "%%V"') do (
    echo %date% %time% [AFTER] %%V=%%b>>"%logs%"
  )
)

echo %date% %time% [INFO] Mouse 1:1 applied (EPP OFF, slider 6/11).>>"%logs%"
echo %date% %time% [HINT] You may need to re-logon or restart apps.>>"%logs%"
pause
goto menu

:: ====================== CANCEL SHUTDOWN ======================
:nshutdown
echo.                                                           >> "%logs%"
echo ====================== :NSHUTDOWN =====================     >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :nshutdown label                         >> "%logs%"
shutdown /a
echo The computer will not restart.
timeout /t 5 >nul
goto menu

:: ====================== CLEAN OPTY FOLDER ======================
:Clean_Opty_Curl
echo.                                                           >> "%logs%"
echo ====================== :CLEAN_OPTY_CURL ================= >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :Clean_Opty_Curl label                >> "%logs%"
for /f "delims=" %%f in ('dir /b /a-d "%~dp0" ^| findstr /i /v "OPTY.bat"') do (
    echo %date% %time% : Deleting file "%~dp0%%f"                   >> "%logs%"
    del /f /q "%~dp0%%f"
)
goto menu

:: ====================== UPDATE PERSO (placeholder) =============
:mupdate_perso
echo.                                                           >> "%logs%"
echo ====================== :MUPDATE_PERSO ===================   >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :mupdate_perso label                  >> "%logs%"
echo (Not implemented yet)
timeout /t 2 >nul
goto menu

:: ====================== END ======================
:end
echo.                                                           >> "%logs%"
echo ====================== :END ======================        >> "%logs%"
echo.                                                           >> "%logs%"
echo %date% %time% : Entered :end label                             >> "%logs%"
echo %date% %time% : Script end                                      >> "%logs%"
color F2
cls
echo(
echo  Thanks for using my script
echo     @YannD-Deltagon
echo(
timeout /t 10 >nul
endlocal
exit /b
