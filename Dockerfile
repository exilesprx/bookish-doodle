FROM debian:bookworm-20250811-slim AS source
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
RUN apt-get -y update \
  && apt-get -y install --no-install-recommends \
  ca-certificates \
  curl \
  libdigest-sha-perl \
  gnupg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  \"$(. /etc/os-release && echo "$VERSION_CODENAME")\" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get -y update \
  && apt-get -y install --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

FROM exilesprx/github-runner:source AS build
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
# Commands below fail if running as root
RUN groupadd -r runner \
  && useradd -r -g runner runner \
  && usermod -aG docker runner
USER runner
WORKDIR /opt/actions-runner
RUN curl -o actions-runner-linux-x64-2.308.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.308.0/actions-runner-linux-x64-2.308.0.tar.gz \
  && echo '9f994158d49c5af39f57a65bf1438cbae4968aec1e4fec132dd7992ad57c74fa  actions-runner-linux-x64-2.308.0.tar.gz' | shasum -a 256 -c \
  && tar -xzf ./actions-runner-linux-x64-2.308.0.tar.gz
USER root
# Command below fail if not running as root
RUN ./bin/installdependencies.sh
USER runner


FROM exilesprx/github-runner:build AS runner
COPY --chmod=555 --chown=runner:runner entrypoint.sh /usr/lib/entrypoint.sh
ENTRYPOINT [ "/usr/lib/entrypoint.sh" ]
