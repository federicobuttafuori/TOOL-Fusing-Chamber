@echo off
setlocal enabledelayedexpansion

rem Script folder (drag-and-drop: concat list is written here)
set "FUSER_SCRIPTDIR=%~dp0"
rem Working directory at launch (shortcut "Avvia in", Explorer, etc.) — output goes here in drag mode
set "FUSER_STARTDIR=%CD%"

rem Ensure all videos are in the same format and have compatible settings
rem Folder mode uses the current working directory (shortcut "Avvia in", Explorer folder, etc.)

rem ---------------------------------------------------------------------------
rem Mode A: files dragged onto this .bat — fuse them in drop order
rem ---------------------------------------------------------------------------
if not "%~1"=="" goto :from_dragdrop

rem ---------------------------------------------------------------------------
rem Mode B: double-click — fuse all .mp4 in this folder (unchanged behavior)
rem ---------------------------------------------------------------------------

rem Step 1: Get the first file to use as prefix
for %%f in (*.mp4) do (
    set "first_file=%%~nf"
    goto :got_prefix
)
echo Nessun file .mp4 in questa cartella.
pause
exit /b 1
:got_prefix

rem Step 2: Generate the list of input files and build output filename
rem This will create a file called concat.txt listing all mp4 files in the folder
echo Generating file list...
set "output_name="
set "first_file="
(for %%i in (*.mp4) do (
    @echo file '%%i'
    if not defined first_file (
        set "first_file=%%~ni"
        set "output_name=%%~ni"
    ) else (
        set "output_name=!output_name!_(+)_%%~ni"
    )
)) > concat.txt

set "FUSER_CONCAT=concat.txt"
set "FUSER_DRAGMODE=0"
goto :run_ffmpeg

:from_dragdrop
set "FUSER_PLIST=%TEMP%\fuser_paths_%RANDOM%%RANDOM%.txt"
if exist "%FUSER_PLIST%" del "%FUSER_PLIST%" 2>nul
set "first_file="

:drag_loop
if "%~1"=="" goto :drag_after_collect
if exist "%~f1" (
    if not defined first_file set "first_file=%~n1"
    >>"%FUSER_PLIST%" echo(%~f1
) else (
    echo File non trovato, ignorato: "%~1"
)
shift
goto :drag_loop

:drag_after_collect
if not exist "%FUSER_PLIST%" (
    echo Nessun file valido trascinato.
    pause
    exit /b 1
)
for %%A in ("%FUSER_PLIST%") do if %%~zA equ 0 (
    echo Nessun file valido trascinato.
    del "%FUSER_PLIST%" 2>nul
    pause
    exit /b 1
)

set "FUSER_OUT=%FUSER_SCRIPTDIR%concat.txt"
echo Generating file list from file trascinati...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$plist = $env:FUSER_PLIST; $out = $env:FUSER_OUT; " ^
  "$paths = Get-Content -LiteralPath $plist -ErrorAction SilentlyContinue | Where-Object { $_ -and (Test-Path -LiteralPath $_) }; " ^
  "if (-not $paths) { exit 1 }; " ^
  "$q = [char]39; $rep = -join [char[]](39, 92, 39, 39); " ^
  "$lines = $paths | ForEach-Object { $full = ((Resolve-Path -LiteralPath $_).Path).Replace([char]92, [char]47); $esc = $full.Replace([string]$q, $rep); 'file ' + $q + $esc + $q }; " ^
  "$enc = New-Object System.Text.UTF8Encoding ($false); [System.IO.File]::WriteAllLines($out, [string[]]$lines, $enc)"
if errorlevel 1 (
    echo Impossibile creare concat.txt dai file trascinati.
    del "%FUSER_PLIST%" 2>nul
    pause
    exit /b 1
)

rem Build output filename from all dragged files
set "output_name="
set "first_file="
for /f "usebackq delims=" %%i in ("%FUSER_PLIST%") do (
    if exist "%%i" (
        if not defined first_file (
            set "first_file=%%~ni"
            set "output_name=%%~ni"
        ) else (
            set "output_name=!output_name!_(+)_%%~ni"
        )
    )
)

del "%FUSER_PLIST%" 2>nul

if not defined first_file (
    echo Prefisso output non disponibile.
    pause
    exit /b 1
)

set "FUSER_CONCAT=%FUSER_SCRIPTDIR%concat.txt"
set "FUSER_DRAGMODE=1"
rem FUSER_STARTDIR was captured at script start (= cartella "Avvia in" del collegamento)

:run_ffmpeg
rem Step 3: Prepare the FFmpeg command
set "output_file=!output_name! .mp4"
if "!FUSER_DRAGMODE!"=="1" (
    set "OUTVIDEO=!FUSER_STARTDIR!\!output_file!"
) else (
    set "OUTVIDEO=!output_file!"
)
set "ffmpeg_cmd=ffmpeg -f concat -safe 0 -i "!FUSER_CONCAT!" -c copy "!OUTVIDEO!""

rem Step 4: Execute FFmpeg command
echo Running FFmpeg...
%ffmpeg_cmd%

rem Check if FFmpeg was successful
if %ERRORLEVEL% neq 0 (
    echo Error occurred while running FFmpeg.
    pause
    exit /b %ERRORLEVEL%
)

rem Step 5: Cleanup temporary file
echo Cleaning up...
del "%FUSER_CONCAT%" 2>nul

echo Done. Output file: !OUTVIDEO!
pause
