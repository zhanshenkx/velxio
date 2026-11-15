@echo off
REM One-time setup: restore everything that this snapshot deliberately excludes
REM (node_modules, Python venv, Monaco static assets) and check arduino-cli.
setlocal enabledelayedexpansion
set ROOT=%~dp0
cd /d "%ROOT%"

echo ============================================================
echo  Velxio custom build - setup
echo ============================================================
echo.

REM ---------- prerequisites ----------
where node >nul 2>nul || (echo [!] Node.js not found in PATH & goto :fail)
where npm  >nul 2>nul || (echo [!] npm not found in PATH & goto :fail)
where python >nul 2>nul || (echo [!] Python not found in PATH & goto :fail)
for /f "tokens=*" %%v in ('node --version') do echo [ok] node %%v

REM ---------- frontend deps ----------
echo.
echo [1/4] Installing frontend dependencies (a few minutes)...
pushd frontend
call npm install --no-audit --no-fund
if errorlevel 1 (
  echo     retry with --legacy-peer-deps
  call npm install --no-audit --no-fund --legacy-peer-deps
)

REM npm sometimes skips optional platform binaries (npm/cli#4828). Vite then
REM dies with "Cannot find module @rollup/rollup-win32-x64-msvc".
if not exist "node_modules\@rollup\rollup-win32-x64-msvc" (
  echo     installing missing rollup/esbuild platform binaries
  call npm install --no-audit --no-fund --no-save @rollup/rollup-win32-x64-msvc @esbuild/win32-x64
)

REM ---------- monaco ----------
echo.
echo [2/4] Copying Monaco static assets (gitignored, ~16MB)...
if exist "public\monaco\vs\loader.js" (
  echo     already present
) else (
  if exist "node_modules\monaco-editor\min\vs" (
    mkdir "public\monaco" 2>nul
    xcopy /E /I /Q /Y "node_modules\monaco-editor\min\vs" "public\monaco\vs" >nul
    echo     copied from node_modules
  ) else (
    echo     [!] monaco-editor not installed; code editor will show "Loading..."
  )
)
popd

REM ---------- backend ----------
echo.
echo [3/4] Creating Python venv and installing backend requirements...
pushd backend
if not exist venv (
  python -m venv venv
)
call venv\Scripts\python.exe -m pip install -q --upgrade pip
call venv\Scripts\python.exe -m pip install -q -r requirements.txt
if errorlevel 1 (echo [!] pip install failed & popd & goto :fail)
echo     backend ready
popd

REM ---------- arduino-cli ----------
echo.
echo [4/4] Checking arduino-cli...
if exist "%ROOT%tools\arduino-cli.exe" (
  echo     found tools\arduino-cli.exe
  "%ROOT%tools\arduino-cli.exe" version
) else (
  where arduino-cli >nul 2>nul && (
    arduino-cli version
  ) || (
    echo     [!] arduino-cli NOT found - compiling sketches will fail.
    echo         Download: https://github.com/arduino/arduino-cli/releases
    echo         Put arduino-cli.exe in %ROOT%tools\  (or add it to PATH)
  )
)

echo.
echo ============================================================
echo  Setup complete. Now run:  start-custom.bat
echo ============================================================
pause
exit /b 0

:fail
echo.
echo Setup aborted. Fix the issue above and re-run.
pause
exit /b 1
