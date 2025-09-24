@echo off
setlocal enabledelayedexpansion

rem Ensure all videos are in the same format and have compatible settings

rem Step 1: Get the first file to use as prefix
for %%f in (*.mp4) do (
    set "first_file=%%~nf"
    goto :got_prefix
)
:got_prefix

rem Step 2: Generate the list of input files
rem This will create a file called concat.txt listing all mp4 files in the folder
echo Generating file list...
(for %%i in (*.mp4) do @echo file '%%i') > concat.txt

rem Step 3: Prepare the FFmpeg command
set "output_file=%first_file%_(+)_Fused .mp4"
set "ffmpeg_cmd=ffmpeg -f concat -safe 0 -i concat.txt -c copy "%output_file%""

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
del concat.txt

echo Done. Output file: %output_file%
pause
