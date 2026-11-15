@echo off
REM Same as start-custom.bat, but the dev server listens on the LAN so phones and
REM tablets can open the editor. The backend stays on 127.0.0.1 - Vite proxies
REM /api to it, so the API is reachable through the same origin and nothing else
REM is exposed.
setlocal
set "ROOT=%~dp0"
set "OVERLAY=%ROOT%frontend\src\pro"

set "TOOLS="
if exist "%ROOT%tools\arduino-cli.exe" (
  set "TOOLS=%ROOT%tools"
) else (
  where arduino-cli >nul 2>nul || (
    echo [!] arduino-cli not found. Compiling sketches will fail.
    echo     Put arduino-cli.exe in %ROOT%tools\ - or add it to PATH.
    echo.
  )
)

if not exist "%ROOT%backend\venv\Scripts\python.exe" (
  echo [!] backend venv missing. Run setup.bat first.
  pause
  exit /b 1
)
if not exist "%ROOT%frontend\node_modules" (
  echo [!] frontend node_modules missing. Run setup.bat first.
  pause
  exit /b 1
)
if not exist "%OVERLAY%\index.ts" (
  echo [!] overlay missing at %OVERLAY%
  pause
  exit /b 1
)

REM Overlay path must have no trailing space - see CUSTOM.md.
set "VITE_PRO_BUILD=true"
set "PRO_OVERLAY_PATH=%OVERLAY%"
if defined TOOLS set "PATH=%TOOLS%;%PATH%"

echo Overlay:  %PRO_OVERLAY_PATH%
echo Starting backend on 127.0.0.1:8001 ...
start "velxio backend" /d "%ROOT%backend" cmd /c "venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001"

echo Starting frontend on 0.0.0.0:5173 ...
start "velxio frontend" /d "%ROOT%frontend" cmd /c "npx vite --host 0.0.0.0 --port 5173 --strictPort"

echo Waiting for the dev server...
set "CURL=%SystemRoot%\System32\curl.exe"
set /a TRIES=0
if not exist "%CURL%" (
  ping -n 6 127.0.0.1 >nul
  goto :ready
)
:wait
set /a TRIES+=1
ping -n 3 127.0.0.1 >nul
"%CURL%" -s -o nul http://localhost:5173/ && goto :ready
if %TRIES% lss 30 goto :wait
echo [!] dev server did not answer within 60s - check the "velxio frontend" window.
goto :done

:ready
start "" http://localhost:5173/editor

:done
echo.
echo   This machine:  http://localhost:5173/editor
echo   Other devices: http://^<this-PC-IPv4^>:5173/editor
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do call :show %%a
echo.
echo   Backend is loopback-only; /api is proxied by Vite, so the LAN only sees 5173.
echo   Phone cannot connect? Allow Node.js through Windows Firewall for private
echo   networks - Windows normally asks the first time Vite binds 0.0.0.0.
endlocal
exit /b 0

:show
set "IP=%~1"
set "IP=%IP: =%"
if "%IP%"=="127.0.0.1" exit /b 0
echo                 http://%IP%:5173/editor
exit /b 0
