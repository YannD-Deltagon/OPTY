:::: OPTY by @YannD-Deltagon ::::

@echo off
set current_version=04.1
set GitHubRawLink=https://raw.githubusercontent.com/YannD-Deltagon/OPTY/master/resources/
set GitHubLatestLink=https://github.com/YannD-Deltagon/OPTY/releases/latest/download/

:: ---- User / paths configuration (edit here if your username or layout differs) ----
set "USERHOME=C:\Users\compt"
set "WSL_DOCKER_VHDX=%USERHOME%\AppData\Local\Docker\wsl\disk\docker_data.vhdx"
set "WSL_SEARCH1=%USERHOME%\AppData\Local\Packages"
set "WSL_SEARCH2=%USERHOME%\AppData\Local\wsl"
set "DOCKER_EXE=C:\Program Files\Docker\Docker\Docker Desktop.exe"

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
for /f "skip=15 delims=" %%F in ('dir /b /a-d /o:-d "%~dp0logs_*.txt"') do (
    del "%~dp0%%F"
)

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
if not "%~dp0" == "C:\OPTY_by-YannD\" (
    echo %date% %time% : Creating shortcut folder & copying script >> %logs%
    md "C:\OPTY_by-YannD"
    xcopy /y "%~dp0OPTY.bat" "C:\OPTY_by-YannD"
    echo %date% %time% : Starting script from new location         >> %logs%
    start "" "C:\OPTY_by-YannD\OPTY.bat"
    echo %date% %time% : Deleting original script                  >> %logs%
    del "%~dp0OPTY.bat"
    exit
)

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
for /f "tokens=2 delims=V" %%a in ('curl -s https://api.github.com/repos/YannD-Deltagon/OPTY/releases/latest -L -H "Accept: application/json" ^| findstr "tag_name"') do set latest_version=%%a
set latest_version=%latest_version:~0,-2%
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
if /i "%choice%"=="N" goto update_found_and_not_accepted

:update_found_and_accepted
echo.                                                           >> %logs%
echo ====================== :UPDATE_FOUND_AND_ACCEPTED ======== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :update_found_and_accepted label    >> %logs%
cls
color 02
echo.                                                  
curl -o "%~dp0\new_OPTY.bat" -LJO %GitHubLatestLink%OPTY.bat
echo %date% %time% : Downloaded new_OPTY.bat                   >> %logs%
echo.                                                  
echo The script has been updated to %latest_version%.           
echo.                                                  
move /y "%~dp0new_OPTY.bat" "%~dp0OPTY.bat"
echo %date% %time% : Replaced old OPTY.bat with new version     >> %logs%
start "" "%~dp0OPTY.bat"
echo %date% %time% : Relaunched updated script                  >> %logs%
exit

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
color F1
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo.                                                  
echo.                                                  
echo.                                                  
echo.                                                  
echo   1. MENU - Clean + Optimization                                  
echo   2. MENU - Re-enable option                                      
echo   3. MENU - Register profil option                                
echo.                                                  
echo   9. Clean OPTY and delete all files                              
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
echo   0. Exit                                                         
echo.                                                  
echo.                                                  
set "choice="
set /p choice= Enter action:
echo %date% %time% : Menu.bat-menuadmin "%choice%"                    >> %logs%
if "%choice%"=="1" (call :restore_point & goto mopti)
if "%choice%"=="2" (call :restore_point & goto mreenable)
if "%choice%"=="3" (call :restore_point & goto mregprofil)
if "%choice%"=="9" goto Clean_Opty_Curl
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
if /i "%choice%"=="1" set autoclean=0 & set autoshutdownreboot=5 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto mdisenable
if /i "%choice%"=="2" set autoclean=1 & set autoshutdownreboot=0 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto wupdate
if /i "%choice%"=="3" set autoclean=2 & set autoshutdownreboot=0 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto stopapps
if /i "%choice%"=="2s" set autoclean=1 & set autoshutdownreboot=1 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto wupdate
if /i "%choice%"=="3s" set autoclean=2 & set autoshutdownreboot=1 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto stopapps
if /i "%choice%"=="2r" set autoclean=1 & set autoshutdownreboot=2 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto wupdate
if /i "%choice%"=="3r" set autoclean=2 & set autoshutdownreboot=2 & echo %date% %time% : Variables - autoclean=%autoclean%, autoshutdownreboot=%autoshutdownreboot% >> %logs% & goto stopapps
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
if "%autoclean%"=="2" goto netdns_tcp
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
dism /Online /Cleanup-image /StartComponentCleanup /ResetBase
echo %date% %time% : Executed DISM /StartComponentCleanup /ResetBase    >> %logs%
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
echo Cleanmgr...                                                 
if /i "%autoclean%"=="2" (cleanmgr /verylowdisk & goto clean_wsl)
cleanmgr /sageset:65535
echo %date% %time% : Executed cleanmgr /sageset:65535              >> %logs%
pause
cleanmgr /sagerun:65535
echo %date% %time% : Executed cleanmgr /sagerun:65535              >> %logs%
timeout /t 5


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
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\StorageSense" /v "AllowStorageSenseGlobal" /t REG_DWORD /d 1 /f >nul
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

:: --- Delivery Optimization cache ---
echo %date% %time% : Deleting Delivery Optimization files             >> %logs%
del /F /S /Q "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache\*"

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

:: --- GPU / Shader caches (safe to clear, auto-regenerated) ---
echo %date% %time% : Deleting GPU caches                                >> %logs%
del /S /F /Q "%LOCALAPPDATA%\AMD\DxCache\*"
del /S /F /Q "%ProgramData%\NVIDIA Corporation\NV_Cache\*"
del /S /F /Q "%LOCALAPPDATA%\Intel\ShaderCache\*"

:: NVIDIA GL/DX caches (user)
del /S /F /Q "%LOCALAPPDATA%\NVIDIA\GLCache\*"        2>nul
del /S /F /Q "%LOCALAPPDATA%\NVIDIA\DXCache\*"        2>nul

:: AMD GL/Vulkan caches (user)
del /S /F /Q "%LOCALAPPDATA%\AMD\GLCache\*"           2>nul
del /S /F /Q "%LOCALAPPDATA%\AMD\VkCache\*"           2>nul

echo %date% %time% : Deleting DirectX Shader Cache                       >> %logs%
del /S /F /Q "%LOCALAPPDATA%\D3DSCache\*"
del /S /F /Q "%LOCALAPPDATA%\Microsoft\DirectX Shader Cache\*"

:: --- DaVinci Resolve caches (user scope only) ---
echo %date% %time% : Deleting DaVinci Resolve media cache (user)        >> %logs%
del /F /S /Q "%USERHOME%\Documents\DaVinci\*"
echo %date% %time% : Deleting DaVinci AppData Roaming CacheClip >> %logs%
del /F /S /Q "%USERHOME%\AppData\Roaming\Blackmagic Design\DaVinci Resolve\Support\CacheClip\*"

:: --- Dumps (facultatif mais sans impact sur réglages) ---
echo %date% %time% : Deleting MiniDump files                             >> %logs%
del /F /S /Q "%SystemRoot%\Minidump\*"
echo %date% %time% : Deleting Memory Dump file                           >> %logs%
del /F /S /Q "%SystemRoot%\MEMORY.DMP"

:: OPTIONAL - Edge WebView2 runtime caches (safe, but may trigger recompile)
:: set CLEAR_WEBVIEW2=1
echo %date% %time% : Clearing Edge WebView2 caches               >> %logs%
del /S /F /Q "%LOCALAPPDATA%\Microsoft\EdgeWebView\Cache\*" 2>nul
del /S /F /Q "%LOCALAPPDATA%\Microsoft\EdgeWebView\User Data\Default\Code Cache\*" 2>nul
del /S /F /Q "%LOCALAPPDATA%\Microsoft\EdgeWebView\User Data\Default\Cache\*" 2>nul

:: Recycle Bin fallback per drive (silent)
for %%D in (C D E F) do if exist "%%D:\" (
  rd /S /Q "%%D:\$Recycle.Bin" 2>nul
)

:: --- Thumbnail & icon cache (rebuilt automatically; locked files are skipped) ---
echo %date% %time% : Deleting thumbnail/icon cache                  >> %logs%
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*.db" 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Windows\Explorer\iconcache_*.db" 2>nul

:: --- Windows Error Reporting reports + crash dumps ---
echo %date% %time% : Deleting WER reports and crash dumps           >> %logs%
del /F /S /Q "%ProgramData%\Microsoft\Windows\WER\*" 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Windows\WER\*" 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\CrashDumps\*" 2>nul

:: --- Old servicing / setup logs (CBS, Panther) ---
echo %date% %time% : Deleting CBS and Panther logs                  >> %logs%
del /F /S /Q "%WINDIR%\Logs\CBS\*" 2>nul
del /F /S /Q "%WINDIR%\Panther\*" 2>nul

:: --- Legacy IE/Edge system web cache (INetCache) ---
echo %date% %time% : Deleting INetCache                             >> %logs%
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Windows\INetCache\*" 2>nul

:: --- GPU driver extraction leftovers (NOT the installed drivers) ---
echo %date% %time% : Deleting driver extraction folders            >> %logs%
rd /S /Q "C:\NVIDIA" 2>nul
rd /S /Q "C:\AMD"    2>nul
rd /S /Q "C:\Intel"  2>nul

:: --- Browser + Store (closes apps): FULL mode only, skipped in Auto-lite ---
if not "%autoclean%"=="2" goto delete_skip_apps
echo %date% %time% : Closing Edge/Chrome and clearing their caches  >> %logs%
taskkill /f /im msedge.exe  >nul 2>&1
taskkill /f /im chrome.exe  >nul 2>&1
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Edge\User Data\Default\Cache\*"        2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Edge\User Data\Default\Code Cache\*"   2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Edge\User Data\Default\GPUCache\*"     2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Google\Chrome\User Data\Default\Cache\*"         2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Google\Chrome\User Data\Default\Code Cache\*"    2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Google\Chrome\User Data\Default\GPUCache\*"      2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Microsoft\Edge\User Data\Default\Service Worker\CacheStorage\*"  2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Google\Chrome\User Data\Default\Service Worker\CacheStorage\*"   2>nul

:: --- Microsoft Store download cache (wsreset) ---
echo %date% %time% : Resetting Microsoft Store cache               >> %logs%
start "" wsreset.exe
timeout /t 15 /nobreak >nul
taskkill /f /im "WinStore.App.exe" >nul 2>&1
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

call :L "%cInfo%" "Cleaning app caches (Spotify / Teams / Discord)"
del /F /S /Q "%USERHOME%\AppData\Local\Spotify\Storage\*"             2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Spotify\Data\*"                2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\Spotify\Storage\*"           2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\discord\Cache\*"             2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\discord\Code Cache\*"        2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\discord\GPUCache\*"          2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\Microsoft\Teams\Cache\*"     2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\Microsoft\Teams\GPUCache\*"  2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\*" 2>nul

call :L "%cInfo%" "Cleaning game launcher caches (Steam / Ubisoft / EA / Origin / Epic)"
:: Steam: install path from registry; shadercache + http cache + logs/dumps (rebuilt on launch)
set "STEAMPATH="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul ^| findstr /i "InstallPath"') do set "STEAMPATH=%%b"
if not defined STEAMPATH goto delete_skip_steam
rd /S /Q "%STEAMPATH%\steamapps\shadercache"    2>nul
del /F /S /Q "%STEAMPATH%\appcache\httpcache\*"  2>nul
del /F /S /Q "%STEAMPATH%\logs\*"                2>nul
del /F /S /Q "%STEAMPATH%\dumps\*"               2>nul
:delete_skip_steam
set "STEAMPATH="
del /F /S /Q "%USERHOME%\AppData\Local\Ubisoft Game Launcher\cache\*"        2>nul
del /F /S /Q "C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\cache\*"  2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Electronic Arts\EA Desktop\cache\*"   2>nul
del /F /S /Q "%ProgramData%\EA Core\cache\*"                                 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\Origin\*"                             2>nul
del /F /S /Q "%ProgramData%\Origin\*"                                        2>nul
for /d %%W in ("%USERHOME%\AppData\Local\EpicGamesLauncher\Saved\webcache*") do rd /S /Q "%%W" 2>nul
del /F /S /Q "%USERHOME%\AppData\Local\EpicGamesLauncher\Saved\Logs\*"       2>nul

call :L "%cInfo%" "Cleaning Adobe media cache (Premiere / After Effects / Media Encoder)"
del /F /S /Q "%USERHOME%\AppData\Roaming\Adobe\Common\Media Cache Files\*"   2>nul
del /F /S /Q "%USERHOME%\AppData\Roaming\Adobe\Common\Media Cache\*"         2>nul

call :L "%cInfo%" "Clearing font cache (Prefetch left intact - it speeds up app launches)"
net stop FontCache >nul 2>&1
del /F /S /Q "%WINDIR%\ServiceProfiles\LocalService\AppData\Local\FontCache\*" 2>nul
del /F /Q "%WINDIR%\System32\FNTCACHE.DAT" 2>nul
net start FontCache >nul 2>&1

if not "%autoclean%"=="2" goto delete_skip_vss
call :L "%cInfo%" "Trimming old restore points (keeping the most recent)"
set "SHCOUNT=0"
for /f %%c in ('vssadmin list shadows /for=%SystemDrive% 2^>nul ^| find /c "HarddiskVolumeShadowCopy"') do set "SHCOUNT=%%c"
echo %date% %time% : Shadow copies on %SystemDrive% = %SHCOUNT%      >> %logs%
:vss_trim_loop
if %SHCOUNT% LEQ 1 goto vss_trim_done
vssadmin delete shadows /for=%SystemDrive% /oldest /quiet >nul 2>&1
set /a SHCOUNT-=1
goto vss_trim_loop
:vss_trim_done
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
if not defined FREE_BEFORE set "FREE_BEFORE=0"
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
taskkill /f /im chrome.exe
echo %date% %time% : Killed Chrome processes                       >> %logs%
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
echo.                                                           >> %logs%
echo %date% %time% : Entered :mregprofil label                       >> %logs%
color FC
cls
echo.                                                  
echo  WELCOME to OPTY by @YannD-Deltagon                         
echo    Optimize your Registry, mouse, and power settings              
echo      Choose your desired profile:                                  
echo.                                                  
echo.                                                  
echo   1. Mouse and power only                                          
echo   10. Mouse and power only-
echo   2. Gaming / Performance tweaks
echo   3. Debloat 2026 (Recall / Copilot / sponsored apps / Widgets)
echo   4. Re-assert good Windows defaults (Firewall / Defender / UAC / system)
echo   5. Display tweaks (MPO / HAGS) - test on/off, can flicker multi-monitor
echo   20. Restore ALL profile defaults (gaming + debloat + services)                                        
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
echo %date% %time% : RegProfil.bat-mregprofil "%choice%"              >> %logs%
if "%choice%"=="1" goto map_only
if "%choice%"=="10" goto map_only-
if "%choice%"=="2" goto gaming_perf
if "%choice%"=="3" goto debloat2026
if "%choice%"=="4" goto reassert_defaults
if "%choice%"=="5" goto display_tweaks
if "%choice%"=="20" goto gaming_restore
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mregprofil                     >> %logs%
timeout /t 5
goto mregprofil


:gaming_perf
echo.                                                           >> %logs%
echo ====================== :GAMING_PERF ====================== >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :gaming_perf label                   >> %logs%
color FC
cls
call :L "%cStep%" "Applying Gaming / Performance tweaks (registry, power, network)..."

call :L "%cInfo%" "Game priority (MMCSS) + foreground boost"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 10 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 6 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul

call :L "%cInfo%" "Game Mode ON (HAGS and MPO moved to menu 3 -> 5: Display tweaks)"
reg add "HKCU\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Disabling CPU power throttling"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul

call :L "%cInfo%" "Network latency: throttling off + Nagle off on all interfaces"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /b /i "HKEY"') do (
    reg add "%%K" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
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
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul

call :L "%cInfo%" "Disabling telemetry scheduled tasks (Appraiser / CEIP / DmClient)"
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\PcaPatchDbTask" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\StartupAppTask" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClient" /Disable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" /Disable >nul 2>&1

call :L "%cInfo%" "Disabling VBS / Memory Integrity HVCI for gaming - security tradeoff"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul

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
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul
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
schtasks /Change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Enable >nul 2>&1
schtasks /Change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /Enable >nul 2>&1
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
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 1 /f >nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /f >nul 2>&1

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
reg delete "HKLM\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /f >nul 2>&1
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

call :L "%cOK%" "All profile defaults restored (gaming + debloat + services). Game Mode/HAGS left as-is."
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
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "EnableLUA" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "ConsentPromptBehaviorAdmin" /t REG_DWORD /d 5 /f >nul

call :L "%cInfo%" "System perf defaults: TRIM on, SysMain/Prefetch on, system-managed pagefile"
fsutil behavior set disabledeletenotify 0 >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000003 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000003 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "AutomaticManagedPagefile" /t REG_DWORD /d 1 /f >nul
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
echo    Display tweaks - test individually, REBOOT after each.
echo.
echo    WARNING: these can FIX or CAUSE flicker/stutter, especially on
echo    multi-monitor setups with mixed refresh rates or VRR (FreeSync/G-Sync).
echo.
echo   1. Disable MPO (Multi-Plane Overlay)
echo   2. Re-enable MPO  (Windows default)
echo.
echo   3. Enable HAGS  (Hardware-accelerated GPU Scheduling)
echo   4. Disable HAGS (Windows default)
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
call :L "%cWarn%" "Disabling MPO - can FIX or CAUSE multi-monitor flicker. Reboot after."
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
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul
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
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set SearchOrderConfig=0                            >> %logs%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_SZ /d "00000000" /f
echo %date% %time% : Set AllowGameDVR value=00000000 (machine-level)     >> %logs%
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set GameDVR_Enabled=0 (user-level)                  >> %logs%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set AllowGameDVR=0 under Policies\Windows\GameDVR   >> %logs%
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
sc stop Spooler
echo %date% %time% : Stopped service: Spooler                            >> %logs%
sc stop DPS
echo %date% %time% : Stopped service: DPS                                  >> %logs%
sc stop TabletInputService
echo %date% %time% : Stopped service: TabletInputService                 >> %logs%
sc config "WSearch" start= demand
echo %date% %time% : Configured WSearch start= demand                      >> %logs%
sc config "WerSvc" start= demand
echo %date% %time% : Configured WerSvc start= demand                         >> %logs%
sc config "Spooler" start= demand
echo %date% %time% : Configured Spooler start= demand                       >> %logs%
sc config "DPS" start= demand
echo %date% %time% : Configured DPS start= demand                            >> %logs%
sc config "TabletInputService" start= disabled
echo %date% %time% : Disabled TabletInputService                            >> %logs%
pause
echo %date% %time% : Exiting :regsc_map_only, going to :mregpowercfg       >> %logs%
goto mregpowercfg

:map_only-
echo.                                                           >> %logs%
echo ====================== :MAP_ONLY- ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :map_only- label                         >> %logs%
cls
echo %date% %time% : (map_only-) Re-asserting SysMain/Prefetch good defaults    >> %logs%
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000003 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000003 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 00000000 /f
echo %date% %time% : (map_only-) Set SearchOrderConfig=0              >> %logs%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_SZ /d "00000000" /f
echo %date% %time% : (map_only-) Set AllowGameDVR value=00000000       >> %logs%
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 00000000 /f
echo %date% %time% : (map_only-) Set GameDVR_Enabled=0                 >> %logs%
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 00000000 /f
echo %date% %time% : (map_only-) Set AllowGameDVR=0                    >> %logs%
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 00000000 /f
echo %date% %time% : (map_only-) Set AppCaptureEnabled=0               >> %logs%
powercfg /h off
echo %date% %time% : (map_only-) Disabled hibernation                  >> %logs%
timeout /t 5
goto regsc_map_only-

:regsc_map_only-
echo.                                                           >> %logs%
echo ====================== :REGSC_MAP_ONLY- ==================  >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :regsc_map_only- label                  >> %logs%
pause
echo %date% %time% : Exiting :regsc_map_only-, going to :mregpowercfg  >> %logs%
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
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
echo %date% %time% : Duplicated "Ultimate Performance" power plan      >> %logs%
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
echo.                                                           >> %logs%
echo %date% %time% : Entered :mouseantilag label                     >> %logs%
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f
echo %date% %time% : Set MouseSensitivity=10 (neutral pointer speed)  >> %logs%
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f
echo %date% %time% : Set MouseSpeed=0 (Enhance pointer precision OFF) >> %logs%
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f
echo %date% %time% : Set MouseThreshold1=0                            >> %logs%
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f
echo %date% %time% : Set MouseThreshold2=0                            >> %logs%
pause
goto menu



:Clean_Opty_Curl
echo.                                                           >> %logs%
echo ====================== :CLEAN_OPTY_CURL ================= >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :Clean_Opty_Curl label                >> %logs%
for /f "delims=" %%f in ('dir /b /a-d "%~dp0" ^| findstr /i /v "OPTY.bat"') do (
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
echo(%~1%~2%cR%
>>%logs% echo %date% %time% : %~2
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
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "Checkpoint-Computer -Description 'OPTY v%current_version% - before optimization' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if errorlevel 1 (
    call :L "%cWarn%" "Restore point not created - System Protection may be off, continuing"
) else (
    call :L "%cOK%" "Restore point created"
)
goto :eof