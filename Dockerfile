FROM debian:bookworm-slim AS build

ARG WATCHMAN_COMMIT=fa659091b95107677e5d2dba6f7a7277dbaf68ee
ARG TARGETARCH

WORKDIR /usr/src/watchman

RUN <<DOCKER_RUN_EOF
set -ex
apt-get update
apt-get install --no-install-recommends -y git build-essential python3 curl ca-certificates sudo
curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. $HOME/.cargo/env
echo "source $HOME/.cargo/env" >> $HOME/.bashrc
cargo --help
git clone --depth=1 https://github.com/facebook/watchman.git .
git fetch --depth=1 origin $WATCHMAN_COMMIT
git checkout $WATCHMAN_COMMIT
./install-system-packages.sh
./autogen.sh
mkdir -p debian/DEBIAN
mkdir -p debian/usr/local/{bin,lib}
cp -r built/* debian/usr/local

cat <<EOF > debian/DEBIAN/control
Package: watchman
Version: 1.0.0-$WATCHMAN_COMMIT
Section: base
Priority: optional
Architecture: $TARGETARCH
Depends: libgoogle-glog0v6, libboost-context1.74.0, libdouble-conversion3, libevent-2.1-7, libsnappy1v5, libunwind8
Maintainer: Olle Bröms <olle.broms@ewebbyran.se>
Description: Facebook Watchman file watching service
 Watchman is a file watching service from Facebook, used to monitor changes
 in file trees and trigger actions based on those changes. It is designed to
 be highly performant and scalable.
EOF
chmod -R 0755 debian
chmod 0755 debian/DEBIAN
dpkg-deb --build debian

rm -rf /var/lib/apt/lists/*
DOCKER_RUN_EOF

FROM scratch

COPY --from=build /usr/src/watchman/debian.deb /watchman.deb
