# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY files /files

# Base Image
FROM ghcr.io/samd2021/zirconium-asahi:latest-arm64@sha256:f2dc98d1ea1c0142eceb8badf779de697f32e9ef724b5437edfcb927dbcdbe66
ARG IMAGE_NAME="${IMAGE_NAME:-kosmo}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-samd2021}"

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
