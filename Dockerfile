ARG DEBIAN_VERSION=13-slim
ARG MINIMAP2_VERSION=2.28
ARG MINIMAP2_SHA256=ffa5712735d229119f8c05722a0638ae0cc15aeb8938e29a3e52d5da5c92a0b4
ARG SAMTOOLS_VERSION=1.23.1
ARG SAMTOOLS_SHA256=32266198a4bc6a6df395d8526688c9697d9c8e472f888c749fdde2e08ea88dd2
ARG HTSLIB_VERSION=1.23.1
ARG HTSLIB_SHA256=f8a3f36effeec38f043c53ab1f2d9ed45064f14205c5ef8e3c815763b90803c4

# builder #####################################################################

FROM debian:${DEBIAN_VERSION} AS builder

ARG MINIMAP2_VERSION
ARG MINIMAP2_SHA256
ARG MINIMAP2_URL="https://github.com/lh3/minimap2/releases/download/v${MINIMAP2_VERSION}/minimap2-${MINIMAP2_VERSION}.tar.bz2"
ARG SAMTOOLS_VERSION
ARG SAMTOOLS_SHA256
ARG SAMTOOLS_URL="https://github.com/samtools/samtools/releases/download/${SAMTOOLS_VERSION}/samtools-${SAMTOOLS_VERSION}.tar.bz2"
ARG HTSLIB_VERSION
ARG HTSLIB_SHA256
ARG HTSLIB_URL="https://github.com/samtools/htslib/releases/download/${HTSLIB_VERSION}/htslib-${HTSLIB_VERSION}.tar.bz2"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libbz2-dev \
        libcurl4-openssl-dev \
        libdeflate-dev \
        liblzma-dev \
        libncurses-dev \
        libssl-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

# minimap2 builds a SIMD path per architecture: SSE on x86_64, NEON on aarch64
# via the arm_neon target. Building from source is what keeps this image
# genuinely multi-arch rather than shipping one architecture's binary to both.
RUN curl -fsSL --retry 3 -o "minimap2.tar.bz2" "${MINIMAP2_URL}" \
    && echo "${MINIMAP2_SHA256}  minimap2.tar.bz2" | sha256sum -c - \
    && tar -xjf minimap2.tar.bz2 \
    && cd "minimap2-${MINIMAP2_VERSION}" \
    && if [ "$(uname -m)" = "aarch64" ]; then make arm_neon=1 aarch64=1 -j"$(nproc)"; else make -j"$(nproc)"; fi \
    && mkdir -p /opt/minimap2/bin \
    && install -m 0755 minimap2 /opt/minimap2/bin/minimap2 \
    && strip /opt/minimap2/bin/minimap2 || true

RUN curl -fsSL --retry 3 -o "htslib.tar.bz2" "${HTSLIB_URL}" \
    && echo "${HTSLIB_SHA256}  htslib.tar.bz2" | sha256sum -c - \
    && tar -xjf htslib.tar.bz2 \
    && cd "htslib-${HTSLIB_VERSION}" \
    && ./configure \
        --prefix=/opt/samtools \
        --enable-libcurl \
        --enable-s3 \
        --enable-gcs \
    && make -j"$(nproc)" \
    && make install

RUN curl -fsSL --retry 3 -o "samtools.tar.bz2" "${SAMTOOLS_URL}" \
    && echo "${SAMTOOLS_SHA256}  samtools.tar.bz2" | sha256sum -c - \
    && tar -xjf samtools.tar.bz2 \
    && cd "samtools-${SAMTOOLS_VERSION}" \
    && ./configure \
        --prefix=/opt/samtools \
        --with-htslib=/opt/samtools \
        LDFLAGS="-Wl,-rpath,/opt/samtools/lib" \
    && make -j"$(nproc)" all \
    && make install \
    && strip /opt/samtools/bin/* /opt/samtools/lib/libhts.so.* || true

# runtime #####################################################################

FROM debian:${DEBIAN_VERSION} AS runtime

ARG DEBIAN_VERSION
ARG MINIMAP2_VERSION

LABEL org.opencontainers.image.title="minimap2" \
    org.opencontainers.image.description="minimap2 and samtools on debian:${DEBIAN_VERSION}" \
    org.opencontainers.image.version="${MINIMAP2_VERSION}" \
    org.opencontainers.image.source="https://github.com/lh3/minimap2" \
    org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH=/opt/minimap2/bin:/opt/samtools/bin:${PATH} \
    LC_ALL=C.UTF-8

# procps for `ps`: Nextflow's task wrapper shells out to it to collect metrics,
# and without it every task dies with
#   Command 'ps' required by nextflow to collect task metrics cannot be found
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libbz2-1.0 \
        libcurl4 \
        libdeflate0 \
        liblzma5 \
        libncursesw6 \
        procps \
        libssl3 \
        zlib1g \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --from=builder /opt/minimap2 /opt/minimap2
COPY --from=builder /opt/samtools /opt/samtools

# No ENTRYPOINT: Nextflow invokes the container as `/bin/bash -c ...`, and an
# ENTRYPOINT of ["minimap2"] turns that into `minimap2 /bin/bash`, which fails
# with: unrecognized command
CMD ["minimap2", "--help"]
