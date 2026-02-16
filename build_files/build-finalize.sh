#!/bin/bash

set -ouex pipefail

/tmp/ctx/branding.sh

systemctl enable podman.socket brew-setup.service bt-a2dp-fix.service
# Disable NetworkManager wait-online (unnecessary on desktops)
systemctl disable NetworkManager-wait-online.service
# Skip Plymouth quit wait to reduce boot delay (keep graphical LUKS prompt)
systemctl mask plymouth-quit-wait.service
