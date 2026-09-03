# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.1@sha256:c79560084fe79cf4b3a3cf960da4b4c6ce6f4ef71567a24f5b612dbfc8d50c87 AS build
ENV UV_INDEX=https://packages.vexxhost.com/pypi/openstack/simple/
ARG OCTAVIA_VERSION=12.0.1+a8e.10.0
RUN --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "octavia==${OCTAVIA_VERSION}" \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:2023.1@sha256:c00e4452fee0a2fa2599c86b4bece3b940f4784a3d5e919d0bba600a1236b7e8
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
