#!/bin/bash
# vim: tabstop=4 shiftwidth=4 autoindent noexpandtab
#
# install a handler script for telnet:// and ssh:// URIs
#
# tested w/ 
# - Firefox, Chrome, Chromium
# - Ubuntu 1[45].04 Unity, LXDE and XFCE
# - potentially works with other systems, too
#
# inspiration from 
# - http://edoceo.com/howto/xfce-custom-uri-handler
# - https://github.com/epleterte/ssh-xdg-open
# 
# Regarding the xdg-utils patch also see:
# - https://answers.launchpad.net/ubuntu/+source/xdg-utils/+question/272079
#
# rschmied@cisco.com
#

cd

#
# don't run as root
#
if [[ $(id) =~ ^uid=0 ]]; then
	cat <<-'EOF'

	Don't run this as root (e.g. with "sudo"). If the script needs to make
	changes as root, you will be prompted for your password!

	EOF
	exit
fi


#
# blurb
#
clear
cat <<-'EOF'

	*** Telnet and SSH handler installation script ***

	This script will install various files and make various configuration
	changes to the MIME system according to the FreeDesktop conventions.  E.g.
	it will install custom URI handlers for SSH and Telnet. It will create a
	Python handler script in ~/bin that actually will start the default
	terminal application based on your Linux distribution. It will also change
	some setting for Firefox, Chrome and Chromium; so that telnet:// and
	ssh:// links in web pages will start the terminal application.

	If the GVFS daemon has SFTP or SSH registered to handle remote file
	systems, then that setting needs to be changed as well. This requires root
	privileges as this is a system file. All other files and settings are
	owned by the user and thus do not require elevated privileges.

	NOTE: We have tested this with various OS, browser and desktop
	combinations but not all. This script might or might not work with your
	particular system :)

	[Press 'Enter' to continue or Ctrl-C to stop...]
EOF
read a

#
# the desktop file and handler
#
APPS=~/.local/share/applications
mkdir -p $APPS
sed -e "s#HOME#"${HOME}"/bin#" >$APPS/terminal.desktop <<-'EOF'
	[Desktop Entry]
	Name=terminal
	Terminal=false
	Type=Application
	Exec=HOME/terminal-handler %U
	MimeType=x-scheme-handler/ssh;x-scheme-handler/telnet;
EOF

mkdir -p ~/bin
cat >~/bin/terminal-handler <<'EOF'
#!/usr/bin/env python
# vim: tabstop=4 shiftwidth=4 autoindent noexpandtab

import sys
from urlparse import urlparse
from os import system

TERMINAL='CHANGEME -e "%s"'

def main(argv):
	if len(argv) != 2:
		print argv[0]+": URL required!"
		return -1

	o=urlparse(argv[1])
	if o.hostname and o.scheme in ( "ssh", "telnet" ):
		args=[ o.scheme ]
		if o.scheme == "ssh":
			if o.username:
				args.extend(["-l", o.username])
			if o.port:
				args.extend(["-p", str(o.port)])
			args.append(o.hostname)
		else:
			args.append(o.hostname)
			if o.port:
				args.append(str(o.port))
		return system(TERMINAL % " ".join(args))
	else:
		print argv[0]+": can't parse URL"
		return -1

if __name__ == "__main__":
	sys.exit(main(sys.argv))
EOF
chmod u+x ~/bin/terminal-handler


#
# test a list of known terminal emulators take the first one that is in the
# path otherwise warn the user
#
OLDIFS=$IFS
IFS=$'\n'
terminalbinaries="x-terminal-emulator
gnome-terminal
xterm
"
for file in ${terminalbinaries}; do
    terminal=$(which $file)
    if [ -n "$terminal"  ]; then
        break
    fi
done
IFS=$OLDIFS
if [ -z "$terminal" ]; then
	cat <<-'EOF'
	
	*** ATTENTION! ***

	We can't figure out your terminal application. Please edit the TERMINAL
	line at the top of the ~/bin/terminal-handler script so that it points to
	a valid terminal application. Use your favorite editor to open the script
	and modify the following line:

	TERMINAL='/path/to/your_terminal_application_here -e "%s"'

	ssh:// and telnet:// URIs will not work as intended if the ~/bin/terminal-
	handler script does not reference a valid terminal application for your
	system.

	[Press 'Enter' to continue...]
	EOF
	read a
else
	sed -ie "s#CHANGEME#$terminal#" ~/bin/terminal-handler
fi


#
# MIME types (primarily Firefox)
#
xdg-mime default terminal.desktop x-scheme-handler/telnet
xdg-mime default terminal.desktop x-scheme-handler/ssh

gvfs-mime --set x-scheme-handler/ssh terminal.desktop
gvfs-mime --set x-scheme-handler/telnet terminal.desktop

# global installation not required
#sudo desktop-file-install $APPS/terminal.desktop

# Gnome specific (gnome-open) SSH, Chrome uses these
gconftool-2 --set --type=bool /desktop/gnome/url-handlers/ssh/enabled true
gconftool-2 --set --type=string /desktop/gnome/url-handlers/ssh/command 'x-terminal-emulator -e "%s"'
gconftool-2 --set --type=bool /desktop/gnome/url-handlers/ssh/needs_terminal false

# Gnome specific (gnome-open) Telnet
gconftool-2 --set --type=bool /desktop/gnome/url-handlers/telnet/enabled true
gconftool-2 --set --type=string /desktop/gnome/url-handlers/telnet/command 'x-terminal-emulator -e "%s"'
gconftool-2 --set --type=bool /desktop/gnome/url-handlers/telnet/needs_terminal false


#
# patch xdg-open (fixes LXDE)
#
cat >xdg-open.patch <<'EOF'
--- /usr/bin/xdg-open	2015-10-05 16:43:25.622169319 +0200
+++ /usr/bin/xdg-open.patched	2015-10-15 11:38:07.575196250 +0200
@@ -384,7 +384,11 @@
 
 open_generic_xdg_mime()
 {
-    filetype=`xdg-mime query filetype "$1" | sed "s/;.*//"`
+    if [ -z $2 ]; then
+	filetype=`xdg-mime query filetype "$1" | sed "s/;.*//"`
+    else
+	filetype=$2
+    fi
     default=`xdg-mime query default "$filetype"`
     if [ -n "$default" ] ; then
         xdg_user_dir="$XDG_DATA_HOME"
@@ -406,6 +410,8 @@
                 fi
             fi
         done
+    else
+	exit_failure_operation_impossible "no handler for filetype $filetype defined!"
     fi
 }
 
@@ -444,6 +450,12 @@
                 exit_success
             fi
         fi
+    elif (echo "$1" | egrep -q '^[a-zA-Z\.\-]+://'); then
+	local handler=$(echo "$1" | sed -re 's#^([a-zA-Z\.\-]+)://.*#\1#')
+	open_generic_xdg_mime "$1" "x-scheme-handler/"$handler
+	if [ $? -eq 0 ]; then
+                exit_success
+	fi
     fi
 
     OLDIFS="$IFS"
EOF


#
# fix gvfsd / mostly xfce4?
#
GVFS_MOUNTS=/usr/share/gvfs/mounts/sftp.mount
if [ -f $GVFS_MOUNTS ]; then
	if grep -q ^SchemeAliases=ssh $GVFS_MOUNTS; then
	cat <<-EOF

		NOTE: We need to change the GVFS config and therefore we
		need your password! This is the command we will run as root:

		sed -ire 's/^SchemeAliases=ssh/#\0/' $GVFS_MOUNTS

		(e.g. it will comment out the 'SchemeAliases=ssh' line)

	EOF
	sudo sed -ire 's/^SchemeAliases=ssh/#\0/' $GVFS_MOUNTS
	NEED_LOGOUT_LOGIN="yes"
	fi
fi


#
# fix Google Chrome and Chromium
#
OLDIFS=$IFS
IFS=$'\n'
chromefiles=".config/google-chrome/Local State
.config/chromium/Local State"
for file in ${chromefiles}; do
    if [ -f $file ]; then
        python -c '
import json
FILE="'$file'"
with open(FILE, "r") as chromeconfig:
    config = json.loads(chromeconfig.read())
    config.setdefault("protocol_handler", {"excluded_schemes": {}})
    for proto in ( u"ssh", u"telnet"):
        config["protocol_handler"]["excluded_schemes"][proto]=False
with open(FILE, "w") as chromeconfig:
    chromeconfig.write(json.dumps(config))
'
    fi
done
IFS=$OLDIFS


#
# notify user
#
cat <<-'EOF'

	If you're running LX Ubuntu and the terminals will not open it maybe the
	case that your xdg-open utility can't handle telnet:// and ssh:// URIs.
	Chrome uses xdg-open, Firefox does not. If this affects you, then you can
	apply the provided patch in xdg-open.patch using the following command:

		sudo patch -d/ -p0 <xdg-open.patch

	This will fix xdg-open for certain desktop enviroments. Gnome uses gnome-
	open or gvs-open which should work out-of-the-box.

	Verify functionality using something like:

		xdg-open telnet://localhost:22

	and you should see a new terminal with the OpenSSH banner text. 

	IMPORTANT: SSH must be running on your system and accepting connections on
	TCP/22 for this to work. If your system does not accept SSH connections,
	change "localhost" to a system that allows SSH connectivity.

EOF
if [ ! -z "$NEED_LOGOUT_LOGIN" ]; then
	echo
	echo "IMPORTANT: you must logout and login again to apply the changes!"
	echo
fi
