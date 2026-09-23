#!/usr/bin/env bash
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive

# Wait for another apt run (apt-daily, unattended-upgrades) instead of failing.
APT_OPTS=(-o DPkg::Lock::Timeout=600)

echo "== Proxmox update start: $(date) =="

apt-get "${APT_OPTS[@]}" update || { echo "apt-get update failed" >&2; exit 1; }
apt-get "${APT_OPTS[@]}" -y \
  -o Dpkg::Options::="--force-confdef" \
  -o Dpkg::Options::="--force-confold" \
  full-upgrade || { echo "apt-get full-upgrade failed" >&2; exit 1; }
apt-get "${APT_OPTS[@]}" autoremove -y || echo "apt-get autoremove failed" >&2
apt-get clean

if command -v pveversion >/dev/null 2>&1; then
    pveversion
fi

if [ -f /var/run/reboot-required ]; then
    echo "Reboot required."
fi

echo "== Done. =="
