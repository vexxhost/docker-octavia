# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2026.1@sha256:83c382a525e500e4a982400b9470d0c395fdf049a719947cc35311b5a202145a AS build
ENV UV_INDEX=https://packages.vexxhost.com/pypi/openstack/simple/
ARG OCTAVIA_VERSION=18.0.0+a8e.20.1
RUN --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "octavia[redis]==${OCTAVIA_VERSION}" \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:2026.1@sha256:c65c298a343b36ed6fdc3e5096d96b2dc0428c0b2a19696e02a3b64360e7e0ed
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
