#!/usr/bin/env bash

.github/workflows/scripts/qemu-wait-for-vm.sh vm0
scp .github/workflows/scripts/qemu-3-deps-vm.sh user@vm0:qemu-3-deps-vm.sh
scp -r .github/workflows/scripts/patches user@vm0:patches
PID=`pidof /usr/bin/qemu-system-x86_64`
ssh user@vm0 '$HOME/qemu-3-deps-vm.sh' "$@"

# wait for poweroff to succeed
tail --pid=$PID -f /dev/null
sleep 5 # avoid this: "error: Domain is already active"
rm -f $HOME/.ssh/known_hosts
