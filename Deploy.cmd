@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy.ps1"
set "deployResult=%ERRORLEVEL%"
echo.
pause
exit /b %deployResult%
