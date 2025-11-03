:::: OPTY by @YannD-Deltagon ::::

@echo off
set current_version=02.4
set GitHubRawLink=https://raw.githubusercontent.com/YannD-Deltagon/OPTY/master/resources/
set GitHubLatestLink=https://github.com/YannD-Deltagon/OPTY/releases/latest/download/

cd /d "%~dp0"
for /f "skip=15 delims=" %%F in ('dir /b /a-d /o:-d "%~dp0logs_*.txt"') do (
    del "%~dp0%%F"
)

set current_time="%time:~0,5%"
set current_time="%current_time::=-%"
set logs="%~dp0\logs_%date%_%current_time%.txt"

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
set /p choice= Enter action:
echo %date% %time% : Menu.bat-menuadmin "%choice%"                    >> %logs%
if "%choice%"=="1" goto mopti
if "%choice%"=="2" goto mreenable
if "%choice%"=="3" goto mregprofil
if "%choice%"=="9" goto Clean_Opty_Curl
if "%choice%"=="0" goto end
if "%choice%"=="." goto update_opty
if "%choice%"=="-" goto mupdate_perso
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid menu choice                             >> %logs%
timeout /t 5
goto menu


:mopti
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
ipconfig /flushdns
echo %date% %time% : Executed ipconfig /flushdns                      >> %logs%
netsh int ip reset
echo %date% %time% : Executed netsh int ip reset                      >> %logs%
netsh winsock reset
echo %date% %time% : Executed netsh winsock reset                     >> %logs%
netsh winsock reset proxy
echo %date% %time% : Executed netsh winsock reset proxy               >> %logs%
if /i %autoclean% == 2 goto dism
timeout /t 5


:mdism
echo.                                                           >> %logs%
echo ====================== :MDISM ======================        >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdism label                            >> %logs%
cls
echo Do you want to DISM the Windows image and correct problems?
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
dism /Online /Cleanup-image /ScanHealth
echo %date% %time% : Executed DISM /ScanHealth                         >> %logs%
dism /Online /Cleanup-image /CheckHealth
echo %date% %time% : Executed DISM /CheckHealth                        >> %logs%
dism /Online /Cleanup-image /RestoreHealth
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
sfc /scannow
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
usoclient StartScan
echo %date% %time% : Executed usoclient StartScan                      >> %logs%
usoclient RefreshSettings
echo %date% %time% : Executed usoclient RefreshSettings                >> %logs%
usoclient StartInstall
echo %date% %time% : Executed usoclient StartInstall                   >> %logs%
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
cleanmgr /sageset:65535
echo %date% %time% : Executed cleanmgr /sageset:65535              >> %logs%
pause
cleanmgr /sagerun:65535
echo %date% %time% : Executed cleanmgr /sagerun:65535              >> %logs%
timeout /t 5


:mdelete
echo.                                                           >> %logs%
echo ====================== :MDELETE ======================      >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdelete label                          >> %logs%
cls
echo Do you want to delete temporary files - DEL?
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
del /S /F /Q "%WINDIR%\Temp"
rd /S /Q "%WINDIR%\Temp" 2>nul

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
del /F /S /Q "C:\Users\compt\Documents\DaVinci\*"
echo %date% %time% : Deleting DaVinci AppData Roaming CacheClip >> %logs%
del /F /S /Q "C:\Users\compt\AppData\Roaming\Blackmagic Design\DaVinci Resolve\Support\CacheClip\*"

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

echo %date% %time% : :delete done                                        >> %logs%

if /i %autoclean% == 1 goto mshutdownreboot
if /i %autoclean% == 2 goto defrag
timeout /t 5


:mdefrag
echo.                                                           >> %logs%
echo ====================== :MDEFRAG ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mdefrag label                          >> %logs%
cls
echo Do you want to defragment HDD or optimize SSD - DEFRAG?
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
defrag /C /O /U /V /H
echo %date% %time% : Executed defrag /C /O /U /V /H                 >> %logs%
if /i %autoclean% == 2 goto endready
timeout /t 5


:mchkdsk
echo.                                                           >> %logs%
echo ====================== :MCHKDSK ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :mchkdsk label                          >> %logs%
cls
echo Do you want to check drive integrity and fix issues - CHKDSK?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mchkdsk "%choice%"                            >> %logs%
if /i "%choice%"=="1" goto chkdsk
if /i "%choice%"=="2" goto mshutdownreboot
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
CHKDSK /f /r
echo %date% %time% : Executed CHKDSK /f /r                         >> %logs%
if /i %autoclean% == 2 goto endready
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
set /p choice= Enter action:
echo %date% %time% : RegProfil.bat-mregprofil "%choice%"              >> %logs%
if "%choice%"=="1" goto map_only
if "%choice%"=="10" goto map_only-
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action                                      
echo %date% %time% : Invalid option in :mregprofil                     >> %logs%
timeout /t 5
goto mregprofil

:map_only
echo.                                                           >> %logs%
echo ====================== :MAP_ONLY ======================       >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :map_only label                         >> %logs%
cls
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set EnablePrefetcher=0                           >> %logs%
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000000 /f
echo %date% %time% : Set EnableSuperfetch=0                            >> %logs%
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
sc stop WSearch
echo %date% %time% : Stopped service: WSearch                           >> %logs%
sc stop SysMain
echo %date% %time% : Stopped service: SysMain                            >> %logs%
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
sc config "SysMain" start= demand
echo %date% %time% : Configured SysMain start= demand                       >> %logs%
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
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000000 /f
echo %date% %time% : (map_only-) Set EnablePrefetcher=0                >> %logs%
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000000 /f
echo %date% %time% : (map_only-) Set EnableSuperfetch=0               >> %logs%
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
echo %date% %time% : Set MouseSensitivity=10                         >> %logs%
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d "0000000000CCCCC0809919406626003333" /f
echo %date% %time% : Set SmoothMouseXCurve                           >> %logs%
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d "0000000000003800000070000000A8000000E000" /f
echo %date% %time% : Set SmoothMouseYCurve                           >> %logs%
pause
goto menu


:nshutdown
echo.                                                           >> %logs%
echo ====================== :NSHUTDOWN =====================     >> %logs%
echo.                                                           >> %logs%
echo %date% %time% : Entered :nshutdown label                         >> %logs%
echo.                                                  
shutdown /a                                                     
echo.                                                  
echo The computer will not restart.                                  
echo.                                                  
timeout /t 10
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