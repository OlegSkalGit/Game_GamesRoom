@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"
set "GODOT_EXE=%~dp0godot\Godot_v4.7.2-stable_win64.exe"

if not exist "%GODOT_EXE%" call "%~dp01_SETUP.bat"
if errorlevel 1 exit /b 1
if not exist "%~dp0game\addons\terrain_3d\plugin.cfg" call "%~dp01_SETUP.bat"
if errorlevel 1 exit /b 1

start "" "%GODOT_EXE%" --path "%~dp0game"
exit /b 0
