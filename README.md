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

On Proxmox VE, you're root by default: drop `sudo` from the commands below.
On plain Debian with a regular user, keep `sudo`.

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

## Scheduling

Two options: plain cron, or a systemd timer (recommended, no log file to
manage).

### Option A: systemd timer (recommended)

```bash
sudo curl -fsSL -o /etc/systemd/system/pve-update.service \
  https://raw.githubusercontent.com/stephdl/proxmox-updater/main/pve-update.service
sudo curl -fsSL -o /etc/systemd/system/pve-update.timer \
  https://raw.githubusercontent.com/stephdl/proxmox-updater/main/pve-update.timer

sudo systemctl daemon-reload
sudo systemctl enable --now pve-update.timer
```

`pve-update.timer` options:

- `OnCalendar=Sun 00:00:00` — base run time, once a week.
- `RandomizedDelaySec=6h` — spreads the actual start over a 6h window, so
  many hosts don't hit the mirrors at the exact same second.
- `FixedRandomDelay=true` — keeps that random offset the same on every run
  for a given host, instead of picking a new one each time.
- `Persistent=true` — if the host was off at the scheduled time, runs once
  as soon as it's back on, instead of skipping to next week.

Output goes straight to journald, tagged `pve-update` (`SyslogIdentifier`
in the `.service` file). No log file, no logrotate needed:

```bash
journalctl -u pve-update.service -e
```

Run it once manually to test, without waiting for the timer:

```bash
sudo systemctl start pve-update.service
```

### Option B: plain cron

```bash
echo "0 3 * * 0 root /usr/local/bin/pve-update.sh >> /var/log/pve-update.log 2>&1" \
  | sudo tee /etc/cron.d/pve-update
```

Check the log after a run:

```bash
tail -50 /var/log/pve-update.log
```

With cron, the script writes to a plain file, so it needs logrotate (see
below). No randomized delay here: every host on the same cron line fires at
the exact same second.

Either way, check if a config file was kept instead of upgraded:

```bash
find /etc -name "*.dpkg-dist" -o -name "*.ucf-dist"
```

## Log rotation (cron option only)

`pve-update.logrotate` rotates `/var/log/pve-update.log` weekly, keeps 8
archives, compresses old ones, and uses `copytruncate` so the running cron
job never writes to a moved/deleted file descriptor.

Test it manually:

```bash
sudo logrotate -f /etc/logrotate.d/pve-update
```

## Tested on

Debian 13 (trixie), Proxmox VE 8/9 hosts.
