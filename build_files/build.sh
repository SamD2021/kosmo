#!/bin/bash

set -ouex pipefail

# Copy files from context
cp -avf "/tmp/ctx/files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1
dnf5 -y copr enable scottames/ghostty
# this installs a package from fedora repos
dnf5 install --allowerasing -y \
	fedora-asahi-remix-release-cosmic-atomic \
	fedora-asahi-remix-release-identity-cosmic-atomic

dnf5 install -y \
	tmux \
	just \
	ghostty \
	@cosmic-desktop-environment

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
