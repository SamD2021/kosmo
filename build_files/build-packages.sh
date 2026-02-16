#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable scottames/ghostty

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
  swtpm \
  @cosmic-desktop-environment

dnf5 clean all
dnf5 -y copr disable scottames/ghostty
