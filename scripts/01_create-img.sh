#!/bin/bash
# http://ubuntu-smoser.blogspot.fr/2013/02/using-ubuntu-cloud-images-without-cloud.html

SANDBOX_DIR=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

[[ $1 == "-f" ]] || {
    echo "This will destroy and recreate your all of the virtual machine disk images."
    echo "If you reeeally want to do that, you need to use the '-f' option:"
    echo $'\a' "$0 -f  # to force it"
    exit 1
}

lts_url="http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img"
# lts_url="http://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
[[ -f "${SANDBOX_DIR}/img/lts.img.dist" ]] || {
    wget $lts_url -O ${SANDBOX_DIR}/img/lts.img.dist
}

# Uncompress it and increase it to 20 GB
qemu-img convert -O qcow2 ${SANDBOX_DIR}/img/lts.img.dist img/maas0.qcow2
qemu-img resize img/maas0.qcow2 +18G

# Create a disk storing seed data
[[ -f "${SANDBOX_DIR}/maas0/user-data"  && -f "${SANDBOX_DIR}/maas0/meta-data" ]] && {
    cloud-localds img/maas0-seed.img maas0/user-data maas0/meta-data
}
# kvm -net nic -net user,name=priv_net -net user,name=pub_net -hda img/maas0.qcow2 -hdb img/maas0-seed.img -m 512

# An empty disk for nodeN VMs
for def in $(ls ${SANDBOX_DIR}/nodeN/*_definition.xml); do
    def=$(basename $def)
    name=${def%_definition.xml}
    qemu-img create -f qcow2 ${SANDBOX_DIR}/img/${name}.qcow2 20G
done
