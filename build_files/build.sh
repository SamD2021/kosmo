#!/bin/bash

set -ouex pipefail

# Backward-compatible entrypoint for local workflows expecting build.sh
/tmp/ctx/build-setup.sh
/tmp/ctx/build-configure.sh
/tmp/ctx/build-packages.sh
/tmp/ctx/build-finalize.sh
