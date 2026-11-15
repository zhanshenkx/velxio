@echo off
REM One-time setup: restore everything this checkout deliberately excludes
REM (node_modules, Python venv) and check arduino-cli.
setlocal
set "ROOT=%~dp0"
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
REM --legacy-peer-deps, unconditionally. Upstream gitignores package-lock.json
REM (see .gitignore), so every clone resolves the tree from scratch and npm
REM 10/11 dies with "Cannot read properties of null (reading 'edgesOut')" on the
REM peer graph. Ignoring peers sidesteps that path and installs cleanly
REM (measured: 551 packages in ~2 min).
call npm install --no-audit --no-fund --legacy-peer-deps
if errorlevel 1 (
  echo     retry without --legacy-peer-deps
  call npm install --no-audit --no-fund
)
if errorlevel 1 (echo [!] npm install failed & popd & goto :fail)

REM npm sometimes skips optional platform binaries (npm/cli#4828). Vite then
REM dies with "Cannot find module @rollup/rollup-win32-x64-msvc".
if not exist "node_modules\@rollup\rollup-win32-x64-msvc" (
  echo     installing missing rollup/esbuild platform binaries
  call npm install --no-audit --no-fund --no-save @rollup/rollup-win32-x64-msvc @esbuild/win32-x64
)
if not exist "node_modules\@esbuild\win32-x64" (
  call npm install --no-audit --no-fund --no-save @esbuild/win32-x64
)

REM ---------- monaco ----------
REM The package.json postinstall (scripts/copy-monaco.mjs) normally does this;
REM the copy below is the fallback for installs run with --ignore-scripts.
echo.
echo [2/4] Checking Monaco static assets (gitignored, ~16MB)...
if exist "public\monaco\vs\loader.js" (
  echo     already present
) else (
  if exist "node_modules\monaco-editor\min\vs" (
    mkdir "public\monaco" 2>nul
    xcopy /E /I /Q /Y "node_modules\monaco-editor\min\vs" "public\monaco\vs" >nul
    echo     copied from node_modules
  ) else (
    echo [!] monaco-editor not installed - the code editor will show "Loading..."
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
if not exist "%ROOT%tools" mkdir "%ROOT%tools"
if exist "%ROOT%tools\arduino-cli.exe" (
  echo     found tools\arduino-cli.exe
  "%ROOT%tools\arduino-cli.exe" version
) else (
  where arduino-cli >nul 2>nul && (
    arduino-cli version
  ) || (
    echo [!] arduino-cli NOT found - compiling sketches will fail.
    echo     Download https://github.com/arduino/arduino-cli/releases
    echo     and put arduino-cli.exe in %ROOT%tools\  - or add it to PATH.
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
