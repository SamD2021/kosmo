#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable scottames/ghostty

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

dnf5 install -y \
  tmux \
  just \
  ghostty \
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
  greetd \
  @cosmic-desktop-environment

dnf5 clean all
dnf5 -y copr disable scottames/ghostty
