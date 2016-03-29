@echo off

REM Thank you to user Flex from our Support community for creating this batch file.
REM This script is a modification of the original .bat file found in the 
REM original post: http://community.dev-innovate.com/t/script-to-enable-remote-live-packet-captures-using-windows/4414

echo When done, close CMD Window to stop capture!
if -%1-==-- echo live capture tcp port not provided, please start as "live_pcap.cmd <live_port>" & exit /b

set NETCAT_PATH=%PROGRAMFILES(x86)%\Nmap\ncat.exe
set WIRESHARK_PATH=%PROGRAMFILES%\Wireshark\Wireshark.exe
set VIRL_HOST="172.16.50.245"
set PCAP_PORT="%1"

"%NETCAT_PATH%" %VIRL_HOST% %PCAP_PORT% | "%WIRESHARK_PATH%" -k -i -