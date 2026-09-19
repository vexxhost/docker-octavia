# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.2@sha256:59c568404cf43ded71ed90958e4c31952597b37cff27c40ad375de731628b6ec AS build
ENV UV_INDEX=https://packages.vexxhost.com/pypi/openstack/simple/
ARG OCTAVIA_VERSION=13.0.1+a8e.1.3
RUN --mount=type=bind,from=ovn-octavia-provider,source=/,target=/src/ovn-octavia-provider,readwrite <<EOF bash -xe
sed -i 's/taskflow===.*/taskflow===5.5.0/g' /upper-constraints.txt
uv pip install \
    --constraint /upper-constraints.txt \
        "octavia[redis]==${OCTAVIA_VERSION}" \
        /src/ovn-octavia-provider
EOF

FROM ghcr.io/vexxhost/python-base:2023.2@sha256:153e7f0b4c827b13fc059fbb676ea6724cb77c674a334f5edd4d2575553c3074
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
