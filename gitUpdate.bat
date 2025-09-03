@echo off
cd /d C:\WoW_WotLK\Interface\AddOns\GuideReaderLite

:: Check if a commit message was passed in (%1, %2, …)
if "%~1"=="" (
    set DATESTAMP=%date:~10,4%-%date:~4,2%-%date:~7,2%
    set MSG=Nightly commit - %DATESTAMP%
) else (
    set MSG=%*
)

git add .
git commit -m "%MSG%"
git push
pause
