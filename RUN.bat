@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

cd /d "%~dp0"
set "ROOT=%~dp0"
set "GAME_DIR=%ROOT%game"
set "ASSETS_DIR=%GAME_DIR%\assets"
set "GODOT_DIR=%ROOT%godot"
set "TMP_DIR=%ROOT%_setup_tmp"
set "CFG_FILE=%GAME_DIR%\config.cfg"

set "REPO_ZIP_URL=https://github.com/OlegSkalGit/Game_GamesRoom/archive/refs/heads/main.zip"
set "GODOT_VER=4.7.2-stable"
set "GODOT_EXE=%GODOT_DIR%\Godot_v%GODOT_VER%_win64.exe"
set "GODOT_CONSOLE=%GODOT_DIR%\Godot_v%GODOT_VER%_win64_console.exe"
set "GODOT_URL=https://github.com/godotengine/godot/releases/download/%GODOT_VER%/Godot_v%GODOT_VER%_win64.exe.zip"

set "TERRAIN3D_URL=https://github.com/TokisanGames/Terrain3D/releases/download/v1.1.0-stable/Terrain3D_v1.1.0-stable.zip"
set "SKY3D_URL=https://github.com/TokisanGames/Sky3D/releases/download/v2.1.0/Sky3D_v2.1.0.zip"
set "SGT_URL=https://github.com/IcterusGames/SimpleGrassTextured/archive/refs/tags/v2.1.1.zip"
set "COSMO_URL=https://github.com/FrogCosmonaut/cosmo_tree_gen/archive/refs/heads/main.zip"
set "T3D_RAW=https://raw.githubusercontent.com/TokisanGames/Terrain3D/main/project/demo/assets"

set "NEED_REPO=0"
set "NEED_IMPORT=0"

where curl.exe >nul 2>&1 || goto :NO_CURL
where tar.exe >nul 2>&1 || goto :NO_TAR

rem ============================================================
rem 1. Download missing repository files from GitHub if absent
rem ============================================================
for %%F in (
    "project.godot"
    "splash.png"
    "lang\en.cfg"
    "lang\uk.cfg"
    "scenes\main.tscn"
    "scenes\self_check.tscn"
    "scripts\main.gd"
    "scripts\autoload\config_manager.gd"
    "scripts\ui\main_menu.gd"
    "scripts\player\race_car.gd"
    "scripts\world\casino_room.gd"
    "scripts\world\race_track.gd"
    "scripts\world\ferris_wheel.gd"
    "scripts\world\god_rays_effect.gd"
    "scripts\ui\roulette_overlay.gd"
    "scripts\minigames\games\game_python3d.gd"
    "shaders\water_lake.gdshader"
    "shaders\god_rays.glsl"
    "shaders\interactive_plant.gdshader"
    "assets\textures\python3d\ground_quantum.png"
) do (
    if not exist "%GAME_DIR%\%%~F" set "NEED_REPO=1"
)
for %%L in (ar bn de el en es fa fr gu hi id it ja ko mr ms nl pl pt ro ru sw ta te th tl tr uk ur vi zh) do (
    if not exist "%GAME_DIR%\lang\%%L.cfg" set "NEED_REPO=1"
)

if "%NEED_REPO%"=="1" call :FETCH_REPO
if errorlevel 1 goto :FAIL_END
if /i "%~1"=="--repo-only" (
    if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%"
    exit /b 0
)

if not exist "%GAME_DIR%\addons" mkdir "%GAME_DIR%\addons"
if not exist "%ASSETS_DIR%" mkdir "%ASSETS_DIR%"
if not exist "%GODOT_DIR%" mkdir "%GODOT_DIR%"

rem ============================================================
rem 2. Ensure Godot Engine 4.7.2-stable (pure curl + tar)
rem ============================================================
if not exist "%GODOT_EXE%" (
    echo [1/6] Downloading Godot %GODOT_VER%...
    if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
    call :DL_FILE "%GODOT_URL%" "%TMP_DIR%\godot.zip"
    if errorlevel 1 goto :FAIL_END
    if exist "%TMP_DIR%\godot" rmdir /s /q "%TMP_DIR%\godot"
    mkdir "%TMP_DIR%\godot"
    call :UNZIP "%TMP_DIR%\godot.zip" "%TMP_DIR%\godot"
    if errorlevel 1 goto :FAIL_END
    robocopy "%TMP_DIR%\godot" "%GODOT_DIR%" /E /MOVE /NFL /NDL /NJH /NJS /NP >nul
    if errorlevel 8 goto :FAIL_END
    if not exist "%GODOT_EXE%" goto :FAIL_END
    set "NEED_IMPORT=1"
    echo [OK] Godot %GODOT_VER% ready.
)

rem ============================================================
rem 3. Ensure Godot Addons (pure curl + tar + dir/xcopy)
rem ============================================================
call :INSTALL_ADDON "%TERRAIN3D_URL%" "terrain3d.zip" "terrain_3d" "Terrain3D"
if errorlevel 1 goto :FAIL_END
call :INSTALL_ADDON "%SKY3D_URL%" "sky3d.zip" "sky_3d" "Sky3D"
if errorlevel 1 goto :FAIL_END
call :INSTALL_ADDON "%SGT_URL%" "sgt.zip" "simplegrasstextured" "SimpleGrassTextured"
if errorlevel 1 goto :FAIL_END
call :PATCH_SGT
if errorlevel 1 goto :FAIL_END
call :INSTALL_ADDON "%COSMO_URL%" "cosmo.zip" "cosmo_tree_gen" "CosmoTreeGen"
if errorlevel 1 goto :FAIL_END

rem ============================================================
rem 4. Download missing PBR textures, nature GLTFs & animal GLBs
rem ============================================================
call :FETCH_ALL_ASSETS
if errorlevel 1 goto :FAIL_END

rem ============================================================
rem 5. Ensure default config & import Godot project if updated
rem ============================================================
if not exist "%GAME_DIR%\config.cfg" call :WRITE_DEFAULT_CONFIG
if not exist "%GAME_DIR%\.godot" set "NEED_IMPORT=1"

if "%NEED_IMPORT%"=="1" if exist "%GAME_DIR%\project.godot" (
    echo [Import] Importing project assets and plugins in Godot...
    if exist "%GODOT_CONSOLE%" (
        "%GODOT_CONSOLE%" --headless --path "%GAME_DIR%" --import --quit
    ) else (
        "%GODOT_EXE%" --headless --path "%GAME_DIR%" --import --quit
    )
    if errorlevel 1 goto :FAIL_END
)

if exist "%TMP_DIR%" rmdir /s /q "%TMP_DIR%"

if /i "%~1"=="--setup-only" exit /b 0

rem ============================================================
rem 6. Interactive Launcher Menu (DX12 / Vulkan / OpenGL 3)
rem    5s auto-launch timer, defaults to last selected mode
rem ============================================================
:MENU
call :GET_DEF_MODE
set /a INIT_IDX=%DEF_MODE%-1

cls
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $ErrorActionPreference='Stop'; try{[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false)}catch{}; $items=@('DirectX 12 (Forward+)','Vulkan (Forward+)','OpenGL 3 (Сумісність)'); $idx=[int]%INIT_IDX%; $timerOn=$true; $deadline=[DateTime]::UtcNow.AddSeconds(5); $lastKey=''; $startTop=0; try{[Console]::CursorVisible=$false; $startTop=[Console]::CursorTop}catch{}; try{while($true){$sec=0; if($timerOn){$sec=[int][Math]::Ceiling(($deadline-[DateTime]::UtcNow).TotalSeconds); if($sec -le 0){exit (10+$idx)}}; $stateKey=(''+$idx+'|'+$timerOn+'|'+$sec); if($stateKey -ne $lastKey){$lastKey=$stateKey; try{[Console]::SetCursorPosition(0,$startTop)}catch{}; Write-Host '======================================================' -ForegroundColor DarkYellow; Write-Host '   ДІМ ІГОР / ЛІСОВЕ КАЗИНО - ОБЕРІТЬ РЕЖИМ ЗАПУСКУ' -ForegroundColor Yellow; Write-Host '======================================================' -ForegroundColor DarkYellow; Write-Host ''; for($i=0;$i -lt $items.Count;$i++){$line=('  '+($i+1)+'. '+$items[$i]).PadRight(48); if($i -eq $idx){Write-Host ('> '+$line.TrimStart()) -ForegroundColor Black -BackgroundColor Green}else{Write-Host $line -ForegroundColor Gray}}; Write-Host ''; if($timerOn){Write-Host ('  Автозапуск через '+$sec+' с...                          ') -ForegroundColor Green}else{Write-Host '  Таймер зупинено — оберіть режим і натисніть [Enter]' -ForegroundColor DarkYellow}; Write-Host '  [Стрілки Вгору/Вниз] або [1-3] - вибір              ' -ForegroundColor DarkCyan; Write-Host '  [Enter] - запуск  |  [Esc] - вихід                  ' -ForegroundColor DarkCyan}; $hasKey=$false; try{$hasKey=[Console]::KeyAvailable}catch{exit 99}; if($hasKey){$k=[Console]::ReadKey($true); switch($k.Key){'UpArrow'{$timerOn=$false; if($idx -le 0){$idx=$items.Count-1}else{$idx--}} 'W'{$timerOn=$false; if($idx -le 0){$idx=$items.Count-1}else{$idx--}} 'DownArrow'{$timerOn=$false; if($idx -ge $items.Count-1){$idx=0}else{$idx++}} 'S'{$timerOn=$false; if($idx -ge $items.Count-1){$idx=0}else{$idx++}} 'D1'{exit 10} 'NumPad1'{exit 10} 'D2'{exit 11} 'NumPad2'{exit 11} 'D3'{exit 12} 'NumPad3'{exit 12} 'Enter'{exit (10+$idx)} 'Spacebar'{exit (10+$idx)} 'Escape'{exit 0} default{$timerOn=$false}}}; Start-Sleep -Milliseconds 60}}finally{try{[Console]::CursorVisible=$true}catch{}}"
set "RC=%ERRORLEVEL%"

if "%RC%"=="10" goto :LAUNCH_DX12
if "%RC%"=="11" goto :LAUNCH_VULKAN
if "%RC%"=="12" goto :LAUNCH_OPENGL
if "%RC%"=="0" exit /b 0

rem Classic cmd fallback if PowerShell console input is unavailable
cls
echo ======================================================
echo    ДІМ ІГОР / ЛІСОВЕ КАЗИНО - ОБЕРІТЬ РЕЖИМ ЗАПУСКУ
echo ======================================================
echo.
echo   1. DirectX 12 (Forward+)
echo   2. Vulkan (Forward+)
echo   3. OpenGL 3 (Сумісність)
echo   Q. Вихід
echo.
echo   Автозапуск режиму #%DEF_MODE% через 5 с...
choice /C 123Q /N /T 5 /D %DEF_MODE%
if errorlevel 4 exit /b 0
if errorlevel 3 goto :LAUNCH_OPENGL
if errorlevel 2 goto :LAUNCH_VULKAN
goto :LAUNCH_DX12

:LAUNCH_DX12
call :SAVE_MODE 1
start "" "%GODOT_EXE%" --path "%GAME_DIR%" --rendering-driver d3d12 --rendering-method forward_plus
exit /b 0

:LAUNCH_VULKAN
call :SAVE_MODE 2
start "" "%GODOT_EXE%" --path "%GAME_DIR%" --rendering-driver vulkan --rendering-method forward_plus
exit /b 0

:LAUNCH_OPENGL
call :SAVE_MODE 3
start "" "%GODOT_EXE%" --path "%GAME_DIR%" --rendering-driver opengl3 --rendering-method gl_compatibility
exit /b 0

rem ============================================================
rem Subroutines (pure cmd / curl / tar / cscript)
rem ============================================================
:FETCH_REPO
echo [Git] Downloading repository from GitHub...
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
call :DL_FILE "%REPO_ZIP_URL%" "%TMP_DIR%\repo.zip"
if errorlevel 1 exit /b 1
if exist "%TMP_DIR%\repo" rmdir /s /q "%TMP_DIR%\repo"
mkdir "%TMP_DIR%\repo"
call :UNZIP "%TMP_DIR%\repo.zip" "%TMP_DIR%\repo"
if errorlevel 1 exit /b 1
set "REPO_SRC="
for /d %%D in ("%TMP_DIR%\repo\*") do if not defined REPO_SRC set "REPO_SRC=%%~fD"
if not defined REPO_SRC exit /b 1
if not exist "%GAME_DIR%" mkdir "%GAME_DIR%"
robocopy "%REPO_SRC%\game" "%GAME_DIR%" /E /XC /XN /XO /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
if not exist "%ROOT%README.md" if exist "%REPO_SRC%\README.md" copy /y "%REPO_SRC%\README.md" "%ROOT%README.md" >nul
if not exist "%ROOT%.gitignore" if exist "%REPO_SRC%\.gitignore" copy /y "%REPO_SRC%\.gitignore" "%ROOT%.gitignore" >nul
set "NEED_IMPORT=1"
echo [OK] Repository files ready.
exit /b 0

:INSTALL_ADDON
if exist "%GAME_DIR%\addons\%~3\plugin.cfg" exit /b 0
echo Installing %~4...
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
call :DL_FILE "%~1" "%TMP_DIR%\%~2"
if errorlevel 1 exit /b 1
if exist "%TMP_DIR%\%~3" rmdir /s /q "%TMP_DIR%\%~3"
mkdir "%TMP_DIR%\%~3"
call :UNZIP "%TMP_DIR%\%~2" "%TMP_DIR%\%~3"
if errorlevel 1 exit /b 1
set "SRC_ADDON="
for /f "delims=" %%D in ('dir /b /s /ad "%TMP_DIR%\%~3" ^| findstr /i "\\%~3$"') do if not defined SRC_ADDON set "SRC_ADDON=%%D"
if not defined SRC_ADDON (
    echo [ERROR] Addon folder '%~3' not found inside %~2
    exit /b 1
)
if exist "%GAME_DIR%\addons\%~3" rmdir /s /q "%GAME_DIR%\addons\%~3"
robocopy "%SRC_ADDON%" "%GAME_DIR%\addons\%~3" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 exit /b 1
set "NEED_IMPORT=1"
echo [OK] %~4 ready.
exit /b 0

:UNZIP
tar.exe -xf "%~1" -C "%~2" >nul 2>&1
if not errorlevel 1 exit /b 0
set "SYSTMP=%TEMP%\gr_unz_%RANDOM%"
if exist "%SYSTMP%" rmdir /s /q "%SYSTMP%"
mkdir "%SYSTMP%"
tar.exe -xf "%~1" -C "%SYSTMP%" >nul 2>&1
if errorlevel 1 goto :UNZIP_PS
robocopy "%SYSTMP%" "%~2" /E /MOVE /NFL /NDL /NJH /NJS /NP >nul
if not errorlevel 8 (
    if exist "%SYSTMP%" rmdir /s /q "%SYSTMP%" 2>nul
    exit /b 0
)
:UNZIP_PS
if exist "%SYSTMP%" rmdir /s /q "%SYSTMP%" 2>nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Add-Type -AssemblyName System.IO.Compression.FileSystem; $d='%~2'; if(Test-Path $d){Remove-Item $d -Recurse -Force}; [IO.Compression.ZipFile]::ExtractToDirectory('%~1', $d)"
exit /b %ERRORLEVEL%

:PATCH_SGT
set "SGT_DIR=%GAME_DIR%\addons\simplegrasstextured"
if exist "%SGT_DIR%\shaders\.gdignore" del /f /q "%SGT_DIR%\shaders\.gdignore"
if exist "%SGT_DIR%\materials\.gdignore" del /f /q "%SGT_DIR%\materials\.gdignore"
set "SGT_GRASS=%SGT_DIR%\grass.gd"
if not exist "%SGT_GRASS%" exit /b 0
findstr /c:"img_size.x)" "%SGT_GRASS%" >nul 2>&1
if errorlevel 1 exit /b 0
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
>  "%TMP_DIR%\patch_grass.js" echo var fso = new ActiveXObject("Scripting.FileSystemObject");
>> "%TMP_DIR%\patch_grass.js" echo var p = WScript.Arguments(0);
>> "%TMP_DIR%\patch_grass.js" echo var s = fso.OpenTextFile(p, 1).ReadAll();
>> "%TMP_DIR%\patch_grass.js" echo s = s.replace(/clampi\(int\(trans\.origin\.x \* relx\), 0, img_size\.x\)/g, "clampi(int(trans.origin.x * relx), 0, img_size.x - 1)");
>> "%TMP_DIR%\patch_grass.js" echo s = s.replace(/clampi\(int\(trans\.origin\.z \* relz\), 0, img_size\.y\)/g, "clampi(int(trans.origin.z * relz), 0, img_size.y - 1)");
>> "%TMP_DIR%\patch_grass.js" echo fso.OpenTextFile(p, 2, true).Write(s);
cscript //nologo //E:JScript "%TMP_DIR%\patch_grass.js" "%SGT_GRASS%"
if errorlevel 1 exit /b 1
exit /b 0

:FETCH_ALL_ASSETS
set "ASSET_CHECK=0"
for %%F in (
    "textures\terrain\ground037_alb_ht.png"
    "textures\terrain\rock023_nrm_rgh.png"
    "models\RockA.glb"
    "models\RockC.glb"
    "textures\pbr\forrest_ground_01\diff.jpg"
    "textures\pbr\denim_fabric\rough.jpg"
    "models\fern_02\fern_02.gltf"
    "models\dead_tree_trunk\textures\dead_tree_trunk_arm_1k.jpg"
    "models\shrub_01\shrub_01.gltf"
    "models\shrub_01\textures\shrub_01_arm_1k.jpg"
    "models\moss_01\moss_01.gltf"
    "models\animals\Fox.glb"
    "models\animals\animal_fox.glb"
) do (
    if not exist "%ASSETS_DIR%\%%~F" set "ASSET_CHECK=1"
)
if "%ASSET_CHECK%"=="0" goto :FETCH_VERIFY_FULL
echo [Assets] Checking and downloading missing PBR textures, nature GLTFs, and animal GLBs...
:FETCH_VERIFY_FULL

for %%F in (ground037_alb_ht.png ground037_nrm_rgh.png rock023_alb_ht.png rock023_nrm_rgh.png) do (
    call :FETCH "%T3D_RAW%/textures/%%F" "%ASSETS_DIR%\textures\terrain\%%F" || exit /b 1
)
for %%F in (RockA.glb RockB.glb RockC.glb) do (
    call :FETCH "%T3D_RAW%/models/%%F" "%ASSETS_DIR%\models\%%F" || exit /b 1
)

for %%T in (forrest_ground_01 coast_sand_01 marble_01 wood_planks_dirt herringbone_parquet american_walnut_veneer painted_plaster_wall fabric_leather_02 denim_fabric) do (
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/%%T/%%T_diff_1k.jpg" "%ASSETS_DIR%\textures\pbr\%%T\diff.jpg" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/%%T/%%T_nor_gl_1k.jpg" "%ASSETS_DIR%\textures\pbr\%%T\nor.jpg" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/%%T/%%T_rough_1k.jpg" "%ASSETS_DIR%\textures\pbr\%%T\rough.jpg" || exit /b 1
)

for %%M in (fern_02 flower_gazania grass_medium_01 boulder_01 dead_tree_trunk) do (
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/gltf/1k/%%M/%%M_1k.gltf" "%ASSETS_DIR%\models\%%M\%%M.gltf" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/gltf/8k/%%M/%%M.bin" "%ASSETS_DIR%\models\%%M\%%M.bin" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/%%M/%%M_diff_1k.jpg" "%ASSETS_DIR%\models\%%M\textures\%%M_diff_1k.jpg" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/%%M/%%M_nor_gl_1k.jpg" "%ASSETS_DIR%\models\%%M\textures\%%M_nor_gl_1k.jpg" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/%%M/%%M_arm_1k.jpg" "%ASSETS_DIR%\models\%%M\textures\%%M_arm_1k.jpg" || exit /b 1
)

for %%M in (shrub_01 moss_01) do (
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/gltf/1k/%%M/%%M_1k.gltf" "%ASSETS_DIR%\models\%%M\%%M.gltf" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/gltf/4k/%%M/%%M.bin" "%ASSETS_DIR%\models\%%M\%%M.bin" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/%%M/%%M_diff_1k.jpg" "%ASSETS_DIR%\models\%%M\textures\%%M_diff_1k.jpg" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/%%M/%%M_nor_gl_1k.jpg" "%ASSETS_DIR%\models\%%M\textures\%%M_nor_gl_1k.jpg" || exit /b 1
    call :FETCH "https://dl.polyhaven.org/file/ph-assets/Models/jpg/1k/%%M/%%M_arm_1k.jpg" "%ASSETS_DIR%\models\%%M\textures\%%M_arm_1k.jpg" || exit /b 1
)

call :FETCH "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Fox/glTF-Binary/Fox.glb" "%ASSETS_DIR%\models\animals\Fox.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Assets/main/Models/Duck/glTF-Binary/Duck.glb" "%ASSETS_DIR%\models\animals\Duck.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Stork.glb" "%ASSETS_DIR%\models\animals\Stork.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Parrot.glb" "%ASSETS_DIR%\models\animals\Parrot.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Flamingo.glb" "%ASSETS_DIR%\models\animals\Flamingo.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/mrdoob/three.js/dev/examples/models/gltf/Horse.glb" "%ASSETS_DIR%\models\animals\Horse.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/Vuena/free-low-poly-animals-cc0/main/GLB/animal_owl.glb" "%ASSETS_DIR%\models\animals\animal_owl.glb" || exit /b 1
call :FETCH "https://raw.githubusercontent.com/Vuena/free-low-poly-animals-cc0/main/GLB/animal_fox.glb" "%ASSETS_DIR%\models\animals\animal_fox.glb" || exit /b 1
exit /b 0

:FETCH
if exist "%~2" exit /b 0
if not exist "%~dp2." mkdir "%~dp2"
echo   -^> %~nx2
curl.exe -fsSL --retry 3 "%~1" -o "%~2.part"
if errorlevel 1 (
    if exist "%~2.part" del /f /q "%~2.part"
    echo [ERROR] Failed downloading %~1
    exit /b 1
)
move /y "%~2.part" "%~2" >nul
set "NEED_IMPORT=1"
exit /b 0

:DL_FILE
setlocal
set "DL_URL=%~1"
set "DL_OUT=%~2"
set "DL_HDR=%TMP_DIR%\dl_hdr.txt"
if not exist "%TMP_DIR%" mkdir "%TMP_DIR%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $inv=[Globalization.CultureInfo]::InvariantCulture; $u=$env:DL_URL; $out=$env:DL_OUT; $part=$out+'.part'; $hdr=$env:DL_HDR; if(Test-Path $part){Remove-Item $part -Force -ErrorAction SilentlyContinue}; if(Test-Path $hdr){Remove-Item $hdr -Force -ErrorAction SilentlyContinue}; $psi=[System.Diagnostics.ProcessStartInfo]::new('curl.exe'); $psi.UseShellExecute=$false; $psi.RedirectStandardError=$true; $psi.Arguments='-fsSL --retry 3 -D \"'+$hdr+'\" \"'+$u+'\" -o \"'+$part+'\"'; $p=[System.Diagnostics.Process]::Start($psi); $errTask=$p.StandardError.ReadToEndAsync(); $sw=[System.Diagnostics.Stopwatch]::StartNew(); $pos=0; $dir=1; $barW=18; $pill=5; $isRedir=$false; try{$isRedir=[Console]::IsOutputRedirected}catch{}; $maxW=48; try{$ww=[Console]::WindowWidth; if($ww -gt 16){$maxW=[Math]::Min(54,$ww-2)}}catch{}; function Show([string]$s,[bool]$nl){if($s.Length -gt $maxW){$s=$s.Substring(0,$maxW)}else{$s=$s.PadRight($maxW)}; if($nl){$pre=if($isRedir){''}else{\"`r\"}; [Console]::Write($pre+$s+\"`n\")}elseif(-not $isRedir){[Console]::Write(\"`r\"+$s)}}; while(-not $p.WaitForExit(110)){$got=0L; if(Test-Path $part){$got=(Get-Item $part).Length}; $tot=0L; if(Test-Path $hdr){try{$raw=Get-Content $hdr -Raw -ErrorAction SilentlyContinue; if($raw){$blocks=$raw -split '(\r?\n){2,}' | Where-Object {$_.Trim().Length -gt 0}; if($blocks){$last=@($blocks)[-1]; if($last -match '(?im)^content-length:\s*(\d+)'){$tot=[long]$matches[1]}}}}catch{}}; $mb=$got/1048576.0; $sec=[Math]::Max(0.1,$sw.Elapsed.TotalSeconds); $spd=$mb/$sec; if($tot -gt 1024){$frac=[Math]::Min(1.0,$got/[double]$tot); $fill=[int][Math]::Round($frac*$barW); $pct=[int][Math]::Round($frac*100.0); $bar=('#'*$fill)+('-'*($barW-$fill)); $totMb=$tot/1048576.0; Show ('  ['+$bar+'] '+$pct.ToString().PadLeft(3)+[char]37+' '+$mb.ToString('0.0',$inv)+'/'+$totMb.ToString('0.0',$inv)+' MB') $false}else{$track=('-'*$barW).ToCharArray(); for($i=0;$i -lt $pill;$i++){$track[$pos+$i]='='}; $pos+=$dir; if($pos -ge ($barW-$pill)){$pos=$barW-$pill; $dir=-1}elseif($pos -le 0){$pos=0; $dir=1}; $bar=-join $track; Show ('  ['+$bar+'] '+$mb.ToString('0.0',$inv).PadLeft(5)+' MB ('+$spd.ToString('0.0',$inv)+' MB/s)') $false}}; $p.WaitForExit(); $err=$errTask.GetAwaiter().GetResult(); if($p.ExitCode -ne 0){if(-not $isRedir){Show '' $false}; if($err){[Console]::Error.WriteLine($err.Trim())}; exit $p.ExitCode}; $got=if(Test-Path $part){(Get-Item $part).Length}else{0L}; $mb=$got/1048576.0; $sec=[Math]::Max(0.1,$sw.Elapsed.TotalSeconds); $spd=$mb/$sec; $doneBar='#'*$barW; Show ('  ['+$doneBar+'] 100'+[char]37+' '+$mb.ToString('0.0',$inv)+' MB ('+$spd.ToString('0.0',$inv)+' MB/s)') $true"
if errorlevel 1 (
    if exist "%DL_OUT%.part" del /f /q "%DL_OUT%.part"
    if exist "%DL_HDR%" del /f /q "%DL_HDR%"
    endlocal & exit /b 1
)
if exist "%DL_HDR%" del /f /q "%DL_HDR%"
move /y "%DL_OUT%.part" "%DL_OUT%" >nul
endlocal
exit /b 0

:WRITE_DEFAULT_CONFIG
>  "%GAME_DIR%\config.cfg" echo [graphics]
>> "%GAME_DIR%\config.cfg" echo preset=3
>> "%GAME_DIR%\config.cfg" echo render_scale=1.0
>> "%GAME_DIR%\config.cfg" echo antialiasing=3
>> "%GAME_DIR%\config.cfg" echo shadows=3
>> "%GAME_DIR%\config.cfg" echo sdfgi=false
>> "%GAME_DIR%\config.cfg" echo ssao=true
>> "%GAME_DIR%\config.cfg" echo ssr=true
>> "%GAME_DIR%\config.cfg" echo volumetric_fog=true
>> "%GAME_DIR%\config.cfg" echo glow=true
>> "%GAME_DIR%\config.cfg" echo foliage_density=1.0
>> "%GAME_DIR%\config.cfg" echo view_distance=1.0
>> "%GAME_DIR%\config.cfg" echo weather_mode=0
>> "%GAME_DIR%\config.cfg" echo day_time_mode=0
>> "%GAME_DIR%\config.cfg" echo day_duration_min=28.0
>> "%GAME_DIR%\config.cfg" echo.
>> "%GAME_DIR%\config.cfg" echo [display]
>> "%GAME_DIR%\config.cfg" echo width=1920
>> "%GAME_DIR%\config.cfg" echo height=1080
>> "%GAME_DIR%\config.cfg" echo window_mode=0
>> "%GAME_DIR%\config.cfg" echo vsync=1
>> "%GAME_DIR%\config.cfg" echo max_fps=0
>> "%GAME_DIR%\config.cfg" echo show_fps=false
>> "%GAME_DIR%\config.cfg" echo language="en"
>> "%GAME_DIR%\config.cfg" echo.
>> "%GAME_DIR%\config.cfg" echo [audio]
>> "%GAME_DIR%\config.cfg" echo master_volume=0.8
>> "%GAME_DIR%\config.cfg" echo.
>> "%GAME_DIR%\config.cfg" echo [launcher]
>> "%GAME_DIR%\config.cfg" echo renderer_mode=1
exit /b 0

:GET_DEF_MODE
set "DEF_MODE=1"
set "HAS_LAUNCHER_CFG=0"
set "IN_LAUNCHER=0"
if exist "%CFG_FILE%" for /f "usebackq tokens=1* delims==" %%A in ("%CFG_FILE%") do call :CFG_READ_LINE "%%~A" "%%~B"
if "%HAS_LAUNCHER_CFG%"=="0" if exist "%ROOT%.run_mode" set /p DEF_MODE=<"%ROOT%.run_mode"
set "DEF_MODE=%DEF_MODE: =%"
if not "%DEF_MODE%"=="1" if not "%DEF_MODE%"=="2" if not "%DEF_MODE%"=="3" set "DEF_MODE=1"
exit /b 0

:CFG_READ_LINE
set "K=%~1"
set "K=%K: =%"
if not "%K:~0,1%"=="[" goto :CFG_READ_KV
if /i "%K%"=="[launcher]" (set "IN_LAUNCHER=1") else (set "IN_LAUNCHER=0")
exit /b 0

:CFG_READ_KV
if "%IN_LAUNCHER%"=="1" if /i "%K%"=="renderer_mode" (
    set "DEF_MODE=%~2"
    set "HAS_LAUNCHER_CFG=1"
)
exit /b 0

:SAVE_MODE
if not exist "%CFG_FILE%" call :WRITE_DEFAULT_CONFIG
setlocal EnableDelayedExpansion
set "NEW_MODE=%~1"
set "IN_L=0"
set "WROTE_L=0"
set "SAW_SEC=0"
> "%CFG_FILE%.tmp" (
    for /f "usebackq delims=" %%L in ("%CFG_FILE%") do (
        set "LINE=%%L"
        call :CFG_WRITE_LINE
    )
    call :CFG_FINISH_LAUNCHER
)
move /y "%CFG_FILE%.tmp" "%CFG_FILE%" >nul
endlocal
if exist "%ROOT%.run_mode" del /f /q "%ROOT%.run_mode" 2>nul
exit /b 0

:CFG_WRITE_LINE
set "TRIM=!LINE: =!"
if "!TRIM:~0,1!"=="[" (
    if "!IN_L!"=="1" if "!WROTE_L!"=="0" (
        echo renderer_mode=!NEW_MODE!
        set "WROTE_L=1"
    )
    if "!SAW_SEC!"=="1" echo.
    set "SAW_SEC=1"
    if /i "!TRIM!"=="[launcher]" (set "IN_L=1") else (set "IN_L=0")
    echo !LINE!
    exit /b 0
)
if "!IN_L!"=="1" (
    for /f "tokens=1 delims==" %%K in ("!TRIM!") do (
        if /i "%%K"=="renderer_mode" (
            echo renderer_mode=!NEW_MODE!
            set "WROTE_L=1"
            exit /b 0
        )
    )
)
echo !LINE!
exit /b 0

:CFG_FINISH_LAUNCHER
if "!WROTE_L!"=="0" (
    if "!IN_L!"=="0" (
        if "!SAW_SEC!"=="1" echo.
        echo [launcher]
    )
    echo renderer_mode=!NEW_MODE!
)
exit /b 0

:NO_CURL
echo [ERROR] curl.exe not found (Windows 10 1803+ / Windows 11 required).
goto :FAIL_END

:NO_TAR
echo [ERROR] tar.exe not found (Windows 10 1803+ / Windows 11 required).
goto :FAIL_END

:FAIL_END
echo [ERROR] Setup or launch failed.
if not defined NO_PAUSE pause
exit /b 1
