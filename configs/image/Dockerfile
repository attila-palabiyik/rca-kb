# The one image every run executes in: the agent's container and the grading
# container alike, in every condition. Versions are pinned by build argument
# and written to /etc/harness-versions.

FROM ubuntu:24.04

ARG NODE_VERSION=22.23.5
ARG CODEX_VERSION=0.170.0
ARG FASTEMBED_VERSION=0.9.1

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      iverilog python3 python3-venv ca-certificates curl xz-utils git ripgrep \
 && rm -rf /var/lib/apt/lists/*

# Node, for the Codex CLI.
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
    | tar -xJ -C /usr/local --strip-components=1

RUN npm install -g "@openai/codex@${CODEX_VERSION}" && codex --version

# Similarity search: a small embedding model that runs locally, with no network.
RUN python3 -m venv /opt/kbsearch \
 && /opt/kbsearch/bin/pip install --no-cache-dir "fastembed==${FASTEMBED_VERSION}"
ENV KBSEARCH_MODELS=/opt/kbsearch/models
RUN /opt/kbsearch/bin/python -c "from fastembed import TextEmbedding; list(TextEmbedding('BAAI/bge-small-en-v1.5', cache_dir='/opt/kbsearch/models').embed(['warm up']))"
ENV HF_HUB_OFFLINE=1
COPY kbsearch.py /opt/kbsearch/kbsearch.py
RUN printf '#!/bin/sh\nexec /opt/kbsearch/bin/python /opt/kbsearch/kbsearch.py "$@"\n' > /usr/local/bin/kbsearch \
 && chmod +x /usr/local/bin/kbsearch

RUN { echo "node $(node --version)"; echo "codex $(codex --version)"; \
      echo "iverilog $(iverilog -V | head -1)"; echo "python $(python3 --version)"; \
      echo "fastembed ${FASTEMBED_VERSION}"; } > /etc/harness-versions

WORKDIR /app
