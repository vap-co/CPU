@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_all_sims.ps1" %*
exit /b %ERRORLEVEL%
