LABEL org.opencontainers.image.description="ADOC Automate"
LABEL org.opencontainers.image.licenses=MIT

# Playwright version (pip package, must be available for the Python version below)
# https://pypi.org/project/playwright/
# https://playwright.dev/docs/release-notes
ARG PLAYWRIGHT_VERSION="1.53.0"

# Base image
# https://hub.docker.com/_/node
# Node.js versions
# https://nodejs.org/en/about/previous-releases
# Debian releases
# https://www.debian.org/releases/
ARG BASE_IMAGE="node:24.3.0-bookworm-slim"

# Python version (apt package, must be available in the Debian release of the base image)
# https://wiki.debian.org/Python#Supported_Python_Versions
# https://docs.python.org/3/whatsnew/changelog.html
# https://www.python.org/doc/versions/
ARG PYTHON_VERSION="3.11"
ARG PYTHON_MAIN_VERSION="3"
ARG ASCIIDOCTOR_REVEALJS_VERSION=5.2.0

FROM ${BASE_IMAGE}

# Install Microsoft fonts and helpful tools
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    sed -i 's/^Components: main$/& contrib/' /etc/apt/sources.list.d/debian.sources && \
    apt-get update && \
    apt-get install -y \
        nano \
        ttf-mscorefonts-installer && \
    rm -rf /var/lib/apt/lists/*

# install asciidoctor (and the pdf and reveal.js version)
RUN apt-get update && \
    apt-get install -y \
        ruby \
        asciidoc \
        asciidoctor \
        ruby-asciidoctor \
        ruby-asciidoctor-pdf && \
    rm -rf /var/lib/apt/lists/*

# install asciidoctor-revealjs
ARG ASCIIDOCTOR_REVEALJS_VERSION
ENV ASCIIDOCTOR_REVEALJS_VERSION=$ASCIIDOCTOR_REVEALJS_VERSION
RUN gem install "asciidoctor-revealjs:${ASCIIDOCTOR_REVEALJS_VERSION}"

# Install Python
ARG PYTHON_VERSION
ENV PYTHON_VERSION=$PYTHON_VERSION
ARG PYTHON_MAIN_VERSION
ENV PYTHON_MAIN_VERSION=$PYTHON_MAIN_VERSION
RUN apt-get update && \
    apt-get install -y \
        python${PYTHON_VERSION} \
        python${PYTHON_MAIN_VERSION}-pip \
        python${PYTHON_VERSION}-venv && \
    rm -rf /var/lib/apt/lists/*

# Configure Python venv and automatically activate it via environment variables in this container
ENV VIRTUAL_ENV=/opt/venv
RUN python${PYTHON_VERSION} -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Switch to the working directory - required before npm install
WORKDIR /opt/prj

# Install Playwright and Chromium
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/ms-playwright
RUN npm install -g playwright@${PLAYWRIGHT_VERSION} && \
    npm cache clean --force
RUN playwright install chromium --with-deps

# Install the Playwright Python API
ARG PLAYWRIGHT_VERSION
ENV PLAYWRIGHT_VERSION=$PLAYWRIGHT_VERSION
RUN python${PYTHON_VERSION} -m pip install -v --no-cache-dir "playwright==${PLAYWRIGHT_VERSION}"

ENTRYPOINT []
CMD ["/bin/bash"]
