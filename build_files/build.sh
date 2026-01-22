#!/bin/bash

set -ouex pipefail

# Copy files from context
cp -avf "/tmp/ctx/files"/. /

# Caffeine extension setup
# The Caffeine extension is built/packaged into a temporary subdirectory.
# It must be moved to the standard extensions directory for GNOME Shell to detect it.
if [ -d /usr/share/gnome-shell/extensions/tmp/caffeine/caffeine@patapon.info ]; then
  mv /usr/share/gnome-shell/extensions/tmp/caffeine/caffeine@patapon.info /usr/share/gnome-shell/extensions/caffeine@patapon.info
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
  libfido2

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

systemctl enable podman.socket brew-setup.service
