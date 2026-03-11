# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY files /files
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:b9a75b68a14211b36389402564a2cf2f9369290027ecf5f05df2d5f9cf36450a /system_files/bluefin /files
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:b9a75b68a14211b36389402564a2cf2f9369290027ecf5f05df2d5f9cf36450a /system_files/shared /files
COPY --from=ghcr.io/ublue-os/brew:latest@sha256:2eca44f5b4b58b8271a625d61c2c063b7c8776f68d004ae67563e2a79450be9c /system_files /files

# OPTIONS: quay.io/fedora-asahi-remix-atomic-desktops/base-atomic:42
# Base Image
FROM quay.io/fedora-asahi-remix-atomic-desktops/silverblue:43@sha256:5de8fcd4fc04a50e51cb91816aee7dcb2e9285c78c0d3a267ddb8f369e7d6fe9
ARG IMAGE_NAME="${IMAGE_NAME:-kosmo}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-samd2021}"

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

RUN if [ -L /opt ]; then rm -f /opt; fi && mkdir -p /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=tmpfs,dst=/var \
  --mount=type=tmpfs,dst=/tmp \
  --mount=type=tmpfs,dst=/boot \
  --mount=type=tmpfs,dst=/run \
  --mount=type=bind,from=ctx,source=/,dst=/tmp/ctx \
  /tmp/ctx/build-setup.sh

RUN --mount=type=tmpfs,dst=/var \
  --mount=type=tmpfs,dst=/tmp \
  --mount=type=tmpfs,dst=/boot \
  --mount=type=tmpfs,dst=/run \
  --mount=type=bind,from=ctx,source=/,dst=/tmp/ctx \
  /tmp/ctx/build-packages.sh

RUN --mount=type=tmpfs,dst=/var \
  --mount=type=tmpfs,dst=/tmp \
  --mount=type=tmpfs,dst=/boot \
  --mount=type=tmpfs,dst=/run \
  --mount=type=bind,from=ctx,source=/,dst=/tmp/ctx \
  /tmp/ctx/build-configure.sh

RUN --mount=type=tmpfs,dst=/var \
  --mount=type=tmpfs,dst=/tmp \
  --mount=type=tmpfs,dst=/boot \
  --mount=type=tmpfs,dst=/run \
  --mount=type=bind,from=ctx,source=/,dst=/tmp/ctx \
  /tmp/ctx/build-finalize.sh

### LINTING
## Verify final image and contents are correct.
LABEL containers.bootc=1
LABEL org.opencontainers.image.source="https://github.com/samd2021/kosmo"
RUN bootc container lint
