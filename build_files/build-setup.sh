#!/bin/bash

set -ouex pipefail

# Keep composefs/transient root settings deterministic
printf '[composefs]\nenabled = yes\n\n[root]\ntransient = true\n' >/usr/lib/ostree/prepare-root.conf
ostree container commit

mkdir -p /nix
ostree container commit
