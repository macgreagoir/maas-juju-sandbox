MAAS Juju Sandbox
=================

Prepare a local environment using KVM virtual machines as the 'bare metal', ready for maas-installation before deployment with Juju.

[maas-installation](https://github.com/macgreagoir/maas-installation/) is a related project to install and configure the MAAS server, and add the nodes.

This project assumes to configure these two virsh NAT networks on the host machine:

 * 192.168.123.0/24 as the private network
 * 192.168.124.0/24 as the public network


Install and Configure Virtual Networks and Machines
---------------------------------------------------
On the host machine

 * `scripts/00_install-host.sh` to prepare the host machine, including creation of virsh networks
 * `scripts/01_create-images.sh` to download the latest cloud image, create VM disks and seed disk
 * `scripts/02_define-machines.sh` to define the VMs in virsh
 * `scripts/03_generate-secrets.sh` to generate the secrets and templates files to be used with maas-installation


MAAS Server Configuration
-----------------------------

 * The `maas0` VM is defined in `scripts/02_define-machines.sh`
 * `maas0` gets its configuration from `maas0-seed.img`, created by `scripts/01_create-images.sh`
     * `maas0/user-data` stores the password to be set for the `ubuntu` user
     * `maas0/meta-data` configures networking


Initial Environment
-------------------
Start maas0

 * `virsh start maas0`
     * `virsh console maas0` if you'd like to watch it boot
 * `ssh -o StrictHostKeyChecking=no -l ubuntu 192.168.123.2`
 * Secrets files to be used with maas-installation have been created in `./maas-installation/`

Using the mass-installation project code on `maas0`, install and configure MAAS

 * Use the generated secrets as the `maas-installation/secrets/` files
 * During installation, `maas-installation/scripts/install-mass.sh` also configures MAAS 'Global Kernel Parameters' to set "console=ttyS0" for virsh console
 * Add the nodes listed in `maas-installation/secrets/host-inventory.txt` to MAAS
     * `maas-installation/scripts/maas-add-hosts.sh -d`
 * Add this maas cloud to Juju
     * `juju add-cloud maas-cloud ${generated_secrets}/maas-clouds.yaml`
     * `juju add-credential maas-cloud` ('maas-oath', when prompted, is the API key from `maas-region apikey --username=maas-root`)
