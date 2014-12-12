#!/bin/bash
#
# do the Salt minion pub/private key stuff
#
# rschmied@cisco.com
#
#set -x

if [ "$1" = "-f" ]; then
  CHECK=false
  shift
else
  CHECK=true
fi

KEY=$1
if $CHECK && [[ ! "$KEY" =~ [0-9A-E]{8}\.[[:alpha:]]+\.[[:alpha:]]+\.pem ]]; then
        echo "you need to provide the key as a parameter to this script!"
        exit
fi
if [[ ! $(id) =~ ^uid=0 ]]; then
        echo "you need to run this as root (e.g. run \"sudo $*\")"
        exit
fi

mkdir -p /etc/salt/pki/minion
cp $KEY minion.pem
openssl rsa -in minion.pem -pubout >minion.pub
cp -f minion.pem /etc/salt/pki/minion/minion.pem
cp -f minion.pub /etc/salt/pki/minion/minion.pub
chmod 400 /etc/salt/pki/minion/minion.pem
rm minion.pub minion.pem

#
# write the /etc/salt/minion.d/extra.conf
#
SALT_DOMAIN=$(basename $KEY | cut -d. -f2,3)
SALT_ID=$(basename $KEY | cut -d. -f1)
mkdir -p /etc/salt/minion.d/
cat >/etc/salt/minion.d/extra.conf <<EOF
master: [ salt-master.cisco.com, salt-master-2.cisco.com ]
id: $SALT_ID
append_domain: $SALT_DOMAIN
master_type: failover 
verify_master_pubkey_sign: True 
master_shuffle: True 
master_alive_interval: 180 
EOF


