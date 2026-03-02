# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY files /files
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:b8fe93b16674a547b4cf38493af19caa484d9575956fc3be04ca3d10faec23ff /system_files/bluefin /files
COPY --from=ghcr.io/projectbluefin/common:latest@sha256:b8fe93b16674a547b4cf38493af19caa484d9575956fc3be04ca3d10faec23ff /system_files/shared /files
COPY --from=ghcr.io/ublue-os/brew:latest@sha256:ca91068f51ce663d495ccfc829352d6621ec95f6c7db447ade55023b222f9762 /system_files /files

# OPTIONS: quay.io/fedora-asahi-remix-atomic-desktops/base-atomic:42
# Base Image
FROM quay.io/fedora-asahi-remix-atomic-desktops/silverblue:43@sha256:76b707478d0625b2fd31200501826502bec3cbe4830a271606545b8fb2280ab5
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
  /tmp/ctx/build-configure.sh

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
  /tmp/ctx/build-finalize.sh

### LINTING
## Verify final image and contents are correct.
LABEL containers.bootc=1
LABEL org.opencontainers.image.source="https://github.com/samd2021/kosmo"
RUN bootc container lint
