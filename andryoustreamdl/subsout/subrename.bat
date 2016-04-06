@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
cd %2
SET old=subtitles
SET new=%1
for /f "tokens=*" %%f in ('dir /b *.srt') do (
  SET newname=%%f
  SET newname=!newname:%old%=%new%!
  move "%%f" "!newname!"
)
dir
pause