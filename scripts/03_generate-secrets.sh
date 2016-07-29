#!/bin/bash
# Generate secrets used in maas-installation

SANDBOX_DIR=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

mkdir -p ${SANDBOX_DIR}/maas-installation/secrets

cat > ${SANDBOX_DIR}/maas-installation/secrets/network.sh <<EOF
# Export the variables used to create network interfaces configurations.
# Used in maas_server_interfaces.tmpl and maas_interfaces.tmpl.

# Align with maas_server_interfaces.tmpl
export MAAS_PRIV_IFACE=eth0
export MAAS_PRIV_IP=192.168.123.2
export PRIV_NETMASK=255.255.255.0
export MAAS_PUB_IP=192.168.124.2
export PUB_NETMASK=255.255.255.0
export PUB_GW=192.168.124.1
export DNS_NS="192.168.123.2 8.8.8.8"
# MAAS DHCP scope on private network
export STATIC_IP_RANGE_LOW=192.168.123.40
export STATIC_IP_RANGE_HIGH=192.168.123.99
export IP_RANGE_LOW=192.168.123.100
export IP_RANGE_HIGH=192.168.123.239
export BROADCAST_IP=192.168.123.255
export ROUTER_IP=192.168.123.1
# no management (0), manage DHCP (1), manage DHCP and DNS (2)
export MANAGEMENT=2
# Space-separated list of dns forwarders. Leave empty for system
# defaults
export UPSTREAM_DNS=''
EOF
chmod 0770 ${SANDBOX_DIR}/maas-installation/secrets/network.sh

cat > ${SANDBOX_DIR}/maas-installation/secrets/maas-config.sh <<EOF
#!/bin/bash
# Export MAAS config used in the installation

export MAAS_DOMAIN=maas
export MAAS_ARCH=amd64/generic
export MAAS_USER=maas-root
export MAAS_USER_PASSWD=foobar
export BOOTSTACK_USER_PASS='\$1\$4w7pExuv\$fzZNr5p/2l2EzyVgymbFj/'  # foobar escaped
EOF
chmod 0770 ${SANDBOX_DIR}/maas-installation/secrets/maas-config.sh

cat > ${SANDBOX_DIR}/maas-installation/secrets/host-inventory.txt <<EOF
#name     tags  ipmi_user  ipmi_passwd  ipmi_ip  priv_ip  pub_ip  priv_mac  pub_mac
EOF

# You might want a new user for machine power control (ipmi_user)
# adduser --no-create-home --home /nonexistent --ingroup libvirtd virt

vm_node=0
for def in $(ls ${SANDBOX_DIR}/nodeN/*_definition.xml); do
    def=$(basename $def)
    name=${def%_definition.xml}
    # ${name} node
    # ipmi_user is a local user on the host machine, in the libvirtd grp
    # MAAS 'Power address' is qemu+ssh://<ipmi_user>@<ipmi_ip>/system
    # MAAS 'Power ID' is name
    # MAAS 'Power password' is ipmi_passwd, local passwd of ipmi_user
    HOST_NAME=${name}
    TAGS='virtual'
    # Tag node0 with 'bootstrap' in case we want the constraint
    [[ $vm_node -eq 0 ]] && TAGS='bootstrap,virtual'
    IPMI_USER=virt          # a user in libvirtd group
    IPMI_PASSWD=XXXXXXXX    # edit here or in generated file
    IPMI_IP=192.168.123.1
    PRIV_IP=192.168.123.$(( vm_node+40 ))  # based on dhcp scope
    PUB_IP=192.168.124.$(( vm_node+40 ))
    # TODO nasty and presumptuous
    PRIV_MAC=$(virsh dumpxml ${name} | grep -B1 priv_net | awk -F\' '/mac address/ {print $2}')
    PUB_MAC=$(virsh dumpxml ${name} | grep -B1 pub_net | awk -F\' '/mac address/ {print $2}')
    
    cat >> ${SANDBOX_DIR}/maas-installation/secrets/host-inventory.txt <<EOF
$HOST_NAME $TAGS $IPMI_USER $IPMI_PASSWD $IPMI_IP $PRIV_IP $PUB_IP $PRIV_MAC $PUB_MAC
EOF

    vm_node=$(( vm_node+1 ))
done

cat > ${SANDBOX_DIR}/maas-installation/maas-clouds.yaml <<EOF
clouds:
  dot2:
    type: maas
    auth-types: [oauth1]
    endpoint: http://192.168.124.2/MAAS
EOF
