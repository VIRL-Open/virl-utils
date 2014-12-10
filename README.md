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
* ```link.py``` needs a MAC address as a parameter and 'up' or 'down', e.g. from running 'show interface gi0/0' in a VM. This will enable or disable the given interface on the VM, like connecting or disconnecting the cable to the router interface. Note: Interface state is not reflected in XRv. 
* ```list.py``` lists all interfaces of all running nodes / VMs of the user. The username must be given as a parameter to the script. The tap interfaces listed in the right column can be used to capture traffic, see ```capture.bat``` and ```capture.sh```.
* ```ports.py``` shows all ports (VNC and Console information) of all running instances on a VIRL host. 
* ```minion-key-reset.sh``` using the provided minion key file as a parameter (example AABBCCDD.virl.info.pem) this script will reset the minion key / configuration on the system. 

Example Output
======
Showing all interfaces of the user guest:

	virl@virl-sandbox:~$ ./virl-utils/list.py guest
	+-------------------+----------+--------+-------------------------+----------------+
	| Project           | Topology | Node   | Link                    | Interface      |
	+-------------------+----------+--------+-------------------------+----------------+
	| Sample_Topologies | Single   | iosv-2 | Multipoint Connection-1 | tap2cff6fb2-5e |
	|                   |          | iosv-2 | Management Network      | tap3dca55b5-f5 |
	|                   |          | iosv-2 | snat-1                  | tap6dbe122c-d2 |
	|                   |          | iosv-3 | Management Network      | tap603b92de-2b |
	|                   |          | iosv-3 | Multipoint Connection-1 | tapb419d5d7-43 |
	|                   |          | iosv-4 | Management Network      | tap1473bb05-c8 |
	|                   |          | iosv-4 | Multipoint Connection-1 | tap9fdfb633-d6 |
	|                   |          | linux  | Multipoint Connection-1 | tap27fed9a3-cb |
	|                   |          | linux  | flat-1                  | tap2d7a90b9-b6 |
	|                   |          | linux  | Management Network      | tap8f62596c-2c |
	+-------------------+----------+--------+-------------------------+----------------+
	virl@virl-sandbox:~$ 

Displaying ports of running simulations:

	virl@virl-sandbox:~$ ./virl-utils/ports.py 
	+-------+----------+--------+------+---------+
	| User  | Topology | Node   | VNC  | Console |
	+-------+----------+--------+------+---------+
	| guest | single   | iosv-2 | 5900 | 17000   |
	| guest | single   | iosv-3 | 5901 | 17002   |
	| guest | single   | iosv-4 | 5902 | 17004   |
	| guest | single   | linux  | 5903 | 17006   |
	+-------+----------+--------+------+---------+
	virl@virl-sandbox:~$ 

Enabling / disabling an interface for a given MAC address:

	virl@virl-sandbox:~$ ./virl-utils/link.py fa16.3e3d.0092 down
	Node Name for MAC 'fa:16:3e:3d:00:92': 
	</guest/endpoint>-<Sample_Topologies@single-T2IT_U>-<iosv-2>-<guest>
	Domain Name: 'instance-00000001'
	Interface updated!
	virl@virl-sandbox:~$ ./virl-utils/link.py fa16.3e3d.0092 up
	Node Name for MAC 'fa:16:3e:3d:00:92': 
	</guest/endpoint>-<Sample_Topologies@single-T2IT_U>-<iosv-2>-<guest>
	Domain Name: 'instance-00000001'
	Interface updated!
	virl@virl-sandbox:~$ 



