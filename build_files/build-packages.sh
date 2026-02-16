#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable scottames/ghostty

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

dnf5 clean all
dnf5 -y copr disable scottames/ghostty
