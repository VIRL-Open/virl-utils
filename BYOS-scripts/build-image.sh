#!/bin/bash
#
# pass in the name of the image you’d like to create. 
# A file <name>.qcow2 will be created
#

if [ "$1" = "" ]; then
  echo "You need to provide a VM name!"
  echo "exiting."
  exit
fi

echo "Creating the base disk"
qemu-img convert trusty-server-cloudimg-amd64-disk1.img -O qcow2 $1.qcow2

echo "instance-id: $(uuidgen || echo i-abcdefg)" >my-meta-data
cat >my-user-data <<EOF
#cloud-config
password: password
chpasswd: { expire: False }
ssh_pwauth: True
EOF

cloud-localds my-seed.img my-user-data my-meta-data
ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222

echo "Booting VM... please wait. Password == \"password\""
echo "When done, shutdown the VM using \"shutdown -h now\""
sudo kvm --enable-kvm -daemonize -m 2048 \
-net nic -net user,hostfwd=tcp::2222-:22 \
-drive file=$1.qcow2,if=virtio -drive file=my-seed.img,if=virtio \
-vnc 127.0.1.1:99 -k en-us; ssh -p 2222 ubuntu@localhost
