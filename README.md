# Watchman

## Installation
Add this to your Dockerfile for debian bookworm to install newer watchman. Support AMD64/ARM64 architect.

```dockerfile
COPY --from=elob/watchman:debian-bookworm /watchman.deb /tmp/watchman.deb

RUN apt-get install /tmp/watchman.deb && \
    rm /tmp/watchman.deb
```

## Deploy
```bash
docker buildx build --platform linux/amd64,linux/arm64 -t elob/watchman:debian-bookworm --push .
```