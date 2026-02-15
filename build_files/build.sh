#!/bin/bash

set -ouex pipefail

### Setup nix
echo -e '[composefs]\nenabled = yes\n\n[root]\ntransient = true' >/usr/lib/ostree/prepare-root.conf && ostree container commit

mkdir -p /nix && ostree container commit

### Fix bluetooth
dnf5 install -y bluez-deprecated expect
cat >/etc/systemd/system/bt-a2dp-fix.service <<EOF
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
EOF

cat >/usr/bin/bt-a2dp-fix.sh <<'EOF'
#!/bin/bash
# Bluetooth A2DP stutter fix for Apple Silicon (BCM4377/4378/4387)
# https://github.com/bluez/bluez/issues/722

unbuffer bluetoothctl --monitor | while read -r line; do
    if [[ "$line" =~ Device.*([0-9A-F:]{17}).*Connected:\ yes ]]; then
        mac="${BASH_REMATCH[1]}"
        sleep 2
        bluetoothctl info "$mac" | grep -q "Audio Sink" || continue
        handle=$(hcitool con | grep -i "$mac" | grep -oP 'handle \K[0-9]+')
        [[ -n "$handle" ]] && hcitool cmd 0x3f 0x57 "$(printf 0x%02X $handle)" 0x00 0x01
    fi
done
EOF

mkdir -p "/etc/wireplumber/wireplumber.conf.d"

cat >/etc/wireplumber/wireplumber.conf.d/50-bt-latency.conf <<EOF
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
EOF

# Copy files from context
cp -avf "/tmp/ctx/files"/. /

# Bootc kernel args:
# - quiet + splash: keep graphical LUKS unlock
# - plymouth.ignore-serial-consoles: reduce boot delay on Apple Silicon
mkdir -p /usr/lib/bootc/kargs.d
cat >/usr/lib/bootc/kargs.d/10-base-boot-options.toml <<EOF
kargs = [
  "quiet",
  "splash",
  "plymouth.ignore-serial-consoles"
]
match-architectures = ["aarch64"]
EOF

# Reduce shutdown/reboot timeout for faster restarts
mkdir -p /etc/systemd/system.conf.d
cat >/etc/systemd/system.conf.d/10-fast-shutdown.conf <<EOF
[Manager]
DefaultTimeoutStopSec=10s
EOF

# Blur-my-shell extension setup
# the src/* files must be moved to the standard extensions directory for GNOME Shell to detect it.
BMS_DIR=/usr/share/gnome-shell/extensions/blur-my-shell@aunetx
CAFFEINE_DIR=/usr/share/gnome-shell/extensions/caffeine@patapon.info

if [ -d "$BMS_DIR/src" ]; then
  cp -a "$BMS_DIR/src/." "$BMS_DIR/"
fi

# Caffeine extension setup
# Upstream repo wraps the actual extension in a nested directory.
if [ -d "$CAFFEINE_DIR/caffeine@patapon.info" ]; then
  cp -a "$CAFFEINE_DIR/caffeine@patapon.info/." "$CAFFEINE_DIR/"
fi

TMP_EXT_DIR=/usr/share/gnome-shell/extensions/tmp

if [ -d "$TMP_EXT_DIR" ]; then
  rm -rf "$TMP_EXT_DIR"
fi

# Logo Menu setup
# xdg-terminal-exec is required for this extension
install -Dpm0755 -t /usr/bin /usr/share/gnome-shell/extensions/logomenu@aryan_k/distroshelf-helper
install -Dpm0755 -t /usr/bin /usr/share/gnome-shell/extensions/logomenu@aryan_k/missioncenter-helper

# GSchema compilation for extensions
for schema_dir in /usr/share/gnome-shell/extensions/*/schemas; do
  if [ -d "${schema_dir}" ]; then
    glib-compile-schemas --strict "${schema_dir}"
  fi
done

# Bluefin GSchema overrides
tee /usr/share/glib-2.0/schemas/zz3-bluefin-unsupported-stuff.gschema.override <<EOF
[org.gnome.shell]
disable-extension-version-validation=true
EOF

# Update background XML month dynamically
# Target both picture-uri and picture-uri-dark
HARDCODED_MONTH="12"
CURRENT_MONTH=$(date +%m)
sed -i "/picture-uri/ s/${HARDCODED_MONTH}/${CURRENT_MONTH}/g" "/usr/share/glib-2.0/schemas/zz0-bluefin-modifications.gschema.override"

# Compile system-wide schemas
rm -f /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1
dnf5 -y copr enable scottames/ghostty

# How to replace identity to cosmic atomic asahi linux
#dnf5 install --allowerasing -y \
#	fedora-asahi-remix-release-cosmic-atomic \
#	fedora-asahi-remix-release-identity-cosmic-atomic

dnf5 install -y \
  tmux \
  just \
  ghostty \
  asahi-nvram \
  zsh \
  gcc \
  gnome-shell-extension-pop-shell \
  pam-u2f \
  pamu2fcfg \
  libfido2 \
  qemu \
  libvirt \
  libvirt-devel \
  virt-install \
  genisoimage \
  virt-manager \
  openvswitch \
  swtpm

#	@cosmic-desktop-environment

dnf5 clean all
dnf5 -y copr disable scottames/ghostty
# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

/tmp/ctx/branding.sh
#### Example for enabling a System Unit File

systemctl enable podman.socket brew-setup.service bt-a2dp-fix.service
# Disable NetworkManager wait-online (unnecessary on desktops)
systemctl disable NetworkManager-wait-online.service
# Skip Plymouth quit wait to reduce boot delay (keep graphical LUKS prompt)
systemctl mask plymouth-quit-wait.service
