@echo off

REM Thank you to user Flex from our Support community for creating this batch file.
REM original post is here: http://community.dev-innovate.com/t/script-to-enable-remote-live-packet-captures-using-windows/4414

echo When done, close CMD Window to stop capture!
if -%1-==-- echo live capture tcp port not provided, please start as "capture-from-socket.bat <tcp-live-capture-port>" & exit /b

set NETCAT_PATH=%PROGRAMFILES(x86)%\Nmap\ncat.exe
set WIRESHARK_PATH=%PROGRAMFILES%\Wireshark\Wireshark.exe
set VIRL_HOST="172.31.60.100"
set PCAP_PORT="%1"


REM start cmd /C "echo reading live capture from port %1, close this window to stop capture! ... & %NETCAT_PATH% %VIRL_HOST% %PCAP_PORT% | %WIRESHARK_PATH% -k -i -"
"%NETCAT_PATH%" %VIRL_HOST% %PCAP_PORT% | "%WIRESHARK_PATH%" -k -i -