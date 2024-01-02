@echo off
setlocal enabledelayedexpansion

rem Get current date and time for the file name
for /f "delims=" %%a in ('wmic OS Get localdatetime ^| find "."') do set "timestamp=%%a"
set "timestamp=!timestamp:~0,4!-!timestamp:~4,2!-!timestamp:~6,2!-!timestamp:~8,2!-!timestamp:~10,2!-!timestamp:~12,2!"
set "resultsFile=results-!timestamp!.txt"

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
) else (
    rem Ask the user if they want to provide a path
    set /p "providePath=The input does not seem to be a valid drive letter. Do you want to provide a path? (Y/N): "
    if /i "!providePath!"=="Y" (
        call :selectPath
    ) else (
        rem Display an error message if the input is neither a valid drive letter nor a valid path
        color 0c
        echo Invalid drive letter or path. Please select a valid drive like C:, D:, E: or provide a valid path.
        color 07
        goto selectDrive
    )
)

echo.

rem Ask the user to enter a search pattern (can be none, one, or multiple)
set /p "searchTerms=Enter the search pattern (e.g., image.jpg, *.txt, enter for all files): "
echo Searching for: !searchTerms!

rem If no search terms were entered, search for all files
if "!searchTerms!"=="" set "searchTerms=*"

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

endlocal
exit /b

:selectPath
rem Prompt the user to enter a path
set /p "selectedPath=Enter the path: "

rem Check if the path is valid using the dir command
dir "!selectedPath!" >nul 2>&1

if %errorlevel% equ 0 (
    echo "Selected path: !selectedPath!"
    rem Set the path as the selected drive
    set "selectedDrive=!selectedPath!"
) else (
    rem Display an error message if the input is not a valid path
    color 0c
    echo Invalid path. Please provide a valid path.
    color 07
    goto selectPath
)
exit /b
