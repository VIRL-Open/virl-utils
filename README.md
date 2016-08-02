virl-utils
==========

Tools for working with VIRL. This is a loose collection of scripts that maybe useful when working with VIRL. Some in Python, some in Bash and even one for Windows. Here's a brief list of the scripts and what they are supposed to do. YMMV :)

For some of the tools it is required / useful to have a specific environment set and that the virl user is member of the libvirtd group:

    sudo usermod -a -G libvirtd virl
    echo "export LIBVIRT_DEFAULT_URI=qemu:///system" >>.bashrc

logout and login again to make those changes effective.

*  ```capture.bat``` This is a Windows script that takes a tap interface name as input. It will then fire up putty to connect to your VIRL host, start a tcpdump on the given interface and then will feed the output of the tcpdump into a local copy of Wireshark. Prerequisites to make this work (and some values like paths to executables or IP addresses may have to be changed in the capture.bat file itself)
   * [Putty](http://www.chiark.greenend.org.uk/~sgtatham/putty/download.html "Putty download page") installed (and the accompanying plink.exe)
   * [Wireshark](https://www.wireshark.org/download.html "Wireshark download page") installed
   * known VIRL host IP address
   * known tap interface name from where to capture packets. The tap interfaces must follow the following scheme 'tap00000000-00' where the digits are hex digits. See also ```list.py``` to identify those tap interfaces on the VIRL host.
*   ```capture.sh``` The corresponding Mac / Un*x shell script to do the same thing, namely start a tcpdump process on the VIRL host on a given tap interface, feed the packets into a named pipe. Wireshark needs to be started manually and it has to setup a named pipe interface via 'Capture -> Options', then 'Manage Interfaces', then on the 'Pipe' tab create a 'New' pipe interface pointing to the named pipe that has been created by the script.
* ```con.sh``` connects a Telnet session to the console of a router VM on the local VIRL host. It sets the escape sequence to Ctrl-\ instead of the default Ctrl-]. See also ```ports.py``` to identify the right port.
* ```ipv4.sh``` shows all local interfaces on the VIRL host that have an IPv4 address attached.
* ```lcVIRL``` stands for [live capture VIRL](https://github.com/gustavooferreira/lcVIRL) and it has the purpose to use wireshark or any other tool to capture packets on a VIRL network.
* ```link.py``` needs a MAC address as a parameter and 'up' or 'down', e.g. from running 'show interface gi0/0' in a VM. This will enable or disable the given interface on the VM, like connecting or disconnecting the cable to the router interface. Note: Interface state is not reflected in XRv. 
* ```list.py``` lists all interfaces of all running nodes / VMs of the user. The username can be given as a parameter to the script. The tap interfaces listed in the right column can be used to capture traffic, see ```capture.bat``` and ```capture.sh```.
* ```ports.py``` shows all ports (VNC and Console information) of all running instances on a VIRL host. It also includes the Instance name of the libvirt instance which can be manipulated via ```virsh```
* ```minion-key-reset.sh``` using the provided minion key file as a parameter (example AABBCCDD.virl.info.pem) this script will reset the minion key / configuration on the system. 
* ```salt-test.py``` helps with troubleshooting Salt key related issues.
* ```user.sh``` define required libvirtd environment variable for virsh.
* ```flatter.sh``` creates additional external networks a la FLAT and FLAT1. See the ```--help``` function to get more detailed information about the usage.
* ```ufw-enable.sh``` enable the User Friendly Firewall. Allow SSH and OpenVPN in, enable Masquerading / NAT / PAT going out on the management interface. Note that there are no safeguards in this script. It is meant to be modified (see top section) to reflect your environment and then modify the system configuration to turn on the firewall. If you want to be safe, study it first.
* ```openvpn-maximize.sh``` Includes ```ufw-enable.sh``` but does modify the system so that not only the firewall is enabled but also additional routing and system modification allows to use the entire VIRL system via OpenVPN (including console ports, UWM, STD, VM Maestro...).
* ```openvpn-bridge.sh``` Mac specific script that creates a bridge using the L2 OpenVPN connection and an additional, unused interface on the Mac so that external devices like a switch can be connected to the remote simulation. Modify vars on top of script to reflect actual system. Should be relatively easy to adapt for use on Linux (brctl / or ip link commands)

Example Output
======
Showing all interfaces of the user guest:

	virl@virl:~$ ./virl-utils/list.py 
	+---------+----------+-----------+--------------------+----------------+
	| Project | Topology | Node      | Link               | Interface      |
	+---------+----------+-----------+--------------------+----------------+
	| Guest   | Aaaaaa   | server-1  | Management Network | tap1566cc7c-f3 |
	|         |          | ~mgmt-lxc | Management Network | tap01825caf-28 |
	|         |          | ~mgmt-lxc | ~lxc-flat          | tapf95a5b9f-30 |
	|         | Testaa   | lxc-1     | Management Network | tapd9c9d9a5-57 |
	|         |          | ~mgmt-lxc | Management Network | tap6be5ff64-84 |
	|         |          | ~mgmt-lxc | ~lxc-flat          | tapa8198bea-59 |
	| User1   | Polizei  | lxc-1     | Management Network | tap9609e014-99 |
	|         |          | ~mgmt-lxc | Management Network | tap979bc19d-e0 |
	|         |          | ~mgmt-lxc | ~lxc-flat          | tap9c53aea5-51 |
	+---------+----------+-----------+--------------------+----------------+


Displaying ports of running simulations:

	virl@virl:~$ virl-utils/ports.py 
	+---------+----------+----------+------+---------+-------------------+
	| Project | Topology | Node     | VNC  | Console | Instance Name     |
	+---------+----------+----------+------+---------+-------------------+
	| guest   | kk       | iosvl2-1 | 5953 | 17003   | instance-0000001b |
	| guest   | kk       | server-1 | 5950 | 17000   | instance-00000018 |
	| guest   | kk       | server-2 | 5951 | 17001   | instance-00000019 |
	| guest   | kk       | server-3 | 5952 | 17002   | instance-0000001a |
	+---------+----------+----------+------+---------+-------------------+

Enabling / disabling an interface for a given MAC address:

	virl@virl:~$ ./virl-utils/link.py fa16.3e3d.0092 down
	Node Name for MAC 'fa:16:3e:3d:00:92': 
	</guest/endpoint>-<Sample_Topologies@single-T2IT_U>-<iosv-2>-<guest>
	Domain Name: 'instance-00000001'
	Interface updated!
	virl@virl:~$ ./virl-utils/link.py fa16.3e3d.0092 up
	Node Name for MAC 'fa:16:3e:3d:00:92': 
	</guest/endpoint>-<Sample_Topologies@single-T2IT_U>-<iosv-2>-<guest>
	Domain Name: 'instance-00000001'
	Interface updated!
	virl@virl:~$ 



