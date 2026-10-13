# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:bf7c99d29416ae600b153194731f5966fd7deefc04ab03f292e3b04d2728005d AS build
ENV UV_INDEX=https://packages.vexxhost.com/pypi/openstack/simple/
ARG OCTAVIA_VERSION=19.0.0+a8e.50.2
RUN --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "octavia[redis]==${OCTAVIA_VERSION}" \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:main@sha256:bd4686739e93c44c1550e6a9de8afea384fbb6df43e25ece7f3d6d2a47a73778
RUN \
    groupadd -g 42424 octavia && \
    useradd -u 42424 -g 42424 -M -d /var/lib/octavia -s /usr/sbin/nologin -c "Octavia User" octavia && \
    mkdir -p /etc/octavia /var/log/octavia /var/lib/octavia /var/cache/octavia && \
    chown -Rv octavia:octavia /etc/octavia /var/log/octavia /var/lib/octavia /var/cache/octavia
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    isc-dhcp-client openssh-client
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=build --link /var/lib/openstack /var/lib/openstack
