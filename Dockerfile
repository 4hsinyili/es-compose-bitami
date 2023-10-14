# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0
# https://github.com/bitnami/containers/blob/main/bitnami/elasticsearch/7/debian-11/Dockerfile

FROM docker.io/bitnami/minideb:bullseye

ARG ELASTICSEARCH_PLUGINS
ARG JAVA_EXTRA_SECURITY_DIR="/bitnami/java/extra-security"
ARG TARGETARCH

LABEL com.vmware.cp.artifact.flavor="sha256:1e1b4657a77f0d47e9220f0c37b9bf7802581b93214fff7d1bd2364c8bf22e8e" \
  org.opencontainers.image.base.name="docker.io/bitnami/minideb:bullseye" \
  org.opencontainers.image.created="2023-10-11T19:53:34Z" \
  org.opencontainers.image.description="Application packaged by VMware, Inc" \
  org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.ref.name="7.4.2-debian-11-r1" \
  org.opencontainers.image.title="elasticsearch" \
  org.opencontainers.image.vendor="VMware, Inc." \
  org.opencontainers.image.version="7.4.2"

ENV HOME="/" \
  OS_ARCH="${TARGETARCH:-amd64}" \
  OS_FLAVOUR="debian-11" \
  OS_NAME="linux" \
  PATH="/opt/bitnami/common/bin:/opt/bitnami/java/bin:/opt/bitnami/elasticsearch/bin:$PATH"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages ca-certificates curl libasound2-dev libc6 libfreetype6 libfreetype6-dev libgcc1 procps zlib1g
RUN mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/ && \
  COMPONENTS=( \
  "yq-4.35.2-3-linux-${OS_ARCH}-debian-11" \
  "java-17.0.8-7-5-linux-${OS_ARCH}-debian-11" \
  "elasticsearch-7.4.2-0-linux-${OS_ARCH}-debian-11" \
  ) && \
  for COMPONENT in "${COMPONENTS[@]}"; do \
  if [ ! -f "${COMPONENT}.tar.gz" ]; then \
  curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz" -O ; \
  curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz.sha256" -O ; \
  fi && \
  sha256sum -c "${COMPONENT}.tar.gz.sha256" && \
  tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' && \
  rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
  done
RUN apt-get update && apt-get upgrade -y && \
  apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN chmod g+rwX /opt/bitnami

COPY rootfs /
RUN /opt/bitnami/scripts/elasticsearch/postunpack.sh
RUN /opt/bitnami/scripts/java/postunpack.sh
ENV APP_VERSION="7.4.2" \
  BITNAMI_APP_NAME="elasticsearch" \
  ES_JAVA_HOME="/opt/bitnami/java" \
  JAVA_HOME="/opt/bitnami/java" \
  LD_LIBRARY_PATH="/opt/bitnami/elasticsearch/jdk/lib:/opt/bitnami/elasticsearch/jdk/lib/server:$LD_LIBRARY_PATH"

RUN /opt/bitnami/elasticsearch/bin/elasticsearch-plugin install https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v7.4.2/elasticsearch-analysis-ik-7.4.2.zip

EXPOSE 9200 9300

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/elasticsearch/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/elasticsearch/run.sh" ]
