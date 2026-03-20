@echo off
cd /d "%~dp0"
powershell -STA -NoProfile -ExecutionPolicy RemoteSigned -File ".\LiveCountersApp.ps1"