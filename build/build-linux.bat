@echo off
rem Baut den Linux-Desktop-Build nach build\linux\.
rem Ergebnis: carry-queen-pinball.x86_64 (x86_64, eingebettetes PCK).
rem Diese Datei liegt in build\ ; das Projekt ist eine Ebene hoeher (%~dp0..).
call "%~dp0godot-suchen.bat"
if errorlevel 1 (
    if not "%1"=="nopause" pause
    exit /b 1
)
if not exist "%~dp0linux" mkdir "%~dp0linux"
echo Exportiere Linux-Build nach build\linux\ ...
"%GODOT%" --headless --path "%~dp0.." --export-release "Linux"
if errorlevel 1 (
    echo Erster Versuch fehlgeschlagen, wiederhole...
    "%GODOT%" --headless --path "%~dp0.." --export-release "Linux"
)
if errorlevel 1 (
    echo.
    echo Export fehlgeschlagen.  Sind die Linux-Export-Vorlagen installiert?
    if not "%1"=="nopause" pause
    exit /b 1
)
echo.
echo Fertig: %~dp0linux\
echo Hinweis: auf dem Zielsystem ggf. ausfuehrbar machen:
echo   chmod +x carry-queen-pinball.x86_64
if not "%1"=="nopause" pause
