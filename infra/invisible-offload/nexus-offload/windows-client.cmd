@ECHO OFF
SETLOCAL
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0windows-client.ps1" %*
EXIT /B %ERRORLEVEL%
