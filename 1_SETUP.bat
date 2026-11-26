@echo off
chcp 65001 >nul
setlocal EnableExtensions

cd /d "%~dp0"
set "ROOT=%~dp0"
set "GAME_DIR=%ROOT%game"
set "GODOT_DIR=%ROOT%godot"
set "TMP_DIR=%ROOT%_setup_tmp"

set "GODOT_VER=4.7.2-stable"
set "GODOT_EXE=%GODOT_DIR%\Godot_v%GODOT_VER%_win64.exe"
set "GODOT_CONSOLE=%GODOT_DIR%\Godot_v%GODOT_VER%_win64_console.exe"
set "GODOT_URL=https://github.com/godotengine/godot/releases/download/%GODOT_VER%/Godot_v%GODOT_VER%_win64.exe.zip"

set "TERRAIN3D_URL=https://github.com/TokisanGames/Terrain3D/releases/download/v1.1.0-stable/Terrain3D_v1.1.0-stable.zip"
set "SKY3D_URL=https://github.com/TokisanGames/Sky3D/releases/download/v2.1.0/Sky3D_v2.1.0.zip"
set "SGT_URL=https://github.com/IcterusGames/SimpleGrassTextured/archive/refs/tags/v2.1.1.zip"
set "COSMO_URL=https://github.com/FrogCosmonaut/cosmo_tree_gen/archive/refs/heads/main.zip"

echo ============================================================
echo   Setup: Godot %GODOT_VER% + Plugins + CC0 Nature/Animal Assets
echo ============================================================
echo.

if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
if not exist "%GAME_DIR%\addons" mkdir "%GAME_DIR%\addons"
if not exist "%GAME_DIR%\assets" mkdir "%GAME_DIR%\assets"
if not exist "%GODOT_DIR%" mkdir "%GODOT_DIR%"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"

if exist "%GODOT_EXE%" goto :GODOT_OK
echo [1/6] Downloading Godot %GODOT_VER%...
curl.exe -fL --retry 3 --progress-bar "%GODOT_URL%" -o "%TMP_DIR%\godot.zip"
if errorlevel 1 goto :FAIL_END
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%TMP_DIR%\godot.zip' -DestinationPath '%GODOT_DIR%' -Force"
if not exist "%GODOT_EXE%" goto :FAIL_END
:GODOT_OK
echo [OK] Godot %GODOT_VER% ready

if exist "%GAME_DIR%\addons\terrain_3d\plugin.cfg" goto :TERRAIN_OK
echo [2/6] Installing Terrain3D...
curl.exe -fL --retry 3 --progress-bar "%TERRAIN3D_URL%" -o "%TMP_DIR%\terrain3d.zip"
if errorlevel 1 goto :FAIL_END
powershell -NoProfile -ExecutionPolicy Bypass -Command "$dst='%TMP_DIR%\t3d'; Expand-Archive -Path '%TMP_DIR%\terrain3d.zip' -DestinationPath $dst -Force; $f=Get-ChildItem $dst -Directory -Recurse | Where-Object Name -eq 'terrain_3d' | Select-Object -First 1; if(-not $f){throw 'missing terrain_3d'}; Copy-Item $f.FullName '%GAME_DIR%\addons\terrain_3d' -Recurse -Force"
if errorlevel 1 goto :FAIL_END
:TERRAIN_OK
echo [OK] Terrain3D ready

if exist "%GAME_DIR%\addons\sky_3d\plugin.cfg" goto :SKY_OK
echo [3/6] Installing Sky3D...
curl.exe -fL --retry 3 --progress-bar "%SKY3D_URL%" -o "%TMP_DIR%\sky3d.zip"
if errorlevel 1 goto :FAIL_END
powershell -NoProfile -ExecutionPolicy Bypass -Command "$dst='%TMP_DIR%\sky'; Expand-Archive -Path '%TMP_DIR%\sky3d.zip' -DestinationPath $dst -Force; $f=Get-ChildItem $dst -Directory -Recurse | Where-Object Name -eq 'sky_3d' | Select-Object -First 1; if(-not $f){throw 'missing sky_3d'}; Copy-Item $f.FullName '%GAME_DIR%\addons\sky_3d' -Recurse -Force"
if errorlevel 1 goto :FAIL_END
:SKY_OK
echo [OK] Sky3D ready

if exist "%GAME_DIR%\addons\simplegrasstextured\plugin.cfg" goto :SGT_OK
echo [4/6] Installing SimpleGrassTextured...
curl.exe -fL --retry 3 --progress-bar "%SGT_URL%" -o "%TMP_DIR%\sgt.zip"
if errorlevel 1 goto :FAIL_END
powershell -NoProfile -ExecutionPolicy Bypass -Command "$dst='%TMP_DIR%\sgt'; Expand-Archive -Path '%TMP_DIR%\sgt.zip' -DestinationPath $dst -Force; $f=Get-ChildItem $dst -Directory -Recurse | Where-Object Name -eq 'simplegrasstextured' | Select-Object -First 1; if(-not $f){throw 'missing simplegrasstextured'}; Copy-Item $f.FullName '%GAME_DIR%\addons\simplegrasstextured' -Recurse -Force; Remove-Item '%GAME_DIR%\addons\simplegrasstextured\shaders\.gdignore','%GAME_DIR%\addons\simplegrasstextured\materials\.gdignore' -ErrorAction SilentlyContinue; $g='%GAME_DIR%\addons\simplegrasstextured\grass.gd'; if(Test-Path $g){$t=(Get-Content $g -Raw) -replace 'clampi\(int\(trans\.origin\.x \* relx\), 0, img_size\.x\)','clampi(int(trans.origin.x * relx), 0, img_size.x - 1)' -replace 'clampi\(int\(trans\.origin\.z \* relz\), 0, img_size\.y\)','clampi(int(trans.origin.z * relz), 0, img_size.y - 1)'; Set-Content $g $t -NoNewline}"
if errorlevel 1 goto :FAIL_END
:SGT_OK
echo [OK] SimpleGrassTextured ready

if exist "%GAME_DIR%\addons\cosmo_tree_gen\plugin.cfg" goto :COSMO_OK
echo [5/6] Installing CosmoTreeGen...
curl.exe -fL --retry 3 --progress-bar "%COSMO_URL%" -o "%TMP_DIR%\cosmo.zip"
if errorlevel 1 goto :FAIL_END
powershell -NoProfile -ExecutionPolicy Bypass -Command "$dst='%TMP_DIR%\cosmo'; Expand-Archive -Path '%TMP_DIR%\cosmo.zip' -DestinationPath $dst -Force; $f=Get-ChildItem $dst -Directory -Recurse | Where-Object Name -eq 'cosmo_tree_gen' | Select-Object -First 1; if(-not $f){throw 'missing cosmo_tree_gen'}; Copy-Item $f.FullName '%GAME_DIR%\addons\cosmo_tree_gen' -Recurse -Force"
if errorlevel 1 goto :FAIL_END
:COSMO_OK
echo [OK] CosmoTreeGen ready

echo [6/6] Downloading PBR terrain textures, nature GLTFs, and animated animal GLBs...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0_fetch_assets.ps1" "%GAME_DIR%\assets"
if errorlevel 1 goto :FAIL_END

if exist "%GAME_DIR%\config.cfg" goto :CONFIG_OK
powershell -NoProfile -ExecutionPolicy Bypass -Command "$cfg = @('[graphics]','preset=3','render_scale=1.0','antialiasing=2','shadows=3','sdfgi=true','ssao=true','ssr=true','volumetric_fog=true','glow=true','foliage_density=1.0','view_distance=1.0','weather_mode=0','','[display]','width=1920','height=1080','window_mode=0','vsync=1','max_fps=0','','[audio]','master_volume=0.8') -join \"`r`n\"; [IO.File]::WriteAllText('%GAME_DIR%\config.cfg', $cfg + \"`r`n\", [Text.UTF8Encoding]::new($false))"
:CONFIG_OK
echo [OK] Config ready at game\config.cfg

if not exist "%GAME_DIR%\project.godot" goto :SKIP_IMPORT
echo [Import] Importing project assets and plugins in Godot...
if exist "%GODOT_CONSOLE%" (
    "%GODOT_CONSOLE%" --headless --path "%GAME_DIR%" --import --quit
) else (
    "%GODOT_EXE%" --headless --path "%GAME_DIR%" --import --quit
)
:SKIP_IMPORT

if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%"

echo.
echo ============================================================
echo   Setup complete!
echo   Run: 2_RUN.bat / 2_RUN_DX12.bat / 2_RUN_OpenGL.bat
echo ============================================================
if not defined NO_PAUSE pause
exit /b 0

:FAIL_END
echo [ERROR] Setup failed.
if not defined NO_PAUSE pause
exit /b 1
