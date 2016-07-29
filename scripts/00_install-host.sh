#!/bin/bash
# Install and configure networking and instances on host machine
#
# Run this script with sudo or as root

[[ $EUID -eq 0 ]] || {
  echo "This script must be run as root" 1>&2
  exit 1
}

SANDBOX_DIR=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

apt-get install -y libvirt-bin kvm cloud-utils genisoimage

# Define and start the required networks
# We assume 'default' is defined, but we don't use it
virsh net-define ${SANDBOX_DIR}/networks/priv_net.xml
virsh net-start priv_net
virsh net-autostart priv_net

virsh net-define ${SANDBOX_DIR}/networks/pub_net.xml
virsh net-start pub_net
virsh net-autostart pub_net

# Uncomment for jumboframes
# for i in $(ip a | grep virbr[12] | awk '$2 ~ /(virbr|vnet)/ {print $2}'); do ip li set dev ${i%:} mtu 9000; done

# iptables for dhcp and dns
## virsh adds most of what we need, but not these two
iptables -t mangle -A POSTROUTING -o virbr1 -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill
iptables -t mangle -A POSTROUTING -o virbr2 -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill
