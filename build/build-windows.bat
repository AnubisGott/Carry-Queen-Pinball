@echo off
rem Baut den Windows-Desktop-Build nach build\windows\.
rem Diese Datei liegt in build\ ; das Projekt ist eine Ebene hoeher (%~dp0..).
rem
rem Godot und Export-Vorlagen muessen zusammenpassen.  Installiert sind die
rem Vorlagen fuer 4.7.stable, deshalb wird zuerst danach gesucht; die
rem mitgelieferte portable 4.7.1 taugt zum Spielen und Testen, exportiert
rem aber nur mit passenden 4.7.1-Vorlagen.
call "%~dp0godot-suchen.bat" || exit /b 1
if not exist "%~dp0windows" mkdir "%~dp0windows"
echo Exportiere Windows-Build nach build\windows\ ...
"%GODOT%" --headless --path "%~dp0.." --export-release "Windows Desktop"
if errorlevel 1 (
    echo Erster Versuch fehlgeschlagen, wiederhole...
    "%GODOT%" --headless --path "%~dp0.." --export-release "Windows Desktop"
)
if errorlevel 1 (
    echo.
    echo Export fehlgeschlagen.  Sind die Export-Vorlagen zur Godot-Version da?
    if not "%1"=="nopause" pause
    exit /b 1
)
echo.
echo Fertig: %~dp0windows\
if not "%1"=="nopause" pause
