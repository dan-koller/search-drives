@echo off
setlocal enabledelayedexpansion

rem Get all connected drives and their labels
for /f "tokens=1,2" %%a in ('wmic logicaldisk get DeviceID^,VolumeName ^| find ":"') do (
    set "driveLetter=%%a"
    set "driveLabel=%%b"
    if defined driveLabel (
        set "driveList=!driveList!!driveLetter!-!driveLabel! "
    ) else (
        set "driveList=!driveList!!driveLetter! "
    )
)

rem Create a temporary file with valid drive letters
echo %driveList: =% > temp.txt

rem Display the list of drives with each drive on a new line
echo Connected Drives:
for %%d in (%driveList%) do (
    echo %%d
)

:selectDrive
rem Prompt the user to select a drive
set /p "selectedDrive=Enter the drive letter to select: "

rem Validate the entered drive letter
find /i "%selectedDrive%" < temp.txt >nul
if errorlevel 1 (
    echo Please select a correct drive.
    goto selectDrive
)

rem Display the selected drive
echo You selected %selectedDrive%

rem Clean up temporary file
del temp.txt
