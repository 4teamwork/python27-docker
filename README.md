# Python 2.7 Docker Image

A Docker image with Python 2.7 compiled on a recent Alpine Linux including
backports of security fixes.

## Build image

```
docker buildx build --platform linux/amd64,linux/arm64 --tag 4teamwork/python:2.7 --tag 4teamwork/python:latest --push .
```
