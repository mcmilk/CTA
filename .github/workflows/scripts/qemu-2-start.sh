#!/usr/bin/env bash

######################################################################
# 2) start qemu with some operating system, init via cloud-init
######################################################################

set -eu

# short name used in zfs-qemu.yml
OS="$1"

# OS variant (virt-install --os-variant list)
OSv=$OS

# default nic model for vm's
NIC="virtio"

case "$OS" in
  almalinux8)
    OSNAME="AlmaLinux 8"
    URL="https://repo.almalinux.org/almalinux/8/cloud/x86_64/images/AlmaLinux-8-GenericCloud-latest.x86_64.qcow2"
    ;;
  almalinux9)
    OSNAME="AlmaLinux 9"
    URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
    ;;
  almalinux10)
    OSNAME="AlmaLinux 10"
    OSv="almalinux9"
    URL="https://repo.almalinux.org/almalinux/10/cloud/x86_64/images/AlmaLinux-10-GenericCloud-latest.x86_64.qcow2"
    ;;
  *)
    echo "Wrong value for OS variable!"
    exit 111
    ;;
esac

# environment file
ENV="/var/tmp/env.txt"
echo "ENV=$ENV" >> $ENV

# result path
echo 'RESPATH="/var/tmp/test_results"' >> $ENV
echo "NIC=$NIC" >> $ENV
echo "OS=$OS" >> $ENV
echo "OSv=\"$OSv\"" >> $ENV
echo "OSNAME=\"$OSNAME\"" >> $ENV

# default vm count for testings
VMs=2
echo "VMs=\"$VMs\"" >> $ENV

# default cpu count for testing vm's
CPU=2
echo "CPU=\"$CPU\"" >> $ENV

sudo mkdir -p "/mnt/tests"
sudo chown -R $(whoami) /mnt/tests

# we are downloading via axel, curl and wget are mostly slower and
# require more return value checking
IMG="/mnt/tests/cloudimg.qcow2"
echo "Loading image $URL ..."
time axel -q -o "$IMG" "$URL"

DISK="/dev/zvol/zpool/disk"
FORMAT="raw"
sudo zfs create -ps -b 64k -V 80g zpool/disk
while true; do test -b $DISK && break; sleep 1; done

echo "Importing VM image to zvol..."
sudo qemu-img dd -f qcow2 -O raw if=$IMG of=$DISK bs=4M
rm -f $IMG

PUBKEY=$(cat ~/.ssh/id_ed25519.pub)
cat <<EOF > /tmp/user-data
#cloud-config

fqdn: $OS

users:
- name: root
  shell: $BASH
- name: user
  sudo: ALL=(ALL) NOPASSWD:ALL
  shell: $BASH
  ssh_authorized_keys:
    - $PUBKEY

growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false
EOF

sudo virsh net-update default add ip-dhcp-host \
  "<host mac='52:54:00:83:79:00' ip='192.168.122.10'/>" --live --config

sudo virt-install \
  --os-variant $OSv \
  --name "testvm" \
  --cpu host-passthrough \
  --virt-type=kvm --hvm \
  --vcpus=4,sockets=1 \
  --memory $((1024*15)) \
  --memballoon model=virtio \
  --graphics none \
  --network bridge=virbr0,model=$NIC,mac='52:54:00:83:79:00' \
  --cloud-init user-data=/tmp/user-data \
  --disk $DISK,bus=virtio,cache=none,format=$FORMAT,driver.discard=unmap \
  --import --noautoconsole >/dev/null

# enable KSM
sudo virsh dommemstat --domain "testvm" --period 5
sudo virsh node-memory-tune 100 50 1
echo 1 | sudo tee /sys/kernel/mm/ksm/run > /dev/null

# vm0:    Initial VM with build dependencies for cta
# vm1..2  Testing VMs
for ((i=0; i<=VMs; i++)); do
  echo "192.168.122.1$i vm$i" | sudo tee -a /etc/hosts
done

# in case the directory isn't there already
mkdir -p $HOME/.ssh

cat <<EOF >> $HOME/.ssh/config
# no questions please
StrictHostKeyChecking no

# small timeout, used in while loops later
ConnectTimeout 1
EOF
