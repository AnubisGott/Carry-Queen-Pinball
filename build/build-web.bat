@echo off
rem Baut den Web-Build (GL Compatibility, single-threaded) nach build\web\.
rem index.html liegt danach im Wurzel von build\web\ - bereit fuer itch.io
rem (Ordner per butler pushen, oder build\web\ zippen und hochladen).
rem Diese Datei liegt in build\ ; das Projekt ist eine Ebene hoeher (%~dp0..).
call "%~dp0godot-suchen.bat"
if errorlevel 1 (
    if not "%1"=="nopause" pause
    exit /b 1
)
if not exist "%~dp0web" mkdir "%~dp0web"
echo Exportiere Web-Build nach build\web\ ...
"%GODOT%" --headless --path "%~dp0.." --export-release "Web"
if errorlevel 1 (
    echo Erster Versuch fehlgeschlagen, wiederhole...
    "%GODOT%" --headless --path "%~dp0.." --export-release "Web"
)
if errorlevel 1 (
    echo.
    echo Export fehlgeschlagen.  Sind die Web-Export-Vorlagen installiert?
    if not "%1"=="nopause" pause
    exit /b 1
)
echo.
echo Fertig: %~dp0web\
if not "%1"=="nopause" pause
