#!/bin/bash

set -ouex pipefail

# Fix bluetooth
DNF_SYSTEM_UPGRADE_NO_REBOOT=1 dnf5 install -y bluez-deprecated expect
cat >/etc/systemd/system/bt-a2dp-fix.service <<'UNIT'
[Unit]
Description=Bluetooth A2DP stutter fix for Apple Silicon
After=bluetooth.target
Wants=bluetooth.target

[Service]
Type=simple
ExecStart=/usr/bin/bt-a2dp-fix.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

cat >/usr/bin/bt-a2dp-fix.sh <<'SCRIPT'
#!/bin/bash
# Bluetooth A2DP stutter fix for Apple Silicon (BCM4377/4378/4387)
# https://github.com/bluez/bluez/issues/722

unbuffer bluetoothctl --monitor | while read -r line; do
    if [[ "$line" =~ Device.*([0-9A-F:]{17}).*Connected:\ yes ]]; then
        mac="${BASH_REMATCH[1]}"
        sleep 2
        bluetoothctl info "$mac" | grep -q "Audio Sink" || continue
        handle=$(hcitool con | grep -i "$mac" | grep -oP 'handle \K[0-9]+')
        [[ -n "$handle" ]] && hcitool cmd 0x3f 0x57 "$(printf 0x%02X "$handle")" 0x00 0x01
    fi
done
SCRIPT
chmod 0755 /usr/bin/bt-a2dp-fix.sh

mkdir -p /etc/wireplumber/wireplumber.conf.d
cat >/etc/wireplumber/wireplumber.conf.d/50-bt-latency.conf <<'EOF2'
monitor.bluez.rules = [
  {
    matches = [
      { node.name = "~bluez_output.*" }
    ]
    actions = {
      update-props = {
        latency.internal.ns = 100000000
      }
    }
  }
]
EOF2

# Copy static files from context
cp -avf /tmp/ctx/files/. /

# Remove inherited GNOME-specific schema overrides from common layer.
rm -f /usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override
rm -f /usr/share/glib-2.0/schemas/zz3-bluefin-unsupported-stuff.gschema.override

# Bootc kernel args:
# - quiet + splash: keep graphical LUKS unlock
# - plymouth.ignore-serial-consoles: reduce boot delay on Apple Silicon
mkdir -p /usr/lib/bootc/kargs.d
cat >/usr/lib/bootc/kargs.d/10-base-boot-options.toml <<'EOF3'
kargs = [
  "quiet",
  "splash",
  "plymouth.ignore-serial-consoles",
  "apple_dcp.show_notch=1",
  "appledrm.show_notch=1"
]
match-architectures = ["aarch64"]
EOF3

# Reduce shutdown/reboot timeout for faster restarts
mkdir -p /etc/systemd/system.conf.d
cat >/etc/systemd/system.conf.d/10-fast-shutdown.conf <<'EOF4'
[Manager]
DefaultTimeoutStopSec=10s
EOF4

# Make update-m1n1 robust on immutable /usr images where source file mtimes may
# trigger gzip warnings and non-zero exits.
mkdir -p /usr/sbin
mkdir -p /var/lib/asahi-boot
cat >/usr/sbin/refresh-asahi-boot-sources <<'EOF5'
#!/bin/bash
set -euo pipefail

install -D -m 0644 /usr/lib64/m1n1/m1n1.bin /var/lib/asahi-boot/m1n1.bin
install -D -m 0644 /usr/share/uboot/apple_m1/u-boot-nodtb.bin /var/lib/asahi-boot/u-boot-nodtb.bin
touch -d '2025-01-01 00:00:00 UTC' /var/lib/asahi-boot/m1n1.bin /var/lib/asahi-boot/u-boot-nodtb.bin
EOF5
chmod 0755 /usr/sbin/refresh-asahi-boot-sources

/usr/sbin/refresh-asahi-boot-sources

cat >/etc/sysconfig/update-m1n1 <<'EOF6'
M1N1="/var/lib/asahi-boot/m1n1.bin"
U_BOOT="/var/lib/asahi-boot/u-boot-nodtb.bin"
# limit DTBS to Mx and Mx Pro/Max/Ultra
DTBS="/boot/dtb/apple/t6*.dtb /boot/dtb/apple/t81*.dtb"
EOF6

cat >/usr/sbin/update-m1n1-safe <<'EOF7'
#!/bin/bash
set -euo pipefail
/usr/sbin/refresh-asahi-boot-sources
exec /usr/bin/update-m1n1 "$@"
EOF7
chmod 0755 /usr/sbin/update-m1n1-safe

# Keep /boot DTBs in sync with the running kernel for bootc/rpm-ostree deployments.
cat >/usr/sbin/asahi-sync-dtb <<'EOF8'
#!/bin/bash
set -euo pipefail

kver="$(uname -r)"
src="/usr/lib/modules/${kver}/dtb"
dst="/boot/dtb"

if [[ ! -d "${src}" ]]; then
  logger -t asahi-sync-dtb "skip: missing source dtb dir ${src}"
  exit 0
fi

mkdir -p "${dst}"

if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "${src}/" "${dst}/"
else
  rm -rf "${dst:?}/"*
  cp -a "${src}/." "${dst}/"
fi

sync
logger -t asahi-sync-dtb "synced dtbs for kernel ${kver}: ${src} -> ${dst}"
EOF8
chmod 0755 /usr/sbin/asahi-sync-dtb

# Keep m1n1 boot blob in sync on boot for bootc/rpm-ostree deployments.
mkdir -p /usr/lib/systemd/system
cat >/usr/lib/systemd/system/asahi-sync-dtb.service <<'EOF9'
[Unit]
Description=Sync DTBs to /boot for current kernel
DefaultDependencies=no
After=local-fs.target
Before=asahi-update-m1n1.service multi-user.target
ConditionPathExists=/usr/sbin/asahi-sync-dtb

[Service]
Type=oneshot
ExecStart=/usr/sbin/asahi-sync-dtb
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF9

cat >/usr/lib/systemd/system/asahi-update-m1n1.service <<'EOF10'
[Unit]
Description=Refresh m1n1 boot blob on ESP
DefaultDependencies=no
After=local-fs.target asahi-sync-dtb.service
Requires=asahi-sync-dtb.service
Before=multi-user.target
ConditionPathExists=/usr/bin/update-m1n1

[Service]
Type=oneshot
ExecStart=/usr/sbin/update-m1n1-safe
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF10

cat >/usr/sbin/asahi-verify-boot-artifacts <<'EOF11'
#!/bin/bash
set -euo pipefail

kver="$(uname -r)"
src="/usr/lib/modules/${kver}/dtb"
dst="/boot/dtb"

if [[ ! -d "${src}" || ! -d "${dst}" ]]; then
  logger -t asahi-boot-verify "warn: dtb source or destination missing (src=${src} dst=${dst})"
else
  tmp_src="$(mktemp)"
  tmp_dst="$(mktemp)"
  trap 'rm -f "${tmp_src}" "${tmp_dst}"' EXIT

  (
    cd "${src}"
    find . -type f -name '*.dtb' -print0 | sort -z | xargs -0 -r sha256sum
  ) >"${tmp_src}"
  (
    cd "${dst}"
    find . -type f -name '*.dtb' -print0 | sort -z | xargs -0 -r sha256sum
  ) >"${tmp_dst}"

  if diff -u "${tmp_src}" "${tmp_dst}" >/dev/null; then
    logger -t asahi-boot-verify "ok: /boot dtb content matches /usr/lib/modules/${kver}/dtb"
  else
    logger -t asahi-boot-verify "warn: /boot dtb content differs from /usr/lib/modules/${kver}/dtb"
  fi
fi

if [[ -s /boot/efi/m1n1/boot.bin ]]; then
  logger -t asahi-boot-verify "ok: ESP m1n1 boot.bin present"
else
  logger -t asahi-boot-verify "warn: ESP m1n1 boot.bin missing or empty"
fi
EOF11
chmod 0755 /usr/sbin/asahi-verify-boot-artifacts

cat >/usr/lib/systemd/system/asahi-verify-boot-artifacts.service <<'EOF12'
[Unit]
Description=Verify Asahi boot artifacts after sync
After=asahi-update-m1n1.service
ConditionPathExists=/usr/sbin/asahi-verify-boot-artifacts

[Service]
Type=oneshot
ExecStart=/usr/sbin/asahi-verify-boot-artifacts
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF12

mkdir -p /usr/lib/systemd/system/multi-user.target.wants
ln -sf ../asahi-sync-dtb.service /usr/lib/systemd/system/multi-user.target.wants/asahi-sync-dtb.service
ln -sf ../asahi-update-m1n1.service /usr/lib/systemd/system/multi-user.target.wants/asahi-update-m1n1.service
ln -sf ../asahi-verify-boot-artifacts.service /usr/lib/systemd/system/multi-user.target.wants/asahi-verify-boot-artifacts.service

# Compile system-wide schemas
rm -f /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas
