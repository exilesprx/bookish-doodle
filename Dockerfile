FROM debian:bookworm-20240423-slim AS source

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

RUN apt-get -y update \
  && apt-get -y install --no-install-recommends curl libdigest-sha-perl ca-certificates gnupg

RUN install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get -y update \
  && apt-get -y --no-install-recommends install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd -r runner \
  && useradd -r -g runner runner \
  && usermod -aG docker runner

WORKDIR /opt/actions-runner

RUN chown -R runner /opt/actions-runner


FROM exilesprx/github-runner:source AS build

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# Commands below fail if running as root
USER runner

RUN curl -o actions-runner-linux-x64-2.308.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.308.0/actions-runner-linux-x64-2.308.0.tar.gz

RUN echo '9f994158d49c5af39f57a65bf1438cbae4968aec1e4fec132dd7992ad57c74fa  actions-runner-linux-x64-2.308.0.tar.gz' | shasum -a 256 -c

RUN tar xzf ./actions-runner-linux-x64-2.308.0.tar.gz

USER root

# Command below fail if not running as root
RUN ./bin/installdependencies.sh

USER runner


FROM exilesprx/github-runner:build AS runner

USER root

COPY entrypoint.sh /usr/lib/entrypoint.sh

RUN chmod +x /usr/lib/entrypoint.sh

# Runner should run as the runner user
USER runner

ENTRYPOINT [ "/usr/lib/entrypoint.sh" ]