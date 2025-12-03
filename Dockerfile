FROM debian:trixie-slim AS build

ARG WATCHMAN_COMMIT=ac8dcba0da5e8b834626b194a1d2ff1ddcee328b
ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

WORKDIR /usr/src/watchman

RUN <<'DOCKER_RUN_EOF'
apt-get update
apt-get install --no-install-recommends -y git build-essential python3-full curl ca-certificates sudo g++-12 gcc-12 libbz2-dev
curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. $HOME/.cargo/env
cargo --version
git clone --depth=1 https://github.com/facebook/watchman.git .
git fetch --depth=1 origin "$WATCHMAN_COMMIT"
git checkout "$WATCHMAN_COMMIT"
python3 -m venv .venv
. .venv/bin/activate
update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-12 100
update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-12 100
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
./install-system-packages.sh
./autogen.sh
mkdir -p debian/DEBIAN
mkdir -p debian/usr/local
cp -a built/* debian/usr/local/
cat > debian/DEBIAN/control <<EOF
Package: watchman
Version: 1.0.0
Section: utils
Priority: optional
Architecture: ${TARGETARCH}
Depends: libgoogle-glog0v6t64, libboost-context1.83.0, libdouble-conversion3, libevent-2.1-7, libsnappy1v5, libunwind8
Maintainer: Olle Bröms <olle.broms@example.com>
Description: Facebook Watchman file watching service
 Watchman is a file watching service from Meta that watches files and records
 when they change. It can trigger actions based on these changes and is designed
 to be fast and scalable.
EOF
chmod -R 0755 debian
chmod 0755 debian/DEBIAN
dpkg-deb --build debian watchman.deb
rm -rf /var/lib/apt/lists/*
DOCKER_RUN_EOF

FROM scratch
COPY --from=build /usr/src/watchman/watchman.deb /watchman.deb
