# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:zed@sha256:ca033d8e0797ce1a4a4c71e00b8ee33cf81a5f621a715897228c66db8e8aeb4f AS build
RUN --mount=type=bind,from=octavia,source=/,target=/src/octavia,readwrite \
    --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/octavia \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:zed@sha256:b108d7e54ac02d1c902a2156593387d1273505ab5245c48ac5e0c9c1cfd12b5b
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
