#!/usr/bin/env bash

######################################################################
# 4) build CTA
######################################################################

sudo virsh start testvm
.github/workflows/scripts/qemu-wait-for-vm.sh vm0

# /home/runner/work/CTA
rsync -ar $HOME/work/CTA/CTA user@vm0:./
ssh user@vm0 '/home/user/CTA/.github/workflows/scripts/qemu-4-build-vm.sh' $@

rsync -ar user@vm0:/home/user/CTA-v5.11.10.0-1/build_srpm/RPM/RPMS/x86_64 ./
ls -la
