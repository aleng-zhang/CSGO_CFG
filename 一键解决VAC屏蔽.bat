::=====================  ��ȡ����ԱȨ��  ======================
@echo off
CLS
SETLOCAL ENABLEDELAYEDEXPANSION
title VAC��֤�޸�

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
echo ���ڼ��Steam�Ƿ���......
tasklist | find /I "Steam.exe"
if not errorlevel 1 goto killsteam

:stop
echo Steamδ����
goto start

:killsteam
echo Steam�ѿ���
echo ����ǿ�ƹر�
taskkill /F /IM Steam.exe
echo ��ǿ�ƹر�
goto start

:start
echo ��ʼ���VAC����

echo ���� Network Connections
sc config Netman start= AUTO
sc start Netman

echo ���� Remote Access Connection Manager
sc config RasMan start= AUTO
sc start RasMan

echo ���� Telephony
sc config TapiSrv start= AUTO
sc start TapiSrv

echo ���� Windows Firewall
sc config MpsSvc start= AUTO
sc start MpsSvc
netsh advfirewall set allprofiles state on

echo �ָ� Data Execution Prevention ��������ΪĬ��ֵ
bcdedit /deletevalue nointegritychecks
bcdedit /deletevalue loadoptions
bcdedit /debug off
bcdedit /deletevalue nx

echo ���ڻ�ȡ���SteamĿ¼
for /f "tokens=1,2,* " %%i in ('REG QUERY "HKEY_CURRENT_USER\SOFTWARE\Valve\Steam" ^| find /i "SteamPath"') do set "SteamPath=%%k" 
if "%SteamPath%" NEQ "0x1" (goto Auto) else (goto Manual)

:Manual
echo ��ȡSteamĿ¼ʧ�� 
echo ���ֶ��������SteamĿ¼ ��:"C:\Program Files (x86)\Steam"
set /p SteamPath=SteamĿ¼:
goto Auto

:Auto
echo SteamĿ¼Ϊ%SteamPath% 

echo ��ʼ��װSteam Services
cd /d "%SteamPath%\bin"
steamservice  /uninstall
steamservice  /install
echo ��װSteam Services���
echo ����"Steam client service installation complete"
echo �����κ�"Fail"����(��"Add firewall exception failed for steamservice.exe")
echo �ſ��Խ���, �����������ķ���ǽ����(�رա����������⡱ѡ��)
echo ����Steam�����ݷ�ʽ(����ģʽ)
mshta VBScript:Execute("Set a=CreateObject(""WScript.Shell""):Set b=a.CreateShortcut(a.SpecialFolders(""Desktop"") & ""\Steam(����ģʽ).lnk""):b.TargetPath=""%SteamPath%\Steam.exe"":b.Arguments=""-cafeapplaunch -forceservice"":b.WorkingDirectory=""%SteamPath%"":b.Save:close")

echo ��Steam(����ģʽ)
cd /d "%SteamPath%"
start /high steam -cafeapplaunch -forceservice

echo ����Steam Services����
sc config "Steam Client Service" start= AUTO
sc start "Steam Client Service"

title ���!
echo ��ϣ���������������ڣ�
pause>nul
exit