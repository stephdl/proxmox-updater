# proxmox-updater

Simple bash script to keep a Proxmox VE (or plain Debian) host updated via cron.
Runs `apt update && apt dist-upgrade`, handles locally modified config files
without hanging on a prompt, cleans up old kernels, and logs everything.

## What it does

- Updates package lists and upgrades all packages (`dist-upgrade`).
- Runs non-interactively (`DEBIAN_FRONTEND=noninteractive`), so it never hangs
  waiting for a prompt when a config file was modified locally.
- Keeps your local config changes on conflict (`--force-confold`): the new
  version proposed by the package is saved next to it as `*.dpkg-dist` /
  `*.ucf-dist` instead of overwriting your file.
- Removes unused packages and old kernels (`autoremove`).
- Prints the current Proxmox version if `pveversion` is available.
- Reports if a reboot is required.

## Installation

Quick install via curl:

```bash
sudo curl -fsSL -o /usr/local/bin/pve-update.sh \
  https://raw.githubusercontent.com/stephdl/proxmox-updater/main/pve-update.sh
sudo chmod 750 /usr/local/bin/pve-update.sh

sudo curl -fsSL -o /etc/logrotate.d/pve-update \
  https://raw.githubusercontent.com/stephdl/proxmox-updater/main/pve-update.logrotate

sudo touch /var/log/pve-update.log
sudo chmod 640 /var/log/pve-update.log
```

## Cron setup

Run it weekly, Sunday at 3am, log everything:

```bash
echo "0 3 * * 0 root /usr/local/bin/pve-update.sh >> /var/log/pve-update.log 2>&1" \
  | sudo tee /etc/cron.d/pve-update
```

Check the log after a run:

```bash
tail -50 /var/log/pve-update.log
```

Check if a config file was kept instead of upgraded:

```bash
find /etc -name "*.dpkg-dist" -o -name "*.ucf-dist"
```

## Log rotation

`pve-update.logrotate` rotates `/var/log/pve-update.log` weekly, keeps 8
archives, compresses old ones, and uses `copytruncate` so the running cron
job never writes to a moved/deleted file descriptor.

Test it manually:

```bash
sudo logrotate -f /etc/logrotate.d/pve-update
```

## Tested on

Debian 13 (trixie), Proxmox VE 8/9 hosts.
