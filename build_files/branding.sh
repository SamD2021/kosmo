#!/usr/bin/env bash

set -xeuo pipefail

IMAGE_REF="ostree-image-signed:docker://ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}"
IMAGE_INFO="/usr/share/ublue-os/image-info.json"
IMAGE_FLAVOR="main"
IMAGE_TAG="latest"

cat >"${IMAGE_INFO}" <<EOF
{
  "image-name": "${IMAGE_NAME}",
  "image-ref": "${IMAGE_REF}",
  "image-flavor": "${IMAGE_FLAVOR}",
  "image-vendor": "${IMAGE_VENDOR}",
  "image-tag": "${IMAGE_TAG}"
}
EOF

IMAGE_PRETTY_NAME="Kosmo"
HOME_URL="https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}"
DOCUMENTATION_URL="https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}"
SUPPORT_URL="https://github.com/${IMAGE_VENDOR}/${IMAGE_NAME}/issues"
BUG_SUPPORT_URL="${SUPPORT_URL}"

CODE_NAME="Kosmoceratops"
ID="kosmo"

# Preserve compatibility fields from the base image so system tooling
# (e.g. systemd-sysupdate pattern tokens) can still resolve release info.
if [[ -f /usr/lib/os-release ]]; then
  # shellcheck disable=SC1091
  . /usr/lib/os-release
  BASE_VERSION_ID="${VERSION_ID:-}"
  BASE_VERSION="${VERSION:-}"
  BASE_PLATFORM_ID="${PLATFORM_ID:-}"
fi

if [[ -z "${BASE_VERSION_ID:-}" ]] && [[ "${BASE_VERSION:-}" =~ ^([0-9]+) ]]; then
  BASE_VERSION_ID="${BASH_REMATCH[1]}"
fi

# os-release
cat >/usr/lib/os-release <<EOF
NAME="${IMAGE_PRETTY_NAME}"
ID="${ID}"
ID_LIKE="fedora"
VERSION="${IMAGE_TAG}"
VERSION_ID="${BASE_VERSION_ID:-0}"
VERSION_CODENAME="${CODE_NAME}"
PRETTY_NAME="${IMAGE_PRETTY_NAME} (${CODE_NAME})"
BUG_REPORT_URL="${BUG_SUPPORT_URL}"
HOME_URL="${HOME_URL}"
DOCUMENTATION_URL="${DOCUMENTATION_URL}"
SUPPORT_URL="${SUPPORT_URL}"
PLATFORM_ID="${BASE_PLATFORM_ID:-platform:f${BASE_VERSION_ID:-0}}"
LOGO=img-logo-icon
DEFAULT_HOSTNAME="kosmic"
EOF

# fastfetch user count (placeholder until you add your own endpoint)
echo "experimental" >/usr/share/ublue-os/fastfetch-user-count

# Deterministic placeholder for Bazaar stats
echo "n/a" >/usr/share/ublue-os/bazaar-install-count
