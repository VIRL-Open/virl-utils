:: Launch putty with a remote command
:: this requires a VM Maestro External terminal configuration as follows
:: (assuming this script is saved in the location indicated by the first)
::
:: SSH command: c:\putty.bat
:: SSH arguments: -ssh guest@%h %p -- %r
::
:: Also make sure that the puttyPath points to putty.exe
::
:: rschmied@cisco.com
::


@echo off
set puttyPath="C:\Program Files (x86)\putty\putty.exe"
setlocal enabledelayedexpansion
rem echo %* >>c:\cmd.log

set local_cmd=
set remote_cmd=
set remainder=no
for %%a in (%*) do (
   if "%%a"=="--" (
      set remainder=yes
   ) else (
      if "!remainder!"=="yes" (
         set remote_cmd=!remote_cmd! %%a
      ) else (
         set local_cmd=!local_cmd! %%a
      )
   )
)

rem echo %local_cmd% >>c:\cmd.log
rem echo %remote_cmd% >>c:\cmd.log

if not (!remote_cmd!)==() (
   :GETTEMPNAME
   set TMPFILE=%TMP%\virl-putty-%RANDOM%-%TIME:~6,5%.tmp
   if exist "!TMPFILE!" GOTO :GETTEMPNAME
   rem the remote command is wrapped in double quotes...!?
   echo %remote_cmd:"=% >!TMPFILE!
   set puttyCommand=%puttyPath%%local_cmd% -m "!TMPFILE!" -t
) else (
   set puttyCommand=%puttyPath%%local_cmd%
)

rem echo puttyCommand:   %puttyCommand% >>c:\cmd.log
start ""  /dc:\ /i %puttyCommand%

rem this is a bit of a hack:
if not "%TMPFILE%"=="" (
   timeout 1 >nul
   del %TMPFILE%
)

