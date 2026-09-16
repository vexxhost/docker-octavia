# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:8ca0cae46c3320b964f50f3e835afd34c280feb0201b0b8de63d803c9fd83ccf AS build
ENV UV_INDEX=https://packages.vexxhost.com/pypi/openstack/simple/
ARG OCTAVIA_VERSION=18.0.0+a8e.3.1
RUN --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "octavia[redis]==${OCTAVIA_VERSION}" \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:main@sha256:3ef187f5e1f46af80d16e32230d73e392dc88246aa62b9dc9a5f85c5013661d5
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
