@echo off
rem Sucht eine Godot-Programmdatei, zu der Export-Vorlagen installiert sind,
rem und legt sie in GODOT ab.  Wird von den anderen Skripten mit "call"
rem aufgerufen, damit GODOT dort verfuegbar ist - deshalb kein setlocal.
rem Reihenfolge: fester Pfad zuerst, dann die portable Fassung im Projekt.
set "GODOT="
if exist "C:\dev\godot\Godot_v4.7-stable_win64_console.exe" set "GODOT=C:\dev\godot\Godot_v4.7-stable_win64_console.exe"
if not defined GODOT if exist "%~dp0..\godot-engine\Godot_v4.7.1-stable_win64_console.exe" set "GODOT=%~dp0..\godot-engine\Godot_v4.7.1-stable_win64_console.exe"
if not defined GODOT (
    echo Keine Godot-Programmdatei gefunden.  Gesucht wurde:
    echo   C:\dev\godot\Godot_v4.7-stable_win64_console.exe
    echo   %~dp0..\godot-engine\Godot_v4.7.1-stable_win64_console.exe
    echo Pfad in godot-suchen.bat anpassen.
    exit /b 1
)
echo Godot: %GODOT%
exit /b 0
