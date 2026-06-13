#!/bin/bash

set -ouex pipefail

dnf5 -y copr enable scottames/ghostty
dnf5 -y copr enable architektapx/zen-browser

# Keep 1Password CLI group ID stable across rpm-ostree/bootc deployments.
if getent group onepassword-cli >/dev/null; then
	current_gid="$(getent group onepassword-cli | cut -d: -f3)"
	if [ "$current_gid" != "30001" ]; then
		groupmod -g 30001 onepassword-cli
	fi
else
	groupadd -g 30001 onepassword-cli
fi

rpm --import https://downloads.1password.com/linux/keys/1password.asc

sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

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
	lxpolkit \
	1password-cli

# Enforce Linux app-integration permissions for immutable systems.
for op_bin in /usr/bin/op /usr/sbin/op; do
	if [ -e "$op_bin" ]; then
		chgrp onepassword-cli "$op_bin"
		chmod 2755 "$op_bin"
	fi
done

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
