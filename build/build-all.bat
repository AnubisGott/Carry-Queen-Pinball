@echo off
rem Baut alle Deploy-Targets, je einer pro Unterordner in build\:
rem   windows\  linux\  web\  itch\ (ZIP des Web-Builds)
rem Einzeln: build-windows.bat / build-linux.bat / build-web.bat /
rem build-itch.bat (liegen daneben in build\).
rem   android\ (Debug-APK, zum Testen auf Emulator oder Telefon)
rem Android braucht zusaetzlich Android-SDK und JDK in den Godot-Einstellungen.
rem Fehlt davon etwas, sollen die fertigen Desktop- und Web-Builds nicht
rem verworfen werden - deshalb dort nur eine Warnung.
call "%~dp0build-windows.bat" nopause
if errorlevel 1 (
    echo Windows-Build fehlgeschlagen.
    pause
    exit /b 1
)
call "%~dp0build-linux.bat" nopause
if errorlevel 1 (
    echo Linux-Build fehlgeschlagen.
    pause
    exit /b 1
)
call "%~dp0build-web.bat" nopause
if errorlevel 1 (
    echo Web-Build fehlgeschlagen.
    pause
    exit /b 1
)
call "%~dp0build-itch.bat" nopause
if errorlevel 1 (
    echo itch.io-Paket fehlgeschlagen.
    pause
    exit /b 1
)
set "ANDROID_OK=ja"
call "%~dp0build-android.bat" nopause
if errorlevel 1 set "ANDROID_OK=nein"
echo.
echo Fertige Builds:
echo   build\windows\
echo   build\linux\
echo   build\web\
echo   build\itch\
if "%ANDROID_OK%"=="ja" echo   build\android\
if "%ANDROID_OK%"=="nein" echo   build\android\ - NICHT gebaut (SDK/JDK pruefen)
pause
