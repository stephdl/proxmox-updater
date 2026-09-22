#!/usr/bin/env bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

echo "== Proxmox update start: $(date) =="

apt update
apt-get -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  full-upgrade
apt autoremove -y
apt clean

if command -v pveversion >/dev/null 2>&1; then
    pveversion
fi

if [ -f /var/run/reboot-required ]; then
    echo "Reboot required."
fi

echo "== Done. =="
