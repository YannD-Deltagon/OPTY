:::: CHANGELOGS ::::
:: 2025-05-31  :                      Re-Master all







@echo off
REM set variables
set current_version=02.0
set GitHubRawLink=https://raw.githubusercontent.com/YannD-Deltagon/OPTY/master/resources/
set GitHubLatestLink=https://github.com/YannD-Deltagon/OPTY/releases/latest/download/
REM Set variables for logs
cd /d "%~dp0"
set current_time="%time:~0,5%"
set current_time="%current_time::=-%"
set logs="%~dp0\logs_%date%_%current_time%.txt"

REM Check if running as administrator
net session >nul 2>&1
if %errorlevel% == 0 (
    echo %date% %time% : Admin >> %logs%
    goto shortcut
) else (
    echo %date% %time% : User >> %logs%
    echo.
    echo   Not running as administrator
    echo   lanch with admin right
    echo.
    timeout /t 15
    exit
)


REM Check if running from C:\OPTY_by-YannD\OPTY.bat if not copy it to C:\OPTY_by-YannD\OPTY.bat
:shortcut
if not "%~dp0" == "C:\OPTY_by-YannD\" (
    echo %date% %time% : Creat shurtcut >> %logs%
    md "C:\OPTY_by-YannD"
    xcopy /y %~dp0OPTY.bat C:\OPTY_by-YannD
    start "" "C:\OPTY_by-YannD\OPTY.bat"
    del "%~dp0OPTY.bat"
    exit
)


REM Check if internet connection is available and ping github.com
:ping_github
set loop_pinggh=0
color 60
:ping_github_loop
cls
echo.
echo  Check GitHub ping...
echo.
ping -n 1 -l 8 github.com | find "TTL="
if %errorlevel%==0 (
    echo %date% %time% : Ping GitHub ok >> %logs%
    color 20
    echo.
    echo  Ping check successful.
    echo.
    goto update_opty
) else (
    echo %date% %time% : Ping GitHub ko for %loop_pinggh% time >> %logs%
    color 40
    echo.
    echo  Ping check failed, retrying...
    echo   error : %errorlevel%
	echo   ko : %loop_pinggh% "(max : 5)"
    echo.
    set /a loop_pinggh=%loop_pinggh%+1
    if %loop_pinggh%==5 goto ping_github_failed
    timeout /t 1
    goto ping_github_loop
)


REM If ping failed 5 times
:ping_github_failed
cls
color c0
echo.
echo  Ping check failed.
echo  local mode
echo.
timeout /t 5
goto update_not_available


REM Update OPTY.bat
:update_opty
color 0A
cls
echo.
echo  Check Update for this script...
echo.
for /f "tokens=2 delims=V" %%a in ('curl -s https://api.github.com/repos/YannD-Deltagon/OPTY/releases/latest -L -H "Accept: application/json"^|findstr "tag_name"') do set latest_version=%%a
set latest_version=%latest_version:~0,-2%
if "%current_version%"=="%latest_version%" goto update_not_available
echo %date% %time% : Update found >> %logs%
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
if /i "%choice%"=="Y" goto update_found_and_accepted
if /i "%choice%"=="N" goto update_found_and_not_accepted

REM If user accept update, download new OPTY.bat and replace the old one
:update_found_and_accepted
echo %date% %time% : Update found and accepted >> %logs%
cls
color 02
echo.
curl -o "%~dp0\new_OPTY.bat" -LJO %GitHubLatestLink%OPTY.bat
echo.
echo The script has been updated to %latest_version%.
echo.
timeout /t 1
move /y new_OPTY.bat OPTY.bat
start "" "%~dp0\OPTY.bat"
exit

REM If user don't accept update, exit
:update_found_and_not_accepted
echo %date% %time% : Update found and not accepted >> %logs%
cls
color 04
echo.
echo The script will continue to run with version %current_version%.
echo.
timeout /t 1
goto menu


REM If no update is available, continue
:update_not_available
echo %date% %time% : No update >> %logs%
color 30
cls
echo.
echo You are running the latest version of this script: %current_version%.
echo.
timeout /t 1
goto menu


:::: MENU ::::
:menu
echo %date% %time% : Menu.bat >> %logs%
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
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : Menu.bat-menuadmin %choice% >> %logs%
if "%choice%"=="1" goto mopti
if "%choice%"=="2" goto mreenable
if "%choice%"=="3" goto mregprofil
if "%choice%"=="9" goto Clean_Opty_Curl
if "%choice%"=="0" goto end
if "%choice%"=="." goto update_opty
if "%choice%"=="-" goto mupdate_perso
color 0C
echo This is not a valid action
timeout /t 5
goto menu


:::: OPTI ::::
:mopti
echo %date% %time% : Opti >> %logs%
if /i "%AutoOpti_Shutdown%"=="1" echo %date% %time% : AutoOpti_Shutdown >> %logs% & goto wupdate

:mopti
color F5
cls
echo.
echo  WELCOME to OPTY by @YannD-Deltagon
echo  Choose a option for Optimization cycle:
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
echo  If you want reboot/stop after autoopti, type "r" (reboot) or"s" (shutdown) after the number
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
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : Opti-mopti %choice% >> %logs%
if /i "%choice%"=="1" set autoclean=0 & set autoshutdownreboot=5 & goto mdisenable
if /i "%choice%"=="2" set autoclean=1 & set autoshutdownreboot=0 & goto wupdate
if /i "%choice%"=="3" set autoclean=2 & set autoshutdownreboot=0 & goto stopapps
if /i "%choice%"=="2s" set autoclean=1 & set autoshutdownreboot=1 & goto wupdate
if /i "%choice%"=="3s" set autoclean=2 & set autoshutdownreboot=1 & goto stopapps
if /i "%choice%"=="2r" set autoclean=1 & set autoshutdownreboot=2 & goto wupdate
if /i "%choice%"=="3r" set autoclean=2 & set autoshutdownreboot=2 & goto stopapps
if /i "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 5
goto mopti


:mdisenable
color F4
cls
echo.
echo  WELCOME to OPTY by @YannD-Deltagon
echo  Choose a option to Disable/Enable :
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
echo  Add "+" or "-" in front of an action + activate or - deactivate it (example "-ani" to deactivate animations)
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
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : Opti-mdisenable %choice% >> %logs%
if /i "%choice%"=="-ani" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuAnimate" /t REG_SZ /d "0" /f & pause & goto mdisenable
if /i "%choice%"=="+ani" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuAnimate" /t REG_SZ /d "1" /f & pause & goto mdisenable
if /i "%choice%"=="-mov" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "0" /f & pause & goto mdisenable
if /i "%choice%"=="+mov" reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "DragFullWindows" /t REG_SZ /d "1" /f & pause & goto mdisenable
if /i "%choice%"=="-fad" fsutil behavior set disablelastaccess 1 & pause & goto mdisenable
if /i "%choice%"=="+fad" fsutil behavior set disablelastaccess 0 & pause & goto mdisenable
if /i "%choice%"=="-hbn" powercfg.exe /hibernate off & echo Disable hibernate & pause & goto mdisenable
if /i "%choice%"=="+hbn" powercfg.exe /hibernate on & echo Enable hibernate & pause & goto mdisenable
if /i "%choice%"=="2" goto mnetdns
if /i "%choice%"=="0" goto menu
cls
color 0C
echo This is not a valid action
timeout /t 5
goto mdisenable


:stopapps
echo %date% %time% : Opti-stopapps >> %logs%
cls
echo Stop your background apps !
pause
if /i %autoclean% == 2 goto startready

:startready
echo %date% %time% : Opti-startready >> %logs%
net stop bits
net stop wuauserv
net stop msiserver
net stop cryptsvc
net stop appidsvc
regsvr32.exe /s atl.dll
regsvr32.exe /s urlmon.dll
regsvr32.exe /s mshtml.dll
if /i %autoclean% == 2 goto netdns


:mnetdns
cls
echo Do you want to flushdns and ip reset - IPCONFIG and NETSH ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mnetdns %choice% >> %logs%
if /i "%choice%"=="1" goto netdns
if /i "%choice%"=="2" goto mdism
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mnetdns

:netdns
echo %date% %time% : Opti-netdns >> %logs%
ipconfig /flushdns
netsh int ip reset
netsh winsock reset
netsh winsock reset proxy
if /i %autoclean% == 2 goto dism
timeout /t 5


:mdism
cls
echo Do you want to dismy the integrity of the Windows image and correct problems - DISM ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mdism %choice% >> %logs%
if /i "%choice%"=="1" goto dism
if /i "%choice%"=="2" goto msfc
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mdism

:dism
echo %date% %time% : Opti-dism >> %logs%
dism /Online /Cleanup-image /ScanHealth
dism /Online /Cleanup-image /CheckHealth
dism /Online /Cleanup-image /RestoreHealth
dism /Online /Cleanup-image /StartComponentCleanup /ResetBase
if /i %autoclean% == 2 goto sfc
timeout /t 5


:msfc
cls
echo Do you want to verify the integrity of system files and fix problems - SFC ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-msfc %choice% >> %logs%
if /i "%choice%"=="1" goto sfc
if /i "%choice%"=="2" goto mwupdate
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto msfc

:sfc
echo %date% %time% : Opti-sfc >> %logs%
sfc /scannow
if /i %autoclean% == 2 goto wupdate
timeout /t 5


:mwupdate
cls
echo Do you want to update Windows - USOCLIENT ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mwupdate %choice% >> %logs%
if /i "%choice%"=="1" goto wupdate
if /i "%choice%"=="2" goto mclean
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mwupdate

:wupdate
echo %date% %time% : Opti-wupdate >> %logs%
usoclient StartScan
usoclient RefreshSettings
usoclient StartInstall
if /i %autoclean% == 1 goto delete
if /i %autoclean% == 2 goto delete
timeout /t 5

:mclean
cls
echo Execute clean disk - CLEANMGR ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mclean %choice% >> %logs%
if /i "%choice%"=="1" goto clean
if /i "%choice%"=="2" goto mdelete
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mclean

:clean
echo %date% %time% : Opti-clean %choice% >> %logs%
echo Cleanmgr...
cleanmgr /sageset:65535
pause
cleanmgr /sagerun:65535
timeout /t 5


:mdelete
cls
echo Do you want to delete temporary files - DEL ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mdelete %choice% >> %logs%
if /i "%choice%"=="1" goto delete
if /i "%choice%"=="2" goto mdefrag
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mdelete

:delete
echo %date% %time% : Opti-delete >> %logs%

REM ========= Windows Update Cache =========
net stop wuauserv
del /S /F /Q "C:\Windows\SoftwareDistribution\Download\*"
net start wuauserv

REM ========= Windows Error Reporting =========
del /S /F /Q "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue\*"
del /S /F /Q "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive\*"

REM ========= Windows Event Logs =========
del /S /F /Q "%WINDIR%\System32\winevt\Logs\*"

REM ========= Windows Upgrade Logs =========
del /S /F /Q "%SystemDrive%\$Windows.~BT\Sources\Panther\*"

REM ========= Prefetch =========
del /S /F /Q "%WINDIR%\Prefetch\*"

REM ========= Temp Files =========
setlocal
for /D %%i in ("C:\Users\*") do (
   echo %%i
   del /S /F /Q "%%i\AppData\Local\Temp\*"
)
endlocal
del /S /F /Q "%WINDIR%\Temp"
rd /S /Q "%WINDIR%\Temp"

REM ========= CCMCache =========
del /F /S /Q "%WINDIR%\ccmcache\*.*"
rd /S /Q "%WINDIR%\ccmcache\"

REM ========= Browser Cache =========
del /S /F /Q "%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*\cache2\*"
del /S /F /Q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*"
del /S /F /Q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Code Cache\*"
del /S /F /Q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*"
del /S /F /Q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache\*"

REM ========= Gaming Platforms Cache =========
REM del /S /F /Q "%ProgramFiles(x86)%\Steam\appcache\*"
REM del /S /F /Q "%ProgramFiles(x86)%\Steam\depotcache\*"
REM del /S /F /Q "%ProgramFiles(x86)%\Ubisoft\Ubisoft Game Launcher\cache\*"
REM del /S /F /Q "%ProgramData%\Battle.net\Cache\*"
REM del /S /F /Q "%ProgramFiles(x86)%\Rockstar Games\Launcher\cache\*"
REM del /S /F /Q "%ProgramData%\Origin\Cache\*"
REM del /S /F /Q "%ProgramData%\GOG.com\Galaxy\cache\*"

REM ========= Communication Tools Cache =========
del /S /F /Q "%APPDATA%\discord\Cache\*"
del /S /F /Q "%APPDATA%\Microsoft\Teams\Cache\*"
del /S /F /Q "%APPDATA%\Slack\Cache\*"

REM ========= Office Applications Cache =========
del /S /F /Q "%LOCALAPPDATA%\Microsoft\Outlook\RoamCache\*"

REM ========= Development Tools Cache =========
del /S /F /Q "%APPDATA%\Code\Cache\*"
del /S /F /Q "%LOCALAPPDATA%\Android\Sdk\cache\*"

REM ========= GPU Caches =========
del /S /F /Q "%LOCALAPPDATA%\AMD\DxCache\*"
del /S /F /Q "%ProgramData%\NVIDIA Corporation\NV_Cache\*"
del /S /F /Q "%LOCALAPPDATA%\Intel\ShaderCache\*"

REM ========= DirectX Shader Cache =========
del /S /F /Q "%LOCALAPPDATA%\D3DSCache\*"

REM ========= Windows Defender Cache =========
del /S /F /Q "%ProgramData%\Microsoft\Windows Defender\Scans\History\Store\*"

REM ========= Windows Thumbnail Cache =========
del /S /F /Q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db"

REM ========= Windows Installer Cache =========
del /S /F /Q "%WINDIR%\Installer\$PatchCache$\*"

REM ========= Windows Font Cache =========
del /S /F /Q "%LOCALAPPDATA%\FontCache\*"

REM ========= Nuanceur DirectX =========
del /S /F /Q "%LOCALAPPDATA%\Microsoft\DirectX Shader Cache\*"

if /i %autoclean% == 1 goto mshutdownreboot
if /i %autoclean% == 2 goto defrag
timeout /t 5


:mdefrag
cls
echo Do you want to defragment HDD or optimize SSD - DEFRAG ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mdefrag %choice% >> %logs%
if /i "%choice%"=="1" goto defrag
if /i "%choice%"=="2" goto mchkdsk
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mdefrag

:defrag
echo %date% %time% : Opti-defrag >> %logs%
defrag /C /O /U /V /H
if /i %autoclean% == 2 goto endready
timeout /t 5


:mchkdsk
cls
echo Do you want to check the integrity of hard drives and fix any problems - CHKDSK ?
set /p choice= 1 (Yes) - 2 (No)
echo %date% %time% : Opti-mchkdsk %choice% >> %logs%
if /i "%choice%"=="1" goto chkdsk
if /i "%choice%"=="2" goto mshutdownreboot
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mchkdsk

:chkdsk
echo %date% %time% : Opti-chkdsk >> %logs%
CHKDSK /f /r
if /i %autoclean% == 2 goto endready
timeout /t 5

:endready
echo %date% %time% : Opti-endready >> %logs%
net start bits
net start wuauserv
net start msiserver
net start cryptsvc
net start appidsvc
if /i %autoclean% == 2 goto mshutdownreboot
timeout /t 5

:mshutdownreboot
echo %date% %time% : Opti-mshutdownreboot >> %logs%
cls
if /i %autoshutdownreboot% == 0 goto skipshutdownreboot
if /i %autoshutdownreboot% == 1 goto shutdown
if /i %autoshutdownreboot% == 2 goto reboot
if /i %autoshutdownreboot% == 5 goto mshutdownrebootfix


:mshutdownrebootfix
echo Do you want to restart/stop the computer?
set /p choice= R (Reboot) - S (Stop) - 0 (No)
echo %date% %time% : Opti-mshutdownrebootfix %choice% >> %logs%
if /i "%choice%"=="R" goto reboot
if /i "%choice%"=="S" goto shutdown
if /i "%choice%"=="0" goto menu
echo This is not a valid action
timeout /t 5
goto mshutdownreboot


:shutdown
echo %date% %time% : Opti-shutdown >> %logs%
shutdown /s /f /t 15
timeout /t 15
exit

:reboot
echo %date% %time% : Opti-reboot >> %logs%
shutdown /r /f /t 15
timeout /t 15
exit


:skipshutdownreboot
echo %date% %time% : Opti-skipshutdownreboot >> %logs%
echo The computer will not restart.
pause
goto menu
:::: END OPTI ::::


:::: ENABLE ::::
:mreenable
color F2
cls
echo.
echo  WELCOME to OPTY by @YannD-Deltagon
echo    Choose the option to re-enable:
echo.
echo.
echo.
echo   1. Start office update
echo   2. Enable chrome update (if you compagny use GPO [Register])
echo   3. Enable windows update (if you compagny use GPO [Register])
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
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : ReEnable.bat-mreenable %choice% >> %logs%
if "%choice%"=="1" goto office_update
if "%choice%"=="2" goto enable_google_update
if "%choice%"=="3" goto enable_windows_update
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 5
goto mreenable


:office_update
echo %date% %time% : ReEnable.bat-office_update >> %logs%
cls
echo Microsoft Office update...
"C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe" /update user
pause
goto mreenable


:enable_google_update
echo %date% %time% : ReEnable.bat-enable_google_update >> %logs%
cls
taskkill /f /im chrome.exe
cls
REG ADD "HKLM\SOFTWARE\Policies\Google\Update" /v "UpdateDefault" /t REG_DWORD /d 1 /f
start chrome.exe
echo.
echo Go to .../help/about.
echo This launches the Update
echo.
pause
goto mreenable


:enable_windows_update
echo %date% %time% : ReEnable.bat-enable_windows_update >> %logs%
cls
Net stop wuauserv
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableWindowsUpdateAccess" /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "SetDisableUXWUAccess" /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer" /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ExcludeWUDriversInQualityUpdate" /t REG_DWORD /d 0 /f
echo.
Net start wuauserv
pause
goto mreenable
:::: END ENABLE ::::


:::: REG ::::
:mregprofil
color FC
cls
echo.
echo  Optimize your Register, mouse and power
echo    Choose your desired profil:
echo.
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
echo.
echo   0. Menu
echo.
echo.
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : RegProfil.bat-mregprofil %choice% >> %logs%
if "%choice%"=="1" goto map_only
if "%choice%"=="10" goto map_only-
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 5
goto mregprofil


:map_only
echo %date% %time% : RegProfil.bat-map_only >> %logs%
cls
echo.
:: Memory
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000000 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000000 /f
:: Driver
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 00000000 /f
:: DVR
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_SZ /d "00000000" /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 00000000 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 00000000 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 00000000 /f
:: Power
powercfg /h off
timeout /t 5
goto regsc_map_only

:regsc_map_only
echo %date% %time% : RegProfil.bat-regsc_map_only >> %logs%
sc stop WSearch
sc stop SysMain
sc stop WerSvc
sc stop Spooler
sc stop DPS
sc stop TabletInputService
sc config "WSearch" start= demand
sc config "SysMain" start= demand
sc config "WerSvc" start= demand
sc config "Spooler" start= demand
sc config "DPS" start= demand
sc config "TabletInputService" start= disabled
pause
goto mregpowercfg


:map_only-
echo %date% %time% : RegProfil.bat-map_only- >> %logs%
cls
echo.
:: Memory
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnablePrefetcher" /t REG_DWORD /d 00000000 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v "EnableSuperfetch" /t REG_DWORD /d 00000000 /f
:: Driver
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v "SearchOrderConfig" /t REG_DWORD /d 00000000 /f
:: DVR
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_SZ /d "00000000" /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d 00000000 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 00000000 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 00000000 /f
:: Power
powercfg /h off
timeout /t 5
goto regsc_map_only-

:regsc_map_only-
echo %date% %time% : RegProfil.bat-regsc_map_only- >> %logs%
pause
goto mregpowercfg


:mregpowercfg
color FC
cls
echo.
echo.
echo Do you want create the "ULTIMATE POWER" ?
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
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : RegProfil.bat-mregpowercfg %choice% >> %logs%
if "%choice%"=="1" goto powercfg
if "%choice%"=="2" goto mregmouse
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 5
goto mregprofil

:powercfg
echo %date% %time% : RegProfil.bat-powercfg >> %logs%
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
powercfg.cpl
pause
goto mregmouse


:mregmouse
color FC
cls
echo.
echo.
echo Do you want create to optimize your mouse ?
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
echo.
echo.
echo.
set /p choice= Enter action:
echo %date% %time% : RegProfil.bat-mregmouse %choice% >> %logs%
if "%choice%"=="1" goto mouseantilag
if "%choice%"=="2" goto menu
if "%choice%"=="0" goto menu
color 0C
echo This is not a valid action
timeout /t 5
goto mregprofil

:mouseantilag
echo %date% %time% : RegProfil.bat-mouseantilag >> %logs%
:: Mouse Settings
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "MouseSensitivity" /t REG_SZ /d "10" /f
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d "0000000000CCCCC0809919406626003333" /f
reg add "HKEY_CURRENT_USER\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d "0000000000003800000070000000A8000000E000" /f
pause
goto menu
:::: END REG ::::


:nshutdown
echo %date% %time% : Menu.bat-nshutdown >> %logs%
echo.
shutdown /a
echo.
echo The computer will not restart.
echo.
timeout /t 10
goto menu


:Clean_Opty_Curl
echo %date% %time% : Menu.bat-Clean_Opty_Curl >> %logs%
for /f "delims=" %f in ('dir /b /a-d ^| findstr /v "OPTY.bat"') do @del /f /q "%~dp0%f"
goto end
pause

:::: END MENU ::::


:end
echo %date% %time% : End >> %logs%
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