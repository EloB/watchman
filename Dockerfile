FROM debian:bookworm-slim AS build

ARG WATCHMAN_COMMIT=fa659091b95107677e5d2dba6f7a7277dbaf68ee

WORKDIR /usr/src/watchman

RUN apt-get update && \
    apt-get install --no-install-recommends -y git build-essential python3 curl ca-certificates sudo && \
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . $HOME/.cargo/env && \
    echo "source $HOME/.cargo/env" >> $HOME/.bashrc && \
    cargo --help && \
    git clone --depth=1 https://github.com/facebook/watchman.git . && \
    git fetch --depth=1 origin $WATCHMAN_COMMIT && \
    git checkout $WATCHMAN_COMMIT && \
    ./install-system-packages.sh && \
    ./autogen.sh && \
    rm -rf /var/lib/apt/lists/*

FROM scratch

COPY --from=build /usr/src/watchman/built /
