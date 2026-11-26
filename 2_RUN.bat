@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [Console]::OutputEncoding=[System.Text.UTF8Encoding]::new($false); $items=@('DirectX 12 (Forward+)  - 2_RUN_DX12.bat','Vulkan (Forward+)      - 2_RUN_Vulkan.bat','OpenGL 3 (Сумісність)  - 2_RUN_OpenGL.bat'); $codes=@(10,11,12); $idx=0; try{[Console]::CursorVisible=$false}catch{}; try{while($true){Clear-Host; Write-Host '======================================================' -ForegroundColor DarkYellow; Write-Host '   ЛІСОВЕ КАЗИНО - ОБЕРІТЬ РЕЖИМ ЗАПУСКУ' -ForegroundColor Yellow; Write-Host '======================================================' -ForegroundColor DarkYellow; Write-Host ''; for($i=0;$i -lt $items.Count;$i++){if($i -eq $idx){Write-Host ('  > ' + $items[$i] + ' ') -ForegroundColor Black -BackgroundColor Green}else{Write-Host ('    ' + $items[$i]) -ForegroundColor Gray}}; Write-Host ''; Write-Host '  [Стрілки Вгору/Вниз] або [1-3] - вибір' -ForegroundColor DarkCyan; Write-Host '  [Enter] - запуск  |  [Esc] - вихід' -ForegroundColor DarkCyan; $k=[Console]::ReadKey($true); switch($k.Key){'UpArrow'{if($idx -le 0){$idx=$items.Count-1}else{$idx--}} 'W'{if($idx -le 0){$idx=$items.Count-1}else{$idx--}} 'DownArrow'{if($idx -ge $items.Count-1){$idx=0}else{$idx++}} 'S'{if($idx -ge $items.Count-1){$idx=0}else{$idx++}} 'D1'{$idx=0} 'NumPad1'{$idx=0} 'D2'{$idx=1} 'NumPad2'{$idx=1} 'D3'{$idx=2} 'NumPad3'{$idx=2} 'Enter'{exit $codes[$idx]} 'Spacebar'{exit $codes[$idx]} 'Escape'{exit 0}}}}finally{try{[Console]::CursorVisible=$true}catch{}}"
set "RC=%ERRORLEVEL%"

if "%RC%"=="10" (
	call "%~dp02_RUN_DX12.bat"
	exit /b %ERRORLEVEL%
)
if "%RC%"=="11" (
	call "%~dp02_RUN_Vulkan.bat"
	exit /b %ERRORLEVEL%
)
if "%RC%"=="12" (
	call "%~dp02_RUN_OpenGL.bat"
	exit /b %ERRORLEVEL%
)
exit /b 0
