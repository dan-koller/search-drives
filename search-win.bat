:: Search for files in a drive using Windows command line. No external tools or admin rights required.
:: Author: Dan Koller
:: Date: 02.01.2024
:: Version: 1.0
:: License: MIT

@echo off
setlocal enabledelayedexpansion

rem Get current date and time for the file name
for /f "delims=" %%a in ('wmic OS Get localdatetime ^| find "."') do set "timestamp=%%a"
set "timestamp=!timestamp:~0,4!-!timestamp:~4,2!-!timestamp:~6,2!-!timestamp:~8,2!-!timestamp:~10,2!-!timestamp:~12,2!"
set "resultsFile=results-!timestamp!.txt"

rem Main menu to select between searching for a drive or a path
:mainMenu
echo Select an option:
echo 1. Search for a drive
echo 2. Search for a path
echo 3. Exit
set /p "option=Enter an option: "
if "!option!"=="1" (
    call :selectDrive
) else if "!option!"=="2" (
    call :selectPath
) else if "!option!"=="3" (
    call :exit
) else (
    color 0c
    echo Invalid option. Please select a valid option.
    color 07
    goto mainMenu
)
goto :exit

:selectPath
rem Prompt the user to enter a path
set /p "selectedPath=Enter the path: "

rem Check if the path is valid using the dir command
dir "!selectedPath!" >nul 2>&1

if %errorlevel% equ 0 (
    echo "Selected path: !selectedPath!"
    rem Set the path as the selected drive
    set "selectedDrive=!selectedPath!"
    goto search
) else (
    rem Display an error message if the input is not a valid path
    color 0c
    echo Invalid path. Please provide a valid path like C:\Users\ or D:\.
    color 07
    goto selectPath
)

:selectDrive
rem Get all connected drives and their labels
echo Listing Available Drives:
echo -------------------------
set "driveList="
for /f "skip=1 delims=" %%d in ('wmic logicaldisk get caption^,volumename') do (
    set "driveInfo=%%d"
    if defined driveInfo (
        for /f "tokens=1,2" %%a in ("!driveInfo!") do (
            echo %%a %%b
            set "driveList=!driveList! %%a"
        )
    )
)
echo.

rem Prompt the user to select a drive
set /p "selectedDrive=Enter a drive letter (e.g., C:, D:, E:) or press enter to set a path: "

rem Check if the input is a valid drive letter
echo !driveList! | find /i " %selectedDrive% " >nul

if %errorlevel% equ 0 (
    echo "Selected drive: %selectedDrive%"
    goto search
) else (
    rem Display an error message if the input is neither a valid drive letter nor a valid path
    color 0c
    echo Invalid drive letter or path. Please select a valid drive like C:, D:, E: or provide a valid path.
    color 07
    goto selectDrive
)
echo.

:search
rem Ask the user to enter a search pattern (can be none, one, or multiple)
set /p "searchTerms=Enter the search pattern (e.g., image.jpg, *.txt, enter for all files): "

rem If no search terms were entered, search for all files
if "!searchTerms!"=="" set "searchTerms=*"

echo Searching for: !searchTerms!

rem For every search term, add a "/s <drive>\searchTerm*" to the search string
set "searchTerms=!searchTerms: =* /s %selectedDrive%\!*"

rem Use the dir command to search for the search terms in the selected drive
:: echo "Search string: dir /b /a-d /s %selectedDrive%\!searchTerms! > %resultsFile%"
dir /b /a-d /s %selectedDrive%\!searchTerms! > %resultsFile%

rem Count the number of results
set /a count=0
for /f %%i in ('type %resultsFile% ^| find /c /v ""') do set count=%%i
echo Found !count! results in %selectedDrive%.

rem Open the results file
start notepad %resultsFile%

rem Ask the user if they want to copy the results to a folder
call :copy
goto :exit

:copy
rem Ask the user if they want to copy the results to a folder only if there are results
if %count% equ 0 (
    goto :exit
)
set /p "copyResults=Do you want to copy the results to a folder? (Y/N): "
if /i "!copyResults!"=="Y" (
    call :copyResults
) else if /i "!copyResults!"=="N" (
    goto :exit
) else (
    rem Display an error message if the input is neither Y nor N
    color 0c
    echo Invalid input. Please enter Y or N.
    color 07
    goto copy
)
goto :exit

:copyResults
rem Prompt the user to enter a path
set /p "copyPath=Enter the path to copy the results to: "

rem Check if the path is valid using the dir command
dir "!copyPath!" >nul 2>&1

if %errorlevel% equ 0 (
    :: echo "Selected path: !copyPath!"
    rem Copy all files from the results file to the selected path
    for /f "delims=" %%f in (%resultsFile%) do (
        copy "%%f" "!copyPath!"
    )
    echo Results copied to !copyPath!.
) else (
    rem Display an error message if the input is not a valid path
    color 0c
    echo Invalid path. Please provide a valid path like C:\Users\ or D:\.
    color 07
)
goto :exit

:exit
rem Exit the script
exit /b

