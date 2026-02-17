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

# Compile system-wide schemas
rm -f /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas
