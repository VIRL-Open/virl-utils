@echo off

REM start a remote capture session using the provided live capture port
REM requires NetCat to be installed (https://eternallybored.org/misc/netcat/)
REM Depending on platform (32/64 bit) nc64.exe might be required
REM
REM rschmied@cisco.com

set NC=c:\bin\nc.exe
set HOST=172.16.1.254

if -%1-==-- echo port number is required & exit /b
%NC% %HOST% %1 | "\Program Files\Wireshark\Wireshark.exe" -k -i -
