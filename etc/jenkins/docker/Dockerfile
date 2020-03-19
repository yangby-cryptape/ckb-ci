FROM jenkins/jenkins:lts-alpine
MAINTAINER "Boyu Yang <yangby@cryptape.com>"

ARG docker_gid

USER root
RUN set -euo pipefail; \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> \
        /etc/apk/repositories; \
    apk add --no-cache docker-cli terraform ansible bc; \
    addgroup --gid ${docker_gid} docker; \
    adduser jenkins docker;

USER jenkins
