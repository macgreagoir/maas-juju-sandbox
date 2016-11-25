#!/bin/bash
# Define instances on host machine
#
# Run this script as user in the libvirtd group
# Its passwd will be exposed in host-inventory.txt on maas0

[[ $(groups | grep libvirtd) ]] || {
    echo "Run this script as user in the libvirtd group"
    exit 1
}

SANDBOX_DIR=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

# Define the VMs
sed -e "s|../img/maas0.qcow2|${SANDBOX_DIR}/img/maas0.qcow2|" \
    -e "s|../img/maas0-seed.img|${SANDBOX_DIR}/img/maas0-seed.img|" \
    ${SANDBOX_DIR}/maas0/definition.xml > /tmp/maas0.xml
virsh define /tmp/maas0.xml
rm /tmp/maas0.xml

for def in $(ls ${SANDBOX_DIR}/nodeN/*_definition.xml); do
    def=$(basename $def)
    name=${def%_definition.xml}
    sed -e "s|../img/${name}.qcow2|${SANDBOX_DIR}/img/${name}.qcow2|" \
        ${SANDBOX_DIR}/nodeN/${def} > /tmp/${def}
    virsh define /tmp/${def}
    rm /tmp/$def
done
