#!/bin/bash

# *** updated on Oct 10, 2016
# Questions about this script or if you found a bug
# please notify alegalle@cisco.com or send a note to ciscovirl@cisco.com
# ***
#
# This script will:
# 1.) install and reconfigure cloud-init to work only with ConfigDrive data source
# 2.) ensure rc-local.service will run after cloud-init
# 3.) create new ssh keys 
# 4.) add Kali repositories to /etc/apt/sources and comment the default ones
# 5.) install full Kali tools
# 6.) clean disk
#
# After this your image will run in VIRL cloud topologies.

trap int_exit INT
function int_exit
{
echo "${PROGNAME}: Aborted by user"
exit
}

update_cloud_init() {
apt-get install cloud-init -y

if [ $? -ne 0 ]; then
    echo "ERROR: Installation failed due to cloud-init."
    exit 1
fi

# reconfigure cloud-init, user interaction needed
dpkg-reconfigure cloud-init

# save patch for cloud.cfg
rm /tmp/cloud-cfg.patch >& /dev/null
touch /tmp/cloud-cfg.patch
cat >> /tmp/cloud-cfg.patch << EOF
--- cloud.cfg	2015-11-18 10:08:06.389556900 +0100
+++ cloud2.cfg	2015-11-18 10:10:37.177824900 +0100
@@ -91,3 +91,4 @@
      - arches: [default]
        failsafe:
          primary: http://ftp.debian.org/debian
+         security: http://security.debian.org/
EOF

# apply patch to cloud.cfg, adds security repository
patch /etc/cloud/cloud.cfg < /tmp/cloud-cfg.patch

# export sbin to path for tools usage in topologies
echo "export PATH=\"\$PATH:/sbin\"" >> /etc/bash.bashrc
ln -s /sbin/ifconfig /bin/ifconfig
ln -s /sbin/route /bin/route
ln -s /sbin/dhclient /bin/dhclient
}

change_rc(){
# patch /lib/systemd/system/rc-local.service to wait for cloud-config
touch /tmp/rc-local-service.patch
cat >> /tmp/rc-local-service.patch << EOF
13c13
< After=network.target
---
> After=network.target cloud-config.service
EOF

# apply patch to rc-local.service
	patch /lib/systemd/system/rc-local.service < /tmp/rc-local-service.patch
}

add_kali_repositories(){
# replace old /etc/apt/sources.list
mv /etc/apt/sources.list /etc/apt/sources.list.orig
touch /etc/apt/sources.list
cat >> /etc/apt/sources.list << EOF
# Kali repositories
# Based on Kali 2016.1 release
deb http://http.kali.org/kali kali-rolling main contrib non-free
# For source package access, uncomment the following line
# deb-src http://http.kali.org/kali kali-rolling main contrib non-free
EOF

apt-key adv --keyserver pgp.mit.edu --recv-keys ED444FF07D8D0BF6
apt-get clean
apt-get update -m
}

install_tools(){
cat<<-EOF

***********************
*  Installing Tools   *
***********************

EOF
sleep 2
apt-get update --fix-missing
apt-get upgrade -y
apt-get dist-upgrade -y
cat<<-EOF

**********************************
*  Installing Kali OS Packages   *
**********************************

EOF
sleep 2
apt-get install kali-linux-full -y
}

enable_ssh(){
rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server
if [ $? -ne 0 ]; then
    echo "ERROR: Installation failed. Cannot reconfigure openssh-server."
    exit 1
fi
service ssh restart
count="$(ps aux | grep -c sshd)"

if [ $count -lt 2 ]; then
    echo "ERROR: Installation failed, ssh daemon not running."
    exit 1
fi
}

clean_disk() {
dd if=/dev/zero of=/mytempfile
rm /mytempfile
}

echo "
Preparing system for Kali installation...
>>> Configuring Cloud Init <<<<
"
sleep 2
update_cloud_init
echo "
>>>> Configuring rc.local <<<<
"
sleep 2
change_rc
echo "
>>>> Configuring ssh server <<<<
"
sleep 2
enable_ssh
echo "
>>>> Configuring kali repositories <<<<
"
sleep 2
add_kali_repositories
install_tools
clean_disk
echo "Installation completed"
