@echo off

REM start a remote capture session using the provided tap interface 
REM use list.py script on VIRL host to identify correct tap interface
REM adapt path to Wireshark and Putty / plink.exe binaries
REM
REM rschmied@cisco.com

if -%1-==-- echo tap interface name not provided & exit /b

echo %1 | findstr /r "tap[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f]" >NUL
if errorlevel 1 (
  echo %1 does not look like a tap interface
) else (

  set HOST=172.16.1.1
  set USER=virl

  "\Program Files (x86)\PuTTY\plink.exe" -T %USER%@%HOST% sudo stdbuf -o0 tcpdump -w- -s0 -ni %1 | "\Program Files\Wireshark\Wireshark.exe" -k -i -
)

