FROM alpine:latest
MAINTAINER "Boyu Yang <yangby@cryptape.com>"

ARG ansible_uid
ARG ansible_gid

RUN set -euo pipefail; \
    apk add --no-cache bash ansible; \
    addgroup -g ${ansible_gid} ansible; \
    adduser --disabled-password -h /mnt/workdir -s /bin/bash \
        -u ${ansible_uid} -G ansible ansible;

USER ansible
