FROM nvidia/cuda:12.4.1-base-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ARG SRBMINER_VERSION=3.7.8

LABEL org.opencontainers.image.source="https://github.com/RunOnFlux/srbminer-docker-nvidia"
LABEL org.opencontainers.image.description="SRBMiner-MULTI for NVIDIA GPUs, built from upstream releases"

# SRBMiner drives NVIDIA GPUs through OpenCL, so it needs the OpenCL loader and an
# ICD entry pointing at NVIDIA's implementation. The driver libraries themselves
# (libnvidia-opencl, libcuda, libnvidia-ml) are mounted from the host by the NVIDIA
# container runtime and are deliberately not installed here: a copy baked into the
# image can shadow the host's on machines running a different driver version.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /etc/OpenCL/vendors \
    && echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

# Release assets use dashes in the version: 3.7.8 -> SRBMiner-Multi-3-7-8-Linux.tar.gz
RUN V="$(echo "${SRBMINER_VERSION}" | tr . -)" && \
    BASE="https://github.com/doktor83/SRBMiner-Multi/releases/download/${SRBMINER_VERSION}/SRBMiner-Multi-${V}-Linux" && \
    curl -fsSL "${BASE}.tar.gz" -o /tmp/srbminer.tar.gz && \
    curl -fsSL "${BASE}.tar.md5" | tr -d '\r' | cut -d' ' -f1 | sed 's|$|  /tmp/srbminer.tar.gz|' | md5sum -c - && \
    mkdir -p /opt/srbminer && \
    tar --strip-components=1 -xzf /tmp/srbminer.tar.gz -C /opt/srbminer && \
    rm /tmp/srbminer.tar.gz

# Make the SRBMiner binary executable
RUN chmod +x /opt/srbminer/SRBMiner-MULTI

# Copy the entrypoint script into the image
COPY entrypoint.sh /opt/srbminer/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /opt/srbminer/entrypoint.sh

# Set working directory
WORKDIR /opt/srbminer

# The miner talks to the driver directly and uses none of the CUDA runtime in this
# image, so skip the runtime's "cuda>=12.4" check. Without this the container
# refuses to start on hosts whose driver predates CUDA 12.4.
ENV NVIDIA_DISABLE_REQUIRE=1

# Define environment variables with default values
ENV ALGO=""
ENV POOL=""
ENV WALLET=""
ENV WORKER=""
ENV CPU_MINING="false"
ENV EXTRA=""

# Set the entrypoint to the entrypoint script
ENTRYPOINT ["/opt/srbminer/entrypoint.sh"]
