FROM debian:bookworm-20230814-slim

RUN apt-get -y update \
  && apt-get -y install --no-install-recommends curl libdigest-sha-perl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd -r runner \
  && useradd -r -g runner runner

WORKDIR /opt/actions-runner

RUN chown -R runner /opt/actions-runner


USER runner

RUN curl -o actions-runner-linux-x64-2.308.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.308.0/actions-runner-linux-x64-2.308.0.tar.gz

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN echo '9f994158d49c5af39f57a65bf1438cbae4968aec1e4fec132dd7992ad57c74fa  actions-runner-linux-x64-2.308.0.tar.gz' | shasum -a 256 -c

RUN tar xzf ./actions-runner-linux-x64-2.308.0.tar.gz


USER root

RUN ./bin/installdependencies.sh

COPY entrypoint.sh /usr/lib/entrypoint.sh

RUN chmod +x /usr/lib/entrypoint.sh


USER runner

ENTRYPOINT [ "/usr/lib/entrypoint.sh" ]