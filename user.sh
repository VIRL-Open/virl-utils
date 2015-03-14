#!/bin/bash
#
# source this to define the LIBVIRT_DEFAULT_URI var
# (or include it into .bashrc)
#
# usage: source user.sh
#

[[ `id` =~ \(libvirtd\) ]] || cat <<- EOF

	The current user '$USER' is not member of the libvirtd system group.
	you need to add the user to this group to make the virsh command
	work. Please consider

	sudo usermod -a -G libvirtd $USER

	To make the change effective, you need to log off and log in again.

	EOF
	export LIBVIRT_DEFAULT_URI='qemu:///system'

