# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.2@sha256:1dc1c28b2b702093ccd5039950ae76f512ba2d4939156182b244909b6611ee53 AS build
RUN --mount=type=bind,from=octavia,source=/,target=/src/octavia,readwrite \
    --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
sed -i 's/taskflow===.*/taskflow===5.5.0/g' /upper-constraints.txt
uv pip install \
    --constraint /upper-constraints.txt \
        /src/octavia[redis] \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:2023.2@sha256:d3c56b7343d522d23777f5e16e75fc26673b467b8c44cdbf73d9a2605edc4351
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
