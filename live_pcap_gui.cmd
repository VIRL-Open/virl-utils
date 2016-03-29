@echo off

REM This batch file is primarily the work of other users in our community. I have just adapted a simple GUI
REM to make the script more user freindly. 
REM Thank you to user Flex from our Support community for creating the initial batch file
REM Thank you to rschmeid@cisco.com for your continued input and fun bits. 
REM 
REM Make sure that you have installed zenmap (https://nmap.org/zenmap/) on your system. 
REM original post is here: http://community.dev-innovate.com/t/script-to-enable-remote-live-packet-captures-using-windows/4414

TITLE VIRL Live Packet Capture
MODE con:cols=80 lines=12
COLOR 1F

set NETCAT_PATH=%PROGRAMFILES(x86)%\Nmap\ncat.exe
set WIRESHARK_PATH=%PROGRAMFILES%\Wireshark\Wireshark.exe
echo.
set /P VIRL_HOST="VIRL Server IP: "
set /P PCAP_PORT="Live port: "

echo.
echo Reading live capture from port %PCAP_PORT%. Close this window to stop capture!
echo.
"%NETCAT_PATH%" %VIRL_HOST% %PCAP_PORT% | "%WIRESHARK_PATH%" -k -i -