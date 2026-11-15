@echo off
REM Start the custom Velxio build: backend (8001) + frontend (5173) with our overlay.
REM The overlay lives in frontend\src\pro and is only loaded when VITE_PRO_BUILD
REM is set AND PRO_OVERLAY_PATH points at it (see frontend/vite.config.ts).
setlocal
set ROOT=%~dp0
set OVERLAY=%ROOT%frontend\src\pro

REM arduino-cli: prefer local tools\ copy, fall back to PATH.
if exist "%ROOT%tools\arduino-cli.exe" (
  set TOOLS=%ROOT%tools
) else (
  where arduino-cli >nul 2>nul && (set TOOLS=) || (
    echo [!] arduino-cli not found. Compile will fail until it is installed.
    echo     Put arduino-cli.exe in %ROOT%tools\ or add it to PATH.
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

echo Starting backend on 127.0.0.1:8001 (first run installs the AVR core, 2-3 min)...
if defined TOOLS (
  start "velxio backend" cmd /c "set PATH=%TOOLS%;%PATH% && cd /d %ROOT%backend && venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001"
) else (
  start "velxio backend" cmd /c "cd /d %ROOT%backend && venv\Scripts\python.exe -m uvicorn app.main:app --host 127.0.0.1 --port 8001"
)

echo Starting frontend on localhost:5173 ...
start "velxio frontend" cmd /c "cd /d %ROOT%frontend && set VITE_PRO_BUILD=true && set PRO_OVERLAY_PATH=%OVERLAY% && npx vite --port 5173 --strictPort"

timeout /t 8 /nobreak >nul
start "" http://localhost:5173/editor
echo.
echo   App:      http://localhost:5173/editor      (use "localhost", not 127.0.0.1)
echo   Backend:  http://127.0.0.1:8001/docs
echo   Board:    search "zhanshenkx" in the component picker
endlocal
