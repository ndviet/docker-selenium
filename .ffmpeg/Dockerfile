FROM ubuntu:noble AS builder
ARG FFMPEG_VERSION="7.1"
ARG RCLONE_VER="v1.68.2"
ARG GO_VERSION="latest"
ARG GO_CRYPTO_VERSION="v0.31.0"
ARG GO_NET_VERSION="v0.33.0"

USER root

#======================================
# Install build tools
#======================================
ARG TOOLS_DEPS="autoconf automake cmake libfreetype6 gcc build-essential libtool make nasm pkg-config zlib1g-dev numactl \
libnuma-dev libx11-dev libxcb-shm0 libxcb1-dev yasm git curl jq wget ca-certificates"

RUN apt-get update -qqy \
    && apt-get upgrade -yq \
    && apt-get -qqy --no-install-recommends install ${TOOLS_DEPS} \
    && apt-get -qyy clean \
    && mkdir -p /usr/local/src

RUN if [ "${GO_VERSION}" = "latest" ]; then \
        GO_VERSION=$(curl -sk https://go.dev/dl/?mode=json | jq -r '.[0].version'); \
    fi \
    && curl -skLO https://go.dev/dl/${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz \
    && tar -xf ${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz -C /usr/local \
    && rm -rf ${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz* \
    && ln -sf /usr/local/go/bin/go /usr/bin/go \
    && go version

RUN cd /usr/local/src \
    && git clone https://github.com/rclone/rclone.git \
    && cd rclone \
    && git checkout ${RCLONE_VER} \
    # Patch deps version in go.mod to fix CVEs
    && sed -i "s|golang.org/x/crypto v.*|golang.org/x/crypto ${GO_CRYPTO_VERSION}|g" go.mod \
    && sed -i "s|golang.org/x/net v.*|golang.org/x/net ${GO_NET_VERSION}|g" go.mod \
    && go mod tidy \
    # Build rclone
    && make \
    && mv ~/go/bin/rclone /usr/local/bin/ \
    && rclone version

#======================================
# Install x264 from source
#======================================
RUN cd /usr/local/src \
    && git clone https://code.videolan.org/videolan/x264.git \
    && cd x264 \
    && ./configure --prefix="/usr/local" --enable-static \
    && make \
    && make install

#======================================
# Install FFmpeg from source
#======================================
RUN cd /usr/local/src \
    && git clone https://github.com/FFmpeg/FFmpeg.git \
    && cd FFmpeg \
    && git checkout release/${FFMPEG_VERSION} \
    && rm -rf .git \
    && PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" FFMPEG_VERSION=${FFMPEG_VERSION} ./configure \
    --prefix="/usr/local" \
    --extra-cflags="-I/usr/local/include" \
    --extra-ldflags="-L/usr/local/lib" \
    --pkg-config-flags="--static" \
    --enable-gpl \
    --enable-nonfree \
    --enable-libx264 \
    --enable-libxcb \
    --enable-static \
    && make \
    && make install

# Final stage
FROM ubuntu:noble

USER root

COPY --from=builder /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=builder /usr/local/bin/rclone /usr/local/bin/rclone

RUN apt-get -qqy update \
    && apt-get -qqy --no-install-recommends install \
    libx11-dev libxcb-shm0 libxcb1-dev \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN ldd /usr/local/bin/ffmpeg \
    && ffmpeg -version \
    && rclone --version

USER 101
