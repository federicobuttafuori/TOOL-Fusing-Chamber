@echo off
setlocal enabledelayedexpansionrem Ensure all videos are in the same format and have compatible settingsrem Step 1: Generate the list of input files
rem This will create a file called concat.txt listing all mp4 files in the folder
echo Generating file list...
(for %%i in (*.mp4) do @echo file '%%i') > concat.txtrem Step 2: Prepare the FFmpeg command
set "ffmpeg_cmd=ffmpeg -f concat -safe 0 -i concat.txt -c copy output.mp4"rem Step 3: Execute FFmpeg command
echo Running FFmpeg...
%ffmpeg_cmd%rem Check if FFmpeg was successful
if %ERRORLEVEL% neq 0 (
    echo Error occurred while running FFmpeg.
    pause
    exit /b %ERRORLEVEL%
)rem Step 4: Cleanup temporary file
echo Cleaning up...
del concat.txtecho Done.
pause

