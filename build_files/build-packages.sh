#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable scottames/ghostty
dnf5 -y copr enable architektapx/zen-browser

# Aggressive GNOME desktop purge: fail hard on conflicts.
dnf5 remove -y \
  gdm \
  gnome-shell \
  gnome-shell-common \
  gnome-session \
  gnome-session-wayland-session \
  gnome-session-xsession \
  mutter \
  mutter-common \
  gnome-shell-extension-apps-menu \
  gnome-shell-extension-background-logo \
  gnome-shell-extension-common \
  gnome-shell-extension-launch-new-instance \
  gnome-shell-extension-places-menu \
  gnome-shell-extension-pop-shell \
  gnome-shell-extension-pop-shell-shortcut-overrides \
  gnome-shell-extension-window-list

# Install COSMIC identity on top of Silverblue base
dnf5 install --allowerasing -y \
  fedora-asahi-remix-release-cosmic-atomic \
  fedora-asahi-remix-release-identity-cosmic-atomic

dnf5 config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo

dnf5 install -y \
  tmux \
  just \
  ghostty \
  zen-browser \
  asahi-nvram \
  zsh \
  gcc \
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
  swtpm \
  tailscale \
  greetd \
  @cosmic-desktop-environment

# Ensure Widevine prefs are always present in immutable /opt payload.
install -d /opt/zen-browser/defaults/pref
cat >/opt/zen-browser/defaults/pref/gmpwidevine.js <<'EOF'
pref("media.gmp-widevinecdm.version", "system-installed");
pref("media.gmp-widevinecdm.visible", true);
pref("media.gmp-widevinecdm.enabled", true);
pref("media.gmp-widevinecdm.autoupdate", false);
pref("media.eme.enabled", true);
pref("media.eme.encrypted-media-encryption-scheme.enabled", true);
EOF

dnf5 clean all
dnf5 -y copr disable scottames/ghostty
dnf5 -y copr disable architektapx/zen-browser
