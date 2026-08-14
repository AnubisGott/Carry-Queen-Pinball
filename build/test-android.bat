@echo off
rem Bringt das APK aus build\android\ auf den Emulator und startet es.
rem   test-android.bat              -> nimmt das erste AVD
rem   test-android.bat Medium_Phone -> nimmt dieses AVD
rem Laeuft schon ein Geraet (Emulator oder angestecktes Telefon), wird das
rem benutzt.
rem
rem Zwei Dinge, die beim Einrichten Zeit gekostet haben und deshalb hier
rem stehen:
rem   - Der Emulator braucht Platz.  War /data zu 91%% voll, scheiterte die
rem     Installation mit INSTALL_FAILED_INSUFFICIENT_STORAGE, auch bei einem
rem     36-MB-Paket.  Abhilfe: im Device Manager "Wipe Data".
rem   - Gestartet wird ueber den Startbildschirm (monkey).  Ein direktes
rem     "am start -n ...GodotApp" verweigert Android: die Aktivitaet ist
rem     nicht exportiert.
setlocal

set "AVD=%1"
set "SDK=%ANDROID_HOME%"
if "%SDK%"=="" set "SDK=%LOCALAPPDATA%\Android\Sdk"
set "ADB=%SDK%\platform-tools\adb.exe"
set "EMU=%SDK%\emulator\emulator.exe"
set "APK=%~dp0android\carry-queen-pinball.apk"
set "PAKET=de.anubisgott.carryqueen"

if not exist "%ADB%" goto no_sdk
if not exist "%APK%" goto no_apk

echo Suche ein Geraet ...
"%ADB%" get-state >nul 2>nul
if not errorlevel 1 goto geraet_da

if not exist "%EMU%" goto no_emu
if "%AVD%"=="" for /f "usebackq delims=" %%A in (`"%EMU%" -list-avds`) do if not defined AVD set "AVD=%%A"
if "%AVD%"=="" goto no_avd
echo Starte Emulator %AVD% ...
start "" "%EMU%" -avd %AVD% -no-snapshot-save
"%ADB%" wait-for-device
echo Warte auf den Bootvorgang ...
"%ADB%" shell "while [ \"$(getprop sys.boot_completed)\" != \"1\" ]; do sleep 2; done"

:geraet_da
echo Installiere %APK% ...
"%ADB%" install -r "%APK%"
if errorlevel 1 goto install_failed
echo Starte das Spiel ...
"%ADB%" logcat -c
"%ADB%" shell monkey -p %PAKET% -c android.intent.category.LAUNCHER 1 >nul
echo.
echo Laeuft.  Ausgabe des Spiels mitlesen:
echo   "%ADB%" logcat -s godot:V
echo Bildschirmfoto holen:
echo   "%ADB%" exec-out screencap -p ^> bild.png
pause
exit /b 0

:no_sdk
echo Android-SDK nicht gefunden: %SDK%
echo ANDROID_HOME setzen oder den Pfad hier anpassen.
goto fail

:no_apk
echo Kein APK gefunden: %APK%
echo Bitte zuerst build-android.bat ausfuehren.
goto fail

:no_emu
echo Kein Emulator im SDK gefunden und kein Geraet angesteckt.
goto fail

:no_avd
echo Kein AVD eingerichtet.  Im Android Studio unter Device Manager anlegen.
goto fail

:install_failed
echo.
echo Installation fehlgeschlagen.  Haeufigster Grund: zu wenig Platz im
echo Emulator.  Im Device Manager "Wipe Data" ausfuehren und noch einmal.
goto fail

:fail
pause
exit /b 1
