@echo off
rem Packt den fertigen Web-Build als ZIP fuer itch.io nach build\itch\.
rem Voraussetzung: build\web\ existiert (sonst zuerst build-web.bat).
rem Wichtig: index.html muss auf oberster Ebene im ZIP liegen, sonst findet
rem itch.io das Spiel nicht - deshalb wird der Inhalt von build\web gepackt
rem und nicht der Ordner selbst.
rem Beim Hochladen ankreuzen: "This file will be played in the browser".
rem Projekt-Kind: HTML, SharedArrayBuffer AUS (der Build ist single-threaded).
setlocal

set "NOPAUSE="
if /i "%1"=="nopause" set "NOPAUSE=1"

if not exist "%~dp0web\index.html" goto no_web
if not exist "%~dp0itch" mkdir "%~dp0itch"

set "ZIP=%~dp0itch\carry-queen-web-itch.zip"
set "QUELLE=%~dp0web"
echo Packe build\web\ nach build\itch\ ...
powershell -NoProfile -Command "$z='%ZIP%'; if(Test-Path $z){del $z}; Compress-Archive -Path (Join-Path '%QUELLE%' '*') -DestinationPath $z -CompressionLevel Optimal"
if errorlevel 1 goto zip_failed
if not exist "%ZIP%" goto zip_failed

rem Gegenprobe: liegt index.html wirklich auf oberster Ebene?
powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $a=[IO.Compression.ZipFile]::OpenRead('%ZIP%'); $ok=$a.Entries.FullName -contains 'index.html'; $mb=[math]::Round((Get-Item '%ZIP%').Length/1MB,1); $a.Dispose(); if(-not $ok){Write-Host 'FEHLER: index.html liegt nicht auf oberster Ebene'; exit 1}; Write-Host ('OK  index.html auf oberster Ebene, ' + $mb + ' MB')"
if errorlevel 1 goto bad_layout

echo.
echo Fertig: %ZIP%
goto done

:no_web
echo Kein Web-Build gefunden: %~dp0web\index.html
echo Bitte zuerst build-web.bat ausfuehren.
goto fail

:zip_failed
echo ZIP konnte nicht erstellt werden.
goto fail

:bad_layout
echo Das ZIP hat die falsche Struktur - itch.io wuerde das Spiel nicht finden.
goto fail

:fail
if not defined NOPAUSE pause
exit /b 1

:done
if not defined NOPAUSE pause
exit /b 0
