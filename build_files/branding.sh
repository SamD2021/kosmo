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

# os-release
cat > /usr/lib/os-release <<EOF
NAME="${IMAGE_PRETTY_NAME}"
ID="${ID}"
ID_LIKE="fedora"
VERSION="${IMAGE_TAG}"
VERSION_CODENAME="${CODE_NAME}"
PRETTY_NAME="${IMAGE_PRETTY_NAME} (${CODE_NAME})"
BUG_REPORT_URL="${BUG_SUPPORT_URL}"
HOME_URL="${HOME_URL}"
DOCUMENTATION_URL="${DOCUMENTATION_URL}"
SUPPORT_URL="${SUPPORT_URL}"
LOGO=img-logo-icon
DEFAULT_HOSTNAME="kosmic"
EOF

# fastfetch user count (placeholder until you add your own endpoint)
echo "experimental" > /usr/share/ublue-os/fastfetch-user-count

# Optional: keep Bazaar stats only if you ship Bazaar
curl -fsSL \
  'https://flathub.org/api/v2/stats/io.github.kolunmi.Bazaar?all=false&days=1' \
  | jq -r ".installs_last_7_days" \
  | numfmt --to=si --round=nearest \
  > /usr/share/ublue-os/bazaar-install-count || true

