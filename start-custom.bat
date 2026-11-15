@echo off
REM Start the custom Velxio build: backend (8001) + frontend (5173) with our overlay.
REM The overlay lives in frontend\src\pro and is only loaded when VITE_PRO_BUILD
REM is set AND PRO_OVERLAY_PATH points at it (see frontend/vite.config.ts).
setlocal
set "ROOT=%~dp0"
set "OVERLAY=%ROOT%frontend\src\pro"

REM arduino-cli: prefer local tools\ copy, fall back to PATH.
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

REM Export the overlay env vars here: `start` children inherit them, so we never
REM write `set VAR=value && cmd` - cmd would swallow the space before && into the
REM value, and a trailing space in PRO_OVERLAY_PATH breaks the @pro alias.
set "VITE_PRO_BUILD=true"
set "PRO_OVERLAY_PATH=%OVERLAY%"
if defined TOOLS set "PATH=%TOOLS%;%PATH%"

echo Overlay:  %PRO_OVERLAY_PATH%
echo Starting backend on 127.0.0.1:8001 (first run installs the AVR core, 2-3 min)...
start "velxio backend" /d "%ROOT%backend" cmd /c "venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001"

echo Starting frontend on localhost:5173 ...
start "velxio frontend" /d "%ROOT%frontend" cmd /c "npx vite --port 5173 --strictPort"

echo Waiting for the dev server...
set "HASCURL="
where curl >nul 2>nul && set "HASCURL=1"
if not defined HASCURL (
  timeout /t 10 /nobreak >nul
  goto :ready
)
set /a TRIES=0
:wait
set /a TRIES+=1
timeout /t 2 /nobreak >nul
curl -s -o nul http://localhost:5173/ && goto :ready
if %TRIES% lss 30 goto :wait
echo [!] dev server did not answer within 60s - check the "velxio frontend" window.
goto :done

:ready
start "" http://localhost:5173/editor

:done
echo.
echo   App:      http://localhost:5173/editor      (use "localhost", not 127.0.0.1)
echo   Backend:  http://127.0.0.1:8001/docs
echo   Board:    search "zhanshenkx" in the component picker
endlocal
