@echo off
rem Testet die Browser-Version aus build\web\ lokal.
rem Startet einen kleinen HTTP-Server und oeffnet das Spiel im Standardbrowser.
rem   test-web.bat        -> Port 8060
rem   test-web.bat 9000   -> Port 9000
rem Beenden: Strg+C in diesem Fenster (oder Fenster schliessen).
rem Wichtig: ueber file:// laedt der Browser das WASM nicht - daher dieser Server.
setlocal

set "PORT=%1"
if "%PORT%"=="" set "PORT=8060"

if not exist "%~dp0web\index.html" goto no_build

set "PY="
where py >nul 2>nul
if not errorlevel 1 set "PY=py"
if defined PY goto have_python
where python >nul 2>nul
if not errorlevel 1 set "PY=python"
if defined PY goto have_python
where python3 >nul 2>nul
if not errorlevel 1 set "PY=python3"
if not defined PY goto no_python

:have_python

echo Starte HTTP-Server auf http://localhost:%PORT%/ ...
echo Verzeichnis: %~dp0web
echo.
echo Browser wird gleich geoeffnet.  Zum Beenden: Strg+C
echo.
start "" "http://localhost:%PORT%/"
%PY% -m http.server %PORT% --directory "%~dp0web"
goto done

:no_build
echo Kein Web-Build gefunden: %~dp0web\index.html
echo Bitte zuerst build-web.bat ausfuehren.
pause
goto done

:no_python
echo Kein Python gefunden - ohne HTTP-Server laesst sich der Web-Build nicht
echo testen (ueber file:// laedt der Browser das WASM nicht).
pause

:done
