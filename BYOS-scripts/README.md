BYOS -- "Build your own server" scripts
=====================================

These are a few scripts that can be used to build a server based on an existing cloud image. The scripts make a few assumptions on the server image used. In particular, there are some static references to the current [Ubuntu Trusty Cloud image](http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img "http://cloud-images.ubuntu.com/trusty/current/trusty-server-cloudimg-amd64-disk1.img").

*  ```build-image.sh``` Creates a disk image, based on the trusty base image. Takes a name as a parameter that will be used to name the disk / VM. It deletes existing known SSH keys from the known_hosts database, creates the cloud-init disk and launches the VM. It also starts a SSH client that will connect to the VM when it has come up.
*  ```clean-image.sh``` takes an existing disk image as a parameter, cleans and compresses it to save disk space and creates a new QCOW2 image and a VMDK image as a result


