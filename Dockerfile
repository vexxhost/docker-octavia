# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2026.1@sha256:260aa7774e22447cf3144412b528474f5fbaf99a15a7fa4718465da5f25ea7fd AS build
RUN --mount=type=bind,from=octavia,source=/,target=/src/octavia,readwrite \
    --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/octavia[redis] \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:2026.1@sha256:adf79ecab7a9b55a328f843f5a4e837a50e1f751b9865e7820909ce334c0ab97
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
