:::: OPTY by @YannD-Deltagon ::::

@echo off
set current_version=06.2
set GitHubRawLink=https://raw.githubusercontent.com/YannD-Deltagon/OPTY/master/resources/
set GitHubLatestLink=https://github.com/YannD-Deltagon/OPTY/releases/latest/download/

:: ---- User / paths configuration (edit here if your username or layout differs) ----
set "USERHOME=C:\Users\compt"
set "WSL_DOCKER_VHDX=%USERHOME%\AppData\Local\Docker\wsl\disk\docker_data.vhdx"
set "WSL_SEARCH1=%USERHOME%\AppData\Local\Packages"
set "WSL_SEARCH2=%USERHOME%\AppData\Local\wsl"
set "DOCKER_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"
set "OPTY_HOME=C:\OPTY_by-YannD"
set "OPTY_HOME_D=%OPTY_HOME%"

:: ---- ANSI / VT colors for live colored console output (CMD on Windows 10/11) ----
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
for /f "delims=" %%E in ('echo prompt $E^| cmd') do set "ESC=%%E"
set "cR=%ESC%[0m"
set "cT=%ESC%[1;96m"
set "cOK=%ESC%[1;92m"
set "cWarn=%ESC%[1;93m"
set "cErr=%ESC%[1;91m"
set "cInfo=%ESC%[90m"
set "cStep=%ESC%[1;95m"
set "cVal=%ESC%[1;97m"

cd /d "%~dp0"
:: keep only the 5 most recent of each artifact family (newest first, skip 5, delete rest)
for /f "skip=5 delims=" %%F in ('dir /b /a-d /o:-d "%~dp0logs_*.txt" 2^>nul') do del "%~dp0%%F" >nul 2>&1
for /f "skip=5 delims=" %%F in ('dir /b /a-d /o:-d "%~dp0netinfo_*.txt" 2^>nul') do del "%~dp0%%F" >nul 2>&1
for /f "skip=5 delims=" %%F in ('dir /b /a-d /o:-d "%~dp0netprops_*.json" 2^>nul') do del "%~dp0%%F" >nul 2>&1

set "current_date=%date:/=-%"
set "current_date=%current_date: =_%"
set "current_time=%time:~0,5%"
set "current_time=%current_time::=-%"
set "current_time=%current_time: =0%"
set logs="%~dp0logs_%current_date%_%current_time%.txt"

echo.                                                           >> %logs%
echo ====================== :START SCRIPT ====================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Script start                                >> %logs%
echo.                                                           >> %logs%
echo ====================== :CHECK_ADMIN ======================   >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Checking admin rights                        >> %logs%
net session >nul 2>&1
if %errorlevel% == 0 (
    echo %date% %time% : Running as ADMIN                         >> %logs%
    goto shortcut
) else (
    echo %date% %time% : Running as USER                          >> %logs%
    echo.                                                       
    echo   Not running as administrator                            
    echo   launch with admin right                                 
    echo.                                                       
    timeout /t 15
    exit
)

:shortcut
echo.                                                           >> %logs%
echo ====================== :SHORTCUT ======================     >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :shortcut label                      >> %logs%
:: Case-insensitive compare: "c:\opty_by-yannd\" used to fail this test, so the
:: script relocated on top of itself and then deleted the copy it was running.
:: And the original is only removed once the copy is verified present - the old
:: order deleted the source even when xcopy had failed, which is how a checkout
:: of this repo could simply lose OPTY.bat.
if /i not "%~dp0" == "%OPTY_HOME%\" (
    echo %date% %time% : Relocating to %OPTY_HOME%                  >> %logs%
    if not exist "%OPTY_HOME%" md "%OPTY_HOME%" >nul 2>&1
    xcopy /y /q "%~dp0OPTY.bat" "%OPTY_HOME%\" >nul
    if not exist "%OPTY_HOME%\OPTY.bat" (
        echo %date% %time% : Relocation FAILED - staying put        >> %logs%
        color 0C
        echo.
        echo  Could not copy OPTY.bat to %OPTY_HOME% - running from here instead.
        echo.
        timeout /t 5
        goto shortcut_done
    )
    echo %date% %time% : Starting script from new location          >> %logs%
    start "" "%OPTY_HOME%\OPTY.bat"
    echo %date% %time% : Removing the original copy                 >> %logs%
    del "%~dp0OPTY.bat"
    exit
)
:shortcut_done

call :sysinfo

:ping_github
echo.                                                           >> %logs%
echo ====================== :PING_GITHUB ======================   >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :ping_github label                  >> %logs%
set loop_pinggh=0
color 60

:ping_github_loop
cls
echo.                                                  
echo  Check GitHub ping...                                  
echo.                                                  
ping -n 1 -l 8 github.com | find "TTL="
if %errorlevel%==0 (
    echo %date% %time% : Ping GitHub OK                      >> %logs%
    color 20
    echo.                                                  
    echo  Ping check successful.                             
    echo.                                                  
    goto update_opty
) else (
    echo %date% %time% : Ping GitHub failed for attempt %loop_pinggh% >> %logs%
    color 40
    echo.                                                
    echo  Ping check failed, retrying...                     
    echo   error : %errorlevel%                              
    echo   attempt : %loop_pinggh% "(max : 5)"                
    echo.                                                
    set /a loop_pinggh=%loop_pinggh%+1
    if %loop_pinggh%==5 goto ping_github_failed
    timeout /t 1
    goto ping_github_loop
)

:ping_github_failed
echo.                                                           >> %logs%
echo ====================== :PING_GITHUB_FAILED ================= >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :ping_github_failed label           >> %logs%
cls
color c0
echo.                                                  
echo  Ping check failed.                                     
echo  local mode                                              
echo.                                                  
timeout /t 5
goto update_not_available

:update_opty
color 0E
cls
echo.                                                  
echo  Check Update for this script...                           
echo.                                                  
:: The API is queried unauthenticated, so it is rate limited (60/h per IP) and
:: can answer with an error body. If tag_name is missing, latest_version stays
:: undefined and %latest_version:~0,-2% would expand to the literal "~0,-2",
:: which used to offer a bogus update on an up-to-date install. Bail out
:: instead: an update check that cannot answer means "no update".
set "latest_version="
for /f "tokens=2 delims=V" %%a in ('curl -s https://api.github.com/repos/YannD-Deltagon/OPTY/releases/latest -L -H "Accept: application/json" ^| findstr "tag_name"') do set "latest_version=%%a"
if not defined latest_version (
    echo %date% %time% : Version check failed - staying on %current_version%  >> %logs%
    goto update_not_available
)
set "latest_version=%latest_version:~0,-2%"
if not defined latest_version goto update_not_available
echo %date% %time% : current_version=%current_version%, latest_version=%latest_version% >> %logs%
if "%current_version%"=="%latest_version%" goto update_not_available
echo %date% %time% : Update found                          >> %logs%
color 0E
cls
echo.                                                  
echo  A new version of OPTY.bat is available on GitHub.      
echo.                                                  
echo.                                                  
echo   Current version: v%current_version%                    
echo   Latest version: v%latest_version%                      
echo.                                                  
echo.                                                  
set "choice="
set /p choice=Do you want to update ? Y (Yes) - N (No)
echo %date% %time% : User choice for update = "%choice%"       >> %logs%
if /i "%choice%"=="Y" goto update_found_and_accepted
:: Anything else - including a bare Enter - means "no". Without this the code
:: fell straight through into the update, so pressing Enter replaced the script.
goto update_found_and_not_accepted

:update_found_and_accepted
echo.                                                           >> %logs%
echo ====================== :UPDATE_FOUND_AND_ACCEPTED ======== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :update_found_and_accepted label    >> %logs%
cls
color 02
echo.                                                  
:: -f makes curl fail on HTTP errors instead of writing the error page to disk,
:: and -LJO was contradictory with -o (curl warns and honours -o anyway).
:: Without this, a 404 wrote an HTML page over OPTY.bat and curl still exited 0.
:: :shortcut already deleted the copy the user launched, so this file is the
:: ONLY one left - and it is the undo path for every change OPTY makes.
curl -f -L -o "%~dp0new_OPTY.bat" %GitHubLatestLink%OPTY.bat
if errorlevel 1 goto update_download_failed
if not exist "%~dp0new_OPTY.bat" goto update_download_failed
:: Sanity-check the payload really is an OPTY script before overwriting.
find /c "set current_version=" "%~dp0new_OPTY.bat" >nul 2>&1 || goto update_download_failed
echo %date% %time% : Downloaded and validated new_OPTY.bat      >> %logs%
copy /y "%~dp0OPTY.bat" "%~dp0OPTY_rollback.bat" >nul 2>&1
move /y "%~dp0new_OPTY.bat" "%~dp0OPTY.bat" >nul || goto update_download_failed
echo %date% %time% : Replaced old OPTY.bat with new version     >> %logs%
echo.
echo The script has been updated to %latest_version%.
echo  (previous version kept as OPTY_rollback.bat)
echo.
start "" "%~dp0OPTY.bat"
echo %date% %time% : Relaunched updated script                  >> %logs%
exit

:update_download_failed
del /f /q "%~dp0new_OPTY.bat" >nul 2>&1
echo %date% %time% : Update download failed - keeping v%current_version% >> %logs%
color 0C
echo.
echo  Update failed, or the downloaded file was not a valid OPTY.bat.
echo  Keeping version %current_version% - nothing was replaced.
echo.
timeout /t 6
goto menu

:update_found_and_not_accepted
echo.                                                           >> %logs%
echo ====================== :UPDATE_FOUND_AND_NOT_ACCEPTED ===== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :update_found_and_not_accepted label >> %logs%
cls
color 04
echo.                                                  
echo The script will continue to run with version %current_version%. 
echo.                                                  
goto menu

:update_not_available
echo.                                                           >> %logs%
echo ====================== :UPDATE_NOT_AVAILABLE =============== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : No update available                         >> %logs%
color 30
cls
echo.                                                  
echo You are running the latest version of this script: %current_version%. 
echo.                                                  
goto menu


:menu
echo.                                                           >> %logs%
echo ====================== :MENU ======================            >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :menu label                          >> %logs%
color 0F
cls
call :banner "OPTY v%current_version%   -   Windows 11 optimizer   -   @YannD-Deltagon"
echo(
echo(   %cT%MAINTENANCE%cR%
echo(     %cVal%1.%cR%  Clean ^& Optimize        %cInfo%Manual / Auto Lite / Auto Full%cR%
echo(     %cVal%2.%cR%  Repair Windows          %cInfo%DISM, SFC, CHKDSK - one at a time%cR%
echo(
echo(   %cT%TUNING%cR%
echo(     %cVal%3.%cR%  Network                 %cInfo%diagnose, full report, apply, restore%cR%
echo(     %cVal%4.%cR%  System ^& Gaming         %cInfo%registry profile, power plan, mouse%cR%
echo(     %cVal%5.%cR%  Display ^& GPU           %cInfo%MPO / HAGS - opt-in, read the notes%cR%
echo(
echo(   %cT%PRIVACY%cR%
echo(     %cVal%6.%cR%  Debloat 2026            %cInfo%Recall, Copilot, ads, widgets, telemetry%cR%
echo(
echo(   %cT%SAFETY NET%cR%
echo(     %cVal%7.%cR%  Restore defaults        %cInfo%re-assert good defaults / undo profiles%cR%
echo(     %cVal%8.%cR%  Re-enable updates       %cInfo%Office / Chrome / Windows Update via GPO%cR%
echo(
echo(   %cT%OPTY%cR%
echo(     %cVal%9.%cR%  Clean OPTY files        %cInfo%logs and reports in %OPTY_HOME_D%%cR%
echo(     %cVal%D.%cR%  Driver store            %cInfo%remove superseded driver packages%cR%
echo(     %cVal%0.%cR%  Exit
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : Menu choice "%choice%"                           >> %logs%
if "%choice%"=="1" (call :restore_point & goto mopti)
if "%choice%"=="2" goto mrepair
if "%choice%"=="3" goto mnetwork
if "%choice%"=="4" (call :restore_point & goto mregprofil)
if "%choice%"=="5" goto display_tweaks
if "%choice%"=="6" (call :restore_point & goto debloat2026)
if "%choice%"=="7" (call :restore_point & goto mrestore)
if "%choice%"=="8" (call :restore_point & goto mreenable)
if "%choice%"=="9" goto Clean_Opty_Curl
if /i "%choice%"=="D" goto driverstore
if "%choice%"=="0" goto end
if "%choice%"=="." goto update_opty
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid menu choice                             >> %logs%
timeout /t 5
goto menu


:mopti
call :get_free_mb "%SystemDrive%"
set "FREE_BEFORE=%FREE_MB%"
>>%logs% echo %date% %time% : Free space %SystemDrive% before = %FREE_BEFORE% MB
echo.                                                           >> %logs%
echo ====================== :MOPTI ======================           >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mopti label                           >> %logs%
if /i "%AutoOpti_Shutdown%"=="1" (
    echo %date% %time% : AutoOpti_Shutdown flag detected            >> %logs%
    goto wupdate
)

color F5
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo    Choose an option for Optimization cycle:                    
echo.                                                  
echo.                                                  
echo.                                                  
echo   1. Manual                                                    
echo   2. Auto (lite)                                                
echo   3. Auto (Full)                                                
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo  If you want reboot/stop after autoopti, type "r" (reboot) or "s" (shutdown) after the number 
echo  If you don't want reboot/stop, type nothing after the number - 2-3     
echo  2r - Auto (Lite) + reboot                                       
echo  3s - Auto (Full) + Stop                                          
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo   0. Menu                                                         
echo.                                                  
echo.                                                  
set "choice="
set /p choice= Enter action:
echo %date% %time% : Opti-mopti "%choice%"                            >> %logs%
if /i "%choice%"=="1" (set "autoclean=0" & set "autoshutdownreboot=5" & call :logvars & goto mdisenable)
if /i "%choice%"=="2" (set "autoclean=1" & set "autoshutdownreboot=0" & call :logvars & goto wupdate)
if /i "%choice%"=="3" (set "autoclean=2" & set "autoshutdownreboot=0" & call :logvars & goto stopapps)
if /i "%choice%"=="2s" (set "autoclean=1" & set "autoshutdownreboot=1" & call :logvars & goto wupdate)
if /i "%choice%"=="3s" (set "autoclean=2" & set "autoshutdownreboot=1" & call :logvars & goto stopapps)
if /i "%choice%"=="2r" (set "autoclean=1" & set "autoshutdownreboot=2" & call :logvars & goto wupdate)
if /i "%choice%"=="3r" (set "autoclean=2" & set "autoshutdownreboot=2" & call :logvars & goto stopapps)
if /i "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mopti                        >> %logs%
timeout /t 5
goto mopti


:mdisenable
echo.                                                           >> %logs%
echo ====================== :MDISENABLE ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdisenable label                       >> %logs%
color F4
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo    Choose an option to Disable/Enable:                          
echo.                                                  
echo.                                                  
echo.                                                  
echo   ani. Animation                                                 
echo   mov. Window content while moving                               
echo   fad. File access date updating                                  
echo   hbn. Hibernation mods                                           
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo  Add "+" or "-" in front of an action to activate or deactivate (example "-ani" to deactivate animations) 
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo   2. Next                                                          
echo   0. Menu                                                          
echo.                                                  
echo.                                                  
set "choice="
set /p choice= Enter action:
echo %date% %time% : Opti-mdisenable "%choice%"                         >> %logs%
if /i "%choice%"=="-ani" echo %date% %time% : Action - Disable animations (MenuAnimate=0) >> %logs% & echo  -ani & reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuAnimate" /t REG_SZ /d "0" /f & pause & goto mdisenable
if /i "%choice%"=="+ani" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuAnimate" /t REG_SZ /d "1" /f & echo %date% %time% : Action - Enable animations (MenuAnimate=1) >> %logs% & echo  +ani & pause & goto mdisenable
if /i "%choice%"=="-mov" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f & echo %date% %time% : Action - Disable window content while moving (DragFullWindows=0) >> %logs% & echo  -mov & pause & goto mdisenable
if /i "%choice%"=="+mov" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "1" /f & echo %date% %time% : Action - Enable window content while moving (DragFullWindows=1) >> %logs% & echo  +mov & pause & goto mdisenable
if /i "%choice%"=="-fad" fsutil behavior set disablelastaccess 1 & echo %date% %time% : Action - Disable file access date updating (disablelastaccess=1) >> %logs% & echo  -fad & pause & goto mdisenable
if /i "%choice%"=="+fad" fsutil behavior set disablelastaccess 0 & echo %date% %time% : Action - Enable file access date updating (disablelastaccess=0) >> %logs% & echo  +fad & pause & goto mdisenable
if /i "%choice%"=="-hbn" powercfg.exe /hibernate off & echo %date% %time% : Action - Disable hibernation (powercfg h off) >> %logs% & echo  -hbn & pause & goto mdisenable
if /i "%choice%"=="+hbn" powercfg.exe /hibernate on & echo %date% %time% : Action - Enable hibernation (powercfg h on) >> %logs% & echo  +hbn & pause & goto mdisenable
if /i "%choice%"=="2" goto mnetdns
if /i "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mdisenable                     >> %logs%
timeout /t 5
goto mdisenable


:stopapps
echo.                                                           >> %logs%
echo ====================== :STOPAPPS ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :stopapps label                        >> %logs%
cls
echo Stop your background apps!
pause
if /i %autoclean% == 2 goto startready

:startready
echo.                                                           >> %logs%
echo ====================== :STARTREADY ======================     >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :startready label                      >> %logs%
wsl --shutdown
echo %date% %time% : Executed wsl --shutdown (free WSL/Docker resources)   >> %logs%
net stop bits
echo %date% %time% : Stopped service: bits                            >> %logs%
net stop wuauserv
echo %date% %time% : Stopped service: wuauserv                         >> %logs%
net stop msiserver
echo %date% %time% : Stopped service: msiserver                         >> %logs%
net stop cryptsvc
echo %date% %time% : Stopped service: cryptsvc                          >> %logs%
net stop appidsvc
echo %date% %time% : Stopped service: appidsvc                          >> %logs%
regsvr32.exe /s atl.dll
echo %date% %time% : Registered atl.dll silently                         >> %logs%
regsvr32.exe /s urlmon.dll
echo %date% %time% : Registered urlmon.dll silently                      >> %logs%
regsvr32.exe /s mshtml.dll
echo %date% %time% : Registered mshtml.dll silently                      >> %logs%
if /i %autoclean% == 2 goto netdns
timeout /t 5


:mnetdns
echo.                                                           >> %logs%
echo ====================== :MNETDNS ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mnetdns label                          >> %logs%
cls
echo Do you want to flush DNS and reset IP - IPCONFIG and NETSH?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mnetdns "%choice%"                              >> %logs%
if /i "%choice%"=="1" goto netdns
if /i "%choice%"=="2" goto mdism
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mnetdns                          >> %logs%
timeout /t 5
goto mnetdns

:netdns
echo.                                                           >> %logs%
echo ====================== :NETDNS ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :netdns label                           >> %logs%
call :L "%cStep%" "NETWORK - DNS flush + TCP tuning (Winsock/IP reset is manual-only)..."
ipconfig /flushdns
echo %date% %time% : Executed ipconfig /flushdns                      >> %logs%
if /i "%autoclean%"=="2" goto netdns_tcp
netsh int ip reset
echo %date% %time% : Executed netsh int ip reset                      >> %logs%
netsh winsock reset
echo %date% %time% : Executed netsh winsock reset                     >> %logs%
netsh winsock reset proxy
echo %date% %time% : Executed netsh winsock reset proxy               >> %logs%
:netdns_tcp
:: --- TCP/IP performance tuning ---
call :L "%cInfo%" "Re-asserting good TCP defaults (autotuning normal / rss on / heuristics off)"
netsh int tcp set global autotuninglevel=normal
netsh int tcp set heuristics disabled
netsh int tcp set global rss=enabled
echo %date% %time% : Re-applied TCP good defaults (autotuning/rss/heuristics, ECN left default)  >> %logs%
if /i %autoclean% == 2 goto dism
timeout /t 5


:mdism
echo.                                                           >> %logs%
echo ====================== :MDISM ======================        >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdism label                            >> %logs%
cls
echo Do you want to DISM the Windows image and correct problems?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mdism "%choice%"                              >> %logs%
if /i "%choice%"=="1" goto dism
if /i "%choice%"=="2" goto msfc
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mdism                            >> %logs%
timeout /t 5
goto mdism

:dism
echo.                                                           >> %logs%
echo ====================== :DISM ======================        >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :dism label                               >> %logs%
call :L "%cStep%" "DISM - repairing the Windows component store..."
dism /Online /Cleanup-Image /AnalyzeComponentStore
>>%logs% echo %date% %time% : DISM AnalyzeComponentStore exit=%errorlevel%
dism /Online /Cleanup-image /ScanHealth
echo %date% %time% : Executed DISM /ScanHealth                         >> %logs%
dism /Online /Cleanup-image /CheckHealth
echo %date% %time% : Executed DISM /CheckHealth                        >> %logs%
dism /Online /Cleanup-image /RestoreHealth
>>%logs% echo %date% %time% : DISM RestoreHealth exit=%errorlevel%
echo %date% %time% : Executed DISM /RestoreHealth                      >> %logs%
dism /Online /Cleanup-image /StartComponentCleanup
echo %date% %time% : Executed DISM /StartComponentCleanup (no /ResetBase) >> %logs%
if /i %autoclean% == 2 goto sfc
timeout /t 5


:msfc
echo.                                                           >> %logs%
echo ====================== :MSFC ======================        >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :msfc label                               >> %logs%
cls
echo Do you want to run SFC to verify system file integrity and fix problems?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-msfc "%choice%"                              >> %logs%
if /i "%choice%"=="1" goto sfc
if /i "%choice%"=="2" goto mwupdate
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :msfc                            >> %logs%
timeout /t 5
goto msfc

:sfc
echo.                                                           >> %logs%
echo ====================== :SFC ======================         >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :sfc label                                >> %logs%
call :L "%cStep%" "SFC - verifying system file integrity..."
sfc /scannow
>>%logs% echo %date% %time% : SFC exit=%errorlevel%
echo %date% %time% : Executed SFC /scannow                             >> %logs%
if /i %autoclean% == 2 goto wupdate
timeout /t 5


:mwupdate
echo.                                                           >> %logs%
echo ====================== :MWUPDATE ======================     >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mwupdate label                          >> %logs%
cls
echo Do you want to update Windows - USOCLIENT?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mwupdate "%choice%"                          >> %logs%
if /i "%choice%"=="1" goto wupdate
if /i "%choice%"=="2" goto mclean
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mwupdate                        >> %logs%
timeout /t 5
goto mwupdate

:wupdate
echo.                                                           >> %logs%
echo ====================== :WUPDATE ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :wupdate label                           >> %logs%
call :L "%cStep%" "WINDOWS UPDATE - scanning and installing updates..."
usoclient scaninstallwait
echo %date% %time% : Executed usoclient scaninstallwait (scan+download+install) >> %logs%
if /i %autoclean% == 1 goto delete
if /i %autoclean% == 2 goto delete
timeout /t 5


:mclean
echo.                                                           >> %logs%
echo ====================== :MCLEAN ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mclean label                            >> %logs%
cls
echo Execute clean disk - CLEANMGR?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mclean "%choice%"                            >> %logs%
if /i "%choice%"=="1" goto clean
if /i "%choice%"=="2" goto mdelete
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mclean                            >> %logs%
timeout /t 5
goto mclean

:clean
echo.                                                           >> %logs%
echo ====================== :CLEAN ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :clean label                            >> %logs%
call :L "%cStep%" "Disk Cleanup - explicit allow-list, no GUI, no /verylowdisk"
set "VC=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

:: Why this replaced /sageset:65535 + /sagerun:65535 + /verylowdisk:
::  - cleanmgr profile numbers are 4 digits. 65535 silently became 6553, and
::    that profile ended up with Recycle Bin, User file versions (File History),
::    both dump handlers and Update Cleanup ENABLED. So every run emptied the
::    bin on every drive and shredded BSOD dumps - the exact things the manual
::    cleanup above deliberately refuses to touch.
::  - /verylowdisk runs EVERY registered handler, third-party ones included,
::    with no prompt and no record of what it removed.
:: Now: wipe the legacy profiles, write an explicit allow-list, run that.
call :L "%cWarn%" "Clearing the old profile (it had Recycle Bin + File History ON)"
for /f "delims=" %%K in ('reg query "%VC%" 2^>nul') do (
    reg delete "%%K" /v StateFlags6553  /f >nul 2>&1
    reg delete "%%K" /v StateFlags65535 /f >nul 2>&1
)

:: ENABLE - caches, temp, shaders and logs only.
:: Explicit literals, never a loop over the key: enumerating and setting 2 would
:: also arm DownloadsFolder, which deletes the user's Downloads with no age gate.
for %%H in (
 "Active Setup Temp Folders"
 "D3D Shader Cache"
 "Delivery Optimization Files"
 "Diagnostic Data Viewer database files"
 "Downloaded Program Files"
 "Feedback Hub Archive log files"
 "Internet Cache Files"
 "RetailDemo Offline Content"
 "Setup Log Files"
 "Temporary Files"
 "Thumbnail Cache"
 "Windows Defender"
 "Windows Error Reporting Files"
 "Windows Upgrade Log Files"
 "Recycle Bin"
 "System error memory dump files"
 "System error minidump files"
) do reg query "%VC%\%%~H" >nul 2>&1 && reg add "%VC%\%%~H" /v StateFlags0064 /t REG_DWORD /d 2 /f >nul 2>&1

:: DISABLE - re-asserted explicitly rather than left to chance.
for %%H in (
 "BranchCache"
 "Content Indexer Cleaner"
 "Device Driver Packages"
 "DownloadsFolder"
 "Language Pack"
 "Old ChkDsk Files"
 "Previous Installations"
 "Temporary Setup Files"
 "Update Cleanup"
 "Upgrade Discarded Files"
 "User file versions"
 "Windows ESD installation files"
) do reg query "%VC%\%%~H" >nul 2>&1 && reg add "%VC%\%%~H" /v StateFlags0064 /t REG_DWORD /d 0 /f >nul 2>&1
echo %date% %time% : Wrote StateFlags0064 allow-list (14 on / 15 off) >> %logs%

:: /sagerun walks every drive, so a dead SMB mapping can stall it. Hard 10 min cap.
start "" cleanmgr /sagerun:64
set /a CMW=0
:clean_wait
timeout /t 5 /nobreak >nul
set /a CMW+=5
tasklist /fi "imagename eq cleanmgr.exe" /nh 2>nul | findstr /i "cleanmgr.exe" >nul 2>&1 || goto clean_done
if %CMW% GEQ 600 (
    taskkill /f /im cleanmgr.exe >nul 2>&1
    call :L "%cWarn%" "cleanmgr exceeded 10 min - stopped. A disconnected network drive is the usual cause."
    echo %date% %time% : cleanmgr /sagerun:64 TIMED OUT after 600s   >> %logs%
    goto clean_wsl
)
goto clean_wait
:clean_done
call :L "%cOK%" "Disk Cleanup finished (profile 0064)"
echo %date% %time% : cleanmgr /sagerun:64 completed in %CMW%s        >> %logs%


:clean_wsl
echo.                                                           >> %logs%
echo ====================== :CLEAN_WSL ====================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :clean_wsl label                     >> %logs%
echo.
call :L "%cStep%" "WSL and Docker - compacting virtual disks, this can take several minutes..."
echo  Compacting WSL / Docker virtual disks...
echo  ^(Docker Desktop and WSL are closed first - this can take several minutes^)
echo.

:: 1) Ask Docker Desktop to quit cleanly, then wait until it has fully stopped
echo %date% %time% : Asking Docker Desktop to quit (clean)         >> %logs%
set "WSL_UTF8=1"
if exist "%DOCKER_EXE%" (
    echo  Asking Docker Desktop to quit cleanly...
    "%DOCKER_EXE%" -quit
) else (
    echo  Docker Desktop.exe not found, relying on wsl --shutdown only.
    echo %date% %time% : Docker Desktop.exe not found                 >> %logs%
)

:: Wait (max 120s) until the docker-desktop WSL distro AND backend have stopped
set /a wsl_wait=0
:clean_wsl_waitloop
set "DOCKER_UP="
wsl --list --running 2>nul | findstr /i "docker-desktop" >nul 2>&1 && set "DOCKER_UP=1"
tasklist /fi "imagename eq com.docker.backend.exe" 2>nul | findstr /i "com.docker.backend.exe" >nul 2>&1 && set "DOCKER_UP=1"
if not defined DOCKER_UP goto clean_wsl_stopped
if %wsl_wait% GEQ 120 goto clean_wsl_forcekill
echo   Docker is shutting down cleanly... (%wsl_wait%s / 120s max)
timeout /t 3 /nobreak >nul
set /a wsl_wait+=3
goto clean_wsl_waitloop

:clean_wsl_forcekill
echo  Clean shutdown timed out, forcing Docker processes to stop...
echo %date% %time% : Docker clean-stop timeout, forcing kill          >> %logs%
taskkill /f /im "Docker Desktop.exe" /t        >nul 2>&1
taskkill /f /im "com.docker.backend.exe" /t    >nul 2>&1
taskkill /f /im "com.docker.build.exe" /t      >nul 2>&1
taskkill /f /im "com.docker.cli.exe" /t        >nul 2>&1
taskkill /f /im "vpnkit.exe" /t                >nul 2>&1

:clean_wsl_stopped
echo  Docker stopped. Shutting down WSL to release the disks...
echo %date% %time% : Docker stopped, shutting down WSL                 >> %logs%
wsl --shutdown >nul 2>&1
timeout /t 5 /nobreak >nul

:: 2) Build the list of .vhdx to compact (Docker data disk + WSL distro ext4.vhdx)
del /f /q "%TEMP%\opty_vhdx.lst" >nul 2>&1
if exist "%WSL_DOCKER_VHDX%" >>"%TEMP%\opty_vhdx.lst" echo %WSL_DOCKER_VHDX%
for /f "delims=" %%V in ('dir /b /s "%WSL_SEARCH1%\ext4.vhdx" 2^>nul') do >>"%TEMP%\opty_vhdx.lst" echo %%V
for /f "delims=" %%V in ('dir /b /s "%WSL_SEARCH2%\ext4.vhdx" 2^>nul') do >>"%TEMP%\opty_vhdx.lst" echo %%V

:: 3) Compact each disk via diskpart: select / attach readonly / compact / detach
if not exist "%TEMP%\opty_vhdx.lst" (
    echo  No WSL / Docker virtual disk found, skipping.
    echo %date% %time% : No vhdx found to compact                  >> %logs%
) else (
    for /f "usebackq delims=" %%F in ("%TEMP%\opty_vhdx.lst") do (
        echo  -^> %%F
        echo %date% %time% : Compacting "%%F"                      >> %logs%
        >"%TEMP%\opty_diskpart.txt"  echo select vdisk file="%%F"
        >>"%TEMP%\opty_diskpart.txt" echo attach vdisk readonly
        >>"%TEMP%\opty_diskpart.txt" echo compact vdisk
        >>"%TEMP%\opty_diskpart.txt" echo detach vdisk
        >>"%TEMP%\opty_diskpart.txt" echo exit
        diskpart /s "%TEMP%\opty_diskpart.txt"
        echo %date% %time% : Compaction done "%%F"                 >> %logs%
    )
    del /f /q "%TEMP%\opty_diskpart.txt" >nul 2>&1
    del /f /q "%TEMP%\opty_vhdx.lst"     >nul 2>&1
)
echo %date% %time% : WSL/Docker vhdx compaction done               >> %logs%

if /i %autoclean% == 2 goto defrag
timeout /t 5


:mdelete
echo.                                                           >> %logs%
echo ====================== :MDELETE ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdelete label                          >> %logs%
cls
echo Do you want to delete temporary files - DEL?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mdelete "%choice%"                            >> %logs%
if /i "%choice%"=="1" goto delete
if /i "%choice%"=="2" goto mdefrag
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mdelete                          >> %logs%
timeout /t 5
goto mdelete

:delete
echo.                                                           >> %logs%
echo ====================== :DELETE ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :delete label                           >> %logs%

call :L "%cStep%" "CLEANUP - deleting temp files, caches, logs and dumps..."
call :L "%cInfo%" "Enabling Storage Sense (native automatic maintenance)"
:: NOT set: the HKLM StorageSense policy. It greys out the Storage Sense
:: toggle in Settings with "managed by your organization". The HKCU values
:: below do the same job while leaving the user in control.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t REG_DWORD /d 30 /f >nul
:: --- Windows Update download cache ---
echo %date% %time% : Stopping wuauserv service                       >> %logs%
net stop wuauserv >nul 2>&1
echo %date% %time% : Deleting Windows Update Cache files              >> %logs%
del /S /F /Q "C:\Windows\SoftwareDistribution\Download\*"
echo %date% %time% : Restarting wuauserv service                      >> %logs%
net start wuauserv >nul 2>&1

:: --- Per-drive junk, on every FIXED drive ---
:: Windows drops DeliveryOptimization / WUDownloadCache and upgrade staging
:: folders on whichever volume it picked, not always C:. Network drives are
:: excluded - several of the mapped shares here are disconnected and each one
:: would cost a 30 s timeout.
call :L "%cInfo%" "Sweeping per-drive junk on every fixed drive"
call :fixeddrives
for %%D in (%FIXEDLIST%) do call :drivesweep %%D
echo %date% %time% : Fixed drives swept:%FIXEDLIST%                  >> %logs%

:: --- Temp (system + all users Local\Temp as in your model) ---
echo %date% %time% : Deleting Windows Temp folder                     >> %logs%
del /S /F /Q "%WINDIR%\Temp\*"

echo %date% %time% : Deleting user Temp files                         >> %logs%
setlocal
for /D %%i in ("C:\Users\*") do (
   echo %date% %time% : Deleting Temp in %%i\AppData\Local\Temp        >> %logs%
   del /S /F /Q "%%i\AppData\Local\Temp\*"
)
endlocal

:: --- GPU / shader caches ---
:: Kept on purpose. These rot: a corrupted shader cache is a classic cause of
:: artifacts, stutter and launch failures, and clearing it is the standard fix.
:: Rebuild cost is seconds to a couple of minutes of first-run compilation, so
:: it is well worth doing periodically.
call :L "%cInfo%" "Clearing GPU shader caches (rebuild in seconds, prevents corruption bugs)"
:: Contents only - never rd these folders. If DxCache/OglCache/VkCache are
:: absent, some AMD driver builds fail to recreate them and you get permanent
:: stutter instead of a one-off recompile.
:: AMD's OpenGL cache is OglCache; GLCache is the NVIDIA name and does not
:: exist on an AMD install - the old GLCache-only line was a silent no-op.
del /S /F /Q "%LOCALAPPDATA%\AMD\DxCache\*"                        >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\AMD\DxcCache\*"                       >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\AMD\DX9Cache\*"                       >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\AMD\OglCache\*"                       >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\AMD\VkCache\*"                        >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\AMD\cl.cache\*"                       >nul 2>&1
del /S /F /Q "%USERPROFILE%\AppData\LocalLow\AMD\DxCache\*"        >nul 2>&1
:: Adrenalin's Qt UI cache - version-stamped, accumulates, and a stale one is
:: why the panel comes up blank after a driver update.
del /S /F /Q "%LOCALAPPDATA%\AMD\Radeonsoftware\cache\*"           >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\AMD\AMDRSSrcExt\cache\*"              >nul 2>&1
:: NVIDIA / Intel - dead branches on this machine, kept for portability
del /S /F /Q "%LOCALAPPDATA%\NVIDIA\GLCache\*"                     >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\NVIDIA\DXCache\*"                     >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\NVIDIA\ComputeCache\*"                >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\NVIDIA\OptixCache\*"                  >nul 2>&1
del /S /F /Q "%ProgramData%\NVIDIA Corporation\NV_Cache\*"         >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\Intel\ShaderCache\*"                  >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\D3DSCache\*"                          >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\Microsoft\DirectX Shader Cache\*"     >nul 2>&1
echo %date% %time% : Cleared GPU/shader caches                      >> %logs%

:: --- NOT cleared: DaVinci Resolve and Adobe media caches ---
:: These are the one category that fails the test: re-conforming audio and
:: re-rendering optimized media/peak files is hours of work on a real project,
:: not a few seconds of shader compilation. They live in the opt-in purge.

:: --- Dumps (facultatif mais sans impact sur réglages) ---
echo %date% %time% : MiniDump kept (crash forensics)                     >> %logs%
:: Crash dumps: deleted on the maintainer's explicit instruction. Note this
:: loses the only forensic record of a BSOD or GPU driver crash.
call :L "%cInfo%" "Deleting crash dumps"
del /F /S /Q "%SystemRoot%\Minidump\*" >nul 2>&1
echo %date% %time% : Deleting Memory Dump file                           >> %logs%
del /F /S /Q "%SystemRoot%\MEMORY.DMP"

:: --- REMOVED: Edge WebView2 caches ---
:: Same class as a browser cache. Every WebView2-hosted app (new Teams, Office
:: add-ins, several game launchers) re-downloads and re-compiles afterwards.

:: Recycle Bin: emptied on the maintainer's explicit instruction. The cleanmgr
:: handler above covers it properly via the shell API; this pass catches the
:: other volumes. FIXED drives only - a disconnected SMB mapping would stall.
call :L "%cInfo%" "Emptying the Recycle Bin on every fixed drive"
for %%D in (%FIXEDLIST%) do if exist "%%D:\$Recycle.Bin" rd /S /Q "%%D:\$Recycle.Bin" >nul 2>&1

:: --- Thumbnail & icon cache (rebuilt automatically; locked files are skipped) ---
echo %date% %time% : Deleting icon cache (thumbnails kept)          >> %logs%
:: thumbcache kept: Explorer visibly re-generates every thumbnail afterwards,
:: painful in large footage folders. iconcache is cheap so it stays.
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Windows\Explorer\iconcache_*.db" 2>nul

:: --- Windows Error Reporting reports + crash dumps ---
echo %date% %time% : Deleting WER reports and crash dumps           >> %logs%
del /F /S /Q "%ProgramData%\Microsoft\Windows\WER\*" 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Windows\WER\*" 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\CrashDumps\*" 2>nul

:: --- Unbounded log/telemetry files: the real invisible wins ---
:: These are append-only and nothing ever prunes them. Measured on this machine
:: when the rule was written: AMD PPC 317 MB, WMI ETL 228 MB, CbsPersist 93 MB,
:: USOShared 86 MB. All of it is pure log, regenerated on demand, and none of it
:: is ever read by the user.
call :L "%cInfo%" "Clearing unbounded log/trace files (AMD PPC, ETL traces, servicing logs)"
:: AMD Adrenalin usage telemetry - append-only, documented at 30+ GB on some
:: systems. Keep the folder and config.csv; only the growing CSVs go.
del /F /Q "%LOCALAPPDATA%\AMD\PPC\sdkusage.csv"              >nul 2>&1
del /F /Q "%LOCALAPPDATA%\AMD\PPC\apprecord.csv"             >nul 2>&1
del /F /Q "%LOCALAPPDATA%\AMD\PPC\driverworkloadstats.csv"   >nul 2>&1
del /F /Q "%LOCALAPPDATA%\AMD\CN\RSX_*.log*"                 >nul 2>&1
:: Stale ETL traces. Per-file only - never rd the WMI or RtBackup folders.
del /F /Q "%WINDIR%\System32\LogFiles\WMI\*.etl.*"           >nul 2>&1
del /F /Q "%ProgramData%\Microsoft\Diagnosis\ETLLogs\AutoLogger\*.etl" >nul 2>&1
:: Update-orchestrator logs. Never touch USOPrivate\UpdateStore.
del /F /S /Q "%ProgramData%\USOShared\Logs\*.etl"            >nul 2>&1
:: Assorted servicing logs
del /F /Q "%WINDIR%\Logs\DISM\dism.log"                      >nul 2>&1
del /F /S /Q "%WINDIR%\Logs\waasmedic\*"                     >nul 2>&1
del /F /S /Q "%WINDIR%\Logs\SIH\*"                            >nul 2>&1
del /F /S /Q "%WINDIR%\Logs\NetSetup\*"                       >nul 2>&1
del /F /S /Q "%WINDIR%\Logs\WindowsUpdate\*.etl"              >nul 2>&1
:: Two named files only - %WINDIR%\inf otherwise holds the real driver INFs
del /F /Q "%WINDIR%\inf\setupapi.dev.log"                     >nul 2>&1
del /F /Q "%WINDIR%\inf\setupapi.app.log"                     >nul 2>&1
del /F /Q "%WINDIR%\debug\wiatrace.log"                       >nul 2>&1
echo %date% %time% : Cleared unbounded log/trace files              >> %logs%

:: --- Old servicing / setup logs (CBS, Panther) ---
echo %date% %time% : Deleting CBS and Panther logs                  >> %logs%
del /F /Q "%WINDIR%\Logs\CBS\CbsPersist_*.log" >nul 2>&1
del /F /Q "%WINDIR%\Logs\CBS\CbsPersist_*.cab" >nul 2>&1
del /F /S /Q "%WINDIR%\Panther\*" 2>nul

:: --- Legacy IE/Edge system web cache (INetCache) ---
echo %date% %time% : Deleting INetCache                             >> %logs%
:: INetCache left alone: shared WinINET cache used by Office, the Store and
:: installers, and it stages Outlook attachments that may be open.

:: --- GPU driver extraction leftovers (NOT the installed drivers) ---
echo %date% %time% : Deleting driver extraction folders            >> %logs%
rd /S /Q "C:\NVIDIA" 2>nul
:: C:\AMD kept: extracted chipset/driver installer - the fallback copy of a
:: known-good AMD package.
del /F /S /Q "C:\Intel\GfxCPLBatchFiles\*" >nul 2>&1
del /F /S /Q "C:\Intel\Logs\*"            >nul 2>&1

:: --- Chromium browser caches: EVERY profile, browser left running ---
:: A rotten HTTP/code cache is a well-known cause of broken pages, stale assets
:: and renderer crashes, and clearing it is the standard fix. It rebuilds
:: itself as you browse, so it is worth doing periodically.
:: Two deliberate choices:
::   - no taskkill: closing the user's tabs to clean a cache is not acceptable.
::     Files the running browser holds open are simply skipped.
::   - every profile is enumerated (Default, "Profile 1", "Profile 2", ...)
::     instead of hardcoding Default - this machine has two.
:: Never touched: Cookies, Login Data, Web Data, History, Bookmarks,
:: Local Storage, IndexedDB - those are user data, not cache.
call :L "%cInfo%" "Clearing browser caches - every user and profile; running browsers are skipped, never closed"
:: Every Windows user, not just the one running the script, and every browser
:: family - including ones not installed here, which cost nothing to probe.
for /d %%U in ("%SystemDrive%\Users\*") do call :userclean "%%~fU"
:: WebView2 shares the Chromium cache layout and rots the same way
del /S /F /Q "%LOCALAPPDATA%\Microsoft\EdgeWebView\Cache\*"        >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\Microsoft\EdgeWebView\User Data\Default\Cache\*"      >nul 2>&1
del /S /F /Q "%LOCALAPPDATA%\Microsoft\EdgeWebView\User Data\Default\Code Cache\*" >nul 2>&1
:delete_skip_apps

:: --- Windows.old (removes rollback): FULL mode only ---
if not "%autoclean%"=="2" goto delete_skip_winold
if exist "%SystemDrive%\Windows.old" (
    echo %date% %time% : Removing Windows.old previous installation  >> %logs%
    takeown /F "%SystemDrive%\Windows.old" /R /A /D Y               >nul 2>&1
    icacls "%SystemDrive%\Windows.old" /grant administrators:F /T /C >nul 2>&1
    rd /S /Q "%SystemDrive%\Windows.old" 2>nul
)
:delete_skip_winold

:: --- Discord: Electron caches (rebuild on next launch, classic fix for a
:: stuck/blank client). Its logins live in Local Storage, which is untouched.
:: Same guard as the browsers: deleting the unlocked data_* blocks while the
:: memory-mapped index survives is exactly what produces the grey / infinite
:: loading Discord screen this is supposed to prevent.
call :isrunning "Discord.exe"
if defined RUNNING (
    call :L "%cWarn%" "  Discord is running - caches skipped, close it and re-run"
) else (
    call :L "%cInfo%" "Clearing Discord caches (classic fix for a stuck client)"
    del /F /S /Q "%APPDATA%\discord\Cache\Cache_Data\*"    >nul 2>&1
    del /F /S /Q "%APPDATA%\discord\Code Cache\*"          >nul 2>&1
    del /F /S /Q "%APPDATA%\discord\GPUCache\*"            >nul 2>&1
)

:: --- NOT cleared ---
:: Spotify Storage/Data: that is the OFFLINE MUSIC cache. Clearing it forces a
:: multi-GB re-download of everything saved for offline listening.
:: Teams LocalCache: known to sign the user out of the new Teams client.

call :L "%cInfo%" "Cleaning game launcher caches (Steam / Ubisoft / EA / Origin / Epic)"
:: Steam: logs and crash dumps only - both invisible and genuinely useless.
:: NOT steamapps\shadercache: wiping it guarantees shader re-compilation
:: stutter, and the registry InstallPath only covers the C: library anyway
:: (the real libraries are on D:/E: here), so it was harmful AND incomplete.
:: NOT depotcache: those .manifest files are what avoid a full re-download
:: when Steam verifies files.
set "STEAMPATH="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul ^| findstr /i "InstallPath"') do set "STEAMPATH=%%b"
if not defined STEAMPATH goto delete_skip_steam
del /F /S /Q "%STEAMPATH%\logs\*"                >nul 2>&1
del /F /S /Q "%STEAMPATH%\dumps\*"               >nul 2>&1
:delete_skip_steam
:: Steam's web cache moved out of SteamRoot - it is now under LOCALAPPDATA
:: (141 MB here). Stale guides still point at SteamRoot\htmlcache, which no
:: longer exists. Only touched when Steam is closed.
call :isrunning "steam.exe"
if not defined RUNNING del /F /S /Q "%LOCALAPPDATA%\Steam\htmlcache\*" >nul 2>&1
set "STEAMPATH="
:: Launcher caches - each one guarded, for the same reason as Discord: a
:: half-deleted cache under a running client is worse than not cleaning at all.
call :isrunning "upc.exe"
if not defined RUNNING (
    del /F /S /Q "%USERHOME%\AppData\Local\Ubisoft Game Launcher\cache\*"        >nul 2>&1
    del /F /S /Q "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\cache\*"  >nul 2>&1
) else ( call :L "%cWarn%" "  Ubisoft Connect is running - skipped" )
call :isrunning "EADesktop.exe"
if not defined RUNNING (
    del /F /S /Q "%USERHOME%\AppData\Local\Electronic Arts\EA Desktop\cache\*"   >nul 2>&1
    del /F /S /Q "%ProgramData%\EA Core\cache\*"                                 >nul 2>&1
) else ( call :L "%cWarn%" "  EA App is running - skipped" )
:: Origin (legacy): ONLY the cache/log subfolders. Never the folder itself -
:: %ProgramData%\Origin\LocalContent holds game entitlement data and wiping it
:: can stop games from launching.
del /F /S /Q "%USERHOME%\AppData\Local\Origin\Logs\*"                        >nul 2>&1
del /F /S /Q "%USERHOME%\AppData\Roaming\Origin\Logs\*"                      >nul 2>&1
del /F /S /Q "%ProgramData%\Origin\Logs\*"                                   >nul 2>&1
call :isrunning "EpicGamesLauncher.exe"
if not defined RUNNING (
    for /d %%W in ("%USERHOME%\AppData\Local\EpicGamesLauncher\Saved\webcache*") do rd /S /Q "%%W" >nul 2>&1
    del /F /S /Q "%USERHOME%\AppData\Local\EpicGamesLauncher\Saved\Logs\*"   >nul 2>&1
) else ( call :L "%cWarn%" "  Epic Games Launcher is running - skipped" )

:: --- REMOVED: Adobe Common Media Cache ---
:: Deleting it forces Premiere/After Effects to re-conform audio and re-render
:: peak files for every project. Same reasoning as the DaVinci cache:
:: expensive to regenerate, and very much visible to the user.

call :L "%cInfo%" "Clearing font cache (Prefetch left intact - it speeds up app launches)"
net stop FontCache >nul 2>&1
del /F /S /Q "%WINDIR%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" 2>nul
del /F /Q "%WINDIR%\System32\FNTCACHE.DAT" 2>nul
net start FontCache >nul 2>&1

:: --- REMOVED: restore-point trimming ---
:: This was actively dangerous. OPTY creates a restore point at the start of a
:: run and then changes the registry, services and drivers. Trimming down to
:: "the most recent" point deletes the older, KNOWN-GOOD points and keeps the
:: one created moments before the changes - i.e. it destroys the rollback for
:: OPTY's own work. It also contradicts SystemRestorePointCreationFrequency=0
:: set elsewhere in this file, and Windows already expires shadow copies on its
:: own. Restore points are a safety net; a maintenance tool does not delete them.
:delete_skip_vss

echo %date% %time% : :delete done                                        >> %logs%

if /i %autoclean% == 1 goto mshutdownreboot
if /i %autoclean% == 2 goto clean
timeout /t 5


:mdefrag
echo.                                                           >> %logs%
echo ====================== :MDEFRAG ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdefrag label                          >> %logs%
cls
echo Do you want to defragment HDD or optimize SSD - DEFRAG?
set "choice="
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mdefrag "%choice%"                            >> %logs%
if /i "%choice%"=="1" goto defrag
if /i "%choice%"=="2" goto mchkdsk
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mdefrag                          >> %logs%
timeout /t 5
goto mdefrag

:defrag
echo.                                                           >> %logs%
echo ====================== :DEFRAG ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :defrag.label                           >> %logs%
call :L "%cStep%" "DEFRAG - optimizing all volumes..."
defrag /C /O /U /V /H
>>%logs% echo %date% %time% : DEFRAG exit=%errorlevel%
echo %date% %time% : Executed defrag /C /O /U /V /H                 >> %logs%
if /i %autoclean% == 2 goto endready
timeout /t 5


:mchkdsk
echo.                                                           >> %logs%
echo ====================== :MCHKDSK ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mchkdsk label                          >> %logs%
cls
echo Check drive integrity - CHKDSK?
echo   1. Online scan (SSD-safe, no reboot)
echo   2. Full /f /r (HDD only - locks the volume, schedules a reboot)
echo   3. Skip
set "choice="
set /p choice= Enter action:
echo %date% %time% : Opti-mchkdsk "%choice%"                            >> %logs%
if /i "%choice%"=="1" goto chkdsk
if /i "%choice%"=="2" goto chkdsk_full
if /i "%choice%"=="3" goto mshutdownreboot
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mchkdsk                          >> %logs%
timeout /t 5
goto mchkdsk

:chkdsk
echo.                                                           >> %logs%
echo ====================== :CHKDSK ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :chkdsk label                           >> %logs%
call :L "%cStep%" "CHKDSK - online integrity scan (SSD-safe, no reboot)..."
chkdsk %SystemDrive% /scan
>>%logs% echo %date% %time% : CHKDSK /scan exit=%errorlevel%
echo %date% %time% : Executed chkdsk /scan                         >> %logs%
if /i %autoclean% == 2 goto endready
timeout /t 5
goto endready


:chkdsk_full
echo.                                                           >> %logs%
echo ====================== :CHKDSK_FULL ====================== >> %logs%
echo %date% %time% : Entered :chkdsk_full label                    >> %logs%
call :L "%cWarn%" "CHKDSK /f /r - full repair, locks the volume and schedules a reboot..."
CHKDSK /f /r
>>%logs% echo %date% %time% : CHKDSK /f /r exit=%errorlevel%
echo %date% %time% : Executed CHKDSK /f /r                         >> %logs%
timeout /t 5


:endready
echo.                                                           >> %logs%
echo ====================== :ENDREADY ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :endready label                         >> %logs%
net start bits
echo %date% %time% : Started service: bits                             >> %logs%
net start wuauserv
echo %date% %time% : Started service: wuauserv                          >> %logs%
net start msiserver
echo %date% %time% : Started service: msiserver                          >> %logs%
net start cryptsvc
echo %date% %time% : Started service: cryptsvc                           >> %logs%
net start appidsvc
echo %date% %time% : Started service: appidsvc                           >> %logs%
if /i %autoclean% == 2 goto mshutdownreboot
timeout /t 5


:mshutdownreboot
echo.                                                           >> %logs%
echo ====================== :MSHUTDOWNREBOOT ================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mshutdownreboot label                  >> %logs%
cls
:: --- Disk space freed report (before/after) ---
color 0F
call :get_free_mb "%SystemDrive%"
set "FREE_AFTER=%FREE_MB%"
:: FREE_BEFORE is only captured when entering :mopti. Reaching this screen from
:: the guided-repair path meant comparing against 0 and reporting the whole
:: drive as "freed" - a several-hundred-GB fiction. Skip the report instead.
if not defined FREE_BEFORE goto skip_disk_report
if "%FREE_BEFORE%"=="0" goto skip_disk_report
set /a FREED=FREE_AFTER-FREE_BEFORE
set /a FREED_GB=FREED/1024
set /a "FREED_DEC=(FREED*10/1024) %% 10"
if %FREED_DEC% LSS 0 set "FREED_DEC=0"
echo(
echo(%cT%===============================================================%cR%
echo(%cT%    OPTY v%current_version%  -  Disk space report  (drive %SystemDrive%)%cR%
echo(%cT%===============================================================%cR%
echo(    Free before : %cVal%%FREE_BEFORE%%cR% MB
echo(    Free after  : %cVal%%FREE_AFTER%%cR% MB
echo(    %cOK%Total freed : %FREED% MB   ^(%FREED_GB%.%FREED_DEC% GB^)%cR%
echo(%cT%===============================================================%cR%
echo(
>>%logs% echo %date% %time% : DISK REPORT %SystemDrive% before=%FREE_BEFORE%MB after=%FREE_AFTER%MB freed=%FREED%MB approx=%FREED_GB%GB
timeout /t 6 /nobreak >nul
:skip_disk_report

if /i %autoshutdownreboot% == 0 goto skipshutdownreboot
if /i %autoshutdownreboot% == 1 goto shutdown
if /i %autoshutdownreboot% == 2 goto reboot
if /i %autoshutdownreboot% == 5 goto mshutdownrebootfix


:mshutdownrebootfix
echo.                                                           >> %logs%
echo ====================== :MSHUTDOWNREBOOTFIX ================   >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mshutdownrebootfix label               >> %logs%
echo Do you want to restart/stop the computer?
set "choice="
set /p choice= R (Reboot) - S (Stop) - 0 (No)
echo %date% %time% : Opti-mshutdownrebootfix "%choice%"                   >> %logs%
if /i "%choice%"=="R" goto reboot
if /i "%choice%"=="S" goto shutdown
if /i "%choice%"=="0" goto menu
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mshutdownrebootfix                >> %logs%
timeout /t 5
goto mshutdownreboot

:shutdown
echo.                                                           >> %logs%
echo ====================== :SHUTDOWN ======================     >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :shutdown label                          >> %logs%
shutdown /s /f /t 15
echo %date% %time% : Executed shutdown /s /f /t 15                    >> %logs%
timeout /t 15
exit

:reboot
echo.                                                           >> %logs%
echo ====================== :REBOOT ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :reboot label                            >> %logs%
shutdown /r /f /t 15
echo %date% %time% : Executed shutdown /r /f /t 15                    >> %logs%
timeout /t 15
exit

:skipshutdownreboot
echo.                                                           >> %logs%
echo ====================== :SKIPSHUTDOWNREBOOT ================    >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :skipshutdownreboot label                >> %logs%
echo The computer will not restart.
pause
goto menu


:mreenable
echo.                                                           >> %logs%
echo ====================== :MREENABLE ======================     >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mreenable label                         >> %logs%
color F2
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo    Choose the option to re-enable:                            
echo.                                                  
echo.                                                  
echo.                                                  
echo   1. Start office update                                            
echo   2. Enable chrome update (if your company uses GPO [Register])      
echo   3. Enable windows update (if your company uses GPO [Register])    
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo   0. Menu                                                         
echo.                                                  
echo.                                                  
set "choice="
set /p choice= Enter action:
echo %date% %time% : ReEnable.bat-mreenable "%choice%"                     >> %logs%
if "%choice%"=="1" goto office_update
if "%choice%"=="2" goto enable_google_update
if "%choice%"=="3" goto enable_windows_update
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mreenable                        >> %logs%
timeout /t 5
goto mreenable


:office_update
echo.                                                           >> %logs%
echo ====================== :OFFICE_UPDATE ====================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :office_update label                    >> %logs%
cls
echo Microsoft Office update...
"C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user
echo %date% %time% : Launched OfficeC2RClient.exe /update user   >> %logs%
pause
goto mreenable


:enable_google_update
echo.                                                           >> %logs%
echo ====================== :ENABLE_GOOGLE_UPDATE ================= >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :enable_google_update label             >> %logs%
cls
:: Never force-close the browser. The HKLM policy write below does not need
:: Chrome closed at all; the old taskkill just destroyed the user's tabs.
call :isrunning "chrome.exe"
if defined RUNNING (
    call :L "%cWarn%" "Chrome is running. Close it yourself if you want, then press a key."
    call :L "%cInfo%" "OPTY never force-closes your browser."
    pause
)
echo %date% %time% : Chrome close requested, never force-killed     >> %logs%
cls
REG ADD "HKLM\SOFTWARE\Policies\Google\Update" /v "UpdateDefault" /t REG_DWORD /d 1 /f
echo %date% %time% : Set Google UpdateDefault=1                     >> %logs%
start chrome.exe
echo %date% %time% : Launched Chrome                                >> %logs%
echo.                                                  
echo Go to .../help/about.                                       
echo This launches the Update                                        
echo.                                                  
pause
goto mreenable


:enable_windows_update
echo.                                                           >> %logs%
echo ====================== :ENABLE_WINDOWS_UPDATE ============== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :enable_windows_update label          >> %logs%
cls
Net stop wuauserv
echo %date% %time% : Stopped service wuauserv                       >> %logs%
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 0 /f
echo %date% %time% : Set DisableWindowsUpdateAccess=0              >> %logs%
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d 0 /f
echo %date% %time% : Set SetDisableUXWUAccess=0                    >> %logs%
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer" /t REG_DWORD /d 0 /f
echo %date% %time% : Set UseWUServer=0                              >> %logs%
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 0 /f
echo %date% %time% : Set ExcludeWUDriversInQualityUpdate=0         >> %logs%
echo.                                                  
Net start wuauserv
echo %date% %time% : Started service wuauserv                        >> %logs%
pause
goto mreenable


:mregprofil
echo.                                                           >> %logs%
echo ====================== :MREGPROFIL ======================     >> %logs%
echo %date% %time% : Entered :mregprofil label                     >> %logs%
color 0D
cls
call :banner "SYSTEM & GAMING"
echo(
echo(     %cVal%1.%cR%  Gaming / Performance    %cInfo%MMCSS, Game Mode, power throttling, VBS%cR%
echo(     %cVal%2.%cR%  Services + power plan   %cInfo%trim services, GameDVR off, hibernation%cR%
echo(     %cVal%3.%cR%  Mouse                   %cInfo%true 1:1 - acceleration fully off%cR%
echo(
echo(     %cInfo%Debloat is menu 6, Display/GPU is menu 5, undo is menu 7.%cR%
echo(
echo(     %cVal%0.%cR%  Menu
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : mregprofil "%choice%"                         >> %logs%
if "%choice%"=="1" goto gaming_perf
if "%choice%"=="2" goto map_only
if "%choice%"=="3" goto mouseantilag
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
echo %date% %time% : Invalid option in :mregprofil                 >> %logs%
timeout /t 3 >nul
goto mregprofil

:gaming_perf
echo.                                                           >> %logs%
echo ====================== :GAMING_PERF ====================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :gaming_perf label                   >> %logs%
color FC
cls
call :L "%cStep%" "Applying Gaming / Performance tweaks (registry, power, network)..."

call :L "%cInfo%" "Foreground boost (MMCSS SystemProfile)"
:: MMCSS Tasks\Games GPU Priority / Priority / SFIO Priority are NOT written:
:: they are documented as unused or overridden when Scheduling Category=High,
:: and the values every guide tells you to write are already the defaults.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f >nul
:: 0x26 (38) is what "Adjust for best performance of: Programs" writes, but on a
:: client SKU it decodes to the same short/variable/foreground-boosted profile as
:: the shipped default 0x2, and no 2025/2026 measurement shows a frametime
:: difference. Writing it only made "restore defaults" have something to undo.
:: Left at the Windows default on purpose.

call :L "%cInfo%" "Game Mode ON (HAGS and MPO moved to menu 3 -> 5: Display tweaks)"
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Disabling CPU power throttling"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Re-asserting network defaults (throttling index 10, Nagle left alone)"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f >nul
:: TcpAckFrequency/TCPNoDelay removed: they do not affect UDP game traffic, they
:: double ACK count and reduce max download. Absence IS the Windows default.
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /b /i "HKEY"') do (
    reg delete "%%K" /v "TcpAckFrequency" /f >nul 2>&1
    reg delete "%%K" /v "TCPNoDelay" /f >nul 2>&1
)

call :L "%cInfo%" "Re-asserting good defaults: SSD TRIM on + system-managed pagefile (8.3 names off)"
fsutil behavior set disabledeletenotify 0 >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 1 /f >nul
fsutil behavior set disable8dot3 1 >nul

call :L "%cInfo%" "Faster startup apps at login"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul

call :L "%cInfo%" "USB selective suspend off (active power plan)"
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul
powercfg /setactive SCHEME_CURRENT >nul

call :L "%cInfo%" "Background apps + telemetry off"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul
:: REMOVED: LetAppsRunInBackground=2 (Force Deny). It is machine-scope and NOT
:: edition-gated, so on Pro it really does kill toasts and background sync for
:: every packaged app, and greys the per-app toggle with "managed by your
:: organization" - the exact banner this script says it refuses to cause.
:: AllowTelemetry=0 is Enterprise/Education only - on Pro it is clamped to 1
:: (Required), so claiming to set it would be a lie in the log. The scheduled
:: task disables are what actually reduce telemetry here.


call :L "%cInfo%" "Disabling telemetry scheduled tasks (Appraiser / CEIP / DmClient)"
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\StartupAppTask" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable >nul 2>&1

:: HVCI is the biggest security regression in this whole script, so it is the
:: one thing here that asks first instead of being bundled into "apply profile".
call :L "%cWarn%" "Disable Memory Integrity (HVCI)? It removes kernel code-integrity"
call :L "%cWarn%" "enforcement, and some anti-cheats (Vanguard, FACEIT) require it ON."
set "choice="
set /p choice= Disable HVCI? 1 (Yes) - 0 (No, keep it enabled):
if "%choice%"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul
    echo %date% %time% : HVCI/VBS disabled on explicit confirmation           >> %logs%
) else (
    call :L "%cOK%" "  HVCI left enabled"
    echo %date% %time% : HVCI left enabled                                    >> %logs%
)

call :L "%cOK%" "Gaming / Performance tweaks applied - a reboot is recommended (Memory Integrity)."
pause
goto menu

:gaming_restore
echo.                                                           >> %logs%
echo ====================== :GAMING_RESTORE =================== >> %logs%
echo %date% %time% : Entered :gaming_restore label                 >> %logs%
color FC
cls
call :L "%cStep%" "Restoring Windows defaults for the Gaming / Performance tweaks..."

call :L "%cInfo%" "Resetting game priority (MMCSS) + foreground boost to defaults"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 20 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 2 /f >nul

call :L "%cInfo%" "Re-enabling CPU power throttling (default)"
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /f >nul 2>&1

call :L "%cInfo%" "Restoring network defaults (throttling index + Nagle)"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 10 /f >nul
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /b /i "HKEY"') do (
    reg delete "%%K" /v "TcpAckFrequency" /f >nul 2>&1
    reg delete "%%K" /v "TCPNoDelay" /f >nul 2>&1
)

call :L "%cInfo%" "Restoring 8.3 short names (default)"
fsutil behavior set disable8dot3 2 >nul

call :L "%cInfo%" "Restoring login startup delay (default)"
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /f >nul 2>&1

call :L "%cInfo%" "Re-enabling USB selective suspend (default)"
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul
powercfg /setactive SCHEME_CURRENT >nul

call :L "%cInfo%" "Re-enabling background apps + telemetry (default)"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 0 /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /f >nul 2>&1

call :L "%cInfo%" "Restoring MPO (Multi-Plane Overlay) to default"
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayMinFPS" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "DisableOverlays" /f >nul 2>&1

call :L "%cInfo%" "Re-enabling telemetry scheduled tasks"
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\StartupAppTask" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Enable >nul 2>&1

call :L "%cInfo%" "Restoring Recall / Copilot / Consumer Features / Widgets"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /f >nul 2>&1
sc config WSAIFabricSvc start= demand >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Re-enabling VBS / Memory Integrity HVCI"
:: The Windows default for both is the value being ABSENT, not 1. Forcing 1 on
:: a machine whose hardware or drivers cannot support HVCI causes driver-load
:: failures, so the revert removes the override instead of asserting a value.
call :killkey "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled"
call :killkey "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity"

call :L "%cInfo%" "Restoring services + GameDVR + hibernation to Windows defaults (map_only undo)"
sc config SysMain start= auto >nul & sc start SysMain >nul 2>&1
sc config WSearch start= delayed-auto >nul & sc start WSearch >nul 2>&1
sc config Spooler start= auto >nul & sc start Spooler >nul 2>&1
sc config DPS start= auto >nul & sc start DPS >nul 2>&1
sc config WerSvc start= demand >nul
sc config TabletInputService start= demand >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 1 /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d 1 /f >nul
powercfg /h on >nul

call :L "%cInfo%" "Restoring ads / suggestions / Spotlight to Windows defaults"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 1 /f >nul
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /f >nul 2>&1

call :L "%cInfo%" "Restoring mouse defaults (Speed=1, T1=6, T2=10)"
reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f >nul
call :mousecurve
call :mouseapply

call :L "%cOK%" "All profile defaults restored (gaming + debloat + services + mouse)."
pause
goto menu


:debloat2026
echo.                                                           >> %logs%
echo ====================== :DEBLOAT2026 ====================== >> %logs%
echo %date% %time% : Entered :debloat2026 label                   >> %logs%
color FC
cls
call :L "%cStep%" "Debloat 2026 - disabling Recall, Copilot, sponsored apps and Widgets..."

call :L "%cInfo%" "Disabling Windows Recall (AI snapshots) - 24H2+"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul
sc stop WSAIFabricSvc >nul 2>&1
sc config WSAIFabricSvc start= disabled >nul 2>&1

call :L "%cInfo%" "Disabling Windows Copilot"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Blocking sponsored apps (Consumer Features)"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Disabling Widgets and Task View button"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f >nul

call :L "%cInfo%" "Disabling advertising ID + suggested content / Spotlight tips / auto-installed apps"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "RotatingLockScreenOverlayEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsSpotlightFeatures" /t REG_DWORD /d 1 /f >nul

call :L "%cOK%" "Debloat 2026 applied. Sign out or reboot for all changes to take effect."
pause
goto menu


:reassert_defaults
echo.                                                           >> %logs%
echo ====================== :REASSERT_DEFAULTS ================= >> %logs%
echo %date% %time% : Entered :reassert_defaults label             >> %logs%
color FC
cls
call :L "%cStep%" "Re-asserting Windows GOOD DEFAULTS (safety net vs prior bad tweaks)..."

call :L "%cInfo%" "Windows Firewall ON (all profiles)"
netsh advfirewall set allprofiles state on >nul

call :L "%cInfo%" "Microsoft Defender real-time ON (removing disable overrides)"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /f >nul 2>&1

call :L "%cInfo%" "UAC ON (EnableLUA=1, secure prompt) - reboot needed if it was off"
call :regset "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "EnableLUA" REG_DWORD 1 "UAC EnableLUA"
call :regset "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "ConsentPromptBehaviorAdmin" REG_DWORD 5 "UAC prompt behaviour"
:: The banner above promised "secure prompt" but this was never written. Without
:: it the UAC dialog renders on the interactive desktop, where any user-level
:: process can overlay it, screenshot it or synthesise input against it.
call :regset "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "PromptOnSecureDesktop" REG_DWORD 1 "UAC secure desktop"

call :L "%cInfo%" "MMCSS + scheduler back to Windows defaults (20 / 10 / 2)"
:: Measured live on this machine: SystemResponsiveness=10,
:: NetworkThrottlingIndex=0xFFFFFFFF, Win32PrioritySeparation=38 - all left over
:: from earlier OPTY builds. :reassert_defaults never touched them, so they
:: survived every "restore". This is a real fix, not a no-op.
call :regset "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" REG_DWORD 20 "MMCSS SystemResponsiveness"
call :regset "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 10 "NetworkThrottlingIndex"
call :regset "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" REG_DWORD 2 "Win32PrioritySeparation"
echo %date% %time% : Re-asserted MMCSS 20 / NTI 10 / Win32PrioSep 2   >> %logs%

call :L "%cInfo%" "Memory Integrity / HVCI back to the Windows default (value absent)"
call :killkey "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled"
call :killkey "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "EnableVirtualizationBasedSecurity"

call :L "%cInfo%" "Display: clearing leftover overlay/MPO overrides (their default is ABSENT)"
:: Writing 0 does NOT restore these - the Windows default is the value not existing.
:: A stale OverlayTestMode is a classic leftover from older tuning scripts: it
:: disables Multi-Plane Overlay, which costs AutoHDR, Optimized Windowed Mode and
:: VRR in borderless, while rarely fixing the flicker it is supposed to fix.
call :killkey "HKLM\SOFTWARE\Microsoft\Windows\Dwm" "OverlayTestMode"
call :killkey "HKLM\SOFTWARE\Microsoft\Windows\Dwm" "OverlayMinFPS"
call :killkey "HKLM\SOFTWARE\Microsoft\Windows\Dwm" "DisableIndependentFlip"
call :killkey "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "DisableOverlays"
:: NOT removed: UnsupportedMonitorModesAllowed. It is dxgkrnl's custom-mode
:: gate (CRU / Adrenalin custom timings), unrelated to MPO, it is set to 1 on
:: this machine, and nothing here would ever write it back.
:: HAGS is driver-assumed on RDNA3 since Adrenalin 23.12.1 and Anti-Lag 2 needs it.
call :regset "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" REG_DWORD 2 "Hardware GPU scheduling"
call :L "%cInfo%" "Re-asserted hardware GPU scheduling (HwSchMode=2)"

call :L "%cInfo%" "System perf defaults: TRIM on, SysMain/Prefetch on, system-managed pagefile"
fsutil behavior set disabledeletenotify 0 >nul
call :regset "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnablePrefetcher" REG_DWORD 3 "Prefetcher"
call :regset "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" "EnableSuperfetch" REG_DWORD 3 "Superfetch"
call :regset "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "AutomaticManagedPagefile" REG_DWORD 1 "System-managed pagefile"
sc config SysMain start= auto >nul & sc start SysMain >nul 2>&1

call :L "%cOK%" "Good defaults re-asserted. Reboot recommended if UAC was previously off."
pause
goto menu


:display_tweaks
echo.                                                           >> %logs%
echo ====================== :DISPLAY_TWEAKS ================== >> %logs%
echo %date% %time% : Entered :display_tweaks label              >> %logs%
color FC
cls
echo.
echo  WELCOME to OPTY by @YannD-Deltagon
echo    Display tweaks - change ONE thing, REBOOT, retest.
echo.
echo    READ THIS FIRST - fullscreen black flicker on a second monitor:
echo    the usual cause is NOT MPO. If both monitors are on HDMI, VRR
echo    toggling on a fullscreen transition makes HDMI sinks blank.
echo    DisplayPort enforces seamless VRR transitions, HDMI does not.
echo    FIX IN THIS ORDER:
echo      1. Move both monitors to DisplayPort - no registry change
echo      2. If DP is impossible, turn FreeSync off on the SECOND
echo         monitor only, from the AMD Adrenalin GUI
echo      3. Only then try the toggles below
echo.
echo    Disabling MPO is NOT a free win: it costs AutoHDR, Optimized
echo    Windowed Mode and VRR in borderless, and often does not fix flicker.
echo.
echo   1. Disable MPO (Multi-Plane Overlay)  - last resort, see above
echo   2. Re-enable MPO  (Windows default)   - recommended
echo.
echo   3. Enable HAGS  (Windows/RDNA3 default, Anti-Lag 2 needs it)
echo   4. Disable HAGS (A/B test only - not implicated in flicker)
echo.
echo   0. Back to menu
echo.
set "choice="
set /p choice= Enter action:
echo %date% %time% : display_tweaks "%choice%"                    >> %logs%
if "%choice%"=="1" goto dt_mpo_off
if "%choice%"=="2" goto dt_mpo_on
if "%choice%"=="3" goto dt_hags_on
if "%choice%"=="4" goto dt_hags_off
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
echo %date% %time% : Invalid option in :display_tweaks            >> %logs%
timeout /t 5
goto display_tweaks

:dt_mpo_off
call :L "%cWarn%" "Disabling MPO - LAST RESORT. Try DisplayPort / FreeSync-off first."
call :L "%cWarn%" "This costs AutoHDR, Optimized Windowed Mode and VRR in borderless."
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /t REG_DWORD /d 5 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayMinFPS" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "DisableOverlays" /t REG_DWORD /d 1 /f >nul
call :L "%cOK%" "MPO disabled. REBOOT required."
pause
goto display_tweaks

:dt_mpo_on
call :L "%cOK%" "Re-enabling MPO (Windows default) - fixes most multi-monitor flicker"
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayMinFPS" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "DisableOverlays" /f >nul 2>&1
call :L "%cOK%" "MPO re-enabled. REBOOT required."
pause
goto display_tweaks

:dt_hags_on
call :L "%cWarn%" "Enabling HAGS (HwSchMode=2). Reboot after."
call :regset "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "HwSchMode" REG_DWORD 2 "Hardware GPU scheduling"
call :L "%cOK%" "HAGS enabled. REBOOT required."
pause
goto display_tweaks

:dt_hags_off
call :L "%cWarn%" "Disabling HAGS (HwSchMode=1, Windows default). Reboot after."
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 1 /f >nul
call :L "%cOK%" "HAGS disabled. REBOOT required."
pause
goto display_tweaks


:map_only
echo.                                                           >> %logs%
echo ====================== :MAP_ONLY ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :map_only label                         >> %logs%
cls
echo %date% %time% : Re-asserting SysMain/Prefetch good defaults (2026 SSD best practice)   >> %logs%
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000003 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000003 /f
:: REMOVED: SearchOrderConfig=0. That is not a default (default is 1) and it
:: stops Windows Update from delivering ANY driver or firmware - including
:: Intel I211 / AX210 and chipset security fixes. The revert in menu 7 sets 1.
:: REMOVED: writing PolicyManager\...\AllowGameDVR as REG_SZ. It is an OS
:: policy-schema key (policytype=4, lowrange/highrange) whose scalar siblings
:: are REG_DWORD, so the string was a type the policy engine will not read.
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set GameDVR_Enabled=0 (user-level)                  >> %logs%
:: REMOVED: the Policies\Windows\GameDVR write. Windows' own GPBlockingRegKeyPath
:: names exactly this key as what greys out Settings > Gaming > Captures.
:: The HKCU writes below already disable GameDVR without any org banner.
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set AppCaptureEnabled=0 (user-level)                >> %logs%
powercfg /h off
echo %date% %time% : Disabled hibernation via powercfg                  >> %logs%
timeout /t 5
goto regsc_map_only

:regsc_map_only
echo.                                                           >> %logs%
echo ====================== :REGSC_MAP_ONLY ==================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :regsc_map_only label                   >> %logs%
sc config SysMain start= auto
echo %date% %time% : Re-asserted SysMain start= auto (good default)        >> %logs%
sc start SysMain >nul 2>&1
sc stop WSearch
echo %date% %time% : Stopped service: WSearch                           >> %logs%
sc stop WerSvc
echo %date% %time% : Stopped service: WerSvc                              >> %logs%
:: REMOVED: stopping the Print Spooler. Its default start type is Automatic
:: and nothing demand-starts it, so setting it to Manual silently kills all
:: printing after the next reboot - from a menu labelled "services + power".
sc stop DPS
echo %date% %time% : Stopped service: DPS                                  >> %logs%
sc stop TabletInputService
echo %date% %time% : Stopped service: TabletInputService                 >> %logs%
sc config "WSearch" start= demand
echo %date% %time% : Configured WSearch start= demand                      >> %logs%
sc config "WerSvc" start= demand
echo %date% %time% : Configured WerSvc start= demand                         >> %logs%

sc config "DPS" start= demand
echo %date% %time% : Configured DPS start= demand                            >> %logs%
sc config "TabletInputService" start= disabled
echo %date% %time% : Disabled TabletInputService                            >> %logs%
pause
echo %date% %time% : Exiting :regsc_map_only, going to :mregpowercfg       >> %logs%
goto mregpowercfg

:mregpowercfg
echo.                                                           >> %logs%
echo ====================== :MREGPOWERCFG ======================    >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mregpowercfg.label                    >> %logs%
color FC
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo    Do you want to create the "ULTIMATE POWER" power plan?
echo.
echo   1. Yes - create the ULTIMATE POWER power plan
echo   2. No  - skip to mouse optimization          
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo   0. Menu                                                        
echo.                                                  
echo.                                                  
set "choice="
set /p choice= Enter action:
echo %date% %time% : RegProfil.bat-mregpowercfg "%choice%"           >> %logs%
if "%choice%"=="1" goto powercfg
if "%choice%"=="2" goto mregmouse
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mregpowercfg                    >> %logs%
timeout /t 5
goto mregpowercfg

:powercfg
echo.                                                           >> %logs%
echo ====================== :POWERCFG ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :powercfg label                         >> %logs%
:: -duplicatescheme creates a NEW scheme every single time it runs. Unguarded,
:: this machine ended up with three identical "Ultimate Performance" plans.
:: Only duplicate it if no copy exists yet.
set "HASULT="
for /f "delims=" %%S in ('powercfg /list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do set "HASULT=1"
if defined HASULT goto powercfg_have
powercfg /list > "%TEMP%\opty_pc_before.txt" 2>nul
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
if errorlevel 1 (
    call :L "%cWarn%" "Ultimate Performance is not available on this build - keeping the current plan"
    echo %date% %time% : duplicatescheme unavailable                   >> %logs%
    goto powercfg_done
)
call :L "%cOK%" "Ultimate Performance plan created"
echo %date% %time% : Duplicated Ultimate Performance power plan       >> %logs%
goto powercfg_done
:powercfg_have
call :L "%cInfo%" "Ultimate Performance already exists - not duplicating again"
echo %date% %time% : Ultimate Performance already present, skipped    >> %logs%
:powercfg_done
del /f /q "%TEMP%\opty_pc_before.txt" >nul 2>&1
powercfg.cpl
echo %date% %time% : Launched powercfg.cpl GUI                         >> %logs%
pause
goto mregmouse


:mregmouse
echo.                                                           >> %logs%
echo ====================== :MREGMOUSE ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mregmouse label                        >> %logs%
color FC
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo    Do you want to optimize your mouse?                           
echo.                                                  
echo.                                                  
echo.                                                  
echo   1. Yes                                                           
echo   2. No                                                            
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo   0. Menu                                                         
echo.                                                  
echo.                                                  
set "choice="
set /p choice= Enter action:
echo %date% %time% : RegProfil.bat-mregmouse "%choice%"             >> %logs%
if "%choice%"=="1" goto mouseantilag
if "%choice%"=="2" goto menu
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mregmouse                       >> %logs%
timeout /t 5
goto mregmouse

:mouseantilag
echo.                                                           >> %logs%
echo ====================== :MOUSEANTILAG ===================    >> %logs%
echo %date% %time% : Entered :mouseantilag label                     >> %logs%
color 0D
cls
call :banner "MOUSE"
echo(
echo(  %cInfo%All four values are REG_SZ strings, not DWORDs - a DWORD write here is%cR%
echo(  %cInfo%ignored by Windows. Defaults confirmed from the .DEFAULT user profile.%cR%
echo(
echo(     %cVal%1.%cR%  True 1:1     %cInfo%acceleration off - Speed=0, thresholds 0%cR%
echo(     %cVal%2.%cR%  Restore      %cInfo%Windows defaults - Speed=1, T1=6, T2=10%cR%
echo(
echo(     %cVal%0.%cR%  Back
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : mouseantilag "%choice%"                         >> %logs%
if "%choice%"=="1" goto mouse_apply
if "%choice%"=="2" goto mouse_restore
if "%choice%"=="0" goto mregprofil
color 0C
echo This is not a valid action
timeout /t 3 >nul
goto mouseantilag

:mouse_apply
call :L "%cInfo%" "Disabling pointer acceleration (true 1:1)"
reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul
call :mouseapply
call :L "%cOK%" "Pointer acceleration off. Menu 4 -> 3 -> 2 undoes this."
pause
goto mouseantilag

:mouse_restore
:: Values verified against HKEY_USERS\.DEFAULT\Control Panel\Mouse, which is the
:: profile Windows stamps onto a brand-new account - i.e. the factory state.
call :L "%cInfo%" "Restoring Windows mouse defaults (Speed=1, T1=6, T2=10)"
reg add "HKCU\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "6" /f >nul
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "10" /f >nul
:: OPTY v03.x wrote truncated 17/20-byte SmoothMouse curves; the real ones are
:: 40 bytes. Removing them lets Windows regenerate correct defaults at logon.
call :mousecurve
call :mouseapply
call :L "%cOK%" "Mouse restored to Windows defaults."
pause
goto mouseantilag

:mousecurve
:: only remove the curves if they are NOT the expected 40-byte default
for /f "tokens=3" %%C in ('reg query "HKCU\Control Panel\Mouse" /v SmoothMouseXCurve 2^>nul ^| findstr /i "REG_BINARY"') do call :curvecheck "SmoothMouseXCurve" "%%C"
for /f "tokens=3" %%C in ('reg query "HKCU\Control Panel\Mouse" /v SmoothMouseYCurve 2^>nul ^| findstr /i "REG_BINARY"') do call :curvecheck "SmoothMouseYCurve" "%%C"
goto :eof

:curvecheck
:: %~1 = value name, %~2 = the hex blob reg query printed.
:: The stock curve is 40 bytes = exactly 80 hex characters. Anything shorter is
:: a leftover from the old hardcoded curves, so it goes and Windows rebuilds it.
set "CV=%~2"
if "%CV:~80,1%"=="" if not "%CV:~79,1%"=="" goto :eof
reg delete "HKCU\Control Panel\Mouse" /v "%~1" /f >nul 2>&1
call :L "%cInfo%" "  removed non-default %~1 (leftover from an older OPTY)"
goto :eof

:mouseapply
:: make the change live without a logoff
rundll32.exe user32.dll,UpdatePerUserSystemParameters >nul 2>&1
goto :eof



:netinfo_report
echo.                                                           >> %logs%
echo ====================== :NETINFO_REPORT =================== >> %logs%
echo %date% %time% : Entered :netinfo_report label              >> %logs%
color 0B
cls
set "OPTY_HOME=C:\OPTY_by-YannD"
if not exist "%OPTY_HOME%" md "%OPTY_HOME%" >nul 2>&1
set "NICTXT=%OPTY_HOME%\netinfo_%current_date%_%current_time%.txt"
set "NICJSON=%OPTY_HOME%\netprops_%current_date%_%current_time%.json"
call :L "%cStep%" "NETWORK REPORT - dumping every adapter setting (power saving, buffers, offloads)..."
echo(
echo(   Output folder : %cVal%%OPTY_HOME%%cR%
echo(

>"%NICTXT%" echo OPTY v%current_version% - NETWORK ADAPTER REPORT
>>"%NICTXT%" echo Generated : %date% %time%
>>"%NICTXT%" echo Machine   : %COMPUTERNAME%    User: %USERNAME%
>>"%NICTXT%" echo OS        : %OSVER%
>>"%NICTXT%" echo(
>>"%NICTXT%" echo NOTE: section 3 lists, for every driver keyword:
>>"%NICTXT%" echo       current value / factory default / accepted values / min-max-step.
>>"%NICTXT%" echo       Power-saving keywords are vendor-specific - EEE, Green Ethernet,
>>"%NICTXT%" echo       Power Saving Mode, ULPMode... - so ALL keywords are dumped.

call :NH "1. ADAPTER OVERVIEW (physical + hidden/virtual)"
powershell -NoProfile -Command "Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue | Sort-Object Name | Format-Table -AutoSize Name,InterfaceDescription,ifIndex,Status,LinkSpeed,FullDuplex,MtuSize,MacAddress,DriverVersion,DriverDate | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "2. FULL DETAIL PER ADAPTER"
powershell -NoProfile -Command "Get-NetAdapter -IncludeHidden -ErrorAction SilentlyContinue | Sort-Object Name | Format-List * | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "3. TUNABLE SETTINGS (value / factory default / accepted values / min-max-step)"
>>"%NICTXT%" echo This is the actionable view: only keywords the driver exposes as settings.
>>"%NICTXT%" echo Min/Max/Step are the driver's OWN limits - a tuning module must read them
>>"%NICTXT%" echo instead of hardcoding a value - buffer max differs per chipset.
>>"%NICTXT%" echo(
powershell -NoProfile -Command "Get-NetAdapterAdvancedProperty -Name '*' -AllProperties -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Sort-Object Name,RegistryKeyword | Format-Table -AutoSize -Wrap Name,RegistryKeyword,DisplayName,DisplayValue,@{n='Value';e={$_.RegistryValue -join ','}},@{n='Default';e={$_.DefaultRegistryValue -join ','}},@{n='Valid';e={$_.ValidRegistryValues -join ','}},@{n='Min';e={$_.NumericParameterMinValue}},@{n='Max';e={$_.NumericParameterMaxValue}},@{n='Step';e={$_.NumericParameterStepValue}} | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "3b. ALL REGISTRY KEYWORDS (exhaustive, incl. driver metadata)"
powershell -NoProfile -Command "Get-NetAdapterAdvancedProperty -Name '*' -AllProperties -ErrorAction SilentlyContinue | Sort-Object Name,RegistryKeyword | Format-Table -AutoSize -Wrap Name,RegistryKeyword,DisplayName,@{n='Value';e={$_.RegistryValue -join ','}},@{n='Default';e={$_.DefaultRegistryValue -join ','}},@{n='Valid';e={$_.ValidRegistryValues -join ','}} | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "4. POWER SAVING / WAKE KEYWORDS (filtered view of section 3)"
powershell -NoProfile -Command "Get-NetAdapterAdvancedProperty -Name '*' -AllProperties -ErrorAction SilentlyContinue | Where-Object { $_.RegistryKeyword -match 'EEE|Power|Green|ULP|Wake|Idle|Sleep|Energy|Saving|Standby|Moderation|AutoDisable|Selective' -or $_.DisplayName -match 'Energy|Power|Green|Wake|Idle|Sleep|Saving|Moderation' } | Sort-Object Name,RegistryKeyword | Format-Table -AutoSize -Wrap Name,RegistryKeyword,DisplayName,DisplayValue,@{n='Value';e={$_.RegistryValue -join ','}},@{n='Default';e={$_.DefaultRegistryValue -join ','}},@{n='Valid';e={$_.ValidRegistryValues -join ','}} | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "5. POWER MANAGEMENT (Wake-on-LAN / device power-down)"
>>"%NICTXT%" echo Get-NetAdapterPowerManagement fails on some drivers - error: device
>>"%NICTXT%" echo attached to the system is not functioning. Registry fallback below always works.
>>"%NICTXT%" echo PnPCapabilities bit 24 = value 16777216 = Allow the computer to turn off
>>"%NICTXT%" echo this device to save power is UNCHECKED. Value 16 = wake features disabled.
>>"%NICTXT%" echo(
powershell -NoProfile -Command "try { Get-NetAdapterPowerManagement -Name '*' -ErrorAction Stop | Format-List * | Out-String -Width 500 } catch { 'Get-NetAdapterPowerManagement unavailable on this system: ' + $_.Exception.Message }" >>"%NICTXT%" 2>&1
>>"%NICTXT%" echo(
>>"%NICTXT%" echo -- Registry fallback: PnPCapabilities per adapter --
powershell -NoProfile -Command "$b='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'; Get-ChildItem $b -ErrorAction SilentlyContinue | ForEach-Object { $p=Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue; if($p.DriverDesc){ [pscustomobject]@{Key=$_.PSChildName;Driver=$p.DriverDesc;PnPCapabilities=$p.PnPCapabilities} } } | Format-Table -AutoSize | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "6. OFFLOADS - RSS / LSO / Checksum / RSC / QoS"
powershell -NoProfile -Command "Get-NetAdapterRss -Name '*' -ErrorAction SilentlyContinue | Format-List Name,Enabled,NumberOfReceiveQueues,MaxProcessorNumber,Profile | Out-String -Width 500" >>"%NICTXT%" 2>&1
powershell -NoProfile -Command "Get-NetAdapterLso -Name '*' -ErrorAction SilentlyContinue | Format-Table -AutoSize Name,V1IPv4Enabled,IPv4Enabled,IPv6Enabled | Out-String -Width 500" >>"%NICTXT%" 2>&1
powershell -NoProfile -Command "Get-NetAdapterChecksumOffload -Name '*' -ErrorAction SilentlyContinue | Format-Table -AutoSize Name,IpIPv4Enabled,TcpIPv4Enabled,TcpIPv6Enabled,UdpIPv4Enabled,UdpIPv6Enabled | Out-String -Width 500" >>"%NICTXT%" 2>&1
powershell -NoProfile -Command "Get-NetAdapterRsc -Name '*' -ErrorAction SilentlyContinue | Format-Table -AutoSize Name,IPv4Enabled,IPv6Enabled | Out-String -Width 500" >>"%NICTXT%" 2>&1
powershell -NoProfile -Command "Get-NetAdapterQos -Name '*' -ErrorAction SilentlyContinue | Format-List Name,Enabled | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "7. PROTOCOL BINDINGS"
powershell -NoProfile -Command "Get-NetAdapterBinding -Name '*' -ErrorAction SilentlyContinue | Sort-Object Name,ComponentID | Format-Table -AutoSize Name,DisplayName,ComponentID,Enabled | Out-String -Width 500" >>"%NICTXT%" 2>&1

call :NH "8. IP INTERFACES / METRICS / MTU"
powershell -NoProfile -Command "Get-NetIPInterface -ErrorAction SilentlyContinue | Sort-Object InterfaceMetric | Format-Table -AutoSize ifIndex,InterfaceAlias,AddressFamily,NlMtu,InterfaceMetric,AutomaticMetric,Dhcp,ConnectionState | Out-String -Width 500" >>"%NICTXT%" 2>&1
netsh int ip show interfaces      >>"%NICTXT%" 2>&1
netsh int ipv4 show subinterfaces >>"%NICTXT%" 2>&1

call :NH "9. IPCONFIG /ALL"
ipconfig /all >>"%NICTXT%" 2>&1

call :NH "10. GLOBAL TCP SETTINGS"
netsh int tcp show global      >>"%NICTXT%" 2>&1
netsh int tcp show heuristics  >>"%NICTXT%" 2>&1
netsh int tcp show supplemental >>"%NICTXT%" 2>&1

call :NH "11. WI-FI DRIVER CAPABILITIES (if any)"
netsh wlan show drivers    >>"%NICTXT%" 2>&1
netsh wlan show interfaces >>"%NICTXT%" 2>&1

call :NH "12. MAC / TRANSPORT LIST"
getmac /v /fo list >>"%NICTXT%" 2>&1

call :NH "13. RAW REGISTRY - NIC CLASS KEY (pure-CMD backup, includes Ndi\Params)"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /s >>"%NICTXT%" 2>&1

:: --- machine-readable export for the future universal NIC tuning module ---
call :L "%cInfo%" "Exporting machine-readable JSON (driver limits for auto-tuning)"
powershell -NoProfile -Command "Get-NetAdapterAdvancedProperty -Name '*' -AllProperties -ErrorAction SilentlyContinue | Select-Object Name,InterfaceDescription,RegistryKeyword,DisplayName,DisplayValue,RegistryValue,DefaultRegistryValue,ValidRegistryValues,ValidDisplayValues,NumericParameterMinValue,NumericParameterMaxValue,NumericParameterStepValue | ConvertTo-Json -Depth 4" >"%NICJSON%" 2>nul

echo %date% %time% : Network report written to %NICTXT%        >> %logs%
call :L "%cOK%" "Network report done."
echo(
echo(   %cVal%%NICTXT%%cR%
echo(   %cVal%%NICJSON%%cR%
echo(
echo(   %cInfo%The JSON lists each driver's accepted values / limits - it is what a%cR%
echo(   %cInfo%future universal NIC tuning module will read instead of hardcoding.%cR%
echo(
set "choice="
set /p choice= Open the report now? 1 (Yes) - 0 (No):
if "%choice%"=="1" start "" notepad "%NICTXT%"
goto menu


:mnetwork
echo.                                                           >> %logs%
echo ====================== :MNETWORK ========================= >> %logs%
echo %date% %time% : Entered :mnetwork label                     >> %logs%
color 0B
cls
call :banner "NETWORK"
echo(
echo(     %cVal%1.%cR%  Diagnose        %cInfo%what differs from your driver's defaults%cR%
echo(     %cVal%2.%cR%  Full report     %cInfo%every setting + limits -^> %OPTY_HOME_D%%cR%
echo(     %cVal%3.%cR%  Apply profile   %cInfo%one sane profile, clamped to YOUR driver limits%cR%
echo(     %cVal%4.%cR%  Restore         %cInfo%back to the driver's own factory defaults%cR%
echo(
echo(     %cVal%0.%cR%  Menu
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : mnetwork "%choice%"                          >> %logs%
if "%choice%"=="1" goto net_diag
if "%choice%"=="2" goto netinfo_report
if "%choice%"=="3" (call :restore_point & goto net_apply)
if "%choice%"=="4" (call :restore_point & goto net_restore)
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
echo %date% %time% : Invalid option in :mnetwork                  >> %logs%
timeout /t 3 >nul
goto mnetwork


:net_diag
echo.                                                           >> %logs%
echo ====================== :NET_DIAG ========================= >> %logs%
echo %date% %time% : Entered :net_diag label                      >> %logs%
color 0B
cls
call :banner "NETWORK - DIAGNOSE"
echo(
call :L "%cInfo%" "Physical adapters"
powershell -NoProfile -Command "Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Format-Table -AutoSize Name,InterfaceDescription,Status,LinkSpeed,MtuSize | Out-String -Width 200"
call :L "%cInfo%" "Settings that DIFFER from the driver's factory default"
call :L "%cInfo%" "(empty list = your adapters are all at factory settings)"
powershell -NoProfile -Command "Get-NetAdapterAdvancedProperty -Name '*' -AllProperties -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and (($_.RegistryValue -join ',') -ne ($_.DefaultRegistryValue -join ',')) } | Format-Table -AutoSize -Wrap Name,RegistryKeyword,DisplayName,@{n='Now';e={$_.RegistryValue -join ','}},@{n='Default';e={$_.DefaultRegistryValue -join ','}} | Out-String -Width 200"
call :L "%cInfo%" "TCP globals"
netsh int tcp show global | findstr /i "Receive Window Auto-Tuning RSS Heuristic"
echo(
call :rule
echo(  %cInfo%Interpretation: differences are not automatically bad - they are just%cR%
echo(  %cInfo%what someone (or OPTY) changed. Menu 4 restores the driver defaults.%cR%
echo(
pause
goto mnetwork


:mrepair
echo.                                                           >> %logs%
echo ====================== :MREPAIR ========================== >> %logs%
echo %date% %time% : Entered :mrepair label                       >> %logs%
color 0E
cls
call :banner "REPAIR WINDOWS"
echo(
echo(  %cInfo%Guided repair. Each step asks before it runs, so you can skip any of them.%cR%
echo(  %cInfo%Order matters: DISM repairs the component store that SFC restores from.%cR%
echo(
echo(     %cVal%1.%cR%  Start guided repair     %cInfo%DISM -^> SFC -^> Windows Update -^> disk%cR%
echo(
echo(     %cVal%0.%cR%  Menu
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : mrepair "%choice%"                            >> %logs%
if "%choice%"=="0" goto menu
if not "%choice%"=="1" (
    color 0C
    echo This is not a valid action
    timeout /t 3 >nul
    goto mrepair
)
call :restore_point
set autoclean=0
set autoshutdownreboot=5
goto mdism


:mrestore
echo.                                                           >> %logs%
echo ====================== :MRESTORE ========================= >> %logs%
echo %date% %time% : Entered :mrestore label                       >> %logs%
color 0A
cls
call :banner "RESTORE DEFAULTS - safety net"
echo(
echo(     %cVal%1.%cR%  Re-assert good defaults
echo(         %cInfo%Firewall ON, Defender ON, UAC ON, SSD TRIM, SysMain/Prefetch,%cR%
echo(         %cInfo%system-managed pagefile, and removes leftover display overrides%cR%
echo(         %cInfo%whose Windows default is "value absent" (OverlayTestMode etc).%cR%
echo(
echo(     %cVal%2.%cR%  Undo ALL OPTY profiles
echo(         %cInfo%gaming + debloat + services back to Windows defaults%cR%
echo(
echo(     %cVal%0.%cR%  Menu
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : mrestore "%choice%"                           >> %logs%
if "%choice%"=="1" goto reassert_defaults
if "%choice%"=="2" goto gaming_restore
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 3 >nul
goto mrestore


:net_apply
echo.                                                           >> %logs%
echo ====================== :NET_APPLY ======================== >> %logs%
echo %date% %time% : Entered :net_apply label                    >> %logs%
color 0B
cls
call :L "%cStep%" "NETWORK - apply sane adapter defaults"
echo(
echo(  %cInfo%There is no Gaming / Streaming / Torrent split: game traffic is small%cR%
echo(  %cInfo%UDP that never touches LSO, RSC or jumbo frames, and streaming and%cR%
echo(  %cInfo%torrenting want the same offloads on and the same buffers raised.%cR%
echo(  %cInfo%One profile, values read from YOUR driver's own limits.%cR%
echo(

:: --- enumerate adapters that actually expose tunable parameters ---
set "NICCLS=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
del /f /q "%TEMP%\opty_nic_list.txt" >nul 2>&1
for /f "delims=" %%K in ('reg query "%NICCLS%" 2^>nul') do (
    reg query "%%K\Ndi\Params" >nul 2>&1 && (
        for /f "tokens=2,*" %%A in ('reg query "%%K" /v DriverDesc 2^>nul ^| findstr /i "DriverDesc"') do >>"%TEMP%\opty_nic_list.txt" echo %%K %%B
    )
)
if not exist "%TEMP%\opty_nic_list.txt" (
    call :L "%cWarn%" "No adapter exposes tunable parameters - nothing to do."
    pause
    goto mnetwork
)
set /a NCOUNT=0
for /f "usebackq tokens=1,*" %%A in ("%TEMP%\opty_nic_list.txt") do (
    set /a NCOUNT+=1
    call :nicecho "%%A" "%%B"
)
echo(
echo(   0. Back
echo(
set "choice="
set /p choice= Adapter number to tune:
echo %date% %time% : net_apply choice "%choice%"                  >> %logs%
if "%choice%"=="0" goto mnetwork
set "NICKEY="
set "NICDESC="
set /a NSEL=0
for /f "usebackq tokens=1,*" %%A in ("%TEMP%\opty_nic_list.txt") do (
    set /a NSEL+=1
    call :nicpick "%choice%" "%%A" "%%B"
)
if not defined NICKEY (
    call :L "%cErr%" "Invalid selection."
    timeout /t 3 >nul
    goto net_apply
)

cls
call :L "%cStep%" "Applying to: %NICDESC%"
echo(
call :L "%cInfo%" "All NDIS keywords are written as REG_SZ - a REG_DWORD write is"
call :L "%cInfo%" "silently ignored by the driver, which is how most .bat 'tweaks' do nothing."
echo(
call :L "%cInfo%" "Re-asserting adaptive interrupt moderation (lowest CPU for the same latency)"
call :nicset "%NICKEY%" "*InterruptModeration" "1"
call :nicset "%NICKEY%" "ITR" "65535"

call :L "%cInfo%" "Re-asserting offloads ON (they never touch small UDP game packets)"
call :nicset "%NICKEY%" "*LsoV2IPv4" "1"
call :nicset "%NICKEY%" "*LsoV2IPv6" "1"
call :nicset "%NICKEY%" "*TCPChecksumOffloadIPv4" "3"
call :nicset "%NICKEY%" "*TCPChecksumOffloadIPv6" "3"
call :nicset "%NICKEY%" "*UDPChecksumOffloadIPv4" "3"
call :nicset "%NICKEY%" "*UDPChecksumOffloadIPv6" "3"
call :nicset "%NICKEY%" "*IPChecksumOffloadIPv4" "3"

call :L "%cInfo%" "Receive Side Scaling on, queues capped to what the driver enumerates"
call :nicset "%NICKEY%" "*RSS" "1"
call :nicenummax "%NICKEY%" "*NumRssQueues"
if defined NENUMMAX call :nicset "%NICKEY%" "*NumRssQueues" "%NENUMMAX%"

call :L "%cInfo%" "Jumbo frames off (they fragment on any 1500-MTU internet path)"
call :nicset "%NICKEY%" "*JumboPacket" "1514"

call :L "%cInfo%" "Buffer headroom - requested 1024, clamped to the driver max and step"
call :nicset "%NICKEY%" "*ReceiveBuffers" "1024"
call :nicset "%NICKEY%" "*TransmitBuffers" "1024"

call :L "%cInfo%" "Energy Efficient Ethernet off (link stability, not a ping fix)"
call :nicset "%NICKEY%" "EEELinkAdvertisement" "0"
call :nicset "%NICKEY%" "*EEE" "0"
call :nicset "%NICKEY%" "EnableGreenEthernet" "0"
call :nicset "%NICKEY%" "AdvancedEEE" "0"

echo(
call :rule
echo(  %cT%Usage profile%cR%
echo(  %cInfo%Everything above is identical for gaming, streaming and torrenting -%cR%
echo(  %cInfo%game traffic is small UDP that never touches LSO, RSC or jumbo frames.%cR%
echo(  %cInfo%Only TWO settings genuinely differ, and both are conditional:%cR%
echo(
echo(     %cVal%1.%cR%  Balanced       %cInfo%Windows defaults for both - recommended%cR%
echo(     %cVal%2.%cR%  Low latency    %cInfo%Flow Control off: avoids a PAUSE frame stalling%cR%
echo(                    %cInfo%your upload up to 33.6 ms - but only if a switch on%cR%
echo(                    %cInfo%your LAN actually sends them. Costs dropped packets%cR%
echo(                    %cInfo%instead of a brief pause under saturation.%cR%
echo(     %cVal%3.%cR%  Throughput     %cInfo%Lifts the MMCSS network cap (~120 Mbit/s) that%cR%
echo(                    %cInfo%applies ONLY while audio is playing. Costs the%cR%
echo(                    %cInfo%protection that cap exists for: network DPC work can%cR%
echo(                    %cInfo%steal time from audio threads.%cR%
echo(
set "choice="
set /p choice= Profile (1/2/3):
echo %date% %time% : net profile "%choice%"                        >> %logs%
if "%choice%"=="2" goto net_prof_lat
if "%choice%"=="3" goto net_prof_thr
call :L "%cInfo%" "Balanced - Flow Control and the MMCSS cap left at their defaults"
call :nicset "%NICKEY%" "*FlowControl" "3"
call :regset "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 10 "NetworkThrottlingIndex"
goto net_prof_done

:net_prof_lat
call :L "%cWarn%" "Low latency - Flow Control off"
call :nicset "%NICKEY%" "*FlowControl" "0"
:: Deliberately no automatic "did this help" check: the only honest signal is the
:: adapter's own "Pause Frames Received" counter, which this driver does not
:: expose through any scriptable interface. Saying it changed nothing would be
:: as much a guess as saying it helped.
call :L "%cInfo%" "  This only does something if a switch on your LAN sends PAUSE frames."
call :L "%cInfo%" "  If none does, the measured effect is exactly zero."
call :regset "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 10 "NetworkThrottlingIndex"
goto net_prof_done

:net_prof_thr
call :L "%cWarn%" "Throughput - lifting the MMCSS network cap"
call :nicset "%NICKEY%" "*FlowControl" "3"
call :regset "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" REG_DWORD 4294967295 "NetworkThrottlingIndex"
call :L "%cInfo%" "  Honest A/B: run a large download while playing audio, before and after."
:net_prof_done

echo(
call :L "%cInfo%" "Re-asserting good TCP globals"
netsh int tcp set global autotuninglevel=normal >nul
netsh int tcp set heuristics disabled >nul
netsh int tcp set global rss=enabled >nul

echo(
call :L "%cWarn%" "The adapter must restart for these to take effect (link drops 2-4 s)."
set "choice="
set /p choice= Restart the adapter now? 1 (Yes) - 0 (No, on next reboot):
if not "%choice%"=="1" goto net_apply_done
call :nicrestart "%NICKEY%"
:net_apply_done
echo(
call :L "%cOK%" "Network profile applied."
call :L "%cInfo%" "Torrent + gaming lag is upstream queue saturation, not a NIC setting."
call :L "%cInfo%" "Real fix: SQM/fq_codel on the router at ~90%% of link rate, or cap"
call :L "%cInfo%" "qBittorrent upload to ~85-90%% of your measured upstream."
del /f /q "%TEMP%\opty_nic_list.txt" >nul 2>&1
pause
goto mnetwork


:net_restore
echo.                                                           >> %logs%
echo ====================== :NET_RESTORE ====================== >> %logs%
echo %date% %time% : Entered :net_restore label                  >> %logs%
color 0B
cls
call :L "%cStep%" "NETWORK - restore the driver's own factory defaults"
set "NICCLS=HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}"
del /f /q "%TEMP%\opty_nic_list.txt" >nul 2>&1
for /f "delims=" %%K in ('reg query "%NICCLS%" 2^>nul') do (
    reg query "%%K\Ndi\Params" >nul 2>&1 && (
        for /f "tokens=2,*" %%A in ('reg query "%%K" /v DriverDesc 2^>nul ^| findstr /i "DriverDesc"') do >>"%TEMP%\opty_nic_list.txt" echo %%K %%B
    )
)
if not exist "%TEMP%\opty_nic_list.txt" (
    call :L "%cWarn%" "No tunable adapter found."
    pause
    goto mnetwork
)
set /a NCOUNT=0
for /f "usebackq tokens=1,*" %%A in ("%TEMP%\opty_nic_list.txt") do (
    set /a NCOUNT+=1
    call :nicecho "%%A" "%%B"
)
echo(
echo(   0. Back
echo(
set "choice="
set /p choice= Adapter number to restore:
if "%choice%"=="0" goto mnetwork
set "NICKEY="
set "NICDESC="
set /a NSEL=0
for /f "usebackq tokens=1,*" %%A in ("%TEMP%\opty_nic_list.txt") do (
    set /a NSEL+=1
    call :nicpick "%choice%" "%%A" "%%B"
)
if not defined NICKEY (
    call :L "%cErr%" "Invalid selection."
    timeout /t 3 >nul
    goto net_restore
)
cls
call :L "%cStep%" "Restoring factory defaults on: %NICDESC%"
echo(
:: every tunable keyword carries its own factory value in Ndi\Params\<kw>\default
:: Restore ONLY the keywords :net_apply actually writes. The unfiltered query
:: returned all 31 the driver exposes, so "Restore" also re-enabled Wake-on-LAN,
:: 802.3az EEE and ReduceSpeedOnPowerDown - settings the user had deliberately
:: turned off and that OPTY never touched.
:: findstr /e /c: is required here: a `for %%P in (*RSS ITR)` style list would be
:: treated as a filesystem glob and silently drop every *-prefixed keyword.
for /f "delims=" %%P in ('reg query "%NICKEY%\Ndi\Params" 2^>nul ^| findstr /i /e /c:"\*InterruptModeration" /c:"\ITR" /c:"\*LsoV2IPv4" /c:"\*LsoV2IPv6" /c:"\*TCPChecksumOffloadIPv4" /c:"\*TCPChecksumOffloadIPv6" /c:"\*UDPChecksumOffloadIPv4" /c:"\*UDPChecksumOffloadIPv6" /c:"\*IPChecksumOffloadIPv4" /c:"\*RSS" /c:"\*NumRssQueues" /c:"\*JumboPacket" /c:"\*ReceiveBuffers" /c:"\*TransmitBuffers"') do call :nicdefault "%NICKEY%" "%%P"
echo(
call :L "%cInfo%" "Restoring TCP globals"
netsh int tcp set global autotuninglevel=normal >nul
netsh int tcp set heuristics default >nul
netsh int tcp set global rss=default >nul
echo(
set "choice="
set /p choice= Restart the adapter now? 1 (Yes) - 0 (No, on next reboot):
if "%choice%"=="1" call :nicrestart "%NICKEY%"
call :L "%cOK%" "Adapter restored to the driver's own defaults."
del /f /q "%TEMP%\opty_nic_list.txt" >nul 2>&1
pause
goto mnetwork


:driverstore
echo.                                                           >> %logs%
echo ====================== :DRIVERSTORE ====================== >> %logs%
echo %date% %time% : Entered :driverstore label                  >> %logs%
color 0E
cls
call :banner "DRIVER STORE - superseded third-party packages"
echo(
echo(  %cInfo%Windows keeps every driver package ever installed, old versions%cR%
echo(  %cInfo%included, and never prunes them. Only THIRD-PARTY packages%cR%
echo(  %cInfo%(oemNN.inf) are considered, through pnputil - the supported API.%cR%
echo(
echo(  %cWarn%Cost: you lose "Roll Back Driver" for the versions removed.%cR%
echo(  %cInfo%This deliberately does NOT hand-delete FileRepository folders: much%cR%
echo(  %cInfo%of that folder is hardlinked into WinSxS, so removing it frees far%cR%
echo(  %cInfo%less than its apparent size and breaks SFC / DISM repair.%cR%
echo(  %cInfo%A package still backing a device is refused - /force is never used.%cR%
echo(
echo(     %cVal%1.%cR%  Analyse only   %cInfo%list what would go, delete nothing%cR%
echo(     %cVal%2.%cR%  Remove         %cInfo%keep the newest of each INF family%cR%
echo(
echo(     %cVal%0.%cR%  Back
echo(
call :rule
set "choice="
set /p choice= Enter action:
echo %date% %time% : driverstore "%choice%"                       >> %logs%
if "%choice%"=="1" goto ds_run
if "%choice%"=="2" goto ds_run
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 3 >nul
goto driverstore

:ds_run
set "DSMODE=%choice%"
set "DSLIST=%TEMP%\opty_ds.txt"
del /f /q "%DSLIST%" >nul 2>&1
call :L "%cInfo%" "Enumerating driver packages..."
:: pnputil output is localised and block-structured, so the grouping is done in
:: one PowerShell pass - the same sanctioned exception as the restore point.
:: The DELETION stays in CMD below, one visible pnputil call per package.
powershell -NoProfile -Command "$b=(pnputil /enum-drivers) -join [char]10; $p=@(); foreach($k in ($b -split '(?m)^\s*$')){ if($k -match 'oem\d+\.inf'){ $pub=[regex]::Match($k,'oem\d+\.inf').Value; $o=[regex]::Match($k,'(?im)^[^\r\n:]*(origine|Original)[^:]*:\s*(\S+)').Groups[2].Value; $v=[regex]::Match($k,'(?im)^[^\r\n:]*(Version)[^:]*:\s*(.+)$').Groups[2].Value.Trim(); if($o){ $d=[datetime]::MinValue; [void][datetime]::TryParse(($v -split ' ')[0],[ref]$d); $p+=[pscustomobject]@{P=$pub;O=$o;D=$d} } } }; $p | Group-Object O | Where-Object Count -gt 1 | ForEach-Object { $_.Group | Sort-Object D -Descending | Select-Object -Skip 1 } | ForEach-Object { $_.P + ' ' + $_.O }" > "%DSLIST%" 2>nul

if not exist "%DSLIST%" goto ds_none
set "DSCOUNT=0"
for /f %%C in ('type "%DSLIST%" ^| find /c /v ""') do set "DSCOUNT=%%C"
if "%DSCOUNT%"=="0" goto ds_none
echo(
call :L "%cInfo%" "Superseded packages (the newest of each family is kept):"
for /f "usebackq tokens=1,2" %%A in ("%DSLIST%") do echo(   %cVal%%%A%cR%  ^(%%B^)
echo(
if "%DSMODE%"=="1" (
    call :L "%cOK%" "Analyse only - nothing was removed."
    echo %date% %time% : driverstore analyse only, %DSCOUNT% superseded >> %logs%
    del /f /q "%DSLIST%" >nul 2>&1
    pause
    goto driverstore
)
call :L "%cWarn%" "This removes the packages above. Driver rollback for them is lost."
set "choice="
set /p choice= Type YES to confirm:
if /i not "%choice%"=="YES" (
    call :L "%cInfo%" "Cancelled - nothing removed."
    del /f /q "%DSLIST%" >nul 2>&1
    pause
    goto driverstore
)
for /f "usebackq tokens=1" %%A in ("%DSLIST%") do call :ds_del "%%A"
call :L "%cOK%" "Done. Packages still in use were refused and left in place."
del /f /q "%DSLIST%" >nul 2>&1
pause
goto driverstore

:ds_del
:: no /force on purpose - a package backing a present device must survive
pnputil /delete-driver "%~1" >nul 2>&1
if errorlevel 1 (
    call :L "%cInfo%" "  %~1 in use or protected - kept"
) else (
    call :L "%cOK%" "  %~1 removed"
)
goto :eof

:ds_none
call :L "%cOK%" "No superseded third-party driver package found."
del /f /q "%DSLIST%" >nul 2>&1
pause
goto driverstore


:Clean_Opty_Curl
echo.                                                           >> %logs%
echo ====================== :CLEAN_OPTY_CURL ================= >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :Clean_Opty_Curl label                >> %logs%
:: Keep OPTY.bat itself AND OPTY_rollback.bat - the rollback copy is the only
:: way back if a self-update ships a broken build, so cleaning must not eat it.
for /f "delims=" %%f in ('dir /b /a-d "%~dp0" ^| findstr /i /v /c:"OPTY.bat" /c:"OPTY_rollback.bat"') do (
    echo %date% %time% : Deleting file "%~dp0%%f"                   >> %logs%
    del /f /q "%~dp0%%f"
)
goto menu


:end
echo.                                                           >> %logs%
echo ====================== :END ======================        >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :end label                             >> %logs%
echo %date% %time% : Script end                                      >> %logs%
color F2
cls
echo.                                                  
echo.                                                  
echo.                                                  
echo  Thanks for using my script                                      
echo     @YannD-Deltagon                              
echo.                                                  
echo.                                                  
echo.                                                  
timeout /t 15
exit

:: ============================================================
:: ====================  HELPER SUBROUTINES  ==================
:: ============================================================

:sysinfo
:: Comprehensive session header: colored console + full log
cls
color 0B
set "OSVER="
for /f "tokens=*" %%v in ('ver') do set "OSVER=%%v"
echo(%cT%================  OPTY v%current_version%  -  SESSION  ================%cR%
echo(    Date/time : %cVal%%date% %time%%cR%
echo(    User      : %cVal%%USERNAME%%cR%   Machine : %cVal%%COMPUTERNAME%%cR%
echo(    OS        : %cVal%%OSVER%%cR%
echo(    CPU       : %cVal%%NUMBER_OF_PROCESSORS% threads%cR%   Arch : %cVal%%PROCESSOR_ARCHITECTURE%%cR%
echo(    Log file  : %cInfo%%logs%%cR%
echo(%cT%---------------------------------------------------------------%cR%
echo(    Free space per drive:
>>%logs% echo.
>>%logs% echo ====================== :SYSINFO ======================
>>%logs% echo %date% %time% : OPTY v%current_version% session start
>>%logs% echo %date% %time% : User=%USERNAME% Machine=%COMPUTERNAME%
>>%logs% echo %date% %time% : OS=%OSVER%
>>%logs% echo %date% %time% : CPU=%NUMBER_OF_PROCESSORS% threads Arch=%PROCESSOR_ARCHITECTURE%
call :show_drive C
call :show_drive D
call :show_drive E
call :show_drive F
echo(%cT%===============================================================%cR%
timeout /t 4 /nobreak >nul
goto :eof

:show_drive
:: %1 = drive letter (C, D...) ; prints + logs free MB if the drive exists
if not exist "%~1:\" goto :eof
call :get_free_mb "%~1:"
echo(      %cVal%%~1:%cR%  free = %cOK%%FREE_MB%%cR% MB
>>%logs% echo %date% %time% : Drive %~1: free=%FREE_MB% MB
goto :eof

:get_free_mb
:: %1 = drive like C:  ->  sets FREE_MB (MB, locale- and overflow-safe via .NET)
:: fsutil's number is locale-formatted (FR thousands separators 0xA0/0xFF break
:: a pure-CMD parse and produce garbage like 499ÿ303ÿ9), so we read the raw byte
:: count through .NET DriveInfo and convert to MB.
set "FREE_MB=0"
powershell -NoProfile -Command "try{[math]::Floor([System.IO.DriveInfo]::new('%~1').AvailableFreeSpace/1MB)}catch{0}" > "%TEMP%\opty_free.txt" 2>nul
set /p FREE_MB=<"%TEMP%\opty_free.txt"
del /f /q "%TEMP%\opty_free.txt" >nul 2>&1
if not defined FREE_MB set "FREE_MB=0"
if "%FREE_MB%"=="" set "FREE_MB=0"
goto :eof

:L
:: %~1 = ANSI color, %~2 = message  ->  colored console line + timestamped log
:: %~2 is echoed through delayed expansion for the same reason as :banner -
:: %~2 strips the quotes, so a message containing > or | was re-parsed as a
:: redirection and the line vanished entirely. "menu 3 -> 5: Display tweaks"
:: printed nothing at all and tried to redirect into a drive called 5:.
setlocal enabledelayedexpansion
set "MSG=%~2"
echo(%~1!MSG!%cR%
>>%logs% echo %date% %time% : !MSG!
endlocal
goto :eof

:chromecache
:: %~1 = a Chromium "User Data" folder. Clears the disposable caches of EVERY
:: profile inside it (Default, "Profile 1", "Profile 2", ...) instead of
:: hardcoding Default - this machine alone has two.
:: The browser is deliberately NOT killed: files it holds open simply fail to
:: delete and are skipped. Closing the user's tabs to clean a cache is not a
:: trade this tool makes.
:: Never touched: Cookies, Login Data, Web Data, History, Bookmarks, Local
:: Storage, IndexedDB - that is user data, not cache. In particular there is no
:: *.log glob here: under User Data those are LevelDB write-ahead logs holding
:: live extension and IndexedDB state.
:: %~2 = the browser's process name. A running Chromium holds LevelDB and cache
:: files half-written; deleting underneath it CREATES the corruption this is
:: meant to prevent. So the browser is never killed AND never cleaned while up.
if not exist "%~1" goto :eof
call :isrunning "%~2"
if defined RUNNING (
    call :L "%cWarn%" "  %~2 is running - skipped, close it and re-run"
    echo %date% %time% : Skipped "%~1" - %~2 running                >> %logs%
    goto :eof
)
:: per-profile
for /d %%P in ("%~1\Default" "%~1\Profile *" "%~1\Guest Profile") do (
    del /F /S /Q "%%~P\Cache\*"                       >nul 2>&1
    del /F /S /Q "%%~P\Code Cache\*"                  >nul 2>&1
    del /F /S /Q "%%~P\GPUCache\*"                    >nul 2>&1
    del /F /S /Q "%%~P\DawnWebGPUCache\*"             >nul 2>&1
    del /F /S /Q "%%~P\DawnGraphiteCache\*"           >nul 2>&1
    del /F /S /Q "%%~P\Service Worker\CacheStorage\*" >nul 2>&1
    del /F /S /Q "%%~P\Service Worker\ScriptCache\*"  >nul 2>&1
)
:: browser-level - these sit BESIDE the profiles, so a per-profile-only sweep
:: misses them entirely (28 MB of component_crx_cache here)
del /F /S /Q "%~1\GrShaderCache\*"        >nul 2>&1
del /F /S /Q "%~1\ShaderCache\*"          >nul 2>&1
del /F /S /Q "%~1\GraphiteDawnCache\*"    >nul 2>&1
del /F /S /Q "%~1\GPUPersistentCache\*"   >nul 2>&1
del /F /S /Q "%~1\component_crx_cache\*"  >nul 2>&1
del /F /S /Q "%~1\extensions_crx_cache\*" >nul 2>&1
del /F /S /Q "%~1\Crashpad\reports\*"     >nul 2>&1
del /F /Q    "%~1\BrowserMetrics\*.pma"   >nul 2>&1
echo %date% %time% : Cleared Chromium caches under "%~1"            >> %logs%
goto :eof

:fixeddrives
:: FIXEDLIST = the letters of every FIXED drive, e.g. " C D E G J".
:: Network drives must never be swept: this machine maps 11 SMB shares and
:: several are disconnected, so touching them costs a 30 s timeout each.
:: The drive-type wording is localised ("Lecteur fixe" here), so instead of
:: matching an English word we take the reference string from %SystemDrive%
:: at runtime and compare against that.
set "FIXEDLIST="
set "FIXEDREF="
for /f "tokens=2 delims=:" %%T in ('fsutil fsinfo drivetype %SystemDrive% 2^>nul') do set "FIXEDREF=%%T"
if not defined FIXEDREF goto :eof
for %%D in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do call :fixedprobe %%D
goto :eof

:fixedprobe
set "DT="
for /f "tokens=2 delims=:" %%T in ('fsutil fsinfo drivetype %~1: 2^>nul') do set "DT=%%T"
if not defined DT goto :eof
if /i not "%DT%"=="%FIXEDREF%" goto :eof
set "FIXEDLIST=%FIXEDLIST% %~1"
goto :eof

:drivesweep
:: %~1 = drive letter. Per-drive junk that Windows drops at the root of
:: whichever volume it decided to use - not only C:.
del /F /S /Q "%~1:\DeliveryOptimization\*"                >nul 2>&1
del /F /S /Q "%~1:\WUDownloadCache\*"                     >nul 2>&1
del /F /S /Q "%~1:\ProgramData\Microsoft\Windows\DeliveryOptimization\Cache\*" >nul 2>&1
del /F /S /Q "%~1:\.cache\*"                              >nul 2>&1
:: Interrupted / leftover feature-update staging folders. Only ever present
:: after a failed or completed in-place upgrade, and useless afterwards.
if exist "%~1:\$WINDOWS.~BT" rd /S /Q "%~1:\$WINDOWS.~BT" >nul 2>&1
if exist "%~1:\$Windows.~WS" rd /S /Q "%~1:\$Windows.~WS" >nul 2>&1
if exist "%~1:\$WinREAgent"  rd /S /Q "%~1:\$WinREAgent"  >nul 2>&1
echo %date% %time% : Swept drive %~1:                               >> %logs%
goto :eof

:userclean
:: %~1 = a user profile folder. Runs the per-user cache sweep for EVERY profile
:: on the machine, not only the one running the script.
:: Caches only - never Cookies, History, Login Data, Preferences or Bookmarks.
if not exist "%~1\AppData\Local" goto :eof
set "UL=%~1\AppData\Local"
set "UR=%~1\AppData\Roaming"
:: Chromium-family browsers, including ones that are not installed here
:: (guarded by :chromecache, which returns immediately if the folder is absent)
call :chromecache "%UL%\Google\Chrome\User Data" "chrome.exe"
call :chromecache "%UL%\Google\Chrome Beta\User Data" "chrome.exe"
call :chromecache "%UL%\Chromium\User Data" "chrome.exe"
call :chromecache "%UL%\Microsoft\Edge\User Data" "msedge.exe"
call :chromecache "%UL%\BraveSoftware\Brave-Browser\User Data" "brave.exe"
call :chromecache "%UL%\Vivaldi\User Data" "vivaldi.exe"
call :chromecache "%UL%\Opera Software\Opera Stable" "opera.exe"
call :chromecache "%UL%\Opera Software\Opera GX Stable" "opera.exe"
call :chromecache "%UL%\Yandex\YandexBrowser\User Data" "browser.exe"
:: Firefox family: cache2 / startupCache live under Local, and a stale
:: startupCache is the classic "Firefox opens with no window" bug.
call :isrunning "firefox.exe"
if not defined RUNNING for /d %%F in ("%UL%\Mozilla\Firefox\Profiles\*") do (
    del /F /S /Q "%%~F\cache2\*"        >nul 2>&1
    del /F /S /Q "%%~F\startupCache\*"  >nul 2>&1
    del /F /S /Q "%%~F\jumpListCache\*" >nul 2>&1
    del /F /S /Q "%%~F\thumbnails\*"    >nul 2>&1
)
goto :eof

:logvars
:: Called AFTER the mode is set. The old code logged %autoclean% inline on the
:: same line as the `set`, so cmd expanded it before the assignment ran and the
:: log recorded the PREVIOUS run's mode (empty on the first pass).
>>%logs% echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot%
goto :eof

:regset
:: %~1 key  %~2 value  %~3 type  %~4 data  %~5 label
:: Reads the current value BEFORE writing, so the log can distinguish "this
:: actually repaired something" from "this was already correct". Without it the
:: tool prints the same OK either way, which makes every report unfalsifiable.
:: reg query prints DWORDs as 0xNN, so numeric comparison goes through set /a.
set "RV="
for /f "tokens=3" %%A in ('reg query "%~1" /v "%~2" 2^>nul ^| findstr /i /c:"    %~2    REG_"') do set "RV=%%A"
reg add "%~1" /v "%~2" /t %~3 /d %~4 /f >nul 2>&1
if errorlevel 1 (
    call :L "%cErr%" "  FAILED   %~5 (write refused)"
    goto :eof
)
if not defined RV (
    call :L "%cOK%" "  SET      %~5 = %~4   (was absent)"
    goto :eof
)
if /i "%RV%"=="%~4" goto regset_same
set "RVN=" & set "TGN="
set /a RVN=%RV% 2>nul
set /a TGN=%~4 2>nul
if defined RVN if defined TGN if "%RVN%"=="%TGN%" goto regset_same
call :L "%cOK%" "  FIXED    %~5 : was %RV%, now %~4"
goto :eof
:regset_same
call :L "%cInfo%" "  already  %~5 = %~4"
goto :eof

:isrunning
:: %~1 = image name -> RUNNING=1 when that process exists
set "RUNNING="
tasklist /fi "imagename eq %~1" /nh 2>nul | findstr /i /b /c:"%~1" >nul 2>&1 && set "RUNNING=1"
goto :eof

:banner
:: %~1 = title. ASCII only on purpose: Unicode box-drawing characters render as
:: garbage as soon as the console code page is not the one the file was saved in.
:: Colour comes from ANSI, which is code-page independent.
echo(%cT%===============================================================================%cR%
:: %~1 is echoed through delayed expansion: %~1 strips the quotes, so a title
:: containing & or ^ would otherwise be re-parsed as a command separator.
setlocal enabledelayedexpansion
set "BTITLE=%~1"
echo(%cT%   !BTITLE!%cR%
endlocal
echo(%cT%===============================================================================%cR%
goto :eof

:rule
echo(%cInfo%-------------------------------------------------------------------------------%cR%
goto :eof

:nicecho
:: %~1 = class key, %~2 = adapter description. %NCOUNT% is re-expanded on CALL,
:: which is how we read a counter incremented inside a FOR block without
:: enabling delayed expansion.
echo(   %cVal%%NCOUNT%.%cR% %~2
goto :eof

:nicpick
:: %~1 = user choice, %~2 = class key, %~3 = description
if not "%~1"=="%NSEL%" goto :eof
set "NICKEY=%~2"
set "NICDESC=%~3"
goto :eof

:nicset
:: %~1 = class key, %~2 = NDIS keyword, %~3 = desired value
:: NDIS keywords are REG_SZ - writing REG_DWORD is silently ignored by the driver.
:: The value is clamped to the driver's own max and rounded down to its step,
:: both read from Ndi\Params, so nothing is ever hardcoded per chipset.
:: Keywords this driver does not expose are skipped.
reg query "%~1\Ndi\Params\%~2" >nul 2>&1 || goto :eof
set "NV=%~3"
set "NMAX="
set "NSTEP="
for /f "tokens=3" %%M in ('reg query "%~1\Ndi\Params\%~2" /v max 2^>nul ^| findstr /i "REG_SZ"') do set "NMAX=%%M"
for /f "tokens=3" %%M in ('reg query "%~1\Ndi\Params\%~2" /v step 2^>nul ^| findstr /i "REG_SZ"') do set "NSTEP=%%M"
if defined NMAX call :nicclamp
if defined NSTEP call :nicround
:: report whether this actually repaired anything - on a fresh or OEM machine
:: these often differ, on an already-tuned one they will all say "already"
set "OLDV="
for /f "tokens=3" %%O in ('reg query "%~1" /v "%~2" 2^>nul ^| findstr /i /c:"REG_SZ"') do set "OLDV=%%O"
reg add "%~1" /v "%~2" /t REG_SZ /d "%NV%" /f >nul 2>&1
if not defined OLDV (
    call :L "%cOK%" "  SET      %~2 = %NV%   (was absent)"
) else if "%OLDV%"=="%NV%" (
    call :L "%cInfo%" "  already  %~2 = %NV%"
) else (
    call :L "%cOK%" "  FIXED    %~2 : was %OLDV%, now %NV%"
)
goto :eof

:nicclamp
:: bail out if NMAX is not purely numeric (the FOR finds a token only then)
for /f "delims=0123456789" %%X in ("%NMAX%") do goto :eof
if %NV% GTR %NMAX% set "NV=%NMAX%"
goto :eof

:nicround
for /f "delims=0123456789" %%X in ("%NSTEP%") do goto :eof
if %NSTEP% LEQ 0 goto :eof
set /a NV=(NV/NSTEP)*NSTEP
goto :eof

:nicenummax
:: %~1 = class key, %~2 = keyword -> NENUMMAX = highest value the driver enumerates
:: (the I211 only enumerates 1 and 2 RSS queues - asking for 4 or 8 is a myth)
set "NENUMMAX="
for /f "tokens=1" %%E in ('reg query "%~1\Ndi\Params\%~2\Enum" 2^>nul ^| findstr /i "REG_SZ"') do set "NENUMMAX=%%E"
goto :eof

:nicdefault
:: %~1 = class key, %~2 = full Ndi\Params\<keyword> key
:: Restores that keyword to the factory value the driver itself ships.
set "NKW=%~2"
set "NKW=%NKW:*\Ndi\Params\=%"
if not defined NKW goto :eof
set "NDEF="
for /f "tokens=3" %%D in ('reg query "%~2" /v default 2^>nul ^| findstr /i "REG_SZ"') do set "NDEF=%%D"
if not defined NDEF goto :eof
reg add "%~1" /v "%NKW%" /t REG_SZ /d "%NDEF%" /f >nul 2>&1
call :L "%cInfo%" "  %NKW% = %NDEF%  (driver default)"
goto :eof

:nicrestart
:: %~1 = class key -> restart the device so NDIS re-reads the keywords, no reboot
set "NGUID="
set "NPNP="
for /f "tokens=3" %%G in ('reg query "%~1" /v NetCfgInstanceId 2^>nul ^| findstr /i "REG_SZ"') do set "NGUID=%%G"
if not defined NGUID goto :eof
for /f "tokens=2,*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Network\{4d36e972-e325-11ce-bfc1-08002be10318}\%NGUID%\Connection" /v PnPInstanceId 2^>nul ^| findstr /i "PnPInstanceId"') do set "NPNP=%%B"
if not defined NPNP goto :eof
call :L "%cWarn%" "Restarting adapter - the link will drop for a few seconds..."
pnputil /restart-device "%NPNP%" >nul 2>&1
call :L "%cOK%" "Adapter restarted - settings are live."
goto :eof

:killkey
:: %~1 = registry key, %~2 = value name
:: Deletes the value ONLY if it exists, and reports it. Used for settings whose
:: Windows default is "value absent" - writing 0 would NOT restore them.
reg query "%~1" /v "%~2" >nul 2>&1 || goto :eof
call :L "%cWarn%" "  leftover found: %~2  -> removing (default is ABSENT)"
>>%logs% echo %date% %time% : Removed leftover %~1\%~2
reg delete "%~1" /v "%~2" /f >nul 2>&1
goto :eof

:NH
:: %~1 = section title -> banner inside the NIC report + live progress line
echo(  %cInfo%- %~1%cR%
>>"%NICTXT%" echo(
>>"%NICTXT%" echo ============================================================
>>"%NICTXT%" echo == %~1
>>"%NICTXT%" echo ============================================================
goto :eof

:restore_point
:: Create ONE system restore point per session, before any destructive change.
:: Uses powershell.exe only here (no native CMD equivalent since WMIC is deprecated).
if defined RP_DONE goto :eof
set "RP_DONE=1"
echo.                                                           >> %logs%
echo ====================== :RESTORE_POINT ==================== >> %logs%
echo %date% %time% : Creating system restore point               >> %logs%
call :L "%cStep%" "Creating a System Restore Point - safety net before changes..."
powershell -NoProfile -Command "Enable-ComputerRestore -Drive '%SystemDrive%\'" >nul 2>&1
:: Windows refuses a second restore point within 1440 minutes, so the throttle
:: is lifted just long enough to create ours - then put straight back. The old
:: code left it at 0 forever, silently changing how System Protection behaves
:: on the machine long after OPTY had exited.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "Checkpoint-Computer -Description 'OPTY v%current_version% - before optimization' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if errorlevel 1 (
    call :L "%cWarn%" "Restore point not created - System Protection may be off, continuing"
) else (
    call :L "%cOK%" "Restore point created"
)
:: Put the throttle back to the Windows default (1440 minutes) so OPTY does not
:: leave System Protection permanently altered behind it.
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d 1440 /f >nul 2>&1
echo %date% %time% : Restore-point throttle put back to 1440 min     >> %logs%
goto :eof