#!/bin/bash
# vim: tabstop=4 shiftwidth=4 autoindent noexpandtab
#
# rschmied@cisco.com
#

# kexts of AppCat
#  177    0 0xffffff7f82703000 0x11000    0x11000    com.vmware.kext.vmci (90.8.1) <11 5 4 3 1>
#  178    0 0xffffff7f82714000 0xa000     0xa000     com.vmware.kext.vmnet (0302.40.04) <5 4 3 1>
#  179    0 0xffffff7f827a8000 0x10000    0x10000    com.vmware.kext.vmx86 (0302.40.04) <7 5 4 3 1>
#
# kexts of Fusion 6
#  180    1 0xffffff7f82703000 0x11000    0x11000    com.vmware.kext.vmci (90.5.7) <11 5 4 3 1>
#  181    0 0xffffff7f82714000 0xf000     0xf000     com.vmware.kext.vsockets (90.5.7) <180 7 5 4 3 1>
#  182    0 0xffffff7f827a8000 0xa000     0xa000     com.vmware.kext.vmnet (0268.43.43) <5 4 3 1>


APPCATALYST_PREFS="/Library/Preferences/VMware AppCatalyst"
APPCATALYST_NETCFG="$APPCATALYST_PREFS/networking"
APPCATALYST_BIN="/opt/vmware/appcatalyst"
BASHRC="${HOME}/.bashrc"
BASHPROFILE="${HOME}/.bash_profile"


function get_a_yes() {
	local __resultvar=$1
	local line result

	echo -en "\n$2 (y/yes)? "
	read line
	if [[ "$line" =~ ^(y|yes)$ ]]; then
		result="yes"
	else
		result="no"
	fi
	eval $__resultvar="'$result'"
}


function get_user_permission() {
	clear
	cat <<-'EOF'

	*** VIRL AppCatalyst installation preparation ***

	This script will check if your system is ready for VIRL on top of VMWare
	AppCatalyst as the hypervisor. It will check for the presence of:

	- Vagrant
	- Vagrant AppCatalyst plugin
	- AppCatalyst

	It then will modify your .bash_rc (Bash Shell configuration file) to
	include AppCatalyst into your path and set it as the default Vagrant
	provider.  
	
	It will also create a VIRL specific AppCatalyst networking configuration
	(providing for 4 network to satisfy FLAT, FLAT1, SNAT and INT) and allow
	for promiscouous mode which is needed for FLAT to work.

	The last two changes require elevated privileges, hence they are run using
	'sudo'.  You will be prompted to enter your password.
	EOF
	get_a_yes ok "Continue"
	if [ "$ok" = "no" ]; then
		return 1
	else 
		return 0
	fi
}


function check_vmware_kexts() {
	echo "### check presence of VMware kexts"
	if [ -n "$(kextstat | grep com\.vmware)" ]; then
		cat <<-'EOF'

		VMware kernel extensions are present on this system. Make sure they
		match the ones that AppCatalyst needs. If they are different, VMs might
		refuse to start. This error message 'Error occurred: Power on was
		canceled, make sure the VM you're trying to power on does not violate
		AppCatalyst constraints.' is an indication for this problem.  You might
		need to manually unload the incompatible extensions using the following
		commands:

			kextstat | grep com\.vmware
			kextunload -b <bundle-id>

		EOF
	fi
}


function check_appcatalyst() {
	echo "### check AppCatalyst"
 	if ! [ -d "$APPCATALYST_PREFS" ]; then
		cat <<-'EOF'

		you need to install AppCatalyst from here:
		https://www.vmware.com/cloudnative/appcatalyst-download

		EOF
		return 1
	else
		return 0
	fi
}


function check_vagrant_base() {
	echo "### check Vagrant base install"
	if [[ $(vagrant version) =~ "Installed Version: 1.7" ]]; then
		return 0
	else
		cat <<-'EOF'

		you need to install Vagrant for the Mac from here:
		https://www.vagrantup.com/downloads.html
		which links to:
		https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.4.dmg

		EOF
		return 1
	fi
}


function check_vagrant_plugin() {
    echo "### check Vagrant AppCatalyst plugin"
    if [[ $(vagrant plugin list) =~ vagrant-vmware-appcatalyst ]]; then
        return 0
    else
		cat <<-'EOF'

		you need to install the AppCatalyst plugin for Vagrant:

		vagrant plugin install vagrant-vmware-appcatalyst

		EOF
        return 1
    fi
}


function modify_bashrc() {
	echo "### Adding AppCatalyst to path and setting VAGRANT_DEFAULT_PROVIDER"
	if [ -n "$(grep appcatalyst $BASHRC)" -o -n "$(grep appcatalyst $BASHPROFILE)" ]; then
		cat <<-'EOF'

		your .bashrc or .bash_profile already contain AppCatalyst specific settings
		- Make sure that you add the AppCatalyst bin directory to your path
		- Make sure that your VAGRANT_DEFAULT_PROVIDER is set to vmware_appcatalyst
		... skipping ...

		EOF
	else
		sed -ire "/\\$/a\\
# AppCatalyst\\
PATH=\$PATH:$APPCATALYST_BIN\\
VAGRANT_DEFAULT_PROVIDER=vmware_appcatalyst\\
export \$PATH\\
export \$VAGRANT_DEFAULT_PROVIDER\\
# AppCatalyst\\
" $BASHRC
	fi
}


function create_networking_file() {
	echo "### create AppCatalyst VIRL network configuration"
	if [ -f "$APPCATALYST_NETCFG" ]; then
		echo "backing up existing config file"
		sudo mv "$APPCATALYST_NETCFG" "$APPCATALYST_NETCFG.backup"
	fi
	sudo tee "$APPCATALYST_NETCFG" >/dev/null <<-'EOF'
	VERSION=1,0
	answer VNET_1_DHCP yes
	answer VNET_1_HOSTONLY_NETMASK 255.255.255.0
	answer VNET_1_HOSTONLY_SUBNET 192.168.250.0
	answer VNET_1_VIRTUAL_ADAPTER yes
	answer VNET_2_DHCP no
	answer VNET_2_HOSTONLY_NETMASK 255.255.255.0
	answer VNET_2_HOSTONLY_SUBNET 172.16.1.0
	answer VNET_2_NAT yes
	answer VNET_2_NAT_PARAM_UDP_TIMEOUT 30
	answer VNET_2_VIRTUAL_ADAPTER yes
	answer VNET_3_DHCP no
	answer VNET_3_HOSTONLY_NETMASK 255.255.255.0
	answer VNET_3_HOSTONLY_SUBNET 172.16.2.0
	answer VNET_3_NAT yes
	answer VNET_3_NAT_PARAM_UDP_TIMEOUT 30
	answer VNET_3_VIRTUAL_ADAPTER yes
	answer VNET_4_DHCP no
	answer VNET_4_HOSTONLY_NETMASK 255.255.255.0
	answer VNET_4_HOSTONLY_SUBNET 172.16.3.0
	answer VNET_4_NAT yes
	answer VNET_4_NAT_PARAM_UDP_TIMEOUT 30
	answer VNET_4_VIRTUAL_ADAPTER yes
	answer VNET_5_DHCP no
	answer VNET_5_HOSTONLY_NETMASK 255.255.255.0
	answer VNET_5_HOSTONLY_SUBNET 172.16.10.0
	answer VNET_5_NAT yes
	answer VNET_5_NAT_PARAM_UDP_TIMEOUT 30
	answer VNET_5_VIRTUAL_ADAPTER yes
	answer VNET_8_DHCP yes
	answer VNET_8_HOSTONLY_NETMASK 255.255.255.0
	answer VNET_8_HOSTONLY_SUBNET 192.168.184.0
	answer VNET_8_NAT yes
	answer VNET_8_VIRTUAL_ADAPTER yes
	EOF
	sudo touch "$APPCATALYST_PREFS/promiscAuthorized"
}


function next_steps() {
	echo "### final thoughts"
	cat <<-'EOF'

		- open a new shell / Terminal to apply .bashrc changes
		- run 'appcatalyst-daemon'. It will run in the foreground unless you 
		  start it with 'appcatalayst-daemon 2>&1 >/tmp/appcatalyst.log &'.
		  (you can verify AppCatalyst is running by hitting http://localhost:8080)
		- Create directory where you will run vagrant
		  (mkdir -p ~/vagrant/appcat; cd ~/vagrant/appcat)
		- Place Vagrantfile and virl.ini into newly created directory
		- Edit Vagrantfile for your forwarded port specifics and bits 
		  you want to add to the provision section
		- Edit virl.ini file if you wish to change salt-master or other specifics
		- 'vagrant up', after clone and bootup you should see provision steps run
		- 'vagrant ssh' onto the box and carry on

	EOF
}

# tell user what we will do and ask for permission
get_user_permission || exit

# check system
check_vmware_kexts
check_appcatalyst || exit
check_vagrant_base || exit
check_vagrant_plugin || exit

# modify system
modify_bashrc
create_networking_file

# inform user
next_steps
echo "### done"

