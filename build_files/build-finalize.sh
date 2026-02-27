#!/bin/bash

set -ouex pipefail

/tmp/ctx/branding.sh

systemctl disable gdm.service || true
systemctl enable cosmic-greeter.service
systemctl enable podman.socket brew-setup.service bt-a2dp-fix.service xhci-wakeup-enable.service tailscaled
# Disable NetworkManager wait-online (unnecessary on desktops)
systemctl disable NetworkManager-wait-online.service
# Skip Plymouth quit wait to reduce boot delay
systemctl mask plymouth-quit-wait.service
