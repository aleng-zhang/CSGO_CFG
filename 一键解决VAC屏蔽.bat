::=====================  获取管理员权限  ======================
@echo off
CLS
SETLOCAL ENABLEDELAYEDEXPANSION
title VAC验证修复

:init
setlocal DisableDelayedExpansion
set cmdInvoke=1
set winSysFolder=System32
set "batchPath=%~0"
for %%k in (%0) do set batchName=%%~nk
set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
setlocal EnableDelayedExpansion

:checkPrivileges
NET FILE 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)

ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
ECHO args = "ELEV " >> "%vbsGetPrivileges%"
ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
ECHO Next >> "%vbsGetPrivileges%"

if '%cmdInvoke%'=='1' goto InvokeCmd 

ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
goto ExecElevation

:InvokeCmd
ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
"%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
exit /B

:gotPrivileges
setlocal & cd /d %~dp0
if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)

goto steam

:steam
echo 正在检测Steam是否开启......
tasklist | find /I "Steam.exe"
if not errorlevel 1 goto killsteam

:stop
echo Steam未开启
goto start

:killsteam
echo Steam已开启
echo 正在强制关闭
taskkill /F /IM Steam.exe
echo 已强制关闭
goto start

:start
echo 开始解决VAC屏蔽

echo 开启 Network Connections
sc config Netman start= AUTO
sc start Netman

echo 开启 Remote Access Connection Manager
sc config RasMan start= AUTO
sc start RasMan

echo 开启 Telephony
sc config TapiSrv start= AUTO
sc start TapiSrv

echo 开启 Windows Firewall
sc config MpsSvc start= AUTO
sc start MpsSvc
netsh advfirewall set allprofiles state on

echo 恢复 Data Execution Prevention 启动设置为默认值
bcdedit /deletevalue nointegritychecks
bcdedit /deletevalue loadoptions
bcdedit /debug off
bcdedit /deletevalue nx

echo 正在获取你的Steam目录
for /f "tokens=1,2,* " %%i in ('REG QUERY "HKEY_CURRENT_USER\SOFTWARE\Valve\Steam" ^| find /i "SteamPath"') do set "SteamPath=%%k" 
if "%SteamPath%" NEQ "0x1" (goto Auto) else (goto Manual)

:Manual
echo 获取Steam目录失败 
echo 请手动输入你的Steam目录 如:"C:\Program Files (x86)\Steam"
set /p SteamPath=Steam目录:
goto Auto

:Auto
echo Steam目录为%SteamPath% 

echo 开始重装Steam Services
cd /d "%SteamPath%\bin"
steamservice  /uninstall
steamservice  /install
echo 重装Steam Services完毕
echo 出现"Steam client service installation complete"
echo 且无任何"Fail"字样(如"Add firewall exception failed for steamservice.exe")
echo 才可以结束, 否则请检查您的防火墙设置(关闭“不允许例外”选项)
echo 创建Steam桌面快捷方式(网吧模式)
mshta VBScript:Execute("Set a=CreateObject(""WScript.Shell""):Set b=a.CreateShortcut(a.SpecialFolders(""Desktop"") & ""\Steam(网吧模式).lnk""):b.TargetPath=""%SteamPath%\Steam.exe"":b.Arguments=""-cafeapplaunch -forceservice"":b.WorkingDirectory=""%SteamPath%"":b.Save:close")

echo 打开Steam(网吧模式)
cd /d "%SteamPath%"
start /high steam -cafeapplaunch -forceservice

echo 启动Steam Services服务
sc config "Steam Client Service" start= AUTO
sc start "Steam Client Service"

title 完毕!
echo 完毕！按任意键结束窗口！
pause>nul
exit