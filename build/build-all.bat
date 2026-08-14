@echo off
rem Baut alle Deploy-Targets, je einer pro Unterordner in build\:
rem   windows\  linux\  web\  itch\ (ZIP des Web-Builds)
rem Einzeln: build-windows.bat / build-linux.bat / build-web.bat /
rem build-itch.bat (liegen daneben in build\).
rem Kein Android: gespielt wird mit Tastatur (A/D Flipper, Leertaste
rem Abschuss), fuer ein Telefon braeuchte es erst eine Touch-Bedienung.
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
echo.
echo Fertige Builds:
echo   build\windows\
echo   build\linux\
echo   build\web\
echo   build\itch\
pause
