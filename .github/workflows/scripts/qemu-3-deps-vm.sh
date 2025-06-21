#!/usr/bin/env bash

######################################################################
# 2) start qemu with some operating system, init via cloud-init
######################################################################

set -eu

sudo dnf config-manager -y --set-enabled crb
sudo dnf install -y epel-release almalinux-release-devel
sudo dnf update -y --setopt=fastestmirror=1 --refresh
sudo dnf group install -y "Development Tools"

sudo dnf install -y ccache cmake3 dnf-utils git htop mc openssh-server \
  pandoc rsync sg3_utils tmux

sudo dnf install -y binutils-devel cryptopp-devel grpc grpc-devel \
  grpc-plugins gtest-devel libattr-devel libcap-devel libuuid-devel \
  libsq3-devel libtirpc-devel librados-devel libradosstriper-devel \
  json-c-devel sqlite-devel postgresql-devel postgresql-server \
  kernel-headers protobuf-c-devel protobuf-devel valgrind \
  krb5-devel valgrind-devel xrootd-client-devel xrootd-devel \
  xrootd-server-devel xrootd-private-devel

sudo postgresql-setup --initdb
sudo systemctl start postgresql

# reset cloud-init configuration and poweroff
sudo cloud-init clean --logs
#sync && sleep 2 && sudo poweroff &

# wait for more input from user for now
sleep 212121
