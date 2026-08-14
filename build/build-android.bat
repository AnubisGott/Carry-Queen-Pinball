@echo off
rem Baut ein Android-Paket nach build\android\.
rem
rem Ohne Argument entsteht ein Debug-APK: signiert mit dem Debug-Keystore aus
rem den Godot-Einstellungen, sofort auf Geraet oder Emulator installierbar,
rem aber nicht fuer den Play Store geeignet.
rem   build-android.bat            -> Debug-APK (zum Testen)
rem   build-android.bat release    -> Release-APK (braucht einen eigenen
rem                                   Keystore, siehe unten)
rem
rem Fuer ein Release muessen vorher drei Umgebungsvariablen gesetzt sein:
rem   GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD
rem Der Keystore gehoert NICHT ins Repo - es ist oeffentlich.
rem
rem Das APK enthaelt arm64-v8a (Telefone) und x86_64 (Emulator).
rem Diese Datei liegt in build\ ; das Projekt ist eine Ebene hoeher (%~dp0..).
setlocal

set "ART=debug"
set "NOPAUSE="
if /i "%1"=="release" set "ART=release"
if /i "%1"=="nopause" set "NOPAUSE=1"
if /i "%2"=="nopause" set "NOPAUSE=1"

call "%~dp0godot-suchen.bat"
if errorlevel 1 goto fail

if not exist "%~dp0android" mkdir "%~dp0android"

if "%ART%"=="release" goto release
echo Exportiere Android-Debug-APK nach build\android\ ...
"%GODOT%" --headless --path "%~dp0.." --export-debug "Android"
goto geprueft

:release
if "%GODOT_ANDROID_KEYSTORE_RELEASE_PATH%"=="" goto no_keystore
echo Exportiere signiertes Android-Release-APK nach build\android\ ...
"%GODOT%" --headless --path "%~dp0.." --export-release "Android"

:geprueft
if errorlevel 1 (
    echo.
    echo Export fehlgeschlagen.  Zu pruefen:
    echo   - Android-SDK und JDK in den Godot-Einstellungen hinterlegt?
    echo   - Android-Export-Vorlagen zur Godot-Version installiert?
    goto fail
)
if not exist "%~dp0android\carry-queen-pinball.apk" (
    echo Kein APK entstanden.
    goto fail
)
echo.
echo Fertig: %~dp0android\carry-queen-pinball.apk  (%ART%)
echo Auf den Emulator bringen: test-android.bat
if not defined NOPAUSE pause
exit /b 0

:no_keystore
echo Fuer ein Release fehlt der Keystore.  Bitte setzen:
echo   GODOT_ANDROID_KEYSTORE_RELEASE_PATH, _USER, _PASSWORD
goto fail

:fail
if not defined NOPAUSE pause
exit /b 1
