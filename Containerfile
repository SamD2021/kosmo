# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY files /files
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:47abba6e2a15e36efcb18255fefa7c65673337404719a925d74409c6e080929e /system_files/bluefin /files
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:47abba6e2a15e36efcb18255fefa7c65673337404719a925d74409c6e080929e /system_files/shared /files
COPY --from=ghcr.io/ublue-os/brew:latest@sha256:7646a12d0369270ba479bde05d69e273af966a55178f283b0f717381d086ca7a /system_files /files

# OPTIONS: quay.io/fedora-asahi-remix-atomic-desktops/base-atomic:42
# Base Image
FROM quay.io/fedora-asahi-remix-atomic-desktops/silverblue:43@sha256:b715a7dfd3ba07359facac977de19292bde9d81f9f84b050f2f4affe901c1cf5
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
