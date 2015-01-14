#!/bin/bash
#
# pass in the name of the .qcow2 image to be processed
# delete the original image
#

echo "Cleaning and compressing... please wait"
qemu-img convert -c -f qcow2 -O qcow2 -o cluster_size=2M $1 $1.clean
qemu-img convert -f qcow2 -O vmdk $1.clean $1.clean.vmdk

echo "Clean qcow2 and vmdk images are ready..."
echo "if everything looks OK you might want to delete the original image $1"
ls -la $1*
